# A map's lumps read into trees, its things as recorded, and
# Doom's tables. Data, so the sim and the renderer take it by copy. Each
# lump is one tree of its 16-bit words, record after record, indexed by
# record number times the words kept of a record, plus the field. The
# words a tic changes are a sector's floor, ceiling and light, in the
# sectors' tree, and a line's special, in the specials' tree; every other
# word is the geometry, which no tic writes.
import Base
import ./vec.bend as V
import ./bytes.bend as B
import ./wad.bend as W
import ./fixed.bend as F
import ./angle.bend as A
import ./tables.bend as T

# The lump's 16-bit words as read: the origin (in map units here, fixed
# in Doom), the size, then the cell offsets and the line lists.
type Level.Blockmap is Data:
  Blockmap{words: V.Vec, ox: U32, oy: U32, cols: U32, rows: U32}

type Level.Start is Data:
  Start{x: U32, y: U32, angle: U32}

# A map by its episode and number, Doom's gameepisode and gamemap.
type Level.Name is Data:
  Name{episode: U32, map: U32}

# The THINGS lump's five words a record (x and y in map units, the angle
# in degrees, the DoomEd type and the options), and how many records.
type Level.Things is Data:
  Things{words: V.Vec, count: U32}

# A blockmap cell, by column and row.
type Level.Cell is Data:
  Cell{bx: U32, by: U32}

# A THINGS record: its position in fixed point, its angle in degrees,
# its DoomEd type and its options.
type Level.Thing is Data:
  Thing{x: U32, y: U32, angle: U32, kind: U32, options: U32}

# The words kept of a record: a line's two vertices, flags and two
# sides; a side's two offsets and sector; a sector's floor, ceiling and
# light; a vertex's x and y; a seg's two vertices, angle, line, side and
# offset; a subsector's seg count and first seg; a node's partition (x,
# y, dx, dy), right box, left box (each top, bottom, left, right) and
# two children (a subsector when bit 15 is set). The names are the
# sides' top, bottom and middle textures and the sectors' floor and
# ceiling flats, as the lumps spell them. A sector's box is the top,
# bottom, left and right of its lines' ends, in fixed point. The
# counts are of lines and of sectors. The sector tags are special and
# tag a sector, with the REJECT lump's bytes after them, one an entry:
# a record's width is a budget the whole program shares, so the two
# lumps share one store and Level.rejected reads past the tags.
# The side textures are top, bottom and middle a side as
# the map gives them, and the switches a texture's partner or 0, both in
# the graphics' numbers, which the graphics' loader fills in. Last is
# REJECT, one entry a byte of the lump, which Level.rejected reads.
type Level.Geo is Data:
  Geo{lines: V.Vec, sides: V.Vec, verts: V.Vec, segs: V.Vec, subs: V.Vec, nodes: V.Vec, root: U32,
    blockmap: Level.Blockmap, things: Level.Things, texnames: List<&2, String>,
    flatnames: List<&2, String>, sine: V.Vec, tanto: V.Vec, boxes: V.Vec, nlines: U32, nsectors: U32,
    sectags: V.Vec, sidetex: V.Vec, switches: V.Vec}

# The geometry, the sectors (floor and ceiling in fixed point, as a
# mover leaves them, and light) and the lines' specials (special and tag
# a line), and the sectors that have heard the one player's gunfire.
type Level is Data:
  Level{geo: Level.Geo, sectors: V.Vec, specials: V.Vec, heard: V.Vec}

# A line as the sim sees it: its ends in fixed point, its flags, and the
# sectors on its two sides (65535 for none).
type Level.Line is Data:
  Line{x1: U32, y1: U32, x2: U32, y2: U32, flags: U32, front: U32, back: U32}

# A seg as the renderer sees it: its ends, the lump's angle and offset
# as stored, its line's flags, its side, and the sectors before and
# behind it (65535 for none: a line not flagged two-sided has no back).
type Level.Seg is Data:
  Seg{x1: U32, y1: U32, x2: U32, y2: U32, angle: U32, offset: U32, flags: U32, side: U32,
    front: U32, back: U32}

type Level.Sub is Data:
  Sub{count: U32, first: U32}

type Level.Box is Data:
  Box{top: U32, bottom: U32, left: U32, right: U32}

type Level.Sector is Data:
  Sector{floor: U32, ceil: U32, light: U32}

type Level.Side is Data:
  Side{xoff: U32, yoff: U32, sector: U32}

def Level.none() -> U32:
  65535

def Level.alerted(l: Level) -> V.Vec:
  Level{geo, sectors, specials, heard} = l
  heard

def Level.heard(l: Level, sector: U32) -> Bool:
  U32.is_eq(V.Vec.get(Level.alerted(l), sector), 1)

# Lookups
# -------

# Where field f of record i is in a tree of n words a record.
def Level.at(i: U32, n: U32, f: U32) -> U32:
  (i * n + f : U32)

def Level.word(v: V.Vec, i: U32, n: U32, f: U32) -> U32:
  V.Vec.get(v, Level.at(i, n, f))

def Level.side.sector(+l: Level, +side: U32) -> U32:
  Level{Geo{lines, sides, verts, segs, subs, nodes, root, blockmap, things, texnames, flatnames, sine, tanto, boxes, nlines, nsectors, sectags, sidetex, switches},
    sectors, specials, heard} = l
  Bool.pick(U32, U32.is_eq(side, Level.none()), Level.none(), Level.word(sides, side, 3, 2))

