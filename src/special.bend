# The line and sector specials of the shareware maps: Doom's p_spec.c,
# p_switch.c, p_doors.c, p_plats.c, p_floor.c and p_lights.c over the
# sim's state. A crossed line fires through Sim.cross for the player and
# Sim.thing.crossed for a monster, both by Sim.cross.special's table,
# which Sim.thing.cross.special filters for a monster; a used line
# through Sim.use for the player, by Sim.use.special's table, and
# Sim.thing.uses for a monster, by Sim.thing.use.special's; a line a
# bullet meets through Sim.shoot, which the shot calls back. The tic's
# Sim.think steps the sectors' thinkers here, and the sector under the
# player acts through Sim.sector and Sim.sector.secret. A level's lights
# start in Sim.lights.
import Base
import ./vec.bend as V
import ./fixed.bend as F
import ./angle.bend as A
import ./level.bend as L
import ./random.bend as M
import ./things.bend as H
import ./inventory.bend as I
import ./sound.bend as Sn
import ./message.bend as Msg
import ./sim.bend as S

# Lights
# ------

def Sim.light(s: S.State, sector: U32) -> U32:
  L.Level.sector.light(S.State.level(s), sector)

# Set a blink's phase and count, then start or retain its thinker.
def Sim.blink.to(~put: @s: S.State -> @t: S.Thinker -> S.State, +lit: Bool, +sector: U32, +dark: U32, +bright: U32,
  +darktime: U32, +brighttime: U32, +random: Bool, s: S.State) -> S.State:
  S.State{player, level, things, sidetex, thinkers, +rnd, clock, ended, usedown, sounds, mrnd, reborn, totalsecret} = s
  +time = Bool.pick(U32, lit, darktime, brighttime)
  +i = Bool.pick(U32, random, M.Random.next(rnd), rnd)
  put(S.State{player, L.Level.light.put(level, sector, Bool.pick(U32, lit, dark, bright)), things, sidetex,
    thinkers, i, clock, ended, usedown, sounds, mrnd, reborn, totalsecret}, S.Blink{sector, Bool.pick(U32, random,
    ((M.Random.at(i) .&. time : U32) + 1 : U32), time), dark, bright, darktime, brighttime, random})

def Sim.blink(turn: Bool, +sector: U32, count: U32, +dark: U32, +bright: U32, darktime: U32, brighttime: U32,
  +random: Bool, +s: S.State) -> S.State:
  match turn:
    case False{}:
      S.State.kept(s, S.Blink{sector, count, dark, bright, darktime, brighttime, random})
    case True{}:
      Sim.blink.to(~S.State.kept, Bool.pick(Bool, random, U32.is_eq(Sim.light(s, sector), bright),
        Bool.not(U32.is_eq(Sim.light(s, sector), dark))), sector, dark, bright, darktime, brighttime,
        random, s)

# Doom's T_Glow: 8 a tic, and a step that would reach an end is undone
# and turns the glow.
def Sim.glow(+sector: U32, +dark: U32, +bright: U32, +down: Bool, s: S.State) -> S.State:
  S.State{player, +level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn, totalsecret} = s
  +light = L.Level.sector.light(level, sector)
  +next = Bool.pick(U32, down, (light - 8 : U32), (light + 8 : U32))
  +turn = Bool.pick(Bool, down, F.Fixed.le(next, dark), F.Fixed.ge(next, bright))
  S.State.kept(S.State{player, L.Level.light.put(level, sector, Bool.pick(U32, turn, light, next)), things, sidetex,
    thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn, totalsecret}, S.Glow{sector, dark, bright, Bool.xor(down, turn)})

# Movers
# ------

# Doom's P_ThingHeightClip, for the player and every thing: what stood on
# its floor stands on the new one, anything else is lowered under the
# ceiling if it must be.
def Sim.clip(+z: U32, +floorz: U32, +floor: U32, +ceil: U32, +height: U32) -> U32:
  Bool.pick(U32, U32.is_eq(z, floorz), floor, F.Fixed.min(z, (ceil - height : U32)))

def Sim.fits(+floor: U32, +ceil: U32, +height: U32) -> Bool:
  F.Fixed.ge((ceil - floor : U32), height)

# The player clipped again: its position check's pickups, the floor and
# ceiling there, and whether it still fits.
def Sim.reclip.fit(p: S.Player, touched: I.Inventory & H.Things, f: S.Sim.Fit) -> S.Sim.Try:
  S.Player{x, y, +z, angle, momx, momy, momz, +floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt} = p
  (held, things) = touched
  S.Fit{ok, +floor, +ceil, drop} = f
  S.Try{Sim.fits(floor, ceil, S.Sim.height()), S.Player{x, y, Sim.clip(z, floorz, floor, ceil, S.Sim.height()), angle,
    momx, momy, momz, floor, ceil, viewheight, deltaview, viewz, crossed, held, psprites, hurt}, things}

def Sim.reclip.met(+level: L.Level, things: H.Things, +p: S.Player, m: S.Sim.Body, +met: S.Sim.Met) -> S.Sim.Try:
  Sim.reclip.fit(p, S.Sim.touch(level, things, p, S.Player.x(p), S.Player.y(p), met), S.Sim.check.met(met, level, m, 1))

def Sim.reclip(+level: L.Level, +things: H.Things, +p: S.Player) -> S.Sim.Try:
  Sim.reclip.met(level, things, p, S.Player.body(p, H.Things.you(things)),
    S.Sim.met(level, things, p, S.Player.body(p, H.Things.you(things))))

# P_ThingHeightClip updates the bounds and z even when the thing fails
# to fit; PIT_ChangeSector decides what that failure means.
def Sim.reclip.fin(th: H.Thing, m: S.Sim.Body, f: S.Sim.Fit) -> Bool & H.Thing:
  H.Thing{id, kind, x, y, +z, +floorz, ceilz, angle, sector, state, tics, momz, hurt} = th
  S.Body{i, mx, my, mz, radius, +height, flags} = m
  S.Fit{ok, +floor, +ceil, drop} = f
  (Sim.fits(floor, ceil, height),
    H.Thing{id, kind, x, y, Sim.clip(z, floorz, floor, ceil, height), floor, ceil, angle, sector, state, tics,
      momz, hurt})

def Sim.reclip.thing(+level: L.Level, things: H.Things, p: S.Player, +th: H.Thing) -> Bool & H.Thing:
  Sim.reclip.fin(th, S.Sim.body.of(th), S.Sim.check(level, things, p, S.Sim.body.of(th), 3))

def Sim.change.gib(+th: H.Thing) -> H.Thing:
  H.Thing.entering(H.Thing.hurting(th,
    V.Vec.set(V.Vec.set(V.Vec.set(H.Thing.hurt(th), H.Thing.hurt.height(), 0), H.Thing.hurt.radius(), 0),
      H.Thing.hurt.flags(), (H.Thing.flags(th) .&. U32.not(2) : U32))), 50)

def Sim.change.fit(fits: Bool, dead: Bool, dropped: Bool, +id: U32, bm: L.Level.Blockmap, ok: Bool,
  p: S.Player, things: H.Things, +th: H.Thing) -> S.Sim.Try:
  match fits dead dropped:
    case True{} _ _:
      S.Try{ok, p, H.Things.put(things, id, Some{th})}
    case False{} True{} _:
      S.Try{ok, p, H.Things.put(things, id, Some{Sim.change.gib(th)})}
    case False{} False{} True{}:
      S.Try{ok, p, H.Things.removed(things, bm, th)}
    case False{} False{} False{}:
      S.Try{Bool.and(ok, Bool.not(H.Thing.flagged(th, 4))), p, H.Things.put(things, id, Some{th})}

