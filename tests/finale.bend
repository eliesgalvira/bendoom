# f_finale.c defines TEXTSPEED3, TEXTWAIT250 and the440-byte E1TEXT.
import Base
import ../src/finale.bend as F

def tick(n: Nat, f: F.Finale) -> F.Finale:
  match n:
    case 0n:
      f
    case 1n+m:
      tick(m, F.Finale.tic(f))

def shown(tag: String, f: F.Finale) -> String:
  F.Finale{+count, art} = f
  tag ++ " count " ++ U32.show(count) ++ " art " ++ Bool.show(art) ++ " budget " ++ U32.show(F.Finale.budget(count))

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(shown("start", F.Finale.start()))
    IO.print(shown("before first", tick(12n, F.Finale.start())))
    IO.print(shown("first", tick(13n, F.Finale.start())))
    IO.print(shown("full", tick(1330n, F.Finale.start())))
    IO.print(shown("last text", tick(1570n, F.Finale.start())))
    IO.print(shown("art", tick(1571n, F.Finale.start())))
    IO.print(shown("art stays", tick(1800n, F.Finale.start())))

#|start count 0 art False budget 0
#|before first count 12 art False budget 0
#|first count 13 art False budget 1
#|full count 1330 art False budget 440
#|last text count 1570 art False budget 520
#|art count 0 art True budget 0
#|art stays count 229 art True budget 73