def Level.vertex.x(+l: Level, v: U32) -> U32:
  Level{Geo{lines, sides, verts, segs, subs, nodes, root, blockmap, things, texnames, flatnames, sine, tanto, boxes, nlines, nsectors, sectags, sidetex, switches},
    sectors, specials, heard} = l
  F.Fixed.of_map(Level.word(verts, v, 2, 0))

def Level.vertex.y(+l: Level, v: U32) -> U32:
  Level{Geo{lines, sides, verts, segs, subs, nodes, root, blockmap, things, texnames, flatnames, sine, tanto, boxes, nlines, nsectors, sectags, sidetex, switches},
    sectors, specials, heard} = l
  F.Fixed.of_map(Level.word(verts, v, 2, 1))

def Level.line(+l: Level, +i: U32) -> Level.Line:
  Level{Geo{+lines, sides, verts, segs, subs, nodes, root, blockmap, things, texnames, flatnames, sine, tanto, boxes, nlines, nsectors, sectags, sidetex, switches},
    sectors, specials, heard} = l
  +a = Level.word(lines, i, 5, 0)
  +b = Level.word(lines, i, 5, 1)
  Line{Level.vertex.x(l, a), Level.vertex.y(l, a), Level.vertex.x(l, b), Level.vertex.y(l, b),
    Level.word(lines, i, 5, 2), Level.side.sector(l, Level.word(lines, i, 5, 3)),
    Level.side.sector(l, Level.word(lines, i, 5, 4))}

# A line's side number: 0 the right one, 1 the left.
def Level.line.side(+l: Level, line: U32, side: U32) -> U32:
  Level{Geo{lines, sides, verts, segs, subs, nodes, root, blockmap, things, texnames, flatnames, sine, tanto, boxes, nlines, nsectors, sectags, sidetex, switches},
    sectors, specials, heard} = l
  Level.word(lines, line, 5, (3 + side : U32))

# The linedef a seg lies along.
def Level.seg.line(+l: Level, +i: U32) -> U32:
  Level{Geo{lines, sides, verts, +segs, subs, nodes, root, blockmap, things, texnames, flatnames, sine, tanto, boxes, nlines, nsectors, sectags, sidetex, switches},
    sectors, specials, heard} = l
  Level.word(segs, i, 6, 3)

# Doom's P_LoadSegs: the angle and offset as the lump stores them, the
# back sector only behind a line flagged two-sided.
def Level.seg(+l: Level, +i: U32) -> Level.Seg:
  Level{Geo{+lines, sides, verts, +segs, subs, nodes, root, blockmap, things, texnames, flatnames, sine, tanto, boxes, nlines, nsectors, sectags, sidetex, switches},
    sectors, specials, heard} = l
  +a = Level.word(segs, i, 6, 0)
  +b = Level.word(segs, i, 6, 1)
  +line = Level.word(segs, i, 6, 3)
  +side = Level.word(segs, i, 6, 4)
  +flags = Level.word(lines, line, 5, 2)
  +sidedef = Level.line.side(l, line, side)
  Seg{Level.vertex.x(l, a), Level.vertex.y(l, a), Level.vertex.x(l, b), Level.vertex.y(l, b),
    F.Fixed.of_map(Level.word(segs, i, 6, 2)), F.Fixed.of_map(Level.word(segs, i, 6, 5)), flags,
    sidedef, Level.side.sector(l, sidedef),
    Bool.pick(U32, U32.is_zero((flags .&. 4 : U32)), Level.none(),
      Level.side.sector(l, Level.line.side(l, line, (side .^. 1 : U32))))}

def Level.sub(+l: Level, +i: U32) -> Level.Sub:
  Level{Geo{lines, sides, verts, segs, +subs, nodes, root, blockmap, things, texnames, flatnames, sine, tanto, boxes, nlines, nsectors, sectags, sidetex, switches},
    sectors, specials, heard} = l
  Sub{Level.word(subs, i, 2, 0), Level.word(subs, i, 2, 1)}

# A node's bounding box on a side: 0 the right child's, 1 the left's.
def Level.box(+l: Level, +n: U32, +side: U32) -> Level.Box:
  Level{Geo{lines, sides, verts, segs, subs, +nodes, root, blockmap, things, texnames, flatnames, sine, tanto, boxes, nlines, nsectors, sectags, sidetex, switches},
    sectors, specials, heard} = l
  Box{F.Fixed.of_map(Level.word(nodes, n, 14, (4 + side * 4 : U32))),
    F.Fixed.of_map(Level.word(nodes, n, 14, (5 + side * 4 : U32))),
    F.Fixed.of_map(Level.word(nodes, n, 14, (6 + side * 4 : U32))),
    F.Fixed.of_map(Level.word(nodes, n, 14, (7 + side * 4 : U32)))}

def Level.floor(+l: Level, s: U32) -> U32:
  Level{Geo{lines, sides, verts, segs, subs, nodes, root, blockmap, things, texnames, flatnames, sine, tanto, boxes, nlines, nsectors, sectags, sidetex, switches},
    sectors, specials, heard} = l
  Level.word(sectors, s, 3, 0)

