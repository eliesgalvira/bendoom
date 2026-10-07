# The sectors' doors, lifts, floors, lights and sounds on the literal
# door level of tests/fixtures/closed.bend: line 0 the door's west face,
# line 1 its east face, sector 0 the west room, 1 the door, 2 the east
# room. Each line is a case's tag, the clock after the tics run, and
# what the case reads there: a sector's ceiling or floor, the thinkers
# running that are no mobj's, the sounds the last tic started, a line's
# special, a light, a random index. A mover shows its sector, whether it
# moves the ceiling, its speed, the steps left, its whole plan and its
# noise: the sfx it starts as it starts, as a wait ends, as a travel up
# or down ends, as it is turned back, and as it grinds. Every expected
# value is worked by hand from vanilla's source, as each case says.
import Base
import ../src/fixed.bend as F
import ../src/angle.bend as A
import ../src/level.bend as L
import ../src/sim.bend as S
import ../src/special.bend as Sp
import ../src/sound.bend as Sn
import ../src/inventory.bend as I
import ./fixtures/closed.bend as Fx

def line(~seen: S.State -> String, tag: String, +s: S.State) -> String:
  tag ++ " tic " ++ U32.show(S.State.clock(s)) ++ seen(s)

# A line for the state, then one after each run of idle tics.
def watch(~seen: S.State -> String, +tag: String, gaps: List<&2, Nat>, +s: S.State) -> IO(Unit):
  match gaps:
    case []:
      IO.print(line(~seen, tag, s))
    case n <> rest:
      do IO<Unit>:
        IO.print(line(~seen, tag, s))
        watch(~seen, tag, rest, Fx.Closed.idled(n, s))

def steps(ss: List<&2, S.Sim.Step>) -> String:
  match ss:
    case []:
      ""
    case S.Travel{down, dest} <> rest:
      Bool.pick(String, down, " down to ", " up to ") ++ F.Fixed.show(dest) ++ steps(rest)
    case S.Hold{tics} <> rest:
      " hold " ++ U32.show(tics) ++ steps(rest)

def noise(n: S.Sim.Noise) -> String:
  S.Noise{start, wake, up, down, crush, grind} = n
  " noise " ++ U32.show(start) ++ " " ++ U32.show(wake) ++ " " ++ U32.show(up) ++ " " ++ U32.show(down) ++ " "
    ++ U32.show(crush) ++ " " ++ U32.show(grind)

def thinker(t: S.Thinker) -> String:
  match t:
    case S.Mover{sector, ceiling, speed, ss, plan, n}:
      "mover sector " ++ U32.show(sector) ++ Bool.pick(String, ceiling, " ceiling", " floor") ++ " speed "
        ++ F.Fixed.show(speed) ++ " steps" ++ steps(ss) ++ " plan" ++ steps(plan) ++ noise(n)
    case S.Button{side, slot, texture, tics}:
      "button side " ++ U32.show(side) ++ " slot " ++ U32.show(slot) ++ " texture " ++ U32.show(texture)
        ++ " tics " ++ U32.show(tics)
    case S.Blink{sector, count, dark, bright, darktime, brighttime, random}:
      "blink sector " ++ U32.show(sector) ++ " count " ++ U32.show(count) ++ " dark " ++ U32.show(dark)
        ++ " bright " ++ U32.show(bright) ++ " darktime " ++ U32.show(darktime) ++ " brighttime "
        ++ U32.show(brighttime) ++ " random " ++ Bool.show(random)
    case _:
      "other"

def thinkers(ts: List<&2, S.Thinker>) -> String:
  match ts:
    case []:
      ""
    case t <> rest:
      " (" ++ thinker(t) ++ ")" ++ thinkers(rest)

def events(es: List<&2, Sn.Sound.Event>) -> String:
  match es:
    case []:
      ""
    case e <> rest:
      " (" ++ Sn.Sound.Event.show(e) ++ ")" ++ events(rest)

def running(s: S.State) -> String:
  " thinkers" ++ thinkers(Fx.Closed.running(s))

def sounds(s: S.State) -> String:
  " sounds" ++ events(S.State.sounds(s))

def ceiling(s: S.State) -> String:
  " ceiling " ++ F.Fixed.show(Fx.Closed.ceil(s, 1))

def floor(s: S.State) -> String:
  " floor " ++ F.Fixed.show(L.Level.floor(S.State.level(s), 0))

