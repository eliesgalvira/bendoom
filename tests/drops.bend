# P_KillMobj spawns the human's item after its death-state draw.
# P_GiveAmmo gives 5 bullets for a dropped clip; P_GiveWeapon gives
# 4 shells for a dropped shotgun. PIT_ChangeSector removes only dropped
# items, makes an obstructing corpse S_GIBS with zero dimensions, and
# reports a living shootable obstruction to the mover.
import Base
import ../src/level.bend as L
import ../src/sim.bend as S
import ../src/special.bend as Sp
import ../src/tic.bend as Tic
import ../src/things.bend as H
import ../src/inventory.bend as I
import ../src/vec.bend as V
import ./fixtures/combat.bend as C
import ../src/fixed.bend as F
import ../src/keys.bend as K

def spawned(kind: U32) -> S.State:
  S.Sim.spawn(H.Thing.info(kind), 4194304, 0, H.Thing.onfloor(), Tic.State.start(L.Level.room(0, 128)))

def killed(kind: U32) -> S.State:
  Tic.Sim.damage(0, 100, H.Thing.you(), H.Thing.you(), spawned(kind))

def drop(m: Maybe<&2, H.Thing>) -> String:
  match m:
    case None{}:
      "missing"
    case Some{+th}:
      U32.show(H.Thing.kind(th)) ++ " dropped " ++ Bool.show(H.Thing.flagged(th, 131072))

def clipped(+id: U32, +s: S.State) -> S.Sim.Try:
  Sp.Sim.change.thing(S.State.thing(id, s), id, L.Level.room(0, 8), True{}, S.State.player(s), S.State.things(s))

def lifted(+s: S.State) -> S.Sim.Try:
  Sp.Sim.change.thing(S.State.thing(1, s), 1, L.Level.room(120, 128), True{}, S.State.player(s), S.State.things(s))

def things(t: S.Sim.Try) -> H.Things:
  S.Try{ok, p, things} = t
  things

def body(m: Maybe<&2, H.Thing>) -> String:
  match m:
    case None{}:
      "missing"
    case Some{+th}:
      "state " ++ U32.show(H.Thing.state(th)) ++ " height " ++ U32.show(H.Thing.height(th))
        ++ " radius " ++ U32.show(V.Vec.get(H.Thing.hurt(th), H.Thing.hurt.radius()))
        ++ " solid " ++ Bool.show(H.Thing.flagged(th, 2))

def items(inv: I.Inventory) -> U32:
  I.Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus, line, kills, secrets} = inv
  items

def pickup(got: I.Inventory & H.Things, ammo: U32) -> String:
  (+inv, things) = got
  "rounds " ++ U32.show(I.Inventory.rounds(ammo, inv)) ++ " gone "
    ++ Bool.show(Maybe.is_none(&2, H.Thing, H.Things.get(things, 1)))
    ++ " items " ++ U32.show(items(inv))

def taken(+s: S.State, ammo: U32) -> String:
  pickup(S.Sim.touch.thing(S.State.thing(1, s), 4194304, 0, 0, I.Inventory.start(),
    L.Level.blockmap_of(S.State.level(s)), S.State.things(s)), ammo)

def health(m: Maybe<&2, H.Thing>) -> U32:
  match m:
    case None{}:
      0
    case Some{th}:
      H.Thing.health(th)

def fought(+s: S.State) -> String:
  "door fight tic " ++ U32.show(S.State.clock(s)) ++ " health " ++ U32.show(health(S.State.thing(265, s)))
    ++ " random " ++ U32.show(S.State.rnd(s))

def dropped(ts: List<&2, H.Thing>) -> U32:
  match ts:
    case []:
      0
    case th <> rest:
      (Bool.to_u32(H.Thing.flagged(th, 131072)) + dropped(rest) : U32)

def crushed(+s: S.State) -> String:
  "door corpse " ++ body(S.State.thing(265, s)) ++ " dropped "
    ++ U32.show(dropped(H.Things.list(S.State.things(s)))) ++ " random " ++ U32.show(S.State.rnd(s))

def opening(ts: List<&2, S.Thinker>) -> Bool:
  match ts:
    case []:
      False{}
    case S.Mover{80, ceiling, speed, S.Travel{down, dest} <> steps, plan, noise} <> rest:
      Bool.not(down)
    case _ <> rest:
      opening(rest)

# Chocolate Doom reopens door 80 on tic 6 when its 54-unit gap would
# crush the living zombieman. The WAD starts this door at height -72.
def reopened(level: L.Level) -> S.State:
  Tic.Sim.replay([K.Cmd.idle(), K.Cmd.demo(0, 0, 0, 2), K.Cmd.idle(), K.Cmd.demo(0, 0, 0, 2),
    K.Cmd.idle(), K.Cmd.idle()], C.Combat.door(L.Level.plane.put(level, 80, True{}, 4290248704)))

def living(+s: S.State) -> String:
  "living door ceiling " ++ F.Fixed.show(L.Level.ceil(S.State.level(s), 80))
    ++ " opening " ++ Bool.show(opening(S.State.thinkers(s)))
    ++ " health " ++ U32.show(health(S.State.thing(265, s)))

