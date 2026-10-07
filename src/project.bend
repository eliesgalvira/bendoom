# The projection: Doom's view tables at view width 320, height 168 and
# full detail, computed once with vanilla's formulas (R_InitTextureMapping
# and R_ExecuteSetViewSize), and the view's own geometry: the angle and
# distance of a point and the scale of a wall at a view angle, in the
# sim's fixed point so every number is vanilla's.
import Base
import ./vec.bend as V
import ./fixed.bend as F
import ./angle.bend as A
import ./tables.bend as T
import ./level.bend as L

# sine, tangent, tanto: Doom's tables. angletox: the column at or after
# a fine view angle (viewangletox). xtoangle: the least view angle of a
# column, 321 of them (xtoviewangle). yslope, distscale: the planes' row
# and column factors. coords: R_CheckBBox's corner table. clipangle: the
# view angle of column 0.
type Project.Tables is Data:
  Tables{sine: V.Vec, tangent: V.Vec, tanto: V.Vec, angletox: V.Vec, xtoangle: V.Vec,
    yslope: V.Vec, distscale: V.Vec, coords: V.Vec, clipangle: U32}

# The eye for one frame: where it is, how high, where it looks, with
# the sine and cosine of that, and Doom's extralight, the muzzle flash's
# brightening of every light number, and the fixed colormap selection.
type View is Data:
  View{x: U32, y: U32, z: U32, angle: U32, sin: U32, cos: U32, tables: Project.Tables, extralight: U32, fixedcolormap: U32}

# Half the view's width and height as fixed point: Doom's centerxfrac,
# which is also its projection, and centeryfrac.
def Project.centerx() -> U32:
  10485760

def Project.centery() -> U32:
  5505024

# The tables
# ----------

# The focal length that spreads a quarter turn over the width.
def Project.focal(tangent: V.Vec) -> U32:
  F.Fixed.div(Project.centerx(), V.Vec.get(tangent, 3072))

# The column of a fine angle from its tangent, before the fencepost
# pass: -1 past the right edge, 321 past the left.
def Project.tox(+tan: U32, focal: U32) -> U32:
  Bool.pick(U32, F.Fixed.gt(tan, 131072), 4294967295,
    Bool.pick(U32, F.Fixed.lt(tan, 4294836224), 321,
      F.Fixed.max(4294967295, F.Fixed.min(321,
        F.Fixed.sarn((Project.centerx() - F.Fixed.mul(tan, focal) + 65535 : U32), 16n)))))

def Project.tox.list(tans: List<&2, U32>, +focal: U32) -> List<&2, U32>:
  match tans:
    case []:
      []
    case tan <> rest:
      Project.tox(tan, focal) <> Project.tox.list(rest, focal)

# The fencepost pass: the columns off the edges become the edges.
def Project.fence(+t: U32) -> U32:
  Bool.pick(U32, U32.is_eq(t, 4294967295), 0, Bool.pick(U32, U32.is_eq(t, 321), 320, t))

def Project.fence.list(ts: List<&2, U32>) -> List<&2, U32>:
  match ts:
    case []:
      []
    case t <> rest:
      Project.fence(t) <> Project.fence.list(rest)

def Project.above(ts: List<&2, U32>, x: U32) -> Bool:
  match ts:
    case []:
      False{}
    case t <> rest:
      F.Fixed.gt(t, x)

# The columns fall as the fine angle rises, so one sweep finds every
# column's least angle: from column 320 down, the angle advances while
# its column is past x, then is x's.
def Project.xtoangle.go(fuel: Nat, done: Bool, advance: Bool, +ts: List<&2, U32>, +i: U32, +x: U32,
  acc: List<&2, U32>) -> List<&2, U32>:
  match fuel done advance:
    case _ True{} _:
      acc
    case 0n _ _:
      acc
    case 1n+f False{} True{}:
      Project.xtoangle.go(f, False{}, Project.above(List.tail(&2, U32, ts), x),
        List.tail(&2, U32, ts), (i + 1 : U32), x, acc)
    case 1n+f False{} False{}:
      Project.xtoangle.go(f, U32.is_zero(x), Project.above(ts, (x - 1 : U32)), ts, i, (x - 1 : U32),
        ((i << 19n) - A.Angle.ang90() : U32) <> acc)

