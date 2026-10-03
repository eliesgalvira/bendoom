# Doom's R_RenderBSPNode, R_CheckBBox and R_Subsector: the BSP walked
# front to back from the root. Doom recurses; here the walk is a stack
# of tasks in the draw's state, since each step reads the solid columns
# the last one left, and a far child's box is tested only once the near
# side is drawn.
import Base
import ./vec.bend as V
import ./fixed.bend as F
import ./clip.bend as C
import ./level.bend as L
import ./gfx.bend as G
import ./project.bend as P
import ./draw.bend as D
import ./planes.bend as N
import ./segs.bend as S

def Bsp.push(tasks: List<&2, D.Draw.Task>, st: D.Draw) -> D.Draw:
  D.Draw{mem, solid, walls, rest, planes, seen} = st
  D.Draw{mem, solid, walls, List.append(&2, D.Draw.Task, tasks, rest), planes, seen}

def Bsp.lines(n: Nat, +seg: U32) -> List<&2, D.Draw.Task>:
  match n:
    case 0n:
      []
    case 1n+m:
      D.Line{seg} <> Bsp.lines(m, (seg + 1 : U32))

# Doom's R_FindPlane's sky rule: all sky planes are one, whatever their
# height and light.
def Bsp.plane(wanted: Bool, isfloor: Bool, height: U32, +pic: U32, light: U32, +gfx: G.Gfx,
  ps: D.Draw.Planes) -> D.Draw.Planes:
  +sky = U32.is_eq(pic, G.Gfx.sky(gfx))
  N.Planes.claim(wanted, isfloor, Bool.pick(U32, sky, 0, height), pic, Bool.pick(U32, sky, 0, light), ps)

# A sector seen: ranked when the walk first reaches it, where Doom's
# R_AddSprites gathers its things, once however many subsectors it is
# split into.
def Bsp.see(seen: D.Draw.Seen, +s: U32) -> D.Draw.Seen:
  D.Seen{+ranks, +next} = seen
  +was = V.Vec.get(ranks, s)
  D.Seen{V.Vec.set(ranks, s, Bool.pick(U32, U32.is_zero(was), next, was)), (next + 1 : U32)}

# The floor's plane when the eye is above it, the ceiling's when the eye
# is below it or it is the sky, then the segs, in order; and the sector
# seen.
def Bsp.sub.planes(+view: P.View, +gfx: G.Gfx, s: U32, sector: L.Level.Sector, floorpic: U32, +ceilpic: U32,
  sub: L.Level.Sub, st: D.Draw) -> D.Draw:
  L.Sector{+floor, +ceil, +light} = sector
  L.Sub{count, first} = sub
  D.Draw{mem, solid, walls, tasks, planes, seen} = st
  D.Draw{mem, solid, walls, List.append(&2, D.Draw.Task, Bsp.lines(U32.to_nat(count), first), tasks),
    Bsp.plane(Bool.or(F.Fixed.gt(ceil, P.View.z(view)), U32.is_eq(ceilpic, G.Gfx.sky(gfx))), False{}, ceil,
      ceilpic, light, gfx,
      Bsp.plane(F.Fixed.lt(floor, P.View.z(view)), True{}, floor, floorpic, light, gfx, planes)),
    Bsp.see(seen, s)}

# Doom's R_Subsector.
def Bsp.sub(+view: P.View, +level: L.Level, +gfx: G.Gfx, +ss: U32, st: D.Draw) -> D.Draw:
  +sector = L.Level.leaf_sector(level, ss)
  Bsp.sub.planes(view, gfx, sector, L.Level.sector(level, sector), G.Gfx.floorpic(gfx, level, sector),
    G.Gfx.ceilpic(gfx, level, sector), L.Level.sub(level, ss), st)

# A node's near child, then its far one if its box might show. Child
# 65535 is Doom's -1, subsector 0 of a map with no nodes.
def Bsp.visit.if(leaf: Bool, +view: P.View, +level: L.Level, gfx: G.Gfx, +n: U32, st: D.Draw) -> D.Draw:
  match leaf:
    case True{}:
      Bsp.sub(view, level, gfx, Bool.pick(U32, U32.is_eq(n, 65535), 0, (n .&. 32767 : U32)), st)
    case False{}:
      P.View{+x, +y, z, angle, sin, cos, tables, extralight} = view
      +side = L.Level.side_of(level, n, x, y)
      Bsp.push([D.Visit{L.Level.node.child(level, n, side)}, D.Check{n, (side .^. 1 : U32)}], st)

