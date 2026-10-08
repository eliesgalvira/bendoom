# Vanilla info.c gives rocket speed20, damage20 and an8-tic explosion.
# P_ExplodeMissile enters A_Explode before shortening those tics. A barrel
# at the same point takes128 and draws8 for death; the rocket then draws109,
# losing1 tic. The same entry runs when P_ZMovement hits floor or ceiling.
import Base
import ../src/things.bend as H
import ../src/sim.bend as S
import ../src/tic.bend as Tic
import ../src/vec.bend as V
import ./fixtures/closed.bend as Fx

def Rocket.fixture() -> S.State:
  Fx.Closed.at(Fx.Closed.player(13107200, 4194304, 0, 8388608), Fx.Closed.doors(), [],
    [S.Sim.missile.thing(Fx.Closed.thing(8, H.Thing.rocket(), 2097152, 4194304, 2097152),
      0, 1310720, 0, 65536, H.Thing.you()), Fx.Closed.thing(9, 2035, 2097152, 4194304, 2097152)])

def Rocket.vertical(+momz: U32) -> S.State:
  +s = Rocket.fixture()
  +th = S.Sim.missile.thing(Fx.Closed.thing(8, H.Thing.rocket(), 2097152, 4194304, 2097152),
    0, 1310720, 0, momz, H.Thing.you())
  Tic.Sim.missile.z(th, 8, S.State.thing.put(8, th, s))

def Rocket.report.thing(tag: String, m: Maybe<&2, H.Thing>, rnd: U32) -> IO(Unit):
  match m:
    case None{}:
      IO.print(tag ++ " missing")
    case Some{+th}:
      IO.print(tag ++ " random " ++ U32.show(rnd) ++ " state " ++ U32.show(H.Thing.state(th))
        ++ "/" ++ U32.show(H.Thing.tics(th)) ++ " z " ++ U32.show(H.Thing.z(th))
        ++ " missile " ++ Bool.show(H.Thing.flagged(th, 65536))
        ++ " momentum " ++ U32.show(V.Vec.get(H.Thing.hurt(th), H.Thing.hurt.momx()))
        ++ "/" ++ U32.show(H.Thing.momz(th)))

def Rocket.report(tag: String, +s: S.State) -> IO(Unit):
  Rocket.report.thing(tag, S.State.thing(8, s), S.State.rnd(s))

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print("rocket speed/damage " ++ U32.show(H.Thing.speed(H.Thing.rocket())) ++ "/" ++ U32.show(H.Thing.damage(H.Thing.rocket())))
    IO.print("launcher ammo " ++ U32.show(H.Thing.Weapon.ammo(H.Thing.launcher())))
    Rocket.report("burst", S.Sim.missile.burst.with(~Tic.Sim.missile.enter.acted, 8, Rocket.fixture()))
    Rocket.report("floor", Rocket.vertical(4290772992))
    Rocket.report("ceiling", Rocket.vertical(6291456))

#|rocket speed/damage 1310720/20
#|launcher ammo 3
#|burst random 2 state 311/7 z 2097152 missile False momentum 0/0
#|floor random 2 state 311/7 z 0 missile False momentum 0/0
#|ceiling random 2 state 311/7 z 7864320 missile False momentum 0/0