def Project.xtoangle(+ts: List<&2, U32>) -> List<&2, U32>:
  Project.xtoangle.go(U32.to_nat(4500), False{}, Project.above(ts, 320), ts, 0, 320, [])

# A row's slope: the distance of a plane one unit from the eye, there.
def Project.yslope(i: U32) -> U32:
  F.Fixed.div(Project.centerx(), F.Fixed.abs((((i - 84 : U32) << 16n) + 32768 : U32)))

def Project.yslope.list(n: Nat, +i: U32) -> List<&2, U32>:
  match n:
    case 0n:
      []
    case 1n+m:
      Project.yslope(i) <> Project.yslope.list(m, (i + 1 : U32))

# A column's distance scale: one over the cosine of its view angle.
def Project.distscale.list(n: Nat, +sine: V.Vec, angles: List<&2, U32>) -> List<&2, U32>:
  match n angles:
    case 1n+m angle <> rest:
      F.Fixed.div(65536, F.Fixed.abs(A.Angle.cos(sine, A.Angle.fine(angle))))
        <> Project.distscale.list(m, sine, rest)
    case _ _:
      []

# Doom's checkcoord: for each of the eye's nine positions about a box,
# which of the box's top, bottom, left and right give the two corners
# that span it.
def Project.coords() -> List<&2, U32>:
  [3, 0, 2, 1, 3, 0, 2, 0, 3, 1, 2, 0, 0, 0, 0, 0, 2, 0, 2, 1, 0, 0, 0, 0, 3, 1, 3, 0, 0, 0, 0, 0,
    2, 0, 3, 1, 2, 1, 3, 1, 2, 1, 3, 0]

def Project.tables.pack(+sine: V.Vec, tangent: V.Vec, tanto: V.Vec, +toxs: List<&2, U32>,
  +angles: List<&2, U32>) -> Project.Tables:
  Tables{sine, tangent, tanto, V.Vec.of_list(Project.fence.list(toxs), 4096),
    V.Vec.of_list(angles, 321), V.Vec.of_list(Project.yslope.list(168n, 0), 168),
    V.Vec.of_list(Project.distscale.list(320n, sine, angles), 320),
    V.Vec.of_list(Project.coords(), 44), Maybe.default(&2, U32, List.head(&2, U32, angles), 0)}

def Project.tables.tox(sine: V.Vec, tangent: V.Vec, tanto: V.Vec, +toxs: List<&2, U32>) ->
  Project.Tables:
  Project.tables.pack(sine, tangent, tanto, toxs, Project.xtoangle(toxs))

def Project.tables.tan(sine: V.Vec, +tangent: V.Vec, tanto: V.Vec) -> Project.Tables:
  Project.tables.tox(sine, tangent, tanto, Project.tox.list(T.Tables.finetangent(), Project.focal(tangent)))

def Project.tables(+level: L.Level) -> Project.Tables:
  Project.tables.tan(L.Level.sine(level), V.Vec.of_list(T.Tables.finetangent(), 4096),
    L.Level.tanto(level))

# The view
# --------

# Doom's R_SetupFrame.
def View.make(+tables: Project.Tables, x: U32, y: U32, z: U32, +angle: U32, extralight: U32, fixedcolormap: U32) -> View:
  Tables{+sine, tangent, tanto, angletox, xtoangle, yslope, distscale, coords, clipangle} = tables
  View{x, y, z, angle, A.Angle.sin(sine, A.Angle.fine(angle)), A.Angle.cos(sine, A.Angle.fine(angle)),
    tables, extralight, fixedcolormap}

def View.fixedcolormap(v: View) -> U32:
  View{x, y, z, angle, sin, cos, tables, extralight, fixedcolormap} = v
  fixedcolormap

def View.angle(+v: View) -> U32:
  View{x, y, z, angle, sin, cos, tables, extralight, fixedcolormap} = v
  angle

def View.z(+v: View) -> U32:
  View{x, y, z, angle, sin, cos, tables, extralight, fixedcolormap} = v
  z

def View.extralight(+v: View) -> U32:
  View{x, y, z, angle, sin, cos, tables, extralight, fixedcolormap} = v
  extralight