def Sim.change.put(+id: U32, bm: L.Level.Blockmap, ok: Bool, p: S.Player, things: H.Things,
  r: Bool & H.Thing) -> S.Sim.Try:
  (fits, +th) = r
  Sim.change.fit(fits, F.Fixed.le(H.Thing.health(th), 0), H.Thing.flagged(th, 131072), id, bm, ok, p, things, th)

def Sim.change.thing(m: Maybe<&2, H.Thing>, +id: U32, +level: L.Level, ok: Bool, +p: S.Player, +things: H.Things) ->
  S.Sim.Try:
  match m:
    case None{}:
      S.Try{ok, p, things}
    case Some{th}:
      Sim.change.put(id, L.Level.blockmap_of(level), ok, p, things, Sim.reclip.thing(level, things, p, th))

def Sim.change.player(ok: Bool, t: S.Sim.Try) -> S.Sim.Try:
  S.Try{fits, p, things} = t
  S.Try{Bool.and(ok, fits), p, things}

# A mobj clipped again: the player's, or a thing's, which has nothing
# to clip once gone.
def Sim.change.one(you: Bool, +id: U32, +level: L.Level, t: S.Sim.Try) -> S.Sim.Try:
  match you:
    case True{}:
      S.Try{ok, +p, things} = t
      Sim.change.player(ok, Sim.reclip(level, things, p))
    case False{}:
      S.Try{ok, +p, +things} = t
      Sim.change.thing(H.Things.get(things, id), id, level, ok, p, things)

def Sim.change.go(ids: List<&2, U32>, +level: L.Level, +you: U32, t: S.Sim.Try) -> S.Sim.Try:
  match ids:
    case []:
      t
    case +id <> rest:
      Sim.change.go(rest, level, you, Sim.change.one(U32.is_eq(id, you), id, level, t))

def Sim.change.box(b: L.Level.Box, +level: L.Level, t: S.Sim.Try) -> S.Sim.Try:
  L.Box{+top, +bottom, +left, +right} = b
  S.Try{ok, p, +things} = t
  Sim.change.go(H.Things.linked(things, L.Level.blockmap_of(level),
    S.Sim.cells(U32.to_nat(F.Fixed.max((right - left + 1 : U32), 0)),
      U32.to_nat(F.Fixed.max((top - bottom + 1 : U32), 0)), left, bottom)), level, H.Things.you(things),
    S.Try{ok, p, things})

# Doom's P_ChangeSector: every mobj linked in the cells of the sector's
# block box, touching the sector or not, clipped again in the blockmap's
# order; whether each that must fit does.
def Sim.change(+level: L.Level, +sector: U32, p: S.Player, things: H.Things) -> S.Sim.Try:
  Sim.change.box(L.Level.blockbox(level, sector), level, S.Try{True{}, p, things})

def Sim.Noise.start(n: S.Sim.Noise) -> U32:
  S.Noise{start, wake, up, down, crush, grind} = n
  start

def Sim.Noise.wake(n: S.Sim.Noise) -> U32:
  S.Noise{start, wake, up, down, crush, grind} = n
  wake

# A sector's floor flat and special set.
def Sim.floor.change(+sector: U32, +flat: U32, +special: U32, s: S.State) -> S.State:
  S.State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn, totalsecret} = s
  S.State{player, L.Level.sector.put(L.Level.sector.put(level, sector, 2, flat), sector, 5, special), things, sidetex,
    thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn, totalsecret}

# A mover with steps left runs again next tic, after those kept so far,
# a change at their head made at once; one with none has ended.
def Sim.mover.kept(+sector: U32, ceiling: Bool, speed: U32, steps: List<&2, S.Sim.Step>,
  plan: List<&2, S.Sim.Step>, noise: S.Sim.Noise, s: S.State) -> S.State:
  match steps:
    case []:
      s
    case S.Change{flat, special} <> rest:
      Sim.mover.kept(sector, ceiling, speed, rest, plan, noise, Sim.floor.change(sector, flat, special, s))
    case step <> rest:
      S.State.kept(s, S.Mover{sector, ceiling, speed, step <> rest, plan, noise})

# A mover's sector heard grinding and then stopping, as T_MoveFloor
# sounds them after its step.
def Sim.mover.heard(+sector: U32, grind: U32, stop: U32, s: S.State) -> S.State:
  S.Sim.sound(stop, Sn.Sector{sector}, S.Sim.sound(grind, Sn.Sector{sector}, s))

# The rest of a plan from its first travel the way given, else what is
# given: where a crushed mover goes on, and a door turned back, as
# T_VerticalDoor and T_PlatRaise turn their direction.
def Sim.plan.from(steps: List<&2, S.Sim.Step>, +down: Bool, +otherwise: List<&2, S.Sim.Step>) ->
  List<&2, S.Sim.Step>:
  match steps:
    case []:
      otherwise
    case S.Travel{+way, +dest} <> +rest:
      Bool.pick(List<&2, S.Sim.Step>, Bool.xor(way, down), Sim.plan.from(rest, down, otherwise),
        S.Travel{way, dest} <> rest)
    case other <> rest:
      Sim.plan.from(rest, down, otherwise)

# A step something does not fit is undone, everything clipped again, and
# the mover crushed: it sounds its crush and goes on from the steps
# given for that.
def Sim.mover.fitted(t: S.Sim.Try, +sector: U32, +ceiling: Bool, speed: U32, was: U32,
  going: List<&2, S.Sim.Step>, crushed: List<&2, S.Sim.Step>, +plan: List<&2, S.Sim.Step>, noise: S.Sim.Noise,
  grind: U32, stop: U32, crush: U32, +s: S.State) -> S.State:
  match t:
    case S.Try{True{}, p, got}:
      Sim.mover.kept(sector, ceiling, speed, going, plan, noise,
        Sim.mover.heard(sector, grind, stop, S.State.moved(S.Try{True{}, p, got}, S.State.level(s), s)))
    case S.Try{False{}, p, got}:
      +undone = L.Level.plane.put(S.State.level(s), sector, ceiling, was)
      Sim.mover.kept(sector, ceiling, speed, crushed, plan, noise,
        Sim.mover.heard(sector, grind, crush, S.State.moved(Sim.change(undone, sector, p, got), undone, s)))

# Doom's T_MovePlane: a step that would pass the destination lands on it
# and ends the travel. A ceiling going up short of its destination does
# not care what fits under it. The sector grinds when the clock's low
# three bits are clear. A travel's last step ends it and sounds its end
# whether or not everything fits, undone if not; any other step that
# does not fit turns the mover back on its plan from its first travel
# the other way, or, for a floor with none, tries again next tic.
def Sim.mover.move(+sector: U32, +ceiling: Bool, +speed: U32, +down: Bool, +dest: U32,
  +rest: List<&2, S.Sim.Step>, +plan: List<&2, S.Sim.Step>, +noise: S.Sim.Noise, s: S.State) -> S.State:
  S.Noise{start, wake, rose, fell, crush, grind} = noise
  S.State{+player, +level, +things, sidetex, thinkers, rnd, +clock, ended, usedown, sounds, mrnd, reborn, totalsecret} = s
  +was = L.Level.plane(level, sector, ceiling)
  +next = Bool.pick(U32, down, (was - speed : U32), (was + speed : U32))
  +past = Bool.pick(Bool, down, F.Fixed.lt(next, dest), F.Fixed.gt(next, dest))
  +moved = L.Level.plane.put(level, sector, ceiling, Bool.pick(U32, past, dest, next))
  +stop = Bool.pick(U32, past, Bool.pick(U32, down, fell, rose), 0)
  +going = Bool.pick(List<&2, S.Sim.Step>, past, rest, S.Travel{down, dest} <> rest)
  Sim.mover.fitted(S.Sim.Try.or(Bool.and(ceiling, Bool.not(Bool.or(down, past))),
    Sim.change(moved, sector, player, things)), sector, ceiling, speed, was, going,
    Bool.pick(List<&2, S.Sim.Step>, past, going, Sim.plan.from(plan, Bool.not(down), going)), plan, noise,
    Bool.pick(U32, U32.is_zero((clock .&. 7 : U32)), grind, 0), stop, Bool.pick(U32, past, stop, crush),
    S.State{player, moved, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn, totalsecret})

