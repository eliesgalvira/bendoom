# Bendoom. The WAD named by BENDOOM_IWAD loads, E1M1 shows in a window
# from the player's eye, and the keyboard walks the player at Doom's 35
# tics a second whatever the frame rate; Esc or Close quits. The scene's
# song plays from the same WAD, synthesized as Chocolate Doom's OPL
# music plays it. RECORD names a demo to record, as vanilla's -record
# does, until the level ends or the game quits; film.bend makes a video
# of it. This binary writes the demo as hex text, and the launcher makes
# the .lmp of it.
import Base
import ./src/level.bend as L
import ./src/gfx.bend as G
import ./src/keys.bend as K
import ./src/demo.bend as D
import ./src/game.bend as M

def main() -> IO(Unit):
  do IO<Unit>:
    world : Array<U32> & G.Gfx & L.Level <- G.Gfx.open()
    record : Result<&1, &1, U32 & String, String> <- IO.get_env("RECORD")
    demo : Maybe<D.Demo.Rec> <- D.Demo.open(record)
    now : Nat <- IO.now()
    dry : Maybe<U32> <- M.Game.start(U32.to_nat(4294967295), K.Input{K.Keys.none(), 0}, [], demo, now, world)
    return Unit{}
