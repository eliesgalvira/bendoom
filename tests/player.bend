# The player's movement, view, weapon bob, damage and rays, and the
# random table, every value by hand from vanilla's formulas. The moves
# stand on Level.room: one sector, no lines, the floor at 0 and the
# ceiling at 128 map units. A player line is the twelve words x, y, z,
# angle, momentum x, y and z, floor, ceiling, view height, its delta and
# the eye, a negative one as its 32-bit word, and then whether the rest
# of the player is as it began: no special line crossed, G_PlayerReborn's
# inventory, no weapon sprite showing and the mobj unhurt in its
# standing state.
# One tic forward from rest at angle zero thrusts 25 * 2048 along the
# facing (51199 along x through the cosine 65535, 19 along y through the
# sine 25) and then decays it by 0.90625: momentum 46399, 17, position
# 0.78125, 0.000290 (the numbers of milestone 2's ticket 08 hand check).
# The eye is the rest height plus the bob: the squared momentum over
# four is 9999, and half of it times the clock's sine 25 is 1.
# 64 above the floor, the first airborne tic sets the fall to twice
# gravity without moving, the second moves by it and adds gravity once;
# the eye sits 41 above the height the tic began at.
# Landing at 9 a tic dips the view by an eighth of it, -1.125; landing
# at 8 a tic does not.
# The eye at the bob's peak (tic 5, sine 65535). The first tic of a run
# from rest has momentum 102398, 39, whose square over four is 39998,
# and half of it bobs the eye by 19998. At 30 a tic the square over four
# is 14745600, capped at 16 units, and half of it bobs the eye by
# 524280, a hair under 8 units.
# A floor 16 above the player's feet lifts the player onto it, cuts the
# view height by the 16 to 25, and sets it recovering by an eighth of
# the gap, 2 a tic.
# The ready pistol, its state, tics, column and row and then the
# flash's, at the bob's lowest, tic 16, a quarter of its turn of 64: at
# 30 a tic the bob is capped at 16 units, 1048576; the cosine -25 moves
# the column by -400 from 65536, and the sine 65535 lowers the row by
# 1048560 from 2097152 (p_pspr.c's A_WeaponReady).
# The blows are p_inter.c's P_DamageMobj by hand. Armour absorbs a third
# of a blow when green and a half when blue, rounded down, and the
# health takes the rest: each line is the health, the armour points and
# type, and what reached the health. A blow of 20 costs 14 health and 6
# points of green armour, or 10 and 10 of blue. Armour with fewer points
# than the blow's share gives all it has and loses its type, leaving the
# rest of the blow to the health; no armour absorbs nothing.
# The damage count, after the health, takes what reached the player and
# stops at 100, where a blow past the health leaves none.
# P_KillMobj picks an extreme death only below the negation of the
# type's spawn health, 60 for the imp, and only for a type with an
# extreme-death state, which the barrel lacks.
# ST_calcPainOffset steps the face's row by eight at each edge of the
# five pain levels, which C's truncating (100 - health) * 5 / 101 puts
# at 80, 60, 40 and 20 health, and health over 100 reads as 100.
# ST_doPaletteStuff's palette at each step's edge, st_stuff.c by hand. A
# count steps the red palette every eight from STARTREDPALS 1, by
# (cnt+7)>>3, and holds at the eighth, so counts 1 to 8 pick 2, 9 picks
# 3, and 64 and the capped 100 both pick the last red 8. A pickup flash
# steps the gold palette the same way from STARTBONUSPALS 9, so 1 to 8
# pick 10, 9 picks 11, and 25 holds at the last gold 12. The berserk
# fade 12 - (strength>>6) stands in for the count while it is larger:
# the tic the pack is taken picks 3, the counter at 256 picks 2, at 768
# the fade is gone and at 4096 vanilla's int is negative, both leaving
# the count to speak. A flash under a count picks no gold.
# One traversal gathers the lines of the cell it crosses and the things
# linked in it, and hands them over in order of distance, each as its
# fraction, whether it is a line and its name: the ray meets the door's
# west face at half its length, the barrel at 0.625 and the east face at
# 0.75, so the thing comes between the two lines. The fractions are
# P_InterceptVector by hand. For the west face, from (64, 128) to (64,
# 0): num is (64 - 32) >> 8 times its dy, -1048576, den is its dy >> 8
# times the ray's dx, -2097152, and the quotient is 32768. For the east
# face, from (80, 0) to (80, 128): num 1572864, den 2097152, quotient
# 49152. For the barrel, PIT_AddThingIntercepts takes the diagonal of
# its box that a rising ray can cross, from (62, 74) to (82, 54): num is
# (62 - 32) >> 8 times -20 plus (64 - 74) >> 8 times 20, -204800, den is
# -20 >> 8 times the ray's dx, -327680, and the quotient is 40960. The
# use key asks for lines alone, so the barrel is not gathered for it,
# and its refusal at the first line with a special ends the walk before
# the east face.
# Vanilla's random table, its first entries and its last, and the index
# wrapping at 256.
import Base
import ./fixtures/closed.bend as Fx
import ../src/keys.bend as K
import ../src/sim.bend as S
import ../src/special.bend as Sp
import ../src/random.bend as M
import ../src/inventory.bend as I
import ../src/bar.bend as Y

