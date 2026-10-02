# A vanilla demo, the .lmp Doom's -record writes: the version 1.9
# header, four bytes a tic, and 0x80 at the end. Chocolate Doom plays it.
# A recording is written as hex text, which the package's launcher
# decodes into the .lmp.
import Base
import ./bytes.bend as B
import ./keys.bend as K

# Version 109, skill 2 (Hurt me plenty), E1M1, no deathmatch, respawn,
# fast or -nomonsters, player 1 alone in the game.
def Demo.header() -> List<&2, U32>:
  [109, 2, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0]

# A demo being recorded, and the turn the last tic's rounding left over.
type Demo.Rec is Type:
  Rec{file: File, carry: U32}

# G_WriteDemoTiccmd's bytes of a tic: the moves, the turn's high byte,
# the buttons.
def Demo.tic(forward: U32, side: U32, turn: U32, buttons: U32, p: List<&2, U32> & U32) -> List<&2, U32> & U32:
  (rest, carry) = p
  ((forward .&. 255 : U32) <> (side .&. 255 : U32) <> ((turn >> 8n) .&. 255 : U32)
    <> (buttons .&. 255 : U32) <> rest, carry)

# The tics' bytes, and the turn left over after them. A demo keeps a
# turn in steps of 256, so each is rounded to one and the error carried
# into the next, as Chocolate Doom records: the walk's 640 alternates
# 768 and 512 either way, and keeps its speed.
def Demo.tics(cmds: List<&2, K.Cmd>, +carry: U32) -> List<&2, U32> & U32:
  match cmds:
    case []:
      ([], carry)
    case K.Cmd{forward, side, turn, buttons} <> rest:
      +desired = (turn + carry : U32)
      +kept = ((desired + 128) .&. 4294967040 : U32)
      Demo.tic(forward, side, kept, buttons, Demo.tics(rest, (desired - kept : U32)))

# A byte as the signed char the file holds.
def Demo.signed(+b: U32) -> U32:
  ((b .^. 128) - 128 : U32)

def Demo.until(end: Bool, cmd: K.Cmd, rest: List<&2, K.Cmd>) -> List<&2, K.Cmd>:
  match end:
    case True{}:
      []
    case False{}:
      cmd <> rest

# G_ReadDemoTiccmd over the tics, up to the end marker or the last whole
# tic.
def Demo.cmds(bytes: List<&2, U32>) -> List<&2, K.Cmd>:
  match bytes:
    case +forward <> side <> turn <> buttons <> rest:
      Demo.until(U32.is_eq(forward, 128), K.Cmd.demo(Demo.signed(forward), Demo.signed(side),
        Demo.signed(turn), buttons), Demo.cmds(rest))
    case _:
      []

# The commands of a demo file, the tics after its header.
def Demo.play(bytes: List<&2, U32>) -> List<&2, K.Cmd>:
  Demo.cmds(List.drop(&2, U32, bytes, 13n))

# The episode and map a demo's header names, its third and fourth bytes,
# 0 for a file too short to have them.
def Demo.episode(bytes: List<&2, U32>) -> U32:
  Maybe.default(&2, U32, List.get(&2, U32, bytes, 2n), 0)

def Demo.map(bytes: List<&2, U32>) -> U32:
  Maybe.default(&2, U32, List.get(&2, U32, bytes, 3n), 0)

def Demo.read.chunk(bytes: List<&2, U32>, kept: List<&2, U32>) -> List<&2, U32>:
  List.append(&2, U32, kept, bytes)

# The bytes of the demo file at the path.
def Demo.read(path: String) -> IO(List<&2, U32>):
  do IO<List<&2, U32>>:
    file : File <- IO.try(File, File.open(path, "r"))
    B.Bytes.fold(~List<&2, U32>, ~Demo.read.chunk, file, [])

# The demo at the path, if one is named, created with its header.
def Demo.open(path: Result<&1, &1, U32 & String, String>) -> IO(Maybe<Demo.Rec>):
  match path:
    case Fail{e}:
      IO.pure(Maybe<Demo.Rec>, None{})
    case Done{name}:
      do IO<Maybe<Demo.Rec>>:
        file : File <- IO.try(File, File.open(name, "w"))
        kept : File <- B.Bytes.put_hex(file, Demo.header())
        return Some{Rec{kept, 0}}

def Demo.recorded(file: File, p: List<&2, U32> & U32) -> IO(Maybe<Demo.Rec> & List<&2, K.Cmd>):
  (+bytes, carry) = p
  do IO<Maybe<Demo.Rec> & List<&2, K.Cmd>>:
    kept : File <- B.Bytes.put_hex(file, bytes)
    return (Some{Rec{kept, carry}}, Demo.cmds(bytes))

# A run of tics recorded, and the commands to play: the ones the demo
# holds, as vanilla reads each tic back, so the game plays what a replay
# will.
def Demo.record(demo: Maybe<Demo.Rec>, cmds: List<&2, K.Cmd>) -> IO(Maybe<Demo.Rec> & List<&2, K.Cmd>):
  match demo:
    case None{}:
      IO.pure(Maybe<Demo.Rec> & List<&2, K.Cmd>, (None{}, cmds))
    case Some{Rec{file, carry}}:
      Demo.recorded(file, Demo.tics(cmds, carry))

# The end marker written and the file closed.
def Demo.stop(demo: Maybe<Demo.Rec>) -> IO(Unit):
  match demo:
    case None{}:
      IO.pure(Unit, Unit{})
    case Some{Rec{file, carry}}:
      do IO<Unit>:
        done : File <- B.Bytes.put_hex(file, [128])
        File.close(done)
