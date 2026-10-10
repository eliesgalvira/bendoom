// Writes the page's art from the IWAD as PNGs: the view border's backdrop
// and bevel, the title screen, menu graphics, and lines in the HUD font.
//
//   node tools/web-art.cjs doom1.wad out/art
const fs = require('node:fs');
const path = require('node:path');
const zlib = require('node:zlib');

const [iwad, out] = process.argv.slice(2);
const wad = fs.readFileSync(iwad);
const lumps = new Map();
for (let i = 0, at = wad.readInt32LE(8); i < wad.readInt32LE(4); i++, at += 16) {
  const start = wad.readInt32LE(at);
  lumps.set(wad.toString('latin1', at + 8, at + 16).replace(/\0.*/s, ''),
    wad.subarray(start, start + wad.readInt32LE(at + 4)));
}
const palette = lumps.get('PLAYPAL');

function image(width, height) {
  return { width, height, rgba: Buffer.alloc(4 * width * height) };
}

function put(art, x, y, index) {
  const at = 4 * (y * art.width + x);
  palette.copy(art.rgba, at, 3 * index, 3 * index + 3);
  art.rgba[at + 3] = 255;
}

// Pieces never overlap, so whole rows are copied, transparent pixels included.
function draw(target, art, x, y) {
  for (let row = 0; row < art.height; row++)
    art.rgba.copy(target.rgba, 4 * ((y + row) * target.width + x), 4 * row * art.width, 4 * (row + 1) * art.width);
}

function flat(name) {
  const art = image(64, 64);
  lumps.get(name).forEach((index, i) => put(art, i % 64, i >> 6, index));
  return art;
}

function patch(name) {
  const lump = lumps.get(name), art = image(lump.readUInt16LE(0), lump.readUInt16LE(2));
  for (let x = 0; x < art.width; x++)
    for (let at = lump.readUInt32LE(8 + 4 * x); lump[at] !== 255; at += lump[at + 1] + 4)
      for (let i = 0; i < lump[at + 1]; i++) put(art, x, lump[at] + i, lump[at + 3 + i]);
  return art;
}

function row(pieces, height) {
  const line = image(pieces.reduce((width, piece) => width + piece.width, 0), height);
  pieces.reduce((x, piece) => (draw(line, piece, x, 0), x + piece.width), 0);
  return line;
}

function text(string) {
  return row([...string.toUpperCase()].map(c => 'STCFN' + String(c.charCodeAt(0)).padStart(3, '0'))
    .map(name => lumps.has(name) ? patch(name) : image(4, 0)), 8);
}

function png(art) {
  const chunk = (type, data) => {
    const body = Buffer.concat([Buffer.from(type, 'latin1'), data]);
    const frame = Buffer.alloc(8 + data.length + 4);
    frame.writeUInt32BE(data.length, 0);
    body.copy(frame, 4);
    frame.writeUInt32BE(zlib.crc32(body), 4 + body.length);
    return frame;
  };
  const header = Buffer.alloc(13);
  header.writeUInt32BE(art.width, 0);
  header.writeUInt32BE(art.height, 4);
  header.set([8, 6, 0, 0, 0], 8);
  const scanlines = Buffer.alloc((4 * art.width + 1) * art.height);
  for (let y = 0; y < art.height; y++)
    art.rgba.copy(scanlines, y * (4 * art.width + 1) + 1, 4 * y * art.width, 4 * (y + 1) * art.width);
  return Buffer.concat([Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]), chunk('IHDR', header),
    chunk('IDAT', zlib.deflateSync(scanlines, { level: 9 })), chunk('IEND', Buffer.alloc(0))]);
}

const bevel = image(14, 14);
for (const [edge, x, y] of [['T', 3, 0], ['B', 3, 11], ['L', 0, 3], ['R', 11, 3],
  ['TL', 0, 0], ['TR', 11, 0], ['BL', 0, 11], ['BR', 11, 11]])
  draw(bevel, patch('BRDR_' + edge), x, y);

const art = {
  floor: flat('FLOOR7_2'),
  bevel,
  title: patch('TITLEPIC'),
  skull: row([patch('M_SKULL1'), patch('M_SKULL2')], 19),
  icon: patch('M_SKULL1'),
  'new-game': patch('M_NGAME'),
  'hurt-me-plenty': patch('M_HURT'),
  bendoom: text('Bendoom'),
  sound: text('Click to enable sound'),
};
fs.mkdirSync(out, { recursive: true });
for (const [name, picture] of Object.entries(art)) fs.writeFileSync(path.join(out, name + '.png'), png(picture));
