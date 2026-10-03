# Doom's R_AddLine, R_StoreWallRange and R_RenderSegLoop: a seg clipped
# to the view and against the solid columns, each fragment left stored
# as a wall range with its scale, and its columns drawn between the
# ceiling and floor clips, which they then narrow.
import Base
import ./vec.bend as V
import ./bytes.bend as B
import ./fixed.bend as F
import ./angle.bend as A
import ./clip.bend as C
import ./level.bend as L
import ./gfx.bend as G
import ./project.bend as P
import ./draw.bend as D
import ./planes.bend as N

# Storing
# -------

def Segs.step(+start: U32, +stop: U32, +scale1: U32, scale2: U32) -> U32:
  Bool.pick(U32, U32.is_gt(stop, start), F.Fixed.quot((scale2 - scale1 : U32), (stop - start : U32)), 0)

# A range's geometry, from its seg and the angle to the seg's first
# vertex: the wall's normal; its distance, the first vertex's times the
# sine of the angle the view makes with the wall; the texture offset
# where the view meets it, the first vertex's distance along the wall
# plus the side's and the seg's offsets and the wall's scroll; and the
# angle its texture columns are measured from.
type Segs.Geo is Data:
  Geo{normal: U32, distance: U32, offset: U32, centerangle: U32}

def Segs.geo.of(+view: P.View, +normal: U32, +delta: U32, +hyp: U32, offsets: U32) -> Segs.Geo:
  +sine = P.View.sine(view)
  +along = F.Fixed.mul(hyp, A.Angle.sin(sine, A.Angle.fine(U32.min(
    Bool.pick(U32, U32.is_gt(delta, A.Angle.ang180()), F.Fixed.neg(delta), delta), A.Angle.ang90()))))
  Geo{normal,
    F.Fixed.mul(hyp, A.Angle.sin(sine, A.Angle.fine(
      (A.Angle.ang90() - U32.min(F.Fixed.abs(delta), A.Angle.ang90()) : U32)))),
    (Bool.pick(U32, U32.is_lt(delta, A.Angle.ang180()), F.Fixed.neg(along), along) + offsets : U32),
    (A.Angle.ang90() + P.View.angle(view) - normal : U32)}

def Segs.geo(+view: P.View, seg: L.Level.Seg, side: L.Level.Side, scroll: U32, angle1: U32) -> Segs.Geo:
  L.Seg{x1, y1, x2, y2, +angle, offset, flags, sidedef, front, back} = seg
  L.Side{xoff, yoff, sector} = side
  Segs.geo.of(view, (angle + A.Angle.ang90() : U32), (angle + A.Angle.ang90() - angle1 : U32),
    P.View.dist_to(view, x1, y1), (xoff + offset + scroll : U32))

def Segs.wall(+view: P.View, index: U32, +start: U32, +stop: U32, geo: Segs.Geo, sil: U32 & U32 & U32) ->
  D.Draw.Wall:
  Geo{+normal, +distance, offset, centerangle} = geo
  (s, b, t) = sil
  +scale1 = P.View.scale(view, (P.View.angle(view) + P.View.xtoangle(view, start) : U32), normal, distance)
  +scale2 = Bool.pick(U32, U32.is_gt(stop, start),
    P.View.scale(view, (P.View.angle(view) + P.View.xtoangle(view, stop) : U32), normal, distance), scale1)
  D.Wall{index, start, stop, scale1, scale2, Segs.step(start, stop, scale1, scale2), s, b, t, [], [], []}