# Doom's button in P_UpdateSpecials: the tic its count reaches zero the
# side shows its texture again. Vanilla sounds the pop-back from the
# address of the button's origin where it means the origin, and reads a
# place out of the next button's slot: the map's own origin, while that
# slot is free.
def Sim.button(done: Bool, side: U32, slot: U32, texture: U32, tics: U32, s: S.State) -> S.State:
  match done:
    case True{}:
      S.State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn, totalsecret} = s
      S.Sim.sound(Sn.Sound.swtchn(), Sn.Spot{0, 0}, S.State{player, level, things,
        V.Vec.set(sidetex, (side * 3 + slot : U32), texture), thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn, totalsecret})
    case False{}:
      S.State.kept(s, S.Button{side, slot, texture, (tics - 1 : U32)})

def Sim.line.touches(+sector: U32, line: L.Level.Line) -> Bool:
  L.Line{x1, y1, x2, y2, flags, +front, +back} = line
  Bool.or(U32.is_eq(front, sector), U32.is_eq(back, sector))

def Sim.lines.go(n: Nat, +level: L.Level, +sector: U32, +i: U32) -> List<&2, U32>:
  match n:
    case 0n:
      []
    case 1n+m:
      V.Vec.keep(~U32, Sim.line.touches(sector, L.Level.line(level, i)), i,
        Sim.lines.go(m, level, sector, (i + 1 : U32)))

# A sector's lines in line order, as P_GroupLines lists them.
def Sim.lines(+level: L.Level, sector: U32) -> List<&2, U32>:
  Sim.lines.go(U32.to_nat(L.Level.nlines(level)), level, sector, 0)

# Something of each of some lines, kept or not by a line of the sector's.
def Sim.over(~of: @+sector: U32 -> @line: L.Level.Line -> @rest: List<&2, U32> -> List<&2, U32>, lines: List<&2, U32>,
  +level: L.Level, +sector: U32) -> List<&2, U32>:
  match lines:
    case []:
      []
    case i <> rest:
      of(sector, L.Level.line(level, i), Sim.over(~of, rest, level, sector))

# Doom's getNextSector: across a two-sided line of the sector, the back
# of a line whose front is the sector, else the front.
def Sim.around.of(+sector: U32, line: L.Level.Line, rest: List<&2, U32>) -> List<&2, U32>:
  L.Line{x1, y1, x2, y2, flags, +front, +back} = line
  V.Vec.keep(~U32, Bool.and(Bool.not(U32.is_zero((flags .&. 4 : U32))), Bool.not(U32.is_eq(back, L.Level.none()))),
    Bool.pick(U32, U32.is_eq(front, sector), back, front), rest)

# The sectors across a sector's lines, line by line.
def Sim.around(+level: L.Level, +sector: U32) -> List<&2, U32>:
  Sim.over(~Sim.around.of, Sim.lines(level, sector), level, sector)

# The least or the most of a sector's word over some sectors, from a
# first value: Doom's P_FindLowestCeilingSurrounding and its kin.
def Sim.extreme(~pick: @+a: U32 -> @+b: U32 -> U32, ~read: @+level: L.Level -> @s: U32 -> U32,
  sectors: List<&2, U32>, +level: L.Level, acc: U32) -> U32:
  match sectors:
    case []:
      acc
    case s <> rest:
      Sim.extreme(~pick, ~read, rest, level, pick(acc, read(level, s)))

# Whether a sector has a mover, Doom's specialdata.
def Sim.moving(thinkers: List<&2, S.Thinker>, +sector: U32) -> Bool:
  match thinkers:
    case []:
      False{}
    case S.Mover{s, ceiling, speed, steps, plan, noise} <> rest:
      Bool.or(U32.is_eq(s, sector), Sim.moving(rest, sector))
    case _ <> rest:
      Sim.moving(rest, sector)

# A mover begun: at the start of its plan, last to run, its start heard.
def Sim.mover.begin(+sector: U32, ceiling: Bool, speed: U32, +plan: List<&2, S.Sim.Step>, +noise: S.Sim.Noise,
  s: S.State) -> S.State:
  S.State.thinking(S.Sim.sound(Sim.Noise.start(noise), Sn.Sector{sector}, s),
    S.Mover{sector, ceiling, speed, plan, plan, noise})

# T_VerticalDoor's sounds: the door starts with a sound given, its wait
# ends with another, and it opens again on what is in its way. The
# blazing door has its own open and close, closes aloud a second time as
# it shuts, and is turned back with the plain door's sound.
def Sim.noise.door(start: U32, wake: U32) -> S.Sim.Noise:
  S.Noise{start, wake, 0, 0, Sn.Sound.doropn(), 0}

def Sim.noise.blazing() -> S.Sim.Noise:
  S.Noise{Sn.Sound.bdopn(), Sn.Sound.bdcls(), 0, Sn.Sound.bdcls(), Sn.Sound.doropn(), 0}

# T_PlatRaise's: the lift starts, stops at either end, starts again
# after its wait, and again when turned back down.
def Sim.noise.lift() -> S.Sim.Noise:
  S.Noise{Sn.Sound.pstart(), Sn.Sound.pstart(), Sn.Sound.pstop(), Sn.Sound.pstop(), Sn.Sound.pstart(), 0}

# T_MoveFloor's: the floor grinds as it moves and stops aloud.
def Sim.noise.floor() -> S.Sim.Noise:
  S.Noise{0, 0, Sn.Sound.pstop(), Sn.Sound.pstop(), 0, Sn.Sound.stnmov()}

# EV_DoPlat's start and T_PlatRaise's grinding, stop and obstruction
# sounds for a plat that raises and changes.
def Sim.noise.plat() -> S.Sim.Noise:
  S.Noise{Sn.Sound.stnmov(), 0, Sn.Sound.pstop(), Sn.Sound.pstop(), Sn.Sound.pstart(), Sn.Sound.stnmov()}

# The level's lights
# ------------------

# Doom's P_FindMinSurroundingLight, from the sector's own light.
def Sim.light.low(+s: S.State, +sector: U32) -> U32:
  Sim.extreme(~F.Fixed.min, ~L.Level.sector.light, Sim.around(S.State.level(s), sector), S.State.level(s),
    Sim.light(s, sector))

# The slow strobe's dark level is 0 when no sector around is darker.
def Sim.strobe.dark(+low: U32, light: U32) -> U32:
  Bool.pick(U32, U32.is_eq(low, light), 0, low)

