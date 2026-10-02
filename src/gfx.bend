# The graphics a map names, copied from the WAD into one linear array the
# draw threads, since a texel read through a copyable tree costs three
# hundred times one through an array (bench/lookup.bend). The array
# holds the frame and the draw's per-column scratch first, then the
# fourteen palettes as RGB words, the colormaps, and the lumps: the flats the
# sectors name, then the patches of the textures the sides name, then
# the composed columns, then the sprite lumps of the frames the map's
# things spawn in or reach and of the weapon's, every rotation, then the
# status bar's; with the map's names go every frame of the animations
# they touch and the partners of their switches.
# Gfx is the directory into it: Data, so the draw takes it by copy.
# Every other flat, texture and sprite stays a name in the WAD.
import Base
import ./vec.bend as V
import ./bytes.bend as B
import ./wad.bend as W
import ./fixed.bend as F
import ./level.bend as L
import ./things.bend as H

# The animations of the flats or of the textures: three words a frame
# (its animation's count, the WAD's number for it, its place in the
# animation), the frames being the numbers from first on; and what every
# number shows, itself but for the frames, as Doom's translation tables.
type Gfx.Anim is Data:
  Anim{rows: List<&2, U32>, first: U32, shown: V.Vec}

# Both, shown as they are after the clock's tics.
type Gfx.Anims is Data:
  Anims{flats: Gfx.Anim, texs: Gfx.Anim, clock: U32}

# flats: a flat number's index in the array. pics: a sector's floor and
# ceiling flat numbers, two a sector. sky: the sky flat's number. texs:
# five words a texture (width, height, patch count, width mask, first
# column), texture 0 being none. cols: every texture's columns, each the
# index of its texels in the array. sidetex: a side's top, bottom and
# middle texture numbers, three a side. skytex: the sky's texture.
# sprites: for each rotation of each state row loaded, six words: the
# index of its lump's patch, the patch's width, left offset and top
# offset in fixed point (Doom's spritewidth, spriteoffset and
# spritetopoffset), 1 when it is mirrored, and 1 for a full-bright frame.
# bar: the index in the array of each of the status bar's patches, in the
# order Gfx.bar.names() lists them. font: the index of each heads-up
# font patch, one a character from HU_FONTSTART.
type Gfx is Data:
  Gfx{flats: V.Vec, pics: V.Vec, sky: U32, texs: V.Vec, cols: V.Vec, sidetex: V.Vec, skytex: U32,
    sprites: V.Vec, anims: Gfx.Anims, bar: V.Vec, font: V.Vec}

# The frame: 320 by 200 palette indices, row by row.
def Gfx.frame() -> U32:
  0

# The draw's clip arrays, one slot a column.
def Gfx.ceilclip() -> U32:
  64000

def Gfx.floorclip() -> U32:
  64320

# Where each row's open span starts, while a plane is drawn.
def Gfx.spanstart() -> U32:
  64640

# The clips of the sprite being drawn, one slot a column: Doom's
# cliptop and clipbot.
def Gfx.cliptop() -> U32:
  64832

def Gfx.clipbot() -> U32:
  65152

# PLAYPAL's fourteen palettes as RGB words, 256 a palette: the plain
# one, the eight reds, the four golds and the radiation suit's green.
# ST_doPaletteStuff picks which one a frame is shown in.
def Gfx.palette() -> U32:
  65536

def Gfx.colormap() -> U32:
  69120

# 128 zeros: the texels of a column no patch covers.
def Gfx.void() -> U32:
  77824

def Gfx.lumps() -> U32:
  77952

def Gfx.none() -> U32:
  4294967295

# Names to numbers
# ----------------

# The names met so far with their numbers, the next number, and, newest
# first, each name's number and the names in number order.
type Gfx.Names is Data:
  Names{seen: Map<&2, U32>, next: U32, numbers: List<&2, U32>, distinct: List<&2, String>}

def Gfx.names.put(new: Bool, +name: String, k: U32, seen: Map<&2, U32>, +next: U32,
  numbers: List<&2, U32>, distinct: List<&2, String>) -> Gfx.Names:
  match new:
    case True{}:
      Names{Map.set(&2, U32, seen, name, next), (next + 1 : U32), next <> numbers, name <> distinct}
    case False{}:
      Names{seen, next, k <> numbers, distinct}

def Gfx.names.found(name: String, next: U32, numbers: List<&2, U32>, distinct: List<&2, String>,
  p: Map<&2, U32> & U32) -> Gfx.Names:
  (seen, +k) = p
  Gfx.names.put(U32.is_eq(k, Gfx.none()), name, k, seen, next, numbers, distinct)

def Gfx.names.add(+name: String, st: Gfx.Names) -> Gfx.Names:
  Names{seen, next, numbers, distinct} = st
  Gfx.names.found(name, next, numbers, distinct, Map.get(U32, Gfx.none(), seen, name))

# Each name numbered by its first appearance.
def Gfx.names(names: List<&2, String>, st: Gfx.Names) -> Gfx.Names:
  match names:
    case []:
      st
    case name <> rest:
      Gfx.names(rest, Gfx.names.add(name, st))

def Gfx.Names.numbers(n: Gfx.Names) -> List<&2, U32>:
  Names{seen, next, numbers, distinct} = n
  List.reverse(&2, U32, numbers)

def Gfx.Names.distinct(n: Gfx.Names) -> List<&2, String>:
  Names{seen, next, numbers, distinct} = n
  List.reverse(&2, String, distinct)

def Gfx.Names.number(n: Gfx.Names, name: String) -> U32:
  Names{seen, next, numbers, distinct} = n
  Pair.snd(Map<&2, U32>, U32, Map.get(U32, Gfx.none(), seen, name))

def Gfx.Names.next(n: Gfx.Names) -> U32:
  Names{seen, next, numbers, distinct} = n
  next

# The numbering kept, the list of numbers begun again.
def Gfx.Names.fresh(n: Gfx.Names) -> Gfx.Names:
  Names{seen, next, numbers, distinct} = n
  Names{seen, next, [], distinct}

# Switches
# --------

# Doom's alphSwitchList for episode 1, each switch before its partner.
def Gfx.switch.pairs() -> List<&2, String>:
  ["SW1BRCOM", "SW2BRCOM", "SW1BRN1", "SW2BRN1", "SW1BRN2", "SW2BRN2", "SW1BRNGN", "SW2BRNGN",
    "SW1BROWN", "SW2BROWN", "SW1COMM", "SW2COMM", "SW1COMP", "SW2COMP", "SW1DIRT", "SW2DIRT",
    "SW1EXIT", "SW2EXIT", "SW1GRAY", "SW2GRAY", "SW1GRAY1", "SW2GRAY1", "SW1METAL", "SW2METAL",
    "SW1PIPE", "SW2PIPE", "SW1SLAD", "SW2SLAD", "SW1STARG", "SW2STARG", "SW1STON1", "SW2STON1",
    "SW1STON2", "SW2STON2", "SW1STONE", "SW2STONE", "SW1STRTN", "SW2STRTN"]

def Gfx.switch.if(named: Bool, partner: String, rest: List<&2, String>) -> List<&2, String>:
  match named:
    case False{}:
      rest
    case True{}:
      partner <> rest

# The partner of each switch among the names numbered so far, so that a
# swap never names a texture that was not composed.
def Gfx.switch.wanted(pairs: List<&2, String>, +tn: Gfx.Names) -> List<&2, String>:
  match pairs:
    case +a <> +b <> rest:
      Gfx.switch.if(Bool.not(U32.is_eq(Gfx.Names.number(tn, a), Gfx.none())), b,
        Gfx.switch.if(Bool.not(U32.is_eq(Gfx.Names.number(tn, b), Gfx.none())), a,
          Gfx.switch.wanted(rest, tn)))
    case _:
      []

def Gfx.switch.pair(named: Bool, +a: U32, +b: U32, table: V.Vec) -> V.Vec:
  match named:
    case False{}:
      table
    case True{}:
      V.Vec.set(V.Vec.set(table, a, b), b, a)

# Each numbered switch's partner by texture number, 0 elsewhere.
def Gfx.switch.table(pairs: List<&2, String>, +tn: Gfx.Names, table: V.Vec) -> V.Vec:
  match pairs:
    case +a <> b <> rest:
      Gfx.switch.table(rest, tn, Gfx.switch.pair(Bool.not(U32.is_eq(Gfx.Names.number(tn, a), Gfx.none())),
        Gfx.Names.number(tn, a), Gfx.Names.number(tn, b), table))
    case _:
      table

# Animations
# ----------

# Doom's animdefs from p_spec.c, each animation's last frame before its
# first: the flats, and the textures.
def Gfx.anim.flats() -> List<&2, String>:
  ["NUKAGE3", "NUKAGE1", "FWATER4", "FWATER1", "SWATER4", "SWATER1", "LAVA4", "LAVA1",
    "BLOOD3", "BLOOD1", "RROCK08", "RROCK05", "SLIME04", "SLIME01", "SLIME08", "SLIME05",
    "SLIME12", "SLIME09"]

def Gfx.anim.textures() -> List<&2, String>:
  ["BLODGR4", "BLODGR1", "SLADRIP3", "SLADRIP1", "BLODRIP4", "BLODRIP1", "FIREWALL", "FIREWALA",
    "GSTFONT3", "GSTFONT1", "FIRELAVA", "FIRELAV3", "FIREMAG3", "FIREMAG1", "FIREBLU2", "FIREBLU1",
    "ROCKRED3", "ROCKRED1", "BFALL4", "BFALL1", "SFALL4", "SFALL1", "WFALL4", "WFALL1",
    "DBRAIN4", "DBRAIN1"]

# A frame of an animation: its name, its animation's count, the WAD's
# number for it, and its place in the animation.
type Gfx.Frame is Data:
  Frame{name: String, count: U32, wad: U32, at: U32}

# P_UpdateSpecials' translation of a picture after clock tics. Before
# the first tic it shows itself. After, the last tic run was clock less
# one, and picture number i of the WAD shows the frame at (that tic over
# 8, plus i) modulo the count, so an animation's phase comes from where
# the WAD keeps it.
def Gfx.anim.shown(+clock: U32, +pic: U32, count: U32, wad: U32, at: U32) -> U32:
  Bool.pick(U32, U32.is_zero(clock), pic, (pic - at + ((clock - 1) / 8 + wad) % count : U32))

# P_UpdateSpecials' loop: the table with what each frame shows after
# clock tics, the rows' frames numbered from pic on.
def Gfx.anim.update(rows: List<&2, U32>, +clock: U32, +pic: U32, shown: V.Vec) -> V.Vec:
  match rows:
    case count <> wad <> at <> rest:
      Gfx.anim.update(rest, clock, (pic + 1 : U32),
        V.Vec.set(shown, pic, Gfx.anim.shown(clock, pic, count, wad, at)))
    case _:
      shown

