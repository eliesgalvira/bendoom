# Chocolate p_enemy.c and p_mobj.c use P_SubRandom shifts 21 and 20.
# rndtable's first draws are 8, 109, 220; spawning consumes the first.
import Base
import ../src/sim.bend as S
import ../src/tic.bend as Tic
import ../src/inventory.bend as I
import ../src/things.bend as H
import ./fixtures/closed.bend as Fx
import ../src/vec.bend as V

def Fuzz.state(tics: U32) -> S.State:
  Fx.Closed.state(S.Player.holding(Fx.Closed.player(13107200, 0, 0, 8388608),
    I.Inventory.power(I.Inventory.pw_invisibility(), tics, I.Inventory.start())), Fx.Closed.level(0, V.Leaf{0}, 0), 0)

def Fuzz.face(tics: U32) -> S.State:
  Tic.Sim.chase.face(7, H.Thing.you(), Fx.Closed.at(
    S.Player.holding(Fx.Closed.player(13107200, 0, 0, 8388608),
      I.Inventory.power(I.Inventory.pw_invisibility(), tics, I.Inventory.start())),
    Fx.Closed.level(0, V.Leaf{0}, 0), [], [Fx.Closed.thing(7, 3004, 0, 0, 0)]))

def Fuzz.missile(tics: U32) -> S.State:
  +s = Fuzz.state(tics)
  S.Sim.missile.spawn(H.Thing.fireball(), S.Body{7, 0, 0, 0, 1310720, 3670016, 4},
    S.Player.body(S.State.player(s), H.Thing.you()), 7, s)

def Fuzz.thing(m: Maybe<&2, H.Thing>) -> String:
  match m:
    case None{}:
      "none"
    case Some{th}:
      "angle " ++ U32.show(H.Thing.angle(th))

def Fuzz.report(tag: String, id: U32, +s: S.State) -> IO(Unit):
  IO.print(tag ++ " random " ++ U32.show(S.State.rnd(s)) ++ " " ++ Fuzz.thing(S.State.thing(id, s)))

def main() -> IO(Unit):
  do IO<Unit>:
    Fuzz.report("face shadow", 7, Fuzz.face(1))
    Fuzz.report("face clear", 7, Fuzz.face(0))
    Fuzz.report("missile shadow", 0, Fuzz.missile(1))
    Fuzz.report("missile clear", 0, Fuzz.missile(0))

#|face shadow random 2 angle 4083154944
#|face clear random 0 angle 0
#|missile shadow random 3 angle 4178575360
#|missile clear random 1 angle 0