def floors.of(p: U32 & U32 & U32) -> String:
  (a, b, c) = p
  " floors " ++ F.Fixed.show(a) ++ " " ++ F.Fixed.show(b) ++ " " ++ F.Fixed.show(c)

def floors(s: S.State) -> String:
  floors.of(Fx.Closed.floors(s))

def seen.of(p: U32 & U32) -> String:
  (f, texture) = p
  " floor " ++ F.Fixed.show(f) ++ " texture " ++ U32.show(texture)

def seen(s: S.State) -> String:
  seen.of(Fx.Closed.seen(s))

def special(s: S.State) -> String:
  " special " ++ U32.show(L.Level.special(S.State.level(s), 0))

def light(s: S.State) -> String:
  " light " ++ U32.show(Fx.Closed.light(s))

def m_random(s: S.State) -> String:
  " m_random " ++ U32.show(S.State.mrnd(s))

def p_random(s: S.State) -> String:
  " p_random " ++ U32.show(S.State.rnd(s))

def spawned(s: S.State) -> String:
  S.State{player, +level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn, secrets} = s
  " light " ++ U32.show(L.Level.sector.light(level, 1)) ++ " p_random " ++ U32.show(rnd) ++
    " sector_special " ++ U32.show(L.Level.sector.special(level, 1))


# The player's place, facing, momentum, heights and eye, and whether the
# rest of it is as it began: no line crossed, G_PlayerReborn's inventory,
# no weapon sprite showing and the mobj unhurt.
def player.of(p: S.Player) -> String:
  S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt} = p
  " x " ++ F.Fixed.show(x) ++ " y " ++ F.Fixed.show(y) ++ " z " ++ F.Fixed.show(z) ++ " angle " ++ A.Angle.show(angle)
    ++ " momentum " ++ F.Fixed.show(momx) ++ " " ++ F.Fixed.show(momy) ++ " " ++ F.Fixed.show(momz)
    ++ " floor " ++ F.Fixed.show(floorz) ++ " ceiling " ++ F.Fixed.show(ceilz) ++ " view " ++ F.Fixed.show(viewheight)
    ++ " delta " ++ F.Fixed.show(deltaview) ++ " viewz " ++ F.Fixed.show(viewz) ++ " rest as it was "
    ++ Bool.show(Fx.began(crossed, inv, psprites, hurt))

def player(s: S.State) -> String:
  player.of(S.State.player(s))

def heard(tag: String, p: U32 & U32) -> IO(Unit):
  (vol, sep) = p
  IO.print(tag ++ " vol " ++ U32.show(vol) ++ " sep " ++ U32.show(sep))

# A manual door, vanilla's T_VerticalDoor, used from the west room on tic
# 1. The top is 4 under the lower ceiling beside it, 68. It rises 2 a
# tic, so it is at 2 after tic 1 and at 68 after tic 34; tic 35 would
# pass, so it lands and the wait of VDOORWAIT, 150, starts; the count
# reaches zero on tic 185, which only turns the door; tic 186 is the
# first step down, tic 219 shuts it with the travel down still its
# step, and tic 220 passes the floor and ends the thinker. The sounds
# are where T_VerticalDoor and EV_VerticalDoor start them: sfx_doropn,
# 20, on the tic of the use, nothing on the next, sfx_dorcls, 21, on
# tic 185 as the wait ends, and nothing as it shuts. The door's lines
# span x 64 to 80 and y 0 to 128, so it sounds from (72, 64), 40 east of
# the player, who faces it: full volume, and dead ahead is 129. Two
# starts draw twice from M_Random and each of the 219 tics draws once
# for ST_Ticker's face, so the index stands at 221.
def door() -> IO(Unit):
  do IO<Unit>:
    watch(~ceiling, "door", [32n, 1n, 151n, 1n, 32n, 1n], Fx.Closed.used(0n, Fx.Closed.west()))
    watch(~running, "door", [1n], Fx.Closed.used(218n, Fx.Closed.west()))
    watch(~sounds, "door", [1n, 183n], Fx.Closed.used(0n, Fx.Closed.west()))
    watch(~sounds, "door", [], Fx.Closed.used(218n, Fx.Closed.west()))
    watch(~m_random, "door", [], Fx.Closed.used(218n, Fx.Closed.west()))

