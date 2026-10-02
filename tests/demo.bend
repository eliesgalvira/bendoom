# A demo's bytes, the turn carried after them, and the commands read
# back from them. Each expected value was worked out by hand from
# Chocolate Doom's G_BuildTiccmd, which when recording rounds the turn
# plus the carry to (t + 128) & 0xff00 and carries the rest, and
# linuxdoom-1.10's G_WriteDemoTiccmd and G_ReadDemoTiccmd, which write
# forward, side, the turn's high byte and the buttons, and read the turn
# back as that byte << 8. So from no carry the walk's 640 turns 768, 512,
# 768 left, carrying -128, and -512, -768, -512 right, carrying -128;
# the slow 320 turns 256, 512, 256, 256, carrying none; the run's 1280
# stays. Side -40 is the byte 216. The end marker, 0x80 where a tic's
# forward byte would be, ends the read, and so does a tic cut short.
# The buttons are G_BuildTiccmd's from held keys: Ctrl is BT_ATTACK, 1;
# Space BT_USE, 2; the lowest held number key i + 1 is BT_CHANGE, 4, with
# i << BT_WEAPONSHIFT, so 1 is 4, 2 is 4 + 8 = 12, 3 is 4 + 16 = 20, 4
# is 4 + 24 = 28, 2 with 3 is 12, 1 with 3 is 4 and 3 with 4 is 20; Ctrl
# with Space is 3, and with 3 too, 23. The byte is written and read
# back whole. The header is G_BeginRecording's for E1M5: version 109,
# the skill, the episode, the map, and the options and players after.
import Base
import ../src/keys.bend as K
import ../src/level.bend as L
import ../src/demo.bend as D

def int(+x: U32) -> String:
  Bool.pick(String, U32.is_lt(x, 2147483648), U32.show(x), "-" ++ U32.show((0 - x : U32)))

def bytes(xs: List<&2, U32>) -> String:
  match xs:
    case []:
      ""
    case x <> rest:
      " " ++ U32.show(x) ++ bytes(rest)

def cmds(xs: List<&2, K.Cmd>) -> String:
  match xs:
    case []:
      ""
    case K.Cmd{+forward, +side, +turn, buttons} <> rest:
      " " ++ int(forward) ++ "," ++ int(side) ++ "," ++ int(turn) ++ "," ++ U32.show(buttons) ++ cmds(rest)

def recorded(tag: String, p: List<&2, U32> & U32) -> String:
  (+tics, carry) = p
  tag ++ bytes(tics) ++ " | carry " ++ int(carry) ++ " | read" ++ cmds(D.Demo.cmds(tics))

def turns(n: Nat, turn: U32) -> List<&2, K.Cmd>:
  List.replicate(K.Cmd, n, K.Cmd{0, 0, turn, 0})

# The command of held button keys, no other key down.
def held(use: Bool, fire: Bool, numbers: List<&2, Bool>) -> K.Cmd:
  K.Keys.cmd(K.Keys{False{}, False{}, False{}, False{}, False{}, False{}, False{}, use, fire, numbers}, 0)

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print("header" ++ bytes(D.Demo.header(L.Name{1, 5})))
    IO.print(recorded("left", D.Demo.tics(K.Cmd{50, (0 - 40 : U32), 640, 2} <> turns(2n, 640), 0)))
    IO.print(recorded("right", D.Demo.tics(K.Cmd{(0 - 25 : U32), 24, (0 - 640 : U32), 0}
      <> turns(2n, (0 - 640 : U32)), 0)))
    IO.print(recorded("slow", D.Demo.tics(turns(4n, 320), 0)))
    IO.print(recorded("run", D.Demo.tics(turns(2n, (0 - 1280 : U32)), 0)))
    IO.print(recorded("fire", D.Demo.tics([held(False{}, True{}, K.Keys.numbers.none())], 0)))
    IO.print(recorded("change", D.Demo.tics([held(False{}, False{}, [True{}, False{}, False{}, False{}]),
      held(False{}, False{}, [False{}, True{}, False{}, False{}]), held(False{}, False{}, [False{}, False{}, True{}, False{}]),
      held(False{}, False{}, [False{}, True{}, True{}, False{}]), held(False{}, False{}, [True{}, False{}, True{}, False{}]),
      held(False{}, False{}, [False{}, False{}, False{}, True{}]), held(False{}, False{}, [False{}, False{}, True{}, True{}])], 0)))
    IO.print(recorded("use and fire", D.Demo.tics([held(True{}, True{}, K.Keys.numbers.none()),
      held(True{}, True{}, [False{}, False{}, True{}, False{}])], 0)))
    IO.print("marker" ++ cmds(D.Demo.cmds([50, 0, 0, 0, 128, 0, 0, 0, 25, 0, 0, 0])))
    IO.print("cut" ++ cmds(D.Demo.cmds([50, 0, 0, 0, 25, 0, 0])))

#|header 109 2 1 5 0 0 0 0 0 1 0 0 0
#|left 50 216 3 2 0 0 2 0 0 0 3 0 | carry -128 | read 50,-40,768,2 0,0,512,0 0,0,768,0
#|right 231 24 254 0 0 0 253 0 0 0 254 0 | carry -128 | read -25,24,-512,0 0,0,-768,0 0,0,-512,0
#|slow 0 0 1 0 0 0 2 0 0 0 1 0 0 0 1 0 | carry 0 | read 0,0,256,0 0,0,512,0 0,0,256,0 0,0,256,0
#|run 0 0 251 0 0 0 251 0 | carry 0 | read 0,0,-1280,0 0,0,-1280,0
#|fire 0 0 0 1 | carry 0 | read 0,0,0,1
#|change 0 0 0 4 0 0 0 12 0 0 0 20 0 0 0 12 0 0 0 4 0 0 0 28 0 0 0 20 | carry 0 | read 0,0,0,4 0,0,0,12 0,0,0,20 0,0,0,12 0,0,0,4 0,0,0,28 0,0,0,20
#|use and fire 0 0 0 3 0 0 0 23 | carry 0 | read 0,0,0,3 0,0,0,23
#|marker 50,0,0,0
#|cut 50,0,0,0
