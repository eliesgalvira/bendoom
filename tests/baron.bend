# Damage dice and state entry follow Chocolate Doom's info.c and p_enemy.c.
import Base
import ../src/things.bend as H
import ../src/sim.bend as S
import ../src/tic.bend as Tic
import ../src/inventory.bend as I
import ../src/fixed.bend as F
import ../src/vec.bend as V
import ../src/sound.bend as Sn
import ./fixtures/closed.bend as Fx

def Baron.melee() -> S.State:
  +s = Fx.Closed.at(Fx.Closed.player(2097152, 4194304, 0, 8388608), Fx.Closed.doors(), [],
    [H.Thing{7, 3003, 0, 4194304, 0, 0, 8388608, 1073741824, 0, 294, 8, 0, H.Thing.Hurt.of(3003)}])
  Tic.Sim.monster.attack(H.Thing.baronball(), 10, 7,
    S.Sim.thing.counted(7, H.Thing.hurt.target(), H.Thing.you(), s))

def Baron.fixture(+blast: Bool) -> S.State:
  Fx.Closed.at(Fx.Closed.player(13107200, 4194304, 0, 8388608), Fx.Closed.doors(), [],
    S.Sim.missile.thing(Fx.Closed.thing(8, H.Thing.baronball(), 2097152, 4194304, 2097152),
      0, 983040, 0, 65536, H.Thing.you()) <>
    Bool.pick(List<&2, H.Thing>, blast, [Fx.Closed.thing(9, 2035, 2097152, 4194304, 2097152)], []))

# Future rocket entry runs A_Explode; this adapter exercises the shared
# burst callback before its duration draw, using the existing blast action.
def Baron.explode(+id: U32, th: H.Thing, +state: U32, s: S.State) -> S.State:
  Tic.Sim.missile.enter.action(H.Explode{}, id, th, state, s)

def Baron.thing(m: Maybe<&2, H.Thing>) -> String:
  match m:
    case None{}:
      "none"
    case Some{+th}:
      "state " ++ U32.show(H.Thing.state(th)) ++ "/" ++ U32.show(H.Thing.tics(th))
        ++ " reaction " ++ U32.show(V.Vec.get(H.Thing.hurt(th), H.Thing.hurt.reaction()))
        ++ " angle " ++ U32.show(H.Thing.angle(th)) ++ " missile " ++ Bool.show(H.Thing.flagged(th, 65536))
        ++ " momentum " ++ F.Fixed.show(V.Vec.get(H.Thing.hurt(th), H.Thing.hurt.momx()))
        ++ " " ++ F.Fixed.show(H.Thing.momz(th))

def Baron.report(tag: String, +id: U32, +s: S.State) -> IO(Unit):
  IO.print(tag ++ " random " ++ U32.show(S.State.rnd(s)) ++ " health "
    ++ U32.show(I.Inventory.health(S.Player.inv(S.State.player(s)))) ++ " "
    ++ Baron.thing(S.State.thing(id, s)))

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print("baron melee/missile " ++ U32.show(H.Thing.melee(3003)) ++ " " ++ U32.show(H.Thing.missile(3003)))
    IO.print("balls speed/damage " ++ U32.show(H.Thing.speed(H.Thing.fireball())) ++ "/" ++ U32.show(H.Thing.damage(H.Thing.fireball()))
      ++ " " ++ U32.show(H.Thing.speed(H.Thing.baronball())) ++ "/" ++ U32.show(H.Thing.damage(H.Thing.baronball())))
    IO.print("map1/map8 volumes " ++ U32.show(Sn.Sound.volume.at(1, F.Fixed.of_map(384))) ++ "/"
      ++ U32.show(Sn.Sound.volume.at(8, F.Fixed.of_map(384))) ++ " "
      ++ U32.show(Sn.Sound.volume.at(1, F.Fixed.of_map(1200))) ++ "/"
      ++ U32.show(Sn.Sound.volume.at(8, F.Fixed.of_map(1200))) ++ " "
      ++ U32.show(Sn.Sound.volume.at(1, F.Fixed.of_map(1400))) ++ "/"
      ++ U32.show(Sn.Sound.volume.at(8, F.Fixed.of_map(1400))))
    Baron.report("claw", 7, Baron.melee())
    Baron.report("burst", 8, S.Sim.missile.burst.with(~Tic.Sim.missile.enter.acted, 8, Baron.fixture(False{})))
    Baron.report("vertical burst", 8, Tic.Sim.missile.z.hit(False{}, 8, Baron.fixture(False{})))
    Baron.report("blast entry", 8, S.Sim.missile.burst.with(~Baron.explode, 8, Baron.fixture(True{})))

#|baron melee/missile 292 292
#|balls speed/damage 655360/3 983040/8
#|map1/map8 volumes 52/54 0/15 0/15
#|claw random 2 health 90 state 294/8 reaction 8 angle 1073741824 missile False momentum 0.000000 0.000000
#|burst random 1 health 100 state 297/6 reaction 8 angle 0 missile False momentum 0.000000 0.000000
#|vertical burst random 1 health 100 state 297/6 reaction 8 angle 0 missile False momentum 0.000000 0.000000
#|blast entry random 2 health 100 state 297/5 reaction 8 angle 0 missile False momentum 0.000000 0.000000