# Doom's silhouette of a range, with the heights it clips sprites below
# and above. A one-sided wall clips both ways at any height. Below: a
# floor stepping down toward the eye clips under the front's floor, a
# back floor above the eye at any height. Above, ceilings likewise. A
# door shut below or above clips that way at any height whatever else
# holds, and a masked middle texture fills in, at any height, only a
# way nothing else clips.
def Segs.sil.of(onesided: Bool, +masked: Bool, f: L.Level.Sector, b: L.Level.Sector, +vz: U32) ->
  U32 & U32 & U32:
  L.Sector{+ffloor, +fceil, flight} = f
  L.Sector{+bfloor, +bceil, blight} = b
  +under = F.Fixed.gt(ffloor, bfloor)
  +over = F.Fixed.lt(fceil, bceil)
  +shutbottom = F.Fixed.le(bceil, ffloor)
  +shuttop = F.Fixed.ge(bfloor, fceil)
  +anybottom = Bool.or(masked, Bool.and(Bool.not(under), F.Fixed.gt(bfloor, vz)))
  +anytop = Bool.or(masked, Bool.and(Bool.not(over), F.Fixed.lt(bceil, vz)))
  Bool.pick(U32 & U32 & U32, onesided, (3, 2147483647, 2147483648),
    ((Bool.to_u32(Bool.or(under, Bool.or(shutbottom, anybottom)))
      + Bool.to_u32(Bool.or(over, Bool.or(shuttop, anytop))) * 2 : U32),
      Bool.pick(U32, shutbottom, 2147483647, Bool.pick(U32, under, ffloor,
        Bool.pick(U32, anybottom, 2147483647, 0))),
      Bool.pick(U32, shuttop, 2147483648, Bool.pick(U32, over, fceil,
        Bool.pick(U32, anytop, 2147483648, 0)))))

def Segs.sil(+view: P.View, +level: L.Level, +gfx: G.Gfx, seg: L.Level.Seg) -> U32 & U32 & U32:
  L.Seg{x1, y1, x2, y2, angle, offset, flags, side, front, +back} = seg
  Segs.sil.of(U32.is_eq(back, L.Level.none()),
    Bool.and(Bool.not(U32.is_eq(back, L.Level.none())), Bool.not(U32.is_zero(G.Gfx.mid(gfx, side)))),
    L.Level.sector(level, front), L.Level.sector(level, back), P.View.z(view))

# Light
# -----

# Doom's fake contrast: a wall along the x axis a light number darker,
# one along the y axis a number brighter, on top of the view's extra
# light; held to 0 and 15.
def Segs.lightnum(seg: L.Level.Seg, light: U32, +extralight: U32) -> U32:
  L.Seg{+x1, +y1, +x2, +y2, angle, offset, flags, side, front, back} = seg
  P.Project.lightnum(light, ((extralight - Bool.to_u32(U32.is_eq(y1, y2))
    + Bool.to_u32(Bool.and(Bool.not(U32.is_eq(y1, y2)), U32.is_eq(x1, x2))) : U32)))

# The range
# ---------

# What R_StoreWallRange works out for a range and the seg loop steps a
# column at a time: the first column and the scale there; the wall's
# top and bottom rows, and the top of the lower and bottom of the upper
# texture, as fractions of 4096 with their steps; for the one-sided,
# upper and lower walls, whether the range draws it, where its texture's
# columns start with their mask, and the row of the texture at the eye's
# height; whether the floor and ceiling are marked; the light number;
# the wall's distance, texture offset and centre angle, which its
# texture columns come from; whether it has a two-sided middle texture
# to draw later; and whether it shuts the view above or below whatever
# its rows, as a one-sided wall or a shut door does, so that what is
# drawn behind it later is clipped whole. All plain words, since the
# seg loop opens it once a column and a boxed field would cost a
# reference count each time.
type Segs.Rw is Data:
  Rw{start: U32, scale: U32, step: U32, topfrac: U32, topstep: U32, bottomfrac: U32,
    bottomstep: U32, pixhigh: U32, pixhighstep: U32, pixlow: U32, pixlowstep: U32,
    solid: Bool, midfirst: U32, midmask: U32, midmid: U32,
    upper: Bool, topfirst: U32, topmask: U32, topmid: U32,
    lower: Bool, bottomfirst: U32, bottommask: U32, bottommid: U32,
    markfloor: Bool, markceiling: Bool, lightnum: U32, distance: U32, offset: U32, centerangle: U32,
    masked: Bool, shuttop: Bool, shutbottom: Bool}

# A height above the eye as the row fraction at the range's first
# column, and its step a column: Doom's topfrac and topstep.
def Segs.frac(world: U32, scale: U32) -> U32:
  ((P.Project.centery() >> 4n) - F.Fixed.mul(F.Fixed.sarn(world, 4n), scale) : U32)

