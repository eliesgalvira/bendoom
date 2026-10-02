# A frame as hex rows: the map the header of the demo file DEMO names,
# from the WAD named by BENDOOM_IWAD, the demo's tics replayed through
# the play from player 1's start, and the frame drawn as the game draws
# it, printed as a line of the palette's index and then 200 lines of 320
# palette indices, two hex digits each. A demo that takes the exit
# leaves the tally showing, and its tics after the exit are the tally's,
# their use the press that accelerates it. tools/oracle.nu writes the
# demo and diffs the frame against Chocolate Doom's after the same one.
#
#   bend tools/frame.bend -o frame
#   DEMO=script.lmp ./frame
import Base
import ../src/bytes.bend as B
import ../src/level.bend as L
import ../src/gfx.bend as G
import ../src/keys.bend as K
import ../src/inter.bend as I
import ../src/project.bend as P
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

def Frame.draw(script: List<&2, K.Cmd>, mem: Array<U32>, gl: G.Gfx & L.Level) -> IO(Unit):
  (+gfx, +level) = gl
  do IO<Unit>:
    rest : Array<U32> <- Frame.print(Frame.palette(I.Play.frame(P.Project.tables(level), gfx,
      I.Play.replay(script, level, I.Play.start(level)), False{}, mem)))
    Frame.rows(200n, 0, rest)

def Frame.start(script: List<&2, K.Cmd>, w: Array<U32> & G.Gfx & L.Level) -> IO(Unit):
  (mem, gl) = w
  Frame.draw(script, mem, gl)

def Frame.demo(+demo: List<&2, U32>) -> IO(Unit):
  IO.bind(Array<U32> & G.Gfx & L.Level, Unit, G.Gfx.open(D.Demo.episode(demo), D.Demo.map(demo)),
    w => Frame.start(D.Demo.play(demo), w))

def main() -> IO(Unit):
  do IO<Unit>:
    path : String <- IO.try(String, IO.get_env("DEMO"))
    demo : List<&2, U32> <- D.Demo.read(path)
    Frame.demo(demo)
