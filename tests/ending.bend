# Expected damage and exit results follow p_inter.c:851 and p_spec.c:1074.
import Base
import ../src/level.bend as L
import ../src/sim.bend as S
import ../src/special.bend as Sp
import ../src/inventory.bend as I
import ../src/things.bend as H
import ../src/tic.bend as Tic
import ./fixtures/closed.bend as Fx

def Ending.state(health: U32, armour: U32, suit: U32, special: U32) -> S.State:
  Fx.Closed.state(S.Player.holding(Fx.Closed.player(2097152, 4194304, 0, 8388608),
    Fx.Closed.inv([Fx.Health{health}, Fx.Armour{armour, 1}, Fx.Power{I.Inventory.pw_ironfeet(), suit}])),
    L.Level.sector.put(Fx.Closed.doors(), 0, 5, special), 0)

def Ending.damage(+s: S.State) -> S.State:
  S.Sim.damage.raw(H.Things.you(S.State.things(s)), 100, H.Thing.you(), H.Thing.you(), s)

def Ending.report(tag: String, +s: S.State) -> IO(Unit):
  IO.print(tag ++ " health " ++ U32.show(I.Inventory.health(S.Player.inv(S.State.player(s))))
    ++ " armour " ++ U32.show(I.Inventory.armour(S.Player.inv(S.State.player(s))))
    ++ " end " ++ S.Sim.Exit.show(S.State.ended(s)) ++ " random " ++ U32.show(S.State.rnd(s)))

def Ending.boss.state(name: L.Level.Name, health: U32, other: Bool) -> S.State:
  Fx.Closed.at(S.Player.holding(Fx.Closed.player(2097152, 4194304, 0, 8388608),
    Fx.Closed.inv([Fx.Health{health}])),
    L.Level.named(name, L.Level.sector.put(L.Level.plane.put(Fx.Closed.doors(), 1, False{}, 2097152), 1, 6, 666)), [],
    H.Thing.entering(H.Thing.counted(Fx.Closed.thing(7, 3003, 2097152, 4194304, 0), H.Thing.hurt.health(), 0), 278)
    <> Bool.pick(List<&2, H.Thing>, other, [Fx.Closed.thing(8, 3003, 6291456, 4194304, 0)], []))

def Ending.boss.report(tag: String, +s: S.State) -> IO(Unit):
  IO.print(tag ++ " movers " ++ Nat.show(List.length(&2, S.Thinker, Fx.Closed.running(s)))
    ++ " end " ++ S.Sim.Exit.show(S.State.ended(s)))

def Ending.boss(name: L.Level.Name, health: U32, other: Bool) -> S.State:
  Tic.Sim.thing.set(1n, S.Acted{Some{279}, Ending.boss.state(name, health, other)}, 7)

def main() -> IO(Unit):
  do IO<Unit>:
    Ending.report("pulse suit", Sp.Sim.sector.grounded(True{}, 11, 32, Ending.state(33, 66, 10, 11)))
    Ending.report("threshold", Sp.Sim.sector.grounded(True{}, 11, 33, Ending.state(10, 0, 0, 11)))
    Ending.report("above threshold", Sp.Sim.sector.grounded(True{}, 11, 33, Ending.state(11, 0, 0, 11)))
    Ending.report("airborne", Sp.Sim.sector.grounded(False{}, 11, 32, Ending.state(10, 0, 0, 11)))
    Ending.report("lethal armour", Ending.damage(Ending.state(10, 66, 0, 11)))
    Ending.report("lethal bare", Ending.damage(Ending.state(10, 0, 0, 11)))
    Ending.report("other sector", Ending.damage(Ending.state(10, 0, 0, 0)))
    Ending.boss.report("last boss", Ending.boss(L.Name{1, 8}, 100, False{}))
    Ending.boss.report("live boss", Ending.boss(L.Name{1, 8}, 100, True{}))
    Ending.boss.report("dead player", Ending.boss(L.Name{1, 8}, 0, False{}))
    Ending.boss.report("wrong map", Ending.boss(L.Name{1, 7}, 100, False{}))
    Ending.boss.report("wrong episode", Ending.boss(L.Name{2, 8}, 100, False{}))

#|pulse suit health 19 armour 60 end none random 1
#|threshold health 10 armour 0 end normal random 0
#|above threshold health 11 armour 0 end none random 0
#|airborne health 10 armour 0 end none random 0
#|lethal armour health 4 armour 63 end none random 1
#|lethal bare health 1 armour 0 end none random 1
#|other sector health 0 armour 0 end none random 1
#|last boss movers 1 end none
#|live boss movers 0 end none
#|dead player movers 0 end none
#|wrong map movers 0 end none
#|wrong episode movers 0 end none