def Segs.fracstep(world: U32, step: U32) -> U32:
  F.Fixed.neg(F.Fixed.mul(step, F.Fixed.sarn(world, 4n)))

# What the two sectors and the side say of a range. The line's flags peg
# its textures: a one-sided wall's hangs from the ceiling, or stands on
# the floor when pegged to the bottom; an upper wall's stands on the
# back's ceiling, or hangs from the front's when pegged to the top; a
# lower wall's hangs from the back's floor, or from the front's ceiling
# when pegged to the bottom. Each then moves by the side's row offset.
def Segs.rw.of(+gfx: G.Gfx, wall: D.Draw.Wall, +mid: U32, +top: U32, +bottom: U32, +flags: U32, +yoff: U32,
  +onesided: Bool, +sky2: Bool, +samefloor: Bool, +sameceil: Bool, f: L.Level.Sector, b: L.Level.Sector,
  +vz: U32, +skyfront: Bool, lightnum: U32, geo: Segs.Geo) -> Segs.Rw:
  D.Wall{index, start, stop, +scale, scale2, +step, sil, bsil, tsil, t0, t1, t2} = wall
  L.Sector{+ffloor, +fceil, +flight} = f
  L.Sector{+bfloor, +bceil, +blight} = b
  Geo{normal, distance, offset, centerangle} = geo
  +worldtop = (Bool.pick(U32, sky2, bceil, fceil) - vz : U32)
  +worldbottom = (ffloor - vz : U32)
  +worldhigh = (bceil - vz : U32)
  +worldlow = (bfloor - vz : U32)
  +shut = Bool.or(onesided, Bool.or(F.Fixed.le(bceil, ffloor), F.Fixed.ge(bfloor, fceil)))
  +relit = Bool.not(U32.is_eq(blight, flight))
  +pegtop = Bool.not(U32.is_zero((flags .&. 8 : U32)))
  +pegbottom = Bool.not(U32.is_zero((flags .&. 16 : U32)))
  +solid = Bool.and(onesided, Bool.not(U32.is_zero(mid)))
  Rw{start, scale, step, Segs.frac(worldtop, scale), Segs.fracstep(worldtop, step),
    Segs.frac(worldbottom, scale), Segs.fracstep(worldbottom, step),
    Segs.frac(worldhigh, scale), Segs.fracstep(worldhigh, step),
    Segs.frac(worldlow, scale), Segs.fracstep(worldlow, step),
    solid, G.Gfx.tex.first(gfx, mid), G.Gfx.tex.mask(gfx, mid),
    (Bool.pick(U32, pegbottom, (ffloor + G.Gfx.tex.height(gfx, mid) - vz : U32), worldtop) + yoff : U32),
    Bool.and(Bool.not(onesided), Bool.and(F.Fixed.lt(worldhigh, worldtop), Bool.not(U32.is_zero(top)))),
    G.Gfx.tex.first(gfx, top), G.Gfx.tex.mask(gfx, top),
    (Bool.pick(U32, pegtop, worldtop, (bceil + G.Gfx.tex.height(gfx, top) - vz : U32)) + yoff : U32),
    Bool.and(Bool.not(onesided), Bool.and(F.Fixed.gt(worldlow, worldbottom), Bool.not(U32.is_zero(bottom)))),
    G.Gfx.tex.first(gfx, bottom), G.Gfx.tex.mask(gfx, bottom),
    (Bool.pick(U32, pegbottom, worldtop, worldlow) + yoff : U32),
    Bool.and(F.Fixed.lt(ffloor, vz), Bool.or(shut, Bool.or(relit,
      Bool.or(Bool.not(U32.is_eq(worldlow, worldbottom)), Bool.not(samefloor))))),
    Bool.and(Bool.or(F.Fixed.gt(fceil, vz), skyfront), Bool.or(shut, Bool.or(relit,
      Bool.or(Bool.not(U32.is_eq(worldhigh, worldtop)), Bool.not(sameceil))))),
    lightnum, distance, offset, centerangle,
    Bool.and(Bool.not(onesided), Bool.not(U32.is_zero(mid))),
    Bool.or(onesided, F.Fixed.ge(bfloor, fceil)), Bool.or(onesided, F.Fixed.le(bceil, ffloor))}

