# Doom's visplanes: R_FindPlane and R_CheckPlane while the BSP is
# walked, R_DrawPlanes after it. A subsector's floor and ceiling each
# find the plane of their height, flat and light or make one; a wall
# range about to mark columns a plane has already marked makes a new
# one, which is what keeps a plane's columns one run of rows each; and
# each plane is then drawn as spans, a row's span running as far as the
# plane's columns hold that row, or as columns of the sky.
import Base
import ./bytes.bend as B
import ./fixed.bend as F
import ./angle.bend as A
import ./gfx.bend as G
import ./project.bend as P
import ./draw.bend as D

# Room for 128 planes, Doom's limit, before the first doubling.
def Planes.start() -> D.Draw.Planes:
  D.Planes{[], 0, Array.new(U32, 17n, 0), 17n, G.Gfx.none(), G.Gfx.none()}

# Finding
# -------

def Planes.fit(full: Bool, ps: D.Draw.Planes) -> D.Draw.Planes:
  match full:
    case False{}:
      ps
    case True{}:
      D.Planes{heads, +count, cols, +depth, floor, ceil} = ps
      D.Planes{heads, count, G.Gfx.Copy.dst(G.Gfx.copy(~B.Bytes.at, ~G.Gfx.same,
        U32.to_nat((count << 10n : U32)), 1, 0, 0, G.Copy{cols, Array.new(U32, 1n+depth, 0)})), 1n+depth,
        floor, ceil}

def Planes.new.put(head: D.Draw.Plane, ps: D.Draw.Planes) -> D.Draw.Planes:
  D.Planes{heads, +count, cols, depth, floor, ceil} = ps
  D.Planes{List.append(&2, D.Draw.Plane, heads, [head]), (count + 1 : U32),
    D.Draw.set(322n, cols, (count << 10n : U32), 255), depth, floor, ceil}

# A new plane after the others, no column of it marked; the array
# doubled first when it is full.
def Planes.new(head: D.Draw.Plane, ps: D.Draw.Planes) -> D.Draw.Planes:
  D.Planes{heads, +count, cols, +depth, floor, ceil} = ps
  Planes.new.put(head, Planes.fit(U32.is_ge((count << 10n : U32), U32.shln(1, depth)),
    D.Planes{heads, count, cols, depth, floor, ceil}))

# The subsector's floor or ceiling plane becomes plane index.
def Planes.slot(+isfloor: Bool, +index: U32, ps: D.Draw.Planes) -> D.Draw.Planes:
  D.Planes{heads, count, cols, depth, floor, ceil} = ps
  D.Planes{heads, count, cols, depth, Bool.pick(U32, isfloor, index, floor),
    Bool.pick(U32, isfloor, ceil, index)}

def Planes.claim.new(isfloor: Bool, head: D.Draw.Plane, ps: D.Draw.Planes) -> D.Draw.Planes:
  D.Planes{heads, +count, cols, depth, floor, ceil} = ps
  Planes.slot(isfloor, count, Planes.new(head, D.Planes{heads, count, cols, depth, floor, ceil}))

# The first plane of a height, flat and light, as Doom's search finds
# it, or none.
def Planes.search(heads: List<&2, D.Draw.Plane>, +height: U32, +pic: U32, +light: U32, +i: U32) -> U32:
  match heads:
    case []:
      G.Gfx.none()
    case D.Plane{h, p, l, minx, maxx} <> rest:
      Bool.pick(U32, Bool.and(U32.is_eq(h, height), Bool.and(U32.is_eq(p, pic), U32.is_eq(l, light))), i,
        Planes.search(rest, height, pic, light, (i + 1 : U32)))

def Planes.claim.put(missing: Bool, isfloor: Bool, head: D.Draw.Plane, found: U32, ps: D.Draw.Planes) ->
  D.Draw.Planes:
  match missing:
    case True{}:
      Planes.claim.new(isfloor, head, ps)
    case False{}:
      Planes.slot(isfloor, found, ps)

