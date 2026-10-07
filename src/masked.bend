# Doom's R_RenderMaskedSegRange: a stored range's two-sided middle
# texture drawn column by column through its posts, so its gaps show
# what is behind it, over the columns the sprites' pass asks for, each
# column once.
import Base
import ./fixed.bend as F
import ./level.bend as L
import ./gfx.bend as G
import ./project.bend as P
import ./draw.bend as D
import ./segs.bend as S

# A masked column: its screen column, the screen row of its texture's
# top as fixed point, its scale, its texture's row at the eye's height,
# the reciprocal scale, the colormap, and the clips above and below.
type Masked.Col is Data:
  Col{x: U32, top: U32, scale: U32, mid: U32, iscale: U32, cmap: U32, cc: U32, fc: U32}

# Doom's R_DrawMaskedColumn for one post: its rows on the screen from
# its row in the texture and its length, held inside the clips, and its
# texels drawn from its own first row.
def Masked.post(mem: Array<U32>, +src: U32, +delta: U32, +len: U32, +col: Masked.Col) -> Array<U32>:
  Col{x, +top, +scale, mid, iscale, cmap, cc, fc} = col
  +topscreen = (top + scale * delta : U32)
  D.Draw.column(mem, x,
    F.Fixed.max(F.Fixed.sarn((topscreen + 65535 : U32), 16n), (cc + 1 : U32)),
    F.Fixed.min(F.Fixed.sarn((topscreen + scale * len - 1 : U32), 16n), (fc - 1 : U32)),
    (src + 3 : U32), (mid - (delta << 16n) : U32), iscale, cmap)

# What a range's masked columns share: the graphics, the texture, the
# range's first column with its scale and step, the texture's row at
# the eye's height, and the light number.
type Masked.Range is Data:
  Range{gfx: G.Gfx, tex: U32, x1: U32, scale1: U32, step: U32, mid: U32, lightnum: U32, fixedcolormap: U32}

# Doom's R_RenderMaskedSegRange for one column: the posts start three
# before the texture column's texels.
def Masked.column(mem: Array<U32>, +x: U32, texcol: U32, cc: U32, fc: U32, range: Masked.Range) ->
  Array<U32>:
  Range{gfx, tex, x1, scale1, step, +mid, lightnum, fixedcolormap} = range
  +scale = (scale1 + (x - x1) * step : U32)
  G.Gfx.posts(~Masked.Col, ~Masked.post, 256n, G.Post{False{}, mem, (G.Gfx.column(gfx, tex, texcol) - 3 : U32)},
    Col{x, (P.Project.centery() - F.Fixed.mul(mid, scale) : U32), scale, mid, S.Segs.iscale(scale),
      S.Segs.colormap(fixedcolormap, lightnum, scale), cc, fc})

# The texture column left in a column once drawn: Doom's SHRT_MAX, here
# a value no texture column takes.
def Masked.drawn() -> U32:
  2147483647

# A column the pass asks for and still pending is drawn and left drawn;
# any other is left as it was. The texture columns gather last first.
def Masked.step(asked: Bool, +x: U32, +texcol: U32, cc: U32, fc: U32, +range: Masked.Range,
  st: Array<U32> & List<&2, U32>) -> Array<U32> & List<&2, U32>:
  match asked:
    case True{}:
      (mem, left) = st
      (Masked.column(mem, x, texcol, cc, fc, range), Masked.drawn() <> left)
    case False{}:
      (mem, left) = st
      (mem, texcol <> left)

def Masked.columns(texcols: List<&2, U32>, tops: List<&2, U32>, bottoms: List<&2, U32>, +x: U32, +r1: U32,
  +r2: U32, +range: Masked.Range, st: Array<U32> & List<&2, U32>) -> Array<U32> & List<&2, U32>:
  match texcols tops bottoms:
    case +texcol <> cs cc <> ts fc <> bs:
      Masked.columns(cs, ts, bs, (x + 1 : U32), r1, r2, range,
        Masked.step(Bool.and(U32.is_le(r1, x), Bool.and(U32.is_le(x, r2),
          Bool.not(U32.is_eq(texcol, Masked.drawn())))), x, texcol, cc, fc, range, st))
    case _ _ _:
      st

# The texture stands on the higher floor when the line is pegged to the
# bottom, else hangs from the lower ceiling; then moves by the side's
# row offset.
def Masked.mid(f: L.Level.Sector, b: L.Level.Sector, side: L.Level.Side, flags: U32, height: U32,
  vz: U32) -> U32:
  L.Sector{ffloor, fceil, flight} = f
  L.Sector{bfloor, bceil, blight} = b
  L.Side{xoff, yoff, sector} = side
  (Bool.pick(U32, U32.is_zero((flags .&. 16 : U32)), F.Fixed.min(fceil, bceil),
    (F.Fixed.max(ffloor, bfloor) + height : U32)) - vz + yoff : U32)

def Masked.range(+view: P.View, +level: L.Level, +gfx: G.Gfx, +seg: L.Level.Seg, x1: U32, scale1: U32,
  step: U32) -> Masked.Range:
  L.Seg{sx1, sy1, sx2, sy2, angle, offset, flags, +side, +front, back} = seg
  Range{gfx, G.Gfx.mid(gfx, side), x1, scale1, step,
    Masked.mid(L.Level.sector(level, front), L.Level.sector(level, back), L.Level.side(level, side), flags,
      G.Gfx.tex.height(gfx, G.Gfx.mid(gfx, side)), P.View.z(view)),
    S.Segs.lightnum(seg, L.Level.sector.light(level, front), P.View.extralight(view)), P.View.fixedcolormap(view)}

def Masked.wall.left(wall: D.Draw.Wall, st: Array<U32> & List<&2, U32>) -> Array<U32> & D.Draw.Wall:
  D.Wall{seg, x1, x2, scale1, scale2, step, sil, bsil, tsil, texcols, tops, bottoms} = wall
  (mem, left) = st
  (mem, D.Wall{seg, x1, x2, scale1, scale2, step, sil, bsil, tsil, List.reverse(&2, U32, left), tops, bottoms})

# The range's columns from r1 to r2 still pending drawn, and the range
# left with them drawn. One with no middle texture has no texture
# columns, and is passed over before anything is worked out for it.
def Masked.wall(+view: P.View, +level: L.Level, +gfx: G.Gfx, +r1: U32, +r2: U32, +wall: D.Draw.Wall,
  mem: Array<U32>) -> Array<U32> & D.Draw.Wall:
  match wall:
    case D.Wall{seg, x1, x2, scale1, scale2, step, sil, bsil, tsil, [], tops, bottoms}:
      (mem, wall)
    case D.Wall{seg, +x1, x2, scale1, scale2, step, sil, bsil, tsil, texcols, tops, bottoms}:
      Masked.wall.left(wall, Masked.columns(texcols, tops, bottoms, x1, r1, r2,
        Masked.range(view, level, gfx, L.Level.seg(level, seg), x1, scale1, step), (mem, [])))

def Masked.mem(p: Array<U32> & D.Draw.Wall) -> Array<U32>:
  (mem, wall) = p
  mem

# Doom's last loop in R_DrawMasked: the columns no sprite drew, every
# stored range's, newest first.
def Masked.draw(walls: List<&2, D.Draw.Wall>, +view: P.View, +level: L.Level, +gfx: G.Gfx,
  mem: Array<U32>) -> Array<U32>:
  match walls:
    case []:
      mem
    case wall <> rest:
      Masked.draw(rest, view, level, gfx, Masked.mem(Masked.wall(view, level, gfx, 0, 319, wall, mem)))