def Level.ceil(+l: Level, s: U32) -> U32:
  Level{Geo{lines, sides, verts, segs, subs, nodes, root, blockmap, things, texnames, flatnames, sine, tanto, boxes, nlines, nsectors, sectags, sidetex, switches},
    sectors, specials, heard} = l
  Level.word(sectors, s, 3, 1)

def Level.sector(+l: Level, +s: U32) -> Level.Sector:
  Level{Geo{lines, sides, verts, segs, subs, nodes, root, blockmap, things, texnames, flatnames, sine, tanto, boxes, nlines, nsectors, sectags, sidetex, switches},
    +sectors, specials, heard} = l
  Sector{Level.word(sectors, s, 3, 0), Level.word(sectors, s, 3, 1), Level.word(sectors, s, 3, 2)}

def Level.sector.light(+l: Level, s: U32) -> U32:
  Level{Geo{lines, sides, verts, segs, subs, nodes, root, blockmap, things, texnames, flatnames, sine, tanto, boxes, nlines, nsectors, sectags, sidetex, switches},
    sectors, specials, heard} = l
  Level.word(sectors, s, 3, 2)

def Level.special(+l: Level, line: U32) -> U32:
  Level{geo, sectors, specials, heard} = l
  Level.word(specials, line, 2, 0)

def Level.tag(+l: Level, line: U32) -> U32:
  Level{geo, sectors, specials, heard} = l
  Level.word(specials, line, 2, 1)

# Doom's line special 48, which P_UpdateSpecials moves a unit left each
# tic on the line's front side: how far a seg's wall has scrolled after
# clock tics, in fixed point.
def Level.seg.scroll(+l: Level, +seg: U32, clock: U32) -> U32:
  Level{Geo{lines, sides, verts, +segs, subs, nodes, root, blockmap, things, texnames, flatnames, sine, tanto, boxes, nlines, nsectors, sectags, sidetex, switches},
    sectors, specials, heard} = l
  F.Fixed.of_map((clock * Bool.to_u32(Bool.and(U32.is_eq(Level.special(l, Level.word(segs, seg, 6, 3)), 48),
    U32.is_zero(Level.word(segs, seg, 6, 4)))) : U32))

def Level.nlines(+l: Level) -> U32:
  Level{Geo{lines, sides, verts, segs, subs, nodes, root, blockmap, things, texnames, flatnames, sine, tanto, boxes, nlines, nsectors, sectags, sidetex, switches},
    sectors, specials, heard} = l
  nlines

def Level.nsectors(+l: Level) -> U32:
  Level{Geo{lines, sides, verts, segs, subs, nodes, root, blockmap, things, texnames, flatnames, sine, tanto, boxes, nlines, nsectors, sectags, sidetex, switches},
    sectors, specials, heard} = l
  nsectors

def Level.sector.special(+l: Level, s: U32) -> U32:
  Level{Geo{lines, sides, verts, segs, subs, nodes, root, blockmap, things, texnames, flatnames, sine, tanto, boxes, nlines, nsectors, sectags, sidetex, switches},
    sectors, specials, heard} = l
  Level.word(sectags, s, 2, 0)

def Level.sector.tag(+l: Level, s: U32) -> U32:
  Level{Geo{lines, sides, verts, segs, subs, nodes, root, blockmap, things, texnames, flatnames, sine, tanto, boxes, nlines, nsectors, sectags, sidetex, switches},
    sectors, specials, heard} = l
  Level.word(sectags, s, 2, 1)

def Level.sidetex(+l: Level) -> V.Vec:
  Level{Geo{lines, sides, verts, segs, subs, nodes, root, blockmap, things, texnames, flatnames, sine, tanto, boxes, nlines, nsectors, sectags, sidetex, switches},
    sectors, specials, heard} = l
  sidetex

def Level.rejected.bit(+reject: V.Vec, +at: U32, +pnum: U32) -> Bool:
  Bool.not(U32.is_zero((V.Vec.get(reject, (at + (pnum >> 3n : U32) : U32))
    .&. (1 << U32.to_nat((pnum .&. 7 : U32)) : U32) : U32)))

# Doom's REJECT test at the head of P_CheckSight: the bit for the pair
# of sectors, row s1 and column s2 of a square of nsectors, set when the
# two can never see each other. Its bytes sit after the sector tags, two
# words a sector. A level with no REJECT lump rejects nothing.
def Level.rejected(+l: Level, +s1: U32, +s2: U32) -> Bool:
  Level{Geo{lines, sides, verts, segs, subs, nodes, root, blockmap, things, texnames, flatnames, sine, tanto, boxes, nlines, +nsectors, +sectags, sidetex, switches},
    sectors, specials, heard} = l
  Level.rejected.bit(sectags, (nsectors + nsectors : U32), ((s1 * nsectors : U32) + s2 : U32))

# A switch texture's partner, 0 for a texture that is no switch.
def Level.switch(+l: Level, texture: U32) -> U32:
  Level{Geo{lines, sides, verts, segs, subs, nodes, root, blockmap, things, texnames, flatnames, sine, tanto, boxes, nlines, nsectors, sectags, sidetex, switches},
    sectors, specials, heard} = l
  V.Vec.get(switches, texture)