# The blazing door, used from the east room, moves 8 a tic: 8 after tic
# 1, 64 after tic 8; tic 9 would pass and lands on 68; the wait ends on
# tic 159, tic 160 is 60, tic 167 is 4, and tic 168 lands on the floor
# and ends the thinker.
def blazing() -> IO(Unit):
  do IO<Unit>:
    watch(~ceiling, "blazing door", [7n, 1n, 150n, 1n, 7n, 1n], Fx.Closed.used(0n, Fx.Closed.east()))
    watch(~running, "blazing door", [], Fx.Closed.used(167n, Fx.Closed.east()))

# The west room's floor going down 4 a tic toward -16, with a player
# standing on it at x.
def carrying(x: U32) -> S.State:
  Fx.Closed.moving(Fx.Closed.doors(),
    S.Mover{0, False{}, 262144, [S.Travel{True{}, 4293918720}], [S.Travel{True{}, 4293918720}], Sp.Sim.noise.floor()},
    x, 4194304, 8388608)

# A moving floor carries the player standing on it, vanilla's
# P_ThingHeightClip. A player at (32, 64) is in the one cell of the
# sector's block box: after tic 1 the floor, the player's height and the
# player's floor are -4, the view height is still 41 with no delta, so
# no dip, and the eye, worked out when the tic began, follows a tic
# later, at 37 after tic 2 over a floor at -8. A player at (200, 64) is
# a cell outside the box, and is left where it was.
def carried() -> IO(Unit):
  do IO<Unit>:
    watch(~player, "carried", [1n], Fx.Closed.idled(1n, carrying(2097152)))
    watch(~player, "outside", [], Fx.Closed.idled(1n, carrying(13107200)))

# The door at 68 closing 2 a tic over a player 56 tall standing across
# both its faces at (72, 64).
def crushing() -> S.State:
  Fx.Closed.moving(L.Level.plane.put(Fx.Closed.doors(), 1, True{}, 4456448),
    S.Mover{1, True{}, 131072, [S.Travel{True{}, 0}], [S.Travel{False{}, 4456448}, S.Hold{150}, S.Travel{True{}, 0}], Sp.Sim.noise.door()},
    4718592, 4194304, 4456448)

# A door that closes on the player goes back up: 56 after 6 tics; the
# 7th would be 54, which the player does not fit, so the step is undone
# and the door is back on its plan, steps and plan alike; 58 after the
# 8th.
def crushed.door() -> IO(Unit):
  do IO<Unit>:
    watch(~ceiling, "crushed door", [1n, 1n], Fx.Closed.idled(6n, crushing()))
    watch(~running, "crushed door", [], Fx.Closed.idled(7n, crushing()))

# A walk-over line fires from the move that crosses it, once, and
# special 36 is vanilla's turboLower: 4 a tic down to the highest floor
# around, plus 8 when that is not the floor's own. A player at (60, 64)
# moving 8 a tic east crosses line 0 on the first tic. Sector 1, floor
# 16 between floors at 0, goes to 8: 12 after that tic, 8 after the
# second, its thinker gone on the third. Sectors 0 and 2, floors at 0
# beside one at 16, go to 24, which is above them, and a travel down to
# a height above lands at once. The line's special is 0 from the first
# tic. A player at (44, 64) moving 6 a tic ends with its box across the
# line and its centre short of it: nothing starts, the special stays 36.
def turbo() -> IO(Unit):
  do IO<Unit>:
    watch(~floors, "turbo", [1n], Fx.Closed.idled(1n, Fx.Closed.turbo(3932160, 524288)))
    watch(~running, "turbo", [], Fx.Closed.idled(3n, Fx.Closed.turbo(3932160, 524288)))
    watch(~special, "turbo", [], Fx.Closed.idled(1n, Fx.Closed.turbo(3932160, 524288)))
    watch(~running, "short of the line", [], Fx.Closed.idled(1n, Fx.Closed.turbo(2883584, 393216)))
    watch(~special, "short of the line", [], Fx.Closed.idled(1n, Fx.Closed.turbo(2883584, 393216)))

