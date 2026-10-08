# The held keys and the tic command built from them, as Doom's
# G_BuildTiccmd: the forward and side moves and the turn, from the walk
# and run tables, with the six-tic slow turn, and the buttons.
import Base

# The held keys, the number keys from 1 last.
type Keys is Data:
  Keys{up: Bool, down: Bool, left: Bool, right: Bool, sleft: Bool,
    sright: Bool, run: Bool, use: Bool, fire: Bool, numbers: List<&2, Bool>}

# forward and side in Doom's units (times 2048 is the thrust), turn in
# Doom's angleturn units (times 65536 is the angle), and the buttons as
# the byte a demo keeps: BT_ATTACK 1, BT_USE 2, BT_CHANGE 4 with the
# weapon's number from 0 in the three bits above it.
type Cmd is Data:
  Cmd{forward: U32, side: U32, turn: U32, buttons: U32}

# The number keys read, none held: one for each weapon Bendoom fires
# that a key selects, the fist's to the launcher's.
def Keys.numbers.none() -> List<&2, Bool>:
  [False{}, False{}, False{}, False{}, False{}]

def Keys.none() -> Keys:
  Keys{False{}, False{}, False{}, False{}, False{}, False{}, False{}, False{}, False{}, Keys.numbers.none()}

def Cmd.idle() -> Cmd:
  Cmd{0, 0, 0, 0}

def Cmd.use(cmd: Cmd) -> Bool:
  Cmd{forward, side, turn, buttons} = cmd
  U32.is_eq((buttons .&. 2 : U32), 2)

# BT_ATTACK, the bit Ctrl sets.
def Cmd.attack(cmd: Cmd) -> Bool:
  Cmd{forward, side, turn, buttons} = cmd
  U32.is_eq((buttons .&. 1 : U32), 1)

def Cmd.weapon(cmd: Cmd) -> Maybe<&2, U32>:
  Cmd{forward, side, turn, +buttons} = cmd
  Bool.pick(Maybe<&2, U32>, U32.is_eq((buttons .&. 4 : U32), 4), Some{((buttons >> 3n : U32) .&. 7 : U32)}, None{})

# A command in a demo file's units: the moves and the buttons as they
# are, the turn in steps of 256, the byte a demo keeps of it.
def Cmd.demo(forward: U32, side: U32, turn: U32, buttons: U32) -> Cmd:
  Cmd{forward, side, (turn << 8n : U32), buttons}

def Keys.set(on: Bool, down: Bool, old: Bool) -> Bool:
  match on:
    case True{}:
      down
    case False{}:
      old

# A key's place among the number keys, from 0 for the key 1. Any other
# code takes place 8, past vanilla's eight weapon keys and every key
# read.
def Keys.number(+code: U32) -> Nat:
  U32.to_nat(U32.min((code - 49 : U32), 8))

# The number keys after a press of the key at a place.
def Keys.numbers(ns: List<&2, Bool>, place: Nat, down: Bool) -> List<&2, Bool>:
  match ns:
    case []:
      []
    case held <> rest:
      match place:
        case 0n:
          down <> rest
        case 1n+p:
          held <> Keys.numbers(rest, p, down)

# The runtime's key codes: arrows 63232 up, 63233 down, 63234 left,
# 63235 right; letters lower case; Shift 65592 and 65596; Space 32 and Enter 13;
# Ctrl 65595 and 65598; the digits their characters, 1 at 49.
def Keys.press(+code: U32, +down: Bool, keys: Keys) -> Keys:
  Keys{up, dn, left, right, sleft, sright, run, use, fire, numbers} = keys
  Keys{Keys.set(U32.is_eq(code, 63232) || U32.is_eq(code, 119), down, up),
    Keys.set(U32.is_eq(code, 63233) || U32.is_eq(code, 115), down, dn),
    Keys.set(U32.is_eq(code, 63234), down, left),
    Keys.set(U32.is_eq(code, 63235), down, right),
    Keys.set(U32.is_eq(code, 97), down, sleft),
    Keys.set(U32.is_eq(code, 100), down, sright),
    Keys.set(U32.is_eq(code, 65592) || U32.is_eq(code, 65596), down, run),
    Keys.set(U32.is_eq(code, 32) || U32.is_eq(code, 13), down, use),
    Keys.set(U32.is_eq(code, 65595) || U32.is_eq(code, 65598), down, fire),
    Keys.numbers(numbers, Keys.number(code), down)}

