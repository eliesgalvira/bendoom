# Files packed four little-endian bytes per U32, and readers for packed
# files and ordinary word arrays. Binary output leaves Bend as hex.
import Base

def Bytes.fold.next(~S: Type, ~step: List<&2, U32> -> S -> S, bytes: List<&2, U32>, file: File, s: S,
  more: File -> S -> IO(S)) -> IO(S):
  match bytes:
    case []:
      IO.bind(Unit, S, File.close(file), u => IO.pure(S, s))
    case b <> rest:
      more(file, step(b <> rest, s))

def Bytes.fold.chunk(~S: Type, ~step: List<&2, U32> -> S -> S,
  p: File & Result<&1, &1, U32 & String, List<&2, U32>>, s: S, more: File -> S -> IO(S)) -> IO(S):
  (file, got) = p
  IO.bind(List<&2, U32>, S, IO.pass(List<&2, U32>, got), bytes => Bytes.fold.next(~S, ~step, bytes, file, s, more))

def Bytes.fold.go(~S: Type, ~step: List<&2, U32> -> S -> S, fuel: Nat, file: File, s: S) -> IO(S):
  match fuel:
    case 0n:
      IO.pure(S, s)
    case 1n+f:
      IO.bind(File & Result<&1, &1, U32 & String, List<&2, U32>>, S, File.read_bytes(file, 4096),
        p => Bytes.fold.chunk(~S, ~step, p, s, h => t => Bytes.fold.go(~S, ~step, f, h, t)))

# An open file's chunks folded into a state, first to last, until a read
# comes back empty, and the file closed. A chunk is at most 4096 bytes,
# so a step that recurses once a byte is safe on the JS lane.
def Bytes.fold(~S: Type, ~step: List<&2, U32> -> S -> S, file: File, s: S) -> IO(S):
  Bytes.fold.go(~S, ~step, U32.to_nat(4294967295), file, s)

type Bytes.Fill is Type:
  Fill{a: Array<U32>, i: U32}

def Bytes.fill.put(+i: U32, b: U32, p: Array<U32> & U32) -> Array<U32>:
  (a, word) = p
  Array.set(U32, a, (i >> 2n : U32), (word .|. (b << U32.to_nat(((i .&. 3 : U32) * 8 : U32))) : U32))

def Bytes.fill.go(bytes: List<&2, U32>, a: Array<U32>, +i: U32) -> Bytes.Fill:
  match bytes:
    case []:
      Fill{a, i}
    case b <> rest:
      Bytes.fill.go(rest, Bytes.fill.put(i, b, a[(i >> 2n : U32)]), (i + 1 : U32))

def Bytes.fill(bytes: List<&2, U32>, s: Bytes.Fill) -> Bytes.Fill:
  Fill{a, i} = s
  Bytes.fill.go(bytes, a, i)

def Bytes.read.done(s: Bytes.Fill) -> IO(Result<&1, &1, U32 & String, Array<U32>>):
  Fill{a, i} = s
  IO.pure(Result<&1, &1, U32 & String, Array<U32>>, Done{a})

def Bytes.read.size(file: File, r: Result<&1, &1, U32 & String, U32>) -> IO(Result<&1, &1, U32 & String, Array<U32>>):
  match r:
    case Fail{e}:
      IO.bind(Unit, Result<&1, &1, U32 & String, Array<U32>>, File.close(file),
        u => IO.pure(Result<&1, &1, U32 & String, Array<U32>>, Fail{e}))
    case Done{+n}:
      +count = ((n >> 2n) + Bool.to_u32(Bool.not(U32.is_eq((n .&. 3 : U32), 0))) : U32)
      +d = U32.log2(count)
      +depth = Nat.add(d, U32.to_nat(Bool.to_u32(U32.is_lt((1 << d : U32), count))))
      IO.bind(Bytes.Fill, Result<&1, &1, U32 & String, Array<U32>>,
        Bytes.fold(~Bytes.Fill, ~Bytes.fill, file, Fill{Array.new(U32, depth, 0), 0}), Bytes.read.done)