# Doom's R_FindPlane for a subsector's floor or ceiling, or none when
# the plane cannot be seen from the eye's height.
def Planes.claim(wanted: Bool, isfloor: Bool, +height: U32, +pic: U32, +light: U32, ps: D.Draw.Planes) ->
  D.Draw.Planes:
  match wanted:
    case False{}:
      Planes.slot(isfloor, G.Gfx.none(), ps)
    case True{}:
      D.Planes{+heads, count, cols, depth, floor, ceil} = ps
      +found = Planes.search(heads, height, pic, light, 0)
      Planes.claim.put(U32.is_eq(found, G.Gfx.none()), isfloor, D.Plane{height, pic, light, 320, 4294967295},
        found, D.Planes{heads, count, cols, depth, floor, ceil})

# Checking
# --------

# A scan of a plane's tops: whether any was marked.
type Planes.Scan is Type:
  Scan{cols: Array<U32>, base: U32, hit: Bool}

def Planes.scan.top(base: U32, hit: Bool, p: Array<U32> & U32) -> Planes.Scan:
  (cols, top) = p
  Scan{cols, base, Bool.or(hit, Bool.not(U32.is_eq(top, 255)))}

def Planes.scan(i: Nat, st: Planes.Scan) -> Planes.Scan:
  Scan{cols, +base, hit} = st
  Planes.scan.top(base, hit, B.Bytes.at(cols, (base + U32.from_nat(i) + 1 : U32)))

# The plane grows to the union when none of the range's columns it
# already spans is marked; else a plane like it starts at the range.
def Planes.check.hit(isfloor: Bool, p: U32, grown: D.Draw.Plane, fresh: D.Draw.Plane,
  heads: List<&2, D.Draw.Plane>, count: U32, depth: Nat, floor: U32, ceil: U32, scan: Planes.Scan) ->
  D.Draw.Planes:
  match scan:
    case Scan{cols, base, False{}}:
      D.Planes{List.set(&2, D.Draw.Plane, heads, U32.to_nat(p), grown), count, cols, depth, floor, ceil}
    case Scan{cols, base, True{}}:
      Planes.claim.new(isfloor, fresh, D.Planes{heads, count, cols, depth, floor, ceil})

def Planes.check.head(isfloor: Bool, +start: U32, +stop: U32, +p: U32, head: D.Draw.Plane,
  ps: D.Draw.Planes) -> D.Draw.Planes:
  D.Plane{+height, +pic, +light, +minx, +maxx} = head
  D.Planes{heads, count, cols, depth, floor, ceil} = ps
  +from = F.Fixed.max(start, minx)
  Planes.check.hit(isfloor, p, D.Plane{height, pic, light, F.Fixed.min(start, minx), F.Fixed.max(stop, maxx)},
    D.Plane{height, pic, light, start, stop}, heads, count, depth, floor, ceil,
    D.Draw.each(~Planes.Scan, ~Planes.scan, D.Draw.rows(from, F.Fixed.min(stop, maxx)), U32.to_nat(from),
      Scan{cols, (p << 10n : U32), False{}}))

# Doom's R_CheckPlane on the subsector's floor or ceiling plane, for a
# wall range about to mark it.
def Planes.check(wanted: Bool, +isfloor: Bool, start: U32, stop: U32, ps: D.Draw.Planes) -> D.Draw.Planes:
  match wanted:
    case False{}:
      ps
    case True{}:
      D.Planes{+heads, count, cols, depth, +floor, +ceil} = ps
      +p = Bool.pick(U32, isfloor, floor, ceil)
      Planes.check.head(isfloor, start, stop, p, Maybe.default(&2, D.Draw.Plane,
        List.get(&2, D.Draw.Plane, heads, U32.to_nat(p)), D.Plane{0, 0, 0, 320, 4294967295}),
        D.Planes{heads, count, cols, depth, floor, ceil})

# Spans
# -----

# What a plane's spans share: the view, the frame's x and y scales, the
# plane's height from the eye, its light number and its flat.
type Planes.Flat is Data:
  Flat{view: P.View, xscale: U32, yscale: U32, height: U32, light: U32, src: U32}

