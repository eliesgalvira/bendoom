# Solid things and sight on the literal door level of
# tests/fixtures/closed.bend, every number computed by hand from
# vanilla's constants.
# First vanilla's PIT_CheckThing. The lamp stops the player's box when
# their centres are under 32 apart, 16 and 16: at 32 it does not, 1/65536
# closer it does, and it never stops its own. The corpse is not solid, so
# it stops nothing even where it stands. The barrel's reach is 26. The
# player's mobj stops a barrel's box under 26 away and not at 26. A
# missile, flag 65536, of radius 6 and height 8 is tested against
# heights: on the barrel's top at 42 it has hit the barrel, 1/65536
# higher it passes over; under the raised barrel its top at 99 passes
# and at 100 has hit; the lamp, not shootable, stops it as a solid thing
# does, and the corpse does not. The cell lists the mobjs the last linked
# first, less the raised barrel, which at x 160 is off the one cell's
# blockmap and so in no cell.
# Then the links' order, vanilla's P_SetThingPosition: a mobj goes first
# in its cell's list when it spawns and when it moves. The player's mobj
# spawns at its record's turn, so as record 6 it is listed after record 9
# and before 5 and 2, and as record 1 last; once it has moved it is
# first; at (200, 64), off the blockmap, no cell lists it. The thinkers
# are started in the same order.
# Then a mobj spawned while the thinkers run joins the tail of the list
# and thinks in that same run, as one P_AddThinker appends to the tail of
# Doom's list does. The bonus takes the id past the 128 records, draws
# one random number (the index goes 0 to 1) and stands in S_BON1 for its
# 6 tics; the rest of the run reaches it and leaves 5. The thinkers are
# the player's mobj's and then the bonus's.
# Then a solid thing stops the player and a corpse does not. Moving north
# at 8 a tic from (32, 64), friction leaves 7.25 and then 6.57: tic 2
# ends at 79.25, 32.75 short of a lamp at (32, 112), and tic 3's move to
# 85.82 would overlap it. The slide finds no line and stairsteps; its
# move north overlaps too, its move by the momentum east is no move, so
# the player stays at 79.25. Doom's things are as tall as the map: the
# lamp raised 100 units stops it all the same. Over a dead player at the
# same place tic 3 reaches 85.82.
# Then a moving floor carries the things on it, vanilla's
# P_ThingHeightClip through P_ChangeSector. The west room's floor goes
# down 4 a tic; the player at (200, 64) is out of its block box. The
# barrel standing at (32, 16) follows the floor, -4 after a tic and -8
# after two, its name, type, state, tics and wound as they were. A leg
# hung 68 under the ceiling at 128 stays at 60, over its floor at -4.
# Then a door closing on a barrel goes back up, vanilla's
# PIT_ChangeSector for a shootable thing that no longer fits, and no
# damage is done. The barrel at (72, 16) stands across both of the door's
# faces, so its ceiling is the door's: 42 after 13 tics, which fits its
# height of 42; the 14th would leave 40, so the step is undone, the
# barrel clipped again under 42, and the door back on its plan, up to 68,
# a wait of 150 tics and down to 0, with T_VerticalDoor's sounds,
# sfx_doropn (20) as it opens and as it turns back and sfx_dorcls (21) as
# it closes; 44 after the 15th.
# Then a lamp is solid but not shootable, and vanilla's PIT_ChangeSector
# passes over it: the door closes on the lamp at (72, 16) as on nothing,
# shut after 34 tics, its thinker ended on the 35th, the lamp still on
# its floor under a ceiling at 0.
# Then vanilla's T_MovePlane lets a ceiling rise short of its destination
# whatever it leaves unfit. A barrel at (72, 100) across the shut door
# does not fit under it, yet the door used on tic 1 is 2 up after it and
# 4 after the second, the barrel's ceiling rising with it.
# Then P_DivlineSide's three answers, 0 in front, 1 behind and 2 on the
# line. A line up the y axis through x 64 has a point at x 64 on it, one
# west of it behind it and one east of it in front. A line east along
# y 64 from x 0 answers on for the point (64, 32), because vanilla
# compares the point's x with the line's y where it means its y; (0, 32)
# is south of it and in front, and (0, 96) north of it and behind. A line
# out along (1, 1) from the origin has (1, 0) in front, (0, 1) behind and
# (1, 1) on it, from the whole-unit products 1 against 0, 0 against 1 and
# 1 against 1.
# Last, every MF_COUNTKILL type stands in a row that runs A_Look and
# chases in a row of the table that runs A_Chase, so no
# monster can wake without a state to wake into and none can watch for
# the player without A_Look to do it.
import Base
import ../src/fixed.bend as F
import ../src/vec.bend as V
import ../src/sim.bend as S
import ../src/things.bend as H
import ./fixtures/closed.bend as Fx