# The level with the graphics' numbers for its sides' textures and its
# switches' partners.
def Level.textured(l: Level, sidetex: V.Vec, switches: V.Vec) -> Level:
  Level{Geo{lines, sides, verts, segs, subs, nodes, root, blockmap, things, texnames, flatnames, sine, tanto, boxes, nlines, nsectors, sectags, none, no},
    sectors, specials, heard} = l
  Level{Geo{lines, sides, verts, segs, subs, nodes, root, blockmap, things, texnames, flatnames, sine, tanto, boxes, nlines, nsectors, sectags, sidetex, switches},
    sectors, specials, heard}

# A sector's plane: its ceiling or its floor.
def Level.plane(+l: Level, s: U32, ceiling: Bool) -> U32:
  Level{geo, sectors, specials, heard} = l
  Level.word(sectors, s, 3, Bool.to_u32(ceiling))

# The writes a tic makes, each a new tree sharing all but one path with
# the old: a sector's plane, its light, and a line's special.
def Level.plane.put(l: Level, s: U32, ceiling: Bool, height: U32) -> Level:
  Level{geo, sectors, specials, heard} = l
  Level{geo, V.Vec.set(sectors, Level.at(s, 3, Bool.to_u32(ceiling)), height), specials, heard}

def Level.light.put(l: Level, s: U32, light: U32) -> Level:
  Level{geo, sectors, specials, heard} = l
  Level{geo, V.Vec.set(sectors, Level.at(s, 3, 2), light), specials, heard}

def Level.special.put(l: Level, line: U32, special: U32) -> Level:
  Level{geo, sectors, specials, heard} = l
  Level{geo, sectors, V.Vec.set(specials, Level.at(line, 2, 0), special), heard}

def Level.geo(l: Level) -> Level.Geo:
  Level{geo, sectors, specials, heard} = l
  geo

def Level.sectors(l: Level) -> V.Vec:
  Level{geo, sectors, specials, heard} = l
  sectors

def Level.specials(l: Level) -> V.Vec:
  Level{geo, sectors, specials, heard} = l
  specials

# Doom's P_GroupLines block box: the blockmap cells a sector's box
# touches, widened by the largest radius, 32 units, and held to the map:
# the top no higher than the last row, the bottom no lower than row 0,
# and so for the columns. Signed: a box wholly off the map's low side
# keeps a negative top or right.
def Level.blockbox.at(+bm: Level.Blockmap, +boxes: V.Vec, +at: U32) -> Level.Box:
  Blockmap{words, +ox, +oy, +cols, +rows} = bm
  Box{F.Fixed.min(F.Fixed.sarn((V.Vec.get(boxes, at) - oy + 2097152 : U32), 23n), (rows - 1 : U32)),
    F.Fixed.max(F.Fixed.sarn((V.Vec.get(boxes, (at + 1 : U32)) - oy - 2097152 : U32), 23n), 0),
    F.Fixed.max(F.Fixed.sarn((V.Vec.get(boxes, (at + 2 : U32)) - ox - 2097152 : U32), 23n), 0),
    F.Fixed.min(F.Fixed.sarn((V.Vec.get(boxes, (at + 3 : U32)) - ox + 2097152 : U32), 23n), (cols - 1 : U32))}

def Level.blockbox(+l: Level, s: U32) -> Level.Box:
  Level{Geo{lines, sides, verts, segs, subs, nodes, root, blockmap, things, texnames, flatnames, sine, tanto, boxes, nlines, nsectors, sectags, sidetex, switches},
    sectors, specials, heard} = l
  Level.blockbox.at(blockmap, boxes, (s * 4 : U32))

# Doom's soundorg: the middle of a sector's box, where its sounds come
# from.
def Level.soundorg(+l: Level, +s: U32) -> U32 & U32:
  Level{Geo{lines, sides, verts, segs, subs, nodes, root, blockmap, things, texnames, flatnames, sine, tanto, +boxes, nlines, nsectors, sectags, sidetex, switches},
    sectors, specials, heard} = l
  (F.Fixed.half((V.Vec.get(boxes, (s * 4 + 3 : U32)) + V.Vec.get(boxes, (s * 4 + 2 : U32)) : U32)),
    F.Fixed.half((V.Vec.get(boxes, (s * 4 : U32)) + V.Vec.get(boxes, (s * 4 + 1 : U32)) : U32)))

def Level.side(+l: Level, +i: U32) -> Level.Side:
  Level{Geo{lines, +sides, verts, segs, subs, nodes, root, blockmap, things, texnames, flatnames, sine, tanto, boxes, nlines, nsectors, sectags, sidetex, switches},
    sectors, specials, heard} = l
  Side{F.Fixed.of_map(Level.word(sides, i, 3, 0)), F.Fixed.of_map(Level.word(sides, i, 3, 1)),
    Level.word(sides, i, 3, 2)}

def Level.texnames(+l: Level) -> List<&2, String>:
  Level{Geo{lines, sides, verts, segs, subs, nodes, root, blockmap, things, texnames, flatnames, sine, tanto, boxes, nlines, nsectors, sectags, sidetex, switches},
    sectors, specials, heard} = l
  texnames

def Level.flatnames(+l: Level) -> List<&2, String>:
  Level{Geo{lines, sides, verts, segs, subs, nodes, root, blockmap, things, texnames, flatnames, sine, tanto, boxes, nlines, nsectors, sectags, sidetex, switches},
    sectors, specials, heard} = l
  flatnames

# A side's top, bottom and middle texture names.
def Level.side_names(+l: Level, i: U32) -> List<&2, String>:
  List.take(&2, String, List.drop(&2, String, Level.texnames(l), U32.to_nat((i * 3 : U32))), 3n)