# Where a span starts in its flat, how it steps a column, and its
# colormap.
type Planes.Step is Data:
  Step{xfrac: U32, yfrac: U32, xstep: U32, ystep: U32, cmap: U32}

# The colormap of a span at a distance: Doom's zlight at the distance's
# light index, which the table's end caps.
def Planes.colormap(fixedcolormap: U32, light: U32, distance: U32) -> U32:
  (G.Gfx.colormap() + P.Project.colormap(fixedcolormap,
    P.Project.zlight(light, U32.min((distance >> 20n : U32), 127))) * 256 : U32)

def Planes.step.at(+view: P.View, +distance: U32, xscale: U32, yscale: U32, light: U32, +angle: U32,
  +length: U32) -> Planes.Step:
  P.View{vx, vy, z, va, sin, cos, tables, extralight, fixedcolormap} = view
  Step{(vx + F.Fixed.mul(A.Angle.cos(P.View.sine(view), angle), length) : U32),
    (F.Fixed.neg(vy) - F.Fixed.mul(A.Angle.sin(P.View.sine(view), angle), length) : U32),
    F.Fixed.mul(distance, xscale), F.Fixed.mul(distance, yscale), Planes.colormap(fixedcolormap, light, distance)}

def Planes.step.far(+view: P.View, +distance: U32, xscale: U32, yscale: U32, light: U32, +x1: U32) ->
  Planes.Step:
  Planes.step.at(view, distance, xscale, yscale, light,
    A.Angle.fine((P.View.angle(view) + P.View.xtoangle(view, x1) : U32)),
    F.Fixed.mul(distance, P.View.distscale(view, x1)))

# Doom's R_MapPlane: row y of a plane is at the plane's height times the
# row's slope; the span starts where the ray through its first column
# meets the plane, and steps by the distance times the frame's scales.
def Planes.step(flat: Planes.Flat, y: U32, x1: U32) -> Planes.Step:
  Flat{+view, xscale, yscale, height, light, src} = flat
  Planes.step.far(view, F.Fixed.mul(height, P.View.yslope(view, y)), xscale, yscale, light, x1)

def Planes.span.draw(mem: Array<U32>, y: U32, x1: U32, x2: U32, src: U32, step: Planes.Step) -> Array<U32>:
  Step{xfrac, yfrac, xstep, ystep, cmap} = step
  D.Draw.span(mem, y, x1, x2, xfrac, yfrac, xstep, ystep, src, cmap)

def Planes.flat.src(flat: Planes.Flat) -> U32:
  Flat{view, xscale, yscale, height, light, src} = flat
  src

# The rows closing at a column: each one's span, from where it opened to
# the column before.
type Planes.Rows is Type:
  Rows{mem: Array<U32>, x2: U32, flat: Planes.Flat}

def Planes.row.start(+y: U32, +x2: U32, +flat: Planes.Flat, p: Array<U32> & U32) -> Planes.Rows:
  (mem, +x1) = p
  Rows{Planes.span.draw(mem, y, x1, x2, Planes.flat.src(flat), Planes.step(flat, y, x1)), x2, flat}

def Planes.row(i: Nat, st: Planes.Rows) -> Planes.Rows:
  Rows{mem, x2, flat} = st
  +y = U32.from_nat(i)
  Planes.row.start(y, x2, flat, B.Bytes.at(mem, (G.Gfx.spanstart() + y : U32)))

def Planes.Rows.mem(st: Planes.Rows) -> Array<U32>:
  Rows{mem, x2, flat} = st
  mem

def Planes.close(mem: Array<U32>, +lo: U32, hi: U32, x2: U32, flat: Planes.Flat) -> Array<U32>:
  Planes.Rows.mem(D.Draw.each(~Planes.Rows, ~Planes.row, D.Draw.rows(lo, hi), U32.to_nat(lo),
    Rows{mem, x2, flat}))

