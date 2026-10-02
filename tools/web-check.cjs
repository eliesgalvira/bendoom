const assert = require('node:assert/strict');
const fs = require('node:fs');
const http = require('node:http');
const path = require('node:path');
const { chromium } = require(process.env.PLAYWRIGHT_DRIVER || 'playwright-core');

// Playwright's Chromium plays audio without a gesture, so a page's
// AudioContext starts suspended and resumes only once allowAudio is set.
function holdAudio() {
  const NativeAudioContext = window.AudioContext;
  window.allowAudio = false;
  window.AudioContext = class extends NativeAudioContext {
    constructor(options) { super(options); this.suspend(); }
    resume() { return window.allowAudio ? super.resume() : Promise.resolve(); }
  };
}

// FNV-1a over 32-bit words, as src/fnv.bend hashes them.
function fnv(words) {
  return words.reduce((h, w) => Math.imul(h ^ w, 16777619) >>> 0, 2166136261);
}

// DOOM1.WAD's E1M1 song as Chocolate Doom plays it: the hash of its
// first 1024 frames other than silence, each a word with the left sample
// in its low half, from a capture (tools/listen.nu --keep):
//   open --raw capture.raw | chunks 4 | each { into int --endian little } | where $it != 0 | first 1024
//     | reduce --fold 2166136261 {|x, h| (($h | bits xor $x) * 16777619) mod 4294967296 }
// Silence is left out on both sides, so a buffer the browser found empty
// cannot shift the frames compared.
const firstNotes = 3238671547;