# A sector's floor and ceiling flat names.
def Level.flat_names(+l: Level, s: U32) -> List<&2, String>:
  List.take(&2, String, List.drop(&2, String, Level.flatnames(l), U32.to_nat((s * 2 : U32))), 2n)

# Whether a sector's ceiling shows the sky: Doom's ceilingpic ==
# skyflatnum, read from the lump's own name, since the sim has no
# graphics to number it with.
def Level.sky(+l: Level, s: U32) -> Bool:
  String.eq(Maybe.default(&2, String, List.get(&2, String, Level.flat_names(l, s), 1n), ""), "F_SKY1")

def Level.sine(+l: Level) -> V.Vec:
  Level{Geo{lines, sides, verts, segs, subs, nodes, root, blockmap, things, texnames, flatnames, sine, tanto, boxes, nlines, nsectors, sectags, sidetex, switches},
    sectors, specials, heard} = l
  sine

def Level.tanto(+l: Level) -> V.Vec:
  Level{Geo{lines, sides, verts, segs, subs, nodes, root, blockmap, things, texnames, flatnames, sine, tanto, boxes, nlines, nsectors, sectags, sidetex, switches},
    sectors, specials, heard} = l
  tanto

def Level.nthings(+l: Level) -> U32:
  Level{Geo{lines, sides, verts, segs, subs, nodes, root, blockmap, Things{words, count}, texnames, flatnames, sine, tanto, boxes, nlines, nsectors, sectags, sidetex, switches},
    sectors, specials, heard} = l
  count

def Level.things.record(+t: Level.Things, +i: U32) -> Level.Thing:
  Things{+words, count} = t
  Thing{F.Fixed.of_map(Level.word(words, i, 5, 0)), F.Fixed.of_map(Level.word(words, i, 5, 1)),
    Level.word(words, i, 5, 2), Level.word(words, i, 5, 3), Level.word(words, i, 5, 4)}

# THINGS record i, as the map gives it.
def Level.thing(+l: Level, +i: U32) -> Level.Thing:
  Level{Geo{lines, sides, verts, segs, subs, nodes, root, blockmap, things, texnames, flatnames, sine, tanto, boxes, nlines, nsectors, sectags, sidetex, switches},
    sectors, specials, heard} = l
  Level.things.record(things, i)

def Level.is_start(t: Level.Thing) -> Bool:
  Thing{x, y, angle, kind, options} = t
  U32.is_eq(kind, 1)

def Level.start.of(t: Level.Thing) -> Level.Start:
  Thing{x, y, angle, kind, options} = t
  Start{x, y, A.Angle.of_thing(angle)}

def Level.start.go(k: Nat, +l: Level, +i: U32, hit: Bool) -> Level.Start:
  match k hit:
    case _ True{}:
      Level.start.of(Level.thing(l, i))
    case 0n _:
      Start{0, 0, 0}
    case 1n+j False{}:
      Level.start.go(j, l, (i + 1 : U32), Level.is_start(Level.thing(l, (i + 1 : U32))))

# Player 1's start: the first thing of type 1.
def Level.start_of(+l: Level) -> Level.Start:
  Level.start.go(U32.to_nat(Level.nthings(l)), l, 0, Level.is_start(Level.thing(l, 0)))

def Level.blockmap_of(+l: Level) -> Level.Blockmap:
  Level{Geo{lines, sides, verts, segs, subs, nodes, root, blockmap, things, texnames, flatnames, sine, tanto, boxes, nlines, nsectors, sectags, sidetex, switches},
    sectors, specials, heard} = l
  blockmap

def Level.root(+l: Level) -> U32:
  Level{Geo{lines, sides, verts, segs, subs, nodes, root, blockmap, things, texnames, flatnames, sine, tanto, boxes, nlines, nsectors, sectags, sidetex, switches},
    sectors, specials, heard} = l
  root

# The lines listed in a blockmap cell: the words from the cell's offset
# up to the 65535, the leading 0 included, since Doom's
# P_BlockLinesIterator checks line 0 in every cell it walks.
def Level.cell.go(k: Nat, end: Bool, +words: V.Vec, +i: U32, +w: U32) ->
  List<&2, U32>:
  match k end:
    case _ True{}:
      []
    case 0n _:
      []
    case 1n+j False{}:
      +w2 = V.Vec.get(words, (i + 1 : U32))
      w <> Level.cell.go(j, U32.is_eq(w2, 65535), words, (i + 1 : U32), w2)

def Level.cell.list(inside: Bool, +words: V.Vec, +i: U32) -> List<&2, U32>:
  match inside:
    case False{}:
      []
    case True{}:
      +off = V.Vec.get(words, i)
      +w = V.Vec.get(words, off)
      Level.cell.go(U32.to_nat(4096), U32.is_eq(w, 65535), words, off, w)

# The cell a point is in, by signed column and row.
def Level.cell_of(+bm: Level.Blockmap, x: U32, y: U32) -> Level.Cell:
  Blockmap{words, +ox, +oy, cols, rows} = bm
  Cell{F.Fixed.sarn((x - ox : U32), 23n), F.Fixed.sarn((y - oy : U32), 23n)}

