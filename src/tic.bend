# The tic: Doom's P_Ticker over the sim's state and its specials. The
# level's start, the monsters' chase and attacks, P_MobjThinker for a
# thing, each thinker's turn, P_PlayerThink, and the tic that maps one
# state of the level to the next.
import Base
import ./vec.bend as V
import ./fixed.bend as F
import ./angle.bend as A
import ./level.bend as L
import ./keys.bend as K
import ./random.bend as M
import ./things.bend as H
import ./inventory.bend as I
import ./sound.bend as Sn
import ./sim.bend as S
import ./special.bend as Sp

# The level's start
# -----------------

# The state a level starts in, from the map as loaded, with the player
# and its inventory at rest at a place, the things spawned with the
# random numbers they draw from an index, then the lights in sector
# order, and the status bar's own state and whether use is down as the
# caller says.
def State.at.spawned(+level: L.Level, place: L.Level.Start, spawn: H.Thing.Spawn, inv: I.Inventory, face: V.Vec,
  usedown: Bool) -> S.State:
  H.Spawn{things, rnd, you} = spawn
  S.Sim.psprites.start(Sp.Sim.lights(U32.to_nat(L.Level.nsectors(level)), 0,
    S.State.populated(things, L.Level.nthings(level),
      S.State{S.Player.at(level, place, inv), level, H.Things.none(0, you, 0, 0), L.Level.sidetex(level), S.Thinkers{[], []},
        rnd, 0, S.Unended{}, usedown, [], face, False{}, S.Sim.secrets(level)})))

# A new game at a place: G_InitNew clears the random indices, and
# G_PlayerReborn hands out the pistol start with use down, so a key held
# since before the level does nothing. The first two commands precede
# the startup melt and its 320 M_Random draws.
def State.at(+level: L.Level, place: L.Level.Start) -> S.State:
  State.at.spawned(level, place, H.Thing.spawn(level, 0), I.Inventory.start(),
    S.Sim.Face.melt.wait(2, S.Sim.Face.start(0)), True{})

def State.start(+level: L.Level) -> S.State:
  State.at(level, L.Level.start_of(level))

# G_DoLoadLevel after a level that came before, which neither random
# index restarts from: the map from its start with the player, use and
# attack as the caller hands them, and ST_Start's bar. Its melt waits
# until the first ST_Ticker has chosen the face.
def State.restarted(+level: L.Level, +rnd: U32, +inv: I.Inventory, +usedown: Bool, attackdown: Bool, +mrnd: U32,
  face: V.Vec) -> S.State:
  State.at.spawned(level, L.Level.start_of(level), H.Thing.spawn(level, rnd), inv,
    S.Sim.Face.melt.wait(1, S.Sim.Face.restart(I.Inventory.weapons(inv), attackdown, mrnd, face)), usedown)

# G_DoReborn's reload: the dead player's map again from a pistol start,
# as G_PlayerReborn leaves the player.
def State.reloaded(+level: L.Level, +dead: S.State) -> S.State:
  State.restarted(level, S.State.rnd(dead), I.Inventory.start(), True{}, True{}, S.State.mrnd(dead),
    S.State.face(dead))

# G_DoWorldDone's load: the next map, entered with the inventory
# G_PlayerFinishLevel leaves, M_Random's index where the tally left it,
# and use and attack down as WI_checkForAccelerate last saw them.
def State.carried(+level: L.Level, +mrnd: U32, +usedown: Bool, +attackdown: Bool, +after: S.State) -> S.State:
  State.restarted(level, S.State.rnd(after), I.Inventory.finished(S.Player.inv(S.State.player(after))), usedown,
    attackdown, mrnd, S.State.face(after))

# Chasing
# -------

# Doom's xspeed table, the fixed-point step a thing of speed 1 takes in
# each of the eight directions: a whole unit along an axis and 47000 of
# 65536 along each half of a diagonal. yspeed is the same table read six
# places on, since it is the sine where this is the cosine.
def Sim.chase.xspeed(+dir: U32) -> U32:
  Bool.pick(U32, U32.is_eq(dir, 0), 65536,
    Bool.pick(U32, U32.is_eq(dir, 1), 47000,
      Bool.pick(U32, U32.is_eq(dir, 2), 0,
        Bool.pick(U32, U32.is_eq(dir, 3), 4294920296,
          Bool.pick(U32, U32.is_eq(dir, 4), 4294901760,
            Bool.pick(U32, U32.is_eq(dir, 5), 4294920296,
              Bool.pick(U32, U32.is_eq(dir, 6), 0, 47000)))))))

def Sim.chase.yspeed(+dir: U32) -> U32:
  Sim.chase.xspeed(((dir + 6 : U32) .&. 7 : U32))

# Doom's opposite table: the way a thing walking a direction came from.
def Sim.chase.opposite(+dir: U32) -> U32:
  Bool.pick(U32, U32.is_ge(dir, H.Thing.nodir()), H.Thing.nodir(), ((dir + 4 : U32) .&. 7 : U32))

# Doom's diags table: the diagonal that points at the target, chosen by
# the signs of the two distances to it.
def Sim.chase.diag(+deltax: U32, +deltay: U32) -> U32:
  Bool.pick(U32, F.Fixed.is_neg(deltay), Bool.pick(U32, F.Fixed.gt(deltax, 0), 7, 5),
    Bool.pick(U32, F.Fixed.gt(deltax, 0), 1, 3))

# A_Chase's turn: the facing snapped down to the eight directions and
# moved a further 45 degrees toward the one the thing walks.
def Sim.chase.turn(+angle: U32, +dir: U32) -> U32:
  +snapped = (angle .&. 3758096384 : U32)
  +delta = (snapped - (dir << 29n : U32) : U32)
  Bool.pick(U32, U32.is_zero(delta), snapped,
    Bool.pick(U32, F.Fixed.is_neg(delta), (snapped + 536870912 : U32), (snapped - 536870912 : U32)))

# A counter one tic further down, which never passes zero.
def Sim.chase.counted(+n: U32) -> U32:
  Bool.pick(U32, U32.is_zero(n), 0, (n - 1 : U32))

# The thing where its move landed: on the floor it found, as P_Move puts
# a thing that does not float, between the heights its check gathered,
# and in the sector under it.
def Sim.chase.landed(th: H.Thing, +level: L.Level, +x: U32, +y: U32, +floor: U32, +ceil: U32) -> H.Thing:
  H.Thing{id, kind, ox, oy, z, wasfloor, wasceil, angle, was, state, tics, momz, ai} = th
  H.Thing{id, kind, x, y, floor, floor, ceil, angle, L.Level.sector_at(level, x, y), state, tics, momz, ai}

# P_UnsetThingPosition and P_SetThingPosition about a thing's move.
def Sim.chase.placed(+th: H.Thing, +level: L.Level, +x: U32, +y: U32, +floor: U32, +ceil: U32, s: S.State) ->
  S.State:
  S.State{player, lv, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn, secrets} = s
  S.State{player, lv, H.Things.moved(things, L.Level.blockmap_of(level), th,
    Sim.chase.landed(th, level, x, y, floor, ceil)), sidetex, thinkers, rnd, clock, ended, usedown, sounds,
    mrnd, reborn, secrets}

def Sim.chase.step.fin(taken: Bool, th: H.Thing, +id: U32, +level: L.Level, +ox: U32, +oy: U32, +x: U32,
  +y: U32, +r: U32, +floor: U32, +ceil: U32, s: S.State) -> S.Sim.Walk:
  match taken:
    case False{}:
      S.Walk{False{}, id, s}
    case True{}:
      S.Walk{True{}, id, Sp.Sim.thing.crossed(S.Sim.crossings(level, ox, oy, x, y, r),
        Sim.chase.placed(th, level, x, y, floor, ceil, s))}

def Sim.chase.step.fit(+z: U32, +height: U32, th: H.Thing, +id: U32, +level: L.Level, +ox: U32, +oy: U32,
  +x: U32, +y: U32, +r: U32, f: S.Sim.Fit, s: S.State) -> S.Sim.Walk:
  S.Fit{ok, +floor, +ceil, +drop} = f
  Sim.chase.step.fin(S.Sim.walks(S.Fit{ok, floor, ceil, drop}, z, height), th, id, level, ox, oy, x, y, r, floor,
    ceil, s)

def Sim.chase.step.met(m: S.Sim.Body, th: H.Thing, +id: U32, +level: L.Level, +x: U32, +y: U32,
  met: S.Sim.Met, s: S.State) -> S.Sim.Walk:
  S.Body{i, +ox, +oy, +z, +radius, +height, flags} = m
  Sim.chase.step.fit(z, height, th, id, level, ox, oy, x, y, radius,
    S.Sim.check.met(met, level, S.Body{i, x, y, z, radius, height, flags}, 3), s)

