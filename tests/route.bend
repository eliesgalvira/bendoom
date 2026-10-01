# The complete Freedoom E1M1 demo with monsters active. Chocolate Doom
# 3.1.1 reaches the exit on tic 2060 with these exact player and RNG
# values, then settles at 37% kills, 22% items, 0% secrets and 0:58.
import Base
import ../src/bytes.bend as B
import ../src/wad.bend as W
import ../src/level.bend as L
import ../src/keys.bend as K
import ../src/sim.bend as S
import ../src/tic.bend as Tic
import ../src/inventory.bend as I
import ../src/fixed.bend as F
import ../src/inter.bend as N
import ./fixtures/route.bend as R

def position(p: S.Player) -> String:
  S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt} = p
  "position " ++ F.Fixed.show(x) ++ " " ++ F.Fixed.show(y) ++ " " ++ F.Fixed.show(z)

def finished(+s: S.State) -> String:
  +inv = S.Player.inv(S.State.player(s))
  "exit tic " ++ U32.show(S.State.clock(s)) ++ " ended " ++ Bool.show(S.State.ended(s))
    ++ " health " ++ U32.show(I.Inventory.health(inv)) ++ " armour " ++ U32.show(I.Inventory.armour(inv))
    ++ " random " ++ U32.show(S.State.rnd(s))

def shown(play: N.Play) -> String:
  match play:
    case N.Playing{state}:
      "still playing"
    case N.Showing{N.Inter{screen, cnt, bcnt, shown, target, anims, mrnd, down}}:
      "intermission " ++ N.Inter.Screen.show(screen) ++ " shown" ++ N.Inter.counts.show(5n, shown, 0)

def report(+s: S.State) -> IO(Unit):
  do IO<Unit>:
    IO.print(finished(s))
    IO.print(position(S.State.player(s)))
    IO.print(S.Sim.Tally.show(S.Sim.tally(s)))
    IO.print(shown(N.Play.replay(List.replicate(K.Cmd, 600n, K.Cmd.idle()), S.State.level(s), N.Play.after(s))))

def loaded(world: Array<U32> & L.Level, cmds: List<&2, K.Cmd>) -> IO(Unit):
  (mem, level) = world
  report(Tic.Sim.replay(cmds, Tic.State.start(level)))

def main() -> IO(Unit):
  do IO<Unit>:
    cmds : List<&2, K.Cmd> <- R.Route.read("tests/fixtures/freedoom.lmp")
    path : String <- IO.try(String, IO.get_env("BENDOOM_IWAD"))
    bytes : Array<U32> <- IO.try(Array<U32>, B.Bytes.read(path))
    loaded(L.Level.load(W.Wad.dir(bytes)), cmds)

#|exit tic 2060 ended True health 25 armour 82 random 22
#|position -364.361557 1296.127792 -128.000000
#|kills 11/29 items 11/49 secrets 0/4 time 2060
#|intermission count 10 shown 37 22 0 58 30