def Segs.side.yoff(s: L.Level.Side) -> U32:
  L.Side{xoff, yoff, sector} = s
  yoff

# The front and back sectors' part of R_StoreWallRange. Between two sky
# ceilings the upper wall is not drawn: the wall's top is the back's.
def Segs.rw(+view: P.View, +level: L.Level, +gfx: G.Gfx, +seg: L.Level.Seg, wall: D.Draw.Wall,
  geo: Segs.Geo) -> Segs.Rw:
  L.Seg{x1, y1, x2, y2, angle, offset, flags, +side, +front, +back} = seg
  +onesided = U32.is_eq(back, L.Level.none())
  +skyfront = U32.is_eq(G.Gfx.ceilpic(gfx, level, front), G.Gfx.sky(gfx))
  Segs.rw.of(gfx, wall, G.Gfx.mid(gfx, side), G.Gfx.top(gfx, side), G.Gfx.bottom(gfx, side), flags,
    Segs.side.yoff(L.Level.side(level, side)), onesided,
    Bool.and(Bool.not(onesided), Bool.and(skyfront, U32.is_eq(G.Gfx.ceilpic(gfx, level, back), G.Gfx.sky(gfx)))),
    U32.is_eq(G.Gfx.floorpic(gfx, level, back), G.Gfx.floorpic(gfx, level, front)),
    U32.is_eq(G.Gfx.ceilpic(gfx, level, back), G.Gfx.ceilpic(gfx, level, front)),
    L.Level.sector(level, front), L.Level.sector(level, back), P.View.z(view), skyfront,
    Segs.lightnum(seg, L.Level.sector.light(level, front), P.View.extralight(view)), geo)

# The seg loop
# ------------

# The seg loop's state: the frame's array, the planes' columns, the
# range, the view, the graphics, the floor and ceiling planes, and, last
# column first, the range's texture columns and clips so far.
type Segs.Cols is Type:
  Cols{mem: Array<U32>, cols: Array<U32>, rw: Segs.Rw, view: P.View, gfx: G.Gfx, floor: U32, ceil: U32,
    texcols: List<&2, U32>, tops: List<&2, U32>, bottoms: List<&2, U32>}

def Segs.row(frac: U32) -> U32:
  F.Fixed.sarn(frac, 12n)

# A column's texture column: the range's offset less the tangent of the
# column's angle from the wall's normal times the wall's distance.
def Segs.texcol(+view: P.View, distance: U32, offset: U32, centerangle: U32, x: U32) -> U32:
  F.Fixed.sarn((offset - F.Fixed.mul(V.Vec.get(P.View.tangent(view),
    A.Angle.fine((centerangle + P.View.xtoangle(view, x) : U32))), distance) : U32), 16n)

# The colormap of a wall column at a scale: Doom's walllights at the
# scale's light index, which the table's end caps.
def Segs.colormap(lightnum: U32, scale: U32) -> U32:
  (G.Gfx.colormap() + P.Project.scalelight(lightnum, U32.min((scale >> 12n : U32), 47)) * 256 : U32)

# Doom's dc_iscale: the texture rows a screen row, the reciprocal of
# the scale by the 32-bit division.
def Segs.iscale(scale: U32) -> U32:
  (4294967295 / scale : U32)

# One of the column's walls, when the range draws it: its texture's
# column looked up only then.
def Segs.col.wall(on: Bool, mem: Array<U32>, x: U32, yl: U32, yh: U32, gfx: G.Gfx, first: U32, mask: U32,
  texcol: U32, mid: U32, iscale: U32, cmap: U32) -> Array<U32>:
  match on:
    case False{}:
      mem
    case True{}:
      D.Draw.column(mem, x, yl, yh, G.Gfx.column.at(gfx, first, mask, texcol), mid, iscale, cmap)