# The lift, vanilla's downWaitUpStay, and the switch that calls it. The
# use on tic 1 gives each sector a lift (the west room's: 4 a tic down
# to -32, the lowest floor around, 105 tics there, back up to 0; the
# door sector's is at its lowest already, so its first tic lands and
# waits, to come back to -32) and swaps the switch to 2 with a button of
# 35 tics, 34 after that tic. The lifts' noises are T_PlatRaise's:
# sfx_pstart, 18, as each starts, as its wait ends and as it is turned
# back, sfx_pstop, 19, as it lands. The west room's floor is -32 after
# tic 8; tic 9 lands and the wait starts; the count reaches zero on tic
# 114; -28 after tic 115, 0 after tic 122, and its thinker gone on tic
# 123. The switch shows 2 through tic 34 and 1 again from tic 35.
# The sounds of tic 1: EV_DoPlat starts sfx_pstart in each sector of the
# tag, P_ChangeSwitchTexture clicks sfx_swtchn, 23, from nobody since no
# button runs yet, and the door sector's lift lands with sfx_pstop. The
# three sectors' boxes are centred at (64, 64), (72, 64) and (80, 64),
# all dead ahead of the player at (32, 64) and nearer than 200. The
# button pops back on tic 35 with a click from the map's origin, where
# vanilla's mistaken origin reads its place: 32 + 64 - 16 = 80 away, at
# angle ANG270 - 1 - tantoangle[1024], fine index 5539, sine -58617,
# whose -85.86 floors to 86 right of 128.
def lift() -> IO(Unit):
  do IO<Unit>:
    watch(~running, "lift", [], Fx.Closed.used(0n, Fx.Closed.lifts()))
    watch(~seen, "lift", [26n, 1n, 79n, 1n, 7n], Fx.Closed.used(7n, Fx.Closed.lifts()))
    watch(~running, "lift", [], Fx.Closed.used(122n, Fx.Closed.lifts()))
    watch(~sounds, "lift", [34n], Fx.Closed.used(0n, Fx.Closed.lifts()))

# The switched floor, vanilla's lowerFloorToLowest, T_MoveFloor's noise
# sfx_stnmov, 22, as it grinds and sfx_pstop as it lands: 1 a tic down
# to the lowest floor around, its own included. The use on tic 1 starts
# the west room and the east room toward the door sector's -32; the door
# sector is at its lowest already, so its first tic lands and ends it.
# The west room is -1 after tic 1 and -32 after tic 32; tic 33 would
# pass it, so it lands and both thinkers end. The switch works once: its
# line has no special from the first tic.
def lowered() -> IO(Unit):
  do IO<Unit>:
    watch(~floor, "lowered", [31n], Fx.Closed.used(0n, Fx.Closed.switched(23)))
    watch(~running, "lowered", [32n], Fx.Closed.used(0n, Fx.Closed.switched(23)))
    watch(~special, "lowered", [], Fx.Closed.used(0n, Fx.Closed.switched(23)))

# The west room's floor at -32 under a ceiling at 40, rising 4 a tic
# under a player 56 tall.
def rising() -> S.State:
  Fx.Closed.moving(L.Level.plane.put(L.Level.plane.put(Fx.Closed.doors(), 0, False{}, 4292870144), 0, True{}, 2621440),
    S.Mover{0, False{}, 262144, [S.Travel{False{}, 0}], [S.Travel{True{}, 4292870144}, S.Hold{105}, S.Travel{False{}, 0}], Sp.Sim.noise.lift()},
    2097152, 4194304, 2621440)

# A lift that rises into a player who does not fit goes back down: -16
# after 4 tics, which leaves 56; the 5th would leave 52, so it is undone
# and the lift is back on its plan; -20 after the 6th.
def crushed.lift() -> IO(Unit):
  watch(~floor, "crushed lift", [1n, 1n], Fx.Closed.idled(4n, rising()))

