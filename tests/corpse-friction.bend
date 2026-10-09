# p_mobj.c's corpse edge guard, using E1M7 tic328's incoming momentum.
# The centre sector floor is32; the overlapping step holds floorz40.
# A corpse keeps momentum above a quarter unit there. Living players,
# corpses on their sector floor and the exact quarter-unit boundary
# decay by FRICTION0xe800; an airborne player keeps its momentum.
import Base
import ./fixtures/closed.bend as Fx
import ../src/sim.bend as S
import ../src/keys.bend as K
import ../src/level.bend as L

def momentum(+p: S.Player) -> String:
  Fx.words([S.Player.momx(p), S.Player.momy(p)])

def run(health: U32, momx: U32, momy: U32, z: U32, floorz: U32) -> String:
  +p = {S.Player{0, 0, z, 0, momx, momy, 0, floorz, 8388608, 2686976, 0, 2686976, [],
    Fx.Closed.inv([Fx.Health{health}]), Fx.Closed.unarmed(), S.Sim.Hurt.start()} : S.Player}
  momentum(S.Sim.friction(L.Level.room(32, 128), K.Cmd.idle(), p))

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print("corpse edge" ++ run(0, 4294775636, 310343, 2621440, 2621440))
    IO.print("living edge" ++ run(100, 4294775636, 310343, 2621440, 2621440))
    IO.print("corpse sector floor" ++ run(0, 4294775636, 310343, 2097152, 2097152))
    IO.print("quarter unit" ++ run(0, 16384, 0, 2621440, 2621440))
    IO.print("past quarter unit" ++ run(0, 16385, 0, 2621440, 2621440))
    IO.print("past negative quarter" ++ run(0, 4294950911, 0, 2621440, 2621440))
    IO.print("airborne" ++ run(0, 4294775636, 310343, 2686976, 2621440))
#|corpse edge 4294775636 310343
#|living edge 4294793604 281248
#|corpse sector floor 4294793604 281248
#|quarter unit 14848 0
#|past quarter unit 16385 0
#|past negative quarter 4294950911 0
#|airborne 4294775636 310343
