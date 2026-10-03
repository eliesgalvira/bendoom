# The complete Freedoom E1M1 demo with monsters active. Chocolate Doom
# 3.1.1 reaches the exit on tic 2060 with these exact player and RNG
# values, then settles at 37% kills, 22% items, 0% secrets and 0:58.
import Base
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
  "exit tic " ++ U32.show(S.State.clock(s)) ++ " ended " ++ S.Sim.Exit.show(S.State.ended(s))
    ++ " health " ++ U32.show(I.Inventory.health(inv)) ++ " armour " ++ U32.show(I.Inventory.armour(inv))
    ++ " random " ++ U32.show(S.State.rnd(s))

def shown(play: N.Play) -> String:
  match play:
    case N.Playing{state, map}:
      "still playing"
    case N.Showing{N.Inter{screen, cnt, bcnt, shown, target, anims, mrnd, down}, after, next}:
      "intermission " ++ N.Inter.Screen.show(screen) ++ " shown" ++ N.Inter.counts.show(5n, shown, 0)

# Idle tics of the play, with no map to load in them.
def idled(n: Nat, +level: L.Level, play: N.Play) -> N.Play:
  match n:
    case 0n:
      play
    case 1n+m:
      idled(m, level, N.Play.Step.play(N.Play.step(level, K.Cmd.idle(), False{}, play)))

def report(+s: S.State) -> IO(Unit):
  do IO<Unit>:
    IO.print(finished(s))
    IO.print(position(S.State.player(s)))
    IO.print(S.Sim.Tally.show(S.Sim.tally(s)))
    IO.print(shown(idled(600n, S.State.level(s), N.Play.after(L.Name{1, 1}, s))))

def loaded(world: Array<U32> & L.Level, cmds: List<&2, K.Cmd>) -> IO(Unit):
  (mem, level) = world
  report(Tic.Sim.replay(cmds, Tic.State.start(level)))

def main() -> IO(Unit):
  do IO<Unit>:
    cmds : List<&2, K.Cmd> <- R.Route.read("tests/fixtures/freedoom.lmp")
    world : Array<U32> & L.Level <- L.Level.open(1, 1)
    loaded(world, cmds)

#|exit tic 2060 ended normal health 25 armour 82 random 22
#|position -364.361557 1296.127792 -128.000000
#|kills 11/29 items 11/49 secrets 0/4 time 2060
#|intermission count 10 shown 37 22 0 58 30