# Doom's P_TryMove for a thing of the population: its position check at
# the place with mask 3, so the lines that block monsters stop it as
# well; the rules P_TryMove adds, the ledge among them; the relink; and
# the walk-over specials the move crossed.
def Sim.chase.step(+th: H.Thing, +id: U32, +level: L.Level, +x: U32, +y: U32, +s: S.State) -> S.Sim.Walk:
  Sim.chase.step.met(S.Sim.body.of(th), th, id, level, x, y,
    S.Sim.met(level, S.State.things(s), S.State.player(s), S.Sim.Body.at(S.Sim.body.of(th), x, y)), s)

# P_Move's blocked branch: with no special line in the way the move
# simply failed; with one, the thing stops where it is and presses each,
# the last gathered first, and counts as having moved if any opened.
def Sim.chase.opened(lines: List<&2, U32>, +id: U32, s: S.State) -> S.Sim.Walk:
  match lines:
    case []:
      S.Walk{False{}, id, s}
    case some:
      Sp.Sim.thing.uses(some, S.Walk{False{}, id, S.Sim.thing.counted(id, H.Thing.hurt.movedir(), H.Thing.nodir(), s)})

def Sim.chase.move.tried(w: S.Sim.Walk, +level: L.Level, +x: U32, +y: U32, +r: U32) -> S.Sim.Walk:
  match w:
    case S.Walk{True{}, id, s}:
      S.Walk{True{}, id, s}
    case S.Walk{False{}, +id, s}:
      Sim.chase.opened(S.Sim.spechit(level, x, y, r, 3), id, s)

# A thing blocking P_CheckPosition ends it before any line is inspected,
# so P_Move has no special line to use in that case.
def Sim.chase.move.met(met: S.Sim.Met, +tx: U32, +ty: U32, +r: U32, +th: H.Thing, +id: U32,
  +level: L.Level, s: S.State) -> S.Sim.Walk:
  match met:
    case S.Met{before, Some{hit}}:
      S.Walk{False{}, id, s}
    case S.Met{before, None{}}:
      Sim.chase.move.tried(Sim.chase.step.met(S.Sim.body.of(th), th, id, level, tx, ty, S.Met{before, None{}}, s),
        level, tx, ty, r)

def Sim.chase.move.at(+tx: U32, +ty: U32, +r: U32, +th: H.Thing, +id: U32, +level: L.Level, +s: S.State) ->
  S.Sim.Walk:
  Sim.chase.move.met(S.Sim.met(level, S.State.things(s), S.State.player(s), S.Sim.Body.at(S.Sim.body.of(th), tx, ty)),
    tx, ty, r, th, id, level, s)

def Sim.chase.move.go(m: S.Sim.Body, th: H.Thing, +id: U32, +level: L.Level, +speed: U32, +dir: U32, s: S.State) ->
  S.Sim.Walk:
  S.Body{i, x, y, z, radius, height, flags} = m
  Sim.chase.move.at((x + (speed * Sim.chase.xspeed(dir) : U32) : U32),
    (y + (speed * Sim.chase.yspeed(dir) : U32) : U32), radius, th, id, level, s)

def Sim.chase.move.dir(nodir: Bool, m: S.Sim.Body, th: H.Thing, +id: U32, +level: L.Level, +speed: U32,
  +dir: U32, s: S.State) -> S.Sim.Walk:
  match nodir:
    case True{}:
      S.Walk{False{}, id, s}
    case False{}:
      Sim.chase.move.go(m, th, id, level, speed, dir, s)

def Sim.chase.move.of(+th: H.Thing, +id: U32, +level: L.Level, +kind: U32, +dir: U32, s: S.State) -> S.Sim.Walk:
  Sim.chase.move.dir(U32.is_ge(dir, H.Thing.nodir()), S.Sim.body.of(th), th, id, level, H.Thing.speed(kind), dir,
    s)

def Sim.chase.move.some(m: Maybe<&2, H.Thing>, +id: U32, +level: L.Level, s: S.State) -> S.Sim.Walk:
  match m:
    case None{}:
      S.Walk{False{}, id, s}
    case Some{+th}:
      Sim.chase.move.of(th, id, level, H.Thing.kind(th), V.Vec.get(H.Thing.hurt(th), H.Thing.hurt.movedir()), s)

# Doom's P_Move: the thing walks its type's speed in the direction it
# holds. A thing with no direction never moves; one whose move is
# blocked opens the special lines its box reached.
def Sim.chase.move(w: S.Sim.Walk, +level: L.Level) -> S.Sim.Walk:
  S.Walk{ok, +id, +s} = w
  Sim.chase.move.some(H.Things.get(S.State.things(s), id), id, level, s)

# Doom's P_TryWalk: a move that was taken draws the tics the thing keeps
# the direction for, 0 to 15.
def Sim.chase.walked(w: S.Sim.Walk) -> S.Sim.Walk:
  match w:
    case S.Walk{False{}, id, s}:
      S.Walk{False{}, id, s}
    case S.Walk{True{}, +id, S.State{player, level, things, sidetex, thinkers, +rnd, clock, ended, usedown, sounds, mrnd, reborn, secrets}}:
      +drawn = M.Random.next(rnd)
      S.Walk{True{}, id, S.Sim.thing.counted(id, H.Thing.hurt.movecount(), (M.Random.at(drawn) .&. 15 : U32),
        S.State{player, level, things, sidetex, thinkers, drawn, clock, ended, usedown, sounds, mrnd, reborn, secrets})}

def Sim.chase.walk(w: S.Sim.Walk, +level: L.Level) -> S.Sim.Walk:
  Sim.chase.walked(Sim.chase.move(w, level))

# One of P_NewChaseDir's attempts: the thing takes the direction and
# walks it, unless an earlier attempt already carried it or this one is
# no direction at all or the way it came.
def Sim.chase.try(w: S.Sim.Walk, allowed: Bool, +dir: U32, +level: L.Level) -> S.Sim.Walk:
  match w allowed:
    case S.Walk{True{}, id, s} _:
      S.Walk{True{}, id, s}
    case S.Walk{False{}, id, s} False{}:
      S.Walk{False{}, id, s}
    case S.Walk{False{}, +id, s} True{}:
      Sim.chase.walk(S.Walk{False{}, id, S.Sim.thing.counted(id, H.Thing.hurt.movedir(), dir, s)}, level)

# P_NewChaseDir's direct route: with both axes pointing away the thing
# faces the diagonal between them whether or not it may walk it, and
# walks it unless that is the way it came.
def Sim.chase.diagonal(direct: Bool, +dir: U32, +back: Bool, w: S.Sim.Walk, +level: L.Level) -> S.Sim.Walk:
  match direct:
    case False{}:
      w
    case True{}:
      S.Walk{ok, +id, s} = w
      Sim.chase.try(S.Walk{False{}, id, S.Sim.thing.counted(id, H.Thing.hurt.movedir(), dir, s)}, Bool.not(back), dir,
        level)

# P_NewChaseDir mid-run: the walk so far and the two axis directions
# still to try, in the order the swap draw left them and with the way it
# came struck out.
type Sim.Chase is Data:
  Chase{w: S.Sim.Walk, first: U32, second: U32}

def Sim.chase.unless(+dir: U32, +back: U32) -> U32:
  Bool.pick(U32, U32.is_eq(dir, back), H.Thing.nodir(), dir)

def Sim.chase.swapped(swap: Bool, w: S.Sim.Walk, +d1: U32, +d2: U32, +back: U32) -> Sim.Chase:
  match swap:
    case True{}:
      Chase{w, Sim.chase.unless(d2, back), Sim.chase.unless(d1, back)}
    case False{}:
      Chase{w, Sim.chase.unless(d1, back), Sim.chase.unless(d2, back)}

# P_NewChaseDir's draw that may swap the two axis directions: made
# whether or not the distances decide it on their own, as C's || leaves
# it, and only where the direct route did not already carry the thing.
def Sim.chase.order(w: S.Sim.Walk, +d1: U32, +d2: U32, +back: U32, +far: Bool) -> Sim.Chase:
  match w:
    case S.Walk{True{}, id, s}:
      Chase{S.Walk{True{}, id, s}, H.Thing.nodir(), H.Thing.nodir()}
    case S.Walk{False{}, id, S.State{player, level, things, sidetex, thinkers, +rnd, clock, ended, usedown, sounds, mrnd, reborn, secrets}}:
      +drawn = M.Random.next(rnd)
      Sim.chase.swapped(Bool.or(U32.is_lt(200, M.Random.at(drawn)), far),
        S.Walk{False{}, id,
          S.State{player, level, things, sidetex, thinkers, drawn, clock, ended, usedown, sounds, mrnd, reborn, secrets}},
        d1, d2, back)

def Sim.chase.axes(c: Sim.Chase, +level: L.Level) -> S.Sim.Walk:
  Chase{w, +first, +second} = c
  Sim.chase.try(Sim.chase.try(w, Bool.not(U32.is_eq(first, H.Thing.nodir())), first, level),
    Bool.not(U32.is_eq(second, H.Thing.nodir())), second, level)

# P_NewChaseDir after the direct route: the two axis directions in the
# order the draw left them, then the direction the thing already walked.
def Sim.chase.after(c: Sim.Chase, +olddir: U32, +level: L.Level) -> S.Sim.Walk:
  Sim.chase.try(Sim.chase.axes(c, level), Bool.not(U32.is_eq(olddir, H.Thing.nodir())), olddir, level)

