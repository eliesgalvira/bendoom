# Bendoom. The WAD named by BENDOOM_IWAD loads, a map shows in a window
# from the player's eye, and the keyboard walks the player at Doom's 35
# tics a second whatever the frame rate; Esc or Close quits. The map is
# E1M1, or the one -warp names as Chocolate Doom's does. E1M1's song
# plays from the render in the directory named by BENDOOM_MUSIC, which
# the package's launcher defaults to its own IWAD's. RECORD names a demo
# to record, as vanilla's -record does, until the level ends or the game
# quits; film.bend makes a video of it. This binary writes the demo as
# hex text, and the launcher makes the .lmp of it.
import Base
import ./src/level.bend as L
import ./src/gfx.bend as G
import ./src/keys.bend as K
import ./src/demo.bend as D
import ./src/inter.bend as I
import ./src/game.bend as M

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    +map : L.Level.Name = M.Game.warp(args)
    world : Array<U32> & G.Gfx & L.Level <- I.Play.open(map)
    record : Result<&1, &1, U32 & String, String> <- IO.get_env("RECORD")
    demo : Maybe<D.Demo.Rec> <- D.Demo.open(record, map)
    now : Nat <- IO.now()
    dry : Maybe<U32> <- M.Game.start(U32.to_nat(4294967295), K.Input{K.Keys.none(), 0}, [], demo, now, map, world)
    return Unit{}
