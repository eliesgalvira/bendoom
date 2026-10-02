# Where a script leaves the sim: the map MAP names (E1M1 unset) from the
# WAD named by BENDOOM_IWAD, the player put at the place FRAME names,
# and after each run of SCRIPT (tools/script.bend has both forms) a line
# of the tics run so far, the player's position, facing, height, floor
# and eye, and the floor and ceiling of each sector SECTORS lists, then
# the inventory, the things left and the records taken. How routes,
# movers' tics and pickups are found for the tests and the oracle.
#
#   bend tools/walk.bend -o walk
#   FRAME="-416 256 0" SCRIPT="34,50,0,0,0 1,0,0,0,1" SECTORS="10 98" ./walk
#   BENDOOM_IWAD=doom1.wad MAP=E1M5 FRAME="-224 -624 90" SCRIPT="35,25,0,0,0" ./walk
import Base
import ../src/bytes.bend as B
import ../src/wad.bend as W
import ../src/fixed.bend as F
import ../src/angle.bend as A
import ../src/level.bend as L
import ../src/keys.bend as K
import ../src/sim.bend as S
import ../src/things.bend as H
import ../src/inventory.bend as I
import ./script.bend as T

# A map as its marker names it, ExMy with one digit each; E0M0, which no
# WAD holds, for any other name.
def Walk.map(name: String) -> U32 & U32:
  match name:
    case SCon{Chr{69}, SCon{Chr{e}, SCon{Chr{77}, SCon{Chr{m}, SNil{}}}}}:
      ((e - 48 : U32), (m - 48 : U32))
    case _:
      (0, 0)

def Walk.named(name: String) -> Bool:
  Bool.not(String.is_empty(name))

def Walk.sectors(which: List<&2, String>, +level: L.Level) -> String:
  match which:
    case []:
      ""
    case name <> rest:
      +s = T.Script.int(name)
      " | " ++ U32.show(s) ++ " " ++ F.Fixed.show(L.Level.floor(level, s)) ++ " "
        ++ F.Fixed.show(L.Level.ceil(level, s)) ++ Walk.sectors(rest, level)

def Walk.line(+which: List<&2, String>, +first: S.State, +s: S.State) -> String:
  +p = S.State.player(s)
  "tic " ++ U32.show(S.State.clock(s)) ++ " at " ++ F.Fixed.show(S.Player.x(p)) ++ " "
    ++ F.Fixed.show(S.Player.y(p)) ++ " " ++ A.Angle.show(S.Player.angle(p)) ++ " z "
    ++ F.Fixed.show(S.Player.z(p)) ++ " floor " ++ F.Fixed.show(S.Player.floorz(p)) ++ " eye "
    ++ F.Fixed.show((S.Player.viewz(p) - S.Player.floorz(p) : U32)) ++ " ended "
    ++ Bool.show(S.State.ended(s)) ++ Walk.sectors(which, S.State.level(s)) ++ "\n  "
    ++ I.Inventory.show(S.Player.inv(p)) ++ H.Things.tally(H.Things.list(S.State.things(first)),
      S.State.things(s))

def Walk.go(runs: List<&2, List<&2, K.Cmd>>, +which: List<&2, String>, +first: S.State, +s: S.State) -> IO(Unit):
  match runs:
    case []:
      IO.print(Walk.line(which, first, s))
    case run <> rest:
      do IO<Unit>:
        IO.print(Walk.line(which, first, s))
        Walk.go(rest, which, first, S.Sim.replay(run, s))

def Walk.start(place: L.Level.Start, runs: List<&2, List<&2, K.Cmd>>, which: List<&2, String>,
  p: Array<U32> & L.Level) -> IO(Unit):
  (a, +level) = p
  +first = S.State.at(level, place)
  Walk.go(runs, which, first, first)

def Walk.load(map: U32 & U32, place: L.Level.Start, runs: List<&2, List<&2, K.Cmd>>, which: List<&2, String>,
  bytes: Array<U32>) -> IO(Unit):
  (episode, number) = map
  Walk.start(place, runs, which, L.Level.load(episode, number, W.Wad.dir(bytes)))

def main() -> IO(Unit):
  do IO<Unit>:
    path : String <- IO.try(String, IO.get_env("BENDOOM_IWAD"))
    spot : String <- IO.try(String, IO.get_env("FRAME"))
    script : String <- IO.try(String, IO.get_env("SCRIPT"))
    sectors : Result<&1, &1, U32 & String, String> <- IO.get_env("SECTORS")
    map : Result<&1, &1, U32 & String, String> <- IO.get_env("MAP")
    bytes : Array<U32> <- IO.try(Array<U32>, B.Bytes.read(path))
    Walk.load(Walk.map(Result.default(&1, &1, U32 & String, String, map, "E1M1")),
      T.Script.place(String.split(spot, ' ')), T.Script.runs(String.split(script, ' ')),
      List.filter(~String, ~Walk.named, String.split(Result.default(&1, &1, U32 & String, String, sectors, ""), ' ')),
      bytes)