# P_NewChaseDir's search over all eight directions, from the east
# upward or from the south-east downward as a draw decides, the way it
# came left out. A direction already taken makes each turn a no-op,
# where vanilla returns.
def Sim.chase.scan(fuel: Nat, w: S.Sim.Walk, +dir: U32, +down: Bool, +back: U32, +level: L.Level) -> S.Sim.Walk:
  match fuel:
    case 0n:
      w
    case 1n+f:
      Sim.chase.scan(f, Sim.chase.try(w, Bool.not(U32.is_eq(dir, back)), dir, level),
        Bool.pick(U32, down, (dir - 1 : U32), (dir + 1 : U32)), down, back, level)

def Sim.chase.search(w: S.Sim.Walk, +back: U32, +level: L.Level) -> S.Sim.Walk:
  match w:
    case S.Walk{True{}, id, s}:
      S.Walk{True{}, id, s}
    case S.Walk{False{}, id, S.State{player, lv, things, sidetex, thinkers, +rnd, clock, ended, usedown, sounds, mrnd, reborn, secrets}}:
      +drawn = M.Random.next(rnd)
      Sim.chase.scan(8n, S.Walk{False{}, id,
          S.State{player, lv, things, sidetex, thinkers, drawn, clock, ended, usedown, sounds, mrnd, reborn, secrets}},
        Bool.pick(U32, U32.is_zero((M.Random.at(drawn) .&. 1 : U32)), 7, 0),
        U32.is_zero((M.Random.at(drawn) .&. 1 : U32)), back, level)

# The end of P_NewChaseDir: the way it came, and then nowhere at all.
def Sim.chase.stuck(w: S.Sim.Walk) -> S.Sim.Walk:
  match w:
    case S.Walk{True{}, id, s}:
      S.Walk{True{}, id, s}
    case S.Walk{False{}, +id, s}:
      S.Walk{False{}, id, S.Sim.thing.counted(id, H.Thing.hurt.movedir(), H.Thing.nodir(), s)}

def Sim.chase.last(w: S.Sim.Walk, +back: U32, +level: L.Level) -> S.Sim.Walk:
  Sim.chase.stuck(Sim.chase.try(Sim.chase.search(w, back, level),
    Bool.not(U32.is_eq(back, H.Thing.nodir())), back, level))

def Sim.chase.newdir.at(w: S.Sim.Walk, +deltax: U32, +deltay: U32, +olddir: U32, +level: L.Level) -> S.Sim.Walk:
  +d1 = Bool.pick(U32, F.Fixed.gt(deltax, 655360), 0,
    Bool.pick(U32, F.Fixed.lt(deltax, 4294311936), 4, H.Thing.nodir()))
  +d2 = Bool.pick(U32, F.Fixed.lt(deltay, 4294311936), 6,
    Bool.pick(U32, F.Fixed.gt(deltay, 655360), 2, H.Thing.nodir()))
  +back = Sim.chase.opposite(olddir)
  +diag = Sim.chase.diag(deltax, deltay)
  Sim.chase.last(Sim.chase.after(Sim.chase.order(
        Sim.chase.diagonal(Bool.and(Bool.not(U32.is_eq(d1, H.Thing.nodir())),
          Bool.not(U32.is_eq(d2, H.Thing.nodir()))), diag, U32.is_eq(diag, back), w, level),
      d1, d2, back, F.Fixed.gt(F.Fixed.abs(deltay), F.Fixed.abs(deltax))), olddir, level), back, level)

# Doom's P_NewChaseDir: the diagonal straight at the target first, then
# the two axis directions in the order a draw leaves them, then the
# direction already walked, then all eight in a drawn order, then the
# way it came, and nowhere if none of them works. Every attempt is a
# P_TryWalk, which moves the thing and draws its move count where it
# carries. The direction it starts from is read here and not before,
# since a P_Move that opened a door has cleared it.
def Sim.chase.newdir(w: S.Sim.Walk, +deltax: U32, +deltay: U32, +level: L.Level) -> S.Sim.Walk:
  S.Walk{ok, +id, +s} = w
  Sim.chase.newdir.at(S.Walk{ok, id, s}, deltax, deltay,
    S.Sim.thing.reads(S.State.things(s), id, H.Thing.hurt.movedir()), level)

# Doom's A_FaceTarget: the thing turns to face its target.
def Sim.chase.face.at(+level: L.Level, th: H.Thing, +tx: U32, +ty: U32) -> H.Thing:
  H.Thing{id, kind, +x, +y, z, floorz, ceilz, was, sector, state, tics, momz, +ai} = th
  H.Thing{id, kind, x, y, z, floorz, ceilz, A.Angle.of(L.Level.tanto(level), (tx - x : U32), (ty - y : U32)),
    sector, state, tics, momz,
    V.Vec.set(ai, H.Thing.hurt.flags(), (V.Vec.get(ai, H.Thing.hurt.flags()) .&. U32.not(32) : U32))}

def Sim.chase.faced(mt: Maybe<&2, S.Sim.Body>, mm: Maybe<&2, H.Thing>, +id: U32, +level: L.Level, s: S.State) ->
  S.State:
  match mt mm:
    case Some{S.Body{i, +tx, +ty, tz, r, h, f}} Some{th}:
      S.State.thing.put(id, Sim.chase.face.at(level, th, tx, ty), s)
    case _ _:
      s

def Sim.chase.face(+id: U32, +target: U32, +s: S.State) -> S.State:
  Sim.chase.faced(S.Sim.body(S.State.things(s), S.State.player(s), target), H.Things.get(S.State.things(s), id), id,
    S.State.level(s), s)

# A thing's facing set by A_Chase's turn, which leaves a thing with no
# direction facing where it was.
def Sim.chase.turned(th: H.Thing, +dir: U32) -> H.Thing:
  H.Thing{id, kind, x, y, z, floorz, ceilz, +angle, sector, state, tics, momz, ai} = th
  H.Thing{id, kind, x, y, z, floorz, ceilz,
    Bool.pick(U32, U32.is_ge(dir, H.Thing.nodir()), angle, Sim.chase.turn(angle, dir)), sector, state, tics,
    momz, ai}

# A_Chase's head: the reaction time counts down, the threshold counts
# down or is dropped outright where the target can no longer be shot,
# and the thing turns 45 degrees toward the direction it walks.
def Sim.chase.head(+th: H.Thing, +alive: Bool) -> H.Thing:
  Sim.chase.turned(H.Thing.counted(H.Thing.counted(th, H.Thing.hurt.reaction(),
      Sim.chase.counted(V.Vec.get(H.Thing.hurt(th), H.Thing.hurt.reaction()))), H.Thing.hurt.threshold(),
    Bool.pick(U32, alive, Sim.chase.counted(V.Vec.get(H.Thing.hurt(th), H.Thing.hurt.threshold())), 0)),
    V.Vec.get(H.Thing.hurt(th), H.Thing.hurt.movedir()))

# Whether a thing's target can still be shot, which A_Chase asks before
# it keeps it. P_KillMobj clears the player's MF_SHOOTABLE where this
# keeps the flag and reads the health instead.
def Sim.chase.alive(t: S.Sim.Body, +you: Bool, +live: Bool) -> Bool:
  S.Body{i, x, y, z, r, h, +flags} = t
  Bool.and(Bool.not(U32.is_zero((flags .&. 4 : U32))), Bool.or(Bool.not(you), live))

def Sim.chase.tick.at(th: H.Thing, +alive: Bool, +id: U32, s: S.State) -> S.State:
  S.State.thing.put(id, Sim.chase.head(th, alive), s)

def Sim.chase.tick.some(m: Maybe<&2, H.Thing>, +alive: Bool, +id: U32, s: S.State) -> S.State:
  match m:
    case None{}:
      s
    case Some{th}:
      Sim.chase.tick.at(th, alive, id, s)

def Sim.chase.tick.body(mt: Maybe<&2, S.Sim.Body>, +you: Bool, +live: Bool) -> Bool:
  match mt:
    case None{}:
      False{}
    case Some{+t}:
      Sim.chase.alive(t, you, live)

def Sim.chase.tick(+id: U32, +s: S.State) -> S.State:
  +target = S.Sim.thing.reads(S.State.things(s), id, H.Thing.hurt.target())
  +you = H.Things.you(S.State.things(s))
  Sim.chase.tick.some(H.Things.get(S.State.things(s), id),
    Sim.chase.tick.body(S.Sim.body(S.State.things(s), S.State.player(s), target), U32.is_eq(target, you),
      Bool.not(S.Player.dead(S.State.player(s)))), id, s)

# A_Chase's target test: a thing whose target is gone or can no longer
# be shot looks all around for the player, takes it where it finds one,
# and goes back to its spawn state where it does not.
def Sim.chase.relook(found: Bool, +kind: U32, +id: U32, +s: S.State) -> S.Sim.Acted:
  match found:
    case True{}:
      +you = H.Things.you(S.State.things(s))
      S.Acted{None{}, S.Sim.thing.counted(id, H.Thing.hurt.target(), you, s)}
    case False{}:
      S.Acted{Some{H.Thing.Def.state(H.Thing.info(kind))}, s}