# Each name's place in a list, an earlier one winning.
def Gfx.places(names: List<&2, String>, +i: U32) -> Map<&2, U32>:
  match names:
    case []:
      Map.new(&2, U32)
    case name <> rest:
      Map.set(&2, U32, Gfx.places(rest, (i + 1 : U32)), name, i)

def Gfx.place(+places: Map<&2, U32>, name: String) -> U32:
  Pair.snd(Map<&2, U32>, U32, Map.get(U32, Gfx.none(), places, name))

def Gfx.anim.frames(names: List<&2, String>, +count: U32, +wad: U32, +at: U32) -> List<&2, Gfx.Frame>:
  match names:
    case []:
      []
    case name <> rest:
      Frame{name, count, wad, at} <> Gfx.anim.frames(rest, count, (wad + 1 : U32), (at + 1 : U32))

# The names from first to last, of an animation the WAD holds.
def Gfx.anim.held(held: Bool, names: List<&2, String>, +first: U32, last: U32) -> List<&2, String>:
  match held:
    case False{}:
      []
    case True{}:
      List.take(&2, String, List.drop(&2, String, names, U32.to_nat(first)),
        U32.to_nat((last - first + 1 : U32)))

def Gfx.anim.touched(names: List<&2, String>, +used: Gfx.Names) -> Bool:
  match names:
    case []:
      False{}
    case name <> rest:
      Bool.or(Bool.not(U32.is_eq(Gfx.Names.number(used, name), Gfx.none())), Gfx.anim.touched(rest, used))

def Gfx.anim.one(+names: List<&2, String>, +first: U32, +last: U32, +used: Gfx.Names,
  rest: List<&2, Gfx.Frame>) -> List<&2, Gfx.Frame>:
  +frames = Gfx.anim.held(Bool.and(U32.is_lt(first, last), U32.is_lt(last, Gfx.none())), names, first, last)
  List.append(&2, Gfx.Frame, Gfx.anim.frames(
    Bool.pick(List<&2, String>, Gfx.anim.touched(frames, used), frames, []), (last - first + 1 : U32), first, 0),
    rest)

def Gfx.anim.each(defs: List<&2, String>, +names: List<&2, String>, +places: Map<&2, U32>,
  +used: Gfx.Names) -> List<&2, Gfx.Frame>:
  match defs:
    case last <> first <> rest:
      Gfx.anim.one(names, Gfx.place(places, first), Gfx.place(places, last), used,
        Gfx.anim.each(rest, names, places, used))
    case _:
      []

# Every frame of each animation that the WAD holds, its first name
# before its last among the WAD's names, and that the map touches, the
# names it uses holding one of the frames: the flats or textures from
# the first to the last in the WAD's order, as vanilla counts them.
def Gfx.anim.wanted(defs: List<&2, String>, +names: List<&2, String>, used: Gfx.Names) ->
  List<&2, Gfx.Frame>:
  Gfx.anim.each(defs, names, Gfx.places(names, 0), used)

def Gfx.frames.names(frames: List<&2, Gfx.Frame>) -> List<&2, String>:
  match frames:
    case []:
      []
    case Frame{name, count, wad, at} <> rest:
      name <> Gfx.frames.names(rest)

def Gfx.frames.rows(frames: List<&2, Gfx.Frame>) -> List<&2, U32>:
  match frames:
    case []:
      []
    case Frame{name, count, wad, at} <> rest:
      count <> wad <> at <> Gfx.frames.rows(rest)

def Gfx.upto(n: Nat, +i: U32) -> List<&2, U32>:
  match n:
    case 0n:
      []
    case 1n+m:
      i <> Gfx.upto(m, (i + 1 : U32))

# The animations of frames numbered from first on, among so many
# numbers, each showing itself.
def Gfx.anim.of(frames: List<&2, Gfx.Frame>, first: U32, numbers: U32) -> Gfx.Anim:
  Anim{Gfx.frames.rows(frames), first, V.Vec.of(Gfx.upto(U32.to_nat(numbers), 0))}

# The WAD's flats in its order: the lumps after F_START, as vanilla
# numbers them, markers and all.
def Gfx.flats.wad(lumps: List<&2, W.Wad.Lump>, started: Bool) -> List<&2, String>:
  match lumps started:
    case [] _:
      []
    case W.Lump{pos, size, name} <> rest False{}:
      Gfx.flats.wad(rest, String.eq(name, "F_START"))
    case W.Lump{pos, size, name} <> rest True{}:
      name <> Gfx.flats.wad(rest, True{})

# The map's names numbered after the frames, so that an animation's
# frames are numbered together, in the WAD's order, whichever of them
# the map names and wherever; the list of numbers is the map's alone.
def Gfx.names.after(frames: List<&2, Gfx.Frame>, names: List<&2, String>, st: Gfx.Names) -> Gfx.Names:
  Gfx.names(names, Gfx.Names.fresh(Gfx.names(Gfx.frames.names(frames), st)))

# Lumps by name
# -------------

# The directory by name; a later lump of a name replaces an earlier, as
# Doom's W_CheckNumForName searches from the end.
def Gfx.dir(lumps: List<&2, W.Wad.Lump>, m: Map<&2, W.Wad.Lump>) -> Map<&2, W.Wad.Lump>:
  match lumps:
    case []:
      m
    case W.Lump{pos, size, +name} <> rest:
      Gfx.dir(rest, Map.set(&2, W.Wad.Lump, m, name, W.Lump{pos, size, name}))

def Gfx.lump.get(+dir: Map<&2, W.Wad.Lump>, name: String) -> W.Wad.Lump:
  Pair.snd(Map<&2, W.Wad.Lump>, W.Wad.Lump,
    Map.get(W.Wad.Lump, W.Lump{Gfx.none(), 0, ""}, dir, name))

def Gfx.lump.pos(l: W.Wad.Lump) -> U32:
  W.Lump{pos, size, name} = l
  pos

def Gfx.lump.check(missing: Bool, who: String, name: String, l: W.Wad.Lump) ->
  Result<&1, &1, U32 & String, W.Wad.Lump>:
  match missing:
    case True{}:
      Fail{(1, who ++ ": " ++ name ++ " not found")}
    case False{}:
      Done{l}

# A lump by name, or Doom's error for who asked.
def Gfx.lump(+dir: Map<&2, W.Wad.Lump>, +who: String, +name: String) ->
  Result<&1, &1, U32 & String, W.Wad.Lump>:
  +l = Gfx.lump.get(dir, name)
  Gfx.lump.check(U32.is_eq(Gfx.lump.pos(l), Gfx.none()), who, name, l)

def Gfx.lookup.cons(l: Result<&1, &1, U32 & String, W.Wad.Lump>,
  rest: Result<&1, &1, U32 & String, List<&2, W.Wad.Lump>>) ->
  Result<&1, &1, U32 & String, List<&2, W.Wad.Lump>>:
  match l rest:
    case Fail{e} _:
      Fail{e}
    case Done{x} Fail{e}:
      Fail{e}
    case Done{x} Done{xs}:
      Done{x <> xs}

# The lump of every name, or the error for the first name the WAD lacks.
def Gfx.lookup(names: List<&2, String>, +dir: Map<&2, W.Wad.Lump>, +who: String) ->
  Result<&1, &1, U32 & String, List<&2, W.Wad.Lump>>:
  match names:
    case []:
      Done{[]}
    case name <> rest:
      Gfx.lookup.cons(Gfx.lump(dir, who, name), Gfx.lookup(rest, dir, who))

# Copying
# -------

type Gfx.Copy is Type:
  Copy{src: Array<U32>, dst: Array<U32>}

# count reads from src, stride bytes apart from from, each converted and
# written to dst from to on.
type Gfx.Job is Data:
  Job{from: U32, to: U32, count: U32}

def Gfx.copy.put(~conv: @+v: U32 -> U32, to: U32, dst: Array<U32>, p: Array<U32> & U32) -> Gfx.Copy:
  (src, v) = p
  Copy{src, Array.set(U32, dst, to, conv(v))}

def Gfx.copy.one(~read: Array<U32> -> @+i: U32 -> Array<U32> & U32, ~conv: @+v: U32 -> U32, from: U32,
  to: U32, st: Gfx.Copy) -> Gfx.Copy:
  Copy{src, dst} = st
  Gfx.copy.put(~conv, to, dst, read(src, from))

def Gfx.copy(~read: Array<U32> -> @+i: U32 -> Array<U32> & U32, ~conv: @+v: U32 -> U32, n: Nat,
  +stride: U32, +from: U32, +to: U32, st: Gfx.Copy) -> Gfx.Copy:
  match n:
    case 0n:
      st
    case 1n+m:
      Gfx.copy(~read, ~conv, m, stride, (from + stride : U32), (to + 1 : U32),
        Gfx.copy.one(~read, ~conv, from, to, st))

def Gfx.same(+x: U32) -> U32:
  x

def Gfx.copies(jobs: List<&2, Gfx.Job>, st: Gfx.Copy) -> Gfx.Copy:
  match jobs:
    case []:
      st
    case Job{from, to, count} <> rest:
      Gfx.copies(rest, Gfx.copy(~B.Bytes.at, ~Gfx.same, U32.to_nat(count), 1, from, to, st))

# A palette entry's three bytes, read as a little-endian word, as the
# window's 0xRRGGBB.
def Gfx.rgb(+v: U32) -> U32:
  (((v .&. 255) << 16n) .|. (v .&. 65280) .|. ((v >> 16n) .&. 255) : U32)

def Gfx.Copy.dst(st: Gfx.Copy) -> Array<U32>:
  Copy{src, dst} = st
  dst

# Composites
# ----------

# A post of a patch column to paste into a composed column: the index
# of the post's header, of the composed column, the patch's row in the
# texture (signed), and the texture's height.
type Gfx.Paste is Data:
  Paste{src: U32, dst: U32, oy: U32, height: U32}

# The post walk's state: done at the column's 255.
type Gfx.Post is Type:
  Post{done: Bool, mem: Array<U32>, src: U32}

def Gfx.posts.len(~C: Data, ~act: Array<U32> -> @+src: U32 -> @+delta: U32 -> @+len: U32 -> @+ctx: C -> Array<U32>,
  +src: U32, delta: U32, ctx: C, p: Array<U32> & U32) -> Gfx.Post:
  (mem, +len) = p
  Post{False{}, act(mem, src, delta, len, ctx), (src + len + 4 : U32)}