# Chocolate Doom's Freedoom key route, tic 553: a shotgun pellet pushes
# demon 184 by (24009, 5246), but its box spans floors 136 and 64.
# P_XYMovement refuses that drop and clears both momentum components.
def ledge.moved(+th: H.Thing, +s: S.State) -> S.State:
  S.Sim.thing.xy.with(~Tic.Sim.thing.move, 184, th, S.State.thing.put(184, th, s))

def ledge.at(+level: L.Level, +flags: U32) -> S.State:
  +th = H.Thing.mobj(H.Thing.info(3002), level, 184, 104767616, 4268374368, 8912896, 0)
  ledge.moved(S.Sim.thing.mom(H.Thing.hurting(th,
      V.Vec.set(H.Thing.hurt(th), H.Thing.hurt.flags(), flags)), 24009, 5246),
    S.State.thing.moved(184, 104767616, 4268374368, Tic.State.start(level)))

def ledge(level: L.Level, flags: U32) -> S.State:
  ledge.at(L.Level.plane.put(level, 103, False{}, 4194304), flags)

def pushed(m: Maybe<&2, H.Thing>) -> String:
  match m:
    case None{}:
      "missing"
    case Some{+th}:
      "xy " ++ U32.show(H.Thing.x(th)) ++ " " ++ U32.show(H.Thing.y(th))
        ++ " momentum " ++ U32.show(H.Thing.momx(th)) ++ " " ++ U32.show(H.Thing.momy(th))

# Chocolate Doom's isolated zombieman is given the player as its target
# behind shut door 80. It opens the door itself, then chases through it.
def chasing.thing(m: Maybe<&2, H.Thing>, +s: S.State) -> S.State:
  match m:
    case None{}:
      s
    case Some{th}:
      +run = H.Thing.entering(th, 89)
      S.State.thing.put(265, H.Thing.hurting(run,
        V.Vec.set(H.Thing.hurt(run), H.Thing.hurt.target(), H.Things.you(S.State.things(s)))), s)

def chasing(+s: S.State) -> S.State:
  chasing.thing(S.State.thing(265, s), s)

def opened(+s: S.State) -> String:
  "chase door ceiling " ++ F.Fixed.show(L.Level.ceil(S.State.level(s), 80))
    ++ " " ++ pushed(S.State.thing(265, s)) ++ " random " ++ U32.show(S.State.rnd(s))

def actual(w: Array<U32> & L.Level) -> IO(Unit):
  (mem, +level) = w
  do IO<Unit>:
    IO.print(fought(C.Combat.fought(level)))
    IO.print(crushed(C.Combat.crushed(level)))
    IO.print(living(reopened(level)))
    IO.print(opened(Tic.Sim.replay(List.replicate(K.Cmd, 100n, K.Cmd.idle()), chasing(
      Tic.State.at(C.Combat.isolated(level, 265, 448, 2128, 3004), L.Start{29360128, 134217728, 1073741824})))))
    IO.print("ledge push " ++ pushed(S.State.thing(184, ledge(level, 4194310))))
    IO.print("dropoff push " ++ pushed(S.State.thing(184, ledge(level, 4195334))))

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print("pain retaliation " ++ Bool.show(Maybe.default(&2, Bool,
      Maybe.map(&2, H.Thing, Bool, th => H.Thing.flagged(th, 64),
        S.State.thing(0, Tic.Sim.damage(0, 5, H.Thing.you(), H.Thing.you(), spawned(3004)))), False{})))
    IO.print("zombieman " ++ drop(S.State.thing(1, killed(3004))) ++ " draws " ++ U32.show(S.State.rnd(killed(3004))))
    IO.print("shotgun guy " ++ drop(S.State.thing(1, killed(9))) ++ " draws " ++ U32.show(S.State.rnd(killed(9))))
    IO.print("clip " ++ taken(killed(3004), I.Inventory.am_clip()))
    IO.print("shotgun " ++ taken(killed(9), I.Inventory.am_shell()))
    IO.print("corpse " ++ body(H.Things.get(things(clipped(0, killed(3004))), 0)))
    IO.print("dropped removed " ++ Bool.show(Maybe.is_none(&2, H.Thing, H.Things.get(things(clipped(1, killed(3004))), 1))))
    IO.print("placed kept " ++ Bool.show(Bool.not(Maybe.is_none(&2, H.Thing, H.Things.get(things(clipped(0, spawned(2007))), 0)))))
    IO.print("living fits " ++ Bool.show(S.Sim.Try.ok(clipped(0, spawned(3004)))))
    IO.print("lift removed drop " ++ Bool.show(Maybe.is_none(&2, H.Thing, H.Things.get(things(lifted(killed(3004))), 1))))
    world : Array<U32> & L.Level <- L.Level.open(1, 1)
    actual(world)

#|pain retaliation True
#|zombieman 2007 dropped True draws 3
#|shotgun guy 2001 dropped True draws 3
#|clip rounds 55 gone True items 0
#|shotgun rounds 4 gone True items 0
#|corpse state 50 height 0 radius 0 solid False
#|dropped removed True
#|placed kept True
#|living fits False
#|lift removed drop True
#|door fight tic 40 health 15 random 34
#|door corpse state 50 height 0 radius 0 solid False dropped 0 random 136
#|living door ceiling -72.000000 opening True health 20
#|chase door ceiling -4.000000 xy 29211840 136463168 momentum 0 0 random 73
#|ledge push xy 104767616 4268374368 momentum 0 0
#|dropoff push xy 104791625 4268379614 momentum 21758 4754