def ids(xs: List<&2, U32>) -> String:
  match xs:
    case []:
      ""
    case x <> rest:
      " " ++ U32.show(x) ++ ids(rest)

def tics(m: Maybe<&2, U32>) -> String:
  match m:
    case None{}:
      "none"
    case Some{t}:
      U32.show(t)

def steps(xs: List<&2, S.Sim.Step>) -> String:
  match xs:
    case []:
      ""
    case S.Travel{True{}, dest} <> rest:
      " down to " ++ F.Fixed.show(dest) ++ steps(rest)
    case S.Travel{False{}, dest} <> rest:
      " up to " ++ F.Fixed.show(dest) ++ steps(rest)
    case S.Hold{t} <> rest:
      " hold " ++ U32.show(t) ++ steps(rest)
    case S.Change{flat, special} <> rest:
      " change to " ++ U32.show(flat) ++ " " ++ U32.show(special) ++ steps(rest)

def thinkers(ts: List<&2, S.Thinker>) -> String:
  match ts:
    case []:
      ""
    case S.Mobj{id} <> rest:
      " mobj " ++ U32.show(id) ++ thinkers(rest)
    case S.Mover{sector, ceiling, speed, going, plan, S.Noise{start, wake, up, down, crush, grind}} <> rest:
      " mover sector " ++ U32.show(sector) ++ " ceiling " ++ Bool.show(ceiling) ++ " speed " ++ F.Fixed.show(speed)
        ++ " steps" ++ steps(going) ++ " plan" ++ steps(plan) ++ " sounds" ++ ids([start, wake, up, down, crush, grind])
        ++ thinkers(rest)
    case _ <> rest:
      " other" ++ thinkers(rest)

# Whether a wound is the one P_SpawnMobj gives a type that never looked.
def unhurt(+kind: U32, +hurt: V.Vec) -> Bool:
  String.eq(V.Vec.show(hurt, 12n, 0), V.Vec.show(H.Thing.Hurt.of(kind), 12n, 0))

def things(xs: List<&2, H.Thing>) -> String:
  match xs:
    case []:
      ""
    case H.Thing{id, +kind, x, y, z, floorz, ceilz, angle, sector, state, t, momz, hurt} <> rest:
      "\n  thing " ++ U32.show(id) ++ " type " ++ U32.show(kind) ++ " at " ++ F.Fixed.show(x) ++ " " ++ F.Fixed.show(y)
        ++ " z " ++ F.Fixed.show(z) ++ " floor " ++ F.Fixed.show(floorz) ++ " ceiling " ++ F.Fixed.show(ceilz)
        ++ " angle " ++ U32.show(angle) ++ " sector " ++ U32.show(sector) ++ " state " ++ U32.show(state)
        ++ " tics " ++ U32.show(t) ++ " momz " ++ F.Fixed.show(momz) ++ " unhurt " ++ Bool.show(unhurt(kind, hurt))
        ++ things(rest)

def ceiling(s: S.State) -> String:
  F.Fixed.show(Fx.Closed.ceil(s, 1))

def closing(n: Nat, th: H.Thing) -> S.State:
  Fx.Closed.idled(n, Fx.Closed.closing(th))

def barrel() -> H.Thing:
  Fx.Closed.thing(24, 2035, 4718592, 1048576, 0)

def lamp() -> H.Thing:
  Fx.Closed.thing(8, 2028, 4718592, 1048576, 0)

def north(th: H.Thing, n: Nat) -> String:
  F.Fixed.show(Fx.Closed.north([th], n))

