# Doom's R_AddSprites, R_ProjectSprite, R_SortVisSprites, R_DrawMasked,
# R_DrawSprite and R_DrawVisSprite: the things in the sectors the walk
# saw, projected from the eye, drawn farthest first, each after the
# masked columns behind it, clipped by the stored ranges in front of it
# and drawn post by post, so the gaps between posts leave the frame as it
# was.
import Base
import ./bytes.bend as B
import ./vec.bend as V
import ./fixed.bend as F
import ./level.bend as L
import ./gfx.bend as G
import ./things.bend as H
import ./project.bend as P
import ./draw.bend as D
import ./segs.bend as S
import ./masked.bend as M

# A thing as the eye sees it, Doom's vissprite: its first and last
# columns, its scale, its origin's x, y and z and its top's z, its
# patch's row at the eye's height, the patch's column at the first
# column as a fraction with its step a column (the reciprocal scale,
# negative for a mirrored patch), the patch's index in the array, the
# colormap, and its place in Doom's list of vissprites: the rank of its
# sector in the walk, and its thing's place among the things shown, which
# come a sector's list at a time.
type Sprites.Vis is Data:
  Vis{x1: U32, x2: U32, scale: U32, gx: U32, gy: U32, gz: U32, gzt: U32, mid: U32, frac: U32, step: U32,
    patch: U32, cmap: U32, rank: U32, nth: U32}

# Doom's -2 in the sprite's clips: a column no range has clipped yet.
def Sprites.unclipped() -> U32:
  4294967294

# Projecting
# ----------

def Sprites.project.if(shows: Bool, vis: Sprites.Vis, rest: List<&2, Sprites.Vis>) -> List<&2, Sprites.Vis>:
  match shows:
    case True{}:
      vis <> rest
    case False{}:
      rest

# The rotation a thing shows, 0 for its front, from the angle of the
# thing from the eye and the thing's facing: each rotation spans the
# eighth of a turn centred on its own angle.
def Sprites.rotation(seen: U32, facing: U32) -> U32:
  ((seen - facing + 2415919104 : U32) >> 29n : U32)

# Doom's R_ProjectSprite: the thing's origin turned into the view, its
# depth tz and its offset tx across it, and the rotation of its frame it
# shows. It shows unless it is nearer than 4 units, farther aside than
# four times its depth, or its patch's edges, placed by its offsets and
# scaled, fall wholly off the screen. The columns are held to the
# screen, and the patch's fraction starts that far in, from its last
# column stepping back for a mirrored patch. Shadow precedes the fixed colormap,
# full-bright and sector lighting at its scale, without fake contrast.
def Sprites.project(+view: P.View, +level: L.Level, +gfx: G.Gfx, rank: U32, nth: U32, thing: H.Thing,
  rest: List<&2, Sprites.Vis>) -> List<&2, Sprites.Vis>:
  P.View{+vx, +vy, +vz, angle, +sin, +cos, tables, extralight, +fixedcolormap} = view
  H.Thing{id, kind, +x, +y, +z, floorz, ceilz, facing, sector, +state, tics, momz, hurt} = thing
  +trx = (x - vx : U32)
  +try = (y - vy : U32)
  +tz = (F.Fixed.mul(trx, cos) + F.Fixed.mul(try, sin) : U32)
  +tx = (F.Fixed.mul(trx, sin) - F.Fixed.mul(try, cos) : U32)
  +xscale = F.Fixed.div(P.Project.centerx(), tz)
  +rot = Sprites.rotation(P.View.angle_to(view, x, y), facing)
  +width = G.Gfx.sprite(gfx, state, rot, 1)
  +left = (tx - G.Gfx.sprite(gfx, state, rot, 2) : U32)
  +x1 = F.Fixed.sarn((P.Project.centerx() + F.Fixed.mul(left, xscale) : U32), 16n)
  +x2 = (F.Fixed.sarn((P.Project.centerx() + F.Fixed.mul((left + width : U32), xscale) : U32), 16n) - 1 : U32)
  +gzt = (z + G.Gfx.sprite(gfx, state, rot, 3) : U32)
  +flip = U32.is_eq(G.Gfx.sprite(gfx, state, rot, 4), 1)
  +iscale = F.Fixed.div(65536, xscale)
  +step = Bool.pick(U32, flip, F.Fixed.neg(iscale), iscale)
  +first = F.Fixed.max(x1, 0)
  Sprites.project.if(Bool.and(F.Fixed.ge(tz, 262144), Bool.and(F.Fixed.le(F.Fixed.abs(tx), (tz << 2n : U32)),
      Bool.and(F.Fixed.le(x1, 320), F.Fixed.ge(x2, 0)))),
    Vis{first, F.Fixed.min(x2, 319), xscale, x, y, z, gzt, (gzt - vz : U32),
      (Bool.pick(U32, flip, (width - 1 : U32), 0) + step * (first - x1) : U32), step,
      G.Gfx.sprite(gfx, state, rot, 0), Bool.pick(U32, Bool.not(U32.is_zero((V.Vec.get(hurt, H.Thing.hurt.flags()) .&. 262144 : U32))), 0, Bool.pick(U32, Bool.and(U32.is_zero(fixedcolormap), U32.is_eq(G.Gfx.sprite(gfx, state, rot, 5), 1)),
        G.Gfx.colormap(), S.Segs.colormap(fixedcolormap, P.Project.lightnum(L.Level.sector.light(level, sector), extralight),
        xscale))),
      rank, nth},
    rest)

