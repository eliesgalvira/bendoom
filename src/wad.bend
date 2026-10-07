# A WAD's header (12 bytes: "IWAD" or "PWAD", the lump count, the
# directory's offset) and directory (16 bytes a lump: offset, size, an
# 8-byte NUL-padded name), read two ways: the whole file as one array,
# which the graphics loader reads at the offsets it finds as it goes,
# or the named lumps gathered from that array for the sound and song
# decoders.
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

# A name's bytes, cut at the first NUL.
def Wad.text(bytes: List<&2, U32>) -> List<&2, Char>:
  match bytes:
    case []:
      []
    case +c <> rest:
      B.Bytes.text.cut(U32.is_zero(c), c, Wad.text(rest))

def Wad.entry(bytes: List<&2, U32>) -> Wad.Lump:
  match bytes:
    case p0 <> p1 <> p2 <> p3 <> s0 <> s1 <> s2 <> s3 <> name:
      Lump{B.Bytes.le32(p0, p1, p2, p3), B.Bytes.le32(s0, s1, s2, s3),
        String.from_list(Wad.text(List.take(&2, U32, name, 8n)))}
    case _:
      Lump{0, 0, ""}

def Wad.entries(n: Nat, +bytes: List<&2, U32>) -> List<&2, Wad.Lump>:
  match n:
    case 0n:
      []
    case 1n+m:
      Wad.entry(bytes) <> Wad.entries(m, List.drop(&2, U32, bytes, 16n))

def Wad.Header.of(bytes: List<&2, U32>) -> Wad.Header:
  match bytes:
    case m0 <> m1 <> m2 <> m3 <> c0 <> c1 <> c2 <> c3 <> d0 <> d1 <> d2 <> d3 <> rest:
      Header{Wad.kind(B.Bytes.le32(m0, m1, m2, m3)), B.Bytes.le32(c0, c1, c2, c3), B.Bytes.le32(d0, d1, d2, d3)}
    case _:
      Header{0, 0, 0}

def Wad.dir.listed(+count: U32, p: Array<U32> & List<&2, U32>) -> Array<U32> & List<&2, Wad.Lump>:
  (a, bytes) = p
  (a, Wad.entries(U32.to_nat(count), bytes))

def Wad.dir.at(a: Array<U32>, h: Wad.Header) -> Array<U32> & List<&2, Wad.Lump>:
  Header{kind, +count, dir} = h
  Wad.dir.listed(count, B.Bytes.file.list(a, dir, (count * 16 : U32)))

def Wad.dir.headed(p: Array<U32> & List<&2, U32>) -> Array<U32> & List<&2, Wad.Lump>:
  (a, bytes) = p
  Wad.dir.at(a, Wad.Header.of(bytes))

# The directory of a WAD read whole.
def Wad.dir(a: Array<U32>) -> Array<U32> & List<&2, Wad.Lump>:
  Wad.dir.headed(B.Bytes.file.list(a, 0, 12))

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

# Named lumps gathered from the opened WAD, in the requested order.
def Wad.lumps.read(bytes: List<&2, List<&2, U32>>, p: Array<U32> & List<&2, U32>) ->
  Array<U32> & List<&2, List<&2, U32>>:
  (a, lump) = p
  (a, lump <> bytes)

def Wad.lumps.at(p: Array<U32> & List<&2, List<&2, U32>>, q: U32 & U32) ->
  Array<U32> & List<&2, List<&2, U32>>:
  (a, bytes) = p
  (pos, size) = q
  Wad.lumps.read(bytes, B.Bytes.file.list(a, pos, size))

def Wad.lumps(names: List<&2, String>, +dir: List<&2, Wad.Lump>, a: Array<U32>) ->
  Array<U32> & List<&2, List<&2, U32>>:
  match names:
    case []:
      (a, [])
    case name <> rest:
      Wad.lumps.at(Wad.lumps(rest, dir, a), Wad.find(dir, name))

def Wad.read.done(p: Array<U32> & List<&2, List<&2, U32>>) -> List<&2, List<&2, U32>>:
  (a, lumps) = p
  lumps

def Wad.read.opened(names: List<&2, String>, p: Array<U32> & List<&2, Wad.Lump>) -> List<&2, List<&2, U32>>:
  (a, dir) = p
  Wad.read.done(Wad.lumps(names, dir, a))

# The named lumps at a path, through the same indexed reader.
def Wad.read(path: String, names: List<&2, String>) -> IO(List<&2, List<&2, U32>>):
  do IO<List<&2, List<&2, U32>>>:
    bytes : Array<U32> <- IO.try(Array<U32>, B.Bytes.read(path))
    return Wad.read.opened(names, Wad.dir(bytes))