def Bytes.read.sized(p: File & Result<&1, &1, U32 & String, U32>) -> IO(Result<&1, &1, U32 & String, Array<U32>>):
  (file, r) = p
  Bytes.read.size(file, r)

def Bytes.read.opened(r: Result<&1, &1, U32 & String, File>) -> IO(Result<&1, &1, U32 & String, Array<U32>>):
  match r:
    case Fail{e}:
      IO.pure(Result<&1, &1, U32 & String, Array<U32>>, Fail{e})
    case Done{file}:
      IO.bind(File & Result<&1, &1, U32 & String, U32>, Result<&1, &1, U32 & String, Array<U32>>, File.size(file), Bytes.read.sized)

def Bytes.read(path: String) -> IO(Result<&1, &1, U32 & String, Array<U32>>):
  IO.bind(Result<&1, &1, U32 & String, File>, Result<&1, &1, U32 & String, Array<U32>>, File.open(path, "r"), Bytes.read.opened)

def Bytes.hex.digit(+d: U32) -> Char:
  Char.from_u32(Bool.pick(U32, U32.is_lt(d, 10), (48 + d : U32), (87 + d : U32)))

# The low byte of each cell as two hex digits. It recurses once a byte,
# which is four times faster natively than a loop over the reversed
# list, so on the JS lane it takes short runs only.
def Bytes.hex(bytes: List<&2, U32>) -> String:
  match bytes:
    case []:
      ""
    case +b <> rest:
      SCon{Bytes.hex.digit(((b >> 4n) .&. 15 : U32)), SCon{Bytes.hex.digit((b .&. 15 : U32)), Bytes.hex(rest)}}

def Bytes.put_hex.done(p: File & Result<&1, &1, U32 & String, Unit>) -> IO(File):
  (file, done) = p
  IO.bind(Unit, File, IO.pass(Unit, done), u => IO.pure(File, file))

# The bytes written to an open file as hex, or the program dies with
# the error.
def Bytes.put_hex(file: File, bytes: List<&2, U32>) -> IO(File):
  IO.bind(File & Result<&1, &1, U32 & String, Unit>, File, File.write(file, Bytes.hex(bytes)), Bytes.put_hex.done)

def Bytes.at(a: Array<U32>, +i: U32) -> Array<U32> & U32:
  a[i]

def Bytes.file.got(+i: U32, p: Array<U32> & U32) -> Array<U32> & U32:
  (a, word) = p
  (a, ((word >> U32.to_nat(((i .&. 3 : U32) * 8 : U32))) .&. 255 : U32))

def Bytes.file.at(a: Array<U32>, +i: U32) -> Array<U32> & U32:
  Bytes.file.got(i, a[(i >> 2n : U32)])

def Bytes.le32(+b0: U32, +b1: U32, +b2: U32, +b3: U32) -> U32:
  (b0 .|. (b1 << 8n) .|. (b2 << 16n) .|. (b3 << 24n) : U32)

def Bytes.le16(+b0: U32, +b1: U32) -> U32:
  (b0 .|. (b1 << 8n) : U32)

def Bytes.u32.fin(b0: U32, b1: U32, b2: U32, p: Array<U32> & U32) ->
  Array<U32> & U32:
  (a, b3) = p
  (a, Bytes.le32(b0, b1, b2, b3))

def Bytes.u32.b3(~read: Array<U32> -> @+i: U32 -> Array<U32> & U32, +i: U32, b0: U32, b1: U32, p: Array<U32> & U32) ->
  Array<U32> & U32:
  (a, b2) = p
  Bytes.u32.fin(b0, b1, b2, read(a, (i + 3 : U32)))

def Bytes.u32.b2(~read: Array<U32> -> @+i: U32 -> Array<U32> & U32, +i: U32, b0: U32, p: Array<U32> & U32) ->
  Array<U32> & U32:
  (a, b1) = p
  Bytes.u32.b3(~read, i, b0, b1, read(a, (i + 2 : U32)))

def Bytes.u32.b1(~read: Array<U32> -> @+i: U32 -> Array<U32> & U32, +i: U32, p: Array<U32> & U32) -> Array<U32> & U32:
  (a, b0) = p
  Bytes.u32.b2(~read, i, b0, read(a, (i + 1 : U32)))