def Gfx.posts.if(~C: Data, ~act: Array<U32> -> @+src: U32 -> @+delta: U32 -> @+len: U32 -> @+ctx: C -> Array<U32>,
  end: Bool, mem: Array<U32>, +src: U32, delta: U32, ctx: C) -> Gfx.Post:
  match end:
    case True{}:
      Post{True{}, mem, src}
    case False{}:
      Gfx.posts.len(~C, ~act, src, delta, ctx, B.Bytes.at(mem, (src + 1 : U32)))

def Gfx.posts.top(~C: Data, ~act: Array<U32> -> @+src: U32 -> @+delta: U32 -> @+len: U32 -> @+ctx: C -> Array<U32>,
  src: U32, ctx: C, p: Array<U32> & U32) -> Gfx.Post:
  (mem, +delta) = p
  Gfx.posts.if(~C, ~act, U32.is_eq(delta, 255), mem, src, delta, ctx)

# A patch column's posts walked from the first's header, in the array:
# act on each, given the post's header index, its first row in the patch
# and its length; the composer pastes them, the masked pass and the
# sprites draw them. The fuel outlasts any column.
def Gfx.posts(~C: Data, ~act: Array<U32> -> @+src: U32 -> @+delta: U32 -> @+len: U32 -> @+ctx: C -> Array<U32>,
  fuel: Nat, st: Gfx.Post, +ctx: C) -> Array<U32>:
  match fuel st:
    case _ Post{True{}, mem, src}:
      mem
    case 0n Post{False{}, mem, src}:
      mem
    case 1n+f Post{False{}, mem, +src}:
      Gfx.posts(~C, ~act, f, Gfx.posts.top(~C, ~act, src, ctx, B.Bytes.at(mem, src)), ctx)

def Gfx.move.put(to: U32, p: Array<U32> & U32) -> Array<U32>:
  (mem, v) = p
  Array.set(U32, mem, to, v)

# n slots copied up the same array.
def Gfx.move(n: Nat, +from: U32, +to: U32, mem: Array<U32>) -> Array<U32>:
  match n:
    case 0n:
      mem
    case 1n+m:
      Gfx.move(m, (from + 1 : U32), (to + 1 : U32), Gfx.move.put(to, B.Bytes.at(mem, from)))

# Doom's R_DrawColumnInCache for one post: pasted at the patch's row
# plus the post's, cut to the texture's height. A post cut at the top
# keeps its first texels, not its last, as Doom's memcpy does.
def Gfx.paste.post(mem: Array<U32>, +src: U32, +delta: U32, +len: U32, +paste: Gfx.Paste) -> Array<U32>:
  Paste{psrc, +dst, +oy, +height} = paste
  +at = (oy + delta : U32)
  +row = F.Fixed.max(at, 0)
  Gfx.move(U32.to_nat(F.Fixed.max(F.Fixed.min((len + F.Fixed.min(at, 0) : U32), (height - row : U32)), 0)),
    (src + 3 : U32), (dst + row : U32), mem)

def Gfx.paste.src(p: Gfx.Paste) -> U32:
  Paste{src, dst, oy, height} = p
  src

# Every post of each patch column, in order, so a later patch covers an
# earlier as in Doom's composite.
def Gfx.pastes(ps: List<&2, Gfx.Paste>, mem: Array<U32>) -> Array<U32>:
  match ps:
    case []:
      mem
    case +p <> rest:
      Gfx.pastes(rest, Gfx.posts(~Gfx.Paste, ~Gfx.paste.post, 256n, Post{False{}, mem, Gfx.paste.src(p)}, p))

# Textures
# --------

# The patches as copied: a patch's index in the array, its width, and
# where its column offsets start in cols, the offsets of all of them.
type Gfx.Patches is Data:
  Patches{base: V.Vec, width: V.Vec, start: V.Vec, cols: V.Vec}

# A patch placed in a texture: its column and row there (signed), and
# which patch.
type Gfx.Placed is Data:
  Placed{x: U32, y: U32, patch: U32}

# The assembly's state: the columns, texture words and pastes so far,
# newest first, the next composed column's index, and the columns so
# far.
type Gfx.Asm is Data:
  Asm{cols: List<&2, U32>, texs: List<&2, U32>, pastes: List<&2, Gfx.Paste>, comp: U32, ncols: U32}

# A 16-bit word as a signed number.
def Gfx.s16(w: U32) -> U32:
  F.Fixed.sarn((w << 16n : U32), 16n)

def Gfx.covering.if(covers: Bool, +ps: Gfx.Patches, +x: U32, placed: Gfx.Placed,
  rest: List<&2, Gfx.Placed>) -> List<&2, Gfx.Placed>:
  match covers:
    case False{}:
      rest
    case True{}:
      Patches{base, width, start, cols} = ps
      Placed{px, y, +patch} = placed
      Placed{(V.Vec.get(base, patch) + V.Vec.get(cols, (V.Vec.get(start, patch) + x - px : U32)) : U32),
        y, patch} <> rest

# The patches over texture column x, in order, each with x replaced by
# the index of its column's first post.
def Gfx.covering(placed: List<&2, Gfx.Placed>, +ps: Gfx.Patches, +x: U32) -> List<&2, Gfx.Placed>:
  match placed:
    case []:
      []
    case Placed{+px, +y, +patch} <> rest:
      Patches{base, width, start, cols} = ps
      Gfx.covering.if(Bool.and(F.Fixed.le(px, x), F.Fixed.lt(x, (px + V.Vec.get(width, patch) : U32))),
        ps, x, Placed{px, y, patch}, Gfx.covering(rest, ps, x))

def Gfx.col.pastes(over: List<&2, Gfx.Placed>, +dst: U32, +height: U32, acc: List<&2, Gfx.Paste>) ->
  List<&2, Gfx.Paste>:
  match over:
    case []:
      acc
    case Placed{src, y, patch} <> rest:
      Gfx.col.pastes(rest, dst, height, Paste{src, dst, y, height} <> acc)

# Doom's R_GenerateLookup for one column: under one patch it is that
# patch's column, past the first post's three header bytes; under
# several it is composed; under none it is the void.
def Gfx.col(over: List<&2, Gfx.Placed>, +height: U32, asm: Gfx.Asm) -> Gfx.Asm:
  match over:
    case []:
      Asm{cols, texs, pastes, comp, ncols} = asm
      Asm{Gfx.void() <> cols, texs, pastes, comp, (ncols + 1 : U32)}
    case Placed{src, y, patch} <> []:
      Asm{cols, texs, pastes, comp, ncols} = asm
      Asm{(src + 3 : U32) <> cols, texs, pastes, comp, (ncols + 1 : U32)}
    case a <> b <> rest:
      Asm{cols, texs, pastes, +comp, ncols} = asm
      Asm{comp <> cols, texs, Gfx.col.pastes(a <> b <> rest, comp, height, pastes),
        (comp + height : U32), (ncols + 1 : U32)}

def Gfx.cols(n: Nat, +placed: List<&2, Gfx.Placed>, +ps: Gfx.Patches, +height: U32, +x: U32,
  asm: Gfx.Asm) -> Gfx.Asm:
  match n:
    case 0n:
      asm
    case 1n+m:
      Gfx.cols(m, placed, ps, height, (x + 1 : U32), Gfx.col(Gfx.covering(placed, ps, x), height, asm))

def Gfx.mask.go(fuel: Nat, +width: U32, +j: U32, done: Bool) -> U32:
  match fuel done:
    case _ True{}:
      (j - 1 : U32)
    case 0n _:
      (j - 1 : U32)
    case 1n+f False{}:
      Gfx.mask.go(f, width, (j << 1n : U32), U32.is_gt((j << 2n : U32), width))

# Doom's texturewidthmask: the largest power of two in the width, less
# one.
def Gfx.mask(+width: U32) -> U32:
  Gfx.mask.go(16n, width, 1, U32.is_gt(2, width))

# A texture's patches from the words read (x, y and patch number a
# patch) and each one's patch index.
def Gfx.placed(n: Nat, words: List<&2, U32>, indices: List<&2, U32>) -> List<&2, Gfx.Placed>:
  match n words indices:
    case 1n+m x <> y <> num <> ws i <> more:
      Placed{Gfx.s16(x), Gfx.s16(y), i} <> Gfx.placed(m, ws, more)
    case _ _ _:
      []

def Gfx.texture(+width: U32, +height: U32, +count: U32, +placed: List<&2, Gfx.Placed>,
  +ps: Gfx.Patches, asm: Gfx.Asm) -> Gfx.Asm:
  Asm{cols, texs, pastes, comp, +ncols} = asm
  Gfx.cols(U32.to_nat(width), placed, ps, height, 0,
    Asm{cols, ncols <> Gfx.mask(width) <> count <> height <> width <> texs, pastes, comp, ncols})

# Every texture in number order: the headers are width, height and patch
# count a texture; the words and indices are consumed a texture's
# patches at a time.
def Gfx.textures(headers: List<&2, U32>, +words: List<&2, U32>, +indices: List<&2, U32>,
  +ps: Gfx.Patches, asm: Gfx.Asm) -> Gfx.Asm:
  match headers:
    case +width <> +height <> +count <> rest:
      Gfx.textures(rest, List.drop(&2, U32, words, U32.to_nat((count * 3 : U32))),
        List.drop(&2, U32, indices, U32.to_nat(count)), ps,
        Gfx.texture(width, height, count, Gfx.placed(U32.to_nat(count), words, indices), ps, asm))
    case _:
      asm

# Sprites
# -------

# The lumps after S_START up to S_END: the sprite namespace, where
# Doom's R_InitSpriteDefs looks.
def Gfx.sprite.space(lumps: List<&2, W.Wad.Lump>, inside: Bool) -> List<&2, W.Wad.Lump>:
  match lumps inside:
    case [] _:
      []
    case W.Lump{pos, size, name} <> rest False{}:
      Gfx.sprite.space(rest, String.eq(name, "S_START"))
    case W.Lump{pos, size, +name} <> rest True{}:
      W.Lump{pos, size, name} <> Gfx.sprite.space(rest, Bool.not(String.eq(name, "S_END")))

# What a sprite lump installs, the arguments of Doom's
# R_InstallSpriteLump: a frame, 0 for A; a rotation, 0 for a lump seen
# from every side, else 1 (the front) to 8; the lump's name; and 1 when
# it is mirrored.
type Gfx.Install is Data:
  Install{frame: U32, rot: U32, name: String, flip: U32}

# The character at k of a lump's name, 0 past its end, as in the
# directory's NUL-padded bytes.
def Gfx.char(name: String, k: Nat) -> U32:
  Char.to_u32(Maybe.default(&2, Char, String.get(name, k), Char.from_u32(0)))

def Gfx.install(+name: String, +k: Nat, flip: U32) -> Gfx.Install:
  Install{(Gfx.char(name, k) - 65 : U32), (Gfx.char(name, 1n+k) - 48 : U32), name, flip}

