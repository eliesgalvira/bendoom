# P_RecursiveSound replayed independently in nushell over Freedoom's
# lines reaches 38 sectors from the start, or 82 with sector 100 open.
# Its two neighbouring zombiemen, records 176 and 177, have option 8:
# A_Look stores the heard target but leaves them asleep without sight.
# The three-room fixture has edges 0-1-2; one sound-block line passes,
# two stop at room 1. Targets survive a later closing door in vanilla.
import Base
import ../src/level.bend as L
import ../src/vec.bend as V
import ../src/sim.bend as S
import ../src/tic.bend as Tic
import ../src/keys.bend as K
import ../src/things.bend as H

def count(n: Nat, +i: U32, +level: L.Level) -> U32:
  match n:
    case 0n:
      0
    case 1n+k:
      (Bool.to_u32(L.Level.heard(level, i)) + count(k, (i + 1 : U32), level) : U32)

def heard(+s: S.State) -> U32:
  count(U32.to_nat(L.Level.nsectors(S.State.level(s))), 0, S.State.level(s))

def shot(level: L.Level) -> S.State:
  Tic.Sim.tic(K.Cmd.demo(0, 0, 0, 1),
    Tic.Sim.replay(List.replicate(K.Cmd, 20n, K.Cmd.idle()), Tic.State.start(level)))

def sleeping(m: Maybe<&2, H.Thing>) -> Bool:
  match m:
    case None{}:
      False{}
    case Some{+th}:
      Bool.and(H.Thing.ambush(th), Bool.or(U32.is_eq(H.Thing.state(th), 61), U32.is_eq(H.Thing.state(th), 62)))

def target(m: Maybe<&2, H.Thing>) -> U32:
  match m:
    case None{}:
      H.Thing.you()
    case Some{th}:
      H.Thing.target(th)

def ambush(+s: S.State) -> String:
  +th = H.Things.get(S.State.things(s), 176)
  "ambush asleep " ++ Bool.show(sleeping(th)) ++ " target " ++ U32.show(target(th))

def next_room(s: S.State) -> U32:
  target(H.Things.get(S.State.things(s), 265))

def corridor(base: L.Level, first: U32, second: U32) -> L.Level:
  L.Level{L.Geo{lines, sides, verts, segs, subs, nodes, root, blockmap, things, texnames, flatnames,
    sine, tanto, boxes, nlines, nsectors, reject, sidetex, switches, identity}, sectors, specials, heard} = base
  L.Level{L.Geo{V.Vec.of([0, 0, first, 0, 1, 0, 0, second, 2, 3]),
    V.Vec.of([0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 2]), verts, segs, subs, nodes, root, blockmap,
    things, texnames, flatnames, sine, tanto, boxes, 2, 3, reject, sidetex, switches, identity},
    V.Vec.of([0, 8388608, 0, 0, 160, 0, 0, 0, 8388608, 0, 0, 160, 0, 0, 0, 8388608, 0, 0, 160, 0, 0]), specials, V.Vec.of_list([], 3)}

def closed(s: S.State) -> S.State:
  S.State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn, totalsecret} = s
  S.State{player, L.Level.plane.put(level, 100, True{}, 0), things, sidetex, thinkers, rnd, clock, ended,
    usedown, sounds, mrnd, reborn, totalsecret}

def run(w: Array<U32> & L.Level) -> IO(Unit):
  (mem, +level) = w
  do IO<Unit>:
    IO.print("unfired " ++ U32.show(heard(Tic.State.start(level))))
    IO.print("closed door " ++ U32.show(heard(shot(level))))
    IO.print("open door " ++ U32.show(heard(shot(L.Level.plane.put(level, 100, True{}, 8388608)))))
    IO.print("closed again " ++ U32.show(heard(S.Sim.alert(closed(shot(L.Level.plane.put(level, 100, True{}, 8388608)))))))
    IO.print(ambush(Tic.Sim.replay(List.replicate(K.Cmd, 20n, K.Cmd.idle()), shot(level))))
    IO.print("next room closed target " ++ U32.show(next_room(
      Tic.Sim.replay(List.replicate(K.Cmd, 20n, K.Cmd.idle()), shot(level)))))
    IO.print("next room open target " ++ U32.show(next_room(
      Tic.Sim.replay(List.replicate(K.Cmd, 20n, K.Cmd.idle()), shot(L.Level.plane.put(level, 100, True{}, 8388608))))))
    IO.print("one sound block " ++ U32.show(heard(shot(corridor(L.Level.room(0, 128), 68, 4)))))
    IO.print("two sound blocks " ++ U32.show(heard(shot(corridor(L.Level.room(0, 128), 68, 68)))))

def main() -> IO(Unit):
  do IO<Unit>:
    world : Array<U32> & L.Level <- L.Level.open(1, 1)
    run(world)

#|unfired 0
#|closed door 38
#|open door 82
#|closed again 82
#|ambush asleep True target 157
#|next room closed target 4294967295
#|next room open target 157
#|one sound block 3
#|two sound blocks 2
