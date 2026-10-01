# The 1453-tic Freedoom fight shared with Chocolate Doom. It takes
# damage, kills four monsters and collects the dropped shotgun. The
# final random index and every MF_COUNTKILL thing make a desync visible
# even when it happens outside the final view.
import Base
import ../src/bytes.bend as B
import ../src/wad.bend as W
import ../src/level.bend as L
import ../src/sim.bend as S
import ../src/tic.bend as Tic
import ../src/things.bend as H
import ../src/inventory.bend as I
import ../src/fixed.bend as F
import ../src/keys.bend as K
import ./fixtures/route.bend as Rt

def Fight.monster(m: Maybe<&2, H.Thing>) -> String:
  match m:
    case None{}:
      ""
    case Some{+th}:
      Bool.pick(String, H.Thing.flagged(th, 4194304),
        " " ++ U32.show(H.Thing.id(th)) ++ ":" ++ U32.show(H.Thing.kind(th))
          ++ ":" ++ U32.show(H.Thing.health(th)) ++ ":" ++ U32.show(H.Thing.state(th))
          ++ "/" ++ U32.show(H.Thing.tics(th)) ++ ":" ++ F.Fixed.show(H.Thing.x(th))
          ++ "," ++ F.Fixed.show(H.Thing.y(th)), "")

def Fight.monsters(n: Nat, +id: U32, +things: H.Things) -> String:
  match n:
    case 0n:
      ""
    case 1n+k:
      Fight.monster(H.Things.get(things, id)) ++ Fight.monsters(k, (id + 1 : U32), things)

def Fight.report(+s: S.State) -> String:
  +p = S.State.player(s)
  +inv = S.Player.inv(p)
  +things = S.State.things(s)
  "fight tic " ++ U32.show(S.State.clock(s)) ++ " random " ++ U32.show(S.State.rnd(s))
    ++ " health " ++ U32.show(I.Inventory.health(inv)) ++ " armour " ++ U32.show(I.Inventory.armour(inv))
    ++ " kills " ++ U32.show(I.Inventory.kills(inv)) ++ " weapons " ++ U32.show(I.Inventory.weapons(inv))
    ++ " ready " ++ U32.show(I.Inventory.ready(inv)) ++ " pending " ++ U32.show(I.Inventory.pending(inv))
    ++ " ammo " ++ U32.show(I.Inventory.rounds(I.Inventory.am_clip(), inv)) ++ ","
    ++ U32.show(I.Inventory.rounds(I.Inventory.am_shell(), inv)) ++ " things " ++ U32.show(H.Things.count(things))
    ++ " monsters" ++ Fight.monsters(U32.to_nat(H.Things.count(things)), 0, things)

def Fight.run(+level: L.Level, cmds: List<&2, K.Cmd>) -> IO(Unit):
  IO.print(Fight.report(Tic.Sim.replay(cmds, Tic.State.start(level))))

def Fight.start(w: Array<U32> & L.Level, cmds: List<&2, K.Cmd>) -> IO(Unit):
  (mem, level) = w
  Fight.run(level, cmds)

def main() -> IO(Unit):
  do IO<Unit>:
    path : String <- IO.try(String, IO.get_env("BENDOOM_IWAD"))
    bytes : Array<U32> <- IO.try(Array<U32>, B.Bytes.read(path))
    cmds : List<&2, K.Cmd> <- Rt.Route.fight()
    Fight.start(L.Level.load(W.Wad.dir(bytes)), cmds)

#|fight tic 1453 random 152 health 17 armour 87 kills 4 weapons 7 ready 0 pending 2 ammo 0,20 things 400 monsters 3:3002:150:67/8:2576.000000,2112.000000 35:3001:60:65/8:544.000000,804.000000 81:3001:4294967290:159/4294967295:1592.391662,1081.359695 82:3001:11:112/2:1301.362411,1161.287734 84:3001:40:111/3:1320.708648,1079.634674 85:3001:40:112/3:2220.931945,851.998901 86:3001:40:105/3:2199.434265,786.042358 88:3004:20:62/1:352.000000,1392.000000 90:9:30:64/7:368.000000,1552.000000 92:3002:150:68/4:-48.000000,1616.000000 94:9:30:64/1:896.000000,1856.000000 95:9:30:64/7:752.000000,1728.000000 96:9:30:64/3:144.000000,1952.000000 97:9:30:64/3:-96.000000,1984.000000 98:3002:150:67/10:2544.000000,2048.000000 176:3004:20:62/2:816.000000,448.000000 177:3004:8:89/2:1249.627853,1021.617248 182:9:30:102/3:844.686523,-564.924804 184:3002:138:120/1:1112.672363,-225.268066 185:9:30:97/2:1105.618164,-664.483398 189:9:4294967246:152/4294967295:2378.101074,-165.256805 190:3001:4294967293:159/4294967295:2352.703109,-324.964187 214:3002:138:113/2:1440.000671,-471.016494 240:9:4294967287:143/4294967295:1191.029983,738.710220 241:3001:35:108/1:2070.698135,612.969894 243:3001:60:105/2:1832.882812,-203.726562 255:3001:60:107/1:2111.033203,462.052734 265:3004:20:92/4:1359.916015,-467.474609 289:9:30:64/2:-352.000000,1280.000000