def Sim.chase.lost(m: Maybe<&2, H.Thing>, +id: U32, +s: S.State) -> S.Sim.Acted:
  match m:
    case None{}:
      S.Acted{None{}, s}
    case Some{+th}:
      Sim.chase.relook(S.Sim.look.sees(H.Thing.blind(th), True{}, S.State.level(s), S.State.player(s),
        S.Sim.body.of(th), H.Thing.angle(th)), H.Thing.kind(th), id, s)

def Sim.chase.gone(+id: U32, +s: S.State) -> S.Sim.Acted:
  Sim.chase.lost(H.Things.get(S.State.things(s), id), id, s)

# Doom's P_CheckMissileRange's own draw: the whole units between the two
# have to beat it, so a thing close enough for the count to go negative
# always fires.
def Sim.chase.range.draw(+dist: U32, w: S.Sim.Walk) -> S.Sim.Walk:
  match w:
    case S.Walk{ok, id, S.State{player, level, things, sidetex, thinkers, +rnd, clock, ended, usedown, sounds, mrnd, reborn, secrets}}:
      +drawn = M.Random.next(rnd)
      S.Walk{F.Fixed.ge(M.Random.at(drawn), dist), id,
        S.State{player, level, things, sidetex, thinkers, drawn, clock, ended, usedown, sounds, mrnd, reborn, secrets}}

# P_CheckMissileRange's distance: the whole units between the two, 64
# off for the range and 128 more where the type has no melee attack, and
# never more than 200.
def Sim.chase.range.dist(+deltax: U32, +deltay: U32, +melee: U32) -> U32:
  +units = F.Fixed.sarn((F.Fixed.approx(deltax, deltay) - 4194304 -
    Bool.pick(U32, U32.is_zero(melee), 8388608, 0) : U32), 16n)
  Bool.pick(U32, F.Fixed.gt(units, 200), 200, units)

def Sim.chase.range.held(ready: Bool, +dist: U32, +id: U32, s: S.State) -> S.Sim.Walk:
  match ready:
    case False{}:
      S.Walk{False{}, id, s}
    case True{}:
      Sim.chase.range.draw(dist, S.Walk{False{}, id, s})

# Doom's P_CheckMissileRange: the target has to be in sight; a thing
# just hit fires back at once and forgets the blow; one still inside its
# reaction time holds its fire; and otherwise the distance has to beat a
# draw.
def Sim.chase.range(sighted: Bool, justhit: Bool, +reaction: U32, +dist: U32, +id: U32, s: S.State) -> S.Sim.Walk:
  match sighted justhit:
    case False{} _:
      S.Walk{False{}, id, s}
    case True{} True{}:
      S.Walk{True{}, id, S.Sim.thing.cleared(id, 64, s)}
    case True{} False{}:
      Sim.chase.range.held(U32.is_zero(reaction), dist, id, s)

# A_Chase's move: the count of tics on this direction runs out, or the
# move is blocked, and the thing picks a new direction.
def Sim.chase.redir(w: S.Sim.Walk, +deltax: U32, +deltay: U32, +level: L.Level) -> S.Sim.Walk:
  match w:
    case S.Walk{True{}, id, s}:
      S.Walk{True{}, id, s}
    case S.Walk{False{}, id, s}:
      Sim.chase.newdir(S.Walk{False{}, id, s}, deltax, deltay, level)

def Sim.chase.stepped(spent: Bool, +deltax: U32, +deltay: U32, +level: L.Level, w: S.Sim.Walk) -> S.Sim.Walk:
  match spent:
    case True{}:
      Sim.chase.newdir(w, deltax, deltay, level)
    case False{}:
      Sim.chase.redir(Sim.chase.move(w, level), deltax, deltay, level)

# A_Chase's idle call: a draw made every tic whether or not anything
# under 3 comes of it.
def Sim.chase.sounded(+kind: U32, w: S.Sim.Walk) -> S.Sim.Acted:
  match w:
    case S.Walk{ok, +id, S.State{player, level, things, sidetex, thinkers, +rnd, clock, ended, usedown, sounds, mrnd, reborn, secrets}}:
      +drawn = M.Random.next(rnd)
      S.Acted{None{}, S.Sim.sound(Bool.pick(U32, U32.is_lt(M.Random.at(drawn), 3), H.Thing.activesound(kind), 0),
        Sn.Thing{id},
        S.State{player, level, things, sidetex, thinkers, drawn, clock, ended, usedown, sounds, mrnd, reborn, secrets})}

def Sim.chase.walks(+kind: U32, +id: U32, +deltax: U32, +deltay: U32, +movecount: U32, +level: L.Level,
  s: S.State) -> S.Sim.Acted:
  Sim.chase.sounded(kind, Sim.chase.stepped(F.Fixed.is_neg((movecount - 1 : U32)), deltax, deltay, level,
    S.Walk{False{}, id, S.Sim.thing.counted(id, H.Thing.hurt.movecount(), (movecount - 1 : U32), s)}))

# A_Chase after the range check: it passed, and the thing enters its
# missile state marked as having just attacked; it failed, and the thing
# walks on.
def Sim.chase.ranged(w: S.Sim.Walk, +missile: U32, +kind: U32, +movecount: U32, +deltax: U32, +deltay: U32,
  +level: L.Level) -> S.Sim.Acted:
  match w:
    case S.Walk{True{}, +id, +s}:
      S.Acted{Some{missile}, S.Sim.thing.flagged(id, 128, s)}
    case S.Walk{False{}, id, s}:
      Sim.chase.walks(kind, id, deltax, deltay, movecount, level, s)

# A_Chase's missile branch: a type with no missile state, or one still
# walking out its move count, never fires, as vanilla's skill test
# leaves it below nightmare.
def Sim.chase.fire(may: Bool, m: S.Sim.Body, t: S.Sim.Body, +kind: U32, +movecount: U32, +reaction: U32,
  +deltax: U32, +deltay: U32, +id: U32, +s: S.State) -> S.Sim.Acted:
  match may:
    case False{}:
      +level = S.State.level(s)
      Sim.chase.walks(kind, id, deltax, deltay, movecount, level, s)
    case True{}:
      +level = S.State.level(s)
      Sim.chase.ranged(Sim.chase.range(S.Sim.sight(level, m, t),
          Bool.not(U32.is_zero((S.Sim.thing.reads(S.State.things(s), id, H.Thing.hurt.flags()) .&. 64 : U32))),
          reaction, Sim.chase.range.dist(deltax, deltay, H.Thing.melee(kind)), id, s),
        H.Thing.missile(kind), kind, movecount, deltax, deltay, level)

# Doom's P_CheckMeleeRange: nearer than MELEERANGE minus 20 map units
# plus the target's radius, with an unobstructed sight line.
def Sim.chase.melee(+level: L.Level, m: S.Sim.Body, t: S.Sim.Body) -> Bool:
  S.Body{mi, +mx, +my, mz, mr, mh, mf} = m
  S.Body{ti, +tx, +ty, tz, +tr, th, tf} = t
  Bool.and(F.Fixed.lt(F.Fixed.approx((tx - mx : U32), (ty - my : U32)), (2883584 + tr : U32)),
    S.Sim.sight(level, S.Body{mi, mx, my, mz, mr, mh, mf}, S.Body{ti, tx, ty, tz, tr, th, tf}))

def Sim.chase.close(near: Bool, m: S.Sim.Body, t: S.Sim.Body, +kind: U32, +movecount: U32, +reaction: U32,
  +deltax: U32, +deltay: U32, +id: U32, +s: S.State) -> S.Sim.Acted:
  match near:
    case True{}:
      S.Acted{Some{H.Thing.melee(kind)}, S.Sim.sound(H.Thing.attacksound(kind), Sn.Thing{id}, s)}
    case False{}:
      Sim.chase.fire(Bool.and(Bool.not(U32.is_zero(H.Thing.missile(kind))), U32.is_zero(movecount)), m, t,
        kind, movecount, reaction, deltax, deltay, id, s)

# A_Chase's MF_JUSTATTACKED: a thing that attacked last tic does not
# attack again, and picks a new direction instead.
def Sim.chase.hit(attacked: Bool, +m: S.Sim.Body, +t: S.Sim.Body, +kind: U32, +movecount: U32, +reaction: U32,
  +deltax: U32, +deltay: U32, +id: U32, +s: S.State) -> S.Sim.Acted:
  match attacked:
    case True{}:
      +level = S.State.level(s)
      S.Acted{None{}, S.Sim.Walk.left(Sim.chase.newdir(S.Walk{False{}, id, S.Sim.thing.cleared(id, 128, s)}, deltax,
        deltay, level))}
    case False{}:
      +level = S.State.level(s)
      Sim.chase.close(Bool.and(Bool.not(U32.is_zero(H.Thing.melee(kind))), Sim.chase.melee(level, m, t)), m, t,
        kind, movecount, reaction, deltax, deltay, id, s)

