# Expected heights and timing are calculated from Chocolate Doom p_floor.c:
# build8 raises at FRACUNIT/4, adds 8*FRACUNIT per matching candidate,
# and completes only on the call after it reaches its destination.
import Base
import ../src/vec.bend as V
import ../src/level.bend as L
import ../src/fixed.bend as F
import ../src/sim.bend as S
import ../src/special.bend as Sp
import ./fixtures/closed.bend as Fx

def geometry(lines: List<&2, U32>, sides: List<&2, U32>, +level: L.Level) -> L.Level:
  L.Level{L.Geo{ls, ss, verts, segs, subs, nodes, root, blockmap, things, texnames, flatnames, sine, tanto,
    boxes, nlines, nsectors, reject, sidetex, switches}, sectors, specials, heard} = level
  L.Level{L.Geo{V.Vec.of_list(lines, 10), V.Vec.of_list(sides, 9), verts, segs, subs, nodes, root, blockmap,
    things, texnames, ["STEP", "CEIL", "STEP", "CEIL", "STEP", "CEIL"], sine, tanto, boxes, nlines, nsectors, reject, sidetex, switches},
    sectors, V.Vec.of_list([8, 7, 0, 0], 4), heard}

def level(lines: List<&2, U32>, sides: List<&2, U32>) -> L.Level:
  geometry(lines, sides, L.Level.sector.put(L.Level.plane.put(Fx.Closed.doors(), 1, True{}, 8388608), 0, 6, 7))

def state(lines: List<&2, U32>, sides: List<&2, U32>) -> S.State:
  Fx.Closed.state(Fx.Closed.player(13107200, 4194304, 0, 8388608), level(lines, sides), 0)

def chain() -> S.State:
  state([0, 1, 4, 0, 1, 2, 3, 4, 1, 2], [0, 0, 0, 0, 0, 1, 0, 0, 2])

def reverse() -> S.State:
  state([0, 1, 4, 0, 1, 2, 3, 4, 2, 1], [0, 0, 0, 0, 0, 1, 0, 0, 2])

def occupied() -> S.State:
  Sp.Sim.mover.begin(1, False{}, 16384, [S.Hold{200}], Sp.Sim.noise.floor(),
    state([0, 1, 4, 0, 1, 2, 3, 4, 0, 2], [0, 0, 0, 0, 0, 1, 0, 0, 2]))

def changed(+s: S.State, sector: U32, field: U32, value: U32) -> S.State:
  S.State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn, totalsecret} = s
  S.State{player, L.Level.sector.put(level, sector, field, value), things, sidetex, thinkers, rnd, clock, ended,
    usedown, sounds, mrnd, reborn, totalsecret}

def targets(ts: List<&2, S.Thinker>) -> String:
  match ts:
    case []:
      ""
    case S.Mover{sector, ceiling, speed, S.Travel{down, dest} <> rest, plan, noise} <> due:
      " " ++ U32.show(sector) ++ ":" ++ F.Fixed.show(dest) ++ targets(due)
    case _ <> due:
      targets(due)

def planned(tag: String, s: S.State) -> IO(Unit):
  IO.print(tag ++ targets(S.State.thinkers(s)))

def floors(tag: String, +s: S.State) -> IO(Unit):
  +l = S.State.level(s)
  IO.print(tag ++ " " ++ F.Fixed.show(L.Level.floor(l, 0)) ++ " " ++ F.Fixed.show(L.Level.floor(l, 1))
    ++ " " ++ F.Fixed.show(L.Level.floor(l, 2)))

def active(tag: String, +s: S.State) -> IO(Unit):
  IO.print(tag ++ " " ++ Bool.show(Sp.Sim.moving(S.State.thinkers(s), 2)))

def special(tag: String, s: S.State) -> IO(Unit):
  IO.print(tag ++ " " ++ U32.show(L.Level.special(S.State.level(s), 0)))

# A chain from 0 to 2 skips the unvisited tagged sector 1.
# A chain ending at 0 resumes at 1. Its occupied neighbour 0 consumes
# another height increment before its free neighbour 2.
def skipped() -> S.State:
  changed(state([0, 1, 4, 0, 2, 2, 3, 4, 1, 0],
    [0, 0, 0, 0, 0, 1, 0, 0, 2]), 1, 6, 7)

def roots() -> S.State:
  changed(changed(state([0, 1, 4, 1, 0, 2, 3, 4, 1, 2],
    [0, 0, 0, 0, 0, 1, 0, 0, 2]), 1, 6, 7), 1, 0, 262144)

def main() -> IO(Unit):
  do IO<Unit>:
    planned("chain", Sp.Sim.stairs(0, chain()))
    planned("same flat name", Sp.Sim.stairs(0, changed(changed(chain(), 1, 2, 2), 2, 2, 4)))
    planned("reverse", Sp.Sim.stairs(0, reverse()))
    planned("different flat", Sp.Sim.stairs(0, changed(chain(), 1, 2, 1)))
    planned("occupied candidate", Sp.Sim.stairs(0, occupied()))
    planned("occupied root", Sp.Sim.stairs(0, Sp.Sim.mover.begin(0, False{}, 16384,
      [S.Hold{200}], Sp.Sim.noise.floor(), chain())))
    planned("skipped root", Sp.Sim.stairs(0, skipped()))
    planned("later root", Sp.Sim.stairs(0, roots()))
    floors("32 calls", Fx.Closed.idled(32n, Sp.Sim.stairs(0, chain())))
    floors("64 calls", Fx.Closed.idled(64n, Sp.Sim.stairs(0, chain())))
    floors("96 calls", Fx.Closed.idled(96n, Sp.Sim.stairs(0, chain())))
    active("at target", Fx.Closed.idled(96n, Sp.Sim.stairs(0, chain())))
    active("past target", Fx.Closed.idled(97n, Sp.Sim.stairs(0, chain())))
    special("empty crossing", Sp.Sim.cross.special(8, 0, 0, S.Cross{0, 0, 0, 0, 0}, changed(chain(), 0, 6, 0)))
    special("empty use", Sp.Sim.use.special(7, 0, True{}, changed(chain(), 0, 6, 0)))
    special("successful use", Sp.Sim.use.special(7, 0, True{}, chain()))
    special("back use", Sp.Sim.use.line(True{}, S.State.level(chain()), 0, chain()))
    IO.print("monster crossing " ++ Bool.show(Sp.Sim.thing.cross.special(8)))
    IO.print("monster use " ++ Bool.show(Sp.Sim.thing.use.special(7)))

#|chain 0:8.000000 1:16.000000 2:24.000000
#|same flat name 0:8.000000 1:16.000000 2:24.000000
#|reverse 0:8.000000 1:16.000000
#|different flat 0:8.000000
#|occupied candidate 0:8.000000 2:24.000000
#|occupied root
#|skipped root 0:8.000000 2:16.000000
#|later root 0:8.000000 1:12.000000 2:28.000000
#|32 calls 8.000000 8.000000 8.000000
#|64 calls 8.000000 16.000000 16.000000
#|96 calls 8.000000 16.000000 24.000000
#|at target True
#|past target False
#|empty crossing 0
#|empty use 8
#|successful use 0
#|back use 8
#|monster crossing False
#|monster use False