def Keys.if(c: Bool, v: U32) -> U32:
  match c:
    case True{}:
      v
    case False{}:
      0

# Doom's forwardmove {25, 50}, sidemove {24, 40} and angleturn
# {640, 1280, 320}: index 1 when running, 2 the slow turn.
def Keys.forward(run: Bool) -> U32:
  Bool.pick(U32, run, 50, 25)

def Keys.side(run: Bool) -> U32:
  Bool.pick(U32, run, 40, 24)

def Keys.turn(run: Bool, slow: Bool) -> U32:
  Bool.pick(U32, slow, 320, Bool.pick(U32, run, 1280, 640))

# G_BuildTiccmd's loop over the weapon keys: the lowest held number
# wins, as BT_CHANGE, 4, with the weapon's number, the key's less one,
# three bits up, so each key past the first is 8 more. P_PlayerThink
# drops a change to a weapon not owned.
def Keys.change(ns: List<&2, Bool>, +change: U32) -> U32:
  match ns:
    case []:
      0
    case True{} <> rest:
      change
    case False{} <> rest:
      Keys.change(rest, (change + 8 : U32))

# The command for held keys, with the tics the turn keys have been
# held, this one included: the first five turn slowly. Opposite keys
# cancel out, in U32's wrapping arithmetic. Ctrl is BT_ATTACK, Space
# and Enter BT_USE.
def Keys.cmd(keys: Keys, +turnheld: U32) -> Cmd:
  Keys{up, down, left, right, sleft, sright, +run, use, fire, numbers} = keys
  +slow = U32.is_lt(turnheld, 6)
  Cmd{(Keys.if(up, Keys.forward(run)) - Keys.if(down, Keys.forward(run)) : U32),
    (Keys.if(sright, Keys.side(run)) - Keys.if(sleft, Keys.side(run)) : U32),
    (Keys.if(left, Keys.turn(run, slow)) - Keys.if(right, Keys.turn(run, slow)) : U32),
    (Keys.if(fire, 1) + Keys.if(use, 2) + Keys.change(numbers, 4) : U32)}

# The turn keys' held count after a tic: one more while either is held.
def Keys.held(keys: Keys, turnheld: U32) -> U32:
  Keys{up, down, left, right, sleft, sright, run, use, fire, numbers} = keys
  Bool.pick(U32, Bool.or(left, right), (turnheld + 1 : U32), 0)

# What G_BuildTiccmd reads: the held keys and the turn keys' held count.
type Input is Data:
  Input{keys: Keys, turnheld: U32}

def Input.press(code: U32, down: Bool, input: Input) -> Input:
  Input{keys, turnheld} = input
  Input{Keys.press(code, down, keys), turnheld}

# The input a tic later, the keys still held.
def Input.tic(input: Input) -> Input:
  Input{+keys, turnheld} = input
  Input{keys, Keys.held(keys, turnheld)}

def Input.cmd(input: Input) -> Cmd:
  Input{keys, turnheld} = input
  Keys.cmd(keys, turnheld)

def Input.after(n: Nat, input: Input) -> Input:
  match n:
    case 0n:
      input
    case 1n+m:
      Input.after(m, Input.tic(input))

# The commands of n tics of the same held keys.
def Input.script(n: Nat, input: Input) -> List<&2, Cmd>:
  match n:
    case 0n:
      []
    case 1n+m:
      +next = Input.tic(input)
      Input.cmd(next) <> Input.script(m, next)