def Sim.light.cleared(+sector: U32, s: S.State) -> S.State:
  S.State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn, totalsecret} = s
  S.State{player, L.Level.sector.put(level, sector, 5, 0), things, sidetex, thinkers, rnd, clock, ended,
    usedown, sounds, mrnd, reborn, totalsecret}

def Sim.strobe(+sync: Bool, +darktime: U32, +sector: U32, +s: S.State) -> S.State:
  +rnd = Bool.pick(U32, sync, S.State.rnd(s), M.Random.next(S.State.rnd(s)))
  S.State.thinking(Sim.light.cleared(sector, S.State.rnd.put(rnd, s)),
    S.Blink{sector, Bool.pick(U32, sync, 1, ((M.Random.at(rnd) .&. 7 : U32) + 1 : U32)),
      Sim.strobe.dark(Sim.light.low(s, sector), Sim.light(s, sector)), Sim.light(s, sector), darktime, 5, False{}})

# Light thinkers leave their sector with no gameplay special.
def Sim.light.spawn(special: U32, +sector: U32, +s: S.State) -> S.State:
  match special:
    case 1:
      Sim.light.cleared(sector, Sim.blink.to(~S.State.thinking, False{}, sector,
        Sim.light.low(s, sector), Sim.light(s, sector), 7, 64, True{}, s))
    case 2:
      Sim.strobe(False{}, 15, sector, s)
    case 3:
      Sim.strobe(False{}, 35, sector, s)
    case 8:
      Sim.light.cleared(sector, S.State.thinking(s,
        S.Glow{sector, Sim.light.low(s, sector), Sim.light(s, sector), True{}}))
    case 12:
      Sim.strobe(True{}, 35, sector, s)
    case 13:
      Sim.strobe(True{}, 15, sector, s)
    case _:
      s

def Sim.lights(n: Nat, +sector: U32, +s: S.State) -> S.State:
  match n:
    case 0n:
      s
    case 1n+m:
      Sim.lights(m, (sector + 1 : U32),
        Sim.light.spawn(L.Level.sector.special(S.State.level(s), sector), sector, s))

# Doors
# -----

# A line that works once has no special afterwards.
def Sim.once(line: U32, s: S.State) -> S.State:
  S.State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn, totalsecret} = s
  S.State{player, L.Level.special.put(level, line, 0), things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn, totalsecret}

# Doom's EV_VerticalDoor on a door already moving: one closing goes back
# up, on its plan from its first travel up, and any other starts down at
# once for the player, on its plan from its first travel down, and is
# left alone for anything else, since bad guys never close doors.
def Sim.door.turned(steps: List<&2, S.Sim.Step>, shuts: Bool, +plan: List<&2, S.Sim.Step>, floor: U32) ->
  List<&2, S.Sim.Step>:
  match steps shuts:
    case S.Travel{True{}, dest} <> rest _:
      Sim.plan.from(plan, False{}, plan)
    case other True{}:
      Sim.plan.from(plan, True{}, [S.Travel{True{}, floor}])
    case other False{}:
      other

def Sim.door.turn(thinkers: List<&2, S.Thinker>, +shuts: Bool, +sector: U32, +floor: U32) ->
  List<&2, S.Thinker>:
  match thinkers:
    case []:
      []
    case S.Mover{+s, ceiling, speed, +steps, +plan, noise} <> rest:
      S.Mover{s, ceiling, speed, Bool.pick(List<&2, S.Sim.Step>, U32.is_eq(s, sector),
        Sim.door.turned(steps, shuts, plan, floor), steps), plan, noise} <>
        Sim.door.turn(rest, shuts, sector, floor)
    case other <> rest:
      other <> Sim.door.turn(rest, shuts, sector, floor)

# A door's top: 4 under the lowest ceiling around it.
def Sim.door.top(+level: L.Level, sector: U32) -> U32:
  (Sim.extreme(~F.Fixed.min, ~L.Level.ceil, Sim.around(level, sector), level, 2147483647) - 262144 : U32)

# A door begun up to its top, and for one that closes again, VDOORWAIT's
# 150 tics open and down to its floor.
def Sim.door.begin(raise: Bool, +sector: U32, +top: U32, speed: U32, noise: S.Sim.Noise, +s: S.State) -> S.State:
  Sim.mover.begin(sector, True{}, speed, Bool.pick(List<&2, S.Sim.Step>, raise,
    [S.Travel{False{}, top}, S.Hold{150}, S.Travel{True{}, L.Level.floor(S.State.level(s), sector)}],
    [S.Travel{False{}, top}]), noise, s)

# A door already moving is turned without a sound.
def Sim.door.on(moving: Bool, +shuts: Bool, +sector: U32, speed: U32, noise: S.Sim.Noise, +s: S.State) -> S.State:
  match moving:
    case True{}:
      S.State{player, +level, things, sidetex, S.Thinkers{ran, due}, rnd, clock, ended, usedown, sounds, mrnd, reborn, totalsecret} = s
      S.State{player, level, things, sidetex,
        S.Thinkers{Sim.door.turn(ran, shuts, sector, L.Level.floor(level, sector)),
          Sim.door.turn(due, shuts, sector, L.Level.floor(level, sector))}, rnd, clock, ended, usedown, sounds,
        mrnd, reborn, totalsecret}
    case False{}:
      Sim.door.begin(True{}, sector, Sim.door.top(S.State.level(s), sector), speed, noise, s)

def Sim.door.behind(+level: L.Level, +i: U32) -> U32:
  L.Level.side.sector(level, L.Level.line.side(level, i, 1))

# Doom's EV_VerticalDoor: the door is the sector behind the line. One
# that closes again is turned if it moves already; one that stays open
# starts beside whatever moves there, and spends its line. Only the
# player may send a door that is not already closing back down.
def Sim.door(raise: Bool, +i: U32, shuts: Bool, speed: U32, noise: S.Sim.Noise, +s: S.State) -> S.State:
  match raise:
    case True{}:
      +back = Sim.door.behind(S.State.level(s), i)
      Sim.door.on(Sim.moving(S.State.thinkers(s), back), shuts, back, speed, noise, s)
    case False{}:
      +back = Sim.door.behind(S.State.level(s), i)
      Sim.once(i, Sim.door.begin(False{}, back, Sim.door.top(S.State.level(s), back), speed, noise, s))

# The plain door's: VDOORSPEED, heard as it opens and as its wait ends.
def Sim.door.plain(raise: Bool, +i: U32, shuts: Bool, +s: S.State) -> S.State:
  Sim.door(raise, i, shuts, 131072, Sim.noise.door(Sn.Sound.doropn(), Sn.Sound.dorcls()), s)

# Doom's EV_VerticalDoor on a locked door: a thing that is no player is
# turned away; the player without the key is refused with the door's
# message and a grunt from nobody; with it, the door is the plain one.
def Sim.door.locked(player: Bool, key: Bool, +refusal: U32, raise: Bool, +i: U32, s: S.State) -> S.State:
  match player key:
    case False{} _:
      s
    case True{} False{}:
      S.Sim.sound(Sn.Sound.oof(), Sn.Nobody{}, S.State.says(refusal, s))
    case True{} True{}:
      Sim.door.plain(raise, i, True{}, s)

# Doom's EV_DoDoor for a sector of a tag, at VDOORSPEED: an opening door
# is heard unless it is at its top already, and one that closes again
# closes aloud once its wait is over.
def Sim.door.tagged(raise: Bool, +level: L.Level, +sector: U32, s: S.State) -> S.State:
  +top = Sim.door.top(level, sector)
  Sim.door.begin(raise, sector, top, 131072,
    Sim.noise.door(Bool.pick(U32, U32.is_eq(top, L.Level.ceil(level, sector)), 0, Sn.Sound.doropn()),
      Sn.Sound.dorcls()), s)