# A mark is written to its plane's slot, or to a slot no plane uses.
def Segs.mark.at(on: Bool, slot: U32) -> U32:
  Bool.pick(U32, on, slot, 1023)

# Doom's marks for one column: the ceiling plane holds the rows from the
# ceiling clip down to the wall's top, the floor plane those from the
# wall's bottom down to the floor clip, each where marked and not empty.
def Segs.col.mark(+x: U32, markceiling: Bool, markfloor: Bool, +cc: U32, +fc: U32, yl: U32, yh: U32,
  +floor: U32, +ceil: U32, cols: Array<U32>) -> Array<U32>:
  +cbottom = F.Fixed.min((yl - 1 : U32), (fc - 1 : U32))
  +ftop = F.Fixed.max((yh + 1 : U32), (cc + 1 : U32))
  +con = Bool.and(markceiling, F.Fixed.le((cc + 1 : U32), cbottom))
  +fon = Bool.and(markfloor, F.Fixed.le(ftop, (fc - 1 : U32)))
  Array.set(U32, Array.set(U32, Array.set(U32, Array.set(U32, cols,
    Segs.mark.at(con, ((ceil << 10n) + x + 1 : U32)), (cc + 1 : U32)),
    Segs.mark.at(con, ((ceil << 10n) + x + 513 : U32)), cbottom),
    Segs.mark.at(fon, ((floor << 10n) + x + 1 : U32)), ftop),
    Segs.mark.at(fon, ((floor << 10n) + x + 513 : U32)), (fc - 1 : U32))

# Doom's R_RenderSegLoop for one column, given its ceiling and floor
# clips cc and fc. The wall's rows yl to yh are held inside them and the
# planes marked around them. A one-sided wall is drawn whole and the
# column closed; else the upper wall runs down to high, the back's
# ceiling, and the lower up from low, its floor, each narrowing its
# clip, or the clips narrow to the wall's rows where a plane is marked.
# The three walls share the column's texture column, colormap and
# reciprocal scale. The range records the texture column of a masked
# middle texture and the clips after, which are whole where it shuts
# the view.
def Segs.col.step(+x: U32, +rw: Segs.Rw, +view: P.View, +gfx: G.Gfx, +cc: U32, +fc: U32, cols: Array<U32>,
  +floor: U32, +ceil: U32, +texcols: List<&2, U32>, tops: List<&2, U32>, bottoms: List<&2, U32>,
  mem: Array<U32>) -> Segs.Cols:
  Rw{start, scale0, step, topfrac, topstep, bottomfrac, bottomstep, pixhigh, pixhighstep, pixlow,
    pixlowstep, +solid, midfirst, midmask, midmid, +upper, topfirst, topmask, topmid, +lower, bottomfirst,
    bottommask, bottommid, markfloor, markceiling, lightnum, distance, offset, centerangle, masked,
    shuttop, shutbottom} = rw
  +k = (x - start : U32)
  +scale = (scale0 + k * step : U32)
  +yl = F.Fixed.max(Segs.row((topfrac + k * topstep + 4095 : U32)), (cc + 1 : U32))
  +yh = F.Fixed.min(Segs.row((bottomfrac + k * bottomstep : U32)), (fc - 1 : U32))
  +high = F.Fixed.min(Segs.row((pixhigh + k * pixhighstep : U32)), (fc - 1 : U32))
  +cc2 = Bool.pick(U32, solid, 168, Bool.pick(U32, upper,
    Bool.pick(U32, F.Fixed.ge(high, yl), high, (yl - 1 : U32)),
    Bool.pick(U32, markceiling, (yl - 1 : U32), cc)))
  +low = F.Fixed.max(Segs.row((pixlow + k * pixlowstep + 4095 : U32)), (cc2 + 1 : U32))
  +fc2 = Bool.pick(U32, solid, 4294967295, Bool.pick(U32, lower,
    Bool.pick(U32, F.Fixed.le(low, yh), low, (yh + 1 : U32)),
    Bool.pick(U32, markfloor, (yh + 1 : U32), fc)))
  +texcol = Segs.texcol(view, distance, offset, centerangle, x)
  +cmap = Segs.colormap(lightnum, scale)
  +iscale = Segs.iscale(scale)
  Cols{Array.set(U32, Array.set(U32,
      Segs.col.wall(lower, Segs.col.wall(upper, Segs.col.wall(solid, mem, x, yl, yh, gfx, midfirst, midmask,
        texcol, midmid, iscale, cmap), x, yl, high, gfx, topfirst, topmask, texcol, topmid, iscale, cmap),
        x, low, yh, gfx, bottomfirst, bottommask, texcol, bottommid, iscale, cmap),
      (G.Gfx.ceilclip() + x : U32), cc2), (G.Gfx.floorclip() + x : U32), fc2),
    Segs.col.mark(x, markceiling, markfloor, cc, fc, yl, yh, floor, ceil, cols), rw, view, gfx, floor, ceil,
    Bool.pick(List<&2, U32>, masked, texcol <> texcols, texcols),
    Bool.pick(U32, shuttop, 168, cc2) <> tops, Bool.pick(U32, shutbottom, 4294967295, fc2) <> bottoms}