def Gfx.installs.if(hit: Bool, mirrored: Bool, +name: String, rest: List<&2, Gfx.Install>) ->
  List<&2, Gfx.Install>:
  match hit mirrored:
    case True{} True{}:
      Gfx.install(name, 4n, 0) <> Gfx.install(name, 6n, 1) <> rest
    case True{} False{}:
      Gfx.install(name, 4n, 0) <> rest
    case False{} _:
      rest

# Doom's R_InitSpriteDefs' scan for one sprite: each lump whose name
# starts with the sprite's four letters installs the frame and rotation
# its fifth and sixth characters name, and, when it has a seventh, the
# seventh and eighth's mirrored.
def Gfx.installs(lumps: List<&2, W.Wad.Lump>, +sprite: String) -> List<&2, Gfx.Install>:
  match lumps:
    case []:
      []
    case W.Lump{pos, size, +name} <> rest:
      Gfx.installs.if(String.starts_with(name, sprite), Bool.not(U32.is_zero(Gfx.char(name, 6n))), name,
        Gfx.installs(rest, sprite))

# How many frames a sprite's installs name: one past the last.
def Gfx.frames(installs: List<&2, Gfx.Install>) -> U32:
  match installs:
    case []:
      0
    case Install{frame, rot, name, flip} <> rest:
      U32.max((frame + 1 : U32), Gfx.frames(rest))

# A frame's installs: how many are seen from every side, and how many
# are rotations with the rotations as bits 1 to 8 (one past 8 sets a
# bit past 8).
type Gfx.Tally is Data:
  Tally{zeros: U32, rotated: U32, rots: U32}

def Gfx.tally(installs: List<&2, Gfx.Install>, +frame: U32, t: Gfx.Tally) -> Gfx.Tally:
  match installs:
    case []:
      t
    case Install{+f, +rot, name, flip} <> rest:
      Tally{zeros, rotated, rots} = t
      +here = U32.is_eq(f, frame)
      +turned = Bool.and(here, Bool.not(U32.is_zero(rot)))
      Gfx.tally(rest, frame, Tally{(zeros + Bool.to_u32(Bool.and(here, U32.is_zero(rot))) : U32),
        (rotated + Bool.to_u32(turned) : U32),
        (rots .|. Bool.pick(U32, turned, U32.shln(1, U32.to_nat(U32.min(rot, 10))), 0) : U32)})

# Vanilla takes a frame of one lump for every side or of eight lumps,
# one a rotation.
def Gfx.tally.right(t: Gfx.Tally) -> Bool:
  Tally{+zeros, +rotated, +rots} = t
  Bool.or(Bool.and(U32.is_eq(zeros, 1), U32.is_zero(rotated)),
    Bool.and(U32.is_zero(zeros), Bool.and(U32.is_eq(rotated, 8), U32.is_eq(rots, 510))))

def Gfx.tally.words(nozeros: Bool, norotations: Bool, named: String) -> String:
  match nozeros norotations:
    case True{} True{}:
      "No patches found for " ++ named
    case True{} False{}:
      "Sprite " ++ named ++ " is missing rotations"
    case False{} True{}:
      "Sprite " ++ named ++ " has multip rot=0 lump"
    case False{} False{}:
      "Sprite " ++ named ++ " has rotations and a rot=0 lump"

# Doom's words for what is wrong with a sprite's frame, from whether it
# has lumps for every side and whether it has rotations.
def Gfx.tally.fault(t: Gfx.Tally, sprite: String, frame: String) -> String:
  Tally{zeros, rotated, rots} = t
  "R_InitSprites: " ++ Gfx.tally.words(U32.is_zero(zeros), U32.is_zero(rotated), sprite ++ " frame " ++ frame)

# The first of n frames from f that vanilla refuses, or none.
def Gfx.frames.wrong(n: Nat, +f: U32, +installs: List<&2, Gfx.Install>) -> U32:
  match n:
    case 0n:
      Gfx.none()
    case 1n+m:
      Bool.pick(U32, Gfx.tally.right(Gfx.tally(installs, f, Tally{0, 0, 0})),
        Gfx.frames.wrong(m, (f + 1 : U32), installs), f)

def Gfx.letter(f: U32) -> String:
  String.from_list([Char.from_u32((65 + f : U32))])

# The install of a frame seen at a rotation: the frame's one for every
# side, or the rotation's own.
def Gfx.view(installs: List<&2, Gfx.Install>, +frame: U32, +rot: U32) -> Gfx.Install:
  match installs:
    case []:
      Install{0, 0, "", 0}
    case Install{+f, +r, name, flip} <> rest:
      Bool.pick(Gfx.Install, Bool.and(U32.is_eq(f, frame), Bool.or(U32.is_zero(r), U32.is_eq(r, rot))),
        Install{f, r, name, flip}, Gfx.view(rest, frame, rot))

def Gfx.views(n: Nat, +rot: U32, +installs: List<&2, Gfx.Install>, +frame: U32) -> List<&2, Gfx.Install>:
  match n:
    case 0n:
      []
    case 1n+m:
      Gfx.view(installs, frame, rot) <> Gfx.views(m, (rot + 1 : U32), installs, frame)

def Gfx.sprite.frames(fine: Bool, +wrong: U32, +sprite: String, +frame: U32, +installs: List<&2, Gfx.Install>) ->
  Result<&1, &1, U32 & String, List<&2, Gfx.Install>>:
  match fine:
    case True{}:
      Done{Gfx.views(8n, 1, installs, frame)}
    case False{}:
      Fail{(1, Gfx.tally.fault(Gfx.tally(installs, wrong, Tally{0, 0, 0}), sprite, Gfx.letter(wrong)))}

def Gfx.sprite.wrong(+wrong: U32, +sprite: String, +frame: U32, +installs: List<&2, Gfx.Install>) ->
  Result<&1, &1, U32 & String, List<&2, Gfx.Install>>:
  Gfx.sprite.frames(U32.is_eq(wrong, Gfx.none()), wrong, sprite, frame, installs)

def Gfx.sprite.check(fits: Bool, +sprite: String, +frame: U32, +count: U32,
  +installs: List<&2, Gfx.Install>) -> Result<&1, &1, U32 & String, List<&2, Gfx.Install>>:
  match fits:
    case True{}:
      Gfx.sprite.wrong(Gfx.frames.wrong(U32.to_nat(count), 0, installs), sprite, frame, installs)
    case False{}:
      Fail{(1, Bool.pick(String, U32.is_gt(count, 29), "R_InstallSpriteLump: Bad frame characters in sprite ",
        "R_ProjectSprite: no frame " ++ Gfx.letter(frame) ++ " of sprite ") ++ sprite)}

# Doom's R_InitSpriteDefs for the sprite of a state row: its frames,
# from A to the last its lumps name, and no more than 29, are each one
# lump for every side or eight rotations, as vanilla requires; then the
# row's frame seen at each rotation, 1 first. Or the error for a sprite
# vanilla refuses or that lacks the row's frame.
def Gfx.sprite.def(+space: List<&2, W.Wad.Lump>, r: H.Thing.Row) ->
  Result<&1, &1, U32 & String, List<&2, Gfx.Install>>:
  H.Row{+sprite, +frame, bright, tics, next, action, light} = r
  +installs = Gfx.installs(space, sprite)
  +count = Gfx.frames(installs)
  Gfx.sprite.check(Bool.and(U32.is_lt(frame, count), U32.is_le(count, 29)), sprite, frame, count, installs)

def Gfx.sprite.defs.cons(d: Result<&1, &1, U32 & String, List<&2, Gfx.Install>>,
  rest: Result<&1, &1, U32 & String, List<&2, Gfx.Install>>) -> Result<&1, &1, U32 & String, List<&2, Gfx.Install>>:
  match d rest:
    case Fail{e} _:
      Fail{e}
    case Done{x} Fail{e}:
      Fail{e}
    case Done{x} Done{xs}:
      Done{List.append(&2, Gfx.Install, x, xs)}

# The eight views of each row's frame, rows in turn.
def Gfx.sprite.defs(rows: List<&2, U32>, +space: List<&2, W.Wad.Lump>) ->
  Result<&1, &1, U32 & String, List<&2, Gfx.Install>>:
  match rows:
    case []:
      Done{[]}
    case row <> rest:
      Gfx.sprite.defs.cons(Gfx.sprite.def(space, H.Thing.row(row)), Gfx.sprite.defs(rest, space))

# A row of no tics is passed through as it is entered and never drawn,
# so its lump is not copied: S_LIGHTDONE names a shotgun frame Freedoom
# does not have.
def Gfx.sprite.mark(shown: Bool, marks: V.Vec, +state: U32) -> V.Vec:
  match shown:
    case False{}:
      marks
    case True{}:
      V.Vec.set(marks, state, 1)

# A state row and each one after it in turn marked, until the next is
# the first again or there is none.
def Gfx.sprite.chase(fuel: Nat, done: Bool, +first: U32, +state: U32, marks: V.Vec) -> V.Vec:
  match fuel done:
    case 1n+f False{}:
      +next = H.Thing.Row.next(H.Thing.row(state))
      Gfx.sprite.chase(f, Bool.or(U32.is_eq(next, first), U32.is_eq(next, H.Thing.null())), first, next,
        Gfx.sprite.mark(Bool.not(U32.is_zero(H.Thing.Row.tics(H.Thing.row(state)))), marks, state))
    case _ _:
      marks

# A row and those after it marked, unless the type has no such row.
def Gfx.sprite.from(none: Bool, +n: Nat, +state: U32, marks: V.Vec) -> V.Vec:
  match none:
    case True{}:
      marks
    case False{}:
      Gfx.sprite.chase(n, False{}, state, state, marks)

# Pain, death and gib chains have entry points outside the spawn chain.
def Gfx.sprite.hurt(+kind: U32, +n: Nat, marks: V.Vec) -> V.Vec:
  Gfx.sprite.from(U32.is_eq(H.Thing.painstate(kind), H.Thing.null()), n, H.Thing.painstate(kind),
    Gfx.sprite.from(U32.is_eq(H.Thing.xdeathstate(kind), H.Thing.null()), n, H.Thing.xdeathstate(kind),
      Gfx.sprite.from(U32.is_eq(H.Thing.deathstate(kind), H.Thing.null()), n, H.Thing.deathstate(kind), marks)))

