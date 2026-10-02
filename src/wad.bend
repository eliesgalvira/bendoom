# A WAD's header (12 bytes: "IWAD" or "PWAD", the lump count, the
# directory's offset) and directory (16 bytes a lump: offset, size, an
# 8-byte NUL-padded name).
import Base
import ./bytes.bend as B

type Wad.Lump is Data:
  Lump{pos: U32, size: U32, name: String}

# kind: 0 not a WAD, 1 an IWAD, 2 a PWAD.
type Wad.Header is Data:
  Header{kind: U32, count: U32, dir: U32}

# "IWAD" is 1145132873 little-endian, "PWAD" 1145132880.
def Wad.kind(+m: U32) -> U32:
  Bool.pick(U32, U32.is_eq(m, 1145132873), 1,
    Bool.pick(U32, U32.is_eq(m, 1145132880), 2, 0))

def Wad.header.fin(magic: U32, count: U32, p: Array<U32> & U32) ->
  Array<U32> & Wad.Header:
  (a, dir) = p
  (a, Header{Wad.kind(magic), count, dir})

def Wad.header.dir(magic: U32, p: Array<U32> & U32) ->
  Array<U32> & Wad.Header:
  (a, count) = p
  Wad.header.fin(magic, count, B.Bytes.u32(a, 8))

def Wad.header.count(p: Array<U32> & U32) -> Array<U32> & Wad.Header:
  (a, magic) = p
  Wad.header.dir(magic, B.Bytes.u32(a, 4))

def Wad.header(a: Array<U32>) -> Array<U32> & Wad.Header:
  Wad.header.count(B.Bytes.u32(a, 0))

def Wad.lump.fin(pos: U32, size: U32, rest: List<&2, Wad.Lump>,
  p: Array<U32> & String) -> Array<U32> & List<&2, Wad.Lump>:
  (a, name) = p
  (a, Lump{pos, size, name} <> rest)

def Wad.lump.name(+off: U32, pos: U32, rest: List<&2, Wad.Lump>,
  p: Array<U32> & U32) -> Array<U32> & List<&2, Wad.Lump>:
  (a, size) = p
  Wad.lump.fin(pos, size, rest, B.Bytes.text(a, (off + 8 : U32), 8n))

def Wad.lump.size(+off: U32, rest: List<&2, Wad.Lump>, p: Array<U32> & U32) ->
  Array<U32> & List<&2, Wad.Lump>:
  (a, pos) = p
  Wad.lump.name(off, pos, rest, B.Bytes.u32(a, (off + 4 : U32)))

def Wad.lump(+off: U32, p: Array<U32> & List<&2, Wad.Lump>) ->
  Array<U32> & List<&2, Wad.Lump>:
  (a, rest) = p
  Wad.lump.size(off, rest, B.Bytes.u32(a, off))

def Wad.lumps(n: Nat, a: Array<U32>, +off: U32) -> Array<U32> & List<&2, Wad.Lump>:
  match n:
    case 0n:
      (a, [])
    case 1n+m:
      Wad.lump(off, Wad.lumps(m, a, (off + 16 : U32)))

def Wad.dir.fin(p: Array<U32> & Wad.Header) -> Array<U32> & List<&2, Wad.Lump>:
  (a, h) = p
  Header{kind, count, dir} = h
  Wad.lumps(U32.to_nat(count), a, dir)

def Wad.dir(a: Array<U32>) -> Array<U32> & List<&2, Wad.Lump>:
  Wad.dir.fin(Wad.header(a))

def Wad.named(+name: String, l: Wad.Lump) -> Bool:
  Lump{pos, size, n} = l
  String.eq(n, name)

def Wad.index.bump(m: Maybe<Nat>) -> Maybe<Nat>:
  match m:
    case None{}:
      None{}
    case Some{i}:
      Some{1n+i}

def Wad.index.pick(hit: Bool, rest: Maybe<Nat>) -> Maybe<Nat>:
  match hit:
    case True{}:
      Some{0n}
    case False{}:
      Wad.index.bump(rest)

# The bytes and directory of the WAD BENDOOM_IWAD names; a WAD that
# cannot be read ends the program with the error.
def Wad.open() -> IO(Array<U32> & List<&2, Wad.Lump>):
  do IO<Array<U32> & List<&2, Wad.Lump>>:
    path : String <- IO.try(String, IO.get_env("BENDOOM_IWAD"))
    bytes : Array<U32> <- IO.try(Array<U32>, B.Bytes.read(path))
    return Wad.dir(bytes)

# The index of the first lump called name.
def Wad.index(+name: String, lumps: List<&2, Wad.Lump>) -> Maybe<Nat>:
  match lumps:
    case []:
      None{}
    case l <> rest:
      Wad.index.pick(Wad.named(name, l), Wad.index(name, rest))

def Wad.find.at(m: Maybe<&2, Wad.Lump>) -> U32 & U32:
  match m:
    case None{}:
      (0, 0)
    case Some{l}:
      Lump{pos, size, name} = l
      (pos, size)

def Wad.find.get(lumps: List<&2, Wad.Lump>, i: Maybe<Nat>) -> U32 & U32:
  match i:
    case None{}:
      (0, 0)
    case Some{k}:
      Wad.find.at(List.get(&2, Wad.Lump, lumps, k))

# The position and size of the first lump called name, both zero for
# none.
def Wad.find(+lumps: List<&2, Wad.Lump>, +name: String) -> U32 & U32:
  Wad.find.get(lumps, Wad.index(name, lumps))
