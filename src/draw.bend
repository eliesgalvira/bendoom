# The draw's state: the one linear array and the lists Doom keeps in
# static arrays, here with no limit. One value threaded through the BSP
# walk, since every step reads what the last wrote.
import Base
import ./vec.bend as V
import ./bytes.bend as B
import ./fixed.bend as F
import ./clip.bend as C
import ./gfx.bend as G

# The walk's work, a stack: a node or subsector to visit, a node's far
# child to visit if its box might show, a seg to add.
type Draw.Task is Data:
  Visit{node: U32}
  Check{node: U32, side: U32}
  Line{seg: U32}

# A stored wall range, Doom's drawseg: the seg, its first and last
# column, and its scale at each with the step between; its silhouette (1
# clips sprites behind it at the bottom, 2 at the top) with the heights
# it clips below and above; and, a column each from the first, the
# texture columns of a two-sided middle texture (none without one), a
# column already drawn holding Masked.drawn() instead, and the ceiling
# and floor clips the range left, which clip what is drawn behind it
# later.
type Draw.Wall is Data:
  Wall{seg: U32, x1: U32, x2: U32, scale1: U32, scale2: U32, step: U32, sil: U32, bsil: U32, tsil: U32,
    texcols: List<&2, U32>, tops: List<&2, U32>, bottoms: List<&2, U32>}

# A visplane's head: its height, flat and light, and the columns it
# spans so far (from 320 to -1 while it spans none).
type Draw.Plane is Data:
  Plane{height: U32, pic: U32, light: U32, minx: U32, maxx: U32}

# Doom's visplanes, with no limit: the heads in the order they were
# made, which Doom's search and its drawing follow; how many; their
# columns, 1024 slots a plane (the top row of column x at x + 1, the
# bottom at x + 513, a top of 255 for a column not marked) in an array
# of 2^depth slots that doubles when it fills; and the floor and ceiling
# planes of the subsector being drawn, 4294967295 for none.
type Draw.Planes is Type:
  Planes{heads: List<&2, Draw.Plane>, count: U32, cols: Array<U32>, depth: Nat, floor: U32, ceil: U32}

# The sectors the walk has seen, Doom's validcount: for each, its rank
# among them in the order the walk first reached them, from 1, and 0
# for one not reached; and the rank the next subsector would give.
type Draw.Seen is Data:
  Seen{ranks: V.Vec, next: U32}

# mem: the frame, the clip arrays and the graphics. solid: the solid
# columns. walls: the stored ranges, newest first. tasks: the walk's
# stack. planes: the visplanes. seen: the sectors the walk has seen.
type Draw is Type:
  Draw{mem: Array<U32>, solid: List<&2, C.Clip.Range>, walls: List<&2, Draw.Wall>,
    tasks: List<&2, Draw.Task>, planes: Draw.Planes, seen: Draw.Seen}

# Drawing
# -------

# f at every index from i, n of them, in order: the loop under every
# column and span, so that the law on which indices it reaches covers
# them all. The state carries what f needs, since a template's function
# is closed.
def Draw.each(~S: Type, ~f: Nat -> S -> S, n: Nat, +i: Nat, st: S) -> S:
  match n:
    case 0n:
      st
    case 1n+m:
      Draw.each(~S, ~f, m, 1n+i, f(i, st))

# How many rows or columns from lo to hi, both signed: none when hi is
# before lo.
def Draw.rows(+lo: U32, +hi: U32) -> Nat:
  U32.to_nat(Bool.pick(U32, F.Fixed.lt(hi, lo), 0, (hi - lo + 1 : U32)))

# A pixel's index in the frame.
def Draw.at(x: U32, row: Nat) -> U32:
  (G.Gfx.frame() + U32.from_nat(row) * 320 + x : U32)

# A column's state: the array, the column, the texture fraction at the
# next row with its step a row, the index of the texture column's
# texels, and of the colormap.
type Draw.Col is Type:
  Col{mem: Array<U32>, x: U32, frac: U32, step: U32, src: U32, cmap: U32}

def Draw.col.lit(row: Nat, +x: U32, +frac: U32, +step: U32, src: U32, cmap: U32, p: Array<U32> & U32) ->
  Draw.Col:
  (mem, c) = p
  Col{Array.set(U32, mem, Draw.at(x, row), c), x, (frac + step : U32), step, src, cmap}