# The rows a type reaches that no chain from its spawn state does: the
# chase rows A_Look sends it to, the melee and missile rows A_Chase
# sends it to, and the rows it dies through. Vanilla's R_InitSprites
# copies every frame of every sprite the WAD holds; Bendoom copies only
# the frames its rows name, so each entry point has to be followed or a
# woken monster draws nothing at all.
def Gfx.sprite.woken(+kind: U32, +n: Nat, marks: V.Vec) -> V.Vec:
  Gfx.sprite.from(U32.is_zero(H.Thing.missile(kind)), n, H.Thing.missile(kind),
    Gfx.sprite.from(U32.is_zero(H.Thing.melee(kind)), n, H.Thing.melee(kind),
      Gfx.sprite.from(U32.is_zero(H.Thing.see(kind)), n, H.Thing.see(kind), Gfx.sprite.hurt(kind, n, marks))))

def Gfx.sprite.marks(things: List<&2, H.Thing>, +n: Nat, marks: V.Vec) -> V.Vec:
  match things:
    case []:
      marks
    case H.Thing{id, +kind, x, y, z, floorz, ceilz, angle, sector, +state, tics, momz, hurt} <> rest:
      Gfx.sprite.marks(rest, n, Gfx.sprite.woken(kind, n, Gfx.sprite.chase(n, False{}, state, state, marks)))

def Gfx.sprite.keep(kept: Bool, row: U32, rest: List<&2, U32>) -> List<&2, U32>:
  match kept:
    case True{}:
      row <> rest
    case False{}:
      rest

def Gfx.sprite.rows.go(n: Nat, +row: U32, +marks: V.Vec) -> List<&2, U32>:
  match n:
    case 0n:
      []
    case 1n+m:
      Gfx.sprite.keep(U32.is_eq(V.Vec.get(marks, row), 1), row, Gfx.sprite.rows.go(m, (row + 1 : U32), marks))

# A weapon's rows and those they lead to, marked: the ones it rises,
# rests, sinks and fires in, and its muzzle flash's.
def Gfx.sprite.weapon(w: H.Thing.Weapon, +n: Nat, marks: V.Vec) -> V.Vec:
  H.Weapon{+up, +ready, +down, ammo, +atk, +flash} = w
  Gfx.sprite.chase(n, False{}, flash, flash, Gfx.sprite.chase(n, False{}, atk, atk,
    Gfx.sprite.chase(n, False{}, down, down,
      Gfx.sprite.chase(n, False{}, ready, ready, Gfx.sprite.chase(n, False{}, up, up, marks)))))

def Gfx.sprite.weapons(ws: List<&2, H.Thing.Weapon>, +n: Nat, marks: V.Vec) -> V.Vec:
  match ws:
    case []:
      marks
    case w <> rest:
      Gfx.sprite.weapons(rest, n, Gfx.sprite.weapon(w, n, marks))

# A type spawned in play alone, whose rows no THINGS record reaches.
def Gfx.sprite.def.rows(d: H.Thing.Def, +n: Nat, marks: V.Vec) -> V.Vec:
  H.Def{kind, +state, radius, height, flags} = d
  Gfx.sprite.chase(n, False{}, state, state, marks)

# The state rows the level and runtime drops can spawn, the weapons,
# the chaingun's second flash, which A_FireCGun sets and no row leads
# to, and every row those entry points lead to, each once, in order.
def Gfx.sprite.rows(s: H.Thing.Spawn) -> List<&2, U32>:
  H.Spawn{things, rnd, you} = s
  +n = List.length(&2, H.Thing.Row, H.Thing.rows())
  +marks = V.Vec.set(V.Vec.of_list([], U32.from_nat(n)), 50, 1)
  +marks = Gfx.sprite.weapons(H.Thing.weapons(), n, marks)
  +second = (H.Thing.Weapon.flash(H.Thing.chaingun()) + 1 : U32)
  +marks = Gfx.sprite.chase(n, False{}, second, second, marks)
  +marks = Gfx.sprite.def.rows(H.Thing.info(2007), n, marks)
  +marks = Gfx.sprite.def.rows(H.Thing.info(2001), n, marks)
  +marks = Gfx.sprite.def.rows(H.Thing.info(H.Thing.puff()), n, marks)
  +marks = Gfx.sprite.def.rows(H.Thing.info(H.Thing.blood()), n, marks)
  +marks = Gfx.sprite.def.rows(H.Thing.info(H.Thing.fireball()), n, marks)
  +marks = Gfx.sprite.hurt(H.Thing.fireball(), n, marks)
  Gfx.sprite.rows.go(n, 0, Gfx.sprite.marks(things, n, marks))

def Gfx.install.names(views: List<&2, Gfx.Install>) -> List<&2, String>:
  match views:
    case []:
      []
    case Install{frame, rot, name, flip} <> rest:
      name <> Gfx.install.names(rest)

def Gfx.install.flips(views: List<&2, Gfx.Install>) -> List<&2, U32>:
  match views:
    case []:
      []
    case Install{frame, rot, name, flip} <> rest:
      flip <> Gfx.install.flips(rest)

# The sprite lumps to copy, each once; the state rows they are for; and
# for each row's eight views the number of its lump among them and
# whether it is mirrored.
type Gfx.Sprites is Data:
  Sprites{lumps: List<&2, W.Wad.Lump>, rows: List<&2, U32>, numbers: List<&2, U32>, flips: List<&2, U32>}

def Gfx.sprites.found(rows: List<&2, U32>, +space: List<&2, W.Wad.Lump>, +views: List<&2, Gfx.Install>) ->
  Result<&1, &1, U32 & String, Gfx.Sprites>:
  +sn = Gfx.names(Gfx.install.names(views), {Names{Map.new(&2, U32), 0, [], []} : Gfx.Names})
  Result.map(&1, &1, U32 & String, List<&2, W.Wad.Lump>, Gfx.Sprites,
    lumps => Sprites{lumps, rows, Gfx.Names.numbers(sn), Gfx.install.flips(views)},
    Gfx.lookup(Gfx.Names.distinct(sn), Gfx.dir(space, Map.new(&2, W.Wad.Lump)), "R_InitSprites"))

# The sprites of some state rows, from the WAD's sprite namespace.
def Gfx.sprites(+rows: List<&2, U32>, +space: List<&2, W.Wad.Lump>) -> Result<&1, &1, U32 & String, Gfx.Sprites>:
  Result.bind(&1, &1, U32 & String, List<&2, Gfx.Install>, Gfx.Sprites, Gfx.sprite.defs(rows, space),
    views => Gfx.sprites.found(rows, space, views))

# Each row's eight slots in the table, row * 8 on.
def Gfx.sprite.slots(rows: List<&2, U32>) -> List<&2, U32>:
  match rows:
    case []:
      []
    case row <> rest:
      List.append(&2, U32, Gfx.upto(8n, (row * 8 : U32)), Gfx.sprite.slots(rest))

# Doom's R_InitSpriteLumps for the lumps copied: each slot gets six
# words from slot * 6: its lump's index in the array; the lump's width,
# left offset and top offset in fixed point (from heads, three words a
# lump); 1 when it is mirrored; and 1 when its row's frame is
# full-bright.
def Gfx.sprite.table(slots: List<&2, U32>, numbers: List<&2, U32>, flips: List<&2, U32>, +bases: V.Vec,
  +heads: V.Vec, table: V.Vec) -> V.Vec:
  match slots numbers flips:
    case +s <> ss +n <> ns flip <> fs:
      Gfx.sprite.table(ss, ns, fs, bases, heads, V.Vec.set(V.Vec.set(V.Vec.set(V.Vec.set(V.Vec.set(V.Vec.set(
        table,
        (s * 6 : U32), V.Vec.get(bases, n)),
        (s * 6 + 1 : U32), F.Fixed.of_map(V.Vec.get(heads, (n * 3 : U32)))),
        (s * 6 + 2 : U32), F.Fixed.of_map(V.Vec.get(heads, (n * 3 + 1 : U32)))),
        (s * 6 + 3 : U32), F.Fixed.of_map(V.Vec.get(heads, (n * 3 + 2 : U32)))),
        (s * 6 + 4 : U32), flip),
        (s * 6 + 5 : U32), Bool.to_u32(H.Thing.Row.bright(H.Thing.row((s >> 3n : U32))))))
    case _ _ _:
      table

# The status bar
# --------------

# Lumps of one name and a number from first, as ST_loadUnloadGraphics
# builds their names.
def Gfx.bar.numbered(n: Nat, +name: String, +first: U32) -> List<&2, String>:
  match n:
    case 0n:
      []
    case 1n+m:
      (name ++ U32.show(first)) <> Gfx.bar.numbered(m, name, (first + 1 : U32))

# ST_loadUnloadGraphics' face states, in the order it numbers them: for
# each of the five pain levels the three straight faces, the turn right,
# the turn left, the ouch, the evil grin and the rampage, then the god
# and the dead face.
def Gfx.bar.faces(n: Nat, +i: U32) -> List<&2, String>:
  match n:
    case 0n:
      ["STFGOD0", "STFDEAD0"]
    case 1n+m:
      +d = U32.show(i)
      List.append(&2, String, ["STFST" ++ d ++ "0", "STFST" ++ d ++ "1", "STFST" ++ d ++ "2",
        "STFTR" ++ d ++ "0", "STFTL" ++ d ++ "0", "STFOUCH" ++ d, "STFEVL" ++ d, "STFKILL" ++ d],
        Gfx.bar.faces(m, (i + 1 : U32)))

# The patches ST_loadGraphics loads that a single player's bar draws, in
# the order Gfx.bar numbers them: the ten tall digits, the ten short
# ones, the percent sign, the six key icons, the six grey weapon
# numbers, the arms panel, the background, and the 42 faces. STMBARL and
# STMBARR belong to Doom 1.0, which neither WAD is; the minus sign shows
# on a negative count alone and the face background on a net game's bar.
type Gfx.Spot is Data:
  Spot{x: U32, y: U32}

def Gfx.Spot.x(s: Gfx.Spot) -> U32:
  Spot{x, y} = s
  x

def Gfx.Spot.y(s: Gfx.Spot) -> U32:
  Spot{x, y} = s
  y

def Gfx.wi.spots() -> List<&2, Gfx.Spot>:
  [Spot{224, 104}, Spot{184, 160}, Spot{112, 136}, Spot{72, 112}, Spot{88, 96}, Spot{64, 48},
    Spot{192, 40}, Spot{136, 16}, Spot{80, 16}, Spot{64, 24}]

def Gfx.wi.anim(+j: U32) -> List<&2, String>:
  ["WIA00" ++ U32.show(j) ++ "00", "WIA00" ++ U32.show(j) ++ "01", "WIA00" ++ U32.show(j) ++ "02"]

def Gfx.wi.anims(n: Nat, +j: U32) -> List<&2, String>:
  match n:
    case 0n:
      []
    case 1n+m:
      List.append(&2, String, Gfx.wi.anim(j), Gfx.wi.anims(m, (j + 1 : U32)))