async function main() {
  const [directory] = process.argv.slice(2);
  const root = path.resolve(directory);
  const server = http.createServer((request, response) => {
    const pathname = new URL(request.url, 'http://localhost').pathname;
    const file = path.resolve(root, '.' + (pathname === '/' ? '/index.html' : pathname));
    if (!file.startsWith(root + '/')) { response.writeHead(403); response.end(); return; }
    response.setHeader('Cross-Origin-Opener-Policy', 'same-origin');
    response.setHeader('Cross-Origin-Embedder-Policy', 'require-corp');
    response.setHeader('Content-Type', ({ '.html': 'text/html', '.js': 'text/javascript',
      '.wasm': 'application/wasm' })[path.extname(file)] || 'application/octet-stream');
    fs.createReadStream(file).on('error', () => { response.writeHead(404); response.end(); }).pipe(response);
  });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const url = 'http://127.0.0.1:' + server.address().port;
  let browser;
  try {
    browser = await chromium.launch({ executablePath: process.env.CHROMIUM || '/usr/bin/chromium',
      headless: true, args: ['--no-sandbox', '--mute-audio', '--disable-dev-shm-usage'] });
    const page = await browser.newPage();
    const errors = [];
    page.on('pageerror', error => errors.push(error.message));
    await page.addInitScript(holdAudio);
    await page.goto(url + '/audio-test.html');
    await page.waitForFunction(() => printed.includes('4096'));
    await page.evaluate(async () => {
      const device = [...Module.bendAudio.values()][0];
      window.observed = [];
      const source = `class Capture extends AudioWorkletProcessor {
        process(inputs) {
          const channels = inputs[0];
          if (channels.length === 2) this.port.postMessage([channels[0][0], channels[1][0]]);
          return true;
        }
      } registerProcessor('capture', Capture);`;
      const url = URL.createObjectURL(new Blob([source], { type: 'text/javascript' }));
      await device.context.audioWorklet.addModule(url);
      URL.revokeObjectURL(url);
      const capture = new AudioWorkletNode(device.context, 'capture', { outputChannelCount: [2] });
      capture.port.onmessage = event => observed.push(event.data);
      device.node.connect(capture);
      capture.connect(device.context.destination);
    });
    await page.evaluate(() => { window.allowAudio = true; });
    await page.locator('button').click();
    await page.waitForFunction(() => printed.includes('closed'), null, { timeout: 20000 });
    const audio = await page.evaluate(() => ({ samples: observed, printed, devices: Module.bendAudio.size }));
    assert.deepEqual(audio.printed, ['invalid rate rejected', '4096', '4096', 'closed']);
    assert.equal(audio.devices, 0);
    assert(audio.samples.some(([l, r]) => l === 0.25 && r === -0.5), 'stereo output');
    assert(audio.samples.some(([l, r]) => l === 0 && r === 0), 'underrun silence');
    assert(audio.samples.every(([l, r]) => (l === 0.25 && r === -0.5) || (l === 0 && r === 0)), 'no corrupt samples');
    console.log('PASS audio: invalid rate, overflow, wraparound, stereo, underruns and close');
    await page.close();

    const unavailable = await browser.newPage();
    unavailable.on('pageerror', error => errors.push(error.message));
    await unavailable.addInitScript(() => { window.AudioContext = class { constructor() { throw Error('No device'); } }; });
    await unavailable.goto(url + '/audio-test.html');
    await unavailable.waitForFunction(() => typeof window.exitCode === 'number' && window.exitCode !== 0);
    console.log('PASS audio: unavailable device fails without hanging');
    await unavailable.close();

    const game = await browser.newPage({ viewport: { width: 1100, height: 1050 } });
    game.on('pageerror', error => errors.push(error.message));
    await game.addInitScript(holdAudio);
    await game.goto(url);
    await game.waitForFunction(() => !document.getElementById('play').disabled, null, { timeout: 120000 });
    await game.evaluate(() => document.getElementById('play').click());
    await game.waitForFunction(() => Module.bendFrames > 10);
    const queued = await game.evaluate(() => {
      const [ring, device] = [...Module.bendAudio.entries()][0];
      const counts = new BigUint64Array(HEAPU8.buffer, ring, 2);
      const written = Number(Atomics.load(counts, 1));
      return { state: device.context.state, read: Number(Atomics.load(counts, 0)),
        pcm: Array.from(new Float32Array(HEAPU8.buffer, ring + 16, written * 2)) };
    });
    assert.equal(queued.state, 'suspended');
    assert.equal(queued.read, 0);
    assert(queued.pcm.length > 0 && queued.pcm.length <= 8192);
    assert(queued.pcm.every(sample => sample === 0), "the chip's first buffer is silent");
    await game.evaluate(async () => {
      const device = [...Module.bendAudio.values()][0];
      window.notes = [];
      const source = `class Notes extends AudioWorkletProcessor {
        process(inputs) {
          if (inputs[0].length === 2) this.port.postMessage([inputs[0][0].slice(), inputs[0][1].slice()]);
          return true;
        }
      } registerProcessor('notes', Notes);`;
      const url = URL.createObjectURL(new Blob([source], { type: 'text/javascript' }));
      await device.context.audioWorklet.addModule(url);
      URL.revokeObjectURL(url);
      const node = new AudioWorkletNode(device.context, 'notes', { outputChannelCount: [2] });
      node.port.onmessage = ({ data: [left, right] }) => left.forEach((l, i) => {
        const word = ((Math.round(l * 32768) & 65535) | (Math.round(right[i] * 32768) & 65535) << 16) >>> 0;
        if (word !== 0 && notes.length < 1024) notes.push(word);
      });
      device.node.connect(node);
      node.connect(device.context.destination);
    });
    await game.evaluate(() => { window.allowAudio = true; });
    await game.locator('#sound').click();
    await game.waitForFunction(() => [...Module.bendAudio.values()][0].context.state === 'running');
    await game.waitForFunction(() => notes.length === 1024, null, { timeout: 20000 });
    assert.equal(fnv(await game.evaluate(() => notes)), firstNotes, "the song's first notes are Chocolate Doom's");
    const before = await game.evaluate(() => document.getElementById('bend').toDataURL());
    await game.keyboard.down('w');
    await game.waitForTimeout(1000);
    await game.evaluate(() => window.dispatchEvent(new Event('blur')));
    assert.equal(await game.evaluate(() => held.size), 0);
    await game.keyboard.up('w');
    assert.notEqual(await game.evaluate(() => document.getElementById('bend').toDataURL()), before, 'movement changes the frame');
    await game.keyboard.down('f');
    assert.equal(await game.evaluate(() => held.has('ControlLeft')), true, 'F reaches the fire binding');
    await game.waitForTimeout(500);
    await game.keyboard.up('f');
    await game.keyboard.press('Escape');
    await game.waitForFunction(() => document.getElementById('status').textContent === 'Game closed.');
    assert.equal(await game.evaluate(() => Module.bendAudio.size), 0);
    assert.deepEqual(errors, []);
    console.log('PASS game: assets, the song from the WAD, audio activation, controls, focus loss and exit');
  } finally {
    if (browser) await browser.close();
    await new Promise(resolve => server.close(resolve));
  }
}

main().catch(error => { console.error(error); process.exitCode = 1; });
