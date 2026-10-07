# Bendoom. The WAD named by BENDOOM_IWAD loads, a map shows in a window
# from the player's eye, and the keyboard walks the player at Doom's 35
# tics a second whatever the frame rate; Esc or Close quits. The map is
# E1M1, or the one -warp names as Chocolate Doom's does. The scene's
# song plays from the same WAD, synthesized as Chocolate Doom's OPL
# music plays it. RECORD names a demo to record, as vanilla's -record
# does, until the level ends or the game quits; film.bend makes a video
# of it. This binary writes the demo as hex text, and the launcher makes
# the .lmp of it.
import Base
import ./src/wad.bend as W
import ./src/level.bend as L
import ./src/gfx.bend as G
import ./src/keys.bend as K
import ./src/demo.bend as D
import ./src/game.bend as M

def play(+map: L.Level.Name, world: Array<U32> & G.Gfx & L.Level) -> IO(Unit):
  do IO<Unit>:
    record : Result<&1, &1, U32 & String, String> <- IO.get_env("RECORD")
    demo : Maybe<D.Demo.Rec> <- D.Demo.open(record, map)
    now : Nat <- IO.now()
    dry : Maybe<U32> <- M.Game.start(U32.to_nat(4294967295), K.Input{K.Keys.none(), 0}, [], demo, now, map, world)
    return Unit{}

def load(+map: L.Level.Name, dir: Array<U32> & List<&2, W.Wad.Lump>) -> IO(Unit):
  L.Name{+episode, +number} = map
  IO.bind(Array<U32> & G.Gfx & L.Level, Unit, IO.pass(Array<U32> & G.Gfx & L.Level, G.Gfx.load(episode, number, dir)),
    world => play(map, world))

def warp(args: List<String>, dir: Array<U32> & List<&2, W.Wad.Lump>) -> IO(Unit):
  (bytes, +lumps) = dir
  load(M.Game.warp(lumps, args), (bytes, lumps))

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    dir : Array<U32> & List<&2, W.Wad.Lump> <- W.Wad.open()
    warp(args, dir)