def Sprites.gather.if(seen: Bool, +view: P.View, +level: L.Level, +gfx: G.Gfx, rank: U32, nth: U32, thing: H.Thing,
  rest: List<&2, Sprites.Vis>) -> List<&2, Sprites.Vis>:
  match seen:
    case True{}:
      Sprites.project(view, level, gfx, rank, nth, thing, rest)
    case False{}:
      rest

# Doom's R_AddSprites: the things of each sector the walk saw, each
# once, since each thing is met once; nth counts them as they come.
def Sprites.gather(things: List<&2, H.Thing>, +nth: U32, +ranks: V.Vec, +view: P.View, +level: L.Level,
  +gfx: G.Gfx) -> List<&2, Sprites.Vis>:
  match things:
    case []:
      []
    case H.Thing{id, kind, x, y, z, floorz, ceilz, angle, +sector, state, tics, momz, hurt} <> rest:
      +rank = V.Vec.get(ranks, sector)
      Sprites.gather.if(Bool.not(U32.is_zero(rank)), view, level, gfx, rank, nth,
        H.Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics, momz, hurt},
        Sprites.gather(rest, (nth + 1 : U32), ranks, view, level, gfx))

# Doom's R_SortVisSprites: whether a sprite is drawn before another. The
# smaller scale goes first; of equal scales, the one earlier in Doom's
# list, which holds the walk's sectors in the order it reached them,
# and each sector's things in the order of its list.
def Sprites.before(a: Sprites.Vis, b: Sprites.Vis) -> Bool:
  Vis{x1, x2, +sa, gx, gy, gz, gzt, mid, frac, step, patch, cmap, +ra, +na} = a
  Vis{y1, y2, +sb, hx, hy, hz, hzt, bmid, bfrac, bstep, bpatch, bcmap, +rb, +nb} = b
  Bool.or(F.Fixed.lt(sa, sb), Bool.and(U32.is_eq(sa, sb),
    Bool.or(U32.is_lt(ra, rb), Bool.and(U32.is_eq(ra, rb), U32.is_lt(na, nb)))))

# Clipping
# --------

# A clip taken when on and the column's is still unclipped.
def Sprites.clip.put(on: Bool, +at: U32, +v: U32, p: Array<U32> & U32) -> Array<U32>:
  (mem, +was) = p
  Array.set(U32, mem, at, Bool.pick(U32, Bool.and(on, U32.is_eq(was, Sprites.unclipped())), v, was))

def Sprites.clip.cols(n: Nat, tops: List<&2, U32>, bottoms: List<&2, U32>, +top: Bool, +bottom: Bool, +x: U32,
  mem: Array<U32>) -> Array<U32>:
  match n tops bottoms:
    case 1n+m t <> ts b <> bs:
      Sprites.clip.cols(m, ts, bs, top, bottom, (x + 1 : U32),
        Sprites.clip.put(top, (G.Gfx.cliptop() + x : U32), t, B.Bytes.at(
          Sprites.clip.put(bottom, (G.Gfx.clipbot() + x : U32), b, B.Bytes.at(mem, (G.Gfx.clipbot() + x : U32))),
          (G.Gfx.cliptop() + x : U32))))
    case _ _ _:
      mem

def Sprites.clip.if(clips: Bool, +top: Bool, +bottom: Bool, +r1: U32, +r2: U32, +x1: U32, tops: List<&2, U32>,
  bottoms: List<&2, U32>, mem: Array<U32>) -> Array<U32>:
  match clips:
    case False{}:
      mem
    case True{}:
      Sprites.clip.cols(D.Draw.rows(r1, r2), List.drop(&2, U32, tops, U32.to_nat((r1 - x1 : U32))),
        List.drop(&2, U32, bottoms, U32.to_nat((r1 - x1 : U32))), top, bottom, r1, mem)