# Whether a cell is on a map of so many columns and rows. Its
# coordinates are signed: a negative one reads as a huge unsigned one,
# so the unsigned bound checks both ends.
def Level.cell.inside(+cols: U32, +rows: U32, +c: Level.Cell) -> Bool:
  Cell{+bx, +by} = c
  Bool.and(U32.is_lt(bx, cols), U32.is_lt(by, rows))

def Level.cell.number(+cols: U32, +c: Level.Cell) -> U32:
  Cell{+bx, +by} = c
  (by * cols + bx : U32)

# The lines of a cell of the geometry's blockmap.
def Level.cell.lines(+geo: Level.Geo, +c: Level.Cell) -> List<&2, U32>:
  Geo{lines, sides, verts, segs, subs, nodes, root, Blockmap{+words, ox, oy, +cols, +rows}, things, texnames, flatnames, sine, tanto, boxes, nlines, nsectors, sectags, sidetex, switches} = geo
  Level.cell.list(Level.cell.inside(cols, rows, c), words, (4 + Level.cell.number(cols, c) : U32))

# The sector under a point
# ------------------------

# Which side of a line through (x0, y0) along (dx, dy) a point is on,
# True for the back: an axis-aligned line is decided by one coordinate,
# any other by the caller's cross product. Doom's P_PointOnLineSide,
# P_PointOnDivlineSide and R_PointOnSide share this shape.
def Level.axis_side(+x: U32, +y: U32, +x0: U32, +y0: U32, +dx: U32, +dy: U32, slow: Bool) -> Bool:
  Bool.pick(Bool, U32.is_zero(dx),
    Bool.pick(Bool, F.Fixed.le(x, x0), F.Fixed.gt(dy, 0), F.Fixed.lt(dy, 0)),
    Bool.pick(Bool, U32.is_zero(dy),
      Bool.pick(Bool, F.Fixed.le(y, y0), F.Fixed.lt(dx, 0), F.Fixed.gt(dx, 0)), slow))

# Doom's R_PointOnSide: the cross product with the sign-bit shortcut and
# the halved multiply of the original.
def Level.node_side.slow(+x: U32, +y: U32, +dx: U32, +dy: U32) -> Bool:
  Bool.pick(Bool, U32.is_zero(((dy .^. dx .^. x .^. y) .&. 2147483648 : U32)),
    Bool.not(F.Fixed.lt(F.Fixed.mul(y, F.Fixed.sarn(dx, 16n)),
      F.Fixed.mul(F.Fixed.sarn(dy, 16n), x))),
    Bool.not(U32.is_zero(((dy .^. x) .&. 2147483648 : U32))))

def Level.node_side(+x: U32, +y: U32, +nx: U32, +ny: U32, +dx: U32, +dy: U32) -> Bool:
  Level.axis_side(x, y, nx, ny, dx, dy, Level.node_side.slow((x - nx : U32), (y - ny : U32), dx, dy))

# A node's child on the side of a point: 0 the right, 1 the left.
def Level.node.child(+l: Level, n: U32, side: U32) -> U32:
  Level{Geo{lines, sides, verts, segs, subs, nodes, root, blockmap, things, texnames, flatnames, sine, tanto, boxes, nlines, nsectors, sectags, sidetex, switches},
    sectors, specials, heard} = l
  Level.word(nodes, n, 14, (12 + side : U32))

# A node's partition line: x, y, dx and dy in fixed point as words 0 to
# 3 of its record.
def Level.node.part(+l: Level, +n: U32, +i: U32) -> U32:
  Level{Geo{lines, sides, verts, segs, subs, +nodes, root, blockmap, things, texnames, flatnames, sine, tanto, boxes, nlines, nsectors, sectags, sidetex, switches},
    sectors, specials, heard} = l
  Level.word(nodes, n, 14, i)

# Doom's R_PointOnSide against node n: 1 on the back (left) side.
def Level.side_of(+l: Level, +n: U32, +x: U32, +y: U32) -> U32:
  Bool.to_u32(Level.node_side(x, y, F.Fixed.of_map(Level.node.part(l, n, 0)),
    F.Fixed.of_map(Level.node.part(l, n, 1)), F.Fixed.of_map(Level.node.part(l, n, 2)),
    F.Fixed.of_map(Level.node.part(l, n, 3))))

def Level.is_leaf(+n: U32) -> Bool:
  U32.is_ge(n, 32768)

# A subsector's sector: its first seg's front sector.
def Level.leaf_sector(+l: Level, ss: U32) -> U32:
  Level{Geo{lines, sides, verts, +segs, +subs, nodes, root, blockmap, things, texnames, flatnames, sine, tanto, boxes, nlines, nsectors, sectags, sidetex, switches},
    sectors, specials, heard} = l
  +seg = Level.word(subs, ss, 2, 1)
  Level.side.sector(l, Level.line.side(l, Level.word(segs, seg, 6, 3), Level.word(segs, seg, 6, 4)))

def Level.descend(fuel: Nat, leaf: Bool, +l: Level, +x: U32, +y: U32, +n: U32) -> U32:
  match fuel leaf:
    case _ True{}:
      Level.leaf_sector(l, (n .&. 32767 : U32))
    case 0n _:
      0
    case 1n+f False{}:
      +m = Level.node.child(l, n, Level.side_of(l, n, x, y))
      Level.descend(f, Level.is_leaf(m), l, x, y, m)

