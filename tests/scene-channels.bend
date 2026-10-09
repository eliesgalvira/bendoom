# d_main.c calls S_UpdateSounds after TryRunTics in every scene.
# WI_updateStats emits pistol64 every fourth count tic. Eight expired
# barrel60 origins reject that start, then update frees them before
# the following count sound. Finale cleanup preserves live volumes.
import Base
import ./fixtures/closed.bend as Fx
import ../src/channel.bend as C
import ../src/sound.bend as Sn
import ../src/inter.bend as I
import ../src/sim.bend as S
import ../src/level.bend as L
import ../src/keys.bend as K
import ../src/finale.bend as Fi

def Test.expired(ids: List<&2, U32>) -> List<&2, Maybe<&2, C.Channel>>:
  match ids:
    case []:
      []
    case id <> rest:
      Some{C.Chan{100, Sn.Sound.barexp(), Sn.Thing{id}, 20, 81, 100}} <> Test.expired(rest)

def Test.counting.of(bcnt: U32, wi: I.Inter) -> I.Play:
  I.Inter{screen, cnt, clock, shown, target, anims, mrnd, down, pointer} = wi
  I.Showing{I.Inter{I.Count{2}, 0, bcnt, shown, target, anims, mrnd, down, pointer},
    Fx.Closed.state(Fx.Closed.player(0, 0, 0, 8388608), L.Level.room(0, 128), 0),
    I.Trip{L.Name{1, 1}, L.Name{1, 2}, False{}}}

def Test.counting(bcnt: U32) -> I.Play:
  Test.counting.of(bcnt, I.Inter.start(S.Tally{1, 0, 0, 1, 1, 1, 0}, 30, 0, 0))

def Test.step(bcnt: U32) -> I.Play.Step:
  I.Play.step(L.Level.room(0, 128), K.Cmd.idle(), Test.counting(bcnt))

def Test.hear(step: I.Play.Step, chans: List<&2, Maybe<&2, C.Channel>>) -> List<&2, Maybe<&2, C.Channel>>:
  I.Step{play, events} = step
  C.Channel.hear([C.Sound{Sn.Sound.pistol(), 0, 22516}], events, chans)

def Test.slot(c: Maybe<&2, C.Channel>) -> String:
  match c:
    case None{}:
      "empty"
    case Some{C.Chan{at, sfx, source, left, right, end}}:
      U32.show(sfx) ++ " " ++ U32.show(at) ++ " " ++ U32.show(end) ++ " " ++ U32.show(left) ++ " " ++ U32.show(right)

def Test.at(chans: List<&2, Maybe<&2, C.Channel>>, n: Nat) -> String:
  Test.slot(Maybe.default(&2, Maybe<&2, C.Channel>, List.get(&2, Maybe<&2, C.Channel>, chans, n), None{}))

def main() -> IO(Unit):
  +rejected = Test.hear(Test.step(3), Test.expired([1, 2, 3, 4, 5, 6, 7, 8]))
  +cleaned = I.Play.channels(I.Play.Step.play(Test.step(3)), rejected)
  +ending = I.Play.channels(I.Ending{Fi.Finale.start()},
    [Some{C.Chan{100, Sn.Sound.barexp(), Sn.Thing{1}, 20, 81, 100}},
      Some{C.Chan{0, Sn.Sound.barexp(), Sn.Thing{2}, 20, 81, 100}}])
  do IO<Unit>:
    IO.print("count start " ++ Test.at(rejected, 0n))
    IO.print("count update " ++ Test.at(cleaned, 0n))
    IO.print("next count " ++ Test.at(Test.hear(Test.step(7), cleaned), 0n))
    IO.print("finale expired " ++ Test.at(ending, 0n))
    IO.print("finale live " ++ Test.at(ending, 1n))
#|count start 82 100 100 20 81
#|count update empty
#|next count 1 0 22516 63 64
#|finale expired empty
#|finale live 82 0 100 20 81