# Doom's R_PointOnSegSide: whether a point is behind the seg.
def Sprites.seg_side(s: L.Level.Seg, +x: U32, +y: U32) -> Bool:
  L.Seg{+x1, +y1, x2, y2, angle, offset, flags, side, front, back} = s
  L.Level.node_side(x, y, x1, y1, (x2 - x1 : U32), (y2 - y1 : U32))

# Whether a stored range is behind the sprite, from whether its larger
# and its smaller scale are under the sprite's: with the smaller alone,
# when the sprite is in front of its seg, which is asked only then.
def Sprites.clip.behind(larger_under: Bool, smaller_under: Bool, +level: L.Level, seg: U32, +x: U32, +y: U32) ->
  Bool:
  match larger_under smaller_under:
    case True{} _:
      True{}
    case False{} False{}:
      False{}
    case False{} True{}:
      Bool.not(Sprites.seg_side(L.Level.seg(level, seg), x, y))

# A stored range in front of the sprite, over the columns they share,
# r1 to r2: it clips the columns no newer range clipped, below unless
# the sprite stands at or over the height it clips below, above unless
# the sprite's top is at or under the height it clips above.
def Sprites.clip.range(vis: Sprites.Vis, r1: U32, r2: U32, wall: D.Draw.Wall, mem: Array<U32>) -> Array<U32>:
  Vis{sx1, sx2, scale, gx, gy, +gz, +gzt, mid, frac, step, patch, cmap, rank, nth} = vis
  D.Wall{seg, +x1, x2, scale1, scale2, wstep, +sil, +bsil, +tsil, texcols, tops, bottoms} = wall
  +bottom = Bool.and(Bool.not(U32.is_zero((sil .&. 1 : U32))), F.Fixed.lt(gz, bsil))
  +top = Bool.and(Bool.not(U32.is_zero((sil .&. 2 : U32))), F.Fixed.gt(gzt, tsil))
  Sprites.clip.if(Bool.or(top, bottom), top, bottom, r1, r2, x1, tops, bottoms, mem)

def Sprites.clip.kept(done: List<&2, D.Draw.Wall>, p: Array<U32> & D.Draw.Wall) ->
  Array<U32> & List<&2, D.Draw.Wall>:
  (mem, wall) = p
  (mem, wall <> done)

# A range behind the sprite draws its masked columns there still
# pending, below the sprite; one in front clips it. Either is kept as
# it is left.
def Sprites.clip.side(behind: Bool, +view: P.View, +level: L.Level, +gfx: G.Gfx, +vis: Sprites.Vis, +r1: U32,
  +r2: U32, +wall: D.Draw.Wall, st: Array<U32> & List<&2, D.Draw.Wall>) -> Array<U32> & List<&2, D.Draw.Wall>:
  match behind:
    case True{}:
      (mem, done) = st
      Sprites.clip.kept(done, M.Masked.wall(view, level, gfx, r1, r2, wall, mem))
    case False{}:
      (mem, done) = st
      (Sprites.clip.range(vis, r1, r2, wall, mem), wall <> done)

# Whether a range can matter to the sprite at all, the test vanilla
# makes first: it has a silhouette, which every masked range has, and
# shares a column with the sprite.
def Sprites.clip.meets(+vis: Sprites.Vis, +wall: D.Draw.Wall) -> Bool:
  Vis{+sx1, +sx2, scale, gx, gy, gz, gzt, mid, frac, step, patch, cmap, rank, nth} = vis
  D.Wall{seg, +x1, +x2, scale1, scale2, wstep, sil, bsil, tsil, texcols, tops, bottoms} = wall
  Bool.and(Bool.not(U32.is_zero(sil)), Bool.and(U32.is_le(x1, sx2), U32.is_ge(x2, sx1)))

# Doom's R_DrawSprite for one stored range: behind the sprite when all
# of it is smaller than the sprite, or some of it is and the sprite is
# in front of its seg; the columns they share are r1 to r2.
def Sprites.clip.wall(meets: Bool, +view: P.View, +level: L.Level, +gfx: G.Gfx, +vis: Sprites.Vis,
  +wall: D.Draw.Wall, st: Array<U32> & List<&2, D.Draw.Wall>) -> Array<U32> & List<&2, D.Draw.Wall>:
  match meets:
    case False{}:
      (mem, done) = st
      (mem, wall <> done)
    case True{}:
      Vis{+sx1, +sx2, +scale, +gx, +gy, gz, gzt, mid, frac, step, patch, cmap, rank, nth} = vis
      D.Wall{seg, +x1, +x2, +scale1, +scale2, wstep, sil, bsil, tsil, texcols, tops, bottoms} = wall
      Sprites.clip.side(Sprites.clip.behind(F.Fixed.lt(F.Fixed.max(scale1, scale2), scale),
          F.Fixed.lt(F.Fixed.min(scale1, scale2), scale), level, seg, gx, gy),
        view, level, gfx, vis, U32.max(x1, sx1), U32.min(x2, sx2), wall, st)

