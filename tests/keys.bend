# G_BuildTiccmd's tables on chosen keys, each command printed as its
# forward move, side move, turn and buttons. Walking forward is 25 a tic
# and running 50; strafing right 24, and left running -40; a turn left
# is 320 while the turn has been held five tics, 640 on the sixth, and
# a turn right running 1280 the other way; use is the button 2.
# Then the held count living in the input: seven tics of the left key
# from a fresh input turn 320 five times, then 640.
import Base
import ../src/keys.bend as K

def cmd(c: K.Cmd) -> String:
  K.Cmd{forward, side, turn, buttons} = c
  U32.show(forward) ++ " " ++ U32.show(side) ++ " " ++ U32.show(turn) ++ " " ++ U32.show(buttons)

def cmds(cs: List<&2, K.Cmd>) -> String:
  List.show(~&2, ~K.Cmd, ~cmd, cs)

def keys(up: Bool, left: Bool, right: Bool, sleft: Bool, sright: Bool, run: Bool, use: Bool) -> K.Keys:
  K.Keys{up, False{}, left, right, sleft, sright, run, use, False{}, K.Keys.numbers.none()}

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print("cmd " ++ cmds([K.Keys.cmd(keys(True{}, False{}, False{}, False{}, False{}, False{}, False{}), 0),
      K.Keys.cmd(keys(True{}, False{}, False{}, False{}, False{}, True{}, False{}), 0),
      K.Keys.cmd(keys(False{}, False{}, False{}, False{}, True{}, False{}, False{}), 0),
      K.Keys.cmd(keys(False{}, False{}, False{}, True{}, False{}, True{}, False{}), 0),
      K.Keys.cmd(keys(False{}, True{}, False{}, False{}, False{}, False{}, False{}), 5),
      K.Keys.cmd(keys(False{}, True{}, False{}, False{}, False{}, False{}, False{}), 6),
      K.Keys.cmd(keys(False{}, False{}, True{}, False{}, False{}, True{}, False{}), 6),
      K.Keys.cmd(keys(False{}, False{}, False{}, False{}, False{}, False{}, True{}), 0)]))
    IO.print("script " ++ cmds(K.Input.script(7n,
      K.Input{keys(False{}, True{}, False{}, False{}, False{}, False{}, False{}), 0})))

#|cmd [25 0 0 0, 50 0 0 0, 0 24 0 0, 0 4294967256 0 0, 0 0 320 0, 0 0 640 0, 0 0 4294966016 0, 0 0 0 2]
#|script [0 0 320 0, 0 0 320 0, 0 0 320 0, 0 0 320 0, 0 0 320 0, 0 0 640 0, 0 0 640 0]