def Sim.chase.kept(m: Maybe<&2, H.Thing>, +t: S.Sim.Body, +id: U32, +s: S.State) -> S.Sim.Acted:
  match m:
    case None{}:
      S.Acted{None{}, s}
    case Some{+th}:
      Sim.chase.hit(Bool.not(U32.is_zero((V.Vec.get(H.Thing.hurt(th), H.Thing.hurt.flags()) .&. 128 : U32))),
        S.Sim.body.of(th), t, H.Thing.kind(th), V.Vec.get(H.Thing.hurt(th), H.Thing.hurt.movecount()),
        V.Vec.get(H.Thing.hurt(th), H.Thing.hurt.reaction()), (S.Sim.Body.x(t) - H.Thing.x(th) : U32),
        (S.Sim.Body.y(t) - H.Thing.y(th) : U32), id, s)

def Sim.chase.armed(shootable: Bool, t: S.Sim.Body, +id: U32, +s: S.State) -> S.Sim.Acted:
  match shootable:
    case False{}:
      Sim.chase.gone(id, s)
    case True{}:
      Sim.chase.kept(H.Things.get(S.State.things(s), id), t, id, s)

def Sim.chase.aimed(mt: Maybe<&2, S.Sim.Body>, +you: Bool, +live: Bool, +id: U32, +s: S.State) -> S.Sim.Acted:
  match mt:
    case None{}:
      Sim.chase.gone(id, s)
    case Some{+t}:
      Sim.chase.armed(Sim.chase.alive(t, you, live), t, id, s)

def Sim.chase.on(+id: U32, +s: S.State) -> S.Sim.Acted:
  +target = S.Sim.thing.reads(S.State.things(s), id, H.Thing.hurt.target())
  +you = H.Things.you(S.State.things(s))
  Sim.chase.aimed(S.Sim.body(S.State.things(s), S.State.player(s), target), U32.is_eq(target, you),
    Bool.not(S.Player.dead(S.State.player(s))), id, s)

# Doom's A_Chase, the thinker of every woken monster: its reaction time
# and its threshold count down and it turns 45 degrees toward the
# direction it walks; then it gives up a target that can no longer be
# shot, holds its fire for a tic after an attack, fires where its type
# and its range let it, and otherwise walks, picking a new direction when
# its count runs out or its move is blocked, and calling out on a draw
# under 3. The netgame branch that looks for a nearer player is left
# out with the other players. The melee branch sits between the
# just-attacked test and the missile one.
def Sim.chase(+id: U32, +s: S.State) -> S.Sim.Acted:
  Sim.chase.on(id, Sim.chase.tick(id, s))

def Sim.damage.enter.chased(a: S.Sim.Acted, +target: U32) -> S.State:
  match a:
    case S.Acted{None{}, s}:
      s
    case S.Acted{Some{+state}, +s}:
      +entered = S.Sim.damage.entered(target, S.State.thing(target, s), state, s)
      Sim.chase.face(target, S.Sim.thing.reads(S.State.things(entered), target, H.Thing.hurt.target()), entered)

def Sim.damage.enter.acted(+target: U32, th: H.Thing, +state: U32, s: S.State) -> S.State:
  Sim.damage.enter.chased(Sim.chase(target, S.Sim.damage.enter(target, th, state, s)), target)

def Sim.damage(+target: U32, damage: U32, inflictor: U32, source: U32, +s: S.State) -> S.State:
  S.Sim.damage.with(~Sim.damage.enter.acted, target, damage, inflictor, source, s)

def Sim.explode.acted(m: Maybe<&2, H.Thing>, +s: S.State) -> S.State:
  match m:
    case None{}:
      s
    case Some{+th}:
      S.Sim.blast.with(~Sim.damage.enter.acted, S.Sim.body.of(th), H.Thing.target(th), 128, s)

# One bullet of a former human's attack: the spread of a P_SubRandom
# turn, the damage of a draw, 3 to 15, and P_LineAttack, which is the
# player's own.
def Sim.bullet.at(+x: U32, +y: U32, +shootz: U32, +id: U32, +angle: U32, +slope: U32, +damage: U32,
  +s: S.State) -> S.State:
  S.Sim.attack.with(~Sim.damage.enter.acted, S.State.level(s), S.State.things(s), S.State.player(s), x, y, shootz, id, angle, S.Sim.missilerange(),
    slope, damage, s)

def Sim.bullet(+x: U32, +y: U32, +shootz: U32, +id: U32, +bangle: U32, +slope: U32, s: S.State) -> S.State:
  S.State{player, level, things, sidetex, thinkers, +rnd, clock, ended, usedown, sounds, mrnd, reborn, secrets} = s
  +a = M.Random.next(rnd)
  +b = M.Random.next(a)
  +c = M.Random.next(b)
  Sim.bullet.at(x, y, shootz, id, (bangle + ((M.Random.at(a) - M.Random.at(b) : U32) << 20n) : U32), slope,
    (3 * ((M.Random.at(c) % 5 : U32) + 1 : U32) : U32),
    S.State{player, level, things, sidetex, thinkers, c, clock, ended, usedown, sounds, mrnd, reborn, secrets})

def Sim.posattack.body(m: S.Sim.Body, +id: U32, +angle: U32, +s: S.State) -> S.State:
  S.Body{i, +x, +y, +z, radius, +height, flags} = m
  +shootz = S.Sim.shootz(z, height)
  +slope = S.Sim.Aim.slope(S.Sim.aim(S.State.level(s), S.State.things(s), S.State.player(s), x, y, shootz, id, angle,
    S.Sim.missilerange()))
  Sim.bullet(x, y, shootz, id, angle, slope, S.Sim.sound(Sn.Sound.pistol(), Sn.Thing{id}, s))

def Sim.posattack.of(m: Maybe<&2, H.Thing>, +id: U32, +s: S.State) -> S.State:
  match m:
    case None{}:
      s
    case Some{+th}:
      Sim.posattack.body(S.Sim.body.of(th), id, H.Thing.angle(th), s)

def Sim.posattack.target(mt: Maybe<&2, S.Sim.Body>, +id: U32, +target: U32, +s: S.State) -> S.State:
  match mt:
    case None{}:
      s
    case Some{t}:
      +faced = Sim.chase.face(id, target, s)
      Sim.posattack.of(H.Things.get(S.State.things(faced), id), id, faced)

# Doom's A_PosAttack: the zombieman turns to its target, aims where it
# then looks, calls its shot and fires one bullet.
def Sim.posattack(+id: U32, +s: S.State) -> S.State:
  +target = S.Sim.thing.reads(S.State.things(s), id, H.Thing.hurt.target())
  Sim.posattack.target(S.Sim.body(S.State.things(s), S.State.player(s), target), id, target, s)

def Sim.sposattack.go(n: Nat, +x: U32, +y: U32, +shootz: U32, +id: U32, +bangle: U32, +slope: U32, s: S.State) ->
  S.State:
  match n:
    case 0n:
      s
    case 1n+k:
      Sim.sposattack.go(k, x, y, shootz, id, bangle, slope, Sim.bullet(x, y, shootz, id, bangle, slope, s))

def Sim.sposattack.body(m: S.Sim.Body, +id: U32, +angle: U32, +s: S.State) -> S.State:
  S.Body{i, +x, +y, +z, radius, +height, flags} = m
  +shootz = S.Sim.shootz(z, height)
  Sim.sposattack.go(3n, x, y, shootz, id, angle,
    S.Sim.Aim.slope(S.Sim.aim(S.State.level(s), S.State.things(s), S.State.player(s), x, y, shootz, id, angle,
      S.Sim.missilerange())), s)

def Sim.sposattack.of(m: Maybe<&2, H.Thing>, +id: U32, +s: S.State) -> S.State:
  match m:
    case None{}:
      s
    case Some{+th}:
      Sim.sposattack.body(S.Sim.body.of(th), id, H.Thing.angle(th), s)

def Sim.sposattack.target(mt: Maybe<&2, S.Sim.Body>, +id: U32, +target: U32, +s: S.State) -> S.State:
  match mt:
    case None{}:
      s
    case Some{t}:
      +faced = Sim.chase.face(id, target, S.Sim.sound(Sn.Sound.shotgn(), Sn.Thing{id}, s))
      Sim.sposattack.of(H.Things.get(S.State.things(faced), id), id, faced)

# Doom's A_SPosAttack: the shotgun guy calls its shot before it turns,
# aims once, and fires three bullets, each with its own spread and its
# own damage.
def Sim.sposattack(+id: U32, +s: S.State) -> S.State:
  +target = S.Sim.thing.reads(S.State.things(s), id, H.Thing.hurt.target())
  Sim.sposattack.target(S.Sim.body(S.State.things(s), S.State.player(s), target), id, target, s)

def Sim.melee.damage(+target: U32, +factor: U32, +id: U32, s: S.State) -> S.State:
  +after = S.Sim.drawn(s)
  Sim.damage(target, (((M.Random.at(S.State.rnd(after)) % Bool.pick(U32, U32.is_eq(factor, 3), 8, 10) : U32) + 1 : U32)
    * factor : U32), id, id, after)