# The stored ranges, newest first, gathered as the sprite leaves them
# and put back in their order.
def Sprites.clip.walls(walls: List<&2, D.Draw.Wall>, +view: P.View, +level: L.Level, +gfx: G.Gfx,
  +vis: Sprites.Vis, st: Array<U32> & List<&2, D.Draw.Wall>) -> Array<U32> & List<&2, D.Draw.Wall>:
  match walls:
    case []:
      (mem, done) = st
      (mem, List.reverse(&2, D.Draw.Wall, done))
    case +wall <> rest:
      Sprites.clip.walls(rest, view, level, gfx, vis,
        Sprites.clip.wall(Sprites.clip.meets(vis, wall), view, level, gfx, vis, wall, st))

# Drawing
# -------

# A sprite's column loop: the array, the sprite, and the patch's column
# as a fraction.
type Sprites.Col is Type:
  Col{mem: Array<U32>, vis: Sprites.Vis, frac: U32}

def Sprites.Col.mem(st: Sprites.Col) -> Array<U32>:
  Col{mem, vis, frac} = st
  mem

# Doom's R_DrawVisSprite's column: its top on the screen, its step down
# the patch, dc_iscale, the step across without its sign, and the clips,
# those no range set being the screen's edges.
def Sprites.col.of(+x: U32, vis: Sprites.Vis, +cc: U32, +fc: U32) -> M.Masked.Col:
  Vis{x1, x2, +scale, gx, gy, gz, gzt, +mid, f, step, patch, cmap, rank, nth} = vis
  M.Col{x, (P.Project.centery() - F.Fixed.mul(mid, scale) : U32), scale, mid, F.Fixed.abs(step), cmap,
    Bool.pick(U32, U32.is_eq(cc, Sprites.unclipped()), 4294967295, cc),
    Bool.pick(U32, U32.is_eq(fc, Sprites.unclipped()), 168, fc)}

# Doom's R_DrawVisSprite for one column: the posts of the patch's column
# drawn through the clips.
def Sprites.col.draw(+x: U32, +vis: Sprites.Vis, frac: U32, cc: U32, fc: U32, p: Array<U32> & U32) ->
  Sprites.Col:
  Vis{x1, x2, scale, gx, gy, gz, gzt, mid, f, +step, +patch, cmap, rank, nth} = vis
  (mem, offset) = p
  Col{G.Gfx.posts(~M.Masked.Col, ~M.Masked.post, 256n, G.Post{False{}, mem, (patch + offset : U32)},
      Sprites.col.of(x, vis, cc, fc)),
    vis, (frac + step : U32)}

def Sprites.col.bottom(+x: U32, +vis: Sprites.Vis, +frac: U32, cc: U32, p: Array<U32> & U32) -> Sprites.Col:
  Vis{x1, x2, scale, gx, gy, gz, gzt, mid, f, step, +patch, cmap, rank, nth} = vis
  (mem, fc) = p
  Sprites.col.draw(x, vis, frac, cc, fc, B.Bytes.u32(mem, (patch + 8 + (frac >> 16n) * 4 : U32)))

def Sprites.col.top(+x: U32, vis: Sprites.Vis, frac: U32, p: Array<U32> & U32) -> Sprites.Col:
  (mem, cc) = p
  Sprites.col.bottom(x, vis, frac, cc, B.Bytes.at(mem, (G.Gfx.clipbot() + x : U32)))

def Sprites.col(i: Nat, st: Sprites.Col) -> Sprites.Col:
  Col{mem, vis, frac} = st
  +x = U32.from_nat(i)
  Sprites.col.top(x, vis, frac, B.Bytes.at(mem, (G.Gfx.cliptop() + x : U32)))

# Doom's R_DrawVisSprite: the sprite's columns, each through its clips.
def Sprites.vis.draw(+vis: Sprites.Vis, mem: Array<U32>) -> Array<U32>:
  Vis{+x1, +x2, scale, gx, gy, gz, gzt, mid, frac, step, patch, cmap, rank, nth} = vis
  Sprites.Col.mem(D.Draw.each(~Sprites.Col, ~Sprites.col, D.Draw.rows(x1, x2), U32.to_nat(x1),
    Col{mem, vis, frac}))