def Gfx.wi.names() -> List<&2, String>:
  List.append(&2, String,
    ["WIMAP0", "WILV00", "WILV01", "WIF", "WIENTER", "WIOSTK", "WIOSTI", "WISCRT2", "WITIME", "WIPAR",
      "WISUCKS", "WIPCNT", "WICOLON", "WINUM0", "WINUM1", "WINUM2", "WINUM3", "WINUM4", "WINUM5",
      "WINUM6", "WINUM7", "WINUM8", "WINUM9", "WISPLAT", "WIURH0", "WIURH1"],
    Gfx.wi.anims(List.length(&2, Gfx.Spot, Gfx.wi.spots()), 0))

def Gfx.bar.names() -> List<&2, String>:
  List.concat(&2, String, [Gfx.bar.numbered(10n, "STTNUM", 0), Gfx.bar.numbered(10n, "STYSNUM", 0),
    ["STTPRCNT"], Gfx.bar.numbered(6n, "STKEYS", 0), Gfx.bar.numbered(6n, "STGNUM", 2), ["STARMS", "STBAR"],
    Gfx.bar.faces(5n, 0), Gfx.wi.names()])

# The heads-up font
# -----------------

def Gfx.font.go(n: Nat, +k: U32) -> List<&2, String>:
  match n:
    case 0n:
      []
    case 1n+m:
      ("STCFN0" ++ U32.show(k)) <> Gfx.font.go(m, (k + 1 : U32))

# Doom's HU_Init: the font is STCFN033 to STCFN095, a lump for each
# character from HU_FONTSTART, '!', to '_'.
def Gfx.font.names() -> List<&2, String>:
  Gfx.font.go(63n, 33)

# Loading
# -------

# What the first half of the load found (the flats, the sprites, the
# status bar's patches), for the textures' half, which adds the
# textures' animations.
type Gfx.Base is Data:
  Base{level: L.Level, fl: Gfx.Names, pal: W.Wad.Lump, cmap: W.Wad.Lump, flats: List<&2, W.Wad.Lump>,
    sprites: Gfx.Sprites, anims: Gfx.Anims, bar: List<&2, W.Wad.Lump>, font: List<&2, W.Wad.Lump>}

def Gfx.lump.size(l: W.Wad.Lump) -> U32:
  W.Lump{pos, size, name} = l
  size

# A copy of each lump, one after another from to.
def Gfx.jobs(lumps: List<&2, W.Wad.Lump>, +to: U32) -> List<&2, Gfx.Job>:
  match lumps:
    case []:
      []
    case +l <> rest:
      Job{Gfx.lump.pos(l), to, Gfx.lump.size(l)} <> Gfx.jobs(rest, (to + Gfx.lump.size(l) : U32))

# Where each of a list of sizes starts, laid end to end from at, and
# then where the last ends.
def Gfx.starts(sizes: List<&2, U32>, +at: U32) -> List<&2, U32>:
  match sizes:
    case []:
      at <> []
    case size <> rest:
      at <> Gfx.starts(rest, (at + size : U32))

def Gfx.sizes(lumps: List<&2, W.Wad.Lump>) -> List<&2, U32>:
  match lumps:
    case []:
      []
    case l <> rest:
      Gfx.lump.size(l) <> Gfx.sizes(rest)

def Gfx.flat.lumps(flats: List<&2, W.Wad.Lump>) -> List<&2, W.Wad.Lump>:
  match flats:
    case []:
      []
    case W.Lump{pos, size, name} <> rest:
      W.Lump{pos, 4096, name} <> Gfx.flat.lumps(rest)

def Gfx.last(xs: List<&2, U32>) -> U32:
  Maybe.default(&2, U32, List.last(&2, U32, xs), 0)

def Gfx.Asm.comp(asm: Gfx.Asm) -> U32:
  Asm{cols, texs, pastes, comp, ncols} = asm
  comp

def Gfx.Asm.pastes(asm: Gfx.Asm) -> List<&2, Gfx.Paste>:
  Asm{cols, texs, pastes, comp, ncols} = asm
  List.reverse(&2, Gfx.Paste, pastes)

def Gfx.Asm.texs(asm: Gfx.Asm) -> V.Vec:
  Asm{cols, texs, pastes, comp, ncols} = asm
  V.Vec.of(List.reverse(&2, U32, texs))

def Gfx.Asm.cols(asm: Gfx.Asm) -> V.Vec:
  Asm{cols, texs, pastes, comp, ncols} = asm
  V.Vec.of(List.reverse(&2, U32, cols))

# The offsets of the given fields from each lump's position.
def Gfx.plan(lumps: List<&2, W.Wad.Lump>, +fields: List<&2, U32>) -> List<&2, U32>:
  match lumps:
    case []:
      []
    case l <> rest:
      B.Bytes.fields.one(fields, Gfx.lump.pos(l), Gfx.plan(rest, fields))

# The array sized for everything; the palettes, the colormaps, the
# flats, the patches, the sprites and the bar's patches copied in; the
# composed columns pasted. heads: each sprite lump's width, left and top
# offsets.
def Gfx.build(base: Gfx.Base, +tn: Gfx.Names, +fbases: List<&2, U32>, plumps: List<&2, W.Wad.Lump>,
  +asm: Gfx.Asm, p: Array<U32> & List<&2, U32>) -> Array<U32> & Gfx & L.Level:
  Base{level, +fl, pal, cmap, flats, Sprites{+slumps, rows, numbers, flips}, anims, +bar, +font} = base
  (a, heads) = p
  +sidetex = V.Vec.of(Gfx.Names.numbers(tn))
  +sbases = Gfx.starts(Gfx.sizes(slumps), Gfx.Asm.comp(asm))
  +bbases = Gfx.starts(Gfx.sizes(bar), Gfx.last(sbases))
  +hbases = Gfx.starts(Gfx.sizes(font), Gfx.last(bbases))
  (Gfx.pastes(Gfx.Asm.pastes(asm), Gfx.Copy.dst(Gfx.copies(
      Job{Gfx.lump.pos(cmap), Gfx.colormap(), 8704} <> List.concat(&2, Gfx.Job,
        [Gfx.jobs(Gfx.flat.lumps(flats), Gfx.lumps()), Gfx.jobs(plumps, Gfx.last(fbases)),
          Gfx.jobs(slumps, Gfx.Asm.comp(asm)), Gfx.jobs(bar, Gfx.last(sbases)),
          Gfx.jobs(font, Gfx.last(bbases))]),
      Gfx.copy(~B.Bytes.u32, ~Gfx.rgb, U32.to_nat(3584), 3, Gfx.lump.pos(pal), Gfx.palette(),
        Copy{a, Array.new(U32, V.Vec.depth((Gfx.last(hbases) + 128 : U32)), 0)})))),
    Gfx{V.Vec.of(fbases), V.Vec.of(Gfx.Names.numbers(fl)), Gfx.Names.number(fl, "F_SKY1"),
      Gfx.Asm.texs(asm), Gfx.Asm.cols(asm), sidetex, Gfx.Names.number(tn, "SKY1"),
      Gfx.sprite.table(Gfx.sprite.slots(rows), numbers, flips, V.Vec.of(sbases), V.Vec.of(heads),
        V.Vec.of_list([], (U32.from_nat(List.length(&2, H.Thing.Row, H.Thing.rows())) * 48 : U32))), anims,
      V.Vec.of(bbases), V.Vec.of(hbases)},
    L.Level.textured(level, sidetex,
      Gfx.switch.table(Gfx.switch.pairs(), tn, V.Vec.of_list([], Gfx.Names.next(tn)))))

# The flats end where the patches start, the patches where the composed
# columns do, those where the sprites do, and the sprites where the
# bar's patches do; texture 0 is none, five zero words.
def Gfx.layout(a: Array<U32>, +base: Gfx.Base, tn: Gfx.Names, headers: List<&2, U32>,
  words: List<&2, U32>, indices: List<&2, U32>, +plumps: List<&2, W.Wad.Lump>, widths: List<&2, U32>,
  +colofs: List<&2, List<&2, U32>>) -> Array<U32> & Gfx & L.Level:
  Base{level, +fl, pal, cmap, flats, Sprites{slumps, rows, numbers, flips}, anims, bar, font} = base
  +fbases = Gfx.starts(Gfx.sizes(Gfx.flat.lumps(flats)), Gfx.lumps())
  +pbases = Gfx.starts(Gfx.sizes(plumps), Gfx.last(fbases))
  +ws = widths
  Gfx.build(base, tn, fbases, plumps,
    Gfx.textures(headers, words, indices,
      Patches{V.Vec.of(pbases), V.Vec.of(ws), V.Vec.of(Gfx.starts(ws, 0)),
        V.Vec.of(List.concat(&2, U32, colofs))},
      Asm{[], [0, 0, 0, 0, 0], [], Gfx.last(pbases), 0}),
    B.Bytes.each(~U32, ~B.Bytes.u16, Gfx.plan(slumps, [0, 4, 6]), a))

# A run of count records of stride bytes from each lump's position plus
# skip, the counts given lump by lump.
def Gfx.runs(lumps: List<&2, W.Wad.Lump>, counts: List<&2, U32>, +skip: U32, +stride: U32,
  +fields: List<&2, U32>) -> List<&2, List<&2, U32>>:
  match lumps counts:
    case l <> ls count <> cs:
      B.Bytes.fields(U32.to_nat(count), (Gfx.lump.pos(l) + skip : U32), stride, fields)
        <> Gfx.runs(ls, cs, skip, stride, fields)
    case _ _:
      []

def Gfx.load.cols(+base: Gfx.Base, tn: Gfx.Names, headers: List<&2, U32>, words: List<&2, U32>,
  indices: List<&2, U32>, plumps: List<&2, W.Wad.Lump>, widths: List<&2, U32>,
  p: Array<U32> & List<&2, List<&2, U32>>) -> Array<U32> & Gfx & L.Level:
  (a, colofs) = p
  Gfx.layout(a, base, tn, headers, words, indices, plumps, widths, colofs)

# Each patch's width, then its column offsets.
def Gfx.load.widths(+base: Gfx.Base, tn: Gfx.Names, headers: List<&2, U32>, words: List<&2, U32>,
  indices: List<&2, U32>, +plumps: List<&2, W.Wad.Lump>, p: Array<U32> & List<&2, U32>) ->
  Array<U32> & Gfx & L.Level:
  (a, +widths) = p
  Gfx.load.cols(base, tn, headers, words, indices, plumps, widths,
    B.Bytes.lists(~U32, ~B.Bytes.u32, Gfx.runs(plumps, widths, 8, 4, [0]), a))