# vld_open, which stays open.
def Sim.door.open(+level: L.Level, +sector: U32, s: S.State) -> S.State:
  Sim.door.tagged(False{}, level, sector, s)

# vld_normal, which closes again.
def Sim.door.raise(+level: L.Level, +sector: U32, s: S.State) -> S.State:
  Sim.door.tagged(True{}, level, sector, s)

# vld_close30ThenOpen: the door closes aloud from where it is, stays shut
# for 30 seconds of tics, and opens aloud back there.
def Sim.door.close30(+level: L.Level, +sector: U32, s: S.State) -> S.State:
  Sim.mover.begin(sector, True{}, 131072, [S.Travel{True{}, L.Level.floor(level, sector)}, S.Hold{1050},
    S.Travel{False{}, L.Level.ceil(level, sector)}], Sim.noise.door(Sn.Sound.dorcls(), Sn.Sound.doropn()), s)

# Switches and tagged movers
# --------------------------

# Tagged sectors in sector order, optionally excluding occupied movers.
def Sim.tagged.go(n: Nat, +available: Bool, +level: L.Level, +thinkers: List<&2, S.Thinker>, +tag: U32, +s: U32) ->
  List<&2, U32>:
  match n:
    case 0n:
      []
    case 1n+m:
      V.Vec.keep(~U32, Bool.and(U32.is_eq(L.Level.sector.tag(level, s), tag), Bool.or(Bool.not(available),
        Bool.not(Sim.moving(thinkers, s)))), s,
        Sim.tagged.go(m, available, level, thinkers, tag, (s + 1 : U32)))

def Sim.tagged(+s: S.State, line: U32) -> List<&2, U32>:
  Sim.tagged.go(U32.to_nat(L.Level.nsectors(S.State.level(s))), True{}, S.State.level(s), S.State.thinkers(s),
    L.Level.tag(S.State.level(s), line), 0)

# A mover begun for each sector, all against the level as it stood.
def Sim.start(~make: @+level: L.Level -> @+sector: U32 -> @s: S.State -> S.State, sectors: List<&2, U32>, +s: S.State) ->
  S.State:
  match sectors:
    case []:
      s
    case sector <> rest:
      Sim.start(~make, rest, make(S.State.level(s), sector, s))

# Doom's P_FindLowestFloorSurrounding: the lowest floor around, its own
# included.
def Sim.floor.lowest(+level: L.Level, +sector: U32) -> U32:
  Sim.extreme(~F.Fixed.min, ~L.Level.floor, Sim.around(level, sector), level, L.Level.floor(level, sector))

# Doom's P_FindNextHighestFloor: the lowest floor around above the
# sector's own, else its own. Every floor found is above it, so the
# first one found replaces it.
def Sim.floor.above(+own: U32, +acc: U32, +floor: U32) -> U32:
  Bool.pick(U32, F.Fixed.gt(floor, own), Bool.pick(U32, U32.is_eq(acc, own), floor, F.Fixed.min(acc, floor)), acc)

def Sim.floor.next.go(sectors: List<&2, U32>, +level: L.Level, +own: U32, +acc: U32) -> U32:
  match sectors:
    case []:
      acc
    case s <> rest:
      Sim.floor.next.go(rest, level, own, Sim.floor.above(own, acc, L.Level.floor(level, s)))

def Sim.floor.next(+level: L.Level, +sector: U32) -> U32:
  Sim.floor.next.go(Sim.around(level, sector), level, L.Level.floor(level, sector), L.Level.floor(level, sector))

def Sim.floor.to(+sector: U32, +down: Bool, +dest: U32, s: S.State) -> S.State:
  Sim.mover.begin(sector, False{}, 65536, [S.Travel{down, dest}], Sim.noise.floor(), s)

# Doom's lowerFloorToLowest: 1 a tic down to the lowest floor around.
def Sim.floor.low(+level: L.Level, +sector: U32, s: S.State) -> S.State:
  Sim.floor.to(sector, True{}, Sim.floor.lowest(level, sector), s)

# Doom's raiseFloor: 1 a tic up to the lowest ceiling around, or to its
# own when that is lower.
def Sim.floor.raise(+level: L.Level, +sector: U32, s: S.State) -> S.State:
  Sim.floor.to(sector, False{}, Sim.extreme(~F.Fixed.min, ~L.Level.ceil, Sim.around(level, sector), level,
    L.Level.ceil(level, sector)), s)

# Doom's raiseFloorToNearest: 1 a tic up to the next floor.
def Sim.floor.nearest(+level: L.Level, +sector: U32, s: S.State) -> S.State:
  Sim.floor.to(sector, False{}, Sim.floor.next(level, sector), s)

# Doom's raiseToNearestAndChange plat, the floor already changed: half a
# unit a tic up to the next floor.
def Sim.plat.nearest(+level: L.Level, +sector: U32, s: S.State) -> S.State:
  Sim.mover.begin(sector, False{}, 32768, [S.Travel{False{}, Sim.floor.next(level, sector)}], Sim.noise.plat(), s)

def Sim.plat.changed.go(sectors: List<&2, U32>, +flat: U32, s: S.State) -> S.State:
  match sectors:
    case []:
      s
    case sector <> rest:
      Sim.plat.changed.go(rest, flat, Sim.floor.change(sector, flat, 0, s))

# EV_DoPlat's raiseToNearestAndChange before the plats start: each
# sector takes the floor flat in front of the line and loses its
# special, damage and all.
def Sim.plat.changed(+sectors: List<&2, U32>, +line: U32, +s: S.State) -> S.State:
  Sim.plat.changed.go(sectors, L.Level.floorpic(S.State.level(s),
    L.Level.side.sector(S.State.level(s), L.Level.line.side(S.State.level(s), line, 0))), s)

# Doom's EV_DoDonut. Across the pillar's first line is the ring; under
# is the back of the ring's first line whose back is not the pillar,
# read as vanilla reads it, whichever way the line faces. The ring rises
# half a unit a tic to under's floor and takes its flat and no special
# as it lands; the pillar sinks as slowly to the same height. A ring
# that is no sector starts nothing, where Chocolate Doom gives up on the
# tag's later sectors too. One pillar's donut can start another's
# sector, so each pillar is passed over if it is moving by its turn.
def Sim.donut.past(+pillar: U32, line: L.Level.Line, rest: List<&2, U32>) -> List<&2, U32>:
  L.Line{x1, y1, x2, y2, flags, front, +back} = line
  V.Vec.keep(~U32, Bool.not(U32.is_eq(back, pillar)), back, rest)

def Sim.donut.start(under: List<&2, U32>, +ring: U32, +pillar: U32, +level: L.Level, s: S.State) -> S.State:
  match under:
    case []:
      s
    case +at <> rest:
      Sim.mover.begin(pillar, False{}, 32768, [S.Travel{True{}, L.Level.floor(level, at)}], Sim.noise.floor(),
        Sim.mover.begin(ring, False{}, 32768, [S.Travel{False{}, L.Level.floor(level, at)},
          S.Change{L.Level.floorpic(level, at), 0}], Sim.noise.floor(), s))