def Planes.open(mem: Array<U32>, +lo: U32, hi: U32, x: U32) -> Array<U32>:
  D.Draw.set(D.Draw.rows(lo, hi), mem, (G.Gfx.spanstart() + lo : U32), x)

# Doom's R_MakeSpans between the column before x, marked from t1 to b1,
# and column x, from t2 to b2: the rows only the first holds close, from
# its top down to the second's and from its bottom up; the rows only the
# second holds open at x, likewise. A column not marked has top 255 and
# holds no row.
def Planes.spans(+x: U32, +t1: U32, +b1: U32, +t2: U32, +b2: U32, +flat: Planes.Flat,
  mem: Array<U32>) -> Array<U32>:
  +e1 = F.Fixed.min((t2 - 1 : U32), b1)
  +t1n = Bool.pick(U32, F.Fixed.le(t1, e1), (e1 + 1 : U32), t1)
  +s1 = F.Fixed.max((b2 + 1 : U32), t1n)
  +b1n = Bool.pick(U32, F.Fixed.le(s1, b1), (s1 - 1 : U32), b1)
  +e2 = F.Fixed.min((t1n - 1 : U32), b2)
  +t2n = Bool.pick(U32, F.Fixed.le(t2, e2), (e2 + 1 : U32), t2)
  Planes.open(Planes.open(Planes.close(Planes.close(mem, t1, e1, (x - 1 : U32), flat), s1, b1,
    (x - 1 : U32), flat), t2, e2, x), F.Fixed.max((b1n + 1 : U32), t2n), b2, x)

# A plane's columns walked left to right, to one past its last: the
# arrays, the plane's first slot, and the column before's top and
# bottom.
type Planes.Run is Type:
  Run{mem: Array<U32>, cols: Array<U32>, base: U32, t1: U32, b1: U32, flat: Planes.Flat}

def Planes.run.bottom(+x: U32, base: U32, t1: U32, b1: U32, +flat: Planes.Flat, mem: Array<U32>, +t2: U32,
  p: Array<U32> & U32) -> Planes.Run:
  (cols, +b2) = p
  Run{Planes.spans(x, t1, b1, t2, b2, flat, mem), cols, base, t2, b2, flat}

def Planes.run.top(+x: U32, +base: U32, t1: U32, b1: U32, flat: Planes.Flat, mem: Array<U32>,
  p: Array<U32> & U32) -> Planes.Run:
  (cols, t2) = p
  Planes.run.bottom(x, base, t1, b1, flat, mem, t2, B.Bytes.at(cols, (base + x + 513 : U32)))

def Planes.run(i: Nat, st: Planes.Run) -> Planes.Run:
  Run{mem, cols, +base, t1, b1, flat} = st
  +x = U32.from_nat(i)
  Planes.run.top(x, base, t1, b1, flat, mem, B.Bytes.at(cols, (base + x + 1 : U32)))

# The sky
# -------

# Doom's sky column: the sky texture turns once in four full turns of
# the view, a column every 2^22 of angle.
def Planes.skycol(+view: P.View, x: U32) -> U32:
  ((P.View.angle(view) + P.View.xtoangle(view, x) : U32) >> 22n : U32)

type Planes.Sky is Type:
  Sky{mem: Array<U32>, cols: Array<U32>, base: U32, view: P.View, gfx: G.Gfx}

# A sky column from its top to its bottom mark, the texture's row 100 at
# the view's centre, one texel a row, never lit.
def Planes.sky.bottom(+x: U32, base: U32, +view: P.View, +gfx: G.Gfx, mem: Array<U32>, yl: U32,
  p: Array<U32> & U32) -> Planes.Sky:
  (cols, yh) = p
  Sky{D.Draw.column(mem, x, yl, yh, G.Gfx.column(gfx, G.Gfx.skytex(gfx), Planes.skycol(view, x)), 6553600,
    65536, G.Gfx.colormap()), cols, base, view, gfx}

