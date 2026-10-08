# A frame as hex rows: the map the header of the demo file DEMO names,
# from the WAD named by BENDOOM_IWAD, the demo's tics replayed through
# the play from player 1's start, and the frame drawn as the game draws
# it, printed as a line of the palette's index and then 200 lines of 320
# palette indices, two hex digits each. A demo that takes the exit
# leaves the tally showing, and its tics after the exit are the tally's,
# their attack or use the press that accelerates it, and then the next
# map's. tools/oracle.nu writes the demo and diffs the frame against
# Chocolate Doom's after the same one.
#
#   bend tools/frame.bend -o frame
#   DEMO=script.lmp ./frame
#   BENDOOM_MESSAGES=1 DEMO=script.lmp ./frame
import Base
import ./script.bend as T
import ../src/bytes.bend as B
import ../src/level.bend as L
import ../src/gfx.bend as G
import ../src/keys.bend as K
import ../src/inter.bend as I
import ../src/demo.bend as D

def Frame.line(p: Array<U32> & List<&2, U32>) -> Array<U32> & String:
  (mem, xs) = p
  (mem, B.Bytes.hex(xs))

def Frame.print(p: Array<U32> & String) -> IO(Array<U32>):
  (mem, text) = p
  do IO<Array<U32>>:
    IO.print(text)
    return mem

def Frame.rows(n: Nat, +row: U32, mem: Array<U32>) -> IO(Unit):
  match n:
    case 0n:
      IO.pure(Unit, Unit{})
    case 1n+m:
      do IO<Unit>:
        next : Array<U32> <- Frame.print(Frame.line(B.Bytes.each(~U32, ~B.Bytes.at,
          B.Bytes.fields(320n, (G.Gfx.frame() + row * 320 : U32), 1, [0]), mem)))
        Frame.rows(m, (row + 1 : U32), next)

def Frame.palette(p: Array<U32> & U32) -> Array<U32> & String:
  (mem, palette) = p
  (mem, B.Bytes.hex([palette]))

def Frame.draw(messages: Bool, ran: I.Play.Run) -> IO(Unit):
  I.Ran{I.World{play, mem, gfx, tables, level}, sounds} = ran
  do IO<Unit>:
    rest : Array<U32> <- Frame.print(Frame.palette(I.Play.frame(tables, gfx, play, messages, mem)))
    Frame.rows(200n, 0, rest)

def Frame.load(messages: Bool, script: List<&2, K.Cmd>, +map: L.Level.Name) -> IO(Unit):
  do IO<Unit>:
    w : Array<U32> & G.Gfx & L.Level <- I.Play.open(map)
    ran : I.Play.Run <- I.Play.run(script, I.Ran{I.Play.World.start(w), []})
    Frame.draw(messages, ran)

def Frame.demo(messages: Bool, +demo: List<&2, U32>) -> IO(Unit):
  Frame.load(messages, D.Demo.play(demo), D.Demo.map(demo))

def main() -> IO(Unit):
  do IO<Unit>:
    path : String <- IO.try(String, IO.get_env("DEMO"))
    demo : List<&2, U32> <- D.Demo.read(path)
    messages : Result<&1, &1, U32 & String, String> <- IO.get_env("BENDOOM_MESSAGES")
    Frame.demo(U32.is_eq(T.Script.int(Result.default(&1, &1, U32 & String, String, messages, "0")), 1), demo)