def Sim.donut.ring(across: List<&2, U32>, +pillar: U32, +level: L.Level, s: S.State) -> S.State:
  match across:
    case []:
      s
    case +ring <> rest:
      Sim.donut.start(Sim.over(~Sim.donut.past, Sim.lines(level, ring), level, pillar), ring, pillar, level, s)

def Sim.donut.at(lines: List<&2, U32>, +pillar: U32, +level: L.Level, s: S.State) -> S.State:
  match lines:
    case []:
      s
    case i <> rest:
      Sim.donut.ring(Sim.around.of(pillar, L.Level.line(level, i), []), pillar, level, s)

def Sim.donut(+level: L.Level, +sector: U32, s: S.State) -> S.State:
  S.State{player, now, things, sidetex, S.Thinkers{+ran, +due}, rnd, clock, ended, usedown, sounds, mrnd, reborn, totalsecret} = s
  Sim.donut.at(Bool.pick(List<&2, U32>, Bool.or(Sim.moving(ran, sector), Sim.moving(due, sector)), [],
    Sim.lines(level, sector)), sector, level,
    S.State{player, now, things, sidetex, S.Thinkers{ran, due}, rnd, clock, ended, usedown, sounds, mrnd, reborn, totalsecret})

# Which of a side's three textures is a switch: the top, else the
# middle, else the bottom; 3 when none is.
def Sim.switch.slot(+level: L.Level, +sidetex: V.Vec, +at: U32) -> U32:
  Bool.pick(U32, U32.is_zero(L.Level.switch(level, V.Vec.get(sidetex, at))),
    Bool.pick(U32, U32.is_zero(L.Level.switch(level, V.Vec.get(sidetex, (at + 2 : U32)))),
      Bool.pick(U32, U32.is_zero(L.Level.switch(level, V.Vec.get(sidetex, (at + 1 : U32)))), 3, 1), 2), 0)

def Sim.pressed.side(thinkers: List<&2, S.Thinker>, +side: U32) -> Bool:
  match thinkers:
    case []:
      False{}
    case S.Button{pressed, slot, texture, tics} <> rest:
      Bool.or(U32.is_eq(pressed, side), Sim.pressed.side(rest, side))
    case _ <> rest:
      Sim.pressed.side(rest, side)

# P_ChangeSwitchTexture sounds a switch from the first button's origin
# where it means the pressed line's: nobody while no button runs, else
# the sector in front of the running button's line. Vanilla's first
# button is a slot, which can be free while a later one runs; here it is
# the first still running, the same while one runs at a time.
def Sim.switch.origin(thinkers: List<&2, S.Thinker>, +level: L.Level) -> Sn.Sound.Source:
  match thinkers:
    case []:
      Sn.Nobody{}
    case S.Button{side, slot, texture, tics} <> rest:
      Sn.Sector{L.Level.side.sector(level, side)}
    case _ <> rest:
      Sim.switch.origin(rest, level)

# A switch that works again starts a button of 35 tics for the texture
# it showed, unless its side has one running.
def Sim.switch.button(start: Bool, side: U32, slot: U32, showed: U32, s: S.State) -> S.State:
  match start:
    case False{}:
      s
    case True{}:
      S.State.thinking(s, S.Button{side, slot, showed, 35})

# The switch's texture swapped for its partner, with a click. The exit
# switch clicks like any other: vanilla clears a once-only line's special
# before it looks for the exit's, so sfx_swtchx never plays.
def Sim.switch.swap(none: Bool, again: Bool, +side: U32, +slot: U32, s: S.State) -> S.State:
  match none:
    case True{}:
      s
    case False{}:
      S.State{player, +level, things, +sidetex, S.Thinkers{+ran, +due}, rnd, clock, ended, usedown, sounds, mrnd, reborn, totalsecret} = s
      +showed = V.Vec.get(sidetex, (side * 3 + slot : U32))
      +started = List.append(&2, S.Thinker, List.reverse(&2, S.Thinker, ran), due)
      Sim.switch.button(Bool.and(again, Bool.not(Sim.pressed.side(started, side))), side, slot, showed,
        S.Sim.sound(Sn.Sound.swtchn(), Sim.switch.origin(started, level),
          S.State{player, level, things, V.Vec.set(sidetex, (side * 3 + slot : U32), L.Level.switch(level, showed)),
            S.Thinkers{ran, due}, rnd, clock, ended, usedown, sounds, mrnd, reborn, totalsecret}))

# Doom's P_ChangeSwitchTexture on the line's front side.
def Sim.switch(again: Bool, line: U32, +s: S.State) -> S.State:
  +side = L.Level.line.side(S.State.level(s), line, 0)
  +slot = Sim.switch.slot(S.State.level(s), S.State.sidetex(s), (side * 3 : U32))
  Sim.switch.swap(U32.is_eq(slot, 3), again, side, slot, s)

# Doom's G_ExitLevel and G_SecretExitLevel: the level ends by the exit
# or the secret exit, and the tic it ends on runs on.
def State.end(secret: Bool, s: S.State) -> S.State:
  S.State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn, totalsecret} = s
  S.State{player, level, things, sidetex, thinkers, rnd, clock, S.Ended{secret}, usedown, sounds, mrnd, reborn, totalsecret}

# A switch that works once: when its tag starts a mover, its texture is
# swapped and its special cleared.
def Sim.use.once(~make: @+level: L.Level -> @+sector: U32 -> @s: S.State -> S.State, sectors: List<&2, U32>, +line: U32,
  s: S.State) -> S.State:
  match sectors:
    case []:
      s
    case sector <> rest:
      Sim.once(line, Sim.switch(False{}, line, Sim.start(~make, sector <> rest, s)))

# A switch that works again: when its tag starts a mover, its texture is
# swapped for 35 tics.
def Sim.use.again(~make: @+level: L.Level -> @+sector: U32 -> @s: S.State -> S.State, sectors: List<&2, U32>, line: U32,
  +s: S.State) -> S.State:
  match sectors:
    case []:
      s
    case sector <> rest:
      Sim.switch(True{}, line, Sim.start(~make, sector <> rest, s))

# Doom's downWaitUpStay lift: 4 a tic down to the lowest floor around,
# its own included, 105 tics there, and back up to where it was.
def Sim.lift(+level: L.Level, +sector: U32, s: S.State) -> S.State:
  Sim.mover.begin(sector, False{}, 262144, [S.Travel{True{}, Sim.floor.lowest(level, sector)}, S.Hold{105},
    S.Travel{False{}, L.Level.floor(level, sector)}], Sim.noise.lift(), s)

def Sim.light.dark(+level: L.Level, +sector: U32, s: S.State) -> S.State:
  S.State{player, was, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn, totalsecret} = s
  S.State{player, L.Level.light.put(was, sector, 35), things, sidetex, thinkers, rnd, clock, ended,
    usedown, sounds, mrnd, reborn, totalsecret}

def Sim.light.tagged(+s: S.State, line: U32) -> List<&2, U32>:
  Sim.tagged.go(U32.to_nat(L.Level.nsectors(S.State.level(s))), False{}, S.State.level(s), S.State.thinkers(s),
    L.Level.tag(S.State.level(s), line), 0)

# Walk-over lines
# ---------------

# Doom's turboLower: 4 a tic down to the highest floor around, plus 8
# when that is not the floor's own height. A travel down to a height
# above lands at once, as Doom's does.
def Sim.floor.turbo.to(+highest: U32, own: U32) -> U32:
  Bool.pick(U32, U32.is_eq(highest, own), highest, (highest + 524288 : U32))

