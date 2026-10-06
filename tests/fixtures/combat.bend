import Base
import ../../src/level.bend as L
import ../../src/things.bend as H
import ../../src/vec.bend as V
import ../../src/sim.bend as S
import ../../src/tic.bend as Tic
import ../../src/keys.bend as K

# The E1M1 monsters removed, every other record kept in its order and
# bytes, so P_SpawnMapThing draws in the same order.
def Combat.clear(n: Nat, +i: U32, +records: V.Vec) -> V.Vec:
  match n:
    case 0n:
      records
    case 1n+k:
      +at = (i * 5 + 3 : U32)
      +kind = V.Vec.get(records, at)
      Combat.clear(k, (i + 1 : U32), V.Vec.set(records, at,
        Bool.pick(U32, Bool.not(U32.is_zero((H.Thing.Def.flags(H.Thing.info(kind)) .&. 4194304 : U32))), 0, kind)))

def Combat.cleared(level: L.Level) -> L.Level:
  L.Level{L.Geo{lines, sides, verts, segs, subs, nodes, root, blockmap, L.Things{records, +count}, texnames,
    flatnames, sine, tanto, boxes, nlines, nsectors, reject, sidetex, switches}, sectors, specials, heard} = level
  L.Level{L.Geo{lines, sides, verts, segs, subs, nodes, root, blockmap,
    L.Things{Combat.clear(U32.to_nat(count), 0, records), count},
    texnames, flatnames, sine, tanto, boxes, nlines, nsectors, reject, sidetex, switches}, sectors, specials, heard}

# The oracle's --things: one record rewritten in place as a thing of a
# kind at x, y facing east with options 7.
def Combat.placed(level: L.Level, +id: U32, x: U32, y: U32, kind: U32) -> L.Level:
  L.Level{L.Geo{lines, sides, verts, segs, subs, nodes, root, blockmap, L.Things{records, count}, texnames,
    flatnames, sine, tanto, boxes, nlines, nsectors, reject, sidetex, switches}, sectors, specials, heard} = level
  +at = (id * 5 : U32)
  L.Level{L.Geo{lines, sides, verts, segs, subs, nodes, root, blockmap,
    L.Things{V.Vec.set(V.Vec.set(V.Vec.set(V.Vec.set(V.Vec.set(records,
      at, x), (at + 1 : U32), y), (at + 2 : U32), 0), (at + 3 : U32), kind), (at + 4 : U32), 7), count},
    texnames, flatnames, sine, tanto, boxes, nlines, nsectors, reject, sidetex, switches}, sectors, specials, heard}

# One monster alone on the map.
def Combat.isolated(level: L.Level, +id: U32, x: U32, y: U32, kind: U32) -> L.Level:
  Combat.placed(Combat.cleared(level), id, x, y, kind)

def Combat.door(level: L.Level) -> S.State:
  Tic.State.at(Combat.isolated(level, 265, 448, 2088, 3004), L.Start{29360128, 134217728, 1073741824})

def Combat.fought(level: L.Level) -> S.State:
  Tic.Sim.replay(List.concat(&2, K.Cmd, [List.replicate(K.Cmd, 20n, K.Cmd.idle()),
    [K.Cmd.demo(0, 0, 0, 2)], List.replicate(K.Cmd, 19n, K.Cmd.demo(0, 0, 0, 1))]), Combat.door(level))

# The isolated zombieman dies across door 80. Its closing ceiling turns
# the corpse into POL5A0 and removes the dropped clip. This 360-tic
# demo matches Chocolate Doom, including the final S_GIBS state.
def Combat.crushed(level: L.Level) -> S.State:
  Tic.Sim.replay(List.concat(&2, K.Cmd, [List.replicate(K.Cmd, 20n, K.Cmd.idle()), [K.Cmd.demo(0, 0, 0, 2)],
    List.replicate(K.Cmd, 60n, K.Cmd.demo(0, 0, 0, 1)), [K.Cmd.demo(0, 0, 32, 1)],
    List.replicate(K.Cmd, 28n, K.Cmd.demo(0, 0, 0, 1)), List.replicate(K.Cmd, 250n, K.Cmd.idle())]),
    Combat.door(level))