def Segs.col.floor(x: U32, rw: Segs.Rw, view: P.View, gfx: G.Gfx, cc: U32, cols: Array<U32>, floor: U32,
  ceil: U32, texcols: List<&2, U32>, tops: List<&2, U32>, bottoms: List<&2, U32>, p: Array<U32> & U32) ->
  Segs.Cols:
  (mem, fc) = p
  Segs.col.step(x, rw, view, gfx, cc, fc, cols, floor, ceil, texcols, tops, bottoms, mem)

def Segs.col.ceil(+x: U32, rw: Segs.Rw, view: P.View, gfx: G.Gfx, cols: Array<U32>, floor: U32, ceil: U32,
  texcols: List<&2, U32>, tops: List<&2, U32>, bottoms: List<&2, U32>, p: Array<U32> & U32) -> Segs.Cols:
  (mem, cc) = p
  Segs.col.floor(x, rw, view, gfx, cc, cols, floor, ceil, texcols, tops, bottoms,
    B.Bytes.at(mem, (G.Gfx.floorclip() + x : U32)))

def Segs.col(i: Nat, st: Segs.Cols) -> Segs.Cols:
  Cols{mem, cols, rw, view, gfx, floor, ceil, texcols, tops, bottoms} = st
  +x = U32.from_nat(i)
  Segs.col.ceil(x, rw, view, gfx, cols, floor, ceil, texcols, tops, bottoms,
    B.Bytes.at(mem, (G.Gfx.ceilclip() + x : U32)))

def Segs.Rw.markfloor(rw: Segs.Rw) -> Bool:
  Rw{start, scale0, step, topfrac, topstep, bottomfrac, bottomstep, pixhigh, pixhighstep, pixlow,
    pixlowstep, solid, midfirst, midmask, midmid, upper, topfirst, topmask, topmid, lower, bottomfirst,
    bottommask, bottommid, markfloor, markceiling, lightnum, distance, offset, centerangle, masked,
    shuttop, shutbottom} = rw
  markfloor

def Segs.Rw.markceiling(rw: Segs.Rw) -> Bool:
  Rw{start, scale0, step, topfrac, topstep, bottomfrac, bottomstep, pixhigh, pixhighstep, pixlow,
    pixlowstep, solid, midfirst, midmask, midmid, upper, topfirst, topmask, topmid, lower, bottomfirst,
    bottommask, bottommid, markfloor, markceiling, lightnum, distance, offset, centerangle, masked,
    shuttop, shutbottom} = rw
  markceiling

# The range is stored with the texture columns and clips its loop
# gathered, in column order.
def Segs.store.done(wall: D.Draw.Wall, solid: List<&2, C.Clip.Range>, walls: List<&2, D.Draw.Wall>,
  tasks: List<&2, D.Draw.Task>, heads: List<&2, D.Draw.Plane>, count: U32, depth: Nat, seen: D.Draw.Seen,
  st: Segs.Cols) -> D.Draw:
  D.Wall{seg, x1, x2, scale1, scale2, step, sil, bsil, tsil, t0, t1, t2} = wall
  Cols{mem, cols, rw, view, gfx, floor, ceil, texcols, tops, bottoms} = st
  D.Draw{mem, solid, D.Wall{seg, x1, x2, scale1, scale2, step, sil, bsil, tsil,
    List.reverse(&2, U32, texcols), List.reverse(&2, U32, tops), List.reverse(&2, U32, bottoms)} <> walls,
    tasks, D.Planes{heads, count, cols, depth, floor, ceil}, seen}