# S_AdjustSoundParams, by hand from s_sound.c and tables.c, for a
# listener some units south of a source, facing an angle. The source is
# due north, at angle ANG90 - 1. Facing east the angle between is fine
# index 2047, whose sine 65535 swings 95 left of 128; facing west it is
# 6143, sine -65535, and the floor of -95.99 swings 96 right; facing
# south 4095, sine 25, centred; facing north 8191, sine -25, whose
# product floors to -1: dead ahead is 129. At 400 units 800 of the 1000
# are left, 64 * 800 / 1000 = 51; 200 is still 64 and 201 is 63; 1184
# leaves 16, volume 1, and 1185 leaves 15, which rounds to 0 and is not
# heard, 15 units inside the clipping distance; 1201 is clipped. A
# source where a listener facing north stands is at distance 0, full
# volume; S_StartSound centres it at 128, but S_UpdateSounds takes
# R_PointToAngle2's 0 less ANG90 and one more, fine index 6143, sine
# -65535, and swings it 96 right, to 224.
def places() -> IO(Unit):
  do IO<Unit>:
    heard("heard 400 facing 0", Fx.Closed.heard(400, 0))
    heard("heard 400 facing 180", Fx.Closed.heard(400, 2147483648))
    heard("heard 400 facing 270", Fx.Closed.heard(400, 3221225472))
    heard("heard 200 facing 90", Fx.Closed.heard(200, 1073741824))
    heard("heard 201 facing 90", Fx.Closed.heard(201, 1073741824))
    heard("heard 1184 facing 90", Fx.Closed.heard(1184, 1073741824))
    heard("heard 1185 facing 90", Fx.Closed.heard(1185, 1073741824))
    heard("heard 1201 facing 90", Fx.Closed.heard(1201, 1073741824))
    heard("coincident start", Fx.Closed.coincident(True{}))
    heard("coincident update", Fx.Closed.coincident(False{}))

# The door sector at light 160 beside the west room at 96, the random
# index at 1. The random blink, vanilla's T_LightFlash: its first count
# is the table's entry 2, 109, masked with 64, plus 1: 65. On tic 65 it
# goes dark for entry 3, 220, masked with 7, plus 1: 5 tics. On tic 70
# it is bright again for entry 4, 222, masked with 64, plus 1, and the
# index stands at 4. The slow strobe in step, vanilla's T_StrobeFlash:
# dark from the first tic for 35, bright for 5. Beside a room at 96 its
# dark level is 96; beside rooms no darker than its own 160 it is 0. The
# glow, vanilla's T_Glow, 8 a tic between 160 and 96: 152 after tic 1,
# 104 after tic 7; tic 8 would reach 96, so it is undone and the glow
# turns; 112 after tic 9, 152 after tic 14; tic 15 would reach 160, is
# undone and turns it; 144 after tic 16.
def lights() -> IO(Unit):
  do IO<Unit>:
    watch(~running, "blink", [65n, 5n], Fx.Closed.lit(1, 96))
    watch(~light, "blink", [1n, 4n, 1n], Fx.Closed.idled(64n, Fx.Closed.lit(1, 96)))
    watch(~p_random, "blink", [], Fx.Closed.idled(70n, Fx.Closed.lit(1, 96)))
    watch(~light, "strobe beside 96", [1n, 34n, 1n, 4n, 1n], Fx.Closed.lit(12, 96))
    watch(~light, "strobe beside 160", [35n, 5n], Fx.Closed.idled(1n, Fx.Closed.lit(12, 160)))
    watch(~light, "glow", [6n, 1n, 1n, 5n, 1n, 1n], Fx.Closed.idled(1n, Fx.Closed.lit(8, 96)))
    watch(~spawned, "fast strobe", [6n, 15n, 5n], Fx.Closed.lit(2, 96))
    watch(~spawned, "slow strobe", [6n, 35n, 5n], Fx.Closed.lit(3, 96))
    watch(~spawned, "sync fast strobe", [1n, 15n, 5n], Fx.Closed.lit(13, 96))


def damage.seen(+s: S.State) -> String:
  " health " ++ U32.show(I.Inventory.health(S.Player.inv(S.State.player(s)))) ++
    " flash " ++ U32.show(S.Sim.Hurt.damage(S.Player.hurt(S.State.player(s)))) ++ p_random(s)

def damage.start(suit: U32, rnd: U32) -> S.State:
  S.State.rnd.put(rnd, S.State.player.put(Fx.Closed.west(),
    S.Player.holding(Fx.Closed.player(2097152, 4194304, 0, 8388608),
      I.Inventory.power(I.Inventory.pw_ironfeet(), suit, I.Inventory.start()))))

# P_PlayerInSpecialSector gates damage on clock&31; suit leakage rolls even between hits.
def damage() -> IO(Unit):
  do IO<Unit>:
    IO.print("20 percent" ++ damage.seen(Sp.Sim.sector.grounded(True{}, 16, 0, damage.start(0, 0))))
    IO.print("between hits" ++ damage.seen(Sp.Sim.sector.grounded(True{}, 16, 1, damage.start(0, 0))))
    IO.print("airborne" ++ damage.seen(Sp.Sim.sector.grounded(False{}, 16, 0, damage.start(0, 0))))
    IO.print("suit blocks nukage" ++ damage.seen(Sp.Sim.sector.grounded(True{}, 7, 0, damage.start(1, 0))))
    IO.print("suit leak between hits" ++ damage.seen(Sp.Sim.sector.grounded(True{}, 16, 1, damage.start(1, 255))))
    IO.print("suit leaks" ++ damage.seen(Sp.Sim.sector.grounded(True{}, 16, 0, damage.start(1, 255))))

