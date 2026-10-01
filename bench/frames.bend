# A measurement, not a test: the game's frame without the window, a
# hundred times over: E1M1 rendered from the player 1 start and folded
# into the window's image. Build natively and time it:
#
#   bend bench/frames.bend -o frames
#   time ./frames
import Base
import ../src/bytes.bend as B
import ../src/level.bend as L
import ../src/gfx.bend as G
import ../src/sim.bend as S
import ../src/tic.bend as Tic
import ../src/project.bend as P
import ../src/render.bend as R
import ../src/show.bend as V

def Bench.drop(p: Array<U32> & Image) -> Array<U32>:
  (mem, image) = p
  mem

def Bench.go(n: Nat, +tables: P.Project.Tables, +gfx: G.Gfx, +s: S.State, mem: Array<U32>) -> Array<U32>:
  match n:
    case 0n:
      mem
    case 1n+m:
      Bench.go(m, tables, gfx, s, Bench.drop(V.Show.image(R.Render.frame(tables, gfx, s, True{}, mem))))

def Bench.peek(p: Array<U32> & U32) -> U32:
  (mem, v) = p
  v

def Bench.frames(mem: Array<U32>, gl: G.Gfx & L.Level) -> IO(Unit):
  (+gfx, +level) = gl
  IO.print("centre " ++ U32.show(Bench.peek(B.Bytes.at(Bench.go(100n, P.Project.tables(level), gfx,
    Tic.State.start(level), mem), (84 * 320 + 160 : U32)))))

def Bench.start(w: Array<U32> & G.Gfx & L.Level) -> IO(Unit):
  (mem, gl) = w
  Bench.frames(mem, gl)

def main() -> IO(Unit):
  do IO<Unit>:
    world : Array<U32> & G.Gfx & L.Level <- G.Gfx.open()
    Bench.start(world)