def Segs.store.loop(+wall: D.Draw.Wall, rw: Segs.Rw, view: P.View, gfx: G.Gfx, solid: List<&2, C.Clip.Range>,
  walls: List<&2, D.Draw.Wall>, tasks: List<&2, D.Draw.Task>, seen: D.Draw.Seen, mem: Array<U32>,
  ps: D.Draw.Planes) -> D.Draw:
  D.Wall{index, +x1, x2, scale1, scale2, step, sil, bsil, tsil, t0, t1, t2} = wall
  D.Planes{heads, count, cols, depth, floor, ceil} = ps
  Segs.store.done(wall, solid, walls, tasks, heads, count, depth, seen,
    D.Draw.each(~Segs.Cols, ~Segs.col, U32.to_nat((x2 - x1 + 1 : U32)), U32.to_nat(x1),
      Cols{mem, cols, rw, view, gfx, floor, ceil, [], [], []}))

def Segs.store.rw(+wall: D.Draw.Wall, +rw: Segs.Rw, view: P.View, gfx: G.Gfx, st: D.Draw) -> D.Draw:
  D.Wall{index, +x1, +x2, scale1, scale2, step, sil, bsil, tsil, t0, t1, t2} = wall
  D.Draw{mem, solid, walls, tasks, planes, seen} = st
  Segs.store.loop(wall, rw, view, gfx, solid, walls, tasks, seen, mem,
    N.Planes.check(Segs.Rw.markfloor(rw), True{}, x1, x2,
      N.Planes.check(Segs.Rw.markceiling(rw), False{}, x1, x2, planes)))

# Doom's R_StoreWallRange for the columns of one gap: the range stored,
# a plane it is about to mark checked, the ceiling's first, and its
# columns drawn.
def Segs.store.wall(+view: P.View, +level: L.Level, +gfx: G.Gfx, seg: L.Level.Seg, +wall: D.Draw.Wall,
  geo: Segs.Geo, st: D.Draw) -> D.Draw:
  Segs.store.rw(wall, Segs.rw(view, level, gfx, seg, wall, geo), view, gfx, st)

def Segs.store.geo(+view: P.View, +level: L.Level, +gfx: G.Gfx, +seg: L.Level.Seg, index: U32,
  gap: C.Clip.Range, +geo: Segs.Geo, st: D.Draw) -> D.Draw:
  C.Range{first, last} = gap
  Segs.store.wall(view, level, gfx, seg, Segs.wall(view, index, U32.from_nat(first), U32.from_nat(last), geo,
    Segs.sil(view, level, gfx, seg)), geo, st)

def Segs.seg.side(seg: L.Level.Seg) -> U32:
  L.Seg{x1, y1, x2, y2, angle, offset, flags, side, front, back} = seg
  side

def Segs.store(+view: P.View, +level: L.Level, +gfx: G.Gfx, +seg: L.Level.Seg, +index: U32, angle1: U32,
  gap: C.Clip.Range, st: D.Draw) -> D.Draw:
  Segs.store.geo(view, level, gfx, seg, index, gap,
    Segs.geo(view, seg, L.Level.side(level, Segs.seg.side(seg)),
      L.Level.seg.scroll(level, index, G.Gfx.clock(gfx)), angle1), st)

def Segs.stores(gaps: List<&2, C.Clip.Range>, +view: P.View, +level: L.Level, +gfx: G.Gfx,
  +seg: L.Level.Seg, +index: U32, +angle1: U32, st: D.Draw) -> D.Draw:
  match gaps:
    case []:
      st
    case gap <> rest:
      Segs.stores(rest, view, level, gfx, seg, index, angle1,
        Segs.store(view, level, gfx, seg, index, angle1, gap, st))