def Gfx.load.patches(+base: Gfx.Base, tn: Gfx.Names, headers: List<&2, U32>, words: List<&2, U32>,
  indices: List<&2, U32>, a: Array<U32>, +plumps: List<&2, W.Wad.Lump>) -> Array<U32> & Gfx & L.Level:
  Gfx.load.widths(base, tn, headers, words, indices, plumps,
    B.Bytes.each(~U32, ~B.Bytes.u16, Gfx.plan(plumps, [0]), a))

# The patches numbered by name, so one used by several textures is
# copied once.
def Gfx.load.pnames(+base: Gfx.Base, +dir: Map<&2, W.Wad.Lump>, tn: Gfx.Names, headers: List<&2, U32>,
  words: List<&2, U32>, p: Array<U32> & List<&2, String>) ->
  Result<&1, &1, U32 & String, Array<U32> & Gfx & L.Level>:
  (a, names) = p
  +pn = Gfx.names(names, Names{Map.new(&2, U32), 0, [], []})
  Result.map(&1, &1, U32 & String, List<&2, W.Wad.Lump>, Array<U32> & Gfx & L.Level,
    plumps => Gfx.load.patches(base, tn, headers, words, Gfx.Names.numbers(pn), a, plumps),
    Gfx.lookup(Gfx.Names.distinct(pn), dir, "R_InitTextures: missing patch"))

# The index in PNAMES of the name of each patch number.
def Gfx.pname.plan(words: List<&2, U32>, +pnames: U32) -> List<&2, U32>:
  match words:
    case x <> y <> num <> rest:
      (pnames + 4 + num * 8 : U32) <> Gfx.pname.plan(rest, pnames)
    case _:
      []

def Gfx.load.words(+base: Gfx.Base, +dir: Map<&2, W.Wad.Lump>, tn: Gfx.Names, headers: List<&2, U32>,
  pnames: W.Wad.Lump, p: Array<U32> & List<&2, List<&2, U32>>) ->
  Result<&1, &1, U32 & String, Array<U32> & Gfx & L.Level>:
  (a, lists) = p
  +words = List.concat(&2, U32, lists)
  Gfx.load.pnames(base, dir, tn, headers, words,
    B.Bytes.each(~String, ~B.Bytes.name, Gfx.pname.plan(words, Gfx.lump.pos(pnames)), a))

def Gfx.counts(headers: List<&2, U32>) -> List<&2, U32>:
  match headers:
    case width <> height <> count <> rest:
      count <> Gfx.counts(rest)
    case _:
      []

# Each texture's width, height and patch count, then its patches' x, y
# and patch number.
def Gfx.load.headers(+base: Gfx.Base, +dir: Map<&2, W.Wad.Lump>, tn: Gfx.Names,
  +defs: List<&2, W.Wad.Lump>, pnames: W.Wad.Lump, p: Array<U32> & List<&2, U32>) ->
  Result<&1, &1, U32 & String, Array<U32> & Gfx & L.Level>:
  (a, +headers) = p
  Gfx.load.words(base, dir, tn, headers, pnames,
    B.Bytes.lists(~U32, ~B.Bytes.u16, Gfx.runs(defs, Gfx.counts(headers), 22, 10, [0, 2, 4]), a))

# The definitions by name, an earlier one winning, as Doom's search
# runs from the first.
def Gfx.defs(names: List<&2, String>, offs: List<&2, U32>) -> Map<&2, W.Wad.Lump>:
  match names offs:
    case +name <> ns off <> os:
      Map.set(&2, W.Wad.Lump, Gfx.defs(ns, os), name, W.Lump{off, 0, name})
    case _ _:
      Map.new(&2, W.Wad.Lump)

# Doom's texture 0 is no texture, whatever its name: a side naming it
# names none.
def Gfx.rename(names: List<&2, String>, +first: String) -> List<&2, String>:
  match names:
    case []:
      []
    case +name <> rest:
      Bool.pick(String, String.eq(name, first), "-", name) <> Gfx.rename(rest, first)

def Gfx.first(names: List<&2, String>) -> String:
  match names:
    case []:
      "-"
    case name <> rest:
      name

# The frames of the animations the map touches, then the textures the
# sides name, the sky and the switches' partners, numbered from 1, none
# being 0.
def Gfx.load.names(base: Gfx.Base, +dir: Map<&2, W.Wad.Lump>, pnames: W.Wad.Lump,
  +offs: List<&2, U32>, p: Array<U32> & List<&2, String>) ->
  Result<&1, &1, U32 & String, Array<U32> & Gfx & L.Level>:
  Base{+level, fl, pal, cmap, flats, sprites, Anims{flatanim, none, clock}, bar, font} = base
  (a, +names) = p
  +unnamed = {Names{Map.set(&2, U32, Map.new(&2, U32), "-", 0), 1, [], ["-"]} : Gfx.Names}
  +sides = Gfx.rename(List.append(&2, String, L.Level.texnames(level), ["SKY1"]), Gfx.first(names))
  +frames = Gfx.anim.wanted(Gfx.anim.textures(), names, Gfx.names(sides, unnamed))
  +named = Gfx.names.after(frames, sides, unnamed)
  +tn = Gfx.names(Gfx.switch.wanted(Gfx.switch.pairs(), named), named)
  Result.bind(&1, &1, U32 & String, List<&2, W.Wad.Lump>, Array<U32> & Gfx & L.Level,
    Gfx.lookup(List.drop(&2, String, Gfx.Names.distinct(tn), 1n), Gfx.defs(names, offs),
      "R_TextureNumForName"),
    +defs => Gfx.load.headers(Base{level, fl, pal, cmap, flats, sprites, Anims{flatanim,
        Gfx.anim.of(frames, 1, Gfx.Names.next(tn)), clock}, bar, font},
      dir, tn, defs, pnames, B.Bytes.each(~U32, ~B.Bytes.u16, Gfx.plan(defs, [12, 14, 20]), a)))

# A texture lump's definition offsets made absolute, lump after lump.
def Gfx.absolute(lumps: List<&2, W.Wad.Lump>, lists: List<&2, List<&2, U32>>) -> List<&2, U32>:
  match lumps lists:
    case l <> ls offs <> os:
      List.append(&2, U32, B.Bytes.fields.one(offs, Gfx.lump.pos(l), []), Gfx.absolute(ls, os))
    case _ _:
      []

def Gfx.load.offs(+base: Gfx.Base, +dir: Map<&2, W.Wad.Lump>, pnames: W.Wad.Lump,
  texlumps: List<&2, W.Wad.Lump>, p: Array<U32> & List<&2, List<&2, U32>>) ->
  Result<&1, &1, U32 & String, Array<U32> & Gfx & L.Level>:
  (a, lists) = p
  +offs = Gfx.absolute(texlumps, lists)
  Gfx.load.names(base, dir, pnames, offs, B.Bytes.each(~String, ~B.Bytes.name, offs, a))

def Gfx.load.counts(+base: Gfx.Base, +dir: Map<&2, W.Wad.Lump>, pnames: W.Wad.Lump,
  +texlumps: List<&2, W.Wad.Lump>, p: Array<U32> & List<&2, U32>) ->
  Result<&1, &1, U32 & String, Array<U32> & Gfx & L.Level>:
  (a, counts) = p
  Gfx.load.offs(base, dir, pnames, texlumps,
    B.Bytes.lists(~U32, ~B.Bytes.u32, Gfx.runs(texlumps, counts, 4, 4, [0]), a))

def Gfx.present(l: W.Wad.Lump) -> Bool:
  Bool.not(U32.is_eq(Gfx.lump.pos(l), Gfx.none()))

# The texture definitions are TEXTURE1's and then TEXTURE2's, when the
# WAD has the second.
def Gfx.texlumps(+dir: Map<&2, W.Wad.Lump>, texture1: W.Wad.Lump) -> List<&2, W.Wad.Lump>:
  texture1 <> List.filter(~W.Wad.Lump, ~Gfx.present, [Gfx.lump.get(dir, "TEXTURE2")])

# Each lump's count, then its offsets, then the name at each.
def Gfx.load.textures(+base: Gfx.Base, +dir: Map<&2, W.Wad.Lump>, a: Array<U32>, pnames: W.Wad.Lump,
  +texture1: W.Wad.Lump) -> Result<&1, &1, U32 & String, Array<U32> & Gfx & L.Level>:
  Gfx.load.counts(base, dir, pnames, Gfx.texlumps(dir, texture1),
    B.Bytes.each(~U32, ~B.Bytes.u32, Gfx.plan(Gfx.texlumps(dir, texture1), [0]), a))

def Gfx.load.go(+lumps: List<&2, W.Wad.Lump>, q: Array<U32> & L.Level) ->
  Result<&1, &1, U32 & String, Array<U32> & Gfx & L.Level>:
  (a, +level) = q
  +dir = Gfx.dir(lumps, Map.new(&2, W.Wad.Lump))
  +unnamed = {Names{Map.new(&2, U32), 0, [], []} : Gfx.Names}
  +frames = Gfx.anim.wanted(Gfx.anim.flats(), Gfx.flats.wad(lumps, False{}),
    Gfx.names(L.Level.flatnames(level), unnamed))
  +fl = Gfx.names.after(frames, L.Level.flatnames(level), unnamed)
  do Result<&1, &1, U32 & String, Array<U32> & Gfx & L.Level>:
    pal : W.Wad.Lump <- Gfx.lump(dir, "W_GetNumForName", "PLAYPAL")
    cmap : W.Wad.Lump <- Gfx.lump(dir, "W_GetNumForName", "COLORMAP")
    flats : List<&2, W.Wad.Lump> <- Gfx.lookup(Gfx.Names.distinct(fl), dir, "R_FlatNumForName")
    pnames : W.Wad.Lump <- Gfx.lump(dir, "W_GetNumForName", "PNAMES")
    texture1 : W.Wad.Lump <- Gfx.lump(dir, "W_GetNumForName", "TEXTURE1")
    sprites : Gfx.Sprites <- Gfx.sprites(Gfx.sprite.rows(H.Thing.spawn(level, 0)), Gfx.sprite.space(lumps, False{}))
    bar : List<&2, W.Wad.Lump> <- Gfx.lookup(Gfx.bar.names(), dir, "W_GetNumForName")
    font : List<&2, W.Wad.Lump> <- Gfx.lookup(Gfx.font.names(), dir, "W_CacheLumpName")
    Gfx.load.textures(Base{level, fl, pal, cmap, flats, sprites,
      Anims{Gfx.anim.of(frames, 0, Gfx.Names.next(fl)), Gfx.anim.of([], 1, 0), 0}, bar, font}, dir, a, pnames,
      texture1)