def Sim.missile.ready(th: H.Thing, +cut: U32) -> H.Thing:
  H.Thing{tid, kind, x, y, +z, floorz, ceilz, angle, sector, state, +tics, +momz, hurt} = th
  H.Thing{tid, kind, x, y, (z + F.Fixed.sar(momz) : U32), floorz, ceilz, angle, sector, state,
    F.Fixed.max((tics - cut : U32), 1), momz, hurt}

def Sim.missile.first.ready(+ready: H.Thing, +id: U32, +s: S.State) -> S.State:
  H.Thing{tid, kind, +x, +y, z, floorz, ceilz, angle, sector, state, tics, momz, +hurt} = ready
  S.Sim.thing.fit.with(~Sim.damage.enter.acted, id, H.Thing{tid, kind, x, y, z, floorz, ceilz, angle, sector, state, tics, momz, hurt},
    (x + F.Fixed.sar(V.Vec.get(hurt, H.Thing.hurt.momx())) : U32),
    (y + F.Fixed.sar(V.Vec.get(hurt, H.Thing.hurt.momy())) : U32), s)

def Sim.missile.first(m: Maybe<&2, H.Thing>, +id: U32, +s: S.State) -> S.State:
  match m:
    case None{}:
      s
    case Some{th}:
      +after = S.Sim.drawn(s)
      +ready = Sim.missile.ready(th, (M.Random.at(S.State.rnd(after)) .&. 3 : U32))
      Sim.missile.first.ready(ready, id, S.State.thing.put(id, ready, after))

def Sim.troopattack.throw(+target: U32, +id: U32, +s: S.State) -> S.State:
  +missile = H.Things.count(S.State.things(s))
  +spawned = S.Sim.missile.spawn(Maybe.default(&2, S.Sim.Body, S.Sim.body(S.State.things(s), S.State.player(s), id),
      S.Player.body(S.State.player(s), H.Things.you(S.State.things(s)))),
    Maybe.default(&2, S.Sim.Body, S.Sim.body(S.State.things(s), S.State.player(s), target),
      S.Player.body(S.State.player(s), H.Things.you(S.State.things(s)))), id, s)
  Sim.missile.first(H.Things.get(S.State.things(spawned), missile), missile, spawned)

def Sim.troopattack.hit(near: Bool, +target: U32, +id: U32, +s: S.State) -> S.State:
  match near:
    case True{}:
      Sim.melee.damage(target, 3, id, S.Sim.sound(Sn.Sound.claw(), Sn.Thing{id}, s))
    case False{}:
      Sim.troopattack.throw(target, id, s)

def Sim.troopattack.target(mt: Maybe<&2, S.Sim.Body>, +id: U32, +target: U32, +s: S.State) -> S.State:
  match mt:
    case None{}:
      s
    case Some{+t}:
      +faced = Sim.chase.face(id, target, s)
      Sim.troopattack.hit(Sim.chase.melee(S.State.level(faced),
        Maybe.default(&2, S.Sim.Body, S.Sim.body(S.State.things(faced), S.State.player(faced), id), t), t), target, id, faced)

def Sim.troopattack(+id: U32, +s: S.State) -> S.State:
  +target = S.Sim.thing.reads(S.State.things(s), id, H.Thing.hurt.target())
  Sim.troopattack.target(S.Sim.body(S.State.things(s), S.State.player(s), target), id, target, s)

def Sim.sargattack.hit(near: Bool, +target: U32, +id: U32, +s: S.State) -> S.State:
  match near:
    case True{}:
      Sim.melee.damage(target, 4, id, s)
    case False{}:
      s

def Sim.sargattack.target(mt: Maybe<&2, S.Sim.Body>, +id: U32, +target: U32, +s: S.State) -> S.State:
  match mt:
    case None{}:
      s
    case Some{+t}:
      +faced = Sim.chase.face(id, target, s)
      +m = Maybe.default(&2, S.Sim.Body, S.Sim.body(S.State.things(faced), S.State.player(faced), id), t)
      Sim.sargattack.hit(Sim.chase.melee(S.State.level(faced), m, t), target, id, faced)

def Sim.sargattack(+id: U32, +s: S.State) -> S.State:
  +target = S.Sim.thing.reads(S.State.things(s), id, H.Thing.hurt.target())
  Sim.sargattack.target(S.Sim.body(S.State.things(s), S.State.player(s), target), id, target, s)

# The dispatch over a mobj's action pointers. The two weapon actions are
# the player sprites' and no state row a mobj holds carries them.
def Sim.thing.act(action: H.Thing.Action, +id: U32, +s: S.State) -> S.Sim.Acted:
  match action:
    case H.Look{}:
      S.Sim.look(id, s)
    case H.Chase{}:
      Sim.chase(id, s)
    case H.Face{}:
      +target = S.Sim.thing.target(S.State.things(s), id)
      S.Acted{None{}, Sim.chase.face(id, target, s)}
    case H.PosAttack{}:
      S.Acted{None{}, Sim.posattack(id, s)}
    case H.SPosAttack{}:
      S.Acted{None{}, Sim.sposattack(id, s)}
    case H.TroopAttack{}:
      S.Acted{None{}, Sim.troopattack(id, s)}
    case H.SargAttack{}:
      S.Acted{None{}, Sim.sargattack(id, s)}
    case H.Explode{}:
      S.Acted{None{}, Sim.explode.acted(S.State.thing(id, s), s)}
    case other:
      S.Acted{None{}, S.Sim.thing.acts(other, S.State.thing(id, s), id, s)}

def Sim.thing.entered(m: Maybe<&2, H.Thing>, +id: U32, +state: U32, s: S.State) -> S.State:
  match m:
    case None{}:
      s
    case Some{th}:
      S.State.thing.put(id, H.Thing.entering(th, state), s)

# Doom's P_SetMobjState: the thing enters the state for its tics and the
# state's action runs, which may set another state. A_Look's chase state
# is the longest chain vanilla's monsters have, and no row of the table
# lasts no tics, so the loop never turns more than twice.
def Sim.thing.set(fuel: Nat, a: S.Sim.Acted, +id: U32) -> S.State:
  match fuel a:
    case 1n+f S.Acted{Some{+state}, +s}:
      Sim.thing.set(f, Sim.thing.act(H.Thing.Row.action(H.Thing.row(state)), id,
        Sim.thing.entered(H.Things.get(S.State.things(s), id), id, state, s)), id)
    case _ S.Acted{state, s}:
      s

# The state half of Doom's P_MobjThinker for a thing: a lasting state
# stays as it is; another counts its tics down, and the tic they run out
# the thing enters the next state, whose action runs.
def Sim.thing.step(lasting: Bool, out: Bool, th: H.Thing, +id: U32, s: S.State) -> S.State:
  match lasting out:
    case True{} _:
      s
    case False{} True{}:
      Sim.thing.set(3n, S.Acted{Some{H.Thing.Row.next(H.Thing.row(H.Thing.state(th)))}, s}, id)
    case False{} False{}:
      S.State.thing.put(id, H.Thing.spent(th), s)

# The thing as its vertical move left it, written back, and then its
# state half against the state that holds it.
def Sim.thing.moved(+th: H.Thing, +id: U32, s: S.State) -> S.State:
  Sim.thing.step(H.Thing.lasting(th), H.Thing.over(th), th, id, S.State.thing.put(id, th, s))

def Sim.missile.z.hit(sky: Bool, +id: U32, +s: S.State) -> S.State:
  match sky:
    case True{}:
      S.Sim.remove(id, s)
    case False{}:
      S.Sim.missile.burst(id, s)

def Sim.missile.z.move(hit: Bool, sky: Bool, +th: H.Thing, +id: U32, +s: S.State) -> S.State:
  match hit:
    case True{}:
      Sim.missile.z.hit(sky, id, s)
    case False{}:
      Sim.thing.moved(H.Thing.zmove(th), id, s)

def Sim.missile.z(+th: H.Thing, +id: U32, +s: S.State) -> S.State:
  H.Thing{tid, kind, x, y, +z, +floorz, +ceilz, angle, +sector, state, tics, +momz, +hurt} = th
  +height = V.Vec.get(hurt, H.Thing.hurt.height())
  +next = (z + momz : U32)
  +floor = F.Fixed.le(next, floorz)
  +ceiling = F.Fixed.gt((next + height : U32), ceilz)
  Sim.missile.z.move(Bool.or(floor, ceiling), Bool.and(ceiling, L.Level.sky(S.State.level(s), sector)),
    H.Thing{tid, kind, x, y, z, floorz, ceilz, angle, sector, state, tics, momz, hurt}, id, s)

def Sim.thing.vertical(missile: Bool, +th: H.Thing, +id: U32, +s: S.State) -> S.State:
  match missile:
    case True{}:
      Sim.missile.z(th, id, s)
    case False{}:
      Sim.thing.moved(H.Thing.zmove(th), id, s)