def Draw.col.texel(row: Nat, x: U32, frac: U32, step: U32, src: U32, +cmap: U32, p: Array<U32> & U32) ->
  Draw.Col:
  (mem, t) = p
  Draw.col.lit(row, x, frac, step, src, cmap, B.Bytes.at(mem, (cmap + t : U32)))

# Doom's R_DrawColumn for one row: the texel at the fraction's whole
# part, wrapped to 128 rows, through the colormap.
def Draw.col.px(row: Nat, st: Draw.Col) -> Draw.Col:
  Col{mem, x, +frac, step, +src, cmap} = st
  Draw.col.texel(row, x, frac, step, src, cmap, B.Bytes.at(mem, (src + ((frac >> 16n) .&. 127) : U32)))

def Draw.Col.mem(st: Draw.Col) -> Array<U32>:
  Col{mem, x, frac, step, src, cmap} = st
  mem

# Column x from row yl to yh: the texture column at src, its row mid at
# the view's centre row, stepped iscale a row, lit through cmap.
def Draw.column(mem: Array<U32>, x: U32, +yl: U32, yh: U32, src: U32, mid: U32, +iscale: U32,
  cmap: U32) -> Array<U32>:
  Draw.Col.mem(Draw.each(~Draw.Col, ~Draw.col.px, Draw.rows(yl, yh), U32.to_nat(yl),
    Col{mem, x, (mid + (yl - 84) * iscale : U32), iscale, src, cmap}))

# A span's state: the array, the index of its row's first pixel, the
# packed position in the flat at the next column with its step, and the
# indices of the flat and the colormap.
type Draw.Span is Type:
  Span{mem: Array<U32>, row: U32, position: U32, step: U32, src: U32, cmap: U32}

# The DOS executable's span position, which Chocolate Doom keeps: x in
# the top sixteen bits and y in the bottom, each six whole bits over ten
# of fraction, so a span drifts from the 16.16 fractions as it runs, and
# y's overflow carries into x.
def Draw.span.pack(xfrac: U32, yfrac: U32) -> U32:
  (((xfrac << 10n) .&. 4294901760) .|. ((yfrac >> 6n) .&. 65535) : U32)

# The texel of a packed position in a 64 by 64 flat.
def Draw.span.spot(+position: U32) -> U32:
  (((position >> 4n) .&. 4032) .|. (position >> 26n) : U32)

def Draw.span.lit(x: U32, +row: U32, +position: U32, +step: U32, src: U32, cmap: U32,
  p: Array<U32> & U32) -> Draw.Span:
  (mem, c) = p
  Span{Array.set(U32, mem, (row + x : U32), c), row, (position + step : U32), step, src, cmap}

def Draw.span.texel(x: U32, row: U32, position: U32, step: U32, src: U32, +cmap: U32,
  p: Array<U32> & U32) -> Draw.Span:
  (mem, t) = p
  Draw.span.lit(x, row, position, step, src, cmap, B.Bytes.at(mem, (cmap + t : U32)))

# Doom's R_DrawSpan for one column: the flat's texel at the position,
# through the colormap.
def Draw.span.px(i: Nat, st: Draw.Span) -> Draw.Span:
  Span{mem, row, +position, step, +src, cmap} = st
  Draw.span.texel(U32.from_nat(i), row, position, step, src, cmap, B.Bytes.at(mem,
    (src + Draw.span.spot(position) : U32)))

def Draw.Span.mem(st: Draw.Span) -> Array<U32>:
  Span{mem, row, position, step, src, cmap} = st
  mem

# Row y from column x1 to x2 of a flat.
def Draw.span(mem: Array<U32>, y: U32, +x1: U32, x2: U32, xfrac: U32, yfrac: U32, xstep: U32,
  ystep: U32, src: U32, cmap: U32) -> Array<U32>:
  Draw.Span.mem(Draw.each(~Draw.Span, ~Draw.span.px, Draw.rows(x1, x2), U32.to_nat(x1),
    Span{mem, (G.Gfx.frame() + y * 320 : U32), Draw.span.pack(xfrac, yfrac), Draw.span.pack(xstep, ystep),
      src, cmap}))