# A player at the room's origin facing east, its view height at rest,
# with no damage and G_PlayerReborn's inventory.
def placed(z: U32, momx: U32, momz: U32, floorz: U32, viewz: U32, ps: S.Psprites) -> S.Player:
  S.Player{0, 0, z, 0, momx, 0, momz, floorz, 8388608, 2686976, 0, viewz, [], I.Inventory.start(), ps,
    S.Sim.Hurt.start()}

def player(p: S.Player) -> String:
  S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt} = p
  Fx.words([x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz]) ++ " rest as it was "
    ++ Bool.show(Fx.began(crossed, inv, psprites, hurt))

def absorbed(got: U32 & U32 & U32 & U32) -> String:
  (health, armour, kind, left) = got
  Fx.words([health, armour, kind, left])

def blow(got: U32 & U32) -> String:
  (health, count) = got
  Fx.words([health, count])

def meets(ms: List<&2, S.Sim.Meet>) -> String:
  match ms:
    case []:
      ""
    case S.Meet{frac, isline, what} <> rest:
      " " ++ U32.show(frac) ++ " " ++ Bool.show(isline) ++ " " ++ U32.show(what) ++ meets(rest)

def reach(r: Sp.Sim.Reach) -> String:
  match r:
    case Sp.Special{line}:
      "special " ++ U32.show(line)
    case Sp.Wall{}:
      "wall"
    case Sp.Nothing{}:
      "nothing"

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print("from rest:" ++ player(Fx.Closed.room([K.Cmd{25, 0, 0, 0}], placed(0, 0, 0, 0, 2686976, Fx.Closed.unarmed()), 0)))
    IO.print("fall a tic:" ++ player(Fx.Closed.room([K.Cmd.idle()], placed(4194304, 0, 0, 0, 0, Fx.Closed.unarmed()), 0)))
    IO.print("fall two tics:"
      ++ player(Fx.Closed.room([K.Cmd.idle(), K.Cmd.idle()], placed(4194304, 0, 0, 0, 0, Fx.Closed.unarmed()), 0)))
    IO.print("land at 9:" ++ player(Fx.Closed.room([K.Cmd.idle()], placed(65536, 0, 4294377472, 0, 0, Fx.Closed.unarmed()), 0)))
    IO.print("land at 8:" ++ player(Fx.Closed.room([K.Cmd.idle()], placed(65536, 0, 4294443008, 0, 0, Fx.Closed.unarmed()), 0)))
    IO.print("eye run, capped:"
      ++ Fx.words([S.Player.viewz(Fx.Closed.room([K.Cmd{50, 0, 0, 0}], placed(0, 0, 0, 0, 0, Fx.Closed.unarmed()), 5)),
        S.Player.viewz(Fx.Closed.room([K.Cmd.idle()], placed(0, 1966080, 0, 0, 0, Fx.Closed.unarmed()), 5))]))
    IO.print("step up:" ++ player(Fx.Closed.room([K.Cmd.idle()], placed(0, 0, 0, 1048576, 0, Fx.Closed.unarmed()), 0)))
    IO.print("pistol bob:"
      ++ Fx.psprites(S.Player.psprites(Fx.Closed.room([K.Cmd.idle()], placed(0, 1966080, 0, 0, 0, Fx.Closed.ready()), 16))))
    IO.print("green 100, blow 20:" ++ absorbed(Fx.Closed.absorbed(1, 100, 20)))
    IO.print("blue 100, blow 20:" ++ absorbed(Fx.Closed.absorbed(2, 100, 20)))
    IO.print("green 5, blow 20:" ++ absorbed(Fx.Closed.absorbed(1, 5, 20)))
    IO.print("blue 0, blow 20:" ++ absorbed(Fx.Closed.absorbed(2, 0, 20)))
    IO.print("none, blow 20:" ++ absorbed(Fx.Closed.absorbed(0, 0, 20)))
    IO.print("count, blow 20:" ++ blow(Fx.Closed.blow(20)))
    IO.print("count, blow 120:" ++ blow(Fx.Closed.blow(120)))
    IO.print("gibs imp at -60 -61, barrel at -1001: " ++ Bool.show(S.Sim.kill.thing.gibs(4294967236, 3001)) ++ " "
      ++ Bool.show(S.Sim.kill.thing.gibs(4294967235, 3001)) ++ " " ++ Bool.show(S.Sim.kill.thing.gibs(4294966295, 2035)))
    IO.print("pain at 200 100 80 79 60 59 40 39 20 19 0:"
      ++ Fx.words([S.Sim.face.pain(200), S.Sim.face.pain(100), S.Sim.face.pain(80), S.Sim.face.pain(79),
        S.Sim.face.pain(60), S.Sim.face.pain(59), S.Sim.face.pain(40), S.Sim.face.pain(39),
        S.Sim.face.pain(20), S.Sim.face.pain(19), S.Sim.face.pain(0)]))
    IO.print("palette count 0 1 8 9 64 100:"
      ++ Fx.words([Y.Bar.palette(0, 0, 0, 0), Y.Bar.palette(1, 0, 0, 0), Y.Bar.palette(8, 0, 0, 0),
        Y.Bar.palette(9, 0, 0, 0), Y.Bar.palette(64, 0, 0, 0), Y.Bar.palette(100, 0, 0, 0)]))
    IO.print("palette flash 1 6 8 9 25:"
      ++ Fx.words([Y.Bar.palette(0, 0, 1, 0), Y.Bar.palette(0, 0, 6, 0), Y.Bar.palette(0, 0, 8, 0),
        Y.Bar.palette(0, 0, 9, 0), Y.Bar.palette(0, 0, 25, 0)]))
    IO.print("palette berserk 1 256 768 4096:"
      ++ Fx.words([Y.Bar.palette(0, 1, 0, 0), Y.Bar.palette(0, 256, 0, 0), Y.Bar.palette(0, 768, 0, 0),
        Y.Bar.palette(0, 4096, 0, 0)]))
    IO.print("palette count 100 berserk 1, berserk 768 flash 6:"
      ++ Fx.words([Y.Bar.palette(100, 1, 0, 0), Y.Bar.palette(0, 768, 6, 0)]))
    IO.print("meets:" ++ meets(Fx.Closed.met(Fx.Closed.barrel())))
    IO.print("use reaches " ++ reach(Fx.Closed.reach(Fx.Closed.barrel())))
    IO.print("random at 0 1 2 3 255:" ++ Fx.words([M.Random.at(0), M.Random.at(1), M.Random.at(2), M.Random.at(3), M.Random.at(255)]))
    IO.print("random after 0 255:" ++ Fx.words([M.Random.next(0), M.Random.next(255)]))

