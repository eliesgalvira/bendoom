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
import ../src/project.bend as P
import ../src/sound.bend as Sn
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

def Frame.printed(palette: U32, mem: Array<U32>) -> IO(Unit):
  do IO<Unit>:
    rest : Array<U32> <- Frame.print(Frame.palette((mem, palette)))
    Frame.rows(200n, 0, rest)

type Frame.Run is Type:
  Run{world: I.Play.World, palette: U32}

def Frame.drawn(play: I.Play, gfx: G.Gfx, tables: P.Project.Tables, level: L.Level,
  p: Array<U32> & U32) -> Frame.Run:
  (mem, palette) = p
  Run{I.World{play, mem, gfx, tables, level}, palette}

def Frame.draw(messages: Bool, w: I.Play.World) -> Frame.Run:
  I.World{+play, mem, +gfx, +tables, level} = w
  Frame.drawn(play, gfx, tables, level, I.Play.frame(tables, gfx, play, messages, mem))

def Frame.stepped(messages: Bool, p: I.Play.World & List<&2, Sn.Sound.Event>) -> Frame.Run:
  (world, sounds) = p
  Frame.draw(messages, world)

# Timedemo consumes its startup command before the first D_Display.
def Frame.go(cmds: List<&2, K.Cmd>, +messages: Bool, run: Frame.Run) -> IO(Unit):
  match cmds run:
    case [] Run{I.World{play, mem, gfx, tables, level}, palette}:
      Frame.printed(palette, mem)
    case +cmd <> rest Run{world, palette}:
      IO.bind(I.Play.World, Unit, I.Play.load(world),
        loaded => Frame.go(rest, messages, Frame.stepped(messages, I.Play.World.step(cmd, loaded))))

def Frame.started(p: I.Play.World & List<&2, Sn.Sound.Event>) -> Frame.Run:
  (world, sounds) = p
  Run{world, 0}

def Frame.start(script: List<&2, K.Cmd>, +messages: Bool, w: I.Play.World) -> IO(Unit):
  match script:
    case []:
      Frame.go([], messages, Frame.draw(messages, w))
    case +cmd <> []:
      Frame.go([], messages, Frame.stepped(messages, I.Play.World.step(cmd, w)))
    case +cmd <> rest:
      Frame.go(rest, messages, Frame.started(I.Play.World.step(cmd, w)))

def Frame.load(messages: Bool, script: List<&2, K.Cmd>, map: L.Level.Name) -> IO(Unit):
  IO.bind(Array<U32> & G.Gfx & L.Level, Unit, I.Play.open(map),
    opened => Frame.start(script, messages, I.Play.World.start(opened)))

def Frame.demo(messages: Bool, +demo: List<&2, U32>) -> IO(Unit):
  Frame.load(messages, D.Demo.play(demo), D.Demo.map(demo))

def main() -> IO(Unit):
  do IO<Unit>:
    path : String <- IO.try(String, IO.get_env("DEMO"))
    demo : List<&2, U32> <- D.Demo.read(path)
    messages : Result<&1, &1, U32 & String, String> <- IO.get_env("BENDOOM_MESSAGES")
    Frame.demo(U32.is_eq(T.Script.int(Result.default(&1, &1, U32 & String, String, messages, "0")), 1), demo)