def Bytes.word32(~read: Array<U32> -> @+i: U32 -> Array<U32> & U32, a: Array<U32>, +i: U32) -> Array<U32> & U32:
  Bytes.u32.b1(~read, i, read(a, i))

def Bytes.u16.fin(b0: U32, p: Array<U32> & U32) -> Array<U32> & U32:
  (a, b1) = p
  (a, Bytes.le16(b0, b1))

def Bytes.u16.b1(~read: Array<U32> -> @+i: U32 -> Array<U32> & U32, +i: U32, p: Array<U32> & U32) -> Array<U32> & U32:
  (a, b0) = p
  Bytes.u16.fin(b0, read(a, (i + 1 : U32)))

def Bytes.word16(~read: Array<U32> -> @+i: U32 -> Array<U32> & U32, a: Array<U32>, +i: U32) -> Array<U32> & U32:
  Bytes.u16.b1(~read, i, read(a, i))

def Bytes.u32(a: Array<U32>, +i: U32) -> Array<U32> & U32:
  Bytes.word32(~Bytes.at, a, i)

def Bytes.u16(a: Array<U32>, +i: U32) -> Array<U32> & U32:
  Bytes.word16(~Bytes.at, a, i)

def Bytes.file.u32(a: Array<U32>, +i: U32) -> Array<U32> & U32:
  Bytes.word32(~Bytes.file.at, a, i)

def Bytes.file.u16(a: Array<U32>, +i: U32) -> Array<U32> & U32:
  Bytes.word16(~Bytes.file.at, a, i)

def Bytes.text.cut(z: Bool, c: U32, rest: List<&2, Char>) -> List<&2, Char>:
  match z:
    case True{}:
      []
    case False{}:
      Char.from_u32(c) <> rest

def Bytes.text.cons(+c: U32, rest: List<&2, Char>) -> List<&2, Char>:
  Bytes.text.cut(U32.is_zero(c), c, rest)

def Bytes.text.join(rest: List<&2, Char>, q: Array<U32> & U32) ->
  Array<U32> & List<&2, Char>:
  (a, c) = q
  (a, Bytes.text.cons(c, rest))

def Bytes.text.read(+i: U32, p: Array<U32> & List<&2, Char>) ->
  Array<U32> & List<&2, Char>:
  (a, rest) = p
  Bytes.text.join(rest, Bytes.file.at(a, i))

# The bytes after i are gathered first, then the byte at i is consed on:
# a loop over a linear array recurses before it reads, and the shrinking
# count goes first, or the termination checker refuses it.
def Bytes.text.go(n: Nat, a: Array<U32>, +i: U32) ->
  Array<U32> & List<&2, Char>:
  match n:
    case 0n:
      (a, [])
    case 1n+m:
      Bytes.text.read(i, Bytes.text.go(m, a, (i + 1 : U32)))

def Bytes.text.pack(p: Array<U32> & List<&2, Char>) -> Array<U32> & String:
  (a, cs) = p
  (a, String.from_list(cs))

# The n bytes at i as a string, cut at the first NUL.
def Bytes.text(a: Array<U32>, +i: U32, n: Nat) -> Array<U32> & String:
  Bytes.text.pack(Bytes.text.go(n, a, i))

def Bytes.name.up(p: Array<U32> & String) -> Array<U32> & String:
  (a, s) = p
  (a, String.to_upper(s))

# A lump, texture or flat name: eight bytes, matched without case as
# Doom matches them, so read in upper case.
def Bytes.name(a: Array<U32>, +i: U32) -> Array<U32> & String:
  Bytes.name.up(Bytes.text(a, i, 8n))

def Bytes.each.join(~T: Data, rest: List<&2, T>, q: Array<U32> & T) ->
  Array<U32> & List<&2, T>:
  (a, x) = q
  (a, x <> rest)

def Bytes.each.cons(~T: Data, ~read: Array<U32> -> @+i: U32 -> Array<U32> & T, i: U32,
  p: Array<U32> & List<&2, T>) -> Array<U32> & List<&2, T>:
  (a, rest) = p
  Bytes.each.join(~T, rest, read(a, i))

