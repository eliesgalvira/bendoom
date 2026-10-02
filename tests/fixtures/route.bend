# A vanilla version-109 demo, shared by the sim, renderer and Chocolate
# Doom. Its first 1453 tics collect the blue key, armour and a dropped
# shotgun after four kills. Every tic's random index and player state
# were compared with Chocolate Doom 3.1.1.
import Base
import ../../src/demo.bend as D
import ../../src/keys.bend as K

def Route.read(path: String) -> IO(List<&2, K.Cmd>):
  do IO<List<&2, K.Cmd>>:
    bytes : List<&2, U32> <- D.Demo.read(path)
    return D.Demo.play(bytes)

def Route.fight() -> IO(List<&2, K.Cmd>):
  do IO<List<&2, K.Cmd>>:
    cmds : List<&2, K.Cmd> <- Route.read("tests/fixtures/freedoom.lmp")
    return List.take(&2, K.Cmd, cmds, 1453n)