def View.sine(+v: View) -> V.Vec:
  View{x, y, z, angle, sin, cos, tables, extralight, fixedcolormap} = v
  Tables{sine, tangent, tanto, angletox, xtoangle, yslope, distscale, coords, clipangle} = tables
  sine

def View.tangent(+v: View) -> V.Vec:
  View{x, y, z, angle, sin, cos, tables, extralight, fixedcolormap} = v
  Tables{sine, tangent, tanto, angletox, xtoangle, yslope, distscale, coords, clipangle} = tables
  tangent

def View.clipangle(+v: View) -> U32:
  View{x, y, z, angle, sin, cos, tables, extralight, fixedcolormap} = v
  Tables{sine, tangent, tanto, angletox, xtoangle, yslope, distscale, coords, clipangle} = tables
  clipangle

# The column at or after a view angle, which is relative to the view's
# and a quarter turn on: Doom's viewangletox[(angle + ANG90) >> 19].
def View.tox(+v: View, angle: U32) -> U32:
  View{x, y, z, va, sin, cos, tables, extralight, fixedcolormap} = v
  Tables{sine, tangent, tanto, angletox, xtoangle, yslope, distscale, coords, clipangle} = tables
  V.Vec.get(angletox, A.Angle.fine((angle + A.Angle.ang90() : U32)))

# A column's least view angle.
def View.xtoangle(+v: View, x: U32) -> U32:
  View{vx, y, z, angle, sin, cos, tables, extralight, fixedcolormap} = v
  Tables{sine, tangent, tanto, angletox, xtoangle, yslope, distscale, coords, clipangle} = tables
  V.Vec.get(xtoangle, x)

def View.yslope(+v: View, y: U32) -> U32:
  View{vx, vy, z, angle, sin, cos, tables, extralight, fixedcolormap} = v
  Tables{sine, tangent, tanto, angletox, xtoangle, yslope, distscale, coords, clipangle} = tables
  V.Vec.get(yslope, y)

def View.distscale(+v: View, x: U32) -> U32:
  View{vx, y, z, angle, sin, cos, tables, extralight, fixedcolormap} = v
  Tables{sine, tangent, tanto, angletox, xtoangle, yslope, distscale, coords, clipangle} = tables
  V.Vec.get(distscale, x)

# Doom's checkcoord: which of a box's top, bottom, left and right is
# corner coordinate k for the eye's position pos about it.
def View.coord(+v: View, pos: U32, k: U32) -> U32:
  View{vx, y, z, angle, sin, cos, tables, extralight, fixedcolormap} = v
  Tables{sine, tangent, tanto, angletox, xtoangle, yslope, distscale, coords, clipangle} = tables
  V.Vec.get(coords, (pos * 4 + k : U32))

# Doom's R_PointToAngle: the angle of a point from the eye.
def View.angle_to(+v: View, x: U32, y: U32) -> U32:
  View{vx, vy, z, angle, sin, cos, tables, extralight, fixedcolormap} = v
  Tables{sine, tangent, tanto, angletox, xtoangle, yslope, distscale, coords, clipangle} = tables
  A.Angle.of(tanto, (x - vx : U32), (y - vy : U32))

def View.dist_to.go(+sine: V.Vec, +tanto: V.Vec, +dx: U32, +dy: U32) -> U32:
  F.Fixed.div(dx, V.Vec.get(sine, A.Angle.fine((V.Vec.get(tanto,
    (Bool.pick(U32, U32.is_zero(dx), 0, F.Fixed.div(dy, dx)) >> 5n : U32)) + A.Angle.ang90() : U32))))

# Doom's R_PointToDist, with Chocolate Doom's guard against a point at
# the eye: the longer leg over the cosine of the angle between.
def View.dist_to(+v: View, x: U32, y: U32) -> U32:
  View{vx, vy, z, angle, sin, cos, tables, extralight, fixedcolormap} = v
  Tables{sine, tangent, tanto, angletox, xtoangle, yslope, distscale, coords, clipangle} = tables
  +dx = F.Fixed.abs((x - vx : U32))
  +dy = F.Fixed.abs((y - vy : U32))
  View.dist_to.go(sine, tanto, F.Fixed.max(dx, dy), F.Fixed.min(dx, dy))