# Adding
# ------

# Doom's R_AddLine's verdict on a seg in view: a solid wall (one-sided
# or a closed door), a window, or a line with the same sector on both
# sides and no middle texture, which draws nothing.
type Segs.Kind is Data:
  Solid{}
  Window{}
  Nothing{}

def Segs.kind(f: L.Level.Sector, b: L.Level.Sector, onesided: Bool, samepics: Bool, nomid: Bool) -> Segs.Kind:
  L.Sector{+ffloor, +fceil, flight} = f
  L.Sector{+bfloor, +bceil, blight} = b
  Bool.pick(Segs.Kind, Bool.or(onesided, Bool.or(F.Fixed.le(bceil, ffloor), F.Fixed.ge(bfloor, fceil))), Solid{},
    Bool.pick(Segs.Kind, Bool.not(Bool.and(U32.is_eq(bceil, fceil), U32.is_eq(bfloor, ffloor))), Window{},
      Bool.pick(Segs.Kind, Bool.and(samepics, Bool.and(U32.is_eq(blight, flight), nomid)), Nothing{}, Window{})))

def Segs.kind.of(+level: L.Level, +gfx: G.Gfx, seg: L.Level.Seg) -> Segs.Kind:
  L.Seg{x1, y1, x2, y2, angle, offset, flags, side, +front, +back} = seg
  Segs.kind(L.Level.sector(level, front), L.Level.sector(level, back), U32.is_eq(back, L.Level.none()),
    Bool.and(U32.is_eq(G.Gfx.ceilpic(gfx, level, back), G.Gfx.ceilpic(gfx, level, front)),
      U32.is_eq(G.Gfx.floorpic(gfx, level, back), G.Gfx.floorpic(gfx, level, front))),
    U32.is_zero(G.Gfx.mid(gfx, side)))

# The gaps the solid columns leave are stored; a solid wall's columns
# then join them.
def Segs.clip(kind: Segs.Kind, +view: P.View, +level: L.Level, +gfx: G.Gfx, +seg: L.Level.Seg, index: U32,
  angle1: U32, +first: Nat, +last: Nat, st: D.Draw) -> D.Draw:
  match kind:
    case Nothing{}:
      st
    case Window{}:
      D.Draw{mem, +solids, walls, tasks, planes, seen} = st
      Segs.stores(C.Clip.gaps(first, last, solids), view, level, gfx, seg, index, angle1,
        D.Draw{mem, solids, walls, tasks, planes, seen})
    case Solid{}:
      D.Draw{mem, +solids, walls, tasks, planes, seen} = st
      Segs.stores(C.Clip.gaps(first, last, solids), view, level, gfx, seg, index, angle1,
        D.Draw{mem, C.Clip.add(first, last, solids), walls, tasks, planes, seen})

def Segs.add.span(+view: P.View, +level: L.Level, +gfx: G.Gfx, +seg: L.Level.Seg, index: U32,
  angle1: U32, span: P.View.Span, st: D.Draw) -> D.Draw:
  match span:
    case P.Span{False{}, True{}, x1, x2}:
      Segs.clip(Segs.kind.of(level, gfx, seg), view, level, gfx, seg, index, angle1, U32.to_nat(x1),
        U32.to_nat((x2 - 1 : U32)), st)
    case _:
      st

def Segs.add.seg(+view: P.View, +level: L.Level, +gfx: G.Gfx, +seg: L.Level.Seg, index: U32,
  st: D.Draw) -> D.Draw:
  L.Seg{+x1, +y1, x2, y2, angle, offset, flags, side, front, back} = seg
  Segs.add.span(view, level, gfx, seg, index, P.View.angle_to(view, x1, y1),
    P.View.span(view, P.View.angle_to(view, x1, y1), P.View.angle_to(view, x2, y2)), st)

# Doom's R_AddLine.
def Segs.add(+view: P.View, +level: L.Level, +gfx: G.Gfx, +index: U32, st: D.Draw) -> D.Draw:
  Segs.add.seg(view, level, gfx, L.Level.seg(level, index), index, st)
