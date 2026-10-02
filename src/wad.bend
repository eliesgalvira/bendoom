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

# Reading lumps from the file
# ---------------------------

# A run of a file's bytes, size long from pos, gathered as the file
# streams past, latest first.
type Wad.Cut is Data:
  Cut{pos: U32, size: U32, got: List<&2, U32>}

# The file's place at the next chunk, and the runs being gathered.
type Wad.Pass is Data:
  Pass{at: U32, cuts: List<&2, Wad.Cut>}

def Wad.piece.go(none: Bool, +skip: U32, +n: U32, chunk: List<&2, U32>, c: Wad.Cut) -> Wad.Cut:
  match none:
    case True{}:
      c
    case False{}:
      Cut{pos, size, got} = c
      Cut{pos, size, List.reverse.go(&2, U32, List.take(&2, U32, List.drop(&2, U32, chunk, U32.to_nat(skip)),
        U32.to_nat(n)), got)}

# The bytes of a chunk of n bytes at the file's place `at` that fall in a
# cut, gathered.
def Wad.piece(+at: U32, +n: U32, +chunk: List<&2, U32>, +c: Wad.Cut) -> Wad.Cut:
  Cut{+pos, +size, got} = c
  +from = U32.max(pos, at)
  +upto = U32.max(U32.min((pos + size : U32), (at + n : U32)), from)
  Wad.piece.go(U32.is_eq(upto, from), (from - at : U32), (upto - from : U32), chunk, c)

def Wad.pieces(+at: U32, +n: U32, +chunk: List<&2, U32>, cuts: List<&2, Wad.Cut>) -> List<&2, Wad.Cut>:
  match cuts:
    case []:
      []
    case c <> rest:
      Wad.piece(at, n, chunk, c) <> Wad.pieces(at, n, chunk, rest)

def Wad.passed.of(+chunk: List<&2, U32>, p: Wad.Pass) -> Wad.Pass:
  Pass{+at, cuts} = p
  +n = U32.from_nat(List.length(&2, U32, chunk))
  Pass{(at + n : U32), Wad.pieces(at, n, chunk, cuts)}

def Wad.passed(chunk: List<&2, U32>, p: Wad.Pass) -> Wad.Pass:
  Wad.passed.of(chunk, p)

def Wad.Pass.cuts(p: Wad.Pass) -> IO(List<&2, Wad.Cut>):
  Pass{at, cuts} = p
  IO.pure(List<&2, Wad.Cut>, cuts)

# The rest of an open file streamed past the cuts from the place at.
def Wad.pass(file: File, +at: U32, cuts: List<&2, Wad.Cut>) -> IO(List<&2, Wad.Cut>):
  IO.bind(Wad.Pass, List<&2, Wad.Cut>, B.Bytes.fold(~Wad.Pass, ~Wad.passed, file, Pass{at, cuts}), Wad.Pass.cuts)

def Wad.Cut.all(cuts: List<&2, Wad.Cut>) -> List<&2, List<&2, U32>>:
  match cuts:
    case []:
      []
    case Cut{pos, size, got} <> rest:
      List.reverse(&2, U32, got) <> Wad.Cut.all(rest)

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

def Wad.listed(+count: U32, cuts: List<&2, List<&2, U32>>) -> List<&2, Wad.Lump>:
  match cuts:
    case []:
      []
    case bytes <> rest:
      Wad.entries(U32.to_nat(count), bytes)

def Wad.headed(file: File, h: Wad.Header) -> IO(List<&2, Wad.Lump>):
  Header{kind, +count, dir} = h
  IO.bind(List<&2, Wad.Cut>, List<&2, Wad.Lump>, Wad.pass(file, 12, [Cut{dir, (count * 16 : U32), []}]),
    cuts => IO.pure(List<&2, Wad.Lump>, Wad.listed(count, Wad.Cut.all(cuts))))

def Wad.header.read(p: File & Result<&1, &1, U32 & String, List<&2, U32>>) -> IO(List<&2, Wad.Lump>):
  (file, got) = p
  Wad.headed(file, Wad.Header.of(Result.default(&1, &1, U32 & String, List<&2, U32>, got, [])))

def Wad.cut(p: U32 & U32) -> Wad.Cut:
  (pos, size) = p
  Cut{pos, size, []}

def Wad.cuts(+lumps: List<&2, Wad.Lump>, names: List<&2, String>) -> List<&2, Wad.Cut>:
  match names:
    case []:
      []
    case name <> rest:
      Wad.cut(Wad.find(lumps, name)) <> Wad.cuts(lumps, rest)

# The bytes of the named lumps of the WAD at a path, none for a name it
# lacks, read as W_CacheLumpName reads them, from the file: one pass for
# the directory, after the header, and one for the lumps, so no more
# than a chunk of the file is held at once.
def Wad.read(+path: String, names: List<&2, String>) -> IO(List<&2, List<&2, U32>>):
  do IO<List<&2, List<&2, U32>>>:
    head : File <- IO.try(File, File.open(path, "r"))
    p : File & Result<&1, &1, U32 & String, List<&2, U32>> <- File.read_bytes(head, 12)
    lumps : List<&2, Wad.Lump> <- Wad.header.read(p)
    file : File <- IO.try(File, File.open(path, "r"))
    cuts : List<&2, Wad.Cut> <- Wad.pass(file, 0, Wad.cuts(lumps, names))
    return Wad.Cut.all(cuts)