def View.scale.of(+num: U32, +den: U32) -> U32:
  Bool.pick(U32, F.Fixed.gt(den, F.Fixed.sarn(num, 16n)),
    F.Fixed.max(256, F.Fixed.min(4194304, F.Fixed.div(num, den))), 4194304)

# Doom's R_ScaleFromGlobalAngle: the scale of a wall, by its normal's
# angle and its distance, at a global view angle; at most 64, at least
# 1/256, and 64 where the division would overflow.
def View.scale(+v: View, +visangle: U32, normal: U32, distance: U32) -> U32:
  View{x, y, z, angle, sin, cos, tables, extralight, fixedcolormap} = v
  Tables{+sine, tangent, tanto, angletox, xtoangle, yslope, distscale, coords, clipangle} = tables
  View.scale.of(
    F.Fixed.mul(Project.centerx(), A.Angle.sin(sine, A.Angle.fine((A.Angle.ang90() + visangle - normal : U32)))),
    F.Fixed.mul(distance, A.Angle.sin(sine, A.Angle.fine((A.Angle.ang90() + visangle - angle : U32)))))

# What the view's edges leave of the span from angle a1 to a2, both
# global: behind when the span faces away, seen when some column is
# left, from x1 up to but not x2. Doom's R_AddLine and R_CheckBBox
# share it.
type View.Span is Data:
  Span{behind: Bool, seen: Bool, x1: U32, x2: U32}

def View.span.cols(behind: Bool, inside: Bool, +x1: U32, +x2: U32) -> View.Span:
  Span{behind, Bool.and(inside, U32.is_lt(x1, x2)), x1, x2}

def View.span.clip(+v: View, +clip: U32, +span: U32, +r1: U32, +r2: U32) -> View.Span:
  +t1 = (r1 + clip : U32)
  +t2 = (clip - r2 : U32)
  +out1 = U32.is_gt(t1, (clip * 2 : U32))
  +out2 = U32.is_gt(t2, (clip * 2 : U32))
  View.span.cols(U32.is_ge(span, A.Angle.ang180()),
    Bool.not(Bool.or(Bool.and(out1, U32.is_ge((t1 - clip * 2 : U32), span)),
      Bool.and(out2, U32.is_ge((t2 - clip * 2 : U32), span)))),
    View.tox(v, Bool.pick(U32, out1, clip, r1)),
    View.tox(v, Bool.pick(U32, out2, F.Fixed.neg(clip), r2)))

def View.span(+v: View, +a1: U32, +a2: U32) -> View.Span:
  View.span.clip(v, View.clipangle(v), (a1 - a2 : U32), (a1 - View.angle(v) : U32),
    (a2 - View.angle(v) : U32))

# Light
# -----

# Doom's light number for a sector: its light level shifted down, with
# the extra light a muzzle flash adds and whatever else the caller adds
# to it, held to 0 and 15. Every light a frame turns into a colormap
# comes through here.
def Project.lightnum(+light: U32, +extra: U32) -> U32:
  F.Fixed.max(0, F.Fixed.min(15, ((light >> 4n) + extra : U32)))

# A colormap number: the light's start less the fade, held to 0 and 31.
def Project.shade(+startmap: U32, fade: U32) -> U32:
  F.Fixed.max(0, F.Fixed.min(31, (startmap - fade : U32)))

def Project.colormap(+fixedcolormap: U32, ordinary: U32) -> U32:
  Bool.pick(U32, U32.is_zero(fixedcolormap), ordinary, fixedcolormap)

# Doom's scalelight: the colormap of a wall column from its light
# number, 0 to 15, and its scale index, 0 to 47: brighter when nearer.
def Project.scalelight(lightnum: U32, index: U32) -> U32:
  Project.shade(((15 - lightnum : U32) * 4 : U32), (index >> 1n : U32))

# Doom's zlight: the colormap of a span from its light number and its
# distance index, 0 to 127.
def Project.zlight(lightnum: U32, index: U32) -> U32:
  Project.shade(((15 - lightnum : U32) * 4 : U32),
    ((F.Fixed.div(Project.centerx(), ((index + 1 : U32) << 20n : U32)) >> 12n : U32) >> 1n : U32))