def Sim.thing.vertical.if(moves: Bool, +th: H.Thing, +id: U32, +s: S.State) -> S.State:
  match moves:
    case True{}:
      Sim.thing.vertical(H.Thing.flagged(th, 65536), th, id, s)
    case False{}:
      Sim.thing.moved(th, id, s)

# The thing after its tic: one that entered S_NULL removed itself, as
# P_SetMobjState does, and its thinker ends at its next turn.
def Sim.thing.left(gone: Bool, +id: U32, s: S.State) -> S.State:
  match gone:
    case True{}:
      S.State.kept(S.Sim.remove(id, s), S.Mobj{id})
    case False{}:
      S.State.kept(s, S.Mobj{id})

def Sim.thing.ended(m: Maybe<&2, H.Thing>, +id: U32, s: S.State) -> S.State:
  match m:
    case None{}:
      S.State.kept(s, S.Mobj{id})
    case Some{th}:
      Sim.thing.left(H.Thing.gone(th), id, s)

def Sim.thing.after(+id: U32, +s: S.State) -> S.State:
  Sim.thing.ended(H.Things.get(S.State.things(s), id), id, s)

def Sim.thing.stepped(m: Maybe<&2, H.Thing>, +id: U32, s: S.State) -> S.State:
  match m:
    case None{}:
      Sim.thing.after(id, s)
    case Some{+th}:
      Sim.thing.after(id, Sim.thing.vertical.if(Bool.or(Bool.not(U32.is_eq(H.Thing.z(th), H.Thing.floorz(th))),
        Bool.not(U32.is_zero(H.Thing.momz(th)))), th, id, s))

# Doom's P_MobjThinker for a thing: the horizontal move a blow gave it,
# then the vertical, then its tic through its states, whose actions run
# as the states are entered. One already removed has no thing, and its
# thinker ends here, as Doom's does when the run reaches it.
def Sim.thing.tic(m: Maybe<&2, H.Thing>, +id: U32, +s: S.State) -> S.State:
  match m:
    case None{}:
      s
    case Some{+th}:
      +after = S.Sim.thing.xy.with(~Sim.damage.enter.acted, id, th, s)
      Sim.thing.stepped(S.State.thing(id, after), id, after)

def Sim.thing(+id: U32, +s: S.State) -> S.State:
  Sim.thing.tic(H.Things.get(S.State.things(s), id), id, s)

# A thinker's tic. A wait counts down, and the tic it reaches zero
# sounds the mover's wake and does nothing else, as Doom's doors and
# lifts turn. A blink turns on the tic its count runs out.
def Sim.think(t: S.Thinker, s: S.State) -> S.State:
  match t:
    case S.Mobj{id}:
      Sim.thing(id, s)
    case S.Mover{sector, ceiling, speed, [], plan, noise}:
      s
    case S.Mover{+sector, ceiling, speed, S.Hold{+tics} <> +rest, plan, +noise}:
      Sp.Sim.mover.kept(sector, ceiling, speed, Bool.pick(List<&2, S.Sim.Step>, U32.is_eq(tics, 1), rest,
        S.Hold{(tics - 1 : U32)} <> rest), plan, noise,
        S.Sim.sound(Bool.pick(U32, U32.is_eq(tics, 1), Sp.Sim.Noise.wake(noise), 0), Sn.Sector{sector}, s))
    case S.Mover{sector, ceiling, speed, S.Travel{down, dest} <> rest, plan, noise}:
      Sp.Sim.mover.move(sector, ceiling, speed, down, dest, rest, plan, noise, s)
    case S.Button{side, slot, texture, +tics}:
      Sp.Sim.button(U32.is_eq(tics, 1), side, slot, texture, tics, s)
    case S.Blink{sector, +count, dark, bright, darktime, brighttime, random}:
      Sp.Sim.blink(U32.is_eq(count, 1), sector, (count - 1 : U32), dark, bright, darktime, brighttime, random, s)
    case S.Glow{sector, dark, bright, down}:
      Sp.Sim.glow(sector, dark, bright, down, s)

# The tic
# -------

# Use acts on the tic it goes down, not while it is held.
def Sim.pressed(cmd: K.Cmd, usedown: Bool) -> Bool:
  Bool.and(Bool.not(usedown), K.Cmd.use(cmd))

# The player back at the place it stood before a thinker's turn, as the
# turn left it otherwise, the lines it crossed fired and forgotten.
def Player.held(+x: U32, +y: U32, after: S.Player) -> S.Player:
  S.Player{ax, ay, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt} = after
  S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, [], inv, psprites, hurt}

# What a turn keeps of the state it began with, whatever it did: the
# geometry, so no tic writes a wall, and the player's place, so nothing
# but the player's own movement moves the player sideways. Those two
# pieces come in on their own: a hold that took the whole state before
# would hold two states at once, and the budget of docs/bend.md's width
# cap has no room for that.
def State.held(geo: L.Level.Geo, +x: U32, +y: U32, after: S.State) -> S.State:
  S.State{player, L.Level{g, sectors, specials, heard}, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn, secrets} = after
  S.State{Player.held(x, y, player), L.Level{geo, sectors, specials, heard}, things, sidetex, thinkers, rnd, clock, ended,
    usedown, sounds, mrnd, reborn, secrets}

# P_PlayerThink's counters, the damage count's fade among them.
def Sim.counters(p: S.Player) -> S.Player:
  S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt} = p
  S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed,
    I.Inventory.tic(inv), psprites, S.Sim.Hurt.fade(hurt)}

# The player's own landing, heard from the player.
def Sim.mobj.landed(hard: Bool, things: H.Things) -> H.Things:
  match hard:
    case False{}:
      things
    case True{}:
      H.Things.sounded(things, Sn.Sound.plain(Sn.Sound.oof(), Sn.Thing{H.Thing.you()}))

def Sim.mobj.z(t: S.Sim.Try) -> S.Sim.Try:
  S.Try{ok, +p, things} = t
  S.Try{ok, S.Sim.z(p), Sim.mobj.landed(S.Sim.lands(p), things)}

# Doom's P_MobjThinker for the player: the XY movement, with the pickups
# its position checks make, then the vertical, against the level the tic
# began with, whose geometry the wall law reads; the lines that movement
# crossed fire, the mobj goes through its own states, which time its
# pain and its death, and the thinker is kept. Each let ends a state:
# the thinker's id is read before the move, so the state the tic began
# with is gone once it has moved, and the place before the states run,
# so the state the move left is gone once they have.
def Sim.mobj(+cmd: K.Cmd, +geo: L.Level.Geo, +s: S.State) -> S.State:
  +level = {L.Level{geo, L.Level.sectors(S.State.level(s)), L.Level.specials(S.State.level(s)), L.Level.alerted(S.State.level(s))} : L.Level}
  +you = H.Things.you(S.State.things(s))
  +went = S.State.moved(Sim.mobj.z(S.Sim.xy(level, S.State.things(s), cmd, S.State.player(s))), level, s)
  +x = S.Player.x(S.State.player(went))
  +y = S.Player.y(S.State.player(went))
  S.State.kept(State.held(geo, x, y, S.Sim.mobj.tics(Sp.Sim.cross(S.Player.crossed(S.State.player(went)), went))),
    S.Mobj{you})

# Whether a thinker is the player's mobj's.
def Sim.mine(t: S.Thinker, you: U32) -> Bool:
  match t:
    case S.Mobj{id}:
      U32.is_eq(id, you)
    case _:
      False{}

# A thinker's turn: the player's mobj moves the player; any other
# thinks, and the state is held where it was.
def Sim.turn(mine: Bool, t: S.Thinker, cmd: K.Cmd, +geo: L.Level.Geo, +s: S.State) -> S.State:
  match mine:
    case True{}:
      Sim.mobj(cmd, geo, s)
    case False{}:
      +x = S.Player.x(S.State.player(s))
      +y = S.Player.y(S.State.player(s))
      State.held(geo, x, y, Sim.think(t, s))

# One run down the thinkers due, its fuel the list of them as it began:
# each in turn, in the order they were started. Those started meanwhile
# are still due when it ends.
def Sim.thinkers.go(fuel: List<&2, S.Thinker>, +cmd: K.Cmd, +geo: L.Level.Geo, s: S.State) -> S.State:
  match fuel s:
    case [] s:
      s
    case f <> rest S.State{player, level, things, sidetex, S.Thinkers{ran, []}, rnd, clock, ended, usedown, sounds, mrnd, reborn, secrets}:
      S.State{player, level, things, sidetex, S.Thinkers{ran, []}, rnd, clock, ended, usedown, sounds, mrnd, reborn, secrets}
    case f <> rest S.State{player, level, +things, sidetex, S.Thinkers{ran, +t <> due}, rnd, clock, ended, usedown, sounds, mrnd, reborn, secrets}:
      Sim.thinkers.go(rest, cmd, geo, Sim.turn(Sim.mine(t, H.Things.you(things)), t, cmd, geo,
        S.State{player, level, things, sidetex, S.Thinkers{ran, due}, rnd, clock, ended, usedown, sounds, mrnd, reborn, secrets}))