def Sim.floor.turbo(+level: L.Level, +sector: U32, s: S.State) -> S.State:
  Sim.mover.begin(sector, False{}, 262144, [S.Travel{True{}, Sim.floor.turbo.to(Sim.extreme(~F.Fixed.max,
    ~L.Level.floor, Sim.around(level, sector), level, 4262199296), L.Level.floor(level, sector))}],
    Sim.noise.floor(), s)

# Doom's raiseToNearestAndChange from a line that is walked over, and
# from a switch that works once.
def Sim.plat(+sectors: List<&2, U32>, +line: U32, s: S.State) -> S.State:
  Sim.start(~Sim.plat.nearest, sectors, Sim.plat.changed(sectors, line, s))

def Sim.plat.switch(+sectors: List<&2, U32>, +line: U32, s: S.State) -> S.State:
  Sim.use.once(~Sim.plat.nearest, sectors, line, Sim.plat.changed(sectors, line, s))

# One-shot crossings consume their special whether or not a sector starts.

def Sim.cross.special(special: U32, +line: U32, +s: S.State) -> S.State:
  match special:
    case 2:
      Sim.once(line, Sim.start(~Sim.door.open, Sim.tagged(s, line), s))
    case 16:
      Sim.once(line, Sim.start(~Sim.door.close30, Sim.tagged(s, line), s))
    case 35:
      Sim.once(line, Sim.start(~Sim.light.dark, Sim.light.tagged(s, line), s))
    case 36:
      Sim.once(line, Sim.start(~Sim.floor.turbo, Sim.tagged(s, line), s))
    case 76:
      Sim.start(~Sim.door.close30, Sim.tagged(s, line), s)
    case 86:
      Sim.start(~Sim.door.open, Sim.tagged(s, line), s)
    case 88:
      Sim.start(~Sim.lift, Sim.tagged(s, line), s)
    case 90:
      Sim.start(~Sim.door.raise, Sim.tagged(s, line), s)
    case 5:
      Sim.once(line, Sim.start(~Sim.floor.raise, Sim.tagged(s, line), s))
    case 22:
      Sim.once(line, Sim.plat(Sim.tagged(s, line), line, s))
    case 82:
      Sim.start(~Sim.floor.low, Sim.tagged(s, line), s)
    case 91:
      Sim.start(~Sim.floor.raise, Sim.tagged(s, line), s)
    case 98:
      Sim.start(~Sim.floor.turbo, Sim.tagged(s, line), s)
    case _:
      s

# Fire a crossing from the part of the move where vanilla fired it,
# while preserving the player's final position for the rest of the tic.
def Sim.cross.one(+line: U32, +x: U32, +y: U32, +s: S.State) -> S.State:
  +p = S.State.player(s)
  S.State.player.put(Sim.cross.special(L.Level.special(S.State.level(s), line), line,
    S.State.player.put(s, S.Player.located(p, x, y))), p)

# The lines the player's moves crossed this tic, each by the special it
# has when its turn comes.
def Sim.cross(lines: List<&2, S.Sim.Cross>, +s: S.State) -> S.State:
  match lines:
    case []:
      s
    case S.Cross{line, x, y} <> rest:
      Sim.cross(rest, Sim.cross.one(line, x, y, s))

# Gunfire
# -------

# Doom's P_ShootSpecialLine: 46 opens the doors of its tag and works its
# switch again, whether or not a door started. A thing that is not the
# player may fire 46 alone of vanilla's three, and the shareware maps
# carry no other.
def Sim.shoot.special(special: U32, +line: U32, +s: S.State) -> S.State:
  match special:
    case 46:
      Sim.switch(True{}, line, Sim.start(~Sim.door.open, Sim.tagged(s, line), s))
    case _:
      s

# A line a bullet met, by the special it has then.
def Sim.shoot(+line: U32, +s: S.State) -> S.State:
  Sim.shoot.special(L.Level.special(S.State.level(s), line), line, s)

# Use
# ---

# Whether the player holds a card's key.
def Sim.key(+s: S.State, card: U32) -> Bool:
  I.Inventory.key(card, S.Player.inv(S.State.player(s)))

# Doom's P_UseSpecialLine, used by the player or by a thing that is not:
# the manual doors, plain, locked or blazing, that close again (1, 26 to
# 28, 117) or stay open (31 to 34), and the switches. Any special Doom
# does not know does nothing.
def Sim.use.special(special: U32, +i: U32, +player: Bool, +s: S.State) -> S.State:
  match special:
    case 1:
      Sim.door.plain(True{}, i, player, s)
    case 26:
      Sim.door.locked(player, Sim.key(s, I.Inventory.bluecard()), Msg.Message.pd_bluek(), True{}, i, s)
    case 27:
      Sim.door.locked(player, Sim.key(s, I.Inventory.yellowcard()), Msg.Message.pd_yellowk(), True{}, i, s)
    case 28:
      Sim.door.locked(player, Sim.key(s, I.Inventory.redcard()), Msg.Message.pd_redk(), True{}, i, s)
    case 31:
      Sim.door.plain(False{}, i, player, s)
    case 32:
      Sim.door.locked(player, Sim.key(s, I.Inventory.bluecard()), Msg.Message.pd_bluek(), False{}, i, s)
    case 33:
      Sim.door.locked(player, Sim.key(s, I.Inventory.redcard()), Msg.Message.pd_redk(), False{}, i, s)
    case 34:
      Sim.door.locked(player, Sim.key(s, I.Inventory.yellowcard()), Msg.Message.pd_yellowk(), False{}, i, s)
    case 117:
      Sim.door(True{}, i, player, 524288, Sim.noise.blazing(), s)
    case 23:
      Sim.use.once(~Sim.floor.low, Sim.tagged(s, i), i, s)
    case 62:
      Sim.use.again(~Sim.lift, Sim.tagged(s, i), i, s)
    case 63:
      Sim.use.again(~Sim.door.raise, Sim.tagged(s, i), i, s)
    case 103:
      Sim.use.once(~Sim.door.open, Sim.tagged(s, i), i, s)
    case 9:
      Sim.use.once(~Sim.donut, Sim.tagged(s, i), i, s)
    case 18:
      Sim.use.once(~Sim.floor.nearest, Sim.tagged(s, i), i, s)
    case 20:
      Sim.plat.switch(Sim.tagged(s, i), i, s)
    case 70:
      Sim.use.again(~Sim.floor.turbo, Sim.tagged(s, i), i, s)
    case 11:
      State.end(False{}, Sim.once(i, Sim.switch(False{}, i, s)))
    case 51:
      State.end(True{}, Sim.once(i, Sim.switch(False{}, i, s)))
    case _:
      s

# Only the front of a line answers use.
def Sim.use.line(back: Bool, +level: L.Level, +i: U32, s: S.State) -> S.State:
  match back:
    case True{}:
      s
    case False{}:
      Sim.use.special(L.Level.special(level, i), i, True{}, s)

# What a use trace reaches: a special line, a wall that ends it, or
# nothing.
type Sim.Reach is Data:
  Special{line: U32}
  Wall{}
  Nothing{}

# The player grunts at a wall.
def Sim.use.hit(hit: Sim.Reach, +p: S.Player, +s: S.State) -> S.State:
  match hit:
    case Nothing{}:
      s
    case Wall{}:
      S.Sim.sound(Sn.Sound.noway(), Sn.Thing{H.Thing.you()}, s)
    case Special{+i}:
      Sim.use.line(S.Sim.point_side(S.Player.x(p), S.Player.y(p), L.Level.line(S.State.level(s), i)),
        S.State.level(s), i, s)