# Doom's R_PointInSubsector, then the subsector's sector.
def Level.sector_at(+l: Level, +x: U32, +y: U32) -> U32:
  +root = Level.root(l)
  Level.descend(U32.to_nat((root + 1 : U32)), Level.is_leaf(root), l, x, y, root)

# Loading
# -------

def Level.map.drop(lumps: List<&2, W.Wad.Lump>, i: Maybe<Nat>) ->
  List<&2, W.Wad.Lump>:
  match i:
    case None{}:
      []
    case Some{k}:
      List.drop(&2, W.Wad.Lump, lumps, k)

# The marker lump that starts a map's lumps, as G_DoLoadLevel names it:
# ExMy.
def Level.marker(+episode: U32, +map: U32) -> String:
  "E" ++ U32.show(episode) ++ "M" ++ U32.show(map)

# The lumps from the map's marker on, none for a marker the WAD lacks.
def Level.map(+episode: U32, +map: U32, +lumps: List<&2, W.Wad.Lump>) -> List<&2, W.Wad.Lump>:
  Level.map.drop(lumps, W.Wad.index(Level.marker(episode, map), lumps))

# The offsets of the given fields in every record of a lump.
def Level.fields(ps: U32 & U32, +stride: U32, fields: List<&2, U32>) -> List<&2, U32>:
  (pos, size) = ps
  B.Bytes.fields(U32.to_nat((size / stride : U32)), pos, stride, fields)

# Every word the level keeps, lump by lump in the order Level.pack
# takes them. REJECT follows the sector tags in one store, and is read a
# byte at a time, so each of its entries holds its own byte in the low
# eight bits and the next one above them, which the bit index never
# reaches.
def Level.plan(+map: List<&2, W.Wad.Lump>) -> List<&2, List<&2, U32>>:
  [Level.fields(W.Wad.find(map, "THINGS"), 10, [0, 2, 4, 6, 8]),
    Level.fields(W.Wad.find(map, "LINEDEFS"), 14, [0, 2, 4, 10, 12]),
    Level.fields(W.Wad.find(map, "SIDEDEFS"), 30, [0, 2, 28]),
    Level.fields(W.Wad.find(map, "VERTEXES"), 4, [0, 2]),
    Level.fields(W.Wad.find(map, "SEGS"), 12, [0, 2, 4, 6, 8, 10]),
    Level.fields(W.Wad.find(map, "SSECTORS"), 4, [0, 2]),
    Level.fields(W.Wad.find(map, "NODES"), 28, [0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26]),
    Level.fields(W.Wad.find(map, "SECTORS"), 26, [0, 2, 20]),
    Level.fields(W.Wad.find(map, "BLOCKMAP"), 2, [0]),
    Level.fields(W.Wad.find(map, "LINEDEFS"), 14, [6, 8]),
    List.append(&2, U32, Level.fields(W.Wad.find(map, "SECTORS"), 26, [22, 24]),
      Level.fields(W.Wad.find(map, "REJECT"), 1, [0]))]

def Level.vecs(lists: List<&2, List<&2, U32>>) -> List<&2, V.Vec>:
  match lists:
    case []:
      []
    case words <> rest:
      V.Vec.of(words) <> Level.vecs(rest)

def Level.count.fin(stride: U32, ps: U32 & U32) -> U32:
  (pos, size) = ps
  (size / stride : U32)

def Level.count(+map: List<&2, W.Wad.Lump>, +name: String, stride: U32) -> U32:
  Level.count.fin(stride, W.Wad.find(map, name))

def Level.blockmap(+bm: V.Vec) -> Level.Blockmap:
  Blockmap{bm, F.Fixed.of_map(V.Vec.get(bm, 0)), F.Fixed.of_map(V.Vec.get(bm, 1)),
    V.Vec.get(bm, 2), V.Vec.get(bm, 3)}

# One sector with no lines, its floor and ceiling as given in map units,
# and Doom's tables: the level of the room's tests and of eye_rest, and
# what a malformed WAD loads as. A Leaf answers every index, so one is a
# whole lump of zeros; root 32768 is subsector 0.
def Level.room(floor: U32, ceil: U32) -> Level:
  Level{Geo{V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, 32768,
    Blockmap{V.Leaf{0}, 0, 0, 0, 0}, Things{V.Leaf{0}, 0}, [], [],
    V.Vec.of_list(T.Tables.finesine(), 10240), V.Vec.of_list(T.Tables.tantoangle(), 2049), V.Leaf{0}, 0, 1,
    V.Leaf{0}, V.Leaf{0}, V.Leaf{0}},
    V.Vec.of_list([F.Fixed.of_map(floor), F.Fixed.of_map(ceil), 0], 3), V.Leaf{0}, V.Leaf{0}}

# Doom's P_GroupLines box: each line's ends widen the box of the sector
# on either side of it, from a box turned inside out.
def Level.boxes.widen(+boxes: V.Vec, +at: U32, +x: U32, +y: U32) -> V.Vec:
  V.Vec.set(V.Vec.set(V.Vec.set(V.Vec.set(boxes,
    at, F.Fixed.max(V.Vec.get(boxes, at), y)),
    (at + 1 : U32), F.Fixed.min(V.Vec.get(boxes, (at + 1 : U32)), y)),
    (at + 2 : U32), F.Fixed.min(V.Vec.get(boxes, (at + 2 : U32)), x)),
    (at + 3 : U32), F.Fixed.max(V.Vec.get(boxes, (at + 3 : U32)), x))