def Sprites.sprite.draw(vis: Sprites.Vis, p: Array<U32> & List<&2, D.Draw.Wall>) ->
  Array<U32> & List<&2, D.Draw.Wall>:
  (mem, walls) = p
  (Sprites.vis.draw(vis, mem), walls)

# The columns from x1 to x2 with no clip yet.
def Sprites.unclip(+x1: U32, x2: U32, mem: Array<U32>) -> Array<U32>:
  +n = D.Draw.rows(x1, x2)
  D.Draw.set(n, D.Draw.set(n, mem, (G.Gfx.cliptop() + x1 : U32), Sprites.unclipped()),
    (G.Gfx.clipbot() + x1 : U32), Sprites.unclipped())

# Doom's R_DrawSprite: the sprite's columns unclipped, the stored ranges
# walked, then the sprite drawn through the clips they left.
def Sprites.sprite(+view: P.View, +level: L.Level, +gfx: G.Gfx, +vis: Sprites.Vis,
  p: Array<U32> & List<&2, D.Draw.Wall>) -> Array<U32> & List<&2, D.Draw.Wall>:
  Vis{+x1, +x2, scale, gx, gy, gz, gzt, mid, frac, step, patch, cmap, rank, nth} = vis
  (mem, walls) = p
  Sprites.sprite.draw(vis, Sprites.clip.walls(walls, view, level, gfx, vis, (Sprites.unclip(x1, x2, mem), [])))

def Sprites.draw(sprites: List<&2, Sprites.Vis>, +view: P.View, +level: L.Level, +gfx: G.Gfx,
  p: Array<U32> & List<&2, D.Draw.Wall>) -> Array<U32>:
  match sprites:
    case []:
      (mem, walls) = p
      M.Masked.draw(walls, view, level, gfx, mem)
    case vis <> rest:
      Sprites.draw(rest, view, level, gfx, Sprites.sprite(view, level, gfx, vis, p))

# Doom's R_DrawMasked: of the things, which come a sector's list at a
# time, those of the sectors the walk saw, drawn farthest first, then the
# masked columns no sprite drew.
def Sprites.masked(things: List<&2, H.Thing>, seen: D.Draw.Seen, +view: P.View, +level: L.Level, +gfx: G.Gfx,
  walls: List<&2, D.Draw.Wall>, mem: Array<U32>) -> Array<U32>:
  D.Seen{ranks, next} = seen
  Sprites.draw(List.sort(~Sprites.Vis, ~Sprites.before, Sprites.gather(things, 0, ranks, view, level, gfx)), view,
    level, gfx, (mem, walls))

# Doom's R_DrawPSprite: a player sprite's state row placed at sx, sy on a
# 320 by 200 screen whose centre column is the view's and whose row
# 100.5 is the view's centre row, less its patch's offsets, at scale one,
# clipped by the view's edges alone. Shadow precedes the fixed colormap,
# full-bright and nearest-wall lighting. One wholly off a side has no columns.
def Sprites.psprite(+gfx: G.Gfx, +state: U32, sx: U32, sy: U32, lightnum: U32, fixedcolormap: U32, shadow: Bool, mem: Array<U32>) -> Array<U32>:
  +width = G.Gfx.sprite(gfx, state, 0, 1)
  +left = (sx - G.Gfx.sprite(gfx, state, 0, 2) : U32)
  +x1 = F.Fixed.sarn(left, 16n)
  +flip = U32.is_eq(G.Gfx.sprite(gfx, state, 0, 4), 1)
  +step = Bool.pick(U32, flip, F.Fixed.neg(65536), 65536)
  +first = F.Fixed.max(x1, 0)
  +last = F.Fixed.min((F.Fixed.sarn((left + width : U32), 16n) - 1 : U32), 319)
  Sprites.vis.draw(Vis{first, last, 65536, 0, 0, 0, 0, (6586368 - sy + G.Gfx.sprite(gfx, state, 0, 3) : U32),
    (Bool.pick(U32, flip, (width - 1 : U32), 0) + step * (first - x1) : U32), step, G.Gfx.sprite(gfx, state, 0, 0),
    Bool.pick(U32, shadow, 0, (G.Gfx.colormap() + P.Project.colormap(fixedcolormap, Bool.pick(U32, U32.is_eq(G.Gfx.sprite(gfx, state, 0, 5), 1), 0,
      P.Project.scalelight(lightnum, 47))) * 256 : U32)), 0, 0}, Sprites.unclip(first, last, mem))