def Sim.use.at(special: Bool, shut: Bool, i: U32) -> S.Sim.Answer<&2, Sim.Reach>:
  match special shut:
    case True{} _:
      S.Answer{True{}, Special{i}}
    case False{} True{}:
      S.Answer{True{}, Wall{}}
    case False{} False{}:
      S.Answer{False{}, Nothing{}}

# Doom's PTR_UseTraverse: the first special line ends the walk whatever
# its special; a line without one ends it at a wall, and is passed when
# its opening is more than nothing.
def Sim.use.visit(+level: L.Level, m: S.Sim.Meet, reach: Sim.Reach) -> S.Sim.Answer<&2, Sim.Reach>:
  S.Meet{frac, isline, +i} = m
  Sim.use.at(Bool.not(U32.is_zero(L.Level.special(level, i))), S.Sim.shut(level, L.Level.line(level, i)), i)

# Doom's P_UseLines, on the press: a trace of 64 units along the facing.
def Sim.use(press: Bool, +s: S.State) -> S.State:
  match press:
    case False{}:
      s
    case True{}:
      +p = S.State.player(s)
      +level = S.State.level(s)
      +sine = L.Level.sine(level)
      +f = A.Angle.fine(S.Player.angle(p))
      Sim.use.hit(S.Sim.path(~Sim.Reach, ~Sim.use.visit, level, S.State.things(s), p, True{}, False{}, S.Player.x(p),
        S.Player.y(p),
        (S.Player.x(p) + 64 * A.Angle.cos(sine, f) : U32), (S.Player.y(p) + 64 * A.Angle.sin(sine, f) : U32),
        Nothing{}), p, s)

# Monsters' lines
# ---------------

# Doom's ML_SECRET: a thing that is not the player never opens a door on
# a line marked secret.
def Sim.secret(+line: L.Level.Line) -> Bool:
  L.Line{x1, y1, x2, y2, +flags, front, back} = line
  Bool.not(U32.is_zero((flags .&. 32 : U32)))

# Doom's P_UseSpecialLine for a thing that is not the player: the
# specials it may press, the manual doors 1 and 32 to 34. EV_VerticalDoor
# turns it away from the locked three, but the press still counts.
def Sim.thing.use.special(special: U32) -> Bool:
  match special:
    case 1:
      True{}
    case 32:
      True{}
    case 33:
      True{}
    case 34:
      True{}
    case _:
      False{}

# A thing presses a line it may press unless the line is secret, from
# whichever side it stands.
def Sim.thing.use.at(opens: Bool, +i: U32, w: S.Sim.Walk) -> S.Sim.Walk:
  match opens:
    case False{}:
      w
    case True{}:
      S.Walk{ok, id, +s} = w
      S.Walk{True{}, id, Sim.use.special(L.Level.special(S.State.level(s), i), i, False{}, s)}

def Sim.thing.use(+i: U32, w: S.Sim.Walk) -> S.Sim.Walk:
  S.Walk{ok, id, +s} = w
  Sim.thing.use.at(Bool.and(Sim.thing.use.special(L.Level.special(S.State.level(s), i)),
    Bool.not(Sim.secret(L.Level.line(S.State.level(s), i)))), i, S.Walk{ok, id, s})

def Sim.thing.uses(lines: List<&2, U32>, w: S.Sim.Walk) -> S.Sim.Walk:
  match lines:
    case []:
      w
    case i <> rest:
      Sim.thing.uses(rest, Sim.thing.use(i, w))

# The walk-over specials a thing that is not the player may fire. Doom's
# P_CrossSpecialLine allows seven, and the lift's retrigger, special 88,
# is the one ported.
def Sim.thing.cross.special(special: U32) -> Bool:
  match special:
    case 88:
      True{}
    case _:
      False{}

# A crossed line fires its special when a thing may fire it, else none.
def Sim.thing.cross.one(+special: U32, +line: U32, +s: S.State) -> S.State:
  Sim.cross.special(Bool.pick(U32, Sim.thing.cross.special(special), special, 0), line, s)

# The walk-over specials a thing's move crossed.
def Sim.thing.crossed(lines: List<&2, U32>, +s: S.State) -> S.State:
  match lines:
    case []:
      s
    case +line <> rest:
      Sim.thing.crossed(rest, Sim.thing.cross.one(L.Level.special(S.State.level(s), line), line, s))

# The sector's special
# --------------------

def Sim.sector.hurt(due: Bool, damage: U32, +s: S.State) -> S.State:
  match due:
    case False{}:
      s
    case True{}:
      S.Sim.damage.raw(H.Things.you(S.State.things(s)), damage, H.Thing.you(), H.Thing.you(), s)

def Sim.sector.leak(suit: Bool, +clock: U32, +s: S.State) -> S.State:
  match suit:
    case False{}:
      Sim.sector.hurt(U32.is_zero((clock .&. 31 : U32)), 20, s)
    case True{}:
      +drawn = S.Sim.drawn(s)
      Sim.sector.hurt(Bool.and(U32.is_lt(M.Random.at(S.State.rnd(drawn)), 5),
        U32.is_zero((clock .&. 31 : U32))), 20, drawn)

# P_PlayerInSpecialSector tests suit leakage before the damage interval.
def Sim.sector.damage(nukage: Bool, hellslime: Bool, +clock: U32, +s: S.State) -> S.State:
  match nukage hellslime:
    case True{} _:
      Sim.sector.hurt(Bool.and(U32.is_zero(I.Inventory.power.of(I.Inventory.pw_ironfeet(),
        S.Player.inv(S.State.player(s)))), U32.is_zero((clock .&. 31 : U32))), 5, s)
    case False{} True{}:
      Sim.sector.leak(Bool.not(U32.is_zero(I.Inventory.power.of(I.Inventory.pw_ironfeet(),
        S.Player.inv(S.State.player(s))))), clock, s)
    case False{} False{}:
      s

def Sim.sector.grounded(+grounded: Bool, +special: U32, clock: U32, s: S.State) -> S.State:
  Sim.sector.damage(Bool.and(grounded, U32.is_eq(special, 7)),
    Bool.and(grounded, U32.is_eq(special, 16)), clock, s)

def Sim.sector(+level: L.Level, clock: U32, +s: S.State) -> S.State:
  +sector = L.Level.sector_at(level, S.Player.x(S.State.player(s)), S.Player.y(S.State.player(s)))
  Sim.sector.grounded(U32.is_eq(S.Player.z(S.State.player(s)), L.Level.floor(level, sector)),
    L.Level.sector.special(S.State.level(s), sector), clock, s)

def Sim.sector.secret.count(counts: Bool, +sector: U32, s: S.State) -> S.State:
  match counts:
    case False{}:
      s
    case True{}:
      S.State{+player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn, totalsecret} = s
      S.State{S.Player.holding(player, I.Inventory.secret(S.Player.inv(player))),
        L.Level.sector.put(level, sector, 5, 0), things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn, totalsecret}

def Sim.sector.secret(+s: S.State) -> S.State:
  +sector = L.Level.sector_at(S.State.level(s), S.Player.x(S.State.player(s)), S.Player.y(S.State.player(s)))
  Sim.sector.secret.count(Bool.and(U32.is_eq(L.Level.sector.special(S.State.level(s), sector), 9),
    U32.is_eq(S.Player.z(S.State.player(s)), L.Level.floor(S.State.level(s), sector))), sector, s)
