# Doom's heads-up message line: the strings d_englsh.h gives the pickups
# the two E1M1s hold, the chaingun's and the blue door's refusal,
# numbered, and the rule hu_lib.c's HUlib_drawTextLine picks a glyph by.
# A message is carried as its number, since the state it lives in is
# what the laws quantify over and the tests print; the text is made
# where it is drawn or printed.
import Base

# No message. The other numbers are this file's own, in the order
# Message.text lists them.
def Message.none() -> U32:
  0

def Message.gotarmor() -> U32:
  1

def Message.gotmega() -> U32:
  2

def Message.goththbonus() -> U32:
  3

def Message.gotarmbonus() -> U32:
  4

def Message.gotstim() -> U32:
  5

def Message.gotmedikit() -> U32:
  6

def Message.gotbluecard() -> U32:
  7

def Message.gotberserk() -> U32:
  8

def Message.gotclip() -> U32:
  9

def Message.gotclipbox() -> U32:
  10

def Message.gotrocket() -> U32:
  11

def Message.gotcell() -> U32:
  12

def Message.gotshells() -> U32:
  13

def Message.gotshellbox() -> U32:
  14

def Message.gotchainsaw() -> U32:
  15

def Message.gotshotgun() -> U32:
  16

def Message.pd_bluek() -> U32:
  17

def Message.gotchaingun() -> U32:
  18

# d_englsh.h's English strings, one for each pickup type a census of the
# two E1M1s on Hurt Me Plenty finds, the chaingun's, and one for the
# blue locked door.
# GOTMEDINEED is not among them: P_GiveBody heals before p_inter.c tests
# the health, which is then never under 25, so vanilla never shows it.
# Nor are the strings of the pickup types neither map places, which
# Inventory.grant still takes but says nothing for.
def Message.text(n: U32) -> String:
  match n:
    case 1:
      "Picked up the armor."
    case 2:
      "Picked up the MegaArmor!"
    case 3:
      "Picked up a health bonus."
    case 4:
      "Picked up an armor bonus."
    case 5:
      "Picked up a stimpack."
    case 6:
      "Picked up a medikit."
    case 7:
      "Picked up a blue keycard."
    case 8:
      "Berserk!"
    case 9:
      "Picked up a clip."
    case 10:
      "Picked up a box of bullets."
    case 11:
      "Picked up a rocket."
    case 12:
      "Picked up an energy cell."
    case 13:
      "Picked up 4 shotgun shells."
    case 14:
      "Picked up a box of shotgun shells."
    case 15:
      "A chainsaw!  Find some meat!"
    case 16:
      "You got the shotgun!"
    case 17:
      "You need a blue key to open this door"
    case 18:
      "You got the chaingun!"
    case _:
      ""

# HU_MSGTIMEOUT: four seconds of tics on the line.
def Message.timeout() -> U32:
  140

# HU_MSGX and HU_MSGY: the line's left column and top row, the screen's
# corner.
def Message.x() -> U32:
  0

def Message.y() -> U32:
  0

# ctype.h's toupper for the letters, which is all d_englsh.h's strings
# hold.
def Message.upper(+c: U32) -> U32:
  Bool.pick(U32, Bool.and(U32.is_ge(c, 97), U32.is_le(c, 122)), (c - 32 : U32), c)

# HUlib_drawTextLine's glyph for an upper-cased character: its place in
# the font from HU_FONTSTART, '!', to '_'. A space, and anything else
# outside that span, has none and moves the line on by 4.
def Message.glyph.of(+u: U32) -> Maybe<&2, U32>:
  Bool.pick(Maybe<&2, U32>, Bool.and(U32.is_ge(u, 33), U32.is_le(u, 95)), Some{(u - 33 : U32)}, None{})

def Message.glyph(c: Char) -> Maybe<&2, U32>:
  Message.glyph.of(Message.upper(Char.to_u32(c)))
