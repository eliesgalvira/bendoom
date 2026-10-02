# A measurement, not a test: the game's own loop in its window for 600
# frames, the frames a second it made, and, with the song and the tics'
# sounds mixed, on how many of them the device's queue was empty before
# the write; the first always is, since nothing has been written yet.
# The script below is the one that keeps channels busy: its door opens
# and closes over the music. WALK=1 holds the run, up and left keys, so
# the player runs in circles some 135 units across through the start
# room and the hall beyond its gate, sliding along what it meets;
# without it the player stands at the start. SCRIPT
# is replayed before the first frame (tools/script.bend has its form);
# the one below walks from the start to the first door and uses it, so
# the frames watch it open, wait and close under the lights. The
# frame-rate bar's scene, the blue key's room, is milestone 5's ticket
# 12's script. Build natively and run it where a window can open, or on
# a private display and sound card that drains at the real rate and
# plays nowhere:
#
#   bend bench/window.bend -o window
#   ./window; WALK=1 ./window
#   SCRIPT="35,50,0,0,0 40,0,0,0,0 1,0,0,14,0 50,50,0,0,0 1,0,0,32,0 10,50,0,0,0 1,0,0,18,0 12,50,0,0,0 10,0,0,0,0 1,0,0,0,1" ./window
#   WALK=1 tools/listen.nu game --binary ./window --sounds
import Base
import ../src/level.bend as L
import ../src/gfx.bend as G
import ../src/keys.bend as K
import ../src/game.bend as M
import ../tools/script.bend as T

def Bench.input(+walk: Bool) -> K.Input:
  K.Input{K.Keys{walk, False{}, walk, False{}, False{}, False{}, walk, False{}, False{}, K.Keys.numbers.none()}, 0}

def Bench.rate(+t0: Nat, +t1: Nat) -> String:
  Nat.show(Nat.div(U32.to_nat(600000), Nat.sub(t1, t0))) ++ " frames a second (600 frames in "
    ++ Nat.show(Nat.sub(t1, t0)) ++ " ms)"

def Bench.dry(dry: Maybe<U32>) -> String:
  match dry:
    case None{}:
      ", silent"
    case Some{n}:
      ", the device's queue empty on " ++ U32.show(n) ++ " of them"

def Bench.run(+t0: Nat, input: K.Input, script: List<&2, K.Cmd>, world: Array<U32> & G.Gfx & L.Level) ->
  IO(Unit):
  do IO<Unit>:
    dry : Maybe<U32> <- M.Game.start(600n, input, script, None{}, t0, world)
    t1 : Nat <- IO.now()
    IO.print(Bench.rate(t0, t1) ++ Bench.dry(dry))

def main() -> IO(Unit):
  do IO<Unit>:
    walk : Result<&1, &1, U32 & String, String> <- IO.get_env("WALK")
    script : Result<&1, &1, U32 & String, String> <- IO.get_env("SCRIPT")
    world : Array<U32> & G.Gfx & L.Level <- G.Gfx.open(1, 1)
    t0 : Nat <- IO.now()
    Bench.run(t0, Bench.input(Result.is_done(&1, &1, U32 & String, String, walk)),
      List.concat(&2, K.Cmd, T.Script.runs(String.split(Result.default(&1, &1, U32 & String, String, script, ""), ' '))),
      world)