# Freedoom's DEHACKED changes S_POSS_ATK2 to full-bright. It is the
# only patched firing frame reachable in these E1M1s; shareware keeps
# info.c's frame 5 without that bit. Read the lump rather than changing
# the common state table or identifying the WAD by its filename.
def Gfx.deh.value(fields: List<&2, String>, selected: Bool, +old: U32) -> U32:
  match fields selected:
    case key <> value <> Nil{} True{}:
      Bool.pick(U32, String.eq(String.trim(key), "sprite subnumber"),
        Maybe.default(&2, U32, U32.read(String.trim(value)), old), old)
    case _ _:
      old

def Gfx.deh.selected(+line: String, selected: Bool) -> Bool:
  Bool.pick(Bool, String.starts_with(line, "frame "), String.eq(line, "frame 185"), selected)

def Gfx.deh.lines(lines: List<&2, String>, +selected: Bool, old: U32) -> U32:
  match lines:
    case []:
      ((old >> 15n : U32) .&. 1 : U32)
    case line <> rest:
      +text = String.to_lower(String.trim(line))
      Gfx.deh.lines(rest, Gfx.deh.selected(text, selected),
        Gfx.deh.value(String.split(text, '='), selected, old))

def Gfx.deh.views(n: Nat, +rot: U32, +bright: U32, table: V.Vec) -> V.Vec:
  match n:
    case 0n:
      table
    case 1n+k:
      Gfx.deh.views(k, (rot + 1 : U32), bright,
        V.Vec.set(table, ((185 * 8 + rot) * 6 + 5 : U32), bright))

def Gfx.deh.loaded(bright: U32, p: Array<U32> & Gfx & L.Level) -> Array<U32> & Gfx & L.Level:
  (a, gfx, level) = p
  Gfx{flats, pics, sky, texs, cols, sidetex, skytex, sprites, anims, bar, font} = gfx
  (a, Gfx{flats, pics, sky, texs, cols, sidetex, skytex, Gfx.deh.views(8n, 0, bright, sprites), anims, bar,
    font}, level)

def Gfx.deh.read(+episode: U32, +map: U32, +lumps: List<&2, W.Wad.Lump>, p: Array<U32> & String) ->
  Result<&1, &1, U32 & String, Array<U32> & Gfx & L.Level>:
  (a, text) = p
  +bright = Gfx.deh.lines(String.lines(text), False{}, 5)
  Result.map(&1, &1, U32 & String, Array<U32> & Gfx & L.Level, Array<U32> & Gfx & L.Level,
    loaded => Gfx.deh.loaded(bright, loaded),
    Result.bind(&1, &1, U32 & String, Array<U32> & L.Level, Array<U32> & Gfx & L.Level,
      L.Level.load(episode, map, (a, lumps)), level => Gfx.load.go(lumps, level)))

def Gfx.deh.at(+episode: U32, +map: U32, +lumps: List<&2, W.Wad.Lump>, a: Array<U32>, span: U32 & U32) ->
  Result<&1, &1, U32 & String, Array<U32> & Gfx & L.Level>:
  (pos, size) = span
  Gfx.deh.read(episode, map, lumps, B.Bytes.text(a, pos, U32.to_nat(size)))

# Map ExMy and its graphics from the WAD's bytes and directory, or
# Doom's error for a name the WAD lacks. The WAD's bytes are dropped.
def Gfx.load(+episode: U32, +map: U32, p: Array<U32> & List<&2, W.Wad.Lump>) ->
  Result<&1, &1, U32 & String, Array<U32> & Gfx & L.Level>:
  (a, +lumps) = p
  Gfx.deh.at(episode, map, lumps, a, W.Wad.find(lumps, "DEHACKED"))

# Map ExMy and its graphics from the WAD BENDOOM_IWAD names; a WAD that
# cannot be read, or a name it lacks, ends the program with the error.
def Gfx.open(+episode: U32, +map: U32) -> IO(Array<U32> & Gfx & L.Level):
  do IO<Array<U32> & Gfx & L.Level>:
    dir : Array<U32> & List<&2, W.Wad.Lump> <- W.Wad.open()
    IO.pass(Array<U32> & Gfx & L.Level, Gfx.load(episode, map, dir))

# Lookups
# -------

def Gfx.flat(+g: Gfx, pic: U32) -> U32:
  Gfx{flats, pics, sky, texs, cols, sidetex, skytex, sprites, anims, bar, font} = g
  V.Vec.get(flats, pic)

# The flat a sector's floor or ceiling shows.
def Gfx.pic(+g: Gfx, at: U32) -> U32:
  Gfx{flats, pics, sky, texs, cols, sidetex, skytex, sprites, Anims{Anim{rows, first, shown}, texanim, clock}, bar, font} = g
  V.Vec.get(shown, V.Vec.get(pics, at))

def Gfx.floorpic(+g: Gfx, sector: U32) -> U32:
  Gfx.pic(g, (sector * 2 : U32))

def Gfx.ceilpic(+g: Gfx, sector: U32) -> U32:
  Gfx.pic(g, (sector * 2 + 1 : U32))

def Gfx.sky(+g: Gfx) -> U32:
  Gfx{flats, pics, sky, texs, cols, sidetex, skytex, sprites, anims, bar, font} = g
  sky

def Gfx.skytex(+g: Gfx) -> U32:
  Gfx{flats, pics, sky, texs, cols, sidetex, skytex, sprites, anims, bar, font} = g
  skytex

# The texture a side shows, 0 for none.
def Gfx.sidetex(+g: Gfx, at: U32) -> U32:
  Gfx{flats, pics, sky, texs, cols, sidetex, skytex, sprites, Anims{flatanim, Anim{rows, first, shown}, clock}, bar, font} = g
  V.Vec.get(shown, V.Vec.get(sidetex, at))

def Gfx.top(+g: Gfx, side: U32) -> U32:
  Gfx.sidetex(g, (side * 3 : U32))

def Gfx.bottom(+g: Gfx, side: U32) -> U32:
  Gfx.sidetex(g, (side * 3 + 1 : U32))

def Gfx.mid(+g: Gfx, side: U32) -> U32:
  Gfx.sidetex(g, (side * 3 + 2 : U32))

def Gfx.tex.width(+g: Gfx, t: U32) -> U32:
  Gfx{flats, pics, sky, texs, cols, sidetex, skytex, sprites, anims, bar, font} = g
  V.Vec.get(texs, (t * 5 : U32))

# A texture's height in fixed point, as pegging uses it.
def Gfx.tex.height(+g: Gfx, t: U32) -> U32:
  Gfx{flats, pics, sky, texs, cols, sidetex, skytex, sprites, anims, bar, font} = g
  F.Fixed.of_map(V.Vec.get(texs, (t * 5 + 1 : U32)))

def Gfx.tex.patches(+g: Gfx, t: U32) -> U32:
  Gfx{flats, pics, sky, texs, cols, sidetex, skytex, sprites, anims, bar, font} = g
  V.Vec.get(texs, (t * 5 + 2 : U32))

def Gfx.tex.mask(+g: Gfx, t: U32) -> U32:
  Gfx{flats, pics, sky, texs, cols, sidetex, skytex, sprites, anims, bar, font} = g
  V.Vec.get(texs, (t * 5 + 3 : U32))

# Where a texture's columns start in the column table.
def Gfx.tex.first(+g: Gfx, t: U32) -> U32:
  Gfx{flats, pics, sky, texs, cols, sidetex, skytex, sprites, anims, bar, font} = g
  V.Vec.get(texs, (t * 5 + 4 : U32))

# Doom's R_GetColumn, the texture's part looked up beforehand: the index
# of a texture column's texels, the column wrapped by the width mask. A
# patch column's first post header sits three before it.
def Gfx.column.at(+g: Gfx, first: U32, mask: U32, col: U32) -> U32:
  Gfx{flats, pics, sky, texs, cols, sidetex, skytex, sprites, anims, bar, font} = g
  V.Vec.get(cols, (first + (col .&. mask) : U32))

def Gfx.column(+g: Gfx, +t: U32, col: U32) -> U32:
  Gfx.column.at(g, Gfx.tex.first(g, t), Gfx.tex.mask(g, t), col)

def Gfx.clock(g: Gfx) -> U32:
  Gfx{flats, pics, sky, texs, cols, sidetex, skytex, sprites, Anims{flatanim, texanim, clock}, bar, font} = g
  clock

def Gfx.Anim.at(a: Gfx.Anim, clock: U32) -> Gfx.Anim:
  Anim{+rows, +first, shown} = a
  Anim{rows, first, Gfx.anim.update(rows, clock, first, shown)}

# The graphics with a state's side textures and clock where the renderer
# looks, the animations shown as they are at that clock.
def Gfx.of_state(g: Gfx, sidetex: V.Vec, +clock: U32) -> Gfx:
  Gfx{flats, pics, sky, texs, cols, loaded, skytex, sprites, Anims{flatanim, texanim, was}, bar, font} = g
  Gfx{flats, pics, sky, texs, cols, sidetex, skytex, sprites,
    Anims{Gfx.Anim.at(flatanim, clock), Gfx.Anim.at(texanim, clock), clock}, bar, font}

# Word k of a state row's sprite seen at rotation index rot (0 for
# rotation 1): 0 its patch's index, 1 its width, 2 its left offset, 3
# its top offset, 4 whether it is mirrored, 5 whether its frame is
# full-bright.
def Gfx.sprite(+g: Gfx, state: U32, rot: U32, k: U32) -> U32:
  Gfx{flats, pics, sky, texs, cols, sidetex, skytex, sprites, anims, bar, font} = g
  V.Vec.get(sprites, ((state * 8 + rot) * 6 + k : U32))

# The index in the array of status bar patch k: 0 to 9 the tall digits,
# 10 to 19 the short ones, 20 the percent sign, 21 to 26 the key icons,
# 27 to 32 the grey weapon numbers, 33 the arms panel, 34 the
# background, 35 to 76 the faces, as Gfx.bar.names() lists them.
def Gfx.bar(+g: Gfx, k: U32) -> U32:
  Gfx{flats, pics, sky, texs, cols, sidetex, skytex, sprites, anims, bar, font} = g
  V.Vec.get(bar, k)

def Gfx.patch.go(names: List<&2, String>, +name: String, +i: U32, +g: Gfx) -> U32:
  match names:
    case []:
      0
    case got <> rest:
      Bool.pick(U32, String.eq(got, name), Gfx.bar(g, i), Gfx.patch.go(rest, name, (i + 1 : U32), g))

def Gfx.patch(+g: Gfx, name: String) -> U32:
  Gfx.patch.go(Gfx.bar.names(), name, 0, g)

# The index in the array of the heads-up font's patch for a character's
# place from HU_FONTSTART.
def Gfx.font(+g: Gfx, i: U32) -> U32:
  Gfx{flats, pics, sky, texs, cols, sidetex, skytex, sprites, anims, bar, font} = g
  V.Vec.get(font, i)