def Bsp.visit(+view: P.View, +level: L.Level, gfx: G.Gfx, +n: U32, st: D.Draw) -> D.Draw:
  Bsp.visit.if(L.Level.is_leaf(n), view, level, gfx, n, st)

def Bsp.coord(box: L.Level.Box, +i: U32) -> U32:
  L.Box{top, bottom, left, right} = box
  Bool.pick(U32, U32.is_eq(i, 0), top, Bool.pick(U32, U32.is_eq(i, 1), bottom,
    Bool.pick(U32, U32.is_eq(i, 2), left, right)))

def Bsp.corner(+view: P.View, box: L.Level.Box, pos: U32, k: U32) -> U32:
  Bsp.coord(box, P.View.coord(view, pos, k))

def Bsp.shows.span(span: P.View.Span, solid: List<&2, C.Clip.Range>) -> Bool:
  P.Span{behind, seen, +x1, +x2} = span
  Bool.or(behind, Bool.and(seen,
    Bool.not(C.Clip.covers(U32.to_nat(x1), U32.to_nat((x2 - 1 : U32)), solid))))

def Bsp.shows.at(+view: P.View, +box: L.Level.Box, +pos: U32, solid: List<&2, C.Clip.Range>) -> Bool:
  Bool.or(U32.is_eq(pos, 5), Bsp.shows.span(P.View.span(view,
    P.View.angle_to(view, Bsp.corner(view, box, pos, 0), Bsp.corner(view, box, pos, 1)),
    P.View.angle_to(view, Bsp.corner(view, box, pos, 2), Bsp.corner(view, box, pos, 3))), solid))

# Doom's R_CheckBBox: whether some column of the box's span, seen from
# the eye's position about it, is not yet solid. Inside the box, or with
# the span facing away, it might be.
def Bsp.shows(+view: P.View, +box: L.Level.Box, solid: List<&2, C.Clip.Range>) -> Bool:
  P.View{+x, +y, z, angle, sin, cos, tables, extralight} = view
  L.Box{+top, +bottom, +left, +right} = box
  Bsp.shows.at(view, box,
    ((Bool.pick(U32, F.Fixed.ge(y, top), 0, Bool.pick(U32, F.Fixed.gt(y, bottom), 1, 2)) << 2n)
      + Bool.pick(U32, F.Fixed.le(x, left), 0, Bool.pick(U32, F.Fixed.lt(x, right), 1, 2)) : U32), solid)

def Bsp.check.if(shows: Bool, child: U32, st: D.Draw) -> D.Draw:
  match shows:
    case True{}:
      Bsp.push([D.Visit{child}], st)
    case False{}:
      st

def Bsp.check(+view: P.View, +level: L.Level, +n: U32, +side: U32, st: D.Draw) -> D.Draw:
  D.Draw{mem, +solid, walls, tasks, planes, seen} = st
  Bsp.check.if(Bsp.shows(view, L.Level.box(level, n, side), solid), L.Level.node.child(level, n, side),
    D.Draw{mem, solid, walls, tasks, planes, seen})

def Bsp.go(fuel: Nat, st: D.Draw, +view: P.View, +level: L.Level, +gfx: G.Gfx) -> D.Draw:
  match fuel st:
    case 0n st:
      st
    case 1n+f D.Draw{mem, solid, walls, [], planes, seen}:
      D.Draw{mem, solid, walls, [], planes, seen}
    case 1n+f D.Draw{mem, solid, walls, D.Visit{n} <> rest, planes, seen}:
      Bsp.go(f, Bsp.visit(view, level, gfx, n, D.Draw{mem, solid, walls, rest, planes, seen}), view, level,
        gfx)
    case 1n+f D.Draw{mem, solid, walls, D.Check{n, side} <> rest, planes, seen}:
      Bsp.go(f, Bsp.check(view, level, n, side, D.Draw{mem, solid, walls, rest, planes, seen}), view, level,
        gfx)
    case 1n+f D.Draw{mem, solid, walls, D.Line{seg} <> rest, planes, seen}:
      Bsp.go(f, S.Segs.add(view, level, gfx, seg, D.Draw{mem, solid, walls, rest, planes, seen}), view, level,
        gfx)

# The walk from the root: every task done, or the fuel (far past any
# map's nodes and segs) spent.
def Bsp.walk(+view: P.View, +level: L.Level, +gfx: G.Gfx, mem: Array<U32>) -> D.Draw:
  Bsp.go(U32.to_nat(16777216), D.Draw{mem, [], [], [D.Visit{L.Level.root(level)}], N.Planes.start(),
    D.Seen{V.Vec.of_list([], L.Level.nsectors(level)), 1}}, view, level, gfx)
