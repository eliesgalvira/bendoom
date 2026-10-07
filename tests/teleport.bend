# Vanilla teleport rules, including destinations outside free space.
import Base
import ../src/level.bend as L
import ../src/keys.bend as K
import ../src/sim.bend as S
import ../src/tic.bend as Tic
import ../src/things.bend as H
import ../src/fixed.bend as F
import ../src/vec.bend as V
import ../src/special.bend as Sp
import ../src/inventory.bend as I
import ./fixtures/closed.bend as Fx

def Tele.cmds(n: Nat, +cmd: K.Cmd, rest: List<&2, K.Cmd>) -> List<&2, K.Cmd>:
  match n:
    case 0n:
      rest
    case 1n+m:
      cmd <> Tele.cmds(m, cmd, rest)

# P_TeleportMove ignores height and solid-only decorations. An E1
# monster cannot stomp; EV_Teleport rejects missiles and back crossings.
def Tele.level.tagged(level: L.Level) -> L.Level:
  L.Level{geo, sectors, specials, heard} = level
  L.Level{geo, sectors, V.Vec.of([97, 5, 117, 0]), heard}

def Tele.level(x: U32) -> L.Level:
  Tele.level.tagged(L.Level.sector.put(Fx.Closed.level(0, V.Vec.of([x, 64, 90, 14, 7]), 1), 0, 6, 5))

def Tele.fixture(special: U32, kind: U32, +obstacle: U32, level: L.Level) -> S.State:
  Fx.Closed.at(S.Player{4259840, 0, 0, 0, 0, 0, 0, 0, 8388608, 2686976, 0, 2686976, [],
    I.Inventory.start(), Fx.Closed.unarmed(), S.Sim.Hurt.start()}, L.Level.special.put(level, 0, special), [],
    Fx.Closed.thing(7, kind, 6291456, 4194304, 0) <>
      Bool.pick(List<&2, H.Thing>, U32.is_zero(obstacle), [],
        [Fx.Closed.thing(8, obstacle, 2097152, 4194304, 6553600)]))

def Tele.cross(+who: U32, +kind: U32, obstacle: U32, +x: U32) -> S.State:
  Sp.Sim.cross.special(97, 0, who, S.Cross{0, x, 4194304, 0, 0}, Tele.fixture(97, kind, obstacle, Tele.level(32)))

def Tele.thing(m: Maybe<&2, H.Thing>) -> String:
  match m:
    case None{}:
      "none"
    case Some{+th}:
      F.Fixed.show(H.Thing.x(th)) ++ " " ++ F.Fixed.show(H.Thing.y(th)) ++ " angle "
        ++ U32.show(H.Thing.angle(th)) ++ " shootable " ++ Bool.show(H.Thing.flagged(th, 4))

def Tele.player(+s: S.State) -> String:
  "kills " ++ U32.show(I.Inventory.kills(S.Player.inv(S.State.player(s)))) ++ " target "
    ++ Tele.thing(H.Things.get(S.State.things(s), 8))

def Tele.once(+special: U32, +who: U32, obstacle: U32, +x: U32) -> U32:
  L.Level.special(S.State.level(Sp.Sim.cross.special(special, 0, who,
    S.Cross{0, x, 4194304, 0, 0}, Tele.fixture(special, 3004, obstacle, Tele.level(32)))), 0)

def Tele.wall.level(level: L.Level) -> L.Level:
  L.Level{L.Geo{lines, sides, verts, segs, subs, nodes, root, blockmap, things, texnames, flatnames, sine, tanto,
    boxes, nlines, nsectors, reject, sidetex, switches}, sectors, specials, heard} = level
  L.Level{L.Geo{V.Vec.set(lines, 2, 5), sides, verts, segs, subs, nodes, root, blockmap, things, texnames,
    flatnames, sine, tanto, boxes, nlines, nsectors, reject, sidetex, switches}, sectors, specials, heard}

# A destination on an explicitly blocking line fails P_CheckPosition, but
# P_TeleportMove accepts it. Frozen tics retain that nonfree position.
def Tele.wall() -> S.State:
  +s = Tele.fixture(97, 2028, 0, Tele.wall.level(Tele.level(64)))
  Sp.Sim.cross.one(S.Cross{0, 4259840, 4194304, 0, 0}, S.State.player.put(s,
    S.Player.went(S.State.level(s), Some{S.Dest{4194304, 4194304, 1073741824}}, S.State.player(s))))

def Tele.wall.report(+s: S.State) -> String:
  +p = S.State.player(s)
  "free " ++ Bool.show(S.Sim.free(S.State.level(s), S.Player.x(p), S.Player.y(p)))
    ++ " at " ++ F.Fixed.show(S.Player.x(p)) ++ " " ++ F.Fixed.show(S.Player.y(p))
    ++ " reaction " ++ U32.show(V.Vec.get(S.Player.hurt(p), S.Sim.hurt.reaction()))

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print("wall arrival " ++ Tele.wall.report(Tele.wall()))
    IO.print("wall frozen " ++ Tele.wall.report(Tic.Sim.replay(Tele.cmds(18n, K.Cmd{25, 0, 0, 0}, []), Tele.wall())))
    IO.print("player telefrag " ++ Tele.player(Tele.cross(H.Thing.you(), 3004, 3004, 4259840)))
    IO.print("monster blocked " ++ Tele.thing(H.Things.get(S.State.things(Tele.cross(7, 3004, 3004, 4259840)), 7)))
    IO.print("monster clear " ++ Tele.thing(H.Things.get(S.State.things(Tele.cross(7, 3004, 0, 4259840)), 7)))
    IO.print("solid decoration " ++ Tele.thing(H.Things.get(S.State.things(Tele.cross(7, 3004, 2028, 4259840)), 7)))
    IO.print("missile " ++ Tele.thing(H.Things.get(S.State.things(Tele.cross(7, H.Thing.fireball(), 0, 4259840)), 7)))
    IO.print("one-shot back " ++ U32.show(Tele.once(39, H.Thing.you(), 0, 4128768))
      ++ " monster-only player " ++ U32.show(Tele.once(125, H.Thing.you(), 0, 4259840))
      ++ " blocked monster " ++ U32.show(Tele.once(125, 7, 3004, 4259840))
      ++ " blocked repeat " ++ U32.show(Tele.once(97, 7, 3004, 4259840)))
    IO.print("back crossing " ++ Tele.thing(H.Things.get(S.State.things(Tele.cross(7, 3004, 0, 4128768)), 7)))

#|wall arrival free False at 64.000000 64.000000 reaction 18
#|wall frozen free False at 64.000000 64.000000 reaction 0
#|player telefrag kills 1 target 32.000000 64.000000 angle 0 shootable False
#|monster blocked 96.000000 64.000000 angle 0 shootable True
#|monster clear 32.000000 64.000000 angle 1073741824 shootable True
#|solid decoration 32.000000 64.000000 angle 1073741824 shootable True
#|missile 96.000000 64.000000 angle 0 shootable False
#|one-shot back 0 monster-only player 125 blocked monster 0 blocked repeat 97
#|back crossing 96.000000 64.000000 angle 0 shootable True