def Planes.sky.top(+x: U32, +base: U32, view: P.View, gfx: G.Gfx, mem: Array<U32>, p: Array<U32> & U32) ->
  Planes.Sky:
  (cols, yl) = p
  Planes.sky.bottom(x, base, view, gfx, mem, yl, B.Bytes.at(cols, (base + x + 513 : U32)))

def Planes.sky(i: Nat, st: Planes.Sky) -> Planes.Sky:
  Sky{mem, cols, +base, view, gfx} = st
  +x = U32.from_nat(i)
  Planes.sky.top(x, base, view, gfx, mem, B.Bytes.at(cols, (base + x + 1 : U32)))

# Drawing
# -------

# The two arrays a plane's drawing threads.
type Planes.Both is Type:
  Both{mem: Array<U32>, cols: Array<U32>}

def Planes.Run.both(st: Planes.Run) -> Planes.Both:
  Run{mem, cols, base, t1, b1, flat} = st
  Both{mem, cols}

def Planes.Sky.both(st: Planes.Sky) -> Planes.Both:
  Sky{mem, cols, base, view, gfx} = st
  Both{mem, cols}

# The frame's x and y scales: a unit of the flat a column, at the
# distance where the view is 160 wide.
def Planes.xscale(+view: P.View) -> U32:
  F.Fixed.div(A.Angle.cos(P.View.sine(view), A.Angle.fine((P.View.angle(view) - A.Angle.ang90() : U32))),
    P.Project.centerx())

def Planes.yscale(+view: P.View) -> U32:
  F.Fixed.neg(F.Fixed.div(A.Angle.sin(P.View.sine(view),
    A.Angle.fine((P.View.angle(view) - A.Angle.ang90() : U32))), P.Project.centerx()))

def Planes.draw.one(empty: Bool, sky: Bool, +view: P.View, +gfx: G.Gfx, +i: U32, head: D.Draw.Plane,
  st: Planes.Both) -> Planes.Both:
  match empty sky:
    case True{} _:
      st
    case False{} True{}:
      D.Plane{height, pic, light, +minx, maxx} = head
      Both{mem, cols} = st
      Planes.Sky.both(D.Draw.each(~Planes.Sky, ~Planes.sky, D.Draw.rows(minx, maxx), U32.to_nat(minx),
        Sky{mem, cols, (i << 10n : U32), view, gfx}))
    case False{} False{}:
      D.Plane{height, pic, light, +minx, maxx} = head
      Both{mem, cols} = st
      Planes.Run.both(D.Draw.each(~Planes.Run, ~Planes.run, D.Draw.rows(minx, (maxx + 1 : U32)),
        U32.to_nat(minx), Run{mem, cols, (i << 10n : U32), 255, 0,
          Flat{view, Planes.xscale(view), Planes.yscale(view), F.Fixed.abs((height - P.View.z(view) : U32)),
            P.Project.lightnum(light, P.View.extralight(view)), G.Gfx.flat(gfx, pic)}}))

def Planes.draw.go(heads: List<&2, D.Draw.Plane>, +view: P.View, +gfx: G.Gfx, +i: U32, st: Planes.Both) ->
  Planes.Both:
  match heads:
    case []:
      st
    case D.Plane{height, +pic, light, +minx, +maxx} <> rest:
      Planes.draw.go(rest, view, gfx, (i + 1 : U32), Planes.draw.one(F.Fixed.gt(minx, maxx),
        U32.is_eq(pic, G.Gfx.sky(gfx)), view, gfx, i, D.Plane{height, pic, light, minx, maxx}, st))

def Planes.Both.mem(st: Planes.Both) -> Array<U32>:
  Both{mem, cols} = st
  mem

# Doom's R_DrawPlanes: every plane in the order it was made.
def Planes.draw(+view: P.View, +gfx: G.Gfx, mem: Array<U32>, ps: D.Draw.Planes) -> Array<U32>:
  D.Planes{heads, count, cols, depth, floor, ceil} = ps
  Planes.Both.mem(Planes.draw.go(heads, view, gfx, 0, Both{mem, cols}))