# n slots from i set to v.
def Draw.set(n: Nat, mem: Array<U32>, +i: U32, +v: U32) -> Array<U32>:
  match n:
    case 0n:
      mem
    case 1n+m:
      Draw.set(m, Array.set(U32, mem, i, v), (i + 1 : U32), v)

# Doom's R_ClearPlanes: no column is clipped yet, the ceiling's clip
# above row 0 and the floor's below the last.
def Draw.clear(mem: Array<U32>) -> Array<U32>:
  Draw.set(320n, Draw.set(320n, mem, G.Gfx.ceilclip(), 4294967295), G.Gfx.floorclip(), 168)

# Patches
# -------

# n slots copied from the array down a screen column, a row apart.
def Draw.down(n: Nat, +from: U32, +to: U32, mem: Array<U32>) -> Array<U32>:
  match n:
    case 0n:
      mem
    case 1n+m:
      Draw.down(m, (from + 1 : U32), (to + 320 : U32), G.Gfx.move.put(to, B.Bytes.at(mem, from)))

# V_DrawPatch's inner loop for one post: its texels straight down the
# screen from the post's row, with no colormap and no clip, since the
# heads-up line draws inside the screen.
def Draw.patch.post(mem: Array<U32>, +src: U32, +delta: U32, +len: U32, +at: U32) -> Array<U32>:
  Draw.down(U32.to_nat(len), (src + 3 : U32), (at + delta * 320 : U32), mem)

# The patch being drawn: the array, the patch's index and the index in
# the frame of the top of the column to come.
type Draw.Patch is Type:
  Patch{mem: Array<U32>, patch: U32, at: U32}

def Draw.patch.col.of(+patch: U32, +at: U32, p: Array<U32> & U32) -> Draw.Patch:
  (mem, +off) = p
  Patch{G.Gfx.posts(~U32, ~Draw.patch.post, 256n, G.Post{False{}, mem, (patch + off : U32)}, at), patch,
    (at + 1 : U32)}

def Draw.patch.col(c: Nat, st: Draw.Patch) -> Draw.Patch:
  Patch{mem, +patch, +at} = st
  Draw.patch.col.of(patch, at, B.Bytes.u32(mem, (patch + 8 + U32.from_nat(c) * 4 : U32)))

def Draw.Patch.mem(st: Draw.Patch) -> Array<U32>:
  Patch{mem, patch, at} = st
  mem

def Draw.patch.of(+patch: U32, +x: U32, +y: U32, p: Array<U32> & List<&2, U32>) -> Array<U32>:
  (mem, dims) = p
  match dims:
    case width <> left <> top <> rest:
      Draw.Patch.mem(Draw.each(~Draw.Patch, ~Draw.patch.col, U32.to_nat(width), 0n,
        Patch{mem, patch, (G.Gfx.frame() + (y - G.Gfx.s16(top)) * 320 + x - G.Gfx.s16(left) : U32)}))
    case _:
      mem

# Doom's V_DrawPatch: the patch's columns from x, y with its offsets
# taken off, post by post, straight into the frame.
def Draw.patch(mem: Array<U32>, +patch: U32, x: U32, y: U32) -> Array<U32>:
  Draw.patch.of(patch, x, y, B.Bytes.each(~U32, ~B.Bytes.u16, [patch, (patch + 4 : U32), (patch + 6 : U32)], mem))

type Draw.Glyph is Type:
  Glyph{mem: Array<U32>, x: U32, done: Bool}

def Draw.glyph.fit(fits: Bool, +x: U32, y: U32, w: U32, patch: U32, mem: Array<U32>) -> Draw.Glyph:
  match fits:
    case False{}:
      Glyph{mem, x, True{}}
    case True{}:
      Glyph{Draw.patch(mem, patch, x, y), (x + w : U32), False{}}

def Draw.glyph.wide(+x: U32, y: U32, patch: U32, p: Array<U32> & U32) -> Draw.Glyph:
  (mem, +w) = p
  Draw.glyph.fit(U32.is_le((x + w : U32), 320), x, y, w, patch, mem)

def Draw.glyph(x: U32, y: U32, +patch: U32, mem: Array<U32>) -> Draw.Glyph:
  Draw.glyph.wide(x, y, patch, B.Bytes.u16(mem, patch))