def main() -> IO(Unit):
  do IO<Unit>:
    door()
    blazing()
    carried()
    crushed.door()
    turbo()
    lift()
    lowered()
    crushed.lift()
    places()
    lights()
    damage()

#|door tic 1 ceiling 2.000000
#|door tic 33 ceiling 66.000000
#|door tic 34 ceiling 68.000000
#|door tic 185 ceiling 68.000000
#|door tic 186 ceiling 66.000000
#|door tic 218 ceiling 2.000000
#|door tic 219 ceiling 0.000000
#|door tic 219 thinkers (mover sector 1 ceiling speed 2.000000 steps down to 0.000000 plan up to 68.000000 hold 150 down to 0.000000 noise 20 21 0 0 20 0)
#|door tic 220 thinkers
#|door tic 1 sounds (DSDOROPN from sector 1 vol 64 sep 129)
#|door tic 2 sounds
#|door tic 185 sounds (DSDORCLS from sector 1 vol 64 sep 129)
#|door tic 219 sounds
#|door tic 219 m_random 221
#|blazing door tic 1 ceiling 8.000000
#|blazing door tic 8 ceiling 64.000000
#|blazing door tic 9 ceiling 68.000000
#|blazing door tic 159 ceiling 68.000000
#|blazing door tic 160 ceiling 60.000000
#|blazing door tic 167 ceiling 4.000000
#|blazing door tic 168 ceiling 0.000000
#|blazing door tic 168 thinkers
#|carried tic 1 x 32.000000 y 64.000000 z -4.000000 angle 0.000 momentum 0.000000 0.000000 0.000000 floor -4.000000 ceiling 128.000000 view 41.000000 delta 0.000000 viewz 41.000000 rest as it was True
#|carried tic 2 x 32.000000 y 64.000000 z -8.000000 angle 0.000 momentum 0.000000 0.000000 0.000000 floor -8.000000 ceiling 128.000000 view 41.000000 delta 0.000000 viewz 37.000000 rest as it was True
#|outside tic 1 x 200.000000 y 64.000000 z 0.000000 angle 0.000 momentum 0.000000 0.000000 0.000000 floor 0.000000 ceiling 128.000000 view 41.000000 delta 0.000000 viewz 41.000000 rest as it was True
#|crushed door tic 6 ceiling 56.000000
#|crushed door tic 7 ceiling 56.000000
#|crushed door tic 8 ceiling 58.000000
#|crushed door tic 7 thinkers (mover sector 1 ceiling speed 2.000000 steps up to 68.000000 hold 150 down to 0.000000 plan up to 68.000000 hold 150 down to 0.000000 noise 20 21 0 0 20 0)
#|turbo tic 1 floors 24.000000 12.000000 24.000000
#|turbo tic 2 floors 24.000000 8.000000 24.000000
#|turbo tic 3 thinkers
#|turbo tic 1 special 0
#|short of the line tic 1 thinkers
#|short of the line tic 1 special 36
#|lift tic 1 thinkers (mover sector 0 floor speed 4.000000 steps down to -32.000000 hold 105 up to 0.000000 plan down to -32.000000 hold 105 up to 0.000000 noise 18 18 19 19 18 0) (mover sector 1 floor speed 4.000000 steps hold 105 up to -32.000000 plan down to -32.000000 hold 105 up to -32.000000 noise 18 18 19 19 18 0) (mover sector 2 floor speed 4.000000 steps down to -32.000000 hold 105 up to 0.000000 plan down to -32.000000 hold 105 up to 0.000000 noise 18 18 19 19 18 0) (button side 0 slot 2 texture 1 tics 34)
#|lift tic 8 floor -32.000000 texture 2
#|lift tic 34 floor -32.000000 texture 2
#|lift tic 35 floor -32.000000 texture 1
#|lift tic 114 floor -32.000000 texture 1
#|lift tic 115 floor -28.000000 texture 1
#|lift tic 122 floor 0.000000 texture 1
#|lift tic 123 thinkers
#|lift tic 1 sounds (DSPSTART from sector 0 vol 64 sep 129) (DSPSTART from sector 1 vol 64 sep 129) (DSPSTART from sector 2 vol 64 sep 129) (DSSWTCHN from nobody vol 64 sep 128) (DSPSTOP from sector 1 vol 64 sep 129)
#|lift tic 35 sounds (DSSWTCHN from spot 0.000000 0.000000 vol 64 sep 214)
#|lowered tic 1 floor -1.000000
#|lowered tic 32 floor -32.000000
#|lowered tic 1 thinkers (mover sector 0 floor speed 1.000000 steps down to -32.000000 plan down to -32.000000 noise 0 0 19 19 0 22) (mover sector 2 floor speed 1.000000 steps down to -32.000000 plan down to -32.000000 noise 0 0 19 19 0 22)
#|lowered tic 33 thinkers
#|lowered tic 1 special 0
#|crushed lift tic 4 floor -16.000000
#|crushed lift tic 5 floor -16.000000
#|crushed lift tic 6 floor -20.000000
#|heard 400 facing 0 vol 51 sep 33
#|heard 400 facing 180 vol 51 sep 224
#|heard 400 facing 270 vol 51 sep 128
#|heard 200 facing 90 vol 64 sep 129
#|heard 201 facing 90 vol 63 sep 129
#|heard 1184 facing 90 vol 1 sep 129
#|heard 1185 facing 90 vol 0 sep 129
#|heard 1201 facing 90 vol 0 sep 129
#|coincident start vol 64 sep 128
#|coincident update vol 64 sep 224
#|blink tic 0 thinkers (blink sector 1 count 65 dark 96 bright 160 darktime 7 brighttime 64 random True)
#|blink tic 65 thinkers (blink sector 1 count 5 dark 96 bright 160 darktime 7 brighttime 64 random True)
#|blink tic 70 thinkers (blink sector 1 count 65 dark 96 bright 160 darktime 7 brighttime 64 random True)
#|blink tic 64 light 160
#|blink tic 65 light 96
#|blink tic 69 light 96
#|blink tic 70 light 160
#|blink tic 70 p_random 4
#|strobe beside 96 tic 0 light 160
#|strobe beside 96 tic 1 light 96
#|strobe beside 96 tic 35 light 96
#|strobe beside 96 tic 36 light 160
#|strobe beside 96 tic 40 light 160
#|strobe beside 96 tic 41 light 96
#|strobe beside 160 tic 1 light 0
#|strobe beside 160 tic 36 light 160
#|strobe beside 160 tic 41 light 0
#|glow tic 1 light 152
#|glow tic 7 light 104
#|glow tic 8 light 104
#|glow tic 9 light 112
#|glow tic 14 light 152
#|glow tic 15 light 152
#|glow tic 16 light 144

