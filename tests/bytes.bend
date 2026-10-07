# File capacity is a power of two bytes, at least four. ASCII a is 97,
# abc sums to 294, and 4096 a bytes sum to 397312.
# Binary bytes 00 ff 80 01 78 56 34 12 give little-endian words
# 0180ff00, 34567801 and 12345678 at offsets 0, 3 and 4.
# Hex uses the low byte. WAD kinds are the IWAD/PWAD little-endian words.
import Base
import ../src/bytes.bend as B
import ../src/wad.bend as W
import ../src/vec.bend as V

def ints(xs: List<&2, U32>) -> String:
  match xs:
    case []:
      ""
    case x <> rest:
      " " ++ U32.show(x) ++ ints(rest)

def add(sum: U32, b: U32) -> U32:
  (sum + b : U32)

def summed(p: Array<U32> & List<&2, U32>) -> String:
  (a, +slots) = p
  ints(List.take(&2, U32, slots, 5n)) ++ " | sum " ++ U32.show(List.foldl(~&2, ~U32, ~U32, ~add, slots, 0))

def sized(p: Array<U32> & U32) -> String:
  (a, +size) = p
  U32.show((size * 4 : U32)) ++ " bytes |" ++ summed(B.Bytes.file.list(a, 0, (size * 4 : U32)))

def wrote(p: File & Result<&1, &1, U32 & String, Unit>) -> IO(Unit):
  (file, done) = p
  File.close(file)

def show(tag: String, text: String) -> IO(Unit):
  do IO<Unit>:
    file : File <- IO.try(File, File.open("bytes.scratch", "w"))
    IO.bind(File & Result<&1, &1, U32 & String, Unit>, Unit, File.write(file, text), wrote)
    bytes : Array<U32> <- IO.try(Array<U32>, B.Bytes.read("bytes.scratch"))
    IO.print(tag ++ ": " ++ sized(Array.size(U32, bytes)))

def words(p: Array<U32> & List<&2, U32>) -> IO(Unit):
  (a, values) = p
  IO.print("packed words" ++ ints(values))

def binary() -> IO(Unit):
  do IO<Unit>:
    file : File <- IO.try(File, File.open("bytes.scratch", "w"))
    IO.bind(File & Result<&1, &1, U32 & String, Unit>, Unit,
      File.write_bytes(file, [0, 255, 128, 1, 120, 86, 52, 18]), wrote)
    bytes : Array<U32> <- IO.try(Array<U32>, B.Bytes.read("bytes.scratch"))
    words(B.Bytes.each(~U32, ~B.Bytes.file.u32, [0, 3, 4], bytes))

def main() -> IO(Unit):
  do IO<Unit>:
    binary()
    show("empty", "")
    show("a", "a")
    show("ab", "ab")
    show("abc", "abc")
    show("abcde", "abcde")
    show("4096 a", String.repeat("a", U32.to_nat(4096)))
    show("4096 a, b", String.repeat("a", U32.to_nat(4096)) ++ "b")
    missing : Result<&1, &1, U32 & String, Array<U32>> <- B.Bytes.read("bytes.missing")
    IO.print("missing: opened " ++ Bool.show(Result.is_done(&1, &1, U32 & String, Array<U32>, missing)))
    IO.print("hex " ++ B.Bytes.hex([0, 9, 10, 15, 16, 128, 255, 427]))
    IO.print("le32" ++ ints([B.Bytes.le32(120, 86, 52, 18)]))
    IO.print("kinds" ++ ints([W.Wad.kind(1145132873), W.Wad.kind(1145132880), W.Wad.kind(0)]))
    IO.print("vec" ++ ints([V.Vec.get(V.Vec.of_list([5, 6, 7], 3), 0), V.Vec.get(V.Vec.of_list([5, 6, 7], 3), 1),
      V.Vec.get(V.Vec.of_list([5, 6, 7], 3), 2)]))

#|packed words 25231104 878082049 305419896
#|empty: 4 bytes | 0 0 0 0 | sum 0
#|a: 4 bytes | 97 0 0 0 | sum 97
#|ab: 4 bytes | 97 98 0 0 | sum 195
#|abc: 4 bytes | 97 98 99 0 | sum 294
#|abcde: 8 bytes | 97 98 99 100 101 | sum 495
#|4096 a: 4096 bytes | 97 97 97 97 97 | sum 397312
#|4096 a, b: 8192 bytes | 97 97 97 97 97 | sum 397410
#|missing: opened False
#|hex 00090a0f1080ffab
#|le32 305419896
#|kinds 1 2 0
#|vec 5 6 7
