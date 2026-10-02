# 25% kills, 40% items, no secrets, 48 seconds: WI_updateStats takes
# 175 pause tics, 13 + 21 + 1 percentage tics, and 17 time tics.
# The export adds those 227 tics and a three-second hold, 332 in all.
import Base
import ../film.bend as F
import ../src/inter.bend as I
import ../src/sim.bend as S
import ../src/keys.bend as K

def main() -> IO(Unit):
  IO.print(Nat.show(List.length(&2, K.Cmd, F.Film.outro.of(I.Inter.start(S.Tally{1, 2, 0, 4, 5, 1, 1691}, 0,
    True{})))))
#|332