def side(x: U32, y: U32, lx: U32, ly: U32, dx: U32, dy: U32) -> String:
  " " ++ U32.show(S.Sim.sight.side(x, y, lx, ly, dx, dy))

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print("lamp stops the player: 32 apart " ++ Bool.show(Fx.Closed.stops(8, 2097152, 5242880, 0, 1048576, 3670016, 33557510, 4294967295))
      ++ ", closer " ++ Bool.show(Fx.Closed.stops(8, 2097152, 5242881, 0, 1048576, 3670016, 33557510, 4294967295))
      ++ ", its own box " ++ Bool.show(Fx.Closed.stops(8, 2097152, 5242881, 0, 1048576, 1048576, 2, 8)))
    IO.print("corpse stops the player: " ++ Bool.show(Fx.Closed.stops(15, 2097152, 2097152, 0, 1048576, 3670016, 33557510, 4294967295)))
    IO.print("barrel stops the player: 26 apart " ++ Bool.show(Fx.Closed.stops(24, 4587520, 7340032, 0, 1048576, 3670016, 33557510, 4294967295))
      ++ ", closer " ++ Bool.show(Fx.Closed.stops(24, 4587521, 7340032, 0, 1048576, 3670016, 33557510, 4294967295)))
    IO.print("player stops a barrel: closer " ++ Bool.show(Fx.Closed.stops(4294967295, 3801087, 4194304, 0, 655360, 2752512, 524294, 24))
      ++ ", 26 apart " ++ Bool.show(Fx.Closed.stops(4294967295, 3801088, 4194304, 0, 655360, 2752512, 524294, 24)))
    IO.print("barrel stops a missile: on its top " ++ Bool.show(Fx.Closed.stops(24, 6291456, 7340032, 2752512, 393216, 524288, 65536, 200))
      ++ ", higher " ++ Bool.show(Fx.Closed.stops(24, 6291456, 7340032, 2752513, 393216, 524288, 65536, 200)))
    IO.print("raised barrel stops a missile: top at 99 " ++ Bool.show(Fx.Closed.stops(30, 10485760, 7340032, 5963776, 393216, 524288, 65536, 200))
      ++ ", at 100 " ++ Bool.show(Fx.Closed.stops(30, 10485760, 7340032, 6029312, 393216, 524288, 65536, 200)))
    IO.print("lamp stops a missile: " ++ Bool.show(Fx.Closed.stops(8, 2097152, 7340032, 0, 393216, 524288, 65536, 200)))
    IO.print("corpse stops a missile: " ++ Bool.show(Fx.Closed.stops(15, 2097152, 2097152, 0, 393216, 524288, 65536, 200)))
    IO.print("cell lists" ++ ids(S.Sim.near(Fx.Closed.doors(), S.State.things(Fx.Closed.linked()), 2097152, 4194304, 1048576)))
    IO.print("record 6 cell" ++ ids(Fx.Closed.cell(Fx.Closed.ranked(6, 2097152, 0))) ++ ", moved"
      ++ ids(Fx.Closed.cell(Fx.Closed.idled(1n, Fx.Closed.ranked(6, 2097152, 65536)))))
    IO.print("record 1 cell" ++ ids(Fx.Closed.cell(Fx.Closed.ranked(1, 2097152, 0))))
    IO.print("off the blockmap cell" ++ ids(Fx.Closed.cell(Fx.Closed.ranked(6, 13107200, 0))))
    IO.print("record 6 thinkers" ++ thinkers(S.State.thinkers(Fx.Closed.ranked(6, 2097152, 0))))
    IO.print("spawned bonus tics " ++ tics(Fx.Closed.tics(H.Things.get(S.State.things(Fx.Closed.spawned()), 128)))
      ++ " random " ++ U32.show(S.State.rnd(Fx.Closed.spawned())))
    IO.print("run on tics " ++ tics(Fx.Closed.tics(H.Things.get(S.State.things(Fx.Closed.spawned.ran()), 128)))
      ++ " thinkers" ++ thinkers(S.State.thinkers(Fx.Closed.spawned.ran())))
    IO.print("north past the lamp: tic 2 " ++ north(Fx.Closed.thing(8, 2028, 2097152, 7340032, 0), 2n)
      ++ ", tic 3 " ++ north(Fx.Closed.thing(8, 2028, 2097152, 7340032, 0), 3n)
      ++ ", lamp raised " ++ north(Fx.Closed.thing(8, 2028, 2097152, 7340032, 6553600), 3n)
      ++ ", over the corpse " ++ north(Fx.Closed.thing(15, 15, 2097152, 7340032, 0), 3n))
    IO.print("floor down a tic:" ++ things(Fx.Closed.lowering(1n)))
    IO.print("floor down two tics:" ++ things(Fx.Closed.lowering(2n)))
    IO.print("door on the barrel: ceiling tic 13 " ++ ceiling(closing(13n, barrel())) ++ ", tic 14 "
      ++ ceiling(closing(14n, barrel())) ++ ", tic 15 " ++ ceiling(closing(15n, barrel())))
    IO.print("door on the barrel tic 14:" ++ thinkers(Fx.Closed.running(closing(14n, barrel())))
      ++ things(Fx.Closed.things(closing(14n, barrel()))))
    IO.print("door on the lamp: ceiling tic 34 " ++ ceiling(closing(34n, lamp())) ++ ", tic 35 thinkers"
      ++ thinkers(Fx.Closed.running(closing(35n, lamp()))) ++ things(Fx.Closed.things(closing(35n, lamp()))))
    IO.print("door over the barrel: ceiling tic 1 " ++ ceiling(Fx.Closed.used(0n, Fx.Closed.over_barrel())) ++ ", tic 2"
      ++ things(Fx.Closed.things(Fx.Closed.used(1n, Fx.Closed.over_barrel()))))
    IO.print("divline up x 64:" ++ side(4194304, 2097152, 4194304, 0, 0, 65536) ++ side(2097152, 2097152, 4194304, 0, 0, 65536)
      ++ side(6291456, 2097152, 4194304, 0, 0, 65536))
    IO.print("divline east y 64:" ++ side(4194304, 2097152, 0, 4194304, 65536, 0) ++ side(0, 2097152, 0, 4194304, 65536, 0)
      ++ side(0, 6291456, 0, 4194304, 65536, 0))
    IO.print("divline out (1, 1):" ++ side(65536, 0, 0, 0, 65536, 65536) ++ side(0, 65536, 0, 0, 65536, 65536)
      ++ side(65536, 65536, 0, 0, 65536, 65536))
    IO.print("monsters wake " ++ Bool.show(List.all(~&2, ~H.Thing.Def, ~Fx.Closed.wakes, H.Thing.defs())))