# One read at each offset, the later offsets first so the list comes
# out in order: every lump is read by planning its offsets, then this.
def Bytes.each(~T: Data, ~read: Array<U32> -> @+i: U32 -> Array<U32> & T, offs: List<&2, U32>,
  a: Array<U32>) -> Array<U32> & List<&2, T>:
  match offs:
    case []:
      (a, [])
    case i <> rest:
      Bytes.each.cons(~T, ~read, i, Bytes.each(~T, ~read, rest, a))

def Bytes.fields.one(fields: List<&2, U32>, +i: U32, tail: List<&2, U32>) -> List<&2, U32>:
  match fields:
    case []:
      tail
    case f <> rest:
      (i + f : U32) <> Bytes.fields.one(rest, i, tail)

# The offsets of the given fields in each of n records of stride bytes
# from i, record by record.
def Bytes.fields(n: Nat, +i: U32, +stride: U32, +fields: List<&2, U32>) -> List<&2, U32>:
  match n:
    case 0n:
      []
    case 1n+m:
      Bytes.fields.one(fields, i, Bytes.fields(m, (i + stride : U32), stride, fields))

def Bytes.lists.join(~T: Data, rest: List<&2, List<&2, T>>, q: Array<U32> & List<&2, T>) ->
  Array<U32> & List<&2, List<&2, T>>:
  (a, xs) = q
  (a, xs <> rest)

def Bytes.lists.cons(~T: Data, ~read: Array<U32> -> @+i: U32 -> Array<U32> & T, offs: List<&2, U32>,
  p: Array<U32> & List<&2, List<&2, T>>) -> Array<U32> & List<&2, List<&2, T>>:
  (a, rest) = p
  Bytes.lists.join(~T, rest, Bytes.each(~T, ~read, offs, a))

# Bytes.each over each plan of a list, a list of reads a plan.
def Bytes.lists(~T: Data, ~read: Array<U32> -> @+i: U32 -> Array<U32> & T,
  plans: List<&2, List<&2, U32>>, a: Array<U32>) -> Array<U32> & List<&2, List<&2, T>>:
  match plans:
    case []:
      (a, [])
    case offs <> rest:
      Bytes.lists.cons(~T, ~read, offs, Bytes.lists(~T, ~read, rest, a))

# A long run of bytes as a list, read from its last byte back to its
# first by a loop whose body is not recursive, so the run's length is no
# recursion depth on the JS lane.
type Bytes.Run is Type:
  Run{a: Array<U32>, i: U32, acc: List<&2, U32>}

def Bytes.run.put(+i: U32, acc: List<&2, U32>, p: Array<U32> & U32) -> Bytes.Run:
  (a, b) = p
  Run{a, (i - 1 : U32), b <> acc}

def Bytes.run.step(~read: Array<U32> -> @+i: U32 -> Array<U32> & U32, r: Bytes.Run) -> Bytes.Run:
  Run{a, +i, acc} = r
  Bytes.run.put(i, acc, read(a, i))

def Bytes.run.go(~read: Array<U32> -> @+i: U32 -> Array<U32> & U32, n: Nat, r: Bytes.Run) -> Bytes.Run:
  match n:
    case 0n:
      r
    case 1n+m:
      Bytes.run.go(~read, m, Bytes.run.step(~read, r))

def Bytes.run.fin(r: Bytes.Run) -> Array<U32> & List<&2, U32>:
  Run{a, i, acc} = r
  (a, acc)

# The n bytes at i.
def Bytes.list(a: Array<U32>, +i: U32, +n: U32) -> Array<U32> & List<&2, U32>:
  Bytes.run.fin(Bytes.run.go(~Bytes.at, U32.to_nat(n), Run{a, (i + n - 1 : U32), []}))

def Bytes.file.list(a: Array<U32>, +i: U32, +n: U32) -> Array<U32> & List<&2, U32>:
  Bytes.run.fin(Bytes.run.go(~Bytes.file.at, U32.to_nat(n), Run{a, (i + n - 1 : U32), []}))
