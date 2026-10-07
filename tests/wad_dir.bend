# The WAD named by BENDOOM_IWAD is an IWAD holding PLAYPAL and E1M1;
# DOOM1.WAD and freedoom1.wad answer the same lines.
import Base
import ../src/bytes.bend as B
import ../src/wad.bend as W

def kind(h: W.Wad.Header) -> String:
  W.Header{+k, count, dir} = h
  Bool.pick(String, U32.is_eq(k, 1), "IWAD",
    Bool.pick(String, U32.is_eq(k, 2), "PWAD", "not a WAD"))

def found(m: Maybe<Nat>) -> String:
  match m:
    case None{}:
      "missing"
    case Some{i}:
      "found"

def report(p: Array<U32> & List<&2, W.Wad.Lump>) -> IO(Unit):
  (a, +lumps) = p
  do IO<Unit>:
    IO.print("PLAYPAL " ++ found(W.Wad.index("PLAYPAL", lumps)))
    IO.print("E1M1 " ++ found(W.Wad.index("E1M1", lumps)))

def header(p: Array<U32> & List<&2, U32>) -> IO(Unit):
  (a, bytes) = p
  do IO<Unit>:
    IO.print(kind(W.Wad.Header.of(bytes)))
    report(W.Wad.dir(a))

def main() -> IO(Unit):
  do IO<Unit>:
    path : String <- IO.try(String, IO.get_env("BENDOOM_IWAD"))
    bytes : Array<U32> <- IO.try(Array<U32>, B.Bytes.read(path))
    header(B.Bytes.file.list(bytes, 0, 12))

#|IWAD
#|PLAYPAL found
#|E1M1 found