def Level.boxes.side(none: Bool, boxes: V.Vec, +s: U32, +x1: U32, +y1: U32, +x2: U32, +y2: U32) -> V.Vec:
  match none:
    case True{}:
      boxes
    case False{}:
      Level.boxes.widen(Level.boxes.widen(boxes, (s * 4 : U32), x1, y1), (s * 4 : U32), x2, y2)

def Level.boxes.line(line: Level.Line, boxes: V.Vec) -> V.Vec:
  Line{+x1, +y1, +x2, +y2, flags, +front, +back} = line
  Level.boxes.side(U32.is_eq(back, Level.none()),
    Level.boxes.side(U32.is_eq(front, Level.none()), boxes, front, x1, y1, x2, y2), back, x1, y1, x2, y2)

def Level.boxes(n: Nat, +l: Level, +i: U32, boxes: V.Vec) -> V.Vec:
  match n:
    case 0n:
      boxes
    case 1n+m:
      Level.boxes(m, l, (i + 1 : U32), Level.boxes.line(Level.line(l, i), boxes))

def Level.inside_out(n: Nat) -> List<&2, U32>:
  match n:
    case 0n:
      []
    case 1n+m:
      2147483648 <> 2147483647 <> 2147483647 <> 2147483648 <> Level.inside_out(m)

def Level.boxed(+l: Level, boxes: V.Vec) -> Level:
  Level{Geo{lines, sides, verts, segs, subs, nodes, root, blockmap, things, texnames, flatnames, sine, tanto, none, nlines, nsectors, sectags, sidetex, switches},
    sectors, specials, heard} = l
  Level{Geo{lines, sides, verts, segs, subs, nodes, root, blockmap, things, texnames, flatnames, sine, tanto, boxes, nlines, nsectors, sectags, sidetex, switches},
    sectors, specials, heard}

# A sector's floor and ceiling as the lump's 16-bit words made fixed
# point.
def Level.fixed(n: Nat, +i: U32, +sectors: V.Vec) -> V.Vec:
  match n:
    case 0n:
      sectors
    case 1n+m:
      Level.fixed(m, (i + 3 : U32), V.Vec.set(V.Vec.set(sectors, i, F.Fixed.of_map(V.Vec.get(sectors, i))),
        (i + 1 : U32), F.Fixed.of_map(V.Vec.get(sectors, (i + 1 : U32)))))

# The level with its sectors' boxes, from its lines.
def Level.grouped(+l: Level) -> Level:
  Level.boxed(l, Level.boxes(U32.to_nat(Level.nlines(l)), l, 0,
    V.Vec.of_list(Level.inside_out(U32.to_nat(Level.nsectors(l))), (Level.nsectors(l) * 4 : U32))))

def Level.pack.go(+map: List<&2, W.Wad.Lump>, vs: List<&2, V.Vec>, texnames: List<&2, String>,
  flatnames: List<&2, String>) -> Level:
  match vs:
    case [things, lines, sides, verts, segs, subs, nodes, sectors, bm, specials, sectags]:
      Level.grouped(Level{Geo{lines, sides, verts, segs, subs, nodes,
        (Level.count(map, "NODES", 28) - 1 : U32), Level.blockmap(bm),
        Things{things, Level.count(map, "THINGS", 10)}, texnames, flatnames,
        V.Vec.of_list(T.Tables.finesine(), 10240), V.Vec.of_list(T.Tables.tantoangle(), 2049), V.Leaf{0},
        Level.count(map, "LINEDEFS", 14), Level.count(map, "SECTORS", 26), sectags, V.Leaf{0}, V.Leaf{0}},
        Level.fixed(U32.to_nat(Level.count(map, "SECTORS", 26)), 0, sectors), specials, V.Vec.of_list([], Level.count(map, "SECTORS", 26))})
    case _:
      Level.room(0, 0)

def Level.pack(+map: List<&2, W.Wad.Lump>, vs: List<&2, V.Vec>, texnames: List<&2, String>,
  p: Array<U32> & List<&2, String>) -> Array<U32> & Level:
  (a, flatnames) = p
  (a, Level.pack.go(map, vs, texnames, flatnames))

def Level.flats(+map: List<&2, W.Wad.Lump>, vs: List<&2, V.Vec>, p: Array<U32> & List<&2, String>) ->
  Array<U32> & Level:
  (a, texnames) = p
  Level.pack(map, vs, texnames, B.Bytes.each(~String, ~B.Bytes.name,
    Level.fields(W.Wad.find(map, "SECTORS"), 26, [4, 12]), a))

def Level.names(+map: List<&2, W.Wad.Lump>, p: Array<U32> & List<&2, List<&2, U32>>) ->
  Array<U32> & Level:
  (a, lists) = p
  Level.flats(map, Level.vecs(lists), B.Bytes.each(~String, ~B.Bytes.name,
    Level.fields(W.Wad.find(map, "SIDEDEFS"), 30, [4, 12, 20]), a))

# Map ExMy of the WAD from its bytes and directory.
def Level.load(+episode: U32, +map: U32, p: Array<U32> & List<&2, W.Wad.Lump>) -> Array<U32> & Level:
  (a, +lumps) = p
  +found = Level.map(episode, map, lumps)
  Level.names(found, B.Bytes.lists(~U32, ~B.Bytes.u16, Level.plan(found), a))
