# P_TryMove fires accepted momentum crossings before friction.
# p_spec.c admits non-projectile mobjs to special88, including corpses;
# p_map.c suppresses crossings with MF_TELEPORT or MF_NOCLIP.
# The shared literal level's west face is x64. A box moves from63 to65;
# its14-unit corpse fits, while144 units cannot fit under ceiling128.
import Base
import ./fixtures/closed.bend as Fx
import ../src/sim.bend as S
import ../src/tic.bend as Tic
import ../src/things.bend as H
import ../src/vec.bend as V
import ../src/sound.bend as Sn

def started(events: List<&2, Sn.Sound.Event>) -> Bool:
  match events:
    case []:
      False{}
    case Sn.Start{sfx, source, vol, sep} <> rest:
      Bool.or(U32.is_eq(sfx, Sn.Sound.pstart()), started(rest))
    case _ <> rest:
      started(rest)

def run(special: U32, +kind: U32, flags: U32, height: U32, momx: U32) -> Bool:
  +hurt = V.Vec.set(V.Vec.set(V.Vec.set(V.Vec.set(H.Thing.Hurt.of(kind), H.Thing.hurt.health(), 0),
    H.Thing.hurt.flags(), flags), H.Thing.hurt.height(), height), H.Thing.hurt.radius(), 1310720)
  +th = S.Sim.thing.mom(H.Thing{0, kind, 4128768, 4194304, 0, 0, 8388608, 0, 0, 159,
    4294967295, 0, hurt}, momx, 0)
  +s = Fx.Closed.at(Fx.Closed.player(13107200, 4194304, 0, 8388608),
    S.State.level(Fx.Closed.switched(special)), [], [th])
  started(S.State.sounds(Tic.Sim.thing(0, s)))

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print("corpse crossing " ++ Bool.show(run(88, 3001, 5243938, 917504, 131072)))
    IO.print("noncorpse crossing " ++ Bool.show(run(88, 3001, 4195334, 3670016, 131072)))
    IO.print("no momentum " ++ Bool.show(run(88, 3001, 5243938, 917504, 0)))
    IO.print("blocked move " ++ Bool.show(run(88, 3001, 5243938, 9437184, 131072)))
    IO.print("player only special " ++ Bool.show(run(5, 3001, 5243938, 917504, 131072)))
    IO.print("teleport flag " ++ Bool.show(run(88, 3001, 5276706, 917504, 131072)))
    IO.print("noclip flag " ++ Bool.show(run(88, 3001, 5248034, 917504, 131072)))
    IO.print("missile " ++ Bool.show(run(88, H.Thing.rocket(), 67088, 917504, 131072)))
    IO.print("exploded projectile " ++ Bool.show(run(88, H.Thing.rocket(), 512, 917504, 131072)))
#|corpse crossing True
#|noncorpse crossing True
#|no momentum False
#|blocked move False
#|player only special False
#|teleport flag False
#|noclip flag False
#|missile False
#|exploded projectile False