#|lamp stops the player: 32 apart False, closer True, its own box False
#|corpse stops the player: False
#|barrel stops the player: 26 apart False, closer True
#|player stops a barrel: closer True, 26 apart False
#|barrel stops a missile: on its top True, higher False
#|raised barrel stops a missile: top at 99 False, at 100 True
#|lamp stops a missile: True
#|corpse stops a missile: False
#|cell lists 4294967295 24 15 8
#|record 6 cell 9 6 5 2, moved 6 9 5 2
#|record 1 cell 9 5 2 1
#|off the blockmap cell 9 5 2
#|record 6 thinkers mobj 2 mobj 5 mobj 6 mobj 9
#|spawned bonus tics 6 random 1
#|run on tics 5 thinkers mobj 4294967295 mobj 128
#|north past the lamp: tic 2 79.250000, tic 3 79.250000, lamp raised 79.250000, over the corpse 85.820312
#|floor down a tic:
#|  thing 24 type 2035 at 32.000000 16.000000 z -4.000000 floor -4.000000 ceiling 128.000000 angle 0 sector 0 state 0 tics 4294967295 momz 0.000000 unhurt True
#|  thing 29 type 60 at 32.000000 100.000000 z 60.000000 floor -4.000000 ceiling 128.000000 angle 0 sector 0 state 0 tics 4294967295 momz 0.000000 unhurt True
#|floor down two tics:
#|  thing 24 type 2035 at 32.000000 16.000000 z -8.000000 floor -8.000000 ceiling 128.000000 angle 0 sector 0 state 0 tics 4294967295 momz 0.000000 unhurt True
#|  thing 29 type 60 at 32.000000 100.000000 z 60.000000 floor -8.000000 ceiling 128.000000 angle 0 sector 0 state 0 tics 4294967295 momz 0.000000 unhurt True
#|door on the barrel: ceiling tic 13 42.000000, tic 14 42.000000, tic 15 44.000000
#|door on the barrel tic 14: mover sector 1 ceiling True speed 2.000000 steps up to 68.000000 hold 150 down to 0.000000 plan up to 68.000000 hold 150 down to 0.000000 sounds 20 21 0 0 20 0
#|  thing 24 type 2035 at 72.000000 16.000000 z 0.000000 floor 0.000000 ceiling 42.000000 angle 0 sector 0 state 0 tics 4294967295 momz 0.000000 unhurt True
#|door on the lamp: ceiling tic 34 0.000000, tic 35 thinkers
#|  thing 8 type 2028 at 72.000000 16.000000 z 0.000000 floor 0.000000 ceiling 0.000000 angle 0 sector 0 state 0 tics 4294967295 momz 0.000000 unhurt True
#|door over the barrel: ceiling tic 1 2.000000, tic 2
#|  thing 24 type 2035 at 72.000000 100.000000 z 0.000000 floor 0.000000 ceiling 4.000000 angle 0 sector 0 state 0 tics 4294967295 momz 0.000000 unhurt True
#|divline up x 64: 2 1 0
#|divline east y 64: 2 0 1
#|divline out (1, 1): 0 1 2
#|monsters wake True