# P_SpawnStrobeFlash consumes entry2=109: (109&7)+1=6; synced count1 consumes none.
#|fast strobe tic 0 light 160 p_random 2 sector_special 0
#|fast strobe tic 6 light 96 p_random 2 sector_special 0
#|fast strobe tic 21 light 160 p_random 2 sector_special 0
#|fast strobe tic 26 light 96 p_random 2 sector_special 0
#|slow strobe tic 0 light 160 p_random 2 sector_special 0
#|slow strobe tic 6 light 96 p_random 2 sector_special 0
#|slow strobe tic 41 light 160 p_random 2 sector_special 0
#|slow strobe tic 46 light 96 p_random 2 sector_special 0
#|sync fast strobe tic 0 light 160 p_random 1 sector_special 0
#|sync fast strobe tic 1 light 96 p_random 1 sector_special 0
#|sync fast strobe tic 16 light 160 p_random 1 sector_special 0
#|sync fast strobe tic 21 light 96 p_random 1 sector_special 0

# Source m_random.c entries0=0 and1=8; a surviving damage hit takes a pain roll.
#|20 percent health 80 flash 20 p_random 1
#|between hits health 100 flash 0 p_random 0
#|airborne health 100 flash 0 p_random 0
#|suit blocks nukage health 100 flash 0 p_random 0
#|suit leak between hits health 100 flash 0 p_random 0
#|suit leaks health 80 flash 20 p_random 1