#|from rest: 51199 19 0 0 46399 17 0 0 8388608 2686976 0 2686977 rest as it was True
#|fall a tic: 0 0 4194304 0 0 0 4294836224 0 8388608 2686976 0 6881280 rest as it was True
#|fall two tics: 0 0 4063232 0 0 0 4294770688 0 8388608 2686976 0 6881280 rest as it was True
#|land at 9: 0 0 0 0 0 0 0 0 8388608 2686976 4294893568 2752512 rest as it was True
#|land at 8: 0 0 0 0 0 0 0 0 8388608 2686976 0 2752512 rest as it was True
#|eye run, capped: 2706974 3211256
#|step up: 0 0 1048576 0 0 0 0 1048576 8388608 1638400 131072 2686976 rest as it was True
#|pistol bob: Some(59) 1 65136 3145712 None 0 65136 3145712
#|green 100, blow 20: 86 94 1 14
#|blue 100, blow 20: 90 90 2 10
#|green 5, blow 20: 85 0 0 15
#|blue 0, blow 20: 80 0 0 20
#|none, blow 20: 80 0 0 20
#|count, blow 20: 80 20
#|count, blow 120: 0 100
#|gibs imp at -60 -61, barrel at -1001: False True False
#|pain at 200 100 80 79 60 59 40 39 20 19 0: 0 0 0 8 8 16 16 24 24 32 32
#|palette count 0 1 8 9 64 100: 0 2 2 3 8 8
#|palette flash 1 6 8 9 25: 10 10 10 11 12
#|palette berserk 1 256 768 4096: 3 2 0 0
#|palette count 100 berserk 1, berserk 768 flash 6: 8 10
#|meets: 32768 True 0 40960 False 0 49152 True 1
#|use reaches special 0
#|random at 0 1 2 3 255: 0 8 109 220 249
#|random after 0 255: 1 0
