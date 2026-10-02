# A measurement, not a test: 100 s of the song SONG names (D_E1M1 if
# unset) from the WAD BENDOOM_IWAD names, as the deck plays it to the
# mixer, in 3500 takes of a tic's 1260 frames, and what a tic of it
# costs. Build natively and run it on one thread:
#
#   bend bench/music.bend -o music
#   SONG=D_E1M6 ./music --threads 1
import Base
import ../src/song.bend as S

def Bench.dropped(p: S.Song.Deck & List<&2, U32>) -> S.Song.Deck:
  (deck, frames) = p
  deck

def Bench.play(n: Nat, deck: S.Song.Deck) -> S.Song.Deck:
  match n:
    case 0n:
      deck
    case 1n+m:
      Bench.play(m, Bench.dropped(S.Song.Deck.take(1260, deck)))

def Bench.report(+song: String, +t0: Nat, +t1: Nat) -> String:
  "3500 tics of " ++ song ++ " in " ++ Nat.show(Nat.sub(t1, t0)) ++ " ms, "
    ++ Nat.show(Nat.div(Nat.mul(Nat.sub(t1, t0), 1000n), 3500n)) ++ " us a tic"

def Bench.timed(+song: String, +t0: Nat, played: S.Song.Deck) -> IO(Unit):
  do IO<Unit>:
    t1 : Nat <- IO.now()
    IO.print(Bench.report(song, t0, t1))

def Bench.run(+song: String, deck: S.Song.Deck, +t0: Nat) -> IO(Unit):
  Bench.timed(song, t0, Bench.play(3500n, S.Song.Deck.change(song, deck)))

def main() -> IO(Unit):
  do IO<Unit>:
    named : Result<&1, &1, U32 & String, String> <- IO.get_env("SONG")
    +song : String = Result.default(&1, &1, U32 & String, String, named, "D_E1M1")
    deck : S.Song.Deck <- S.Song.Deck.load([song])
    t0 : Nat <- IO.now()
    Bench.run(song, deck, t0)