# Runs until none is due: the thinkers a run started run in the next, the
# same tic, as those added to the tail of Doom's list do. The fuel is
# how deep that may go; past it they wait a tic.
def Sim.thinkers.all(fuel: Nat, +cmd: K.Cmd, +geo: L.Level.Geo, s: S.State) -> S.State:
  match fuel s:
    case 0n s:
      s
    case 1n+f S.State{player, level, things, sidetex, S.Thinkers{ran, []}, rnd, clock, ended, usedown, sounds, mrnd, reborn, secrets}:
      S.State{player, level, things, sidetex, S.Thinkers{ran, []}, rnd, clock, ended, usedown, sounds, mrnd, reborn, secrets}
    case 1n+f S.State{player, level, things, sidetex, S.Thinkers{ran, +t <> +due}, rnd, clock, ended, usedown, sounds, mrnd, reborn, secrets}:
      Sim.thinkers.all(f, cmd, geo, Sim.thinkers.go(t <> due, cmd, geo,
        S.State{player, level, things, sidetex, S.Thinkers{ran, t <> due}, rnd, clock, ended, usedown, sounds, mrnd, reborn, secrets}))

# The thinkers all due again, in the order they were started.
def State.rested(s: S.State) -> S.State:
  S.State{player, level, things, sidetex, S.Thinkers{ran, due}, rnd, clock, ended, usedown, sounds, mrnd, reborn, secrets} = s
  S.State{player, level, things, sidetex, S.Thinkers{[], List.append(&2, S.Thinker, List.reverse(&2, S.Thinker, ran), due)},
    rnd, clock, ended, usedown, sounds, mrnd, reborn, secrets}

# Doom's P_RunThinkers.
def Sim.thinkers(+cmd: K.Cmd, +geo: L.Level.Geo, s: S.State) -> S.State:
  State.rested(Sim.thinkers.all(8n, cmd, geo, s))

# What a live tic makes of the state its thinkers left: the geometry it
# began with, the clock counted, and whether use was down.
def Sim.tic.kept(geo: L.Level.Geo, clock: U32, use: Bool, +after: S.State) -> S.State:
  S.State{S.State.player(after), L.Level{geo, L.Level.sectors(S.State.level(after)), L.Level.specials(S.State.level(after)), L.Level.alerted(S.State.level(after))},
    S.State.things(after), S.State.sidetex(after), S.State.thinkers.of(after), S.State.rnd(after), (clock + 1 : U32),
    S.State.ended(after), use, S.State.sounds(after), S.State.face(after), S.State.reborn(after), S.State.secrets(after)}

# P_PlayerThink's counters, once the sprites have moved.
def Sim.player.counted(+s: S.State) -> S.State:
  S.State.player.put(s, Sim.counters(S.State.player(s)))

# P_PlayerThink's BT_CHANGE: the fist's number takes the chainsaw if
# owned, unless it is up with berserk on, and a weapon owned and not in
# hand becomes pending.
def Sim.weapon.selected(chosen: Maybe<&2, U32>, +p: S.Player) -> S.Player:
  match chosen:
    case None{}:
      p
    case Some{+weapon}:
      +inv = S.Player.inv(p)
      +chosen = Bool.pick(U32, Bool.and(U32.is_zero(weapon), Bool.and(I.Inventory.owns(7, inv),
        Bool.not(Bool.and(U32.is_eq(I.Inventory.ready(inv), 7), Bool.not(U32.is_zero(I.Inventory.strength(inv))))))), 7, weapon)
      +valid = Bool.and(I.Inventory.owns(chosen, inv), Bool.not(U32.is_eq(chosen, I.Inventory.ready(inv))))
      S.Player.holding(p, Bool.pick(I.Inventory, valid, I.Inventory.want(chosen, inv), inv))

def Sim.weapon.select(+cmd: K.Cmd, +s: S.State) -> S.State:
  S.State.player.put(s, Sim.weapon.selected(K.Cmd.weapon(cmd), S.State.player(s)))

# The rest of P_PlayerThink once the sector's special has acted: the
# secret, the weapon change, the player sprites and the counters. It
# opens the state first, since each def below reads its state several
# times, and a state the checker cannot compute, as a level no law
# fixes leaves it, is compared once per read (docs/bend.md).
def Sim.player.thinks(+cmd: K.Cmd, hurt: S.State) -> S.State:
  S.State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn, secrets} = hurt
  Sim.player.counted(S.Sim.psprites.with(~Sim.damage.enter.acted, cmd, Sim.weapon.select(cmd, Sp.Sim.sector.secret(
    S.State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn, secrets}))))

# Doom's P_PlayerThink for a living player, in its order: the move, the
# eye, what the sector's special deals, then the player sprites and the
# counters.
def Sim.player.live(+cmd: K.Cmd, +level: L.Level, +clock: U32, +s: S.State) -> S.State:
  Sim.player.thinks(cmd, Sp.Sim.sector(level, clock,
    S.State.player.put(s, S.Sim.eye(level, clock, S.Sim.move(level, cmd, S.State.player(s))))))

# Doom's P_DeathThink: the sprites move, the view sinks and turns to the
# attacker, and use asks for the level again.
def Sim.player.dead(+level: L.Level, +clock: U32, use: Bool, +s: S.State) -> S.State:
  +asked = S.Sim.death.asked(use, s)
  +attacker = S.Sim.Hurt.attacker(S.Player.hurt(S.State.player(asked)))
  S.State.player.put(asked, S.Sim.death(level, clock,
    S.Sim.blamed.if(Bool.or(U32.is_eq(attacker, H.Thing.you()),
      U32.is_eq(attacker, H.Things.you(S.State.things(asked)))), S.State.things(asked), S.State.player(asked), attacker),
    asked))

# Doom's P_PlayerThink: a dead player thinks of dying alone. Neither
# think moves the player, which the mobj's own turn does, so the tic
# holds the place across it.
def Sim.player(dead: Bool, +cmd: K.Cmd, +level: L.Level, +clock: U32, +s: S.State) -> S.State:
  match dead:
    case False{}:
      Sim.player.live(cmd, level, clock, s)
    case True{}:
      Sim.player.dead(level, clock, K.Cmd.use(cmd), s)

# One tic in Doom's order: the player thinks, use acts on the press,
# which a dead player never makes, the thinkers run in the order they
# were started (the mobjs of the map's records, the player's among them,
# whose own turn moves the player and fires the lines that move
# crossed), the clock counts. The tic's sounds start from none, and what
# the things were heard doing is reported when its last thinker has run.
# An ended level stands still: no tic runs, so its sounds stay the last
# live tic's, and whoever gathers sounds tic by tic passes over it.
def Sim.tic.done(+cmd: K.Cmd, +geo: L.Level.Geo, +clock: U32, +x: U32, +y: U32, after: S.State) -> S.State:
  Sim.tic.kept(geo, clock, K.Cmd.use(cmd), S.State.told(Sim.thinkers(cmd, geo, State.held(geo, x, y, after))))

# Doom's ST_Ticker, which G_Ticker runs after P_Ticker, so its draw
# comes after every sound that tic started: a number from M_Random for
# the tic, the face widget over it, and the health the next tic looks
# back at. A_WeaponReady's attackdown stays set while an attack sequence
# keeps that action from seeing a released command.
def Sim.st.ticker(s: S.State) -> S.State:
  S.State{+player, +level, +things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn, secrets} = s
  S.State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds,
    S.Sim.Face.melt.tic(S.Sim.face.tic(level, things, player, S.Sim.Face.drew(True{}, mrnd))), reborn, secrets}

def Sim.tic.live(+cmd: K.Cmd, +level: L.Level, +geo: L.Level.Geo, +clock: U32, +usedown: Bool, +dead: Bool,
  +before: S.State) -> S.State:
  +x = S.Player.x(S.State.player(before))
  +y = S.Player.y(S.State.player(before))
  Sim.st.ticker(Sim.tic.done(cmd, geo, clock, x, y,
    Sp.Sim.use(Bool.and(Bool.not(dead), Sim.pressed(cmd, usedown)), Sim.player(dead, cmd, level, clock, before))))

def Sim.tic(+cmd: K.Cmd, s: S.State) -> S.State:
  match s:
    case S.State{+player, L.Level{+geo, sectors, specials, heard}, things, sidetex, thinkers, rnd, +clock, S.Unended{}, +usedown, sounds, mrnd, reborn, secrets}:
      +level = {L.Level{geo, sectors, specials, heard} : L.Level}
      Sim.tic.live(cmd, level, geo, clock, usedown, S.Player.dead(player),
        {S.State{player, level, things, sidetex, thinkers, rnd, clock, S.Unended{}, usedown, [], mrnd, reborn, secrets} : S.State})
    case ended:
      ended

# A tic for each command of the list, in order: a demo.
def Sim.replay(script: List<&2, K.Cmd>, s: S.State) -> S.State:
  match script:
    case []:
      s
    case cmd <> rest:
      Sim.replay(rest, Sim.tic(cmd, s))
