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

// Freedoom 0.13.0 D_E1M1, Chocolate Doom capture with an explicit IWAD:
// tools/listen.nu --wad freedoom1.wad --length 3sec --keep
// FNV-1a over the first 1024 nonzero stereo words, left in the low half.
// IWAD SHA256 f02a511c0f99ce67645d734c387b7b462542228badc54f2f57a25898f50be2fc.
const firstNotes = 1348322204;

// A WAD control with the pistol alone audible, preserving every lump's size.
function pistolWad(wad) {
  assert.equal(wad.toString('ascii', 0, 4), 'IWAD');
  for (let i = 0, at = wad.readUInt32LE(8); i < wad.readUInt32LE(4); i++, at += 16) {
    const start = wad.readUInt32LE(at), size = wad.readUInt32LE(at + 4);
    const name = wad.toString('ascii', at + 8, at + 16).replace(/\0.*/s, '');
    if (name.startsWith('DS') && name !== 'DSPISTOL') wad.fill(128, start + 8, start + size);
    if (name === 'D_E1M1') Buffer.from('4d55531a01001000000000000000000060', 'hex').copy(wad, start);
  }
  return wad;
}

async function main() {
  const [directory] = process.argv.slice(2);
  const root = path.resolve(directory);
  const pistol = pistolWad(fs.readFileSync(path.join(root, 'game.data')));
  let onlyPistol = false;
  const server = http.createServer((request, response) => {
    const pathname = new URL(request.url, 'http://localhost').pathname;
    if (onlyPistol && pathname === '/game.data') { response.end(pistol); return; }
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

    for (const [map, pistolControl] of [[1, false], [6, false], [1, true]]) {
      onlyPistol = pistolControl;
      const game = await browser.newPage({ viewport: { width: 1100, height: 1050 } });
      game.on('pageerror', error => errors.push(error.message));
      await game.addInitScript(holdAudio);
      await game.goto(url);
      await game.waitForFunction(() => !document.getElementById('play').disabled, null, { timeout: 120000 });
      await game.evaluate(map => { Module.arguments.push('-warp', '1', String(map)); }, map);
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
        window.split = 0;
        window.audioFrames = 0;
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
        node.port.onmessage = ({ data: [left, right] }) => {
          audioFrames += left.length;
          left.forEach((l, i) => {
            const word = ((Math.round(l * 32768) & 65535) | (Math.round(right[i] * 32768) & 65535) << 16) >>> 0;
            if (word !== 0 && notes.length < 1024) notes.push(word);
            if (l !== right[i]) split += 1;
          });
        };
        device.node.connect(node);
        node.connect(device.context.destination);
      });
      await game.evaluate(() => { window.allowAudio = true; });
      await game.locator('#sound').click();
      await game.waitForFunction(() => [...Module.bendAudio.values()][0].context.state === 'running');
      if (pistolControl) {
        await game.waitForFunction(() => audioFrames >= 4096);
        assert.deepEqual(await game.evaluate(() => notes), [], 'the control is quiet before firing');
      } else {
        await game.waitForFunction(() => notes.length === 1024, null, { timeout: 20000 });
        if (map === 1) assert.equal(fnv(await game.evaluate(() => notes)), firstNotes, "the song's first notes are Chocolate Doom's");
      }
      const beforeFire = await game.evaluate(() => Module.bendFrames);
      await game.keyboard.down('f');
      assert.equal(await game.evaluate(() => held.has('ControlLeft')), true, 'F reaches the fire binding');
      await game.waitForFunction(before => Module.bendFrames > before + 2, beforeFire);
      if (pistolControl) await game.waitForFunction(() => notes.length === 1024 && split > 0, null, { timeout: 5000 });
      await game.keyboard.up('f');
      const before = await game.evaluate(() => document.getElementById('bend').toDataURL());
      await game.keyboard.down('w');
      await game.waitForTimeout(1000);
      await game.evaluate(() => window.dispatchEvent(new Event('blur')));
      assert.equal(await game.evaluate(() => held.size), 0);
      await game.keyboard.up('w');
      assert.notEqual(await game.evaluate(() => document.getElementById('bend').toDataURL()), before, 'movement changes the frame');
      await game.keyboard.press('Escape');
      await game.waitForFunction(() => document.getElementById('status').textContent === 'Game closed.');
      assert.equal(await game.evaluate(() => Module.bendAudio.size), 0);
      assert.deepEqual(errors, []);
      console.log(pistolControl ? 'PASS game E1M1: quiet control, pistol output from the WAD and clean exit'
        : `PASS game E1M${map}: assets, music, audio activation, controls, movement, focus loss and exit`);
      await game.close();
    }
  } finally {
    if (browser) await browser.close();
    await new Promise(resolve => server.close(resolve));
  }
}

main().catch(error => { console.error(error); process.exitCode = 1; });
