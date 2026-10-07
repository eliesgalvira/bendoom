# E1M1 from the WAD named by BENDOOM_IWAD, loaded by the game's loader,
# and scripted runs through the game's step. First two walks from the
# player 1 start, the position, facing, height, floor and eye above the
# floor after each run of held keys (U up, D down, L left, R right, A
# strafe left, S strafe right, ! run): the first turns on the lift its
# run called and rides it into the pit; the second runs across that
# lift and off its east edge into the fall and the landing. Freedoom's
# first map is not id's: the shareware start is 1056, -3616 facing 90.
# The start's things, as a nushell replay of P_SpawnMapThing over the
# THINGS records, info.c and m_random.c finds them on Hurt Me Plenty:
# how many, the random index once they and the three flashes have drawn,
# how many of each type Bendoom defines, the names of the first twelve
# (records 0, 1, 4 and 5 are for the easy skills and 7 for multiplayer),
# and ten records: the first, animated armour, a leg hung from its
# ceiling, the blue key, the dead former sergeant, the last, and one
# monster of each type, the zombieman and the demon deaf, each with the
# sector under it (tools/wad.nu's sector-at), its z, its facing (its
# record's angle), its state row, its tics, its definition and whether
# P_SpawnMapThing left it in ambush, which is bit 8 of its record's
# options. The blockmap's links against that population, the player's
# mobj's left out: 209 links for 209 things, 108 of them solid (the
# solid types' counts in ticket 02's nushell inventory and the 29
# monsters), none of a thing gone or in another cell than its centre's,
# and no thing missing from the cell of its centre. The player's
# inventory, G_PlayerReborn's.
# Then the pistol from the start: the weapon sprite's state row, tics and
# place on the screen, and the flash's, after chosen tics. It rises 6 a
# tic from 122 for 15 tics, rests at column 1, row 32, bobs on a walk
# east begun on tic 21, and is at rest again 60 tics after the walk
# ends: a nushell replay of p_pspr.c's P_SetupPsprites, P_MovePsprites,
# A_Raise and A_WeaponReady over the bob that p_user.c's thrust and
# p_mobj.c's friction give on open ground, with Chocolate Doom's
# finesine.
# Then Ctrl fires that pistol, each run printed with the tic, the two
# sprites, the extra light, the bullets left, P_Random's index and every
# mobj past the map's 292 records, which is what the shot spawned. The
# tics are p_pspr.c by hand: A_WeaponReady fires on the tic the attack
# is seen, S_PISTOL1's 4 tics run out on tic 25 and A_FirePistol runs as
# S_PISTOL2, row 80, is entered, and A_ReFire on S_PISTOL4 fires again
# 14 tics later, so the shots are on tics 25 and 39. The flash, row 83,
# shows 6 of S_PISTOLFLASH's 7 tics on the tic it is set, since
# P_MovePsprites reaches the flash after the weapon's action has set it,
# and its row lends the view a light of 1 until S_LIGHTDONE. Each shot
# spends one bullet, and with an empty clip P_CheckAmmo refuses, so
# neither the bullets nor the index move. The draws are P_GunShot's
# damage, its two spread draws when the shot is not the first of a
# press, and P_SpawnPuff's two for the z, P_SpawnMobj's one and one for
# the tics: 5 for the first shot (65 to 70), 7 for a held one (70 to 77)
# and 1 where the bullet meets the sky, which spawns nothing. The puff
# rises a unit a tic on P_SpawnPuff's momentum and is removed as it
# leaves row 88, which stops its sound. The index at the start of each
# case and the values the table gives for the z and the tics are
# regression pins. The places are read from the WAD: the start faces a
# one-sided wall at x 1328 and the puff stands 4 units back along the
# ray; from the pit at (704, 256), floor -128, line 585 steps up to a
# floor at 32, which the level shot meets at x 768; and from the yard at
# (-640, 256), line 1049 has sector 40 behind it, whose ceiling is
# F_SKY1, so PTR_ShootTraverse's sky hack leaves nothing.
# Then bullets hurt things, each run printed with the tic, where the
# player stands, its health and armour, P_Random's index, each watched
# mobj and every mobj the shots and the blows spawned. The places are
# the WAD read in nushell: record 265 is the zombieman at (944, -224)
# in sector 57, shot from 80 units east of it, and records 24, 25 and 26
# are the barrels at (992, 608), (992, 640) and (960, 608) in sector 13,
# shot from 64 units north of the nearest. The rows are info.c's:
# S_POSS_PAIN is row 121 and S_POSS_DIE1 row 123, whose S_POSS_DIE2
# runs A_Scream, and the corpse rests in S_POSS_DIE5, row 127, which
# lasts; the barrel's S_BEXP is row 176, its S_BEXP2 screams and its
# S_BEXP4, row 179, explodes ten tics later. P_SpawnBlood's frame is the
# wound's: row 182 for a wound of 9 to 12, row 183 under 9 and row 181
# over 12, which is the only one whose tics the draw shortens, since
# P_SetMobjState gives the other two their whole 8 again. A dead
# zombieman is no longer shootable, so the last shot flies past its
# corpse to the wall and leaves a puff. The monsters call out here,
# since they see the player the tic the level begins. The blast the barrels deal is
# PIT_RadiusAttack by hand: the player 74.53 units north of barrel 25,
# which the shots had pushed south, is 58 whole units away once its own
# radius of 16 is taken off, so it takes 128 less 58, and green armour
# saves a third of 70, which is 23, leaving 77 armour and 53 health. The
# blow throws the player north, and by the time the other two barrels
# explode it is out of their reach. The damage each shot deals and the tics each death
# state loses are P_Random draws and are regression pins, as the index
# at the start of each case is.
# Then the pickups, each run printed with the tic, the player's place,
# the inventory, the things left and the records taken since the case
# began: a clip, three shells in a row and the rocket walked into, with
# room and at the cap; the shell box behind the closet door west of the
# clips, with room, one clip short of the cap and at it; the chainsaw
# on its step, strafed past on the key's script, not owned and owned;
# then a health, armour or berserk pickup of each type Freedoom's E1M1
# spawns, walked at alone from 80 short, holding the start's inventory
# or one with other health or armour: the tic before contact, 41.61
# short, and the tic of it, 35.84 short, inside the reach of 36. The
# grants are Chocolate Doom's P_TouchSpecialThing, P_GiveBody,
# P_GiveArmor, P_GivePower, P_GiveAmmo and P_GiveWeapon on Hurt Me
# Plenty: clipammo 10 4 20 1, five clips in a box, maxammo 200 50 300
# 50, a flash of 6; the chainsaw is owned, weapons 3 to 131; the health
# bonus makes 101 and counts, and at 200 is taken for nothing; the
# stimpack and medikit stay at 100 health, walked across or not, and
# heal 60 to 70 and 85; the berserk pack counts, heals 60 to 100, and
# its strength counts up from 1 on the tic after, 11 ten tics on; the
# armour bonus makes 1 point of type 1 and counts; green armour makes
# 100 of type 1 and stays for 100. Every contact tic, where the reach of
# 36 is first met, is a regression pin.
# Then the damage, each run printed with the place line, the health, the
# armour, the momentum, the mobj's state row and tics, the damage count,
# the attacker, the player sprites, the random index and whether the
# state asks for the level again. The nukage of Freedoom's sector 173,
# stood in from 1600, 1000: P_PlayerInSpecialSector takes 5 health every
# 32 tics of the clock, the first on the tic the level begins, and
# P_DamageMobj puts the mobj into its pain state, whose second row
# sounds sfx_plpain where P_MobjThinker's count of 4 runs out, three
# tics later; the pain state is entered unless the draw reaches the
# player's pain chance of 255, which none of these does.
# P_PlayerThink's counters fade the damage count on the tic that raises
# it. Armour takes a third of the blow when green and a half when blue,
# rounded down, so 1 and 2 of 5, and green armour of a single point
# gives it and loses its type. Nearby monsters also attack during the
# longer run. On death, P_KillMobj drops the weapon, which
# A_Lower sinks 6 as it enters the down state and 6 more in
# P_MovePsprites, and puts the mobj in its death state for 10 tics less
# a random 0 to 3, a regression pin, since the level's random blinks
# draw between the blows; its second row sounds sfx_pldeth.
# P_DeathThink then sinks the view a unit a tic from 41 to 6 and leaves
# the corpse in the last death row, and a use asks for the level again.
# The health, the shares, the rows and the tics are p_inter.c, p_spec.c,
# p_user.c, p_pspr.c and info.c worked by hand.
# Then two synthetic blows in the one-sector room, Level.room,
# from a barrel of the state's own: 20
# points from 64 units south thrust the player by 20 * 8192 along the
# angle from the inflictor, which for a thing due south is ANG90 - 1,
# fine index 2047, sine 65535 and cosine 25, so 2.499954 north and
# 0.000946 east, and the pain roll draws 8 at index 1. A lethal 20
# points from 512 units south and 128 below draw first for the fall
# forwards, 109 at index 2, which is odd, so the angle turns by 180 and
# the thrust is four times as much, 9.999847 south; P_KillMobj's draw
# is then 220 at index 3, whose low two bits are 0, so the death state
# keeps its 10 tics. The view turns to the attacker 5 degrees a tic
# from 0 degrees toward 270: 18 steps of ANG90/18 leave 10 units of
# angle, inside ANG5, so the nineteenth snaps to it, and the damage
# count holds until the view is on the attacker and fades from then on.
# The sine, the cosine and the draws are Chocolate Doom's tables.c and
# m_random.c.
# Then the clip west of 672, 992: a player killed on the spot and slid
# west at 5 a tic passes over it and takes nothing, where a living one
# slid the same way takes it.
# Then the movers and the lights, as runs of one command in a demo's
# units from a place, each line with the clock, the thinkers running
# and chosen sectors' floors and ceilings: the first door used, turned
# twice, held, walked through and closed on the player; the special 23
# switch; a special 2 line crossed both ways; the lift called by its
# line and by its switch; the blue key taken, and its door, sector 71,
# opening for the blue skull alone; the exit switch; the blinks and the
# strobe from the start. The heights and tics are the hand computations
# in milestone 4's tickets 04 to 10; the blinks' lights, a nushell
# replay of T_LightFlash over Chocolate Doom's random table from index
# 56, where the spawn leaves it; the positions are regression pins.
# The key's tic is P_TouchSpecialThing's reach, its
# radius 20 and the player's 16: tic 33 leaves the player 37.79 east of
# it, tic 34 35.58 east and 28.51 south, the tic Chocolate Doom's status
# bar first shows the card on the same script; P_GiveCard's flash of 6
# and the pickup's 6 make 12, one less a tic after. Door 71's top is 4
# under the ceilings of 0 beside it in the WAD, reached at 2 a tic on
# tic 92. Between the exit and the lights, from the start to tic 36, the
# state row and tics of a lasting chainsaw, the armour, the blue key, a
# barrel, an armour bonus, a health bonus and the twitching impaled
# body: a nushell replay of P_MobjThinker over info.c's states from the
# spawn's tics, the rows numbered in info.c's order.
# Then, on a copy of the map with three of its monster records
# rewritten, solid things stop the player and movers, and carried things
# ride them, as solids says; and the blue key door refuses a use, a blue card is taken
# and the door then opens, in one replay, as locked says.
# Every run prints, before its own line, a line for each sound its tics
# started or stopped, under the clock after the tic. M_Random draws
# once per ST_Ticker, 320 times after the second startup command, and
# once per sound pitch except item pickups. The shell box cases draw
# once for the closet door, opened before their first run. Which sound,
# from whom and on which tic is read
# from where Chocolate Doom calls S_StartSound: EV_VerticalDoor's
# sfx_doropn on the use, T_VerticalDoor's sfx_dorcls as the wait ends
# (tic 253) and sfx_doropn again as the door meets the player (tic 288)
# or the barrel (tic 295); EV_DoPlat's sfx_pstart and T_PlatRaise's
# sfx_pstop as the lift lands and sfx_pstart as its wait ends, on the
# tics of the heights above; T_MoveFloor's sfx_stnmov while leveltime's
# low three bits are clear, the clock before the tic, and its sfx_pstop
# as each floor lands; EV_DoDoor's sfx_doropn for the crossed line;
# PTR_UseTraverse's sfx_noway from the player at the used-up switch's
# wall; EV_VerticalDoor's sfx_oof from nobody at the locked door;
# P_ZMovement's sfx_oof from the player on the landing, tic 61 of the
# second walk, where the fall's momentum, 2 on tic 48 and one more a
# tic, is 14 and the drop of 104 units is spent; P_TouchSpecialThing's
# sfx_itemup, sfx_wpnup for the chainsaw and sfx_getpow for the berserk
# pack from nobody on each contact tic, after P_RemoveMobj's stop of the
# thing; P_ChangeSwitchTexture's sfx_swtchn from nobody, since no button
# runs, for the special 23 switch and for the exit, whose special vanilla
# clears before it looks for the exit's own sound. Volume
# and separation are tools/sound.nu's replay of S_AdjustSoundParams over
# tables.c from the listener's printed place (the place before the move
# for a sound of the use) and the middle of the sector's box read from
# the WAD; where a sound falls inside a run that moves the player, in the
# two walks, they are regression pins. Eight listeners then stand still
# south of the door's origin, 832, 528, until it closes: 400 away on the
# left, on the right and behind; 200 and 201 ahead; 1184, 1185 and 1201
# ahead. Their lines hold what the level's things make them hear; the
# close's own volume and separation at those distances and facings are
# tests/sectors.bend's, worked by hand.
# Last, the links and the thinkers of things that move, spawn and leave
# in play, as relinks says, each line with the mobjs of two blockmap
# cells, the last linked first, the things two sectors show in their
# lists' order, the next id, the random index and a thing, then the
# thinkers' order. Every list is worked from vanilla's source over the
# WAD read in nushell: the blockmap's origin is -712, -1072, so the
# cells of (-400, 400) and (-400, 300) are 2,11 and 2,10, and the sectors
# under them (tools/wad.nu's sector-at) 160 and 140. P_SpawnMapThing
# spawns the records in order and P_SetThingPosition puts each first in
# its lists, so cell 2,11 lists record 58, cell 2,10 the player's mobj,
# record 157, sector 160 record 58 and sector 140 records 238 and 157,
# of which the player's is no thing to show. P_UnsetThingPosition and
# P_SetThingPosition about the move take 58 out of the first lists and
# put it first in the second. P_SpawnMobj gives the bonus the next id
# past the 292 records, draws one random number, leaves it S_BON1's 6
# tics (row 12) on the floor at 0, links it first, and adds its thinker
# at the list's tail: 181 mobjs in record order, the player's between
# records 154 and 166, then the 9 lights (the sectors of special 1, 8 or
# 12), then the bonus, which thinks that same tic, 5 tics left.
# P_RemoveMobj unlinks it, its thinker ends at its next turn, and the
# next spawned is 293, not 292 again. P_TryMove relinks the player's
# mobj first in its cell on its first move. The random index after a
# tic is the lights' draws, a regression pin.
# Then the face, a line for each tic ST_updateFaceWidget put a
# different index up and one for the face each case ends on. Every index
# is ST_calcPainOffset's offset (0 at 100 down to 80 health, 8 at 79
# down to 60, 16, 24 and 32 for the twenties under those) plus what the
# priority that chose it adds: nothing or 1 or 2 for the idle glance,
# which is st_randomnumber % 3 of the tic's own M_Random draw, 3 for a
# turn right, 4 for a turn left, 5 for the ouch face, 6 for the evil
# grin, 7 for the rampage face, and 41 for ST_DEADFACE. Each line
# carries M_Random's index after the command and any melt; every glance
# is rndtable read in nushell at that index, remainder 3: 8 at 1 and
# 92 at 99 give 2, 249 at 82 and 171 at 124 give 0, 145 at 101 and 61 at
# 137 give 1. The nukage's first blow lands on the
# tic the level begins, when the health ST_Ticker saw last is still -1,
# so vanilla's ouch test, whose subtraction is the wrong way round,
# reads a rise of 96 and puts the ouch face up; every later blow finds
# the priority its own count still holds. The blows from the right and
# the left are R_PointToAngle2 from the player at the origin facing
# east: ANG270 to a barrel due south, whose difference passes ANG180 and
# turns the face right, and ANG90-1 due north, which does not and turns
# it left, while one due east is inside ANG45 and takes the rampage face
# head on. The chainsaw is grinned at on the tic it is taken, since
# P_TouchSpecialThing sets the pickup flash before ST_Ticker looks.
# Held fire reaches ST_RAMPAGEDELAY on the 71st tic: the first sets
# lastattackdown to 70 and each after it takes one off. Every case's
# M_Random index counts the sights of that run beside its other sounds.
# Last, A_Look. Six places held still, each with the monsters watched,
# their state rows and tics, whether P_CheckSight has the player in
# sight, and P_Random's index at the end; then REJECT's bit for ten
# sector pairs. The wake tics, the sounds and the indices are a nushell
# replay of P_SpawnMapThing, P_CheckSight, P_LookForPlayers, A_Look and
# T_LightFlash over the WAD, m_random.c and tables.c, described at the
# cases below. Everywhere else in this file a monster's sight sound is
# a regression pin in its volume, separation and place, but not in its
# tic: every one of them falls on a tic the same replay gives that
# monster for an A_Look, its spawn state's tics plus a multiple of ten,
# ten more when its spawn draw left lastlook at 1.
import Base
import ../src/wad.bend as W
import ../src/fixed.bend as F
import ../src/angle.bend as A
import ../src/level.bend as L
import ../src/keys.bend as K
import ../src/sim.bend as S
import ../src/tic.bend as Tic
import ../src/things.bend as H
import ../src/inventory.bend as I
import ../src/vec.bend as V
import ../src/sound.bend as Sn
import ../src/message.bend as Msg

def line(tag: String, s: S.State) -> String:
  +p = S.State.player(s)
  tag ++ " " ++ F.Fixed.show(S.Player.x(p)) ++ " " ++ F.Fixed.show(S.Player.y(p)) ++ " "
    ++ A.Angle.show(S.Player.angle(p)) ++ " z " ++ F.Fixed.show(S.Player.z(p))
    ++ " floor " ++ F.Fixed.show(S.Player.floorz(p))
    ++ " eye " ++ F.Fixed.show((S.Player.viewz(p) - S.Player.floorz(p) : U32))

# A line for each sound of a tic, under the clock after it.
def events(es: List<&2, Sn.Sound.Event>, +clock: U32) -> String:
  match es:
    case []:
      ""
    case e <> rest:
      "sound tic " ++ U32.show(clock) ++ " " ++ Sn.Sound.Event.show(e) ++ "\n" ++ events(rest, clock)

# A replay and what was heard on the way, a line a sound.
type Run is Data:
  Run{log: String, state: S.State}

def Run.log(r: Run) -> String:
  Run{log, state} = r
  log

def Run.state(r: Run) -> S.State:
  Run{log, state} = r
  state

# An ended level runs no tic, so nothing new is heard.
def heard(ended: S.Sim.Exit, log: String, +q: S.State) -> Run:
  match ended:
    case S.Unended{}:
      Run{log ++ events(S.State.sounds(q), S.State.clock(q)), q}
    case _:
      Run{log, q}

def play(script: List<&2, K.Cmd>, r: Run) -> Run:
  match script r:
    case [] _:
      r
    case cmd <> rest Run{log, +s}:
      play(rest, heard(S.State.ended(s), log, Tic.Sim.tic(cmd, s)))

def ran(n: Nat, cmd: K.Cmd, s: S.State) -> Run:
  play(List.replicate(K.Cmd, n, cmd), Run{"", s})

# M_Random's index, printed where a case ends.
def drawn(s: S.State) -> String:
  "sounds drew to " ++ U32.show(S.State.mrnd(s))

def finished(+s: S.State) -> IO(S.State):
  do IO<S.State>:
    IO.print(drawn(s))
    return s

def step(tag: String, n: Nat, keys: K.Keys, s: S.State) -> IO(S.State):
  +r = play(K.Input.script(n, K.Input{keys, 0}), Run{"", s})
  +q = Run.state(r)
  do IO<S.State>:
    IO.print(Run.log(r) ++ line(tag, q))
    return q

def heights(sectors: List<&2, U32>, +level: L.Level) -> String:
  match sectors:
    case []:
      ""
    case +sector <> rest:
      " sector " ++ U32.show(sector) ++ " " ++ F.Fixed.show(L.Level.floor(level, sector)) ++ " "
        ++ F.Fixed.show(L.Level.ceil(level, sector)) ++ heights(rest, level)

# How many thinkers are not mobjs': the lights, movers and buttons.
def specials(ts: List<&2, S.Thinker>) -> U32:
  match ts:
    case []:
      0
    case S.Mobj{id} <> rest:
      specials(rest)
    case _ <> rest:
      (1 + specials(rest) : U32)

# A run of one command in a demo's units, then the clock, the player,
# the thinkers running that are no mobj's, and some sectors' floors and
# ceilings.
def watch(tag: String, sectors: List<&2, U32>, +s: S.State) -> String:
  line(tag ++ " tic " ++ U32.show(S.State.clock(s)), s) ++ " thinkers "
    ++ U32.show(specials(S.State.thinkers(s))) ++ heights(sectors, S.State.level(s))

def run(tag: String, n: Nat, cmd: K.Cmd, sectors: List<&2, U32>, s: S.State) -> IO(S.State):
  +r = ran(n, cmd, s)
  +q = Run.state(r)
  do IO<S.State>:
    IO.print(Run.log(r) ++ watch(tag, sectors, q))
    return q

# The heads-up line: the message it shows, its string from d_englsh.h,
# and the tics it has left there.
def said(+s: S.State) -> String:
  +n = S.State.message(s)
  " message " ++ U32.show(n) ++ " \"" ++ Msg.Message.text(n) ++ "\" tics " ++ U32.show(S.State.msgtics(s))

def idle() -> K.Cmd:
  K.Cmd.idle()

def use() -> K.Cmd:
  K.Cmd.demo(0, 0, 0, 2)

def forward() -> K.Cmd:
  K.Cmd.demo(25, 0, 0, 0)

def fire() -> K.Cmd:
  K.Cmd.demo(0, 0, 0, 1)

def at(+level: L.Level, x: U32, y: U32, degrees: U32) -> S.State:
  Tic.State.at(level, L.Start{F.Fixed.of_map(x), F.Fixed.of_map(y), A.Angle.of_thing(degrees)})

# The map with the middle textures of its two switches' sides, 1166 (the
# special 23 switch) and 615 (the exit), numbered 1, a switch whose
# partner is 2, as the graphics' loader would number them: this test
# loads no graphics, and a switch clicks only when its texture has a
# partner.
def switched(level: L.Level) -> L.Level:
  L.Level.textured(level, V.Vec.set(V.Vec.set(V.Vec.of_list(List.replicate(U32, U32.to_nat(8192), 0), 8192),
    (1166 * 3 + 2 : U32), 1), (615 * 3 + 2 : U32), 1), V.Vec.of_list([0, 2, 1], 3))

# Freedoom's special 23 switch, line 753: its tag's three blocks lower
# at 1 a tic to the lowest floor around each, and it works once.
def floors(+level: L.Level) -> IO(Unit):
  do IO<Unit>:
    f0 : S.State <- run("switch walk", 30n, forward(), [76, 126, 129], at(level, 2064, 65276, 90))
    f1 : S.State <- run("use", 1n, use(), [76, 126, 129], f0)
    f2 : S.State <- run("-", 119n, idle(), [76, 126, 129], f1)
    f3 : S.State <- run("-", 1n, idle(), [76, 126, 129], f2)
    f4 : S.State <- run("-", 7n, idle(), [76, 126, 129], f3)
    f5 : S.State <- run("-", 1n, idle(), [76, 126, 129], f4)
    f6 : S.State <- run("-", 7n, idle(), [76, 126, 129], f5)
    f7 : S.State <- run("-", 1n, idle(), [76, 126, 129], f6)
    f8 : S.State <- run("use", 1n, use(), [76, 126, 129], f7)
    IO.print(drawn(f8))
    IO.print("-")

# Freedoom's special 2 lines along x 2032: crossing one opens sector 145
# for good, and crossing it again starts nothing. The split case starts
# at x 2025 with 20 units of momentum. P_XYMovement crosses the line in
# its first 10-unit half, so S_StartSound listens at x 2035, not the
# final x 2045. tools/sound.nu over vanilla's tables and the WAD gives
# volume 45 and separation 156 there; the final place would give 157.
def fast(+p: S.Player) -> S.Player:
  S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt} = p
  S.Player{x, y, z, angle, F.Fixed.of_map(20), 0, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed,
    inv, psprites, hurt}

def split.crossed(+level: L.Level) -> IO(Unit):
  +s = at(level, 2025, 65086, 0)
  +q = Tic.Sim.tic(idle(), S.State.player.put(s, fast(S.State.player(s))))
  IO.print(events(S.State.sounds(q), S.State.clock(q)) ++ line("split crossing", q))

def crossed(+level: L.Level) -> IO(Unit):
  do IO<Unit>:
    x0 : S.State <- run("trigger walk", 16n, forward(), [145], at(level, 1960, 65086, 0))
    x1 : S.State <- run("over", 1n, forward(), [145], x0)
    x2 : S.State <- run("-", 61n, idle(), [145], x1)
    x3 : S.State <- run("-", 1n, idle(), [145], x2)
    x4 : S.State <- run("back", 40n, K.Cmd.demo(4294967271, 0, 0, 0), [145], x3)
    IO.print(drawn(x4))
    split.crossed(level)
    IO.print("-")

# Freedoom's first lift, sector 98: called by the walk-over line on its
# west edge and ridden down and up, then called by its switch from the
# pit east of it, used again while it runs, and again once it is back.
def lift(+level: L.Level) -> IO(Unit):
  do IO<Unit>:
    l0 : S.State <- run("lift run", 35n, K.Cmd.demo(50, 0, 0, 0), [98], Tic.State.start(level))
    l1 : S.State <- run("-", 4n, idle(), [98], l0)
    l2 : S.State <- run("over", 1n, idle(), [98], l1)
    l3 : S.State <- run("-", 33n, idle(), [98], l2)
    l4 : S.State <- run("-", 1n, idle(), [98], l3)
    l5 : S.State <- run("-", 105n, idle(), [98], l4)
    l6 : S.State <- run("-", 1n, idle(), [98], l5)
    l7 : S.State <- run("-", 33n, idle(), [98], l6)
    l8 : S.State <- run("-", 1n, idle(), [98], l7)
    s0 : S.State <- run("lift switch walk", 10n, forward(), [98], at(level, 240, 256, 180))
    s1 : S.State <- run("use", 1n, use(), [98], s0)
    s2 : S.State <- run("-", 1n, idle(), [98], s1)
    s3 : S.State <- run("use", 1n, use(), [98], s2)
    s4 : S.State <- run("-", 171n, idle(), [98], s3)
    s5 : S.State <- run("-", 1n, idle(), [98], s4)
    s6 : S.State <- run("use", 1n, use(), [98], s5)
    IO.print(drawn(s6))
    IO.print("-")

# A run, then the blue key door's heights, whether the blue card of
# record id is there, how many things are, and the cards and pickup
# flash.
def keyed(tag: String, +id: U32, n: Nat, cmd: K.Cmd, s: S.State) -> IO(S.State):
  +r = ran(n, cmd, s)
  +q = Run.state(r)
  +inv = S.Player.inv(S.State.player(q))
  do IO<S.State>:
    IO.print(Run.log(r) ++ watch(tag, [71], q) ++ " key " ++ Bool.show(Maybe.is_some(&2, H.Thing, H.Things.get(S.State.things(q), id)))
      ++ " things " ++ Nat.show(List.length(&2, H.Thing, H.Things.list(S.State.things(q)))) ++ " cards "
      ++ U32.show(I.Inventory.cards(inv)) ++ " flash " ++ U32.show(I.Inventory.bonus(inv)) ++ said(q))
    return q

# The state with the player holding an inventory.
def holding(inv: I.Inventory, s: S.State) -> S.State:
  S.State{p, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn, totalsecret} = s
  S.State{S.Player.holding(p, inv), level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn, totalsecret}

# The blue key, record 87, taken strafing past it, the oracle's script:
# 20 idle tics, a turn to 157.5, strafing left. Then the blue key door,
# sector 71, used from the south by a player holding the blue skull
# alone.
def blue(+level: L.Level) -> IO(Unit):
  do IO<Unit>:
    k0 : S.State <- keyed("key turn", 87, 1n, K.Cmd.demo(0, 0, 4294967280, 0),
      Tic.Sim.replay(List.replicate(K.Cmd, 20n, idle()), at(level, 2246, 592, 180)))
    k1 : S.State <- keyed("strafe", 87, 12n, K.Cmd.demo(0, 4294967272, 0, 0), k0)
    k2 : S.State <- keyed("-", 87, 1n, K.Cmd.demo(0, 4294967272, 0, 0), k1)
    k3 : S.State <- keyed("-", 87, 10n, K.Cmd.demo(0, 4294967272, 0, 0), k2)
    b0 : S.State <- keyed("blue walk with the skull", 87, 30n, forward(),
      holding(I.Inventory.card(8, Msg.Message.none(), I.Inventory.start()), at(level, 832, 1400, 90)))
    b1 : S.State <- keyed("use", 87, 1n, use(), b0)
    b2 : S.State <- keyed("-", 87, 10n, idle(), b1)
    b3 : S.State <- keyed("-", 87, 51n, idle(), b2)
    IO.print(drawn(b3))
    IO.print("-")

# A run, then whether the level has ended and the exit line's special.
def ending(tag: String, n: Nat, cmd: K.Cmd, s: S.State) -> IO(S.State):
  +r = ran(n, cmd, s)
  +q = Run.state(r)
  do IO<S.State>:
    IO.print(Run.log(r) ++ watch(tag, [], q) ++ " ended " ++ S.Sim.Exit.show(S.State.ended(q)) ++ " special "
      ++ U32.show(L.Level.special(S.State.level(q), 407)))
    return q

def exits(+level: L.Level) -> IO(Unit):
  do IO<Unit>:
    x0 : S.State <- ending("exit first tic use", 1n, use(), at(level, 65184, 1296, 180))
    x1 : S.State <- ending("-", 19n, idle(), x0)
    x2 : S.State <- ending("use", 1n, use(), x1)
    x3 : S.State <- ending("walk held use", 10n, K.Cmd.demo(25, 0, 0, 2), x2)
    IO.print(drawn(x3))
    IO.print("-")

def lit(sectors: List<&2, U32>, +level: L.Level) -> String:
  match sectors:
    case []:
      ""
    case +sector <> rest:
      " sector " ++ U32.show(sector) ++ " " ++ U32.show(L.Level.sector.light(level, sector)) ++ lit(rest, level)

# The lights of four sectors after each run of idle tics.
def lights(gaps: List<&2, Nat>, +s: S.State) -> IO(Unit):
  match gaps:
    case []:
      IO.print("end")
    case n <> rest:
      do IO<Unit>:
        IO.print("lights tic " ++ U32.show(S.State.clock(s)) ++ lit([32, 33, 48, 90], S.State.level(s)))
        lights(rest, Tic.Sim.replay(List.replicate(K.Cmd, n, idle()), s))

# The state row and tics of a thing, none for one gone.
def phase(m: Maybe<&2, H.Thing>) -> String:
  match m:
    case None{}:
      ""
    case Some{H.Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics, momz, hurt}}:
      " " ++ U32.show(id) ++ ":" ++ U32.show(state) ++ "/" ++ U32.show(tics)

def phases(ids: List<&2, U32>, +things: H.Things) -> String:
  match ids:
    case []:
      ""
    case +id <> rest:
      phase(H.Things.get(things, id)) ++ phases(rest, things)

# Seven things' states after each run of idle tics.
def states(gaps: List<&2, Nat>, +s: S.State) -> IO(Unit):
  match gaps:
    case []:
      IO.pure(Unit, Unit{})
    case n <> rest:
      do IO<Unit>:
        IO.print("states tic " ++ U32.show(S.State.clock(s)) ++ phases([2, 6, 87, 24, 121, 144, 172],
          S.State.things(s)))
        states(rest, Tic.Sim.replay(List.replicate(K.Cmd, n, idle()), s))

# A use while the door closes sends it back up; one while it waits
# starts it down.
def turned(+closing: S.State) -> IO(Unit):
  do IO<Unit>:
    r1 : S.State <- run("closing -", 10n, idle(), [10], closing)
    r2 : S.State <- run("use", 1n, use(), [10], r1)
    r3 : S.State <- run("-", 10n, idle(), [10], r2)
    r4 : S.State <- run("-", 4n, idle(), [10], r3)
    r5 : S.State <- run("use", 1n, use(), [10], r4)
    IO.print(drawn(r5))
    IO.print("-")

def closes(+open: S.State) -> IO(S.State):
  do IO<S.State>:
    d4 : S.State <- run("-", 1n, idle(), [10], open)
    d5 : S.State <- run("-", 150n, idle(), [10], d4)
    run("-", 1n, idle(), [10], d5)

def shuts(+closing: S.State) -> IO(Unit):
  do IO<Unit>:
    d7 : S.State <- run("-", 61n, idle(), [10], closing)
    d8 : S.State <- run("-", 1n, idle(), [10], d7)
    turned(closing)

def opens(+open: S.State) -> IO(Unit):
  do IO<Unit>:
    closing : S.State <- closes(open)
    shuts(closing)
    w1 : S.State <- run("through walk", 40n, forward(), [10], open)
    c1 : S.State <- run("doorway walk", 6n, forward(), [10], open)
    c2 : S.State <- run("-", 179n, idle(), [10], c1)
    c3 : S.State <- run("-", 1n, idle(), [10], c2)
    c4 : S.State <- run("-", 1n, idle(), [10], c3)
    c5 : S.State <- run("-", 34n, idle(), [10], c4)
    IO.print(drawn(c5))
    IO.print("-")

# A state with a fresh player at rest some way south of the first
# door's sound origin, 832, 528, facing an angle, its mobj relinked
# where it now stands, as P_UnsetThingPosition and P_SetThingPosition
# relink one that is put somewhere else.
def south(d: U32, degrees: U32, s: S.State) -> S.State:
  S.State{+p, +level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn, totalsecret} = s
  +x = F.Fixed.of_map(832)
  +y = F.Fixed.of_map((528 - d : U32))
  S.State{S.Player.at(level, L.Start{x, y, A.Angle.of_thing(degrees)}, I.Inventory.start()), level,
    S.Sim.relink(level, things, S.Player.x(p), S.Player.y(p), x, y), sidetex, thinkers, rnd, clock, ended, usedown,
    sounds, mrnd, reborn, totalsecret}

def listen(tag: String, d: U32, degrees: U32, open: S.State) -> IO(Unit):
  do IO<Unit>:
    q : S.State <- run(tag, 151n, idle(), [10], south(d, degrees, open))
    IO.print(drawn(q))

# Where a player stands still through the open door's close on tic 253:
# hard left, hard right, behind, at the close distance and a unit past
# it, at the last audible unit, a unit on, where the volume rounds to
# nothing, and past the clipping distance. The 200/201-unit combat
# sequences match a Chocolate Doom replay with the same player reset
# at tic102; its same-species missile block prevents an extra imp pain.
def placements(+open: S.State) -> IO(Unit):
  do IO<Unit>:
    listen("door on the left", 400, 0, open)
    listen("door on the right", 400, 180, open)
    listen("door behind", 400, 270, open)
    listen("door 200 ahead", 200, 90, open)
    listen("door 201 ahead", 201, 90, open)
    listen("door 1184 ahead", 1184, 90, open)
    listen("door 1185 ahead", 1185, 90, open)
    listen("door 1201 ahead", 1201, 90, open)
    IO.print("-")

# The first door, sector 10, from the pit south of it, at 872 where the
# zombieman of record 176 does not reach: used, held open, shut; turned
# twice; use held down all the while; walked through; listened to from
# eight places.
def used(+before: S.State) -> IO(Unit):
  do IO<Unit>:
    d1 : S.State <- run("use", 1n, use(), [10], before)
    d2 : S.State <- run("-", 20n, idle(), [10], d1)
    d3 : S.State <- run("-", 41n, idle(), [10], d2)
    opens(d3)
    h1 : S.State <- run("held use", 100n, use(), [10], before)
    h2 : S.State <- run("use", 200n, use(), [10], h1)
    IO.print(drawn(h2))
    IO.print("-")
    placements(Tic.Sim.replay(use() <> List.replicate(K.Cmd, 61n, idle()), before))

# A thing's type, height, floor and ceiling, state and tics, none for
# one gone.
def bounded(m: Maybe<&2, H.Thing>) -> String:
  match m:
    case None{}:
      ""
    case Some{H.Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics, momz, hurt}}:
      " thing " ++ U32.show(id) ++ " type " ++ U32.show(kind) ++ " z " ++ F.Fixed.show(z) ++ " floor "
        ++ F.Fixed.show(floorz) ++ " ceiling " ++ F.Fixed.show(ceilz) ++ " state " ++ U32.show(state) ++ " tics "
        ++ U32.show(tics)

# A run, then some sectors' floors and ceilings and the thing named id.
def carry(tag: String, n: Nat, cmd: K.Cmd, sectors: List<&2, U32>, +id: U32, s: S.State) -> IO(S.State):
  +r = ran(n, cmd, s)
  +q = Run.state(r)
  do IO<S.State>:
    IO.print(Run.log(r) ++ watch(tag, sectors, q) ++ bounded(H.Things.get(S.State.things(q), id)))
    return q

def patch.byte.put(+at: U32, b: U32, p: Array<U32> & U32) -> Array<U32>:
  (a, +word) = p
  +shift = U32.to_nat(((at .&. 3 : U32) * 8 : U32))
  Array.set(U32, a, (at >> 2n : U32), ((word - (word .&. (255 << shift))) .|. (b << shift) : U32))

def patch.byte(a: Array<U32>, +at: U32, b: U32) -> Array<U32>:
  patch.byte.put(at, b, a[(at >> 2n : U32)])

def patch.word(a: Array<U32>, +at: U32, +w: U32) -> Array<U32>:
  patch.byte(patch.byte(a, at, (w .&. 255 : U32)), (at + 1 : U32), (w >> 8n : U32))

# THINGS record i made a thing of a type at (x, y) in map units, on
# every skill, in the WAD's bytes, whose E1M1 THINGS lump starts at pos.
def patch.record(a: Array<U32>, +pos: U32, i: U32, x: U32, y: U32, kind: U32) -> Array<U32>:
  +at = (pos + i * 10 : U32)
  patch.word(patch.word(patch.word(patch.word(patch.word(a, at, x), (at + 2 : U32), y), (at + 4 : U32), 0),
    (at + 6 : U32), kind), (at + 8 : U32), 7)

def patch.at(a: Array<U32>, +lumps: List<&2, W.Wad.Lump>, lump: U32 & U32) ->
  Result<&1, &1, U32 & String, Array<U32> & L.Level>:
  (+pos, size) = lump
  L.Level.load(1, 1, (patch.record(patch.record(patch.record(a, pos, 3, 96, 216, 48), pos, 35, 800, 528, 2035), pos, 82,
    824, 1352, 5), lumps))

# E1M1 with records 3, 35 and 82, a demon and two imps, made a tech
# column on the first lift, a barrel in the first door and a second blue
# card in the hall south of the blue key door, as tools/oracle.nu's
# --things "3,48,96,216 35,2035,800,528 82,5,824,1352" has them: each
# spawns as the map's other things do, drawing its random numbers in
# record order.
def patched(p: Array<U32> & List<&2, W.Wad.Lump>) -> Result<&1, &1, U32 & String, Array<U32> & L.Level>:
  (a, +lumps) = p
  patch.at(a, lumps, W.Wad.find(Result.default(&1, &1, U32 & String, List<&2, W.Wad.Lump>,
    L.Level.map(1, 1, lumps), []), "THINGS"))

# The solid things, after 20 idle tics as the oracle's scripts start.
# Walking south at 25 from 1712 under the tech column at -192, 1600,
# record 59, radius 16: tic 37 leaves the player 35.78 north of it, and
# tic 38's step of 6.92, the free walk's, would bring it to 28.86, under
# the 32 of the two radii, so the player stays, tic after tic. From 432
# over the dead former human at 128, 384, record 171, which is not
# solid, the player walks the free walk the column walk began with,
# 432 less its distance, over the corpse's box by tic 30 and on. A tech
# column, radius 16, at 96, 216 on the lift, sector 98, as record 3 of
# the patched map: the lift's switch from the pit starts it down 4 a
# tic, and the column's height, floor and ceiling are the lift's floor
# and ceiling on every tic, its name, type, lasting state (row 58, S_ELEC)
# and tics kept, down to -124 and back to 12. A barrel, radius 10, height 42, at 800, 528 inside the first
# door, sector 10, as record 35, where it does not fit under the
# shut door: the door opens over it as on nothing, and when it closes,
# the barrel under its ceiling, the tic it would leave 40 of the
# barrel's 42 is undone at -86, tic 295, and the door goes back up.
# Meanwhile the barrel runs S_BAR1 (row 10) and S_BAR2 (row 11), 6 tics
# each, from the 3 its spawn drew: the next row on tic 3 and every 6
# tics after. A monster stops the player as those solids do: walking
# north at 25 from 832, 384, under the deaf zombieman of record 176 at
# 816, 448, the player stops 36.34 south of it, since its radius of 20
# and the player's 16 leave 36 between their centres, and no later tic
# moves it.
def solids(+level: L.Level, +placed: L.Level) -> IO(Unit):
  do IO<Unit>:
    c0 : S.State <- run("column walk", 17n, forward(), [],
      Tic.Sim.replay(List.replicate(K.Cmd, 20n, idle()), at(level, 65344, 1712, 270)))
    c1 : S.State <- run("-", 1n, forward(), [], c0)
    c2 : S.State <- run("-", 10n, forward(), [], c1)
    k0 : S.State <- run("corpse walk", 10n, forward(), [],
      Tic.Sim.replay(List.replicate(K.Cmd, 20n, idle()), at(level, 128, 432, 270)))
    k1 : S.State <- run("-", 8n, forward(), [], k0)
    z0 : S.State <- run("zombieman walk", 24n, forward(), [],
      Tic.Sim.replay(List.replicate(K.Cmd, 20n, idle()), at(level, 832, 384, 90)))
    z1 : S.State <- run("-", 20n, forward(), [], z0)
    l0 : S.State <- carry("column lift switch walk", 10n, forward(), [98], 3,
      at(placed, 240, 256, 180))
    l1 : S.State <- carry("use", 1n, use(), [98], 3, l0)
    l2 : S.State <- carry("-", 1n, idle(), [98], 3, l1)
    l3 : S.State <- carry("-", 32n, idle(), [98], 3, l2)
    l4 : S.State <- carry("-", 1n, idle(), [98], 3, l3)
    l5 : S.State <- carry("-", 105n, idle(), [98], 3, l4)
    l6 : S.State <- carry("-", 34n, idle(), [98], 3, l5)
    b0 : S.State <- carry("barrel door walk", 40n, forward(), [10], 35,
      at(placed, 872, 384, 90))
    b1 : S.State <- carry("use", 1n, use(), [10], 35, b0)
    b2 : S.State <- carry("-", 61n, idle(), [10], 35, b1)
    b3 : S.State <- carry("-", 192n, idle(), [10], 35, b2)
    b4 : S.State <- carry("-", 1n, idle(), [10], 35, b3)
    b5 : S.State <- carry("-", 1n, idle(), [10], 35, b4)
    b6 : S.State <- carry("-", 1n, idle(), [10], 35, b5)
    b7 : S.State <- carry("-", 4n, idle(), [10], 35, b6)
    IO.print(drawn(b7))
    IO.print("-")

# The blue key door, sector 71, on the patched map: from 880, 1440
# facing north, 20 idle tics and a use the door refuses, then 20 idle
# tics; a turn to 247.5 and a walk that takes record 82's card on tic
# 56, 34.43 east and 35.87 north of it, inside the reach of 36 (tic 55
# leaves 36.81 east), 49.7 away, while the bob holds the eye 36 over the
# floor so the card stays in view; 20 idle tics, a turn north, 19 tics
# forward and a use on tic 97 from 1423.47, 56.53 short of the door's
# line and inside the use range of 64. The door opens at 2 a tic from
# -128 on that tic, -116 at 102, -86 at 117, and stops at its top, 4
# under the ceilings of 0 beside it, on tic 158.
def locked(+placed: L.Level) -> IO(Unit):
  do IO<Unit>:
    k0 : S.State <- keyed("blue door refused", 82, 1n, use(),
      Tic.Sim.replay(List.replicate(K.Cmd, 20n, idle()), at(placed, 880, 1440, 90)))
    k1 : S.State <- keyed("-", 82, 20n, idle(), k0)
    k2 : S.State <- keyed("turn", 82, 1n, K.Cmd.demo(0, 0, 112, 0), k1)
    k3 : S.State <- keyed("walk", 82, 13n, forward(), k2)
    k4 : S.State <- keyed("-", 82, 1n, forward(), k3)
    k5 : S.State <- keyed("-", 82, 20n, idle(), k4)
    k6 : S.State <- keyed("turn", 82, 1n, K.Cmd.demo(0, 0, 4294967184, 0), k5)
    k7 : S.State <- keyed("walk", 82, 19n, forward(), k6)
    k8 : S.State <- keyed("use", 82, 1n, use(), k7)
    k9 : S.State <- keyed("-", 82, 5n, idle(), k8)
    k10 : S.State <- keyed("-", 82, 15n, idle(), k9)
    k11 : S.State <- keyed("-", 82, 41n, idle(), k10)
    k12 : S.State <- keyed("-", 82, 1n, idle(), k11)
    k13 : S.State <- keyed("-", 82, 36n, idle(), k12)
    k14 : S.State <- keyed("-", 82, 1n, idle(), k13)
    IO.print(drawn(k14))
    IO.print("-")

# The patched map's cases.
def patched.cases(+level: L.Level, p: Array<U32> & L.Level) -> IO(Unit):
  (a, +placed) = p
  do IO<Unit>:
    solids(level, placed)
    locked(placed)

def door(+level: L.Level) -> IO(Unit):
  do IO<Unit>:
    d0 : S.State <- run("door walk", 40n, forward(), [10], at(level, 872, 384, 90))
    used(d0)
    floors(switched(level))
    crossed(level)
    lift(level)
    blue(level)
    exits(switched(level))
    states([1n, 1n, 1n, 1n, 1n, 8n, 10n, 12n, 1n, 0n], Tic.State.start(level))
    lights([1n, 7n, 1n, 6n, 20n, 1n, 5n, 24n, 5n, 1n, 5n, 1n, 3n, 1n, 1n, 1n, 8n, 44n, 7n, 2n, 0n],
      Tic.State.start(level))

def count(things: List<&2, H.Thing>, +kind: U32) -> U32:
  match things:
    case []:
      0
    case H.Thing{id, k, x, y, z, floorz, ceilz, angle, sector, state, tics, momz, hurt} <> rest:
      (Bool.to_u32(U32.is_eq(k, kind)) + count(rest, kind) : U32)

# How many things of each type Bendoom defines.
def kinds(defs: List<&2, H.Thing.Def>, +things: List<&2, H.Thing>) -> String:
  match defs:
    case []:
      ""
    case H.Def{+kind, state, radius, height, flags} <> rest:
      " " ++ U32.show(kind) ++ ":" ++ U32.show(count(things, kind)) ++ kinds(rest, things)

def ids(things: List<&2, H.Thing>) -> String:
  match things:
    case []:
      ""
    case H.Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics, momz, hurt} <> rest:
      " " ++ U32.show(id) ++ ids(rest)

def described(d: Maybe<&2, H.Thing.Def>) -> String:
  match d:
    case None{}:
      " undefined"
    case Some{H.Def{kind, state, radius, height, flags}}:
      " radius " ++ U32.show(radius) ++ " height " ++ U32.show(height) ++ " flags " ++ U32.show(flags)

# A thing's line, empty for one gone.
def thing(m: Maybe<&2, H.Thing>) -> String:
  match m:
    case None{}:
      ""
    case Some{H.Thing{id, +kind, x, y, z, floorz, ceilz, angle, sector, state, tics, momz, hurt}}:
      "thing " ++ U32.show(id) ++ " type " ++ U32.show(kind) ++ " at " ++ F.Fixed.show(x) ++ " " ++ F.Fixed.show(y)
        ++ " z " ++ F.Fixed.show(z) ++ " angle " ++ A.Angle.show(angle) ++ " sector " ++ U32.show(sector)
        ++ " state " ++ U32.show(state) ++ " tics " ++ U32.show(tics) ++ described(H.Thing.def(kind))

def ambush(m: Maybe<&2, H.Thing>) -> Bool:
  match m:
    case None{}:
      False{}
    case Some{th}:
      H.Thing.ambush(th)

def things(chosen: List<&2, U32>, +s: S.State) -> IO(Unit):
  match chosen:
    case []:
      IO.pure(Unit, Unit{})
    case +id <> rest:
      do IO<Unit>:
        IO.print(thing(H.Things.get(S.State.things(s), id)) ++ " ambush "
          ++ Bool.show(ambush(H.Things.get(S.State.things(s), id))))
        things(rest, s)

# What the blockmap links hold: how many links, how many of solid
# things, and how many disagree with the population.
type Links is Data:
  Links{links: U32, solid: U32, wrong: U32}

def solid.def(d: H.Thing.Def) -> Bool:
  H.Def{k, state, radius, height, +flags} = d
  Bool.not(U32.is_zero((flags .&. 2 : U32)))

def solid(+kind: U32) -> Bool:
  solid.def(H.Thing.info(kind))

def same(a: L.Level.Cell, b: L.Level.Cell) -> Bool:
  L.Cell{ax, ay} = a
  L.Cell{bx, by} = b
  Bool.and(U32.is_eq(ax, bx), U32.is_eq(ay, by))

# Whether a cell's link agrees with the population: its thing alive,
# with its centre in cell c.
def agrees(m: Maybe<&2, H.Thing>, +bm: L.Level.Blockmap, c: L.Level.Cell) -> Bool:
  match m:
    case None{}:
      False{}
    case Some{H.Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics, momz, hurt}}:
      same(L.Level.cell_of(bm, x, y), c)

def solid.some(m: Maybe<&2, H.Thing>) -> Bool:
  match m:
    case None{}:
      False{}
    case Some{H.Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics, momz, hurt}}:
      solid(kind)

# A cell's link counted, the player's mobj's left out.
def links.count(you: Bool, +m: Maybe<&2, H.Thing>, bm: L.Level.Blockmap, c: L.Level.Cell, t: Links) -> Links:
  match you:
    case True{}:
      t
    case False{}:
      Links{n, s, w} = t
      Links{(n + 1 : U32), (s + Bool.to_u32(solid.some(m)) : U32), (w + Bool.to_u32(Bool.not(agrees(m, bm, c))) : U32)}

def links.cell(ids: List<&2, U32>, +bm: L.Level.Blockmap, +ts: H.Things, +c: L.Level.Cell, t: Links) -> Links:
  match ids:
    case []:
      t
    case +id <> rest:
      links.cell(rest, bm, ts, c, links.count(U32.is_eq(id, H.Things.you(ts)), H.Things.get(ts, id), bm, c, t))

def links.cells(cells: List<&2, L.Level.Cell>, +bm: L.Level.Blockmap, +ts: H.Things, t: Links) -> Links:
  match cells:
    case []:
      t
    case +c <> rest:
      links.cells(rest, bm, ts, links.cell(H.Things.linked(ts, bm, [c]), bm, ts, c, t))

# How many of the things are not in the list of the cell their centre
# is in.
def unlinked(things: List<&2, H.Thing>, +bm: L.Level.Blockmap, +ts: H.Things) -> U32:
  match things:
    case []:
      0
    case H.Thing{+id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics, momz, hurt} <> rest:
      (Bool.to_u32(Bool.not(S.Sim.member(H.Things.linked(ts, bm, [L.Level.cell_of(bm, x, y)]), id)))
        + unlinked(rest, bm, ts) : U32)

def solids.count(things: List<&2, H.Thing>) -> U32:
  match things:
    case []:
      0
    case H.Thing{id, +kind, x, y, z, floorz, ceilz, angle, sector, state, tics, momz, hurt} <> rest:
      (Bool.to_u32(solid(kind)) + solids.count(rest) : U32)

def links.show(t: Links, +things: List<&2, H.Thing>, bm: L.Level.Blockmap, ts: H.Things) -> String:
  Links{n, s, w} = t
  "links " ++ U32.show(n) ++ " of " ++ Nat.show(List.length(&2, H.Thing, things)) ++ " things, solid "
    ++ U32.show(s) ++ " of " ++ U32.show(solids.count(things)) ++ ", wrong " ++ U32.show(w) ++ ", unlinked "
    ++ U32.show(unlinked(things, bm, ts))

# The blockmap links of a state's population, cell by cell over the
# whole blockmap: as many links as things, as many of them solid as
# solid things, none that disagrees with its thing, and no thing missing
# from its centre's cell mean each thing is linked once, in the cell of
# its centre.
def links.in(+bm: L.Level.Blockmap, +s: S.State) -> String:
  L.Blockmap{words, ox, oy, +cols, +rows} = bm
  links.show(links.cells(S.Sim.cells(U32.to_nat(cols), U32.to_nat(rows), 0, 0), bm, S.State.things(s),
    Links{0, 0, 0}), H.Things.list(S.State.things(s)), bm, S.State.things(s))

def links(+s: S.State) -> String:
  links.in(L.Level.blockmap_of(S.State.level(s)), s)

def free(+s: S.State) -> IO(S.State):
  +p = S.State.player(s)
  +spawned = H.Things.list(S.State.things(s))
  do IO<S.State>:
    IO.print("free at start " ++ Bool.show(S.Sim.free(S.State.level(s), S.Player.x(p), S.Player.y(p))))
    IO.print(I.Inventory.show(S.Player.inv(p)))
    IO.print("things at start " ++ Nat.show(List.length(&2, H.Thing, spawned)) ++ " random "
      ++ U32.show(S.State.rnd(s)))
    IO.print("by type" ++ kinds(H.Thing.defs(), spawned))
    IO.print("first" ++ ids(List.take(&2, H.Thing, spawned, 12n)))
    IO.print(links(s))
    things([2, 6, 29, 87, 245, 291, 176, 240, 81, 3], s)
    return s

# A run, then the tic, the player's place, the inventory, how many
# things are left and the names of those taken since the case's first
# state.
def picked(tag: String, n: Nat, cmd: K.Cmd, +first: S.State, s: S.State) -> IO(S.State):
  +r = ran(n, cmd, s)
  +q = Run.state(r)
  do IO<S.State>:
    IO.print(Run.log(r) ++ line(tag ++ " tic " ++ U32.show(S.State.clock(q)), q))
    IO.print("  " ++ I.Inventory.show(S.Player.inv(S.State.player(q)))
      ++ H.Things.tally(H.Things.list(S.State.things(first)), S.State.things(q)) ++ said(q))
    return q

# An inventory with other health, armour points and type, and ammo in
# ammotype_t order.
def stocked(health: U32, armour: U32, armourtype: U32, ammo: List<&2, U32>, inv: I.Inventory) -> I.Inventory:
  I.Inventory{h, a, t, cards, rounds, caps, backpack, weapons, powers, items, bonus, line, kills, secrets} = inv
  I.Inventory{health, armour, armourtype, cards, V.Vec.of_list(ammo, 4), caps, backpack, weapons, powers, items,
    bonus, line, kills, secrets}

# Walking forward from a place for some tics, then one more: the tic
# before contact and the tic of it.
def walked(tag: String, n: Nat, +s: S.State) -> IO(S.State):
  do IO<S.State>:
    a : S.State <- picked(tag, n, forward(), s, s)
    b : S.State <- picked("-", 1n, forward(), s, a)
    finished(b)

# Loose rounds: a clip walked into from the east, and Freedoom's row of
# three shells walked along from the west, the rocket from the east,
# with room and at the cap.
def loose(+level: L.Level) -> IO(Unit):
  do IO<Unit>:
    c : S.State <- walked("clip walk", 9n, at(level, 672, 992, 180))
    h : S.State <- walked("shells walk", 8n, at(level, 1060, 65312, 0))
    h2 : S.State <- picked("-", 17n, forward(), at(level, 1060, 65312, 0), h)
    f : S.State <- walked("shells walk at the cap", 8n,
      holding(stocked(100, 0, 0, [50, 50, 0, 0], I.Inventory.start()), at(level, 1060, 65312, 0)))
    f2 : S.State <- picked("-", 17n, forward(), at(level, 1060, 65312, 0), f)
    r : S.State <- walked("rocket walk", 8n, at(level, 700, 64536, 180))
    r2 : S.State <- walked("rocket walk at the cap", 8n,
      holding(stocked(100, 0, 0, [50, 0, 0, 50], I.Inventory.start()), at(level, 700, 64536, 180)))
    IO.print("-")

# The shell box behind the closet door west of the clips, with room,
# one clip short of the cap, and at it: an idle tic, since the player
# starts with use held, the use, the door rising, the walk.
def box(tag: String, +s: S.State) -> IO(Unit):
  +opened = Tic.Sim.replay(List.concat(&2, K.Cmd, [[idle(), use()], List.replicate(K.Cmd, 30n, idle())]), s)
  do IO<Unit>:
    b : S.State <- walked(tag, 19n, opened)
    IO.print("-")

# The chainsaw on its step, strafed past on the key's script: not owned,
# then owned.
def chainsaw(tag: String, inv: I.Inventory, +level: L.Level) -> IO(S.State):
  +s = holding(inv, at(level, 3158, 2176, 180))
  do IO<S.State>:
    a : S.State <- picked(tag, 12n, K.Cmd.demo(0, 4294967272, 0, 0), s,
      Tic.Sim.replay(List.append(&2, K.Cmd, List.replicate(K.Cmd, 20n, idle()),
        [K.Cmd.demo(0, 0, 4294967280, 0)]), s))
    b : S.State <- picked("-", 1n, K.Cmd.demo(0, 4294967272, 0, 0), s, a)
    finished(b)

# The ammo and the chainsaw, then health, armour and berserk, a pickup
# of each type Freedoom's E1M1 spawns but the key, each walked at alone:
# taken when it improves the inventory, left when it cannot.
def pickups(+level: L.Level) -> IO(Unit):
  do IO<Unit>:
    loose(level)
    box("shell box walk", at(level, 600, 712, 180))
    box("shell box walk short of the cap",
      holding(stocked(100, 0, 0, [50, 45, 0, 0], I.Inventory.start()), at(level, 600, 712, 180)))
    box("shell box walk at the cap",
      holding(stocked(100, 0, 0, [50, 50, 0, 0], I.Inventory.start()), at(level, 600, 712, 180)))
    w : S.State <- chainsaw("chainsaw strafe", I.Inventory.start(), level)
    w2 : S.State <- chainsaw("owned chainsaw strafe", S.Player.inv(S.State.player(w)), level)
    h0 : S.State <- walked("health bonus", 11n, at(level, 432, 256, 0))
    h1 : S.State <- walked("health bonus at 200", 11n,
      holding(stocked(200, 0, 0, [50, 0, 0, 0], I.Inventory.start()), at(level, 432, 256, 0)))
    s0 : S.State <- walked("stimpack at 100", 11n, at(level, 4294967264, 400, 90))
    s1 : S.State <- picked("-", 10n, forward(), at(level, 4294967264, 400, 90), s0)
    s2 : S.State <- walked("stimpack at 60", 11n,
      holding(stocked(60, 0, 0, [50, 0, 0, 0], I.Inventory.start()), at(level, 4294967264, 400, 90)))
    m0 : S.State <- walked("medikit at 100", 11n, at(level, 32, 400, 90))
    m1 : S.State <- walked("medikit at 60", 11n,
      holding(stocked(60, 0, 0, [50, 0, 0, 0], I.Inventory.start()), at(level, 32, 400, 90)))
    b0 : S.State <- walked("berserk at 100", 11n, at(level, 608, 400, 90))
    b1 : S.State <- picked("-", 10n, idle(), at(level, 608, 400, 90), b0)
    b2 : S.State <- walked("berserk at 60", 11n,
      holding(stocked(60, 0, 0, [50, 0, 0, 0], I.Inventory.start()), at(level, 608, 400, 90)))
    a0 : S.State <- walked("armour bonus", 11n, at(level, 624, 4294966576, 270))
    g0 : S.State <- walked("green armour", 11n, at(level, 1664, 1008, 90))
    g1 : S.State <- walked("green armour at 100", 11n,
      holding(stocked(100, 100, 1, [50, 0, 0, 0], I.Inventory.start()), at(level, 1664, 1008, 90)))
    IO.print("-")

def names(ids: List<&2, U32>) -> String:
  match ids:
    case []:
      ""
    case id <> rest:
      " " ++ U32.show(id) ++ names(rest)

# The mobjs that think before any special does, and those after one.
def lead(ts: List<&2, S.Thinker>) -> List<&2, U32>:
  match ts:
    case S.Mobj{id} <> rest:
      id <> lead(rest)
    case _:
      []

def late(ts: List<&2, S.Thinker>, special: Bool) -> List<&2, U32>:
  match ts special:
    case [] _:
      []
    case S.Mobj{id} <> rest True{}:
      id <> late(rest, True{})
    case S.Mobj{id} <> rest False{}:
      late(rest, False{})
    case _ <> rest _:
      late(rest, True{})

# The thinkers' order: how many mobjs think before the specials, the
# five about the player's among them, how many specials, and the mobjs
# after a special.
def order(tag: String, +ts: List<&2, S.Thinker>) -> String:
  tag ++ " thinkers: " ++ Nat.show(List.length(&2, U32, lead(ts))) ++ " mobjs, about the player's"
    ++ names(List.take(&2, U32, List.drop(&2, U32, lead(ts), 103n), 5n)) ++ ", " ++ U32.show(specials(ts))
    ++ " specials, then mobjs" ++ names(late(ts, False{}))

def of.sector(things: List<&2, H.Thing>, +sector: U32) -> List<&2, U32>:
  match things:
    case []:
      []
    case H.Thing{id, kind, x, y, z, floorz, ceilz, angle, +at, state, tics, momz, hurt} <> rest:
      V.Vec.keep(~U32, U32.is_eq(at, sector), id, of.sector(rest, sector))

# The mobjs the blockmap cell of a place in map units lists.
def cell(+bm: L.Level.Blockmap, ts: H.Things, x: U32, y: U32) -> String:
  names(H.Things.linked(ts, bm, [L.Level.cell_of(bm, F.Fixed.of_map(x), F.Fixed.of_map(y))]))

# The mobjs of the blockmap cells at (-400, 400) and (-400, 300), the
# last linked first, the things sectors 160 and 140 show, in their lists'
# order, the next id, the random index, and a thing.
def linked(tag: String, +id: U32, +s: S.State) -> String:
  +bm = L.Level.blockmap_of(S.State.level(s))
  +ts = S.State.things(s)
  tag ++ " cell 2,11" ++ cell(bm, ts, 65136, 400) ++ " cell 2,10" ++ cell(bm, ts, 65136, 300) ++ " sector 160"
    ++ names(of.sector(H.Things.shown(ts), 160)) ++ " sector 140" ++ names(of.sector(H.Things.shown(ts), 140))
    ++ " next " ++ U32.show(H.Things.count(ts)) ++ " random " ++ U32.show(S.State.rnd(s)) ++ " "
    ++ thing(H.Things.get(ts, id))

def moved.some(m: Maybe<&2, H.Thing>, x: U32, y: U32, +s: S.State) -> S.State:
  match m:
    case None{}:
      s
    case Some{+th}:
      S.State.moved(S.Try{True{}, S.State.player(s), H.Things.moved(S.State.things(s),
        L.Level.blockmap_of(S.State.level(s)), th, H.Thing.at(th, S.State.level(s), F.Fixed.of_map(x),
          F.Fixed.of_map(y)))}, S.State.level(s), s)

# A state with a thing at another place, unlinked and linked again.
def moved(+id: U32, x: U32, y: U32, +s: S.State) -> S.State:
  moved.some(H.Things.get(S.State.things(s), id), x, y, s)

def spawned(d: Maybe<&2, H.Thing.Def>, x: U32, y: U32, s: S.State) -> S.State:
  match d:
    case None{}:
      s
    case Some{info}:
      S.Sim.spawn(info, F.Fixed.of_map(x), F.Fixed.of_map(y), H.Thing.onfloor(), s)

# A state's links and a thing, then its thinkers' order.
def seen(tag: String, id: U32, +s: S.State) -> IO(S.State):
  do IO<S.State>:
    IO.print(linked(tag, id, s))
    IO.print(order(" ", S.State.thinkers(s)))
    return s

# Things that move, spawn and leave in play, from the start. The dead
# former human, record 58, moved from (-400, 400) to (-400, 300), over a
# cell border and a sector border, as P_UnsetThingPosition and
# P_SetThingPosition relink it; a health bonus spawned at (-340, 288) as
# P_SpawnMobj spawns it, an idle tic, its removal as P_RemoveMobj removes
# it, a tic, and another spawned; then the player's first move.
def relinks(+level: L.Level) -> IO(Unit):
  do IO<Unit>:
    s0 : S.State <- seen("start", 58, Tic.State.start(level))
    s1 : S.State <- seen("moved", 58, moved(58, 65136, 300, s0))
    s2 : S.State <- seen("spawned", 292, spawned(H.Thing.def(2014), 65196, 288, s1))
    s3 : S.State <- seen("a tic", 292, Tic.Sim.tic(idle(), s2))
    s4 : S.State <- seen("removed, a tic", 292, Tic.Sim.tic(idle(), S.Sim.remove(292, s3)))
    s5 : S.State <- seen("spawned", 293, spawned(H.Thing.def(2014), 65196, 288, s4))
    s6 : S.State <- seen("walked", 293, Tic.Sim.tic(forward(), s5))
    IO.print(links(s6))

def psprite(psp: S.Psprite) -> String:
  S.Psprite{state, tics, sx, sy} = psp
  Maybe.show(~&2, ~U32, ~U32.show, state) ++ " tics " ++ U32.show(tics) ++ " at " ++ F.Fixed.show(sx) ++ " "
    ++ F.Fixed.show(sy)

def psprites(ps: S.Psprites) -> String:
  S.Psprites{weapon, flash} = ps
  " state " ++ psprite(weapon) ++ " flash " ++ psprite(flash)

def armed(n: Nat, cmd: K.Cmd, s: S.State) -> IO(S.State):
  +q = Tic.Sim.replay(List.replicate(K.Cmd, n, cmd), s)
  do IO<S.State>:
    IO.print("weapon tic " ++ U32.show(S.State.clock(q)) ++ psprites(S.Player.psprites(S.State.player(q))))
    return q

# The pistol from the start: up from the bottom, at rest, bobbing on a
# walk east, and at rest again once the momentum is gone.
def weapon(+level: L.Level) -> IO(Unit):
  do IO<Unit>:
    w0 : S.State <- armed(0n, idle(), Tic.State.start(level))
    w1 : S.State <- armed(1n, idle(), w0)
    w2 : S.State <- armed(13n, idle(), w1)
    w3 : S.State <- armed(1n, idle(), w2)
    w4 : S.State <- armed(5n, idle(), w3)
    w5 : S.State <- armed(1n, forward(), w4)
    w6 : S.State <- armed(1n, forward(), w5)
    w7 : S.State <- armed(26n, forward(), w6)
    w8 : S.State <- armed(16n, forward(), w7)
    w9 : S.State <- armed(1n, idle(), w8)
    w10 : S.State <- armed(59n, idle(), w9)
    IO.print("-")

# What a blow left on the player: its mobj's state row and the tics in
# it, the damage count and who is to blame.
def wound(+h: V.Vec) -> String:
  " state " ++ U32.show(S.Sim.Hurt.state(h)) ++ "/" ++ U32.show(S.Sim.Hurt.tics(h)) ++ " damage "
    ++ U32.show(S.Sim.Hurt.damage(h)) ++ " attacker " ++ U32.show(S.Sim.Hurt.attacker(h))

# A state's place line, then the health, the armour, the momentum the
# blow left, the wound, the player sprites and whether the state asks
# for the level again.
def bruised(tag: String, +q: S.State) -> String:
  +p = S.State.player(q)
  +inv = S.Player.inv(p)
  line(tag ++ " tic " ++ U32.show(S.State.clock(q)), q) ++ " health " ++ U32.show(I.Inventory.health(inv))
    ++ " armour " ++ U32.show(I.Inventory.armour(inv)) ++ " type " ++ U32.show(I.Inventory.armourtype(inv))
    ++ " momentum " ++ F.Fixed.show(S.Player.momx(p)) ++ " " ++ F.Fixed.show(S.Player.momy(p))
    ++ wound(S.Player.hurt(p)) ++ psprites(S.Player.psprites(p)) ++ " random "
    ++ U32.show(S.State.rnd(q)) ++ " reborn " ++ Bool.show(S.State.reborn(q))

# A state as it stands, with what it has been heard to start.
def shown(tag: String, +s: S.State) -> IO(S.State):
  do IO<S.State>:
    IO.print(events(S.State.sounds(s), S.State.clock(s)) ++ bruised(tag, s))
    return s

# A run, then the same.
def hurt(tag: String, n: Nat, cmd: K.Cmd, s: S.State) -> IO(S.State):
  +r = ran(n, cmd, s)
  +q = Run.state(r)
  do IO<S.State>:
    IO.print(Run.log(r) ++ bruised(tag, q))
    return q

# The nukage of Freedoom's sector 173, stood in from its middle: 5
# health every 32 tics of the clock, the first on the tic the level
# begins, and armour taking its share of each blow.
def nukage(+level: L.Level) -> IO(Unit):
  do IO<Unit>:
    n0 : S.State <- hurt("nukage", 1n, idle(), at(level, 1600, 1000, 90))
    n1 : S.State <- hurt("-", 3n, idle(), n0)
    n2 : S.State <- hurt("-", 4n, idle(), n1)
    n3 : S.State <- hurt("-", 25n, idle(), n2)
    n4 : S.State <- hurt("-", 4n, idle(), n3)
    g0 : S.State <- hurt("green armour nukage", 1n, idle(),
      holding(stocked(100, 100, 1, [50, 0, 0, 0], I.Inventory.start()), at(level, 1600, 1000, 90)))
    g1 : S.State <- hurt("green armour worn out", 1n, idle(),
      holding(stocked(100, 1, 1, [50, 0, 0, 0], I.Inventory.start()), at(level, 1600, 1000, 90)))
    b0 : S.State <- hurt("blue armour nukage", 1n, idle(),
      holding(stocked(100, 100, 2, [50, 0, 0, 0], I.Inventory.start()), at(level, 1600, 1000, 90)))
    IO.print(drawn(n4))
    IO.print("-")

# Standing in the nukage while monsters attack, then using after death.
# The view sinks to 6 above the floor and the pistol leaves the screen.
# Chocolate Doom matches the frame at tic 650, including the dead face.
def dying(+level: L.Level) -> IO(Unit):
  do IO<Unit>:
    d0 : S.State <- hurt("nukage until it kills", 608n, idle(), at(level, 1600, 1000, 90))
    d1 : S.State <- hurt("death", 1n, idle(), d0)
    d2 : S.State <- hurt("-", 6n, idle(), d1)
    d3 : S.State <- hurt("-", 1n, idle(), d2)
    d4 : S.State <- hurt("-", 7n, idle(), d3)
    d5 : S.State <- hurt("-", 27n, idle(), d4)
    d6 : S.State <- hurt("-", 32n, idle(), d5)
    d7 : S.State <- hurt("use", 1n, use(), d6)
    d8 : S.State <- hurt("-", 1n, idle(), d7)
    IO.print(drawn(d8))
    IO.print("-")

def struck.in(s: S.State, +rnd: U32, thing: H.Thing) -> S.State:
  S.State{p, level, things, sidetex, thinkers, was, clock, ended, usedown, sounds, mrnd, reborn, totalsecret} = s
  S.State{p, level, H.Things.put(H.Things.none(1, H.Thing.you(), 1, 1), 0, Some{thing}), sidetex, thinkers, rnd,
    clock, ended, usedown, sounds, mrnd, reborn, totalsecret}

# A state in the one-sector room, Level.room: the player at rest
# at the origin facing east with some health, the random index a blow's
# draw is to start from, and a barrel named 0 at a place, which is only
# a name and a place, since it is linked in no blockmap and nothing but
# the blow reads it.
def struck(health: U32, rnd: U32, tx: U32, ty: U32, tz: U32) -> S.State:
  struck.in(holding(stocked(health, 0, 0, [50, 0, 0, 0], I.Inventory.start()),
    Tic.State.at(L.Level.room(0, 128), L.Start{0, 0, 0})), rnd,
    H.Thing{0, 2035, F.Fixed.of_map(tx), F.Fixed.of_map(ty), tz, 0, 8388608, 0, 0, 10, 6, 0,
      H.Thing.Hurt.of(2035)})

def blown(damage: U32, +s: S.State) -> S.State:
  Tic.Sim.damage(H.Things.you(S.State.things(s)), damage, 0, 0, s)

# A blow from a thing, which nothing on the map can deal yet: the thrust
# away from the inflictor, the attacker kept, and after a lethal one the
# view turning to it 5 degrees a tic while the damage count holds.
def blows() -> IO(Unit):
  do IO<Unit>:
    h0 : S.State <- shown("blow from the south", blown(20, struck(100, 0, 0, 4294967232, 0)))
    h1 : S.State <- hurt("-", 1n, idle(), h0)
    f0 : S.State <- shown("lethal blow from below", blown(20, struck(10, 1, 0, 4294966784, 4286578688)))
    f1 : S.State <- hurt("-", 1n, idle(), f0)
    f2 : S.State <- hurt("-", 16n, idle(), f1)
    f3 : S.State <- hurt("-", 1n, idle(), f2)
    f4 : S.State <- hurt("-", 1n, idle(), f3)
    f5 : S.State <- hurt("-", 1n, idle(), f4)
    IO.print(drawn(f5))
    IO.print("-")

# The state's player sliding, a corpse pushed by a blow no run can give
# it here.
def sliding(momx: U32, momy: U32, s: S.State) -> S.State:
  S.State{S.Player{x, y, z, angle, mx, my, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv,
    psprites, hurt}, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn, totalsecret} = s
  S.State{S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv,
    psprites, hurt}, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn, totalsecret}

# The player killed on the spot by a blow from nobody.
def killed(+s: S.State) -> S.State:
  Tic.Sim.damage(H.Things.you(S.State.things(s)), 100, H.Thing.you(), H.Thing.you(), s)

# The clip west of 672, 992, which a walk from there takes on its tenth
# tic: a corpse killed on the spot and slid west over it at 5 a tic
# takes nothing, where a living player slid the same way takes it.
def corpses(+level: L.Level) -> IO(Unit):
  do IO<Unit>:
    c0 : S.State <- picked("corpse slide", 20n, idle(), at(level, 672, 992, 180),
      sliding(4294639616, 0, killed(at(level, 672, 992, 180))))
    c1 : S.State <- picked("live slide", 20n, idle(), at(level, 672, 992, 180),
      sliding(4294639616, 0, at(level, 672, 992, 180)))
    IO.print("-")

# The nukage, the armour, the death and the restart, the blows no
# monster can deal yet, and the corpse that takes nothing.
def damaged(+level: L.Level) -> IO(Unit):
  do IO<Unit>:
    nukage(level)
    dying(level)
    blows()
    corpses(level)

def face.at(+s: S.State) -> U32:
  S.Sim.Face.index(S.State.face(s))

def faced.line(changed: Bool, log: String, +q: S.State) -> String:
  match changed:
    case False{}:
      log
    case True{}:
      log ++ "face tic " ++ U32.show(S.State.clock(q)) ++ " index " ++ U32.show(face.at(q)) ++ " health "
        ++ U32.show(I.Inventory.health(S.Player.inv(S.State.player(q)))) ++ " drew " ++ U32.show(S.State.mrnd(q))
        ++ "\n"

# A replay that logs each tic the face index changed to another, which
# is every decision ST_updateFaceWidget made that the bar can show.
def faced(script: List<&2, K.Cmd>, +was: U32, r: Run) -> Run:
  match script r:
    case [] _:
      r
    case cmd <> rest Run{log, s}:
      +q = Tic.Sim.tic(cmd, s)
      faced(rest, face.at(q), Run{faced.line(Bool.not(U32.is_eq(face.at(q), was)), log, q), q})

# A run of one command, its face changes, and the face the run left with
# its count and M_Random's index.
def faces(tag: String, n: Nat, cmd: K.Cmd, +s: S.State) -> IO(S.State):
  +r = faced(List.replicate(K.Cmd, n, cmd), face.at(s), Run{"", s})
  +q = Run.state(r)
  do IO<S.State>:
    IO.print(Run.log(r) ++ tag ++ " tic " ++ U32.show(S.State.clock(q)) ++ " index " ++ U32.show(face.at(q))
      ++ " count " ++ U32.show(S.Sim.Face.count(S.State.face(q))) ++ " health "
      ++ U32.show(I.Inventory.health(S.Player.inv(S.State.player(q)))) ++ " " ++ drawn(q))
    return q

# A blow of 20 from a barrel at a place, with a tic run first so that
# the health ST_Ticker saw last is no longer -1 and the ouch test is
# the one vanilla makes of a wound.
def sided(tag: String, tx: U32, ty: U32) -> IO(S.State):
  faces(tag, 3n, idle(), blown(20, Tic.Sim.tic(idle(), struck(100, 0, tx, ty, 0))))

def face.chased(n: Nat, s: S.State) -> S.State:
  Run.state(ran(n, idle(), s))

# Doom's face, ST_updateFaceWidget once a tic: the idle glance at the
# start, the nukage's pain down the five health levels and the dead
# face at the end of it, the wince toward a blow from either side and
# from dead ahead, the grin on a weapon taken, and the grimace after
# ST_RAMPAGEDELAY of held fire.
def faces.cases(+level: L.Level) -> IO(Unit):
  do IO<Unit>:
    g0 : S.State <- faces("glance", 60n, idle(), Tic.State.start(level))
    n0 : S.State <- faces("nukage", 200n, idle(), at(level, 1600, 1000, 90))
    n1 : S.State <- faces("nukage until it kills", 460n, idle(), n0)
    r0 : S.State <- sided("blow from the right", 0, 4294967232)
    l0 : S.State <- sided("blow from the left", 0, 64)
    a0 : S.State <- sided("blow from dead ahead", 64, 0)
    m0 : S.State <- faces("shotgun guy hit", 0n, idle(),
      face.chased(61n, at(level, 144, 1888, 0)))
    w0 : S.State <- faces("chainsaw grin", 16n, K.Cmd.demo(0, 4294967272, 0, 0),
      Tic.Sim.replay(List.append(&2, K.Cmd, List.replicate(K.Cmd, 20n, idle()),
        [K.Cmd.demo(0, 0, 4294967280, 0)]), at(level, 3158, 2176, 180)))
    f0 : S.State <- faces("held fire", 90n, fire(), Tic.State.start(level))
    f1 : S.State <- faces("held before release", 69n, fire(), Tic.State.start(level))
    f2 : S.State <- faces("release during firing", 1n, idle(), f1)
    f3 : S.State <- faces("held after release", 20n, fire(), f2)
    IO.print("-")

# Everything the two walks do not cover, from the map as loaded and from
# the map with three records rewritten.
# A signed count as text, for a health that goes past zero and for a
# type of -1 or -2, which the puff and the blood have.
def signed(+x: U32) -> String:
  Bool.pick(String, F.Fixed.is_neg(x), "-" ++ U32.show(F.Fixed.neg(x)), U32.show(x))

# A thing spawned in play, a bullet puff or a spot of blood: its type,
# where it stands, its state row and the tics left in it.
def spawned.one(m: Maybe<&2, H.Thing>) -> String:
  match m:
    case None{}:
      ""
    case Some{H.Thing{+id, +kind, +x, +y, +z, floorz, ceilz, angle, sector, +state, +tics, momz, hurt}}:
      " mobj " ++ U32.show(id) ++ " type " ++ signed(kind) ++ " at " ++ F.Fixed.show(x) ++ " "
        ++ F.Fixed.show(y) ++ " " ++ F.Fixed.show(z) ++ " state " ++ U32.show(state) ++ "/" ++ U32.show(tics)

def spawned.go(n: Nat, +i: U32, +things: H.Things) -> String:
  match n:
    case 0n:
      ""
    case 1n+m:
      spawned.one(H.Things.get(things, i)) ++ spawned.go(m, (i + 1 : U32), things)

# Every mobj past the map's records, in the order they spawned.
def spawned.all(+first: U32, +things: H.Things) -> String:
  spawned.go(U32.to_nat((H.Things.count(things) - first : U32)), first, things)

# A firing run: the sounds it started, then the tic, the weapon sprite
# and its flash, the extra light they lend the view, the bullets left,
# P_Random's index and every puff so far.
def fired(tag: String, n: Nat, cmd: K.Cmd, +first: U32, s: S.State) -> IO(S.State):
  +r = play(List.replicate(K.Cmd, n, cmd), Run{"", s})
  +q = Run.state(r)
  +p = S.State.player(q)
  do IO<S.State>:
    IO.print(Run.log(r) ++ tag ++ " tic " ++ U32.show(S.State.clock(q)) ++ psprites(S.Player.psprites(p))
      ++ " light " ++ U32.show(S.Player.extralight(p)) ++ " bullets "
      ++ U32.show(I.Inventory.rounds(I.Inventory.am_clip(), S.Player.inv(p))) ++ " rnd "
      ++ U32.show(S.State.rnd(q)) ++ spawned.all(first, S.State.things(q)))
    return q

# The state with other bullets in the clip.
def clipped(+rounds: U32, +s: S.State) -> S.State:
  holding(stocked(100, 0, 0, [rounds, 0, 0, 0], S.Player.inv(S.State.player(s))), s)

# Ctrl fires the pistol: one shot from the start, held fire, the last
# bullet and the refusal after it, a shot at a ledge above and one into
# the sky.
def firing(+level: L.Level) -> IO(Unit):
  do IO<Unit>:
    a0 : S.State <- fired("ready", 20n, idle(), 292, Tic.State.start(level))
    a1 : S.State <- fired("press", 1n, fire(), 292, a0)
    a2 : S.State <- fired("shot", 4n, idle(), 292, a1)
    a3 : S.State <- fired("after", 10n, idle(), 292, a2)
    a4 : S.State <- fired("gone", 20n, idle(), 292, a3)
    b0 : S.State <- fired("held", 20n, idle(), 292, Tic.State.start(level))
    b1 : S.State <- fired("held", 5n, fire(), 292, b0)
    b2 : S.State <- fired("held", 14n, fire(), 292, b1)
    b3 : S.State <- fired("held", 5n, idle(), 292, b2)
    c0 : S.State <- fired("last", 20n, idle(), 292, clipped(1, Tic.State.start(level)))
    c1 : S.State <- fired("last", 5n, fire(), 292, c0)
    c2 : S.State <- fired("dry", 19n, fire(), 292, c1)
    d0 : S.State <- fired("ledge", 20n, idle(), 292, at(level, 704, 256, 0))
    d1 : S.State <- fired("ledge", 5n, fire(), 292, d0)
    e0 : S.State <- fired("sky", 20n, idle(), 292, at(level, 64896, 256, 180))
    e1 : S.State <- fired("sky", 5n, fire(), 292, e0)
    IO.print("-")

# A mobj a fight watches: its name, its health, the state row it stands
# in with the tics left in it, where it stands, and what it is after.
def fighter(m: Maybe<&2, H.Thing>) -> String:
  match m:
    case None{}:
      " gone"
    case Some{+th}:
      " " ++ U32.show(H.Thing.id(th)) ++ " hp " ++ signed(H.Thing.health(th)) ++ " state "
        ++ U32.show(H.Thing.state(th)) ++ "/" ++ U32.show(H.Thing.tics(th)) ++ " at "
        ++ F.Fixed.show(H.Thing.x(th)) ++ " " ++ F.Fixed.show(H.Thing.y(th)) ++ " "
        ++ F.Fixed.show(H.Thing.z(th)) ++ " after " ++ U32.show(H.Thing.target(th))

def fighters(ids: List<&2, U32>, +things: H.Things) -> String:
  match ids:
    case []:
      ""
    case +id <> rest:
      fighter(H.Things.get(things, id)) ++ fighters(rest, things)

# A fight: the sounds it started, then the tic, where the player stands,
# its health and armour, P_Random's index, each watched mobj, and every
# mobj past the map's 292 records, which is what the shots and the blows
# spawned.
def fight(tag: String, n: Nat, cmd: K.Cmd, ids: List<&2, U32>, s: S.State) -> IO(S.State):
  +r = play(List.replicate(K.Cmd, n, cmd), Run{"", s})
  +q = Run.state(r)
  +inv = S.Player.inv(S.State.player(q))
  do IO<S.State>:
    IO.print(Run.log(r) ++ tag ++ " tic " ++ U32.show(S.State.clock(q)) ++ " at "
      ++ F.Fixed.show(S.Player.x(S.State.player(q))) ++ " " ++ F.Fixed.show(S.Player.y(S.State.player(q)))
      ++ " health " ++ U32.show(I.Inventory.health(inv)) ++ " armour " ++ U32.show(I.Inventory.armour(inv)) ++ "/"
      ++ U32.show(I.Inventory.armourtype(inv)) ++ " rnd " ++ U32.show(S.State.rnd(q))
      ++ fighters(ids, S.State.things(q)) ++ spawned.all(292, S.State.things(q)))
    return q

# The state with green armour and a full clip, so that a barrel's blast
# is split between the armour and the health.
def armoured(+s: S.State) -> S.State:
  holding(stocked(100, 100, 1, [50, 0, 0, 0], S.Player.inv(S.State.player(s))), s)

# Bullets hurt things. Record 265 is the zombieman at (944, -224) in
# sector 57, shot from 80 units east of it: each shot bleeds it, rolls
# its pain, and the last sends it through S_POSS_DIE1 to the corpse it
# rests in. Records 24, 25 and 26 are the three barrels at (992, 608),
# (992, 640) and (960, 608) in sector 13, shot from 64 units north of
# the nearest: the first to die explodes and its blast sets off the
# other two and reaches the player, whose green armour takes a third of
# it.
def fighting(+level: L.Level) -> IO(Unit):
  do IO<Unit>:
    g0 : S.State <- fight("zombieman ready", 20n, idle(), [265], at(level, 1024, 65312, 180))
    g1 : S.State <- fight("shot", 6n, fire(), [265], g0)
    g2 : S.State <- fight("held", 14n, fire(), [265], g1)
    g3 : S.State <- fight("held", 14n, fire(), [265], g2)
    g4 : S.State <- fight("held", 14n, fire(), [265], g3)
    g5 : S.State <- fight("corpse", 30n, idle(), [265], g4)
    IO.print("kill count " ++ U32.show(I.Inventory.kills(S.Player.inv(S.State.player(g5)))))
    b0 : S.State <- fight("barrels ready", 20n, idle(), [24, 25, 26], armoured(at(level, 992, 704, 270)))
    b1 : S.State <- fight("shot", 6n, fire(), [24, 25, 26], b0)
    b2 : S.State <- fight("held", 14n, fire(), [24, 25, 26], b1)
    b3 : S.State <- fight("held", 14n, fire(), [24, 25, 26], b2)
    b4 : S.State <- fight("burning", 10n, idle(), [24, 25, 26], b3)
    b5 : S.State <- fight("blast", 10n, idle(), [24, 25, 26], b4)
    b6 : S.State <- fight("chain", 20n, idle(), [24, 25, 26], b5)
    b7 : S.State <- fight("over", 40n, idle(), [24, 25, 26], b6)
    IO.print("-")

def attack.target(+id: U32, +s: S.State) -> S.State:
  S.Sim.thing.counted(id, H.Thing.hurt.target(), H.Things.you(S.State.things(s)), s)

def attack.result(tag: String, +id: U32, +s: S.State) -> IO(S.State):
  +inv = S.Player.inv(S.State.player(s))
  do IO<S.State>:
    IO.print(events(S.State.sounds(s), S.State.clock(s)) ++ tag ++ " health " ++ U32.show(I.Inventory.health(inv))
      ++ " random " ++ U32.show(S.State.rnd(s)) ++ " " ++ thing(H.Things.get(S.State.things(s), id))
      ++ spawned.all(292, S.State.things(s)))
    return s

def attack.missile.ticks(n: Nat, +id: U32, s: S.State) -> S.State:
  match n:
    case 0n:
      s
    case 1n+k:
      attack.missile.ticks(k, id, Tic.Sim.thing(id, s))

def attack.missile.from(+source: S.Sim.Body, +tx: U32, +ty: U32, n: Nat, +you: U32, +s: S.State) -> S.State:
  S.Body{i, sx, sy, z, radius, height, flags} = source
  +spawned = S.Sim.missile.spawn(S.Body{i, sx, sy, z, radius, height, flags},
    S.Body{4294967294, F.Fixed.of_map(tx), F.Fixed.of_map(ty), z, radius, height, flags}, you, s)
  +id = H.Things.count(S.State.things(s))
  attack.missile.ticks(n, id,
    Tic.Sim.missile.first(H.Things.get(S.State.things(spawned), id), id, spawned))

def attack.missile.up.from(+source: S.Sim.Body, n: Nat, +you: U32, +s: S.State) -> S.State:
  S.Body{i, x, y, z, radius, height, flags} = source
  +spawned = S.Sim.missile.spawn(S.Body{i, x, y, z, radius, height, flags},
    S.Body{4294967294, x, y, (z + F.Fixed.of_map(64) : U32), radius, height, flags}, you, s)
  +id = H.Things.count(S.State.things(s))
  attack.missile.ticks(n, id,
    Tic.Sim.missile.first(H.Things.get(S.State.things(spawned), id), id, spawned))

def attack.missile(+level: L.Level, +x: U32, +y: U32, +tx: U32, +ty: U32, n: Nat) -> S.State:
  +s = at(level, x, y, 0)
  +you = H.Things.you(S.State.things(s))
  attack.missile.from(S.Player.body(S.State.player(s), you), tx, ty, n, you, s)

def attack.missile.up(+level: L.Level, +x: U32, +y: U32, n: Nat) -> S.State:
  +s = at(level, x, y, 0)
  +you = H.Things.you(S.State.things(s))
  attack.missile.up.from(S.Player.body(S.State.player(s), you), n, you, s)

def attack.missile.result(tag: String, +s: S.State) -> IO(S.State):
  do IO<S.State>:
    IO.print(events(S.State.sounds(s), S.State.clock(s)) ++ tag ++ " random " ++ U32.show(S.State.rnd(s))
      ++ spawned.all(292, S.State.things(s)))
    return s

def attack.missile.vertical(+th: H.Thing, +z: U32, +floorz: U32, +momz: U32) -> H.Thing:
  H.Thing{id, kind, x, y, wasz, wasfloor, ceilz, angle, sector, state, tics, wasmom, hurt} = th
  H.Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics, momz, hurt}

def attack.missile.floor.some(+th: H.Thing, +id: U32, +s: S.State) -> IO(Unit):
  +floor = H.Thing.floorz(th)
  +resting = Tic.Sim.thing(id, S.State.thing.put(id, attack.missile.vertical(th, floor, floor, 0), s))
  +crossing = Tic.Sim.thing(id, S.State.thing.put(id, attack.missile.vertical(th, floor, floor, 4294967295), s))
  do IO<Unit>:
    IO.print("fireball resting random " ++ U32.show(S.State.rnd(resting))
      ++ spawned.all(id, S.State.things(resting)))
    IO.print("fireball crossing floor random " ++ U32.show(S.State.rnd(crossing))
      ++ spawned.all(id, S.State.things(crossing)))

def attack.missile.floor.found(m: Maybe<&2, H.Thing>, +id: U32, +s: S.State) -> IO(Unit):
  match m:
    case None{}:
      IO.print("fireball missing")
    case Some{th}:
      attack.missile.floor.some(th, id, s)

def attack.missile.floor(+level: L.Level) -> IO(Unit):
  +s = attack.missile(level, 704, 256, 900, 256, 0n)
  +id = (H.Things.count(S.State.things(s)) - 1 : U32)
  attack.missile.floor.found(H.Things.get(S.State.things(s), id), id, s)

def attack.replay(tag: String, n: Nat, cmd: K.Cmd, +s: S.State) -> IO(S.State):
  +q = Run.state(play(List.replicate(K.Cmd, n, cmd), Run{"", s}))
  do IO<S.State>:
    IO.print(tag ++ " tic " ++ U32.show(S.State.clock(q)) ++ " health "
      ++ U32.show(I.Inventory.health(S.Player.inv(S.State.player(q)))) ++ " facing "
      ++ A.Angle.show(S.Player.angle(S.State.player(q))) ++ " random " ++ U32.show(S.State.rnd(q))
      ++ " fireball" ++ fighter(H.Things.get(S.State.things(q), 297)))
    return q

def attack.play(n: Nat, cmd: K.Cmd, +s: S.State) -> S.State:
  Run.state(play(List.replicate(K.Cmd, n, cmd), Run{"", s}))

def attack.combatant(m: Maybe<&2, H.Thing>) -> String:
  match m:
    case None{}:
      " gone"
    case Some{+th}:
      " target " ++ U32.show(H.Thing.target(th)) ++ " threshold " ++ U32.show(H.Thing.threshold(th))
        ++ fighter(Some{th})

def attack.ticked(m: Maybe<&2, H.Thing>, +id: U32, +tics: U32, s: S.State) -> S.State:
  match m:
    case None{}:
      s
    case Some{th}:
      S.State.thing.put(id, H.Thing.ticking(th, tics), s)

def attack.retaliation.hit(+level: L.Level) -> IO(Unit):
  +s = Tic.State.start(level)
  +aimed = S.Sim.thing.counted(240, H.Thing.hurt.target(), 81, s)
  +first = Tic.Sim.sposattack(240, aimed)
  +held = Tic.Sim.damage(81, 4, 82, 82, first)
  do IO<Unit>:
    IO.print("imp retaliates" ++ attack.combatant(H.Things.get(S.State.things(first), 81))
      ++ " random " ++ U32.show(S.State.rnd(first)))
    IO.print("threshold holds" ++ attack.combatant(H.Things.get(S.State.things(held), 81))
      ++ " random " ++ U32.show(S.State.rnd(held)))

def attack.retaliation.barrel(+level: L.Level) -> IO(Unit):
  +s = Tic.State.start(level)
  +barrel = Tic.Sim.damage(81, 4, 24, H.Things.you(S.State.things(s)), s)
  IO.print("barrel credits player" ++ attack.combatant(H.Things.get(S.State.things(barrel), 81))
    ++ " random " ++ U32.show(S.State.rnd(barrel)))

def attack.retaliation.fight(+level: L.Level) -> IO(Unit):
  +s = Tic.State.start(level)
  +aimed = S.Sim.thing.counted(240, H.Thing.hurt.target(), 81, s)
  +first = Tic.Sim.sposattack(240, aimed)
  +fight = attack.play(60n, idle(), first)
  IO.print("shotgun imp fight" ++ attack.combatant(H.Things.get(S.State.things(fight), 81))
    ++ attack.combatant(H.Things.get(S.State.things(fight), 240)) ++ " random " ++ U32.show(S.State.rnd(fight)))

def attack.retaliation.blast(+level: L.Level) -> IO(Unit):
  +s = Tic.State.start(level)
  +moved = S.State.thing.moved(24, F.Fixed.of_map(832), F.Fixed.of_map(1056), s)
  +credited = S.Sim.thing.counted(24, H.Thing.hurt.target(), H.Things.you(S.State.things(moved)), moved)
  +entered = S.Sim.damage.entered(24, S.State.thing(24, credited), 178, credited)
  +ready = attack.ticked(S.State.thing(24, entered), 24, 1, entered)
  +blast = attack.play(1n, idle(), ready)
  IO.print("player barrel blast" ++ attack.combatant(H.Things.get(S.State.things(blast), 81))
    ++ attack.combatant(H.Things.get(S.State.things(blast), 240))
    ++ attack.combatant(H.Things.get(S.State.things(blast), 82))
    ++ attack.combatant(H.Things.get(S.State.things(blast), 83))
    ++ fighter(H.Things.get(S.State.things(blast), 24)) ++ " random " ++ U32.show(S.State.rnd(blast)))

# Freedoom records 240 and 81 stand 112 units apart in one room. A
# Chocolate Doom call to A_SPosAttack followed by 60 idle tics gives
# random indices 83 and 132 and the same health, states, targets,
# thresholds and fixed-point positions printed below.
def attack.retaliation(+level: L.Level) -> IO(Unit):
  do IO<Unit>:
    attack.retaliation.hit(level)
    attack.retaliation.barrel(level)
    attack.retaliation.fight(level)
    attack.retaliation.blast(level)

def attacks(+level: L.Level) -> IO(Unit):
  do IO<Unit>:
    claw : S.State <- attack.result("imp claw", 81,
      Tic.Sim.troopattack(81, attack.target(81, at(level, 848, 1000, 0))))
    bite : S.State <- attack.result("demon bite", 3,
      Tic.Sim.sargattack(3, attack.target(3, at(level, 2576, 2112, 0))))
    ball : S.State <- attack.result("imp throw", 81,
      Tic.Sim.troopattack(81, attack.target(81, at(level, 848, 900, 0))))
    wall : S.State <- attack.missile.result("fireball wall", attack.missile(level, 704, 256, 900, 256, 8n))
    sky : S.State <- attack.missile.result("fireball sky", attack.missile.up(level, 64896, 256, 3n))
    attack.missile.floor(level)
    replay0 : S.State <- attack.replay("unarmoured flight", 10n, idle(),
      attack.play(34n, fire(), attack.play(20n, idle(), at(level, 992, 704, 270))))
    replay1 : S.State <- attack.replay("unarmoured burst", 10n, idle(), replay0)
    +replay2 : S.State <- attack.replay("unarmoured gone", 20n, idle(), replay1)
    IO.print("dead player idle" ++ attack.combatant(H.Things.get(S.State.things(replay2), 81))
      ++ attack.combatant(H.Things.get(S.State.things(replay2), 82)))
    attack.retaliation(level)
    IO.print("-")

def weapon.inv(+ready: U32, +shells: U32, inv: I.Inventory) -> I.Inventory:
  I.Inventory{health, armour, armourtype, cards, +ammo, caps, backpack, weapons, powers, items, bonus, line, kills, secrets} = inv
  I.Inventory.weaponstate(ready, 255, I.Inventory{health, armour, armourtype, cards,
    V.Vec.set(ammo, I.Inventory.am_shell(), shells), caps, backpack,
    (weapons .|. I.Inventory.shotgun() .|. I.Inventory.weaponbit(ready) : U32),
    powers, items, bonus, line, kills, secrets})

def weapon.state(+ready: U32, +row: U32, +shells: U32, +s: S.State) -> S.State:
  +p = S.State.player(s)
  +shown = {S.Psprites{S.Psprite{Some{row}, 1, 65536, S.Sim.weapontop()},
    S.Psprite{None{}, 0, 65536, S.Sim.weapontop()}} : S.Psprites}
  S.State.player.put(s, S.Player.showing(S.Player.holding(p, weapon.inv(ready, shells, S.Player.inv(p))), shown))

def weapon.line(tag: String, +s: S.State) -> IO(S.State):
  +p = S.State.player(s)
  +inv = S.Player.inv(p)
  do IO<S.State>:
    IO.print(events(S.State.sounds(s), S.State.clock(s)) ++ tag ++ " tic " ++ U32.show(S.State.clock(s))
      ++ " ready " ++ U32.show(I.Inventory.ready(inv)) ++ " pending " ++ U32.show(I.Inventory.pending(inv))
      ++ " shells " ++ U32.show(I.Inventory.rounds(I.Inventory.am_shell(), inv))
      ++ psprites(S.Player.psprites(p)) ++ " random " ++ U32.show(S.State.rnd(s)))
    return s

def weapon.run(tag: String, n: Nat, cmd: K.Cmd, s: S.State) -> IO(S.State):
  weapon.line(tag, Tic.Sim.replay(List.replicate(K.Cmd, n, cmd), s))

def weapon.pick(m: Maybe<&2, I.Inventory>) -> String:
  match m:
    case None{}:
      "none"
    case Some{+inv}:
      "ready " ++ U32.show(I.Inventory.ready(inv)) ++ " pending " ++ U32.show(I.Inventory.pending(inv))
        ++ " shells " ++ U32.show(I.Inventory.rounds(I.Inventory.am_shell(), inv))

def weapon.strong(+s: S.State) -> S.State:
  +p = S.State.player(s)
  S.State.player.put(s, S.Player.holding(p, I.Inventory.power(I.Inventory.pw_strength(), 1, S.Player.inv(p))))

def weapon.health(m: Maybe<&2, H.Thing>) -> U32:
  match m:
    case None{}:
      0
    case Some{+th}:
      H.Thing.health(th)

def weapon.got(m: Maybe<&2, I.Inventory>) -> I.Inventory:
  Maybe.default(&2, I.Inventory, m, I.Inventory.start())

def weapon.carrying(+strong: Bool, +s: S.State) -> S.State:
  +p = S.State.player(s)
  +inv = weapon.got(I.Inventory.weapon(I.Inventory.chainsaw(), 7, False{}, 0, I.Inventory.start()))
  S.State.player.put(s, S.Player.holding(p, Bool.pick(I.Inventory, strong, I.Inventory.power(I.Inventory.pw_strength(), 1, inv), inv)))

def weapon.melee(tag: String, +id: U32, +s: S.State) -> IO(S.State):
  +p = S.State.player(s)
  do IO<S.State>:
    IO.print(events(S.State.sounds(s), S.State.clock(s)) ++ tag ++ " health "
      ++ U32.show(weapon.health(H.Things.get(S.State.things(s), id))) ++ " random " ++ U32.show(S.State.rnd(s))
      ++ " angle " ++ A.Angle.show(S.Player.angle(p)) ++ " at " ++ F.Fixed.show(S.Player.x(p)) ++ " "
      ++ F.Fixed.show(S.Player.y(p)) ++ " momentum " ++ F.Fixed.show(S.Player.momx(p)) ++ " "
      ++ F.Fixed.show(S.Player.momy(p)) ++ " pull "
      ++ U32.show(V.Vec.get(S.Player.hurt(p), S.Sim.hurt.justattacked())))
    return s

def weapons(+level: L.Level) -> IO(Unit):
  +base = weapon.state(1, H.Thing.Weapon.ready(H.Thing.pistol()), 4, Tic.State.start(level))
  do IO<Unit>:
    IO.print("shotgun pickup " ++ weapon.pick(I.Inventory.grant(2001, False{}, I.Inventory.start())))
    k0 : S.State <- weapon.run("key", 1n, K.Cmd.demo(0, 0, 0, 20), base)
    k1 : S.State <- weapon.run("mid switch", 8n, idle(), k0)
    k2 : S.State <- weapon.run("shotgun ready", 24n, idle(), k1)
    b0 : S.State <- weapon.run("trigger", 1n, fire(), k2)
    b1 : S.State <- weapon.run("blast", 3n, idle(), b0)
    l0 : S.State <- weapon.run("last trigger", 1n, fire(),
      weapon.state(2, H.Thing.Weapon.ready(H.Thing.shotgun()), 1, Tic.State.start(level)))
    l1 : S.State <- weapon.run("last blast", 3n, idle(), l0)
    l2 : S.State <- weapon.run("switch away", 70n, idle(), l1)
    p0 : S.State <- weapon.melee("punch", 25, Tic.Sim.replay(List.replicate(K.Cmd, 5n, fire()),
      weapon.state(0, H.Thing.Weapon.ready(H.Thing.fist()), 0, at(level, 992, 660, 270))))
    p1 : S.State <- weapon.melee("berserk punch", 25, Tic.Sim.replay(List.replicate(K.Cmd, 5n, fire()),
      weapon.strong(weapon.state(0, H.Thing.Weapon.ready(H.Thing.fist()), 0, at(level, 992, 660, 270)))))
    c0 : S.State <- weapon.melee("saw hit", 25, Tic.Sim.replay(List.replicate(K.Cmd, 5n, fire()),
      weapon.state(7, H.Thing.Weapon.ready(H.Thing.saw()), 0, at(level, 992, 660, 270))))
    c1 : S.State <- weapon.melee("saw pull", 25, Tic.Sim.tic(fire(), c0))
    c2 : S.State <- weapon.melee("saw miss", 25, Tic.Sim.replay(List.replicate(K.Cmd, 5n, fire()),
      weapon.state(7, H.Thing.Weapon.ready(H.Thing.saw()), 0, Tic.State.start(level))))
    k3 : S.State <- weapon.run("key 1 saw", 1n, K.Cmd.demo(0, 0, 0, 4),
      weapon.state(1, H.Thing.Weapon.ready(H.Thing.pistol()), 0,
        weapon.carrying(False{}, Tic.State.start(level))))
    k4 : S.State <- weapon.run("key 1 berserk", 1n, K.Cmd.demo(0, 0, 0, 4),
      weapon.state(7, H.Thing.Weapon.ready(H.Thing.saw()), 0,
        weapon.carrying(True{}, Tic.State.start(level))))
    IO.print("-")

def cases(a: Array<U32>, +level: L.Level) -> IO(Unit):
  do IO<Unit>:
    weapon(level)
    firing(level)
    fighting(level)
    attacks(level)
    pickups(level)
    damaged(level)
    faces.cases(level)
    door(level)
    world : Array<U32> & L.Level <- IO.pass(Array<U32> & L.Level, patched(W.Wad.dir(a)))
    patched.cases(level, world)
    relinks(level)

# Whether a sector pair is rejected, as REJECT's bit for it says.
def rejects(pairs: List<&2, U32>, +level: L.Level) -> String:
  match pairs:
    case []:
      ""
    case +a <> +b <> rest:
      " " ++ U32.show(a) ++ "," ++ U32.show(b) ++ " " ++ Bool.show(L.Level.rejected(level, a, b))
        ++ rejects(rest, level)
    case +a <> rest:
      ""

# Whether the mobj an id names sees the player where it stands, Doom's
# P_CheckSight both ways round, which it is symmetric under only when
# the two mobjs are the same height, as these are.
def insight.one(m: Maybe<&2, S.Sim.Body>, +s: S.State) -> Bool:
  match m:
    case None{}:
      False{}
    case Some{b}:
      S.Sim.sight(S.State.level(s), b, S.Player.body(S.State.player(s), H.Thing.you()))

def insight(ids: List<&2, U32>, +s: S.State) -> String:
  match ids:
    case []:
      ""
    case +id <> rest:
      " " ++ U32.show(id) ++ " "
        ++ Bool.show(insight.one(S.Sim.body(S.State.things(s), S.State.player(s), id), s))
        ++ insight(rest, s)

def watched(tag: String, +ids: List<&2, U32>, n: Nat, s: S.State) -> IO(S.State):
  +r = ran(n, idle(), s)
  +q = Run.state(r)
  do IO<S.State>:
    IO.print(Run.log(r) ++ tag ++ " tic " ++ U32.show(S.State.clock(q)) ++ phases(ids, S.State.things(q))
      ++ " sight" ++ insight(ids, q) ++ " random " ++ U32.show(S.State.rnd(q)))
    return q

# What monsters see from a place held still: the sounds each tic
# started, then the state rows and tics of the monsters watched, and
# whether each has the player in sight.
def sighting(tag: String, ids: List<&2, U32>, n: Nat, x: U32, y: U32, degrees: U32, +level: L.Level) ->
  IO(Unit):
  do IO<Unit>:
    a : S.State <- watched(tag, ids, n, at(level, x, y, degrees))
    b : S.State <- finished(a)
    IO.pure(Unit, Unit{})

# A_Look over Freedoom's monsters. First REJECT, read from the lump in
# nushell: Freedoom's E1M1 has 182 sectors, so the lump is 4141 bytes
# and its last one holds the pairs (181, 178) to (181, 181), which the
# loader would lose if it read the lump as whole words.
# Sector 36's demon, record 92, stands
# at (-48, 1616) facing east and is deaf; the player 96 units due east
# of it is dead ahead, so it wakes on its first look, the tic its spawn
# draw leaves it, and its sfx_sgtsit needs no draw of its own. Record
# 90's shotgun guy at (368, 1552) faces south: from 80 units behind it
# the angle from it to the player is a half turn, past ANG90 and short
# of ANG270, and 80 is past MELEERANGE, so it never looks up; from 48
# behind it the same angle is excused and it wakes on its first look.
# Record 96's shotgun guy at (144, 1952) is in front of a player at
# (48, 1616) and 384 units off, but the rooms between them close the
# sight; 64 units south of it, it wakes. Record 177's zombieman at
# (752, 336) sees a player at (488, 256) across the pit and not one at
# (488, 320): line 553's opening, floor 32 against the pit's -128 and
# both ceilings at 128, raises the bottom slope over the top one. Its
# spawn draw left lastlook at 1, so its first look stops at player 1
# without looking and it wakes ten tics later than it would.
def sights(+level: L.Level) -> IO(Unit):
  do IO<Unit>:
    IO.print("reject" ++ rejects([17, 17, 36, 36, 17, 5, 36, 87, 36, 56, 5, 66, 181, 178, 181, 179, 181, 180,
      181, 181], level))
    sighting("front and deaf", [92, 90, 96], 12n, 48, 1616, 180, level)
    sighting("behind", [90, 92], 30n, 368, 1632, 0, level)
    sighting("behind in reach", [90, 92], 12n, 368, 1600, 0, level)
    sighting("through the wall", [96], 20n, 144, 1888, 0, level)
    sighting("over the pit", [177, 176], 20n, 488, 256, 0, level)
    sighting("off the pit", [177, 176], 20n, 488, 320, 0, level)

# Where a chasing monster stands, which way it faces, the eight-way
# direction it walks and the row it is in.
def hunt(m: Maybe<&2, H.Thing>) -> String:
  match m:
    case None{}:
      ""
    case Some{H.Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics, momz, hurt}}:
      " " ++ U32.show(id) ++ " at " ++ F.Fixed.show(x) ++ " " ++ F.Fixed.show(y) ++ " facing "
        ++ A.Angle.show(angle) ++ " dir " ++ U32.show(V.Vec.get(hurt, H.Thing.hurt.movedir())) ++ " row "
        ++ U32.show(state) ++ "/" ++ U32.show(tics)

def hunts(ids: List<&2, U32>, +things: H.Things) -> String:
  match ids:
    case []:
      ""
    case +id <> rest:
      hunt(H.Things.get(things, id)) ++ hunts(rest, things)

# One tic of a chase, with the monsters watched and the player's health.
def chased(+ids: List<&2, U32>, n: Nat, s: S.State) -> S.State:
  Run.state(ran(n, idle(), s))

def chasing.go(n: Nat, +ids: List<&2, U32>, s: S.State) -> IO(S.State):
  match n:
    case 0n:
      IO.pure(S.State, s)
    case 1n+k:
      +r = ran(1n, idle(), s)
      +q = Run.state(r)
      do IO<S.State>:
        IO.print(Run.log(r) ++ "tic " ++ U32.show(S.State.clock(q)) ++ hunts(ids, S.State.things(q))
          ++ " health " ++ U32.show(I.Inventory.health(S.Player.inv(S.State.player(q)))) ++ " random "
          ++ U32.show(S.State.rnd(q)))
        chasing.go(k, ids, q)

# A chase from a place held still: each tic's sounds, then where each
# monster watched stands, which way it faces, the direction it walks and
# the row it is in, with the player's health after.
def chasing(tag: String, ids: List<&2, U32>, n: Nat, x: U32, y: U32, degrees: U32, +level: L.Level) ->
  IO(Unit):
  do IO<Unit>:
    IO.print(tag)
    a : S.State <- chasing.go(n, ids, at(level, x, y, degrees))
    b : S.State <- finished(a)
    IO.pure(Unit, Unit{})

# A_Chase over Freedoom's monsters, held at one place so that only the
# monsters move. Head on: the demon of record 92 at (-48, 1616) wakes on
# tic 7 and walks its speed of 10 straight east at a player 96 units
# away. Across a room: zombieman 177 at (752, 336) wakes on tic 15 and walks south-west
# at a player standing at (488, 256), 8 units a move tic. Around a
# corner: shotgun guy 96 at (144, 1952) wakes on tic 6, walks south
# three moves and then turns east, 45 degrees a tic, when the wall stops
# it. At a ledge: zombieman 186 stands on a floor at 120 with an eight
# unit floor all round it, and a player at (1004, -672) is 100 units
# west of it; the drop of 64 is more than the 24 P_TryMove allows, so it
# never steps off. The two longer runs are the
# former humans' shots, where the reaction time of 8 has run out and the
# move count is zero on a tic the range check passes.
def chases(+level: L.Level) -> IO(Unit):
  do IO<Unit>:
    chasing("head on", [92], 12n, 48, 1616, 180, level)
    chasing("across the room", [177], 24n, 488, 256, 0, level)
    chasing("round the corner", [96], 24n, 144, 1888, 0, level)
    chasing("at the ledge", [185], 40n, 1004, 4294966624, 0, level)
    chasing("the zombieman shoots", [177], 70n, 488, 256, 0, level)
    chasing("the shotgun guy shoots", [96], 70n, 144, 1888, 0, level)

def walk(p: Array<U32> & L.Level) -> IO(Unit):
  (a, +level) = p
  do IO<Unit>:
    s : S.State <- step("start", 0n, K.Keys.none(), Tic.State.start(level))
    p0 : S.State <- free(s)
    p1 : S.State <- step("U:1", 1n, K.Keys{True{}, False{}, False{}, False{}, False{}, False{}, False{}, False{}, False{}, K.Keys.numbers.none()}, p0)
    p2 : S.State <- step("U!:34", 34n, K.Keys{True{}, False{}, False{}, False{}, False{}, False{}, True{}, False{}, False{}, K.Keys.numbers.none()}, p1)
    p3 : S.State <- step("L:20", 20n, K.Keys{False{}, False{}, True{}, False{}, False{}, False{}, False{}, False{}, False{}, K.Keys.numbers.none()}, p2)
    p4 : S.State <- step("U!:200", 200n, K.Keys{True{}, False{}, False{}, False{}, False{}, False{}, True{}, False{}, False{}, K.Keys.numbers.none()}, p3)
    p5 : S.State <- step("-:40", 40n, K.Keys{False{}, False{}, False{}, False{}, False{}, False{}, False{}, False{}, False{}, K.Keys.numbers.none()}, p4)
    p6 : S.State <- step("R:10", 10n, K.Keys{False{}, False{}, False{}, True{}, False{}, False{}, False{}, False{}, False{}, K.Keys.numbers.none()}, p5)
    p7 : S.State <- step("U!:70", 70n, K.Keys{True{}, False{}, False{}, False{}, False{}, False{}, True{}, False{}, False{}, K.Keys.numbers.none()}, p6)
    p8 : S.State <- step("L:30", 30n, K.Keys{False{}, False{}, True{}, False{}, False{}, False{}, False{}, False{}, False{}, K.Keys.numbers.none()}, p7)
    p9 : S.State <- step("U:100", 100n, K.Keys{True{}, False{}, False{}, False{}, False{}, False{}, False{}, False{}, False{}, K.Keys.numbers.none()}, p8)
    p10 : S.State <- step("S:60", 60n, K.Keys{False{}, False{}, False{}, False{}, False{}, True{}, False{}, False{}, False{}, K.Keys.numbers.none()}, p9)
    p11 : S.State <- step("D!:100", 100n, K.Keys{False{}, True{}, False{}, False{}, False{}, False{}, True{}, False{}, False{}, K.Keys.numbers.none()}, p10)
    p12 : S.State <- step("R:40", 40n, K.Keys{False{}, False{}, False{}, True{}, False{}, False{}, False{}, False{}, False{}, K.Keys.numbers.none()}, p11)
    p13 : S.State <- step("U!:120", 120n, K.Keys{True{}, False{}, False{}, False{}, False{}, False{}, True{}, False{}, False{}, K.Keys.numbers.none()}, p12)
    p14 : S.State <- step("A!:40", 40n, K.Keys{False{}, False{}, False{}, False{}, True{}, False{}, True{}, False{}, False{}, K.Keys.numbers.none()}, p13)
    q1 : S.State <- step("ledge U!:47", 47n, K.Keys{True{}, False{}, False{}, False{}, False{}, False{}, True{}, False{}, False{}, K.Keys.numbers.none()}, Tic.State.start(level))
    q2 : S.State <- step("U!:1", 1n, K.Keys{True{}, False{}, False{}, False{}, False{}, False{}, True{}, False{}, False{}, K.Keys.numbers.none()}, q1)
    q3 : S.State <- step("U!:1", 1n, K.Keys{True{}, False{}, False{}, False{}, False{}, False{}, True{}, False{}, False{}, K.Keys.numbers.none()}, q2)
    q4 : S.State <- step("U!:15", 15n, K.Keys{True{}, False{}, False{}, False{}, False{}, False{}, True{}, False{}, False{}, K.Keys.numbers.none()}, q3)
    q5 : S.State <- step("-:1", 1n, K.Keys.none(), q4)
    q6 : S.State <- step("-:40", 40n, K.Keys.none(), q5)
    IO.print("the walks: " ++ drawn(p14) ++ ", " ++ drawn(q6))
    cases(a, level)
    sights(level)
    chases(level)
    weapons(level)

def main() -> IO(Unit):
  do IO<Unit>:
    world : Array<U32> & L.Level <- L.Level.open(1, 1)
    walk(world)

#|start -416.000000 256.000000 0.000 z 0.000000 floor 0.000000 eye 41.000000
#|free at start True
#|inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0
#|things at start 209 random 59
#|by type 5:1 8:0 10:3 12:3 15:4 17:0 18:5 19:1 20:1 21:2 24:2 26:1 35:0 43:12 47:18 48:4 54:15 60:2 2001:0 2002:0 2003:0 2004:0 2005:1 2007:2 2008:14 2010:1 2011:2 2012:4 2013:0 2014:30 2015:18 2018:1 2019:0 2023:1 2028:7 2035:22 2046:0 2047:1 2048:1 2049:1 3004:4 9:10 3001:10 3002:5 4294967295:0 4294967294:0 4294967293:0 6:0 13:0 14:0 34:0 46:0 58:0 2024:0 2025:0 2026:0 2045:0 3003:0 4294967292:0
#|first 2 3 6 8 9 10 11 12 13 14 15 16
#|links 209 of 209 things, solid 108 of 108, wrong 0, unlinked 0
#|thing 2 type 2005 at 3104.000000 2160.000000 z 194.000000 angle 315.000 sector 139 state 45 tics 4294967295 radius 20 height 16 flags 1 ambush True
#|thing 6 type 2018 at 1664.000000 1088.000000 z -144.000000 angle 270.000 sector 130 state 6 tics 2 radius 20 height 16 flags 1 ambush False
#|thing 29 type 60 at 1184.000000 288.000000 z 60.000000 angle 90.000 sector 153 state 53 tics 4294967295 radius 20 height 68 flags 768 ambush True
#|thing 87 type 5 at 2192.000000 576.000000 z 136.000000 angle 270.000 sector 35 state 24 tics 1 radius 20 height 16 flags 33554433 ambush False
#|thing 245 type 19 at 1248.000000 224.000000 z 16.000000 angle 90.000 sector 170 state 3 tics 4294967295 radius 20 height 16 flags 0 ambush True
#|thing 291 type 2023 at 608.000000 480.000000 z 0.000000 angle 270.000 sector 150 state 34 tics 4294967295 radius 20 height 16 flags 8388609 ambush False
#|thing 176 type 3004 at 816.000000 448.000000 z -128.000000 angle 225.000 sector 17 state 61 tics 5 radius 20 height 56 flags 4194310 ambush True
#|thing 240 type 9 at 960.000000 1056.000000 z -128.000000 angle 270.000 sector 56 state 63 tics 6 radius 20 height 56 flags 4194310 ambush False
#|thing 81 type 3001 at 848.000000 1056.000000 z -128.000000 angle 270.000 sector 56 state 65 tics 8 radius 20 height 56 flags 4194310 ambush False
#|thing 3 type 3002 at 2576.000000 2112.000000 z 192.000000 angle 315.000 sector 5 state 67 tics 1 radius 30 height 56 flags 4194310 ambush True
#|U:1 -415.218765 256.000289 0.000 z 0.000000 floor 0.000000 eye 41.000015
#|U!:34 3.282882 256.157440 0.000 z 0.000000 floor 0.000000 eye 33.430175
#|sound tic 41 DSPSTART from sector 98 vol 64 sep 149
#|L:20 137.245544 256.206893 61.523 z -48.000000 floor -48.000000 eye 44.403701
#|sound tic 75 DSPSTOP from sector 98 vol 64 sep 78
#|sound tic 135 DSPOSIT1 from thing 177 vol 63 sep 204
#|sound tic 145 DSPOSIT1 from thing 176 vol 59 sep 168
#|sound tic 155 DSPOSACT from thing 177 vol 64 sep 218
#|sound tic 180 DSPSTART from sector 98 vol 38 sep 50
#|sound tic 181 DSPOSACT from thing 176 vol 64 sep 156
#|sound tic 185 stop thing 264
#|sound tic 185 DSITEMUP from nobody vol 64 sep 128
#|sound tic 215 DSPSTOP from sector 98 vol 30 sep 58
#|sound tic 217 DSPISTOL from thing 177 vol 64 sep 164
#|sound tic 232 stop thing 292
#|sound tic 247 DSPISTOL from thing 177 vol 62 sep 122
#|sound tic 250 DSPOPAIN from thing 176 vol 64 sep 155
#|U!:200 879.977035 495.961868 61.523 z -128.000000 floor -128.000000 eye 40.722702
#|sound tic 262 stop thing 293
#|sound tic 287 DSPISTOL from thing 176 vol 64 sep 139
#|sound tic 289 DSPOPAIN from thing 177 vol 64 sep 128
#|sound tic 294 stop thing 294
#|-:40 879.977035 495.961868 61.523 z -128.000000 floor -128.000000 eye 41.000000
#|R:10 879.977035 495.961868 35.156 z -128.000000 floor -128.000000 eye 41.000000
#|sound tic 330 DSPISTOL from thing 177 vol 64 sep 180
#|sound tic 337 stop thing 295
#|sound tic 351 DSPOSACT from thing 176 vol 64 sep 160
#|U!:70 879.977035 495.973220 35.156 z -128.000000 floor -128.000000 eye 40.730163
#|sound tic 393 DSPISTOL from thing 176 vol 64 sep 116
#|sound tic 395 DSPOPAIN from thing 177 vol 62 sep 50
#|L:30 879.977035 495.973220 131.835 z -128.000000 floor -128.000000 eye 41.000000
#|sound tic 408 DSPISTOL from thing 177 vol 61 sep 33
#|sound tic 414 stop thing 296
#|sound tic 420 stop thing 297
#|sound tic 455 DSPISTOL from thing 176 vol 64 sep 81
#|sound tic 457 DSPODTH2 from thing 177 vol 64 sep 47
#|sound tic 462 stop thing 298
#|U:100 784.012985 495.985015 131.835 z -128.000000 floor -128.000000 eye 41.065185
#|sound tic 541 DSPISTOL from thing 176 vol 64 sep 33
#|sound tic 545 DSPLPAIN from thing 4294967295 vol 64 sep 128
#|sound tic 548 stop thing 300
#|sound tic 565 DSPOSACT from thing 176 vol 64 sep 33
#|S:60 879.980789 495.988311 131.835 z -128.000000 floor -128.000000 eye 41.059051
#|sound tic 595 DSPISTOL from thing 176 vol 64 sep 154
#|sound tic 598 stop thing 266
#|sound tic 598 DSITEMUP from nobody vol 64 sep 128
#|sound tic 599 DSPLPAIN from thing 4294967295 vol 64 sep 128
#|sound tic 610 stop thing 301
#|D!:100 809.381698 329.453552 131.835 z -128.000000 floor -128.000000 eye 41.392669
#|sound tic 681 DSPISTOL from thing 176 vol 64 sep 155
#|sound tic 685 DSPLPAIN from thing 4294967295 vol 64 sep 128
#|sound tic 696 stop thing 302
#|R:40 791.505050 311.542190 0.000 z -128.000000 floor -128.000000 eye 41.002899
#|sound tic 771 DSPISTOL from thing 176 vol 64 sep 175
#|sound tic 786 stop thing 303
#|U!:120 879.971008 455.356948 0.000 z -128.000000 floor -128.000000 eye 41.234771
#|sound tic 841 DSPISTOL from thing 176 vol 64 sep 186
#|sound tic 845 DSPLPAIN from thing 4294967295 vol 64 sep 128
#|sound tic 848 stop thing 304
#|A!:40 879.913406 495.963928 0.000 z -128.000000 floor -128.000000 eye 41.147918
#|sound tic 39 DSPSTART from sector 98 vol 64 sep 129
#|ledge U!:47 207.783569 256.234542 0.000 z -24.000000 floor -24.000000 eye 52.658081
#|U!:1 224.302001 256.240737 0.000 z -24.000000 floor -128.000000 eye 151.570556
#|U!:1 240.820434 256.246932 0.000 z -26.000000 floor -128.000000 eye 145.000000
#|sound tic 55 DSPOSIT2 from thing 177 vol 47 sep 110
#|sound tic 61 DSOOF from thing 4294967295 vol 64 sep 128
#|sound tic 64 stop thing 268
#|sound tic 64 DSITEMUP from nobody vol 64 sep 128
#|U!:15 492.898864 256.341476 0.000 z -128.000000 floor -128.000000 eye 42.834960
#|-:1 509.055541 256.347518 0.000 z -128.000000 floor -128.000000 eye 43.033325
#|sound tic 73 DSPSTOP from sector 98 vol 46 sep 129
#|sound tic 75 stop thing 267
#|sound tic 75 DSITEMUP from nobody vol 64 sep 128
#|sound tic 75 DSPOSIT1 from thing 176 vol 57 sep 64
#|sound tic 79 DSPOSACT from thing 176 vol 59 sep 60
#|-:40 658.543090 256.402572 0.000 z -128.000000 floor -128.000000 eye 41.011581
#|the walks: sounds drew to 191, sounds drew to 175
#|weapon tic 0 state Some(60) tics 1 at 0.000000 122.000000 flash None tics 0 at 0.000000 0.000000
#|weapon tic 1 state Some(60) tics 1 at 0.000000 116.000000 flash None tics 0 at 0.000000 116.000000
#|weapon tic 14 state Some(60) tics 1 at 0.000000 38.000000 flash None tics 0 at 0.000000 38.000000
#|weapon tic 15 state Some(59) tics 1 at 1.000000 32.000000 flash None tics 0 at 1.000000 32.000000
#|weapon tic 20 state Some(59) tics 1 at 1.000000 32.000000 flash None tics 0 at 1.000000 32.000000
#|weapon tic 21 state Some(59) tics 1 at 0.941558 32.140930 flash None tics 0 at 0.941558 32.140930
#|weapon tic 22 state Some(59) tics 1 at 0.738449 32.488861 flash None tics 0 at 0.738449 32.488861
#|weapon tic 48 state Some(59) tics 1 at -0.486312 47.151641 flash None tics 0 at -0.486312 47.151641
#|weapon tic 64 state Some(59) tics 1 at 16.923339 33.562011 flash None tics 0 at 16.923339 33.562011
#|weapon tic 65 state Some(59) tics 1 at 14.884948 32.005294 flash None tics 0 at 14.884948 32.005294
#|weapon tic 124 state Some(59) tics 1 at 1.000000 32.000000 flash None tics 0 at 1.000000 32.000000
#|-
#|ready tic 20 state Some(59) tics 1 at 1.000000 32.000000 flash None tics 0 at 1.000000 32.000000 light 0 bullets 50 rnd 65
#|press tic 21 state Some(79) tics 4 at 1.000000 32.000000 flash None tics 0 at 1.000000 32.000000 light 0 bullets 50 rnd 65
#|sound tic 25 DSPISTOL from thing 4294967295 vol 64 sep 128
#|shot tic 25 state Some(80) tics 6 at 1.000000 32.000000 flash Some(83) tics 6 at 1.000000 32.000000 light 1 bullets 49 rnd 70 mobj 292 type -1 at 1323.973449 256.663757 35.437500 state 85/2
#|after tic 35 state Some(82) tics 5 at 1.000000 32.000000 flash None tics 0 at 1.000000 32.000000 light 0 bullets 49 rnd 70 mobj 292 type -1 at 1323.973449 256.663757 45.437500 state 88/4
#|sound tic 39 stop thing 292
#|gone tic 55 state Some(59) tics 1 at 1.000000 32.000000 flash None tics 0 at 1.000000 32.000000 light 0 bullets 49 rnd 70
#|held tic 20 state Some(59) tics 1 at 1.000000 32.000000 flash None tics 0 at 1.000000 32.000000 light 0 bullets 50 rnd 65
#|sound tic 25 DSPISTOL from thing 4294967295 vol 64 sep 128
#|held tic 25 state Some(80) tics 6 at 1.000000 32.000000 flash Some(83) tics 6 at 1.000000 32.000000 light 1 bullets 49 rnd 70 mobj 292 type -1 at 1323.973449 256.663757 35.437500 state 85/2
#|sound tic 39 DSPISTOL from thing 4294967295 vol 64 sep 128
#|sound tic 39 stop thing 292
#|held tic 39 state Some(80) tics 6 at 1.000000 32.000000 flash Some(83) tics 6 at 1.000000 32.000000 light 1 bullets 48 rnd 77 mobj 293 type -1 at 1324.001388 131.023986 36.343750 state 85/2
#|held tic 44 state Some(80) tics 1 at 1.000000 32.000000 flash Some(83) tics 1 at 1.000000 32.000000 light 1 bullets 48 rnd 77 mobj 293 type -1 at 1324.001388 131.023986 41.343750 state 86/1
#|last tic 20 state Some(59) tics 1 at 1.000000 32.000000 flash None tics 0 at 1.000000 32.000000 light 0 bullets 1 rnd 65
#|sound tic 25 DSPISTOL from thing 4294967295 vol 64 sep 128
#|last tic 25 state Some(80) tics 6 at 1.000000 32.000000 flash Some(83) tics 6 at 1.000000 32.000000 light 1 bullets 0 rnd 70 mobj 292 type -1 at 1323.973449 256.663757 35.437500 state 85/2
#|sound tic 39 stop thing 292
#|dry tic 44 state Some(69) tics 1 at 1.000000 92.000000 flash None tics 0 at 1.000000 92.000000 light 0 bullets 0 rnd 70
#|sound tic 5 DSPOSIT2 from thing 176 vol 60 sep 46
#|sound tic 15 DSPOSIT2 from thing 177 vol 64 sep 46
#|ledge tic 20 state Some(59) tics 1 at 1.000000 32.000000 flash None tics 0 at 1.000000 32.000000 light 0 bullets 50 rnd 75
#|sound tic 25 DSPISTOL from thing 4294967295 vol 64 sep 128
#|sound tic 25 DSPOSACT from thing 176 vol 64 sep 42
#|ledge tic 25 state Some(80) tics 6 at 1.000000 32.000000 flash Some(83) tics 6 at 1.000000 32.000000 light 1 bullets 49 rnd 83 mobj 292 type -1 at 763.999084 256.022888 -91.453125 state 85/2
#|sky tic 20 state Some(59) tics 1 at 1.000000 32.000000 flash None tics 0 at 1.000000 32.000000 light 0 bullets 50 rnd 65
#|sound tic 25 DSPISTOL from thing 4294967295 vol 64 sep 128
#|sky tic 25 state Some(80) tics 6 at 1.000000 32.000000 flash Some(83) tics 6 at 1.000000 32.000000 light 1 bullets 49 rnd 66
#|-
#|sound tic 17 DSPOSIT2 from thing 182 vol 48 sep 43
#|sound tic 17 DSPOSIT3 from thing 265 vol 64 sep 129
#|zombieman ready tic 20 at 1024.000000 -224.000000 health 100 armour 0/0 rnd 73 265 hp 20 state 89/1 at 952.000000 -224.000000 0.000000 after 157
#|sound tic 21 DSPOSIT1 from thing 185 vol 45 sep 34
#|sound tic 25 DSPISTOL from thing 4294967295 vol 64 sep 128
#|sound tic 26 DSSGTSIT from thing 184 vol 35 sep 125
#|shot tic 26 at 1024.000000 -224.000000 health 100 armour 0/0 rnd 91 265 hp 15 state 121/1 at 958.808593 -223.999572 0.000000 after 157 mobj 292 type -2 at 970.032058 -224.020599 32.750610 state 183/6
#|sound tic 27 DSPOPAIN from thing 265 vol 64 sep 129
#|sound tic 28 DSDMACT from thing 184 vol 36 sep 127
#|sound tic 32 stop thing 292
#|sound tic 38 DSPOSACT from thing 182 vol 49 sep 42
#|sound tic 39 DSPISTOL from thing 4294967295 vol 64 sep 128
#|held tic 40 at 1024.000000 -224.000000 health 100 armour 0/0 rnd 136 265 hp 10 state 121/1 at 977.521484 -223.998291 0.000000 after 157 mobj 293 type -2 at 989.786468 -223.409988 34.293869 state 183/6
#|sound tic 41 DSPOPAIN from thing 265 vol 64 sep 129
#|sound tic 46 stop thing 293
#|sound tic 53 DSPISTOL from thing 4294967295 vol 64 sep 128
#|held tic 54 at 1024.000000 -224.000000 health 100 armour 0/0 rnd 193 265 hp -5 state 123/2 at 982.773941 -209.031555 0.000000 after 157 mobj 294 type -2 at 1010.943664 -224.395660 41.234375 state 181/3 mobj 295 type 2007 at 986.506484 -210.260131 0.000000 state 35/4294967295
#|sound tic 56 DSPODTH2 from thing 265 vol 64 sep 161
#|sound tic 67 DSPISTOL from thing 4294967295 vol 64 sep 128
#|held tic 68 at 1024.000000 -224.000000 health 100 armour 0/0 rnd 229 265 hp -5 state 126/3 at 969.943405 -204.809158 0.000000 after 157 mobj 294 type -2 at 1010.943664 -224.395660 0.000000 state 183/5 mobj 295 type 2007 at 986.506484 -210.260131 0.000000 state 35/4294967295 mobj 296 type -1 at 884.002136 -223.517211 37.546875 state 86/3
#|sound tic 73 stop thing 294
#|sound tic 79 stop thing 296
#|sound tic 90 DSSHOTGN from thing 182 vol 48 sep 41
#|corpse tic 98 at 1024.000000 -224.000000 health 100 armour 0/0 rnd 49 265 hp -5 state 127/4294967295 at 966.165649 -203.567825 0.000000 after 157 mobj 295 type 2007 at 986.506484 -210.260131 0.000000 state 35/4294967295 mobj 297 type -1 at 986.418884 -163.847015 31.348739 state 87/2 mobj 298 type -1 at 1020.558197 -163.740905 28.708389 state 87/3 mobj 299 type -1 at 1091.770843 -195.430221 26.929992 state 87/1
#|kill count 1
#|sound tic 6 DSPOSIT2 from thing 240 vol 53 sep 137
#|sound tic 8 DSBGSIT1 from thing 81 vol 49 sep 165
#|sound tic 9 DSBGSIT2 from thing 82 vol 42 sep 157
#|sound tic 14 DSBGSIT2 from thing 84 vol 17 sep 78
#|sound tic 15 DSPOSACT from thing 240 vol 55 sep 131
#|barrels ready tic 20 at 992.000000 704.000000 health 100 armour 100/1 rnd 90 24 hp 20 state 11/1 at 992.000000 608.000000 -128.000000 after 4294967295 25 hp 20 state 11/4 at 992.000000 640.000000 -128.000000 after 4294967295 26 hp 20 state 10/5 at 960.000000 608.000000 -128.000000 after 4294967295
#|sound tic 25 DSPISTOL from thing 4294967295 vol 64 sep 128
#|shot tic 26 at 992.000000 704.000000 health 100 armour 100/1 rnd 110 24 hp 20 state 10/1 at 992.000000 608.000000 -128.000000 after 4294967295 25 hp 5 state 10/4 at 992.001327 636.425796 -128.000000 after 157 26 hp 20 state 11/5 at 960.000000 608.000000 -128.000000 after 4294967295 mobj 292 type -1 at 992.020584 650.032058 -102.545318 state 85/1
#|sound tic 33 DSBGACT from thing 82 vol 47 sep 149
#|sound tic 37 DSSHOTGN from thing 240 vol 56 sep 126
#|sound tic 39 DSPISTOL from thing 4294967295 vol 64 sep 128
#|sound tic 39 stop thing 292
#|sound tic 40 DSBAREXP from thing 25 vol 64 sep 128
#|held tic 40 at 991.842330 697.865051 health 88 armour 94/1 rnd 165 24 hp 20 state 11/5 at 992.000000 608.000000 -128.000000 after 4294967295 25 hp 0 state 177/5 at 992.004165 628.246276 -128.000000 after 157 26 hp 14 state 11/3 at 959.800231 605.964096 -128.000000 after 240 mobj 293 type -2 at 998.861236 707.187316 -100.334213 state 183/4 mobj 294 type -1 at 966.790679 611.998947 -97.934570 state 86/3 mobj 295 type -2 at 987.953857 718.468185 -98.442047 state 182/4 mobj 296 type -1 at 986.516006 644.633132 -100.016708 state 86/3
#|sound tic 41 DSPLPAIN from thing 4294967295 vol 64 sep 128
#|sound tic 44 stop thing 293
#|sound tic 51 stop thing 294
#|sound tic 51 stop thing 296
#|sound tic 52 stop thing 295
#|sound tic 53 DSPISTOL from thing 4294967295 vol 64 sep 128
#|sound tic 53 DSPLPAIN from thing 4294967295 vol 64 sep 128
#|sound tic 54 DSBAREXP from thing 24 vol 64 sep 128
#|sound tic 54 DSBAREXP from thing 26 vol 64 sep 163
#|held tic 54 at 991.211257 728.561431 health 31 armour 66/1 rnd 199 24 hp -98 state 177/5 at 991.994369 593.250213 -128.000000 after 4294967295 25 hp 0 state 179/6 at 992.004165 628.246276 -128.000000 after 157 26 hp -92 state 177/5 at 939.605072 586.375808 -128.000000 after 240 mobj 297 type -1 at 994.170410 580.028564 -89.593750 state 86/3
#|sound tic 58 DSFIRSHT from thing 298 vol 51 sep 149
#|burning tic 64 at 990.855346 769.131942 health 31 armour 66/1 rnd 219 24 hp -98 state 179/10 at 991.994369 593.250213 -128.000000 after 4294967295 25 hp 0 state 180/6 at 992.004165 628.246276 -128.000000 after 157 26 hp -92 state 179/10 at 939.605072 586.375808 -128.000000 after 240 mobj 297 type -1 at 994.170410 580.028564 -79.593750 state 88/1 mobj 298 type -3 at 927.402160 1031.680648 -96.000000 state 196/3
#|sound tic 65 stop thing 297
#|sound tic 70 stop thing 25
#|blast tic 74 at 990.721984 784.291122 health 31 armour 66/1 rnd 254 24 hp -98 state 180/10 at 991.994369 593.250213 -128.000000 after 4294967295 gone 26 hp -92 state 180/10 at 939.605072 586.375808 -128.000000 after 240 mobj 298 type -3 at 949.124572 934.068649 -96.000000 state 196/1
#|sound tic 75 DSPOSACT from thing 240 vol 64 sep 117
#|sound tic 84 stop thing 24
#|sound tic 84 stop thing 26
#|sound tic 87 DSFIRXPL from thing 298 vol 64 sep 177
#|sound tic 88 DSSHOTGN from thing 240 vol 64 sep 117
#|sound tic 90 DSPOPAIN from thing 81 vol 64 sep 118
#|sound tic 91 DSPLPAIN from thing 4294967295 vol 64 sep 128
#|chain tic 94 at 991.667602 790.357391 health 29 armour 65/1 rnd 64 gone gone gone mobj 298 type -3 at 975.191467 816.934249 -96.000000 state 199/4 mobj 299 type -2 at 1002.451477 913.182312 -111.315246 state 182/1 mobj 300 type -2 at 999.303100 916.909362 -108.245346 state 182/1 mobj 301 type -2 at 1004.681610 910.531097 -109.003356 state 183/1
#|sound tic 95 DSFIRSHT from thing 302 vol 56 sep 146
#|sound tic 95 stop thing 301
#|sound tic 103 stop thing 299
#|sound tic 103 stop thing 300
#|sound tic 104 DSBGACT from thing 84 vol 40 sep 81
#|sound tic 104 stop thing 298
#|sound tic 120 DSFIRSHT from thing 303 vol 64 sep 85
#|sound tic 121 DSFIRXPL from thing 302 vol 64 sep 148
#|sound tic 123 DSFIRSHT from thing 304 vol 57 sep 143
#|sound tic 125 DSPLPAIN from thing 4294967295 vol 64 sep 128
#|sound tic 125 DSFIRXPL from thing 303 vol 64 sep 121
#|sound tic 128 DSPOPAIN from thing 240 vol 64 sep 140
#|sound tic 133 DSFIRXPL from thing 304 vol 63 sep 143
#|over tic 134 at 996.130065 770.338638 health 15 armour 58/1 rnd 153 gone gone gone mobj 302 type -3 at 987.001617 815.444839 -96.000000 state 200/3 mobj 303 type -3 at 1003.404373 899.675857 -96.000000 state 200/5 mobj 304 type -3 at 966.716430 960.872467 -96.000000 state 198/3
#|-
#|sound tic 0 DSCLAW from thing 81 vol 64 sep 33
#|imp claw health 85 random 61 thing 81 type 3001 at 848.000000 1056.000000 z -128.000000 angle 270.000 sector 56 state 65 tics 8 radius 20 height 56 flags 4194310
#|demon bite health 88 random 61 thing 3 type 3002 at 2576.000000 2112.000000 z 192.000000 angle 0.000 sector 5 state 67 tics 1 radius 30 height 56 flags 4194310
#|sound tic 0 DSFIRSHT from thing 292 vol 64 sep 33
#|imp throw health 100 random 61 thing 81 type 3001 at 848.000000 1056.000000 z -128.000000 angle 270.000 sector 56 state 65 tics 8 radius 20 height 56 flags 4194310 mobj 292 type -3 at 848.001907 1051.000076 -96.000000 state 196/2
#|sound tic 0 DSFIRSHT from thing 292 vol 64 sep 128
#|sound tic 0 DSFIRXPL from thing 292 vol 64 sep 129
#|fireball wall random 62 mobj 292 type -3 at 748.999313 256.017166 -96.000000 state 199/6
#|sound tic 0 DSFIRSHT from thing 292 vol 64 sep 128
#|fireball sky random 61
#|fireball resting random 61 mobj 292 type -3 at 718.999771 256.005722 -128.000000 state 196/1
#|fireball crossing floor random 62 mobj 292 type -3 at 718.999771 256.005722 -128.000000 state 198/4
#|unarmoured flight tic 64 health 0 facing 270.000 random 186 fireball 297 hp 1000 state 196/2 at 927.402160 1031.680648 -96.000000 after 82
#|unarmoured burst tic 74 health 0 facing 270.000 random 192 fireball 297 hp 1000 state 199/2 at 933.918884 1002.397048 -96.000000 after 82
#|unarmoured gone tic 94 health 0 facing 270.000 random 195 fireball gone
#|dead player idle target 157 threshold 0 81 hp 60 state 65/6 at 928.322265 975.677734 -128.000000 after 157 target 157 threshold 0 82 hp 60 state 66/10 at 911.110351 1104.889648 -128.000000 after 157
#|imp retaliates target 240 threshold 100 81 hp 33 state 153/2 at 848.000000 1056.000000 -128.000000 after 240 random 83
#|threshold holds target 240 threshold 100 81 hp 29 state 153/2 at 848.000000 1056.000000 -128.000000 after 240 random 84
#|barrel credits player target 157 threshold 99 81 hp 56 state 105/3 at 842.262695 1050.262695 -128.000000 after 157 random 62
#|shotgun imp fight target 240 threshold 87 81 hp 15 state 108/3 at 891.248580 1056.017028 -128.000000 after 240 target 81 threshold 99 240 hp 12 state 189/7 at 982.616607 1055.972488 -128.000000 after 81 random 132
#|player barrel blast target 4294967295 threshold 0 81 hp -68 state 160/2 at 848.000000 1056.000000 -128.000000 after 4294967295 target 157 threshold 99 240 hp 10 state 97/2 at 956.762649 1050.263641 -128.000000 after 157 target 157 threshold 100 82 hp 24 state 153/1 at 848.634658 1172.454956 -128.000000 after 157 gone 24 hp -108 state 176/5 at 832.000000 1056.000000 -128.000000 after 157 random 67
#|-
#|sound tic 6 DSPOSIT3 from thing 240 vol 55 sep 148
#|sound tic 8 DSBGSIT1 from thing 81 vol 62 sep 159
#|sound tic 9 DSBGSIT1 from thing 82 vol 58 sep 192
#|clip walk tic 9 644.340896 991.988937 180.000 z -128.000000 floor -128.000000 eye 42.770172
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 209 taken message 0 "" tics 0
#|sound tic 10 stop thing 140
#|sound tic 10 DSITEMUP from nobody vol 64 sep 128
#|- tic 10 639.121368 991.986862 180.000 z -128.000000 floor -128.000000 eye 42.064453
#|  inventory health 100 armour 0 type 0 cards 0 ammo 60 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 6 things 208 taken 140 message 9 "Picked up a clip." tics 140
#|sounds drew to 77
#|shells walk tic 8 1082.761047 -223.991744 0.000 z 0.000000 floor 0.000000 eye 43.090270
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 209 taken message 0 "" tics 0
#|sound tic 9 stop thing 276
#|sound tic 9 DSITEMUP from nobody vol 64 sep 128
#|- tic 9 1087.658264 -223.989990 0.000 z 0.000000 floor 0.000000 eye 42.770034
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 4 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 6 things 208 taken 276 message 13 "Picked up 4 shotgun shells." tics 140
#|sounds drew to 73
#|sound tic 11 DSPOSIT3 from thing 185 vol 47 sep 224
#|sound tic 17 DSPOSIT1 from thing 182 vol 44 sep 203
#|sound tic 17 DSPOSIT2 from thing 265 vol 64 sep 129
#|sound tic 18 stop thing 208
#|sound tic 18 DSITEMUP from nobody vol 64 sep 128
#|sound tic 25 DSPOSACT from thing 265 vol 62 sep 129
#|sound tic 26 stop thing 207
#|sound tic 26 DSITEMUP from nobody vol 64 sep 128
#|- tic 26 1202.337890 -223.948562 0.000 z 0.000000 floor 0.000000 eye 48.388656
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 12 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 6 things 206 taken 207 208 276 message 13 "Picked up 4 shotgun shells." tics 140
#|shells walk at the cap tic 8 1082.761047 -223.991744 0.000 z 0.000000 floor 0.000000 eye 43.090270
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 50 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 209 taken message 0 "" tics 0
#|- tic 9 1087.658264 -223.989990 0.000 z 0.000000 floor 0.000000 eye 42.770034
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 50 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 209 taken message 0 "" tics 0
#|sounds drew to 73
#|sound tic 11 DSPOSIT3 from thing 185 vol 47 sep 224
#|sound tic 17 DSPOSIT1 from thing 182 vol 44 sep 203
#|sound tic 17 DSPOSIT2 from thing 265 vol 64 sep 129
#|sound tic 25 DSPOSACT from thing 265 vol 62 sep 129
#|- tic 26 1202.337890 -223.948562 0.000 z 0.000000 floor 0.000000 eye 48.388656
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 50 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 209 taken message 0 "" tics 0
#|rocket walk tic 8 677.238296 -1000.009109 180.000 z 0.000000 floor 0.000000 eye 43.090423
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 209 taken message 0 "" tics 0
#|sound tic 9 stop thing 279
#|sound tic 9 DSITEMUP from nobody vol 64 sep 128
#|- tic 9 672.340896 -1000.011062 180.000 z 0.000000 floor 0.000000 eye 42.770172
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 1 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 6 things 208 taken 279 message 11 "Picked up a rocket." tics 140
#|sounds drew to 73
#|rocket walk at the cap tic 8 677.238296 -1000.009109 180.000 z 0.000000 floor 0.000000 eye 43.090423
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 50 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 209 taken message 0 "" tics 0
#|- tic 9 672.340896 -1000.011062 180.000 z 0.000000 floor 0.000000 eye 42.770172
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 50 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 209 taken message 0 "" tics 0
#|sounds drew to 73
#|-
#|sound tic 39 DSPOSACT from thing 240 vol 48 sep 192
#|shell box walk tic 51 509.810287 711.963989 180.000 z -128.000000 floor -128.000000 eye 41.140472
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 209 taken message 0 "" tics 0
#|sound tic 52 stop thing 137
#|sound tic 52 DSITEMUP from nobody vol 64 sep 128
#|- tic 52 502.640411 711.961120 180.000 z -128.000000 floor -128.000000 eye 39.155944
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 20 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 6 things 208 taken 137 message 14 "Picked up a box of shotgun shells." tics 140
#|sounds drew to 124
#|-
#|sound tic 39 DSPOSACT from thing 240 vol 48 sep 192
#|shell box walk short of the cap tic 51 509.810287 711.963989 180.000 z -128.000000 floor -128.000000 eye 41.140472
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 45 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 209 taken message 0 "" tics 0
#|sound tic 52 stop thing 137
#|sound tic 52 DSITEMUP from nobody vol 64 sep 128
#|- tic 52 502.640411 711.961120 180.000 z -128.000000 floor -128.000000 eye 39.155944
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 50 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 6 things 208 taken 137 message 14 "Picked up a box of shotgun shells." tics 140
#|sounds drew to 124
#|-
#|sound tic 39 DSPOSACT from thing 240 vol 48 sep 192
#|shell box walk at the cap tic 51 509.810287 711.963989 180.000 z -128.000000 floor -128.000000 eye 41.140472
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 50 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 209 taken message 0 "" tics 0
#|- tic 52 502.640411 711.961120 180.000 z -128.000000 floor -128.000000 eye 39.155944
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 50 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 209 taken message 0 "" tics 0
#|sounds drew to 124
#|-
#|sound tic 23 DSDMACT from thing 98 vol 37 sep 79
#|chainsaw strafe tic 33 3141.789398 2136.822265 157.500 z 194.000000 floor 194.000000 eye 30.035858
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 209 taken message 0 "" tics 0
#|sound tic 34 stop thing 2
#|sound tic 34 DSWPNUP from nobody vol 64 sep 128
#|- tic 34 3139.581390 2131.485961 157.500 z 194.000000 floor 194.000000 eye 30.413955
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 131 powers 0 0 0 0 0 0 items 0 flash 6 things 208 taken 2 message 15 "A chainsaw!  Find some meat!" tics 140
#|sounds drew to 102
#|sound tic 23 DSDMACT from thing 98 vol 37 sep 79
#|sound tic 30 DSSAWUP from thing 4294967295 vol 64 sep 128
#|owned chainsaw strafe tic 33 3141.789398 2136.822265 157.500 z 194.000000 floor 194.000000 eye 30.035858
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 131 powers 0 0 0 0 0 0 items 0 flash 0 things 209 taken message 15 "A chainsaw!  Find some meat!" tics 107
#|- tic 34 3139.581390 2131.485961 157.500 z 194.000000 floor 194.000000 eye 30.413955
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 131 powers 0 0 0 0 0 0 items 0 flash 0 things 209 taken message 15 "A chainsaw!  Find some meat!" tics 106
#|sounds drew to 102
#|health bonus tic 11 470.388839 256.013870 0.000 z -128.000000 floor -128.000000 eye 41.015975
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 209 taken message 0 "" tics 0
#|sound tic 12 stop thing 268
#|sound tic 12 DSITEMUP from nobody vol 64 sep 128
#|- tic 12 476.164627 256.015945 0.000 z -128.000000 floor -128.000000 eye 39.730026
#|  inventory health 101 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 1 flash 6 things 208 taken 268 message 3 "Picked up a health bonus." tics 140
#|sounds drew to 76
#|health bonus at 200 tic 11 470.388839 256.013870 0.000 z -128.000000 floor -128.000000 eye 41.015975
#|  inventory health 200 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 209 taken message 0 "" tics 0
#|sound tic 12 stop thing 268
#|sound tic 12 DSITEMUP from nobody vol 64 sep 128
#|- tic 12 476.164627 256.015945 0.000 z -128.000000 floor -128.000000 eye 39.730026
#|  inventory health 200 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 1 flash 6 things 208 taken 268 message 3 "Picked up a health bonus." tics 140
#|sounds drew to 76
#|stimpack at 100 tic 11 -32.015335 438.388839 90.000 z 0.000000 floor 0.000000 eye 41.015975
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 209 taken message 0 "" tics 0
#|- tic 12 -32.017639 444.164627 90.000 z 0.000000 floor 0.000000 eye 39.730026
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 209 taken message 0 "" tics 0
#|sounds drew to 76
#|- tic 22 -32.040420 495.976776 90.000 z 0.000000 floor 0.000000 eye 41.022888
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 209 taken message 0 "" tics 0
#|stimpack at 60 tic 11 -32.015335 438.388839 90.000 z 0.000000 floor 0.000000 eye 41.015975
#|  inventory health 60 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 209 taken message 0 "" tics 0
#|sound tic 12 stop thing 215
#|sound tic 12 DSITEMUP from nobody vol 64 sep 128
#|- tic 12 -32.017639 444.164627 90.000 z 0.000000 floor 0.000000 eye 39.730026
#|  inventory health 70 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 6 things 208 taken 215 message 5 "Picked up a stimpack." tics 140
#|sounds drew to 76
#|medikit at 100 tic 11 31.984664 438.388839 90.000 z 0.000000 floor 0.000000 eye 41.015975
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 209 taken message 0 "" tics 0
#|- tic 12 31.982360 444.164627 90.000 z 0.000000 floor 0.000000 eye 39.730026
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 209 taken message 0 "" tics 0
#|sounds drew to 76
#|medikit at 60 tic 11 31.984664 438.388839 90.000 z 0.000000 floor 0.000000 eye 41.015975
#|  inventory health 60 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 209 taken message 0 "" tics 0
#|sound tic 12 stop thing 259
#|sound tic 12 DSITEMUP from nobody vol 64 sep 128
#|- tic 12 31.982360 444.164627 90.000 z 0.000000 floor 0.000000 eye 39.730026
#|  inventory health 85 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 6 things 208 taken 259 message 6 "Picked up a medikit." tics 140
#|sounds drew to 76
#|berserk at 100 tic 11 607.984664 438.388839 90.000 z 0.000000 floor 0.000000 eye 41.015975
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 209 taken message 0 "" tics 0
#|sound tic 12 stop thing 291
#|sound tic 12 DSGETPOW from nobody vol 64 sep 128
#|- tic 12 607.982360 444.164627 90.000 z 0.000000 floor 0.000000 eye 39.730026
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 1 0 0 0 0 items 1 flash 6 things 208 taken 291 message 8 "Berserk!" tics 140
#|sounds drew to 77
#|- tic 22 607.968032 479.134338 90.000 z 0.000000 floor 0.000000 eye 41.174743
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 11 0 0 0 0 items 1 flash 0 things 208 taken 291 message 8 "Berserk!" tics 130
#|berserk at 60 tic 11 607.984664 438.388839 90.000 z 0.000000 floor 0.000000 eye 41.015975
#|  inventory health 60 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 209 taken message 0 "" tics 0
#|sound tic 12 stop thing 291
#|sound tic 12 DSGETPOW from nobody vol 64 sep 128
#|- tic 12 607.982360 444.164627 90.000 z 0.000000 floor 0.000000 eye 39.730026
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 1 0 0 0 0 items 1 flash 6 things 208 taken 291 message 8 "Berserk!" tics 140
#|sounds drew to 77
#|sound tic 11 DSPOSIT3 from thing 185 vol 43 sep 34
#|armour bonus tic 11 624.013870 -758.390090 270.000 z 0.000000 floor 0.000000 eye 41.015975
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 209 taken message 0 "" tics 0
#|sound tic 12 stop thing 204
#|sound tic 12 DSITEMUP from nobody vol 64 sep 128
#|- tic 12 624.015945 -764.166107 270.000 z 0.000000 floor 0.000000 eye 39.729934
#|  inventory health 100 armour 1 type 1 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 1 flash 6 things 208 taken 204 message 4 "Picked up an armor bonus." tics 140
#|sounds drew to 77
#|sound tic 4 DSBGSIT1 from thing 85 vol 35 sep 217
#|sound tic 6 DSPOSIT3 from thing 240 vol 30 sep 33
#|sound tic 8 DSBGSIT1 from thing 81 vol 23 sep 33
#|sound tic 9 DSBGSIT1 from thing 82 vol 20 sep 34
#|green armour tic 11 1663.984664 1046.388839 90.000 z -144.000000 floor -144.000000 eye 41.015975
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 209 taken message 0 "" tics 0
#|sound tic 12 DSBGACT from thing 82 vol 21 sep 33
#|sound tic 12 stop thing 6
#|sound tic 12 DSITEMUP from nobody vol 64 sep 128
#|- tic 12 1663.982360 1052.164627 90.000 z -144.000000 floor -144.000000 eye 39.730026
#|  inventory health 100 armour 100 type 1 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 6 things 208 taken 6 message 1 "Picked up the armor." tics 140
#|sounds drew to 81
#|sound tic 4 DSBGSIT1 from thing 85 vol 35 sep 217
#|sound tic 6 DSPOSIT3 from thing 240 vol 30 sep 33
#|sound tic 8 DSBGSIT1 from thing 81 vol 23 sep 33
#|sound tic 9 DSBGSIT1 from thing 82 vol 20 sep 34
#|green armour at 100 tic 11 1663.984664 1046.388839 90.000 z -144.000000 floor -144.000000 eye 41.015975
#|  inventory health 100 armour 100 type 1 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 209 taken message 0 "" tics 0
#|sound tic 12 DSBGACT from thing 82 vol 21 sep 33
#|- tic 12 1663.982360 1052.164627 90.000 z -144.000000 floor -144.000000 eye 39.730026
#|  inventory health 100 armour 100 type 1 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 209 taken message 0 "" tics 0
#|sounds drew to 81
#|-
#|nukage tic 1 1600.000000 1000.000000 90.000 z -168.000000 floor -168.000000 eye 41.000000 health 95 armour 0 type 0 momentum 0.000000 0.000000 state 71/3 damage 4 attacker 4294967295 state Some(60) tics 1 at 0.000000 116.000000 flash None tics 0 at 0.000000 116.000000 random 62 reborn False
#|sound tic 4 DSBGSIT1 from thing 85 vol 32 sep 219
#|sound tic 4 DSPLPAIN from thing 4294967295 vol 64 sep 128
#|- tic 4 1600.000000 1000.000000 90.000 z -168.000000 floor -168.000000 eye 41.000000 health 95 armour 0 type 0 momentum 0.000000 0.000000 state 72/4 damage 1 attacker 4294967295 state Some(60) tics 1 at 0.000000 98.000000 flash None tics 0 at 0.000000 98.000000 random 66 reborn False
#|sound tic 6 DSPOSIT2 from thing 240 vol 34 sep 33
#|sound tic 8 DSBGSIT2 from thing 81 vol 26 sep 33
#|- tic 8 1600.000000 1000.000000 90.000 z -168.000000 floor -168.000000 eye 41.000000 health 95 armour 0 type 0 momentum 0.000000 0.000000 state 70/4294967295 damage 0 attacker 4294967295 state Some(60) tics 1 at 0.000000 74.000000 flash None tics 0 at 0.000000 74.000000 random 77 reborn False
#|sound tic 9 DSBGSIT2 from thing 82 vol 23 sep 35
#|sound tic 14 DSBGSIT2 from thing 84 vol 45 sep 91
#|sound tic 16 DSBGACT from thing 85 vol 34 sep 220
#|sound tic 28 DSBGACT from thing 85 vol 36 sep 220
#|- tic 33 1600.000000 1000.000000 90.000 z -168.000000 floor -168.000000 eye 41.000000 health 90 armour 0 type 0 momentum 0.000000 0.000000 state 71/3 damage 4 attacker 4294967295 state Some(59) tics 1 at 1.000000 32.000000 flash None tics 0 at 1.000000 32.000000 random 133 reborn False
#|sound tic 36 DSPLPAIN from thing 4294967295 vol 64 sep 128
#|- tic 37 1600.000000 1000.000000 90.000 z -168.000000 floor -168.000000 eye 41.000000 health 90 armour 0 type 0 momentum 0.000000 0.000000 state 72/3 damage 0 attacker 4294967295 state Some(59) tics 1 at 1.000000 32.000000 flash None tics 0 at 1.000000 32.000000 random 141 reborn False
#|green armour nukage tic 1 1600.000000 1000.000000 90.000 z -168.000000 floor -168.000000 eye 41.000000 health 96 armour 99 type 1 momentum 0.000000 0.000000 state 71/3 damage 3 attacker 4294967295 state Some(60) tics 1 at 0.000000 116.000000 flash None tics 0 at 0.000000 116.000000 random 62 reborn False
#|green armour worn out tic 1 1600.000000 1000.000000 90.000 z -168.000000 floor -168.000000 eye 41.000000 health 96 armour 0 type 0 momentum 0.000000 0.000000 state 71/3 damage 3 attacker 4294967295 state Some(60) tics 1 at 0.000000 116.000000 flash None tics 0 at 0.000000 116.000000 random 62 reborn False
#|blue armour nukage tic 1 1600.000000 1000.000000 90.000 z -168.000000 floor -168.000000 eye 41.000000 health 97 armour 98 type 2 momentum 0.000000 0.000000 state 71/3 damage 2 attacker 4294967295 state Some(60) tics 1 at 0.000000 116.000000 flash None tics 0 at 0.000000 116.000000 random 62 reborn False
#|sounds drew to 110
#|-
#|sound tic 4 DSBGSIT1 from thing 85 vol 32 sep 219
#|sound tic 4 DSPLPAIN from thing 4294967295 vol 64 sep 128
#|sound tic 6 DSPOSIT2 from thing 240 vol 34 sep 33
#|sound tic 8 DSBGSIT2 from thing 81 vol 26 sep 33
#|sound tic 9 DSBGSIT2 from thing 82 vol 23 sep 35
#|sound tic 14 DSBGSIT2 from thing 84 vol 45 sep 91
#|sound tic 16 DSBGACT from thing 85 vol 34 sep 220
#|sound tic 28 DSBGACT from thing 85 vol 36 sep 220
#|sound tic 36 DSPLPAIN from thing 4294967295 vol 64 sep 128
#|sound tic 63 DSFIRSHT from thing 292 vol 32 sep 33
#|sound tic 68 DSPLPAIN from thing 4294967295 vol 64 sep 128
#|sound tic 77 DSFIRXPL from thing 292 vol 42 sep 33
#|sound tic 80 DSPOPAIN from thing 240 vol 44 sep 33
#|sound tic 93 DSFIRSHT from thing 293 vol 56 sep 83
#|sound tic 93 stop thing 292
#|sound tic 100 DSPLPAIN from thing 4294967295 vol 64 sep 128
#|sound tic 118 DSFIRXPL from thing 293 vol 64 sep 84
#|sound tic 122 DSPLPAIN from thing 4294967295 vol 64 sep 128
#|sound tic 129 DSSHOTGN from thing 240 vol 48 sep 33
#|sound tic 131 DSPOPAIN from thing 81 vol 40 sep 33
#|sound tic 134 stop thing 293
#|sound tic 136 stop thing 294
#|sound tic 137 DSFIRSHT from thing 297 vol 34 sep 216
#|sound tic 143 stop thing 295
#|sound tic 144 DSBGACT from thing 84 vol 62 sep 98
#|sound tic 144 stop thing 296
#|sound tic 149 DSFIRSHT from thing 298 vol 40 sep 33
#|sound tic 155 DSFIRXPL from thing 298 vol 44 sep 33
#|sound tic 158 DSPOPAIN from thing 240 vol 46 sep 33
#|sound tic 164 DSPLPAIN from thing 4294967295 vol 64 sep 128
#|sound tic 170 stop thing 298
#|sound tic 175 DSFIRSHT from thing 299 vol 48 sep 33
#|sound tic 180 DSSHOTGN from thing 240 vol 45 sep 33
#|sound tic 182 DSPOPAIN from thing 81 vol 41 sep 33
#|sound tic 187 stop thing 300
#|sound tic 187 stop thing 302
#|sound tic 195 DSFIRXPL from thing 297 vol 64 sep 204
#|sound tic 199 DSFIRSHT from thing 303 vol 64 sep 77
#|sound tic 199 DSPLPAIN from thing 4294967295 vol 64 sep 128
#|sound tic 203 stop thing 301
#|sound tic 204 DSFIRSHT from thing 304 vol 38 sep 213
#|sound tic 206 DSCLAW from thing 81 vol 41 sep 33
#|sound tic 208 DSFIRXPL from thing 303 vol 64 sep 105
#|sound tic 210 stop thing 297
#|sound tic 212 DSPLPAIN from thing 4294967295 vol 64 sep 128
#|sound tic 214 DSBGACT from thing 84 vol 64 sep 94
#|sound tic 223 stop thing 303
#|sound tic 228 DSFIRSHT from thing 305 vol 41 sep 33
#|sound tic 228 DSPLPAIN from thing 4294967295 vol 64 sep 128
#|sound tic 233 DSFIRXPL from thing 305 vol 45 sep 33
#|sound tic 234 DSSHOTGN from thing 240 vol 47 sep 33
#|sound tic 236 DSFIRSHT from thing 309 vol 64 sep 101
#|sound tic 240 DSBGDTH2 from thing 81 vol 40 sep 33
#|sound tic 241 stop thing 306
#|sound tic 244 DSFIRXPL from thing 309 vol 64 sep 101
#|sound tic 248 DSFIRXPL from thing 299 vol 56 sep 223
#|sound tic 249 stop thing 307
#|sound tic 249 stop thing 308
#|sound tic 250 stop thing 305
#|sound tic 252 DSPLDETH from thing 4294967295 vol 64 sep 128
#|sound tic 260 stop thing 309
#|sound tic 264 stop thing 299
#|sound tic 272 DSFIRXPL from thing 304 vol 62 sep 74
#|sound tic 288 stop thing 304
#|nukage until it kills tic 608 1616.825195 910.197158 104.848 z -168.000000 floor -168.000000 eye 6.000000 health 0 armour 0 type 0 momentum 0.000000 0.000000 state 0/4294967295 damage 0 attacker 84 state Some(69) tics 1 at 1.000747 128.000000 flash None tics 0 at 1.000747 128.000000 random 152 reborn False
#|death tic 609 1616.825195 910.197158 104.848 z -168.000000 floor -168.000000 eye 6.000000 health 0 armour 0 type 0 momentum 0.000000 0.000000 state 0/4294967295 damage 0 attacker 84 state Some(69) tics 1 at 1.000747 128.000000 flash None tics 0 at 1.000747 128.000000 random 153 reborn False
#|- tic 615 1616.825195 910.197158 104.848 z -168.000000 floor -168.000000 eye 6.000000 health 0 armour 0 type 0 momentum 0.000000 0.000000 state 0/4294967295 damage 0 attacker 84 state Some(69) tics 1 at 1.000747 128.000000 flash None tics 0 at 1.000747 128.000000 random 154 reborn False
#|- tic 616 1616.825195 910.197158 104.848 z -168.000000 floor -168.000000 eye 6.000000 health 0 armour 0 type 0 momentum 0.000000 0.000000 state 0/4294967295 damage 0 attacker 84 state Some(69) tics 1 at 1.000747 128.000000 flash None tics 0 at 1.000747 128.000000 random 154 reborn False
#|- tic 623 1616.825195 910.197158 104.848 z -168.000000 floor -168.000000 eye 6.000000 health 0 armour 0 type 0 momentum 0.000000 0.000000 state 0/4294967295 damage 0 attacker 84 state Some(69) tics 1 at 1.000747 128.000000 flash None tics 0 at 1.000747 128.000000 random 154 reborn False
#|- tic 650 1616.825195 910.197158 104.848 z -168.000000 floor -168.000000 eye 6.000000 health 0 armour 0 type 0 momentum 0.000000 0.000000 state 0/4294967295 damage 0 attacker 84 state Some(69) tics 1 at 1.000747 128.000000 flash None tics 0 at 1.000747 128.000000 random 154 reborn False
#|- tic 682 1616.825195 910.197158 104.848 z -168.000000 floor -168.000000 eye 6.000000 health 0 armour 0 type 0 momentum 0.000000 0.000000 state 0/4294967295 damage 0 attacker 84 state Some(69) tics 1 at 1.000747 128.000000 flash None tics 0 at 1.000747 128.000000 random 159 reborn False
#|use tic 683 1616.825195 910.197158 104.848 z -168.000000 floor -168.000000 eye 6.000000 health 0 armour 0 type 0 momentum 0.000000 0.000000 state 0/4294967295 damage 0 attacker 84 state Some(69) tics 1 at 1.000747 128.000000 flash None tics 0 at 1.000747 128.000000 random 159 reborn True
#|- tic 684 1616.825195 910.197158 104.848 z -168.000000 floor -168.000000 eye 6.000000 health 0 armour 0 type 0 momentum 0.000000 0.000000 state 0/4294967295 damage 0 attacker 84 state Some(69) tics 1 at 1.000747 128.000000 flash None tics 0 at 1.000747 128.000000 random 159 reborn True
#|sounds drew to 26
#|-
#|blow from the south tic 0 0.000000 0.000000 0.000 z 0.000000 floor 0.000000 eye 41.000000 health 80 armour 0 type 0 momentum 0.000946 2.499954 state 71/4 damage 20 attacker 0 state Some(60) tics 1 at 0.000000 122.000000 flash None tics 0 at 0.000000 0.000000 random 1 reborn False
#|- tic 1 0.000946 2.499954 0.000 z 0.000000 floor 0.000000 eye 41.000289 health 80 armour 0 type 0 momentum 0.000854 2.265579 state 71/3 damage 19 attacker 0 state Some(60) tics 1 at 0.000000 116.000000 flash None tics 0 at 0.000000 116.000000 random 1 reborn False
#|lethal blow from below tic 0 0.000000 0.000000 0.000 z 0.000000 floor 0.000000 eye 41.000000 health 0 armour 0 type 0 momentum -0.003814 -9.999847 state 73/10 damage 20 attacker 0 state Some(69) tics 1 at 0.000000 128.000000 flash None tics 0 at 0.000000 0.000000 random 3 reborn False
#|- tic 1 -0.003814 -9.999847 354.995 z 0.000000 floor 0.000000 eye 40.003051 health 0 armour 0 type 0 momentum -0.003463 -9.062362 state 73/9 damage 20 attacker 0 state Some(69) tics 1 at 0.000000 128.000000 flash None tics 0 at 0.000000 128.000000 random 3 reborn False
#|sound tic 10 DSPLDETH from thing 4294967295 vol 64 sep 128
#|- tic 17 -0.033691 -86.656158 274.998 z 0.000000 floor 0.000000 eye 23.489440 health 0 armour 0 type 0 momentum -0.000778 -1.875976 state 74/3 damage 20 attacker 0 state Some(69) tics 1 at 0.000000 128.000000 flash None tics 0 at 0.000000 128.000000 random 3 reborn False
#|- tic 18 -0.034469 -88.532135 270.000 z 0.000000 floor 0.000000 eye 22.642181 health 0 armour 0 type 0 momentum -0.000717 -1.700103 state 74/2 damage 20 attacker 0 state Some(69) tics 1 at 0.000000 128.000000 flash None tics 0 at 0.000000 128.000000 random 3 reborn False
#|- tic 19 -0.035186 -90.232238 270.000 z 0.000000 floor 0.000000 eye 21.785339 health 0 armour 0 type 0 momentum -0.000656 -1.540725 state 74/1 damage 19 attacker 0 state Some(69) tics 1 at 0.000000 128.000000 flash None tics 0 at 0.000000 128.000000 random 3 reborn False
#|- tic 20 -0.035842 -91.772964 270.000 z 0.000000 floor 0.000000 eye 20.905944 health 0 armour 0 type 0 momentum -0.000595 -1.396286 state 75/10 damage 18 attacker 0 state Some(69) tics 1 at 0.000000 128.000000 flash None tics 0 at 0.000000 128.000000 random 3 reborn False
#|sounds drew to 85
#|-
#|sound tic 10 DSPLDETH from thing 4294967295 vol 64 sep 128
#|corpse slide tic 20 626.112716 992.000000 180.000 z -128.000000 floor -128.000000 eye 20.976486
#|  inventory health 0 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 209 taken message 0 "" tics 0
#|sound tic 6 DSPOSIT3 from thing 240 vol 54 sep 148
#|sound tic 8 DSBGSIT1 from thing 81 vol 61 sep 157
#|sound tic 8 stop thing 140
#|sound tic 8 DSITEMUP from nobody vol 64 sep 128
#|sound tic 9 DSBGSIT1 from thing 82 vol 57 sep 191
#|sound tic 12 DSBGACT from thing 82 vol 58 sep 189
#|sound tic 14 DSBGSIT1 from thing 84 vol 12 sep 173
#|sound tic 17 DSBGACT from thing 81 vol 62 sep 148
#|live slide tic 20 626.112716 992.000000 180.000 z -128.000000 floor -128.000000 eye 40.976486
#|  inventory health 100 armour 0 type 0 cards 0 ammo 60 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 208 taken 140 message 9 "Picked up a clip." tics 128
#|-
#|face tic 1 index 2 health 100 drew 1
#|face tic 18 index 0 health 100 drew 82
#|face tic 35 index 2 health 100 drew 99
#|glance tic 60 index 2 count 8 health 100 sounds drew to 124
#|face tic 1 index 5 health 95 drew 1
#|face tic 36 index 2 health 90 drew 109
#|face tic 53 index 1 health 90 drew 126
#|face tic 65 index 7 health 85 drew 139
#|face tic 118 index 23 health 59 drew 198
#|face tic 173 index 18 health 54 drew 6
#|face tic 193 index 23 health 49 drew 29
#|face tic 195 index 27 health 37 drew 32
#|nukage tic 200 index 27 count 34 health 37 sounds drew to 39
#|face tic 208 index 39 health 13 drew 50
#|face tic 244 index 41 health 0 drew 95
#|nukage until it kills tic 660 index 41 count 0 health 0 sounds drew to 2
#|face tic 2 index 3 health 80 drew 66
#|blow from the right tic 4 index 3 count 34 health 80 sounds drew to 68
#|face tic 2 index 4 health 80 drew 66
#|blow from the left tic 4 index 4 count 34 health 80 sounds drew to 68
#|face tic 2 index 7 health 80 drew 66
#|blow from dead ahead tic 4 index 7 count 34 health 80 sounds drew to 68
#|shotgun guy hit tic 61 index 15 count 34 health 73 sounds drew to 128
#|face tic 34 index 6 health 100 drew 102
#|chainsaw grin tic 37 index 6 count 66 health 100 sounds drew to 105
#|face tic 1 index 2 health 100 drew 1
#|face tic 18 index 0 health 100 drew 82
#|face tic 35 index 1 health 100 drew 101
#|face tic 52 index 2 health 100 drew 119
#|face tic 69 index 1 health 100 drew 137
#|face tic 71 index 7 health 100 drew 139
#|held fire tic 90 index 7 count 0 health 100 sounds drew to 160
#|face tic 1 index 2 health 100 drew 1
#|face tic 18 index 0 health 100 drew 82
#|face tic 35 index 1 health 100 drew 101
#|face tic 52 index 2 health 100 drew 119
#|face tic 69 index 1 health 100 drew 137
#|held before release tic 69 index 1 count 16 health 100 sounds drew to 137
#|release during firing tic 70 index 1 count 15 health 100 sounds drew to 138
#|face tic 71 index 7 health 100 drew 139
#|held after release tic 90 index 7 count 0 health 100 sounds drew to 160
#|-
#|sound tic 5 DSPOSIT2 from thing 176 vol 64 sep 65
#|sound tic 37 DSPOSACT from thing 176 vol 64 sep 126
#|door walk tic 40 871.990203 392.135299 90.000 z -128.000000 floor -128.000000 eye 38.394653 thinkers 9 sector 10 -128.000000 -128.000000
#|use tic 41 871.987243 392.135299 90.000 z -128.000000 floor -128.000000 eye 40.876480 thinkers 9 sector 10 -128.000000 -128.000000
#|- tic 61 871.961898 432.886016 90.000 z -128.000000 floor -128.000000 eye 40.996353 thinkers 9 sector 10 -128.000000 -128.000000
#|sound tic 69 DSDOROPN from sector 10 vol 64 sep 89
#|sound tic 76 DSPOSIT3 from thing 240 vol 34 sep 142
#|sound tic 78 DSBGSIT1 from thing 81 vol 36 sep 125
#|sound tic 79 DSBGSIT2 from thing 82 vol 29 sep 125
#|- tic 102 871.955490 442.302398 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -60.000000
#|- tic 103 871.955490 442.302398 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -58.000000
#|sound tic 127 DSPISTOL from thing 176 vol 64 sep 130
#|sound tic 131 DSPLPAIN from thing 4294967295 vol 64 sep 128
#|sound tic 134 stop thing 292
#|sound tic 145 DSFIRSHT from thing 293 vol 41 sep 119
#|sound tic 155 DSSHOTGN from thing 240 vol 46 sep 130
#|sound tic 162 stop thing 296
#|sound tic 169 stop thing 295
#|sound tic 170 stop thing 294
#|sound tic 178 DSFIRXPL from thing 293 vol 64 sep 119
#|sound tic 181 DSPODTH3 from thing 176 vol 64 sep 131
#|sound tic 188 DSFIRSHT from thing 298 vol 45 sep 121
#|sound tic 195 stop thing 293
#|sound tic 223 DSBGACT from thing 82 vol 46 sep 139
#|sound tic 231 DSFIRSHT from thing 299 vol 48 sep 130
#|sound tic 232 DSFIRXPL from thing 298 vol 64 sep 121
#|sound tic 233 DSSHOTGN from thing 240 vol 54 sep 131
#|sound tic 236 DSPLPAIN from thing 4294967295 vol 64 sep 128
#|sound tic 237 DSFIRXPL from thing 299 vol 52 sep 130
#|sound tic 240 DSPOPAIN from thing 240 vol 54 sep 131
#|sound tic 245 stop thing 300
#|sound tic 246 stop thing 302
#|sound tic 247 stop thing 301
#|sound tic 249 stop thing 298
#|sound tic 252 stop thing 299
#|- tic 253 872.111999 431.430877 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -4.000000
#|- tic 254 872.111999 431.430877 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -4.000000
#|sound tic 259 DSSHOTGN from thing 240 vol 56 sep 132
#|sound tic 261 DSPOPAIN from thing 81 vol 52 sep 129
#|sound tic 266 stop thing 305
#|sound tic 274 stop thing 304
#|sound tic 280 stop thing 303
#|sound tic 281 DSDORCLS from sector 10 vol 64 sep 92
#|sound tic 285 DSFIRSHT from thing 306 vol 51 sep 129
#|sound tic 296 DSFIRXPL from thing 306 vol 58 sep 132
#|sound tic 299 DSPOPAIN from thing 240 vol 60 sep 133
#|sound tic 312 stop thing 306
#|- tic 315 872.111999 431.430877 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -72.000000
#|- tic 316 872.111999 431.430877 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -74.000000
#|sound tic 259 DSSHOTGN from thing 240 vol 56 sep 132
#|sound tic 261 DSPOPAIN from thing 81 vol 52 sep 129
#|closing - tic 264 872.111999 431.430877 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -4.000000
#|use tic 265 872.111999 431.430877 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -4.000000
#|sound tic 266 stop thing 305
#|sound tic 274 stop thing 304
#|- tic 275 872.111999 431.430877 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -4.000000
#|- tic 279 872.111999 431.430877 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -4.000000
#|sound tic 280 stop thing 303
#|use tic 280 872.111999 431.430877 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -4.000000
#|sounds drew to 110
#|-
#|sound tic 127 DSPISTOL from thing 176 vol 64 sep 132
#|sound tic 131 DSPLPAIN from thing 4294967295 vol 64 sep 128
#|sound tic 134 stop thing 292
#|through walk tic 142 871.652679 486.467025 90.000 z -128.000000 floor -128.000000 eye 42.967407 thinkers 10 sector 10 -128.000000 -4.000000
#|doorway walk tic 108 871.949859 456.372085 90.000 z -128.000000 floor -128.000000 eye 42.444900 thinkers 10 sector 10 -128.000000 -48.000000
#|sound tic 127 DSPISTOL from thing 176 vol 64 sep 132
#|sound tic 131 DSPLPAIN from thing 4294967295 vol 64 sep 128
#|sound tic 134 stop thing 292
#|sound tic 145 DSFIRSHT from thing 293 vol 44 sep 118
#|sound tic 155 DSSHOTGN from thing 240 vol 49 sep 130
#|sound tic 162 stop thing 296
#|sound tic 169 stop thing 295
#|sound tic 170 stop thing 294
#|sound tic 178 DSFIRXPL from thing 293 vol 64 sep 118
#|sound tic 181 DSPODTH3 from thing 176 vol 64 sep 132
#|sound tic 188 DSFIRSHT from thing 298 vol 48 sep 121
#|sound tic 195 stop thing 293
#|sound tic 223 DSBGACT from thing 82 vol 49 sep 141
#|sound tic 227 DSFIRXPL from thing 298 vol 64 sep 120
#|sound tic 231 DSFIRSHT from thing 299 vol 51 sep 130
#|sound tic 231 DSPLPAIN from thing 4294967295 vol 64 sep 128
#|sound tic 233 DSSHOTGN from thing 240 vol 57 sep 131
#|sound tic 237 DSFIRXPL from thing 299 vol 55 sep 129
#|sound tic 240 DSPOPAIN from thing 240 vol 57 sep 131
#|sound tic 243 stop thing 298
#|sound tic 245 stop thing 300
#|sound tic 246 stop thing 302
#|sound tic 247 stop thing 301
#|sound tic 254 stop thing 299
#|sound tic 281 DSDORCLS from sector 10 vol 64 sep 76
#|- tic 287 873.423400 465.515304 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -16.000000
#|- tic 288 873.423400 465.515304 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -18.000000
#|sound tic 289 DSSHOTGN from thing 240 vol 64 sep 133
#|- tic 289 873.423400 465.515304 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -20.000000
#|sound tic 291 DSPOPAIN from thing 81 vol 59 sep 129
#|sound tic 296 stop thing 304
#|sound tic 296 stop thing 305
#|sound tic 309 stop thing 303
#|sound tic 318 DSPOSACT from thing 240 vol 64 sep 134
#|- tic 323 873.423400 465.515304 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -88.000000
#|sounds drew to 155
#|-
#|sound tic 69 DSDOROPN from sector 10 vol 64 sep 89
#|sound tic 76 DSPOSIT3 from thing 240 vol 34 sep 142
#|sound tic 78 DSBGSIT1 from thing 81 vol 36 sep 125
#|sound tic 79 DSBGSIT2 from thing 82 vol 29 sep 125
#|sound tic 127 DSPISTOL from thing 176 vol 64 sep 130
#|sound tic 131 DSPLPAIN from thing 4294967295 vol 64 sep 128
#|sound tic 134 stop thing 292
#|held use tic 140 871.868591 436.527603 90.000 z -128.000000 floor -128.000000 eye 40.997543 thinkers 10 sector 10 -128.000000 -4.000000
#|sound tic 145 DSFIRSHT from thing 293 vol 41 sep 119
#|sound tic 155 DSSHOTGN from thing 240 vol 46 sep 130
#|sound tic 162 stop thing 296
#|sound tic 169 stop thing 295
#|sound tic 170 stop thing 294
#|sound tic 178 DSFIRXPL from thing 293 vol 64 sep 119
#|sound tic 181 DSPODTH3 from thing 176 vol 64 sep 131
#|sound tic 188 DSFIRSHT from thing 298 vol 45 sep 121
#|sound tic 195 stop thing 293
#|sound tic 223 DSBGACT from thing 82 vol 46 sep 139
#|sound tic 231 DSFIRSHT from thing 299 vol 48 sep 130
#|sound tic 232 DSFIRXPL from thing 298 vol 64 sep 121
#|sound tic 233 DSSHOTGN from thing 240 vol 54 sep 131
#|sound tic 236 DSPLPAIN from thing 4294967295 vol 64 sep 128
#|sound tic 237 DSFIRXPL from thing 299 vol 52 sep 130
#|sound tic 240 DSPOPAIN from thing 240 vol 54 sep 131
#|sound tic 245 stop thing 300
#|sound tic 246 stop thing 302
#|sound tic 247 stop thing 301
#|sound tic 249 stop thing 298
#|sound tic 252 stop thing 299
#|sound tic 259 DSSHOTGN from thing 240 vol 56 sep 132
#|sound tic 261 DSPOPAIN from thing 81 vol 52 sep 129
#|sound tic 266 stop thing 305
#|sound tic 274 stop thing 304
#|sound tic 280 stop thing 303
#|sound tic 281 DSDORCLS from sector 10 vol 64 sep 92
#|sound tic 285 DSFIRSHT from thing 306 vol 51 sep 129
#|sound tic 296 DSFIRXPL from thing 306 vol 58 sep 132
#|sound tic 299 DSPOPAIN from thing 240 vol 60 sep 133
#|sound tic 312 stop thing 306
#|sound tic 322 DSFIRSHT from thing 307 vol 53 sep 129
#|sound tic 336 DSSHOTGN from thing 240 vol 64 sep 134
#|sound tic 336 DSFIRXPL from thing 307 vol 62 sep 132
#|sound tic 338 DSPOPAIN from thing 81 vol 54 sep 129
#|sound tic 338 DSPODTH3 from thing 240 vol 64 sep 134
#|use tic 340 872.111999 431.430877 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -122.000000
#|sounds drew to 179
#|-
#|sound tic 160 DSPOSACT from thing 240 vol 28 sep 33
#|sound tic 205 DSPOSACT from thing 240 vol 36 sep 33
#|sound tic 214 DSBGACT from thing 82 vol 28 sep 33
#|sound tic 229 DSPOSACT from thing 176 vol 61 sep 33
#|door on the left tic 253 832.000000 128.000000 0.000 z 0.000000 floor 0.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -4.000000
#|sounds drew to 71
#|sound tic 160 DSPOSACT from thing 240 vol 28 sep 224
#|sound tic 205 DSPOSACT from thing 240 vol 36 sep 224
#|sound tic 214 DSBGACT from thing 82 vol 28 sep 224
#|sound tic 229 DSPOSACT from thing 176 vol 61 sep 224
#|door on the right tic 253 832.000000 128.000000 180.000 z 0.000000 floor 0.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -4.000000
#|sounds drew to 71
#|sound tic 160 DSPOSACT from thing 240 vol 28 sep 124
#|sound tic 205 DSPOSACT from thing 240 vol 36 sep 123
#|sound tic 214 DSBGACT from thing 82 vol 28 sep 128
#|sound tic 229 DSPOSACT from thing 176 vol 61 sep 137
#|door behind tic 253 832.000000 128.000000 270.000 z 0.000000 floor 0.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -4.000000
#|sounds drew to 71
#|sound tic 127 DSPISTOL from thing 176 vol 62 sep 148
#|sound tic 141 stop thing 292
#|sound tic 154 DSPOSACT from thing 240 vol 40 sep 135
#|sound tic 165 DSPISTOL from thing 176 vol 64 sep 141
#|sound tic 179 stop thing 293
#|sound tic 203 DSFIRSHT from thing 294 vol 36 sep 128
#|sound tic 205 DSPOSACT from thing 240 vol 49 sep 137
#|sound tic 211 DSPISTOL from thing 176 vol 64 sep 126
#|sound tic 220 DSFIRXPL from thing 294 vol 47 sep 128
#|sound tic 221 DSSHOTGN from thing 240 vol 49 sep 137
#|sound tic 224 DSPOPAIN from thing 177 vol 64 sep 33
#|sound tic 224 stop thing 295
#|sound tic 226 DSFIRSHT from thing 300 vol 49 sep 127
#|sound tic 226 DSPODTH2 from thing 176 vol 64 sep 124
#|sound tic 228 stop thing 299
#|sound tic 236 stop thing 294
#|sound tic 236 stop thing 296
#|sound tic 237 DSPISTOL from thing 177 vol 64 sep 33
#|sound tic 242 stop thing 297
#|sound tic 244 stop thing 301
#|door 200 ahead tic 253 832.000000 328.000000 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -4.000000
#|sounds drew to 79
#|sound tic 127 DSPISTOL from thing 176 vol 62 sep 148
#|sound tic 141 stop thing 292
#|sound tic 154 DSPOSACT from thing 240 vol 40 sep 135
#|sound tic 165 DSPISTOL from thing 176 vol 64 sep 141
#|sound tic 179 stop thing 293
#|sound tic 203 DSFIRSHT from thing 294 vol 36 sep 128
#|sound tic 205 DSPOSACT from thing 240 vol 49 sep 137
#|sound tic 211 DSPISTOL from thing 176 vol 64 sep 126
#|sound tic 220 DSFIRXPL from thing 294 vol 47 sep 128
#|sound tic 221 DSSHOTGN from thing 240 vol 49 sep 137
#|sound tic 224 DSPOPAIN from thing 177 vol 64 sep 33
#|sound tic 224 stop thing 295
#|sound tic 226 DSFIRSHT from thing 300 vol 49 sep 127
#|sound tic 226 DSPODTH2 from thing 176 vol 64 sep 124
#|sound tic 228 stop thing 299
#|sound tic 236 stop thing 294
#|sound tic 236 stop thing 296
#|sound tic 237 DSPISTOL from thing 177 vol 64 sep 33
#|sound tic 242 stop thing 297
#|sound tic 244 stop thing 301
#|door 201 ahead tic 253 832.000000 327.000000 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -4.000000
#|sounds drew to 79
#|sound tic 111 DSPOSIT3 from thing 185 vol 58 sep 224
#|sound tic 180 DSPOSACT from thing 185 vol 58 sep 224
#|sound tic 220 DSSHOTGN from thing 185 vol 59 sep 224
#|sound tic 224 DSPLPAIN from thing 4294967295 vol 64 sep 128
#|sound tic 227 stop thing 292
#|sound tic 234 stop thing 294
#|sound tic 235 stop thing 293
#|door 1184 ahead tic 253 832.000000 -655.915191 90.000 z -8.000000 floor -8.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -4.000000
#|sounds drew to 71
#|sound tic 111 DSPOSIT3 from thing 185 vol 58 sep 224
#|sound tic 180 DSPOSACT from thing 185 vol 58 sep 224
#|sound tic 220 DSSHOTGN from thing 185 vol 59 sep 224
#|sound tic 224 DSPLPAIN from thing 4294967295 vol 64 sep 128
#|sound tic 227 stop thing 292
#|sound tic 234 stop thing 294
#|sound tic 235 stop thing 293
#|door 1185 ahead tic 253 832.000000 -656.928131 90.000 z -8.000000 floor -8.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -4.000000
#|sounds drew to 71
#|sound tic 111 DSPOSIT3 from thing 185 vol 59 sep 224
#|sound tic 138 DSPOSACT from thing 185 vol 59 sep 224
#|sound tic 157 DSSHOTGN from thing 185 vol 59 sep 224
#|sound tic 161 DSPLPAIN from thing 4294967295 vol 64 sep 128
#|sound tic 164 stop thing 294
#|sound tic 170 stop thing 293
#|sound tic 172 stop thing 292
#|sound tic 173 DSPOSACT from thing 176 vol 4 sep 126
#|sound tic 189 DSPOSACT from thing 176 vol 6 sep 128
#|sound tic 202 DSSHOTGN from thing 185 vol 59 sep 224
#|sound tic 214 stop thing 297
#|sound tic 215 stop thing 296
#|sound tic 216 stop thing 295
#|door 1201 ahead tic 253 832.000000 -673.055709 90.000 z -8.000000 floor -8.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -4.000000
#|sounds drew to 74
#|-
#|switch walk tic 30 2063.945510 -240.021331 90.000 z 136.000000 floor 136.000000 eye 41.024505 thinkers 9 sector 76 272.000000 272.000000 sector 126 264.000000 264.000000 sector 129 264.000000 264.000000
#|sound tic 31 DSSWTCHN from nobody vol 64 sep 128
#|use tic 31 2063.943267 -240.021331 90.000 z 136.000000 floor 136.000000 eye 41.000000 thinkers 12 sector 76 271.000000 272.000000 sector 126 263.000000 264.000000 sector 129 263.000000 264.000000
#|sound tic 33 DSSTNMOV from sector 76 vol 51 sep 204
#|sound tic 33 DSSTNMOV from sector 126 vol 51 sep 204
#|sound tic 33 DSSTNMOV from sector 129 vol 26 sep 77
#|sound tic 41 DSSTNMOV from sector 76 vol 51 sep 204
#|sound tic 41 DSSTNMOV from sector 126 vol 51 sep 204
#|sound tic 41 DSSTNMOV from sector 129 vol 26 sep 77
#|sound tic 49 DSSTNMOV from sector 76 vol 51 sep 204
#|sound tic 49 DSSTNMOV from sector 126 vol 51 sep 204
#|sound tic 49 DSSTNMOV from sector 129 vol 26 sep 77
#|sound tic 57 DSSTNMOV from sector 76 vol 51 sep 204
#|sound tic 57 DSSTNMOV from sector 126 vol 51 sep 204
#|sound tic 57 DSSTNMOV from sector 129 vol 26 sep 77
#|sound tic 65 DSSTNMOV from sector 76 vol 51 sep 204
#|sound tic 65 DSSTNMOV from sector 126 vol 51 sep 204
#|sound tic 65 DSSTNMOV from sector 129 vol 26 sep 77
#|sound tic 73 DSSTNMOV from sector 76 vol 51 sep 204
#|sound tic 73 DSSTNMOV from sector 126 vol 51 sep 204
#|sound tic 73 DSSTNMOV from sector 129 vol 26 sep 77
#|sound tic 81 DSSTNMOV from sector 76 vol 51 sep 204
#|sound tic 81 DSSTNMOV from sector 126 vol 51 sep 204
#|sound tic 81 DSSTNMOV from sector 129 vol 26 sep 77
#|sound tic 89 DSSTNMOV from sector 76 vol 51 sep 204
#|sound tic 89 DSSTNMOV from sector 126 vol 51 sep 204
#|sound tic 89 DSSTNMOV from sector 129 vol 26 sep 77
#|sound tic 97 DSSTNMOV from sector 76 vol 51 sep 204
#|sound tic 97 DSSTNMOV from sector 126 vol 51 sep 204
#|sound tic 97 DSSTNMOV from sector 129 vol 26 sep 77
#|sound tic 105 DSSTNMOV from sector 76 vol 51 sep 204
#|sound tic 105 DSSTNMOV from sector 126 vol 51 sep 204
#|sound tic 105 DSSTNMOV from sector 129 vol 26 sep 77
#|sound tic 113 DSSTNMOV from sector 76 vol 51 sep 204
#|sound tic 113 DSSTNMOV from sector 126 vol 51 sep 204
#|sound tic 113 DSSTNMOV from sector 129 vol 26 sep 77
#|sound tic 121 DSSTNMOV from sector 76 vol 51 sep 204
#|sound tic 121 DSSTNMOV from sector 126 vol 51 sep 204
#|sound tic 121 DSSTNMOV from sector 129 vol 26 sep 77
#|sound tic 129 DSSTNMOV from sector 76 vol 51 sep 204
#|sound tic 129 DSSTNMOV from sector 126 vol 51 sep 204
#|sound tic 129 DSSTNMOV from sector 129 vol 26 sep 77
#|sound tic 137 DSSTNMOV from sector 76 vol 51 sep 204
#|sound tic 137 DSSTNMOV from sector 126 vol 51 sep 204
#|sound tic 137 DSSTNMOV from sector 129 vol 26 sep 77
#|sound tic 145 DSSTNMOV from sector 76 vol 51 sep 204
#|sound tic 145 DSSTNMOV from sector 126 vol 51 sep 204
#|sound tic 145 DSSTNMOV from sector 129 vol 26 sep 77
#|- tic 150 2063.943267 -240.021331 90.000 z 136.000000 floor 136.000000 eye 41.000000 thinkers 12 sector 76 152.000000 272.000000 sector 126 144.000000 264.000000 sector 129 144.000000 264.000000
#|sound tic 151 DSPSTOP from sector 126 vol 51 sep 204
#|- tic 151 2063.943267 -240.021331 90.000 z 136.000000 floor 136.000000 eye 41.000000 thinkers 11 sector 76 151.000000 272.000000 sector 126 144.000000 264.000000 sector 129 143.000000 264.000000
#|sound tic 153 DSSTNMOV from sector 76 vol 51 sep 204
#|sound tic 153 DSSTNMOV from sector 129 vol 26 sep 77
#|- tic 158 2063.943267 -240.021331 90.000 z 136.000000 floor 136.000000 eye 41.000000 thinkers 11 sector 76 144.000000 272.000000 sector 126 144.000000 264.000000 sector 129 136.000000 264.000000
#|sound tic 159 DSPSTOP from sector 129 vol 26 sep 77
#|- tic 159 2063.943267 -240.021331 90.000 z 136.000000 floor 136.000000 eye 41.000000 thinkers 10 sector 76 143.000000 272.000000 sector 126 144.000000 264.000000 sector 129 136.000000 264.000000
#|sound tic 161 DSSTNMOV from sector 76 vol 51 sep 204
#|- tic 166 2063.943267 -240.021331 90.000 z 136.000000 floor 136.000000 eye 41.000000 thinkers 10 sector 76 136.000000 272.000000 sector 126 144.000000 264.000000 sector 129 136.000000 264.000000
#|sound tic 167 DSPSTOP from sector 76 vol 51 sep 204
#|- tic 167 2063.943267 -240.021331 90.000 z 136.000000 floor 136.000000 eye 41.000000 thinkers 9 sector 76 136.000000 272.000000 sector 126 144.000000 264.000000 sector 129 136.000000 264.000000
#|sound tic 168 DSNOWAY from thing 4294967295 vol 64 sep 128
#|use tic 168 2063.943267 -240.021331 90.000 z 136.000000 floor 136.000000 eye 41.000000 thinkers 9 sector 76 136.000000 272.000000 sector 126 144.000000 264.000000 sector 129 136.000000 264.000000
#|sounds drew to 29
#|-
#|sound tic 3 DSBGSIT1 from thing 243 vol 53 sep 218
#|sound tic 4 DSBGSIT2 from thing 190 vol 44 sep 68
#|sound tic 5 DSPOSIT2 from thing 189 vol 49 sep 60
#|trigger walk tic 16 2029.450805 -449.974945 0.000 z 128.000000 floor 128.000000 eye 35.541717 thinkers 9 sector 145 136.000000 136.000000
#|sound tic 17 DSDOROPN from sector 145 vol 45 sep 156
#|over tic 17 2036.220657 -449.972503 0.000 z 128.000000 floor 128.000000 eye 35.539337 thinkers 10 sector 145 136.000000 138.000000
#|sound tic 19 DSBGACT from thing 190 vol 52 sep 58
#|sound tic 30 DSBGACT from thing 243 vol 55 sep 205
#|sound tic 72 DSSHOTGN from thing 189 vol 63 sep 59
#|sound tic 76 DSPLPAIN from thing 4294967295 vol 64 sep 128
#|sound tic 78 stop thing 292
#|- tic 78 2097.389953 -453.829498 0.000 z 128.000000 floor 128.000000 eye 40.950988 thinkers 10 sector 145 136.000000 260.000000
#|- tic 79 2096.960357 -454.281051 0.000 z 128.000000 floor 128.000000 eye 40.970077 thinkers 9 sector 145 136.000000 260.000000
#|sound tic 80 stop thing 293
#|sound tic 80 stop thing 294
#|sound tic 84 stop thing 296
#|sound tic 85 stop thing 295
#|sound tic 87 stop thing 297
#|sound tic 91 DSBGACT from thing 190 vol 60 sep 96
#|sound tic 105 DSBGSIT2 from thing 241 vol 48 sep 34
#|back tic 119 1943.006134 -458.662643 0.000 z 128.000000 floor 128.000000 eye 35.955810 thinkers 9 sector 145 136.000000 260.000000
#|sounds drew to 193
#|sound tic 1 DSDOROPN from sector 145 vol 45 sep 156
#|split crossing 2045.000000 -450.000000 0.000 z 128.000000 floor 128.000000 eye 41.003051
#|-
#|lift run tic 35 11.349639 256.160812 0.000 z 0.000000 floor 0.000000 eye 33.430175 thinkers 9 sector 98 12.000000 128.000000
#|- tic 39 62.115066 256.179794 0.000 z 12.000000 floor 12.000000 eye 25.687744 thinkers 9 sector 98 12.000000 128.000000
#|sound tic 40 DSPSTART from sector 98 vol 64 sep 129
#|over tic 40 71.977874 256.183471 0.000 z 8.000000 floor 8.000000 eye 33.644653 thinkers 10 sector 98 8.000000 128.000000
#|- tic 73 163.614135 256.215759 0.000 z -124.000000 floor -124.000000 eye 44.989715 thinkers 10 sector 98 -124.000000 128.000000
#|sound tic 74 DSPSTOP from sector 98 vol 64 sep 129
#|- tic 74 163.961135 256.215820 0.000 z -124.000000 floor -124.000000 eye 40.988113 thinkers 10 sector 98 -124.000000 128.000000
#|sound tic 179 DSPSTART from sector 98 vol 64 sep 129
#|- tic 179 166.744613 256.215911 0.000 z -124.000000 floor -124.000000 eye 41.000000 thinkers 10 sector 98 -124.000000 128.000000
#|- tic 180 166.744613 256.215911 0.000 z -120.000000 floor -120.000000 eye 37.000000 thinkers 10 sector 98 -120.000000 128.000000
#|- tic 213 166.744613 256.215911 0.000 z 12.000000 floor 12.000000 eye 37.000000 thinkers 10 sector 98 12.000000 128.000000
#|sound tic 214 DSPSTOP from sector 98 vol 64 sep 129
#|- tic 214 166.744613 256.215911 0.000 z 12.000000 floor 12.000000 eye 41.000000 thinkers 9 sector 98 12.000000 128.000000
#|lift switch walk tic 10 208.160308 255.986923 180.000 z -124.000000 floor -124.000000 eye 40.314453 thinkers 9 sector 98 12.000000 128.000000
#|sound tic 11 DSPSTART from sector 98 vol 64 sep 129
#|use tic 11 208.160308 255.986602 180.000 z -124.000000 floor -124.000000 eye 40.500000 thinkers 10 sector 98 8.000000 128.000000
#|- tic 12 208.160308 255.986602 180.000 z -124.000000 floor -124.000000 eye 41.000000 thinkers 10 sector 98 4.000000 128.000000
#|use tic 13 208.160308 255.986602 180.000 z -124.000000 floor -124.000000 eye 41.000000 thinkers 10 sector 98 0.000000 128.000000
#|sound tic 15 DSPOSIT3 from thing 177 vol 39 sep 142
#|sound tic 45 DSPSTOP from sector 98 vol 64 sep 129
#|sound tic 47 DSPOSACT from thing 177 vol 44 sep 134
#|sound tic 119 DSPOSACT from thing 177 vol 51 sep 127
#|sound tic 150 DSPSTART from sector 98 vol 64 sep 129
#|sound tic 177 DSPISTOL from thing 177 vol 55 sep 135
#|- tic 184 208.160308 255.986602 180.000 z -124.000000 floor -124.000000 eye 41.000000 thinkers 10 sector 98 12.000000 128.000000
#|sound tic 185 DSPSTOP from sector 98 vol 64 sep 129
#|- tic 185 208.160308 255.986602 180.000 z -124.000000 floor -124.000000 eye 41.000000 thinkers 9 sector 98 12.000000 128.000000
#|sound tic 186 DSPSTART from sector 98 vol 64 sep 129
#|use tic 186 208.160308 255.986602 180.000 z -124.000000 floor -124.000000 eye 41.000000 thinkers 10 sector 98 8.000000 128.000000
#|sounds drew to 3
#|-
#|key turn tic 21 2246.000000 592.000000 157.500 z 136.000000 floor 136.000000 eye 41.000000 thinkers 9 sector 71 -128.000000 -128.000000 key True things 209 cards 0 flash 0 message 0 "" tics 0
#|strafe tic 33 2229.789398 552.822265 157.500 z 136.000000 floor 136.000000 eye 38.785858 thinkers 9 sector 71 -128.000000 -128.000000 key True things 209 cards 0 flash 0 message 0 "" tics 0
#|sound tic 34 stop thing 87
#|sound tic 34 DSITEMUP from nobody vol 64 sep 128
#|- tic 34 2227.581390 547.485961 157.500 z 136.000000 floor 136.000000 eye 37.663955 thinkers 9 sector 71 -128.000000 -128.000000 key False things 208 cards 1 flash 12 message 7 "Picked up a blue keycard." tics 140
#|- tic 44 2202.145187 486.011810 157.500 z 136.000000 floor 136.000000 eye 46.122497 thinkers 9 sector 71 -128.000000 -128.000000 key False things 208 cards 1 flash 2 message 7 "Picked up a blue keycard." tics 130
#|blue walk with the skull tic 30 831.941818 1463.978836 90.000 z -128.000000 floor -128.000000 eye 41.024505 thinkers 9 sector 71 -128.000000 -128.000000 key True things 209 cards 8 flash 0 message 0 "" tics 0
#|sound tic 31 DSDOROPN from sector 71 vol 64 sep 129
#|use tic 31 831.939605 1463.978836 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 71 -128.000000 -126.000000 key True things 209 cards 8 flash 0 message 0 "" tics 0
#|sound tic 34 DSPOSIT2 from thing 94 vol 49 sep 144
#|sound tic 40 DSPOSIT1 from thing 95 vol 57 sep 101
#|- tic 41 831.939605 1463.978836 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 71 -128.000000 -106.000000 key True things 209 cards 8 flash 0 message 0 "" tics 0
#|sound tic 52 DSPOSACT from thing 94 vol 53 sep 135
#|sound tic 67 DSPOSACT from thing 94 vol 55 sep 127
#|- tic 92 831.939605 1463.978836 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 71 -128.000000 -4.000000 key True things 209 cards 8 flash 0 message 0 "" tics 0
#|sounds drew to 161
#|-
#|exit first tic use tic 1 -352.000000 1296.000000 180.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 9 ended none special 11
#|sound tic 5 DSPOSIT2 from thing 289 vol 64 sep 33
#|- tic 20 -352.000000 1296.000000 180.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 9 ended none special 11
#|sound tic 21 DSSWTCHN from nobody vol 64 sep 128
#|use tic 21 -352.000000 1296.000000 180.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 9 ended normal special 0
#|walk held use tic 21 -352.000000 1296.000000 180.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 9 ended normal special 0
#|sounds drew to 87
#|-
#|states tic 0 2:45/4294967295 6:6/2 87:24/1 24:10/3 121:18/1 144:12/2 172:51/5
#|states tic 1 2:45/4294967295 6:6/1 87:25/10 24:10/2 121:19/6 144:12/1 172:51/4
#|states tic 2 2:45/4294967295 6:7/7 87:25/9 24:10/1 121:19/5 144:13/6 172:51/3
#|states tic 3 2:45/4294967295 6:7/6 87:25/8 24:11/6 121:19/4 144:13/5 172:51/2
#|states tic 4 2:45/4294967295 6:7/5 87:25/7 24:11/5 121:19/3 144:13/4 172:51/1
#|states tic 5 2:45/4294967295 6:7/4 87:25/6 24:11/4 121:19/2 144:13/3 172:52/8
#|states tic 13 2:45/4294967295 6:6/2 87:24/8 24:10/2 121:21/6 144:14/1 172:51/6
#|states tic 23 2:45/4294967295 6:6/5 87:25/8 24:10/4 121:22/2 144:16/3 172:52/4
#|states tic 35 2:45/4294967295 6:6/6 87:24/6 24:10/4 121:18/2 144:12/3 172:52/6
#|states tic 36 2:45/4294967295 6:6/5 87:24/5 24:10/3 121:18/1 144:12/2 172:52/5
#|lights tic 0 sector 32 176 sector 33 176 sector 48 140 sector 90 192
#|lights tic 1 sector 32 176 sector 33 140 sector 48 120 sector 90 160
#|lights tic 8 sector 32 176 sector 33 176 sector 48 140 sector 90 160
#|lights tic 9 sector 32 176 sector 33 176 sector 48 120 sector 90 160
#|lights tic 15 sector 32 176 sector 33 176 sector 48 140 sector 90 160
#|lights tic 35 sector 32 176 sector 33 176 sector 48 140 sector 90 160
#|lights tic 36 sector 32 176 sector 33 176 sector 48 140 sector 90 192
#|lights tic 41 sector 32 176 sector 33 176 sector 48 140 sector 90 160
#|lights tic 65 sector 32 144 sector 33 176 sector 48 140 sector 90 160
#|lights tic 70 sector 32 176 sector 33 176 sector 48 140 sector 90 160
#|lights tic 71 sector 32 176 sector 33 140 sector 48 140 sector 90 160
#|lights tic 76 sector 32 176 sector 33 140 sector 48 140 sector 90 192
#|lights tic 77 sector 32 176 sector 33 176 sector 48 140 sector 90 192
#|lights tic 80 sector 32 176 sector 33 176 sector 48 120 sector 90 192
#|lights tic 81 sector 32 176 sector 33 176 sector 48 120 sector 90 160
#|lights tic 82 sector 32 176 sector 33 176 sector 48 140 sector 90 160
#|lights tic 83 sector 32 176 sector 33 176 sector 48 120 sector 90 160
#|lights tic 91 sector 32 176 sector 33 176 sector 48 140 sector 90 160
#|lights tic 135 sector 32 144 sector 33 176 sector 48 140 sector 90 160
#|lights tic 142 sector 32 176 sector 33 140 sector 48 140 sector 90 160
#|lights tic 144 sector 32 176 sector 33 176 sector 48 140 sector 90 160
#|end
#|column walk tic 37 -191.972503 1635.776504 270.000 z -128.000000 floor -128.000000 eye 35.523132 thinkers 9
#|- tic 38 -191.970001 1635.776504 270.000 z -128.000000 floor -128.000000 eye 36.104217 thinkers 9
#|- tic 48 -191.942932 1635.776504 270.000 z -128.000000 floor -128.000000 eye 47.252609 thinkers 9
#|corpse walk tic 30 128.011886 399.121368 270.000 z 0.000000 floor 0.000000 eye 42.094177 thinkers 9
#|- tic 38 128.029998 348.859802 270.000 z 0.000000 floor 0.000000 eye 36.104217 thinkers 9
#|sound tic 21 stop thing 266
#|sound tic 21 DSITEMUP from nobody vol 64 sep 128
#|sound tic 37 DSPOSACT from thing 176 vol 64 sep 64
#|zombieman walk tic 44 831.949234 410.794219 90.000 z -128.000000 floor -128.000000 eye 46.679534 thinkers 9
#|- tic 64 831.902633 495.978729 90.000 z -128.000000 floor -128.000000 eye 41.060394 thinkers 9
#|sound tic 6 DSPOSIT3 from thing 177 vol 40 sep 143
#|column lift switch walk tic 10 208.160308 255.986923 180.000 z -124.000000 floor -124.000000 eye 40.314453 thinkers 9 sector 98 12.000000 128.000000 thing 3 type 48 z 12.000000 floor 12.000000 ceiling 128.000000 state 58 tics 4294967295
#|sound tic 11 DSPSTART from sector 98 vol 64 sep 129
#|use tic 11 208.160308 255.986602 180.000 z -124.000000 floor -124.000000 eye 40.500000 thinkers 10 sector 98 8.000000 128.000000 thing 3 type 48 z 8.000000 floor 8.000000 ceiling 128.000000 state 58 tics 4294967295
#|- tic 12 208.160308 255.986602 180.000 z -124.000000 floor -124.000000 eye 41.000000 thinkers 10 sector 98 4.000000 128.000000 thing 3 type 48 z 4.000000 floor 4.000000 ceiling 128.000000 state 58 tics 4294967295
#|- tic 44 208.160308 255.986602 180.000 z -124.000000 floor -124.000000 eye 41.000000 thinkers 10 sector 98 -124.000000 128.000000 thing 3 type 48 z -124.000000 floor -124.000000 ceiling 128.000000 state 58 tics 4294967295
#|sound tic 45 DSPSTOP from sector 98 vol 64 sep 129
#|- tic 45 208.160308 255.986602 180.000 z -124.000000 floor -124.000000 eye 41.000000 thinkers 10 sector 98 -124.000000 128.000000 thing 3 type 48 z -124.000000 floor -124.000000 ceiling 128.000000 state 58 tics 4294967295
#|sound tic 46 DSPOSACT from thing 177 vol 45 sep 132
#|sound tic 72 DSPISTOL from thing 177 vol 47 sep 128
#|sound tic 84 stop thing 292
#|sound tic 150 DSPSTART from sector 98 vol 64 sep 129
#|- tic 150 208.160308 255.986602 180.000 z -124.000000 floor -124.000000 eye 41.000000 thinkers 10 sector 98 -124.000000 128.000000 thing 3 type 48 z -124.000000 floor -124.000000 ceiling 128.000000 state 58 tics 4294967295
#|sound tic 174 DSPISTOL from thing 177 vol 56 sep 128
#|sound tic 178 DSPLPAIN from thing 4294967295 vol 64 sep 128
#|sound tic 181 stop thing 293
#|- tic 184 208.007965 255.986999 180.000 z -124.000000 floor -124.000000 eye 41.000000 thinkers 10 sector 98 12.000000 128.000000 thing 3 type 48 z 12.000000 floor 12.000000 ceiling 128.000000 state 58 tics 4294967295
#|sound tic 4 DSPOSIT3 from thing 176 vol 64 sep 65
#|barrel door walk tic 40 871.986938 392.114837 90.000 z -128.000000 floor -128.000000 eye 38.394653 thinkers 9 sector 10 -128.000000 -128.000000 thing 35 type 2035 z -128.000000 floor -128.000000 ceiling -128.000000 state 11 tics 5
#|use tic 41 871.983978 392.114837 90.000 z -128.000000 floor -128.000000 eye 40.876480 thinkers 9 sector 10 -128.000000 -128.000000 thing 35 type 2035 z -128.000000 floor -128.000000 ceiling -128.000000 state 11 tics 4
#|sound tic 50 DSPISTOL from thing 176 vol 64 sep 126
#|sound tic 54 DSPLPAIN from thing 4294967295 vol 64 sep 128
#|sound tic 57 stop thing 292
#|sound tic 88 DSPISTOL from thing 176 vol 64 sep 126
#|sound tic 92 DSPLPAIN from thing 4294967295 vol 64 sep 128
#|- tic 102 872.318511 392.379150 90.000 z -128.000000 floor -128.000000 eye 41.003234 thinkers 9 sector 10 -128.000000 -128.000000 thing 35 type 2035 z -128.000000 floor -128.000000 ceiling -128.000000 state 11 tics 3
#|sound tic 103 stop thing 293
#|sound tic 120 DSDOROPN from sector 10 vol 64 sep 101
#|sound tic 130 DSBGSIT1 from thing 81 vol 33 sep 125
#|sound tic 146 DSPISTOL from thing 176 vol 64 sep 127
#|sound tic 150 DSPLPAIN from thing 4294967295 vol 64 sep 128
#|sound tic 153 stop thing 294
#|sound tic 155 DSPOSIT2 from thing 240 vol 31 sep 141
#|sound tic 186 DSSHOTGN from thing 240 vol 35 sep 136
#|sound tic 188 DSPOPAIN from thing 81 vol 39 sep 137
#|sound tic 193 stop thing 295
#|sound tic 193 stop thing 296
#|sound tic 193 stop thing 297
#|sound tic 200 DSPISTOL from thing 176 vol 64 sep 79
#|sound tic 204 DSPLPAIN from thing 4294967295 vol 64 sep 128
#|sound tic 207 stop thing 298
#|sound tic 217 DSBGACT from thing 81 vol 45 sep 128
#|sound tic 222 DSSHOTGN from thing 240 vol 36 sep 134
#|sound tic 224 DSPOPAIN from thing 81 vol 46 sep 126
#|sound tic 225 DSPOPAIN from thing 176 vol 64 sep 103
#|sound tic 229 stop thing 300
#|sound tic 237 stop thing 299
#|sound tic 237 stop thing 301
#|sound tic 242 DSFIRSHT from thing 302 vol 46 sep 125
#|sound tic 252 DSFIRXPL from thing 302 vol 40 sep 132
#|sound tic 266 stop thing 302
#|sound tic 279 DSSHOTGN from thing 240 vol 40 sep 126
#|sound tic 281 DSPOPAIN from thing 81 vol 43 sep 126
#|sound tic 286 stop thing 303
#|sound tic 286 stop thing 304
#|sound tic 294 stop thing 305
#|- tic 294 870.777114 390.815048 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -4.000000 thing 35 type 2035 z -128.000000 floor -128.000000 ceiling -4.000000 state 11 tics 3
#|- tic 295 870.777114 390.815048 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -4.000000 thing 35 type 2035 z -128.000000 floor -128.000000 ceiling -4.000000 state 11 tics 2
#|- tic 296 870.777114 390.815048 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -4.000000 thing 35 type 2035 z -128.000000 floor -128.000000 ceiling -4.000000 state 11 tics 1
#|- tic 297 870.777114 390.815048 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -4.000000 thing 35 type 2035 z -128.000000 floor -128.000000 ceiling -4.000000 state 10 tics 6
#|sound tic 298 DSPISTOL from thing 176 vol 64 sep 131
#|sound tic 299 DSFIRSHT from thing 307 vol 44 sep 125
#|- tic 301 870.777114 390.815048 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -4.000000 thing 35 type 2035 z -128.000000 floor -128.000000 ceiling -4.000000 state 10 tics 2
#|sounds drew to 133
#|-
#|sound tic 21 DSOOF from nobody vol 64 sep 128
#|blue door refused tic 21 880.000000 1440.000000 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 9 sector 71 -128.000000 -128.000000 key True things 209 cards 0 flash 0 message 17 "You need a blue key to open this door" tics 140
#|- tic 41 880.000000 1440.000000 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 9 sector 71 -128.000000 -128.000000 key True things 209 cards 0 flash 0 message 17 "You need a blue key to open this door" tics 120
#|turn tic 42 880.000000 1440.000000 247.500 z -128.000000 floor -128.000000 eye 41.000000 thinkers 9 sector 71 -128.000000 -128.000000 key True things 209 cards 0 flash 0 message 17 "You need a blue key to open this door" tics 119
#|walk tic 55 860.814102 1393.630569 247.500 z -128.000000 floor -128.000000 eye 36.733230 thinkers 9 sector 71 -128.000000 -128.000000 key True things 209 cards 0 flash 0 message 17 "You need a blue key to open this door" tics 106
#|sound tic 56 stop thing 82
#|sound tic 56 DSITEMUP from nobody vol 64 sep 128
#|- tic 56 858.431030 1387.871063 247.500 z -128.000000 floor -128.000000 eye 36.145187 thinkers 9 sector 71 -128.000000 -128.000000 key False things 208 cards 1 flash 12 message 7 "Picked up a blue keycard." tics 140
#|- tic 76 838.610397 1339.968490 247.500 z -128.000000 floor -128.000000 eye 40.905364 thinkers 9 sector 71 -128.000000 -128.000000 key False things 208 cards 1 flash 0 message 7 "Picked up a blue keycard." tics 120
#|turn tic 77 838.308792 1339.239654 90.000 z -128.000000 floor -128.000000 eye 40.925247 thinkers 9 sector 71 -128.000000 -128.000000 key False things 208 cards 1 flash 0 message 7 "Picked up a blue keycard." tics 119
#|walk tic 96 835.806503 1423.465972 90.000 z -128.000000 floor -128.000000 eye 34.990249 thinkers 9 sector 71 -128.000000 -128.000000 key False things 208 cards 1 flash 0 message 7 "Picked up a blue keycard." tics 100
#|sound tic 97 DSDOROPN from sector 71 vol 64 sep 123
#|use tic 97 835.761825 1429.752563 90.000 z -128.000000 floor -128.000000 eye 36.239089 thinkers 10 sector 71 -128.000000 -126.000000 key False things 208 cards 1 flash 0 message 7 "Picked up a blue keycard." tics 99
#|- tic 102 835.593826 1453.375137 90.000 z -128.000000 floor -128.000000 eye 41.488937 thinkers 10 sector 71 -128.000000 -116.000000 key False things 208 cards 1 flash 0 message 7 "Picked up a blue keycard." tics 94
#|sound tic 104 DSPOSIT1 from thing 94 vol 49 sep 143
#|sound tic 104 DSPOSIT3 from thing 95 vol 56 sep 100
#|sound tic 113 DSPOSACT from thing 95 vol 59 sep 105
#|- tic 117 835.508346 1463.921813 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 71 -128.000000 -86.000000 key False things 208 cards 1 flash 0 message 7 "Picked up a blue keycard." tics 79
#|sound tic 135 DSSHOTGN from thing 94 vol 53 sep 134
#|sound tic 137 DSPOPAIN from thing 81 vol 50 sep 131
#|sound tic 138 DSPLPAIN from thing 4294967295 vol 64 sep 128
#|sound tic 142 stop thing 293
#|sound tic 149 stop thing 294
#|sound tic 150 stop thing 292
#|sound tic 155 DSFIRSHT from thing 295 vol 50 sep 132
#|sound tic 156 DSSHOTGN from thing 95 vol 64 sep 127
#|- tic 158 834.717132 1445.361068 90.000 z -128.000000 floor -128.000000 eye 40.795639 thinkers 10 sector 71 -128.000000 -4.000000 key False things 212 cards 1 flash 0 message 7 "Picked up a blue keycard." tics 38
#|sound tic 159 DSPLPAIN from thing 4294967295 vol 64 sep 128
#|- tic 159 834.722137 1444.103607 90.000 z -128.000000 floor -128.000000 eye 40.872573 thinkers 10 sector 71 -128.000000 -4.000000 key False things 212 cards 1 flash 0 message 7 "Picked up a blue keycard." tics 37
#|sound tic 168 stop thing 297
#|sound tic 169 stop thing 298
#|sound tic 171 stop thing 296
#|sound tic 188 DSBGACT from thing 81 vol 57 sep 133
#|sound tic 190 DSFIRXPL from thing 295 vol 64 sep 182
#|sound tic 194 DSPLPAIN from thing 4294967295 vol 64 sep 128
#|sound tic 195 DSSHOTGN from thing 95 vol 64 sep 129
#|- tic 195 830.412582 1437.841964 90.000 z -128.000000 floor -128.000000 eye 40.816085 thinkers 10 sector 71 -128.000000 -4.000000 key False things 212 cards 1 flash 0 message 7 "Picked up a blue keycard." tics 1
#|- tic 196 829.765090 1437.772705 90.000 z -128.000000 floor -128.000000 eye 40.947204 thinkers 10 sector 71 -128.000000 -4.000000 key False things 212 cards 1 flash 0 message 7 "Picked up a blue keycard." tics 0
#|sounds drew to 19
#|-
#|start cell 2,11 58 cell 2,10 157 sector 160 58 sector 140 238 next 292 random 59 thing 58 type 18 at -400.000000 400.000000 z 16.000000 angle 270.000 sector 160 state 2 tics 4294967295 radius 20 height 16 flags 0
#|  thinkers: 210 mobjs, about the player's 132 133 134 137 139, 9 specials, then mobjs
#|moved cell 2,11 cell 2,10 58 157 sector 160 sector 140 58 238 next 292 random 59 thing 58 type 18 at -400.000000 300.000000 z 16.000000 angle 270.000 sector 140 state 2 tics 4294967295 radius 20 height 16 flags 0
#|  thinkers: 210 mobjs, about the player's 132 133 134 137 139, 9 specials, then mobjs
#|spawned cell 2,11 cell 2,10 292 58 157 sector 160 sector 140 292 58 238 next 293 random 60 thing 292 type 2014 at -340.000000 288.000000 z 0.000000 angle 0.000 sector 140 state 12 tics 6 radius 20 height 16 flags 8388609
#|  thinkers: 210 mobjs, about the player's 132 133 134 137 139, 9 specials, then mobjs 292
#|a tic cell 2,11 cell 2,10 292 58 157 sector 160 sector 140 292 58 238 next 293 random 62 thing 292 type 2014 at -340.000000 288.000000 z 0.000000 angle 0.000 sector 140 state 12 tics 5 radius 20 height 16 flags 8388609
#|  thinkers: 210 mobjs, about the player's 132 133 134 137 139, 9 specials, then mobjs 292
#|removed, a tic cell 2,11 cell 2,10 58 157 sector 160 sector 140 58 238 next 293 random 62 
#|  thinkers: 210 mobjs, about the player's 132 133 134 137 139, 9 specials, then mobjs
#|spawned cell 2,11 cell 2,10 293 58 157 sector 160 sector 140 293 58 238 next 294 random 63 thing 293 type 2014 at -340.000000 288.000000 z 0.000000 angle 0.000 sector 140 state 12 tics 6 radius 20 height 16 flags 8388609
#|  thinkers: 210 mobjs, about the player's 132 133 134 137 139, 9 specials, then mobjs 293
#|walked cell 2,11 cell 2,10 157 293 58 sector 160 sector 140 293 58 238 next 294 random 63 thing 293 type 2014 at -340.000000 288.000000 z 0.000000 angle 0.000 sector 140 state 12 tics 5 radius 20 height 16 flags 8388609
#|  thinkers: 210 mobjs, about the player's 132 133 134 137 139, 9 specials, then mobjs 293
#|links 210 of 210 things, solid 108 of 108, wrong 0, unlinked 0
#|reject 17,17 False 36,36 False 17,5 False 36,87 False 36,56 False 5,66 True 181,178 True 181,179 True 181,180 True 181,181 False
#|sound tic 7 DSSGTSIT from thing 92 vol 64 sep 129
#|front and deaf tic 12 92:115/1 90:64/8 96:64/4 sight 92 True 90 True 96 False random 69
#|sounds drew to 77
#|sound tic 7 DSSGTSIT from thing 92 vol 49 sep 132
#|behind tic 30 90:64/10 92:116/1 sight 90 True 92 True random 77
#|sounds drew to 95
#|sound tic 7 DSSGTSIT from thing 92 vol 49 sep 125
#|sound tic 10 DSPOSIT1 from thing 90 vol 64 sep 224
#|behind in reach tic 12 90:97/1 92:115/1 sight 90 True 92 True random 71
#|sounds drew to 78
#|sound tic 6 DSPOSIT2 from thing 96 vol 64 sep 33
#|through the wall tic 20 96:101/1 sight 96 True random 83
#|sounds drew to 85
#|sound tic 15 DSPOSIT3 from thing 177 vol 57 sep 101
#|over the pit tic 20 177:90/3 176:61/5 sight 177 True 176 False random 72
#|sounds drew to 85
#|off the pit tic 20 177:61/5 176:61/5 sight 177 False 176 False random 65
#|sounds drew to 84
#|head on
#|tic 1 92 at -48.000000 1616.000000 facing 0.000 dir 0 row 67/6 health 100 random 61
#|tic 2 92 at -48.000000 1616.000000 facing 0.000 dir 0 row 67/5 health 100 random 61
#|tic 3 92 at -48.000000 1616.000000 facing 0.000 dir 0 row 67/4 health 100 random 61
#|tic 4 92 at -48.000000 1616.000000 facing 0.000 dir 0 row 67/3 health 100 random 61
#|tic 5 92 at -48.000000 1616.000000 facing 0.000 dir 0 row 67/2 health 100 random 61
#|tic 6 92 at -48.000000 1616.000000 facing 0.000 dir 0 row 67/1 health 100 random 62
#|sound tic 7 DSSGTSIT from thing 92 vol 64 sep 129
#|tic 7 92 at -38.000000 1616.000000 facing 0.000 dir 0 row 113/2 health 100 random 65
#|tic 8 92 at -38.000000 1616.000000 facing 0.000 dir 0 row 113/1 health 100 random 66
#|tic 9 92 at -28.000000 1616.000000 facing 0.000 dir 0 row 114/2 health 100 random 68
#|tic 10 92 at -28.000000 1616.000000 facing 0.000 dir 0 row 114/1 health 100 random 68
#|tic 11 92 at -18.000000 1616.000000 facing 0.000 dir 0 row 115/2 health 100 random 69
#|tic 12 92 at -18.000000 1616.000000 facing 0.000 dir 0 row 115/1 health 100 random 69
#|sounds drew to 77
#|across the room
#|tic 1 177 at 752.000000 336.000000 facing 180.000 dir 0 row 61/4 health 100 random 61
#|tic 2 177 at 752.000000 336.000000 facing 180.000 dir 0 row 61/3 health 100 random 61
#|tic 3 177 at 752.000000 336.000000 facing 180.000 dir 0 row 61/2 health 100 random 61
#|tic 4 177 at 752.000000 336.000000 facing 180.000 dir 0 row 61/1 health 100 random 61
#|tic 5 177 at 752.000000 336.000000 facing 180.000 dir 0 row 62/10 health 100 random 61
#|tic 6 177 at 752.000000 336.000000 facing 180.000 dir 0 row 62/9 health 100 random 62
#|tic 7 177 at 752.000000 336.000000 facing 180.000 dir 0 row 62/8 health 100 random 62
#|tic 8 177 at 752.000000 336.000000 facing 180.000 dir 0 row 62/7 health 100 random 63
#|tic 9 177 at 752.000000 336.000000 facing 180.000 dir 0 row 62/6 health 100 random 64
#|tic 10 177 at 752.000000 336.000000 facing 180.000 dir 0 row 62/5 health 100 random 64
#|tic 11 177 at 752.000000 336.000000 facing 180.000 dir 0 row 62/4 health 100 random 64
#|tic 12 177 at 752.000000 336.000000 facing 180.000 dir 0 row 62/3 health 100 random 64
#|tic 13 177 at 752.000000 336.000000 facing 180.000 dir 0 row 62/2 health 100 random 64
#|tic 14 177 at 752.000000 336.000000 facing 180.000 dir 0 row 62/1 health 100 random 64
#|sound tic 15 DSPOSIT3 from thing 177 vol 57 sep 101
#|tic 15 177 at 746.262695 330.262695 facing 225.000 dir 5 row 89/4 health 100 random 68
#|tic 16 177 at 746.262695 330.262695 facing 225.000 dir 5 row 89/3 health 100 random 69
#|tic 17 177 at 746.262695 330.262695 facing 225.000 dir 5 row 89/2 health 100 random 69
#|tic 18 177 at 746.262695 330.262695 facing 225.000 dir 5 row 89/1 health 100 random 69
#|tic 19 177 at 740.525390 324.525390 facing 225.000 dir 5 row 90/4 health 100 random 71
#|tic 20 177 at 740.525390 324.525390 facing 225.000 dir 5 row 90/3 health 100 random 72
#|tic 21 177 at 740.525390 324.525390 facing 225.000 dir 5 row 90/2 health 100 random 72
#|tic 22 177 at 740.525390 324.525390 facing 225.000 dir 5 row 90/1 health 100 random 72
#|tic 23 177 at 734.788085 318.788085 facing 225.000 dir 5 row 91/4 health 100 random 73
#|tic 24 177 at 734.788085 318.788085 facing 225.000 dir 5 row 91/3 health 100 random 73
#|sounds drew to 89
#|round the corner
#|tic 1 96 at 144.000000 1952.000000 facing 225.000 dir 0 row 63/5 health 100 random 61
#|tic 2 96 at 144.000000 1952.000000 facing 225.000 dir 0 row 63/4 health 100 random 61
#|tic 3 96 at 144.000000 1952.000000 facing 225.000 dir 0 row 63/3 health 100 random 61
#|tic 4 96 at 144.000000 1952.000000 facing 225.000 dir 0 row 63/2 health 100 random 61
#|tic 5 96 at 144.000000 1952.000000 facing 225.000 dir 0 row 63/1 health 100 random 61
#|sound tic 6 DSPOSIT2 from thing 96 vol 64 sep 33
#|tic 6 96 at 144.000000 1944.000000 facing 270.000 dir 6 row 97/3 health 100 random 66
#|tic 7 96 at 144.000000 1944.000000 facing 270.000 dir 6 row 97/2 health 100 random 67
#|tic 8 96 at 144.000000 1944.000000 facing 270.000 dir 6 row 97/1 health 100 random 68
#|tic 9 96 at 144.000000 1936.000000 facing 270.000 dir 6 row 98/3 health 100 random 71
#|tic 10 96 at 144.000000 1936.000000 facing 270.000 dir 6 row 98/2 health 100 random 72
#|tic 11 96 at 144.000000 1936.000000 facing 270.000 dir 6 row 98/1 health 100 random 72
#|tic 12 96 at 144.000000 1928.000000 facing 270.000 dir 6 row 99/3 health 100 random 74
#|tic 13 96 at 144.000000 1928.000000 facing 270.000 dir 6 row 99/2 health 100 random 75
#|tic 14 96 at 144.000000 1928.000000 facing 270.000 dir 6 row 99/1 health 100 random 75
#|tic 15 96 at 152.000000 1928.000000 facing 270.000 dir 0 row 100/3 health 100 random 79
#|tic 16 96 at 152.000000 1928.000000 facing 270.000 dir 0 row 100/2 health 100 random 79
#|tic 17 96 at 152.000000 1928.000000 facing 270.000 dir 0 row 100/1 health 100 random 79
#|tic 18 96 at 160.000000 1928.000000 facing 315.000 dir 0 row 101/3 health 100 random 81
#|tic 19 96 at 160.000000 1928.000000 facing 315.000 dir 0 row 101/2 health 100 random 82
#|tic 20 96 at 160.000000 1928.000000 facing 315.000 dir 0 row 101/1 health 100 random 83
#|tic 21 96 at 168.000000 1928.000000 facing 0.000 dir 0 row 102/3 health 100 random 86
#|tic 22 96 at 168.000000 1928.000000 facing 0.000 dir 0 row 102/2 health 100 random 87
#|tic 23 96 at 168.000000 1928.000000 facing 0.000 dir 0 row 102/1 health 100 random 87
#|tic 24 96 at 176.000000 1928.000000 facing 0.000 dir 0 row 103/3 health 100 random 88
#|sounds drew to 89
#|at the ledge
#|sound tic 1 DSPOSIT1 from thing 185 vol 64 sep 129
#|tic 1 185 at 1112.000000 -672.000000 facing 90.000 dir 0 row 97/3 health 100 random 65
#|tic 2 185 at 1112.000000 -672.000000 facing 90.000 dir 0 row 97/2 health 100 random 65
#|tic 3 185 at 1112.000000 -672.000000 facing 90.000 dir 0 row 97/1 health 100 random 65
#|tic 4 185 at 1112.000000 -664.000000 facing 45.000 dir 2 row 98/3 health 100 random 69
#|tic 5 185 at 1112.000000 -664.000000 facing 45.000 dir 2 row 98/2 health 100 random 69
#|tic 6 185 at 1112.000000 -664.000000 facing 45.000 dir 2 row 98/1 health 100 random 69
#|tic 7 185 at 1104.000000 -664.000000 facing 90.000 dir 4 row 99/3 health 100 random 74
#|tic 8 185 at 1104.000000 -664.000000 facing 90.000 dir 4 row 99/2 health 100 random 75
#|tic 9 185 at 1104.000000 -664.000000 facing 90.000 dir 4 row 99/1 health 100 random 75
#|tic 10 185 at 1096.000000 -664.000000 facing 135.000 dir 4 row 100/3 health 100 random 76
#|tic 11 185 at 1096.000000 -664.000000 facing 135.000 dir 4 row 100/2 health 100 random 76
#|tic 12 185 at 1096.000000 -664.000000 facing 135.000 dir 4 row 100/1 health 100 random 76
#|tic 13 185 at 1096.000000 -672.000000 facing 180.000 dir 6 row 101/3 health 100 random 80
#|tic 14 185 at 1096.000000 -672.000000 facing 180.000 dir 6 row 101/2 health 100 random 80
#|tic 15 185 at 1096.000000 -672.000000 facing 180.000 dir 6 row 101/1 health 100 random 81
#|tic 16 185 at 1096.000000 -680.000000 facing 225.000 dir 6 row 102/3 health 100 random 83
#|sound tic 17 DSPOSIT2 from thing 182 vol 63 sep 78
#|sound tic 17 DSPOSIT3 from thing 265 vol 46 sep 33
#|tic 17 185 at 1096.000000 -680.000000 facing 225.000 dir 6 row 102/2 health 100 random 90
#|tic 18 185 at 1096.000000 -680.000000 facing 225.000 dir 6 row 102/1 health 100 random 91
#|tic 19 185 at 1104.000000 -680.000000 facing 270.000 dir 0 row 103/3 health 100 random 95
#|sound tic 20 DSPOSACT from thing 182 vol 64 sep 80
#|tic 20 185 at 1104.000000 -680.000000 facing 270.000 dir 0 row 103/2 health 100 random 96
#|tic 21 185 at 1104.000000 -680.000000 facing 270.000 dir 0 row 103/1 health 100 random 97
#|tic 22 185 at 1112.000000 -680.000000 facing 315.000 dir 0 row 104/3 health 100 random 98
#|tic 23 185 at 1112.000000 -680.000000 facing 315.000 dir 0 row 104/2 health 100 random 102
#|tic 24 185 at 1112.000000 -680.000000 facing 315.000 dir 0 row 104/1 health 100 random 103
#|tic 25 185 at 1106.262695 -674.262695 facing 0.000 dir 3 row 97/3 health 100 random 108
#|tic 26 185 at 1106.262695 -674.262695 facing 0.000 dir 3 row 97/2 health 100 random 109
#|tic 27 185 at 1106.262695 -674.262695 facing 0.000 dir 3 row 97/1 health 100 random 109
#|tic 28 185 at 1100.525390 -668.525390 facing 45.000 dir 3 row 98/3 health 100 random 110
#|tic 29 185 at 1100.525390 -668.525390 facing 45.000 dir 3 row 98/2 health 100 random 115
#|tic 30 185 at 1100.525390 -668.525390 facing 45.000 dir 3 row 98/1 health 100 random 115
#|tic 31 185 at 1094.788085 -662.788085 facing 90.000 dir 3 row 99/3 health 100 random 116
#|tic 32 185 at 1094.788085 -662.788085 facing 90.000 dir 3 row 99/2 health 100 random 119
#|tic 33 185 at 1094.788085 -662.788085 facing 90.000 dir 3 row 99/1 health 100 random 120
#|tic 34 185 at 1094.788085 -670.788085 facing 135.000 dir 6 row 100/3 health 100 random 124
#|tic 35 185 at 1094.788085 -670.788085 facing 135.000 dir 6 row 100/2 health 100 random 125
#|tic 36 185 at 1094.788085 -670.788085 facing 135.000 dir 6 row 100/1 health 100 random 125
#|tic 37 185 at 1094.788085 -678.788085 facing 180.000 dir 6 row 101/3 health 100 random 127
#|tic 38 185 at 1094.788085 -678.788085 facing 180.000 dir 6 row 101/2 health 100 random 129
#|tic 39 185 at 1094.788085 -678.788085 facing 180.000 dir 6 row 101/1 health 100 random 129
#|tic 40 185 at 1100.525390 -673.050781 facing 225.000 dir 1 row 102/3 health 100 random 133
#|sounds drew to 108
#|the zombieman shoots
#|tic 1 177 at 752.000000 336.000000 facing 180.000 dir 0 row 61/4 health 100 random 61
#|tic 2 177 at 752.000000 336.000000 facing 180.000 dir 0 row 61/3 health 100 random 61
#|tic 3 177 at 752.000000 336.000000 facing 180.000 dir 0 row 61/2 health 100 random 61
#|tic 4 177 at 752.000000 336.000000 facing 180.000 dir 0 row 61/1 health 100 random 61
#|tic 5 177 at 752.000000 336.000000 facing 180.000 dir 0 row 62/10 health 100 random 61
#|tic 6 177 at 752.000000 336.000000 facing 180.000 dir 0 row 62/9 health 100 random 62
#|tic 7 177 at 752.000000 336.000000 facing 180.000 dir 0 row 62/8 health 100 random 62
#|tic 8 177 at 752.000000 336.000000 facing 180.000 dir 0 row 62/7 health 100 random 63
#|tic 9 177 at 752.000000 336.000000 facing 180.000 dir 0 row 62/6 health 100 random 64
#|tic 10 177 at 752.000000 336.000000 facing 180.000 dir 0 row 62/5 health 100 random 64
#|tic 11 177 at 752.000000 336.000000 facing 180.000 dir 0 row 62/4 health 100 random 64
#|tic 12 177 at 752.000000 336.000000 facing 180.000 dir 0 row 62/3 health 100 random 64
#|tic 13 177 at 752.000000 336.000000 facing 180.000 dir 0 row 62/2 health 100 random 64
#|tic 14 177 at 752.000000 336.000000 facing 180.000 dir 0 row 62/1 health 100 random 64
#|sound tic 15 DSPOSIT3 from thing 177 vol 57 sep 101
#|tic 15 177 at 746.262695 330.262695 facing 225.000 dir 5 row 89/4 health 100 random 68
#|tic 16 177 at 746.262695 330.262695 facing 225.000 dir 5 row 89/3 health 100 random 69
#|tic 17 177 at 746.262695 330.262695 facing 225.000 dir 5 row 89/2 health 100 random 69
#|tic 18 177 at 746.262695 330.262695 facing 225.000 dir 5 row 89/1 health 100 random 69
#|tic 19 177 at 740.525390 324.525390 facing 225.000 dir 5 row 90/4 health 100 random 71
#|tic 20 177 at 740.525390 324.525390 facing 225.000 dir 5 row 90/3 health 100 random 72
#|tic 21 177 at 740.525390 324.525390 facing 225.000 dir 5 row 90/2 health 100 random 72
#|tic 22 177 at 740.525390 324.525390 facing 225.000 dir 5 row 90/1 health 100 random 72
#|tic 23 177 at 734.788085 318.788085 facing 225.000 dir 5 row 91/4 health 100 random 73
#|tic 24 177 at 734.788085 318.788085 facing 225.000 dir 5 row 91/3 health 100 random 73
#|tic 25 177 at 734.788085 318.788085 facing 225.000 dir 5 row 91/2 health 100 random 73
#|tic 26 177 at 734.788085 318.788085 facing 225.000 dir 5 row 91/1 health 100 random 73
#|tic 27 177 at 729.050781 313.050781 facing 225.000 dir 5 row 92/4 health 100 random 74
#|tic 28 177 at 729.050781 313.050781 facing 225.000 dir 5 row 92/3 health 100 random 75
#|tic 29 177 at 729.050781 313.050781 facing 225.000 dir 5 row 92/2 health 100 random 75
#|tic 30 177 at 729.050781 313.050781 facing 225.000 dir 5 row 92/1 health 100 random 75
#|tic 31 177 at 723.313476 307.313476 facing 225.000 dir 5 row 93/4 health 100 random 76
#|tic 32 177 at 723.313476 307.313476 facing 225.000 dir 5 row 93/3 health 100 random 76
#|tic 33 177 at 723.313476 307.313476 facing 225.000 dir 5 row 93/2 health 100 random 76
#|tic 34 177 at 723.313476 307.313476 facing 225.000 dir 5 row 93/1 health 100 random 76
#|tic 35 177 at 717.576171 301.576171 facing 225.000 dir 5 row 94/4 health 100 random 78
#|tic 36 177 at 717.576171 301.576171 facing 225.000 dir 5 row 94/3 health 100 random 78
#|tic 37 177 at 717.576171 301.576171 facing 225.000 dir 5 row 94/2 health 100 random 78
#|tic 38 177 at 717.576171 301.576171 facing 225.000 dir 5 row 94/1 health 100 random 78
#|tic 39 177 at 711.838867 295.838867 facing 225.000 dir 5 row 95/4 health 100 random 79
#|tic 40 177 at 711.838867 295.838867 facing 225.000 dir 5 row 95/3 health 100 random 79
#|tic 41 177 at 711.838867 295.838867 facing 225.000 dir 5 row 95/2 health 100 random 79
#|tic 42 177 at 711.838867 295.838867 facing 225.000 dir 5 row 95/1 health 100 random 79
#|tic 43 177 at 711.838867 295.838867 facing 190.074 dir 5 row 184/10 health 100 random 80
#|tic 44 177 at 711.838867 295.838867 facing 190.074 dir 5 row 184/9 health 100 random 80
#|tic 45 177 at 711.838867 295.838867 facing 190.074 dir 5 row 184/8 health 100 random 80
#|tic 46 177 at 711.838867 295.838867 facing 190.074 dir 5 row 184/7 health 100 random 80
#|tic 47 177 at 711.838867 295.838867 facing 190.074 dir 5 row 184/6 health 100 random 80
#|tic 48 177 at 711.838867 295.838867 facing 190.074 dir 5 row 184/5 health 100 random 80
#|tic 49 177 at 711.838867 295.838867 facing 190.074 dir 5 row 184/4 health 100 random 80
#|tic 50 177 at 711.838867 295.838867 facing 190.074 dir 5 row 184/3 health 100 random 80
#|tic 51 177 at 711.838867 295.838867 facing 190.074 dir 5 row 184/2 health 100 random 80
#|tic 52 177 at 711.838867 295.838867 facing 190.074 dir 5 row 184/1 health 100 random 80
#|sound tic 53 DSPISTOL from thing 177 vol 61 sep 112
#|tic 53 177 at 711.838867 295.838867 facing 190.074 dir 5 row 185/8 health 100 random 87
#|tic 54 177 at 711.838867 295.838867 facing 190.074 dir 5 row 185/7 health 100 random 87
#|tic 55 177 at 711.838867 295.838867 facing 190.074 dir 5 row 185/6 health 100 random 87
#|tic 56 177 at 711.838867 295.838867 facing 190.074 dir 5 row 185/5 health 100 random 87
#|tic 57 177 at 711.838867 295.838867 facing 190.074 dir 5 row 185/4 health 100 random 87
#|tic 58 177 at 711.838867 295.838867 facing 190.074 dir 5 row 185/3 health 100 random 87
#|tic 59 177 at 711.838867 295.838867 facing 190.074 dir 5 row 185/2 health 100 random 87
#|tic 60 177 at 711.838867 295.838867 facing 190.074 dir 5 row 185/1 health 100 random 87
#|tic 61 177 at 711.838867 295.838867 facing 190.074 dir 5 row 186/8 health 100 random 87
#|tic 62 177 at 711.838867 295.838867 facing 190.074 dir 5 row 186/7 health 100 random 87
#|tic 63 177 at 711.838867 295.838867 facing 190.074 dir 5 row 186/6 health 100 random 87
#|tic 64 177 at 711.838867 295.838867 facing 190.074 dir 5 row 186/5 health 100 random 87
#|sound tic 65 stop thing 292
#|tic 65 177 at 711.838867 295.838867 facing 190.074 dir 5 row 186/4 health 100 random 88
#|tic 66 177 at 711.838867 295.838867 facing 190.074 dir 5 row 186/3 health 100 random 88
#|tic 67 177 at 711.838867 295.838867 facing 190.074 dir 5 row 186/2 health 100 random 88
#|tic 68 177 at 711.838867 295.838867 facing 190.074 dir 5 row 186/1 health 100 random 88
#|tic 69 177 at 706.101562 290.101562 facing 225.000 dir 5 row 89/4 health 100 random 89
#|tic 70 177 at 706.101562 290.101562 facing 225.000 dir 5 row 89/3 health 100 random 89
#|sounds drew to 136
#|the shotgun guy shoots
#|tic 1 96 at 144.000000 1952.000000 facing 225.000 dir 0 row 63/5 health 100 random 61
#|tic 2 96 at 144.000000 1952.000000 facing 225.000 dir 0 row 63/4 health 100 random 61
#|tic 3 96 at 144.000000 1952.000000 facing 225.000 dir 0 row 63/3 health 100 random 61
#|tic 4 96 at 144.000000 1952.000000 facing 225.000 dir 0 row 63/2 health 100 random 61
#|tic 5 96 at 144.000000 1952.000000 facing 225.000 dir 0 row 63/1 health 100 random 61
#|sound tic 6 DSPOSIT2 from thing 96 vol 64 sep 33
#|tic 6 96 at 144.000000 1944.000000 facing 270.000 dir 6 row 97/3 health 100 random 66
#|tic 7 96 at 144.000000 1944.000000 facing 270.000 dir 6 row 97/2 health 100 random 67
#|tic 8 96 at 144.000000 1944.000000 facing 270.000 dir 6 row 97/1 health 100 random 68
#|tic 9 96 at 144.000000 1936.000000 facing 270.000 dir 6 row 98/3 health 100 random 71
#|tic 10 96 at 144.000000 1936.000000 facing 270.000 dir 6 row 98/2 health 100 random 72
#|tic 11 96 at 144.000000 1936.000000 facing 270.000 dir 6 row 98/1 health 100 random 72
#|tic 12 96 at 144.000000 1928.000000 facing 270.000 dir 6 row 99/3 health 100 random 74
#|tic 13 96 at 144.000000 1928.000000 facing 270.000 dir 6 row 99/2 health 100 random 75
#|tic 14 96 at 144.000000 1928.000000 facing 270.000 dir 6 row 99/1 health 100 random 75
#|tic 15 96 at 152.000000 1928.000000 facing 270.000 dir 0 row 100/3 health 100 random 79
#|tic 16 96 at 152.000000 1928.000000 facing 270.000 dir 0 row 100/2 health 100 random 79
#|tic 17 96 at 152.000000 1928.000000 facing 270.000 dir 0 row 100/1 health 100 random 79
#|tic 18 96 at 160.000000 1928.000000 facing 315.000 dir 0 row 101/3 health 100 random 81
#|tic 19 96 at 160.000000 1928.000000 facing 315.000 dir 0 row 101/2 health 100 random 82
#|tic 20 96 at 160.000000 1928.000000 facing 315.000 dir 0 row 101/1 health 100 random 83
#|tic 21 96 at 168.000000 1928.000000 facing 0.000 dir 0 row 102/3 health 100 random 86
#|tic 22 96 at 168.000000 1928.000000 facing 0.000 dir 0 row 102/2 health 100 random 87
#|tic 23 96 at 168.000000 1928.000000 facing 0.000 dir 0 row 102/1 health 100 random 87
#|tic 24 96 at 176.000000 1928.000000 facing 0.000 dir 0 row 103/3 health 100 random 88
#|tic 25 96 at 176.000000 1928.000000 facing 0.000 dir 0 row 103/2 health 100 random 88
#|tic 26 96 at 176.000000 1928.000000 facing 0.000 dir 0 row 103/1 health 100 random 88
#|tic 27 96 at 184.000000 1928.000000 facing 0.000 dir 0 row 104/3 health 100 random 89
#|tic 28 96 at 184.000000 1928.000000 facing 0.000 dir 0 row 104/2 health 100 random 90
#|tic 29 96 at 184.000000 1928.000000 facing 0.000 dir 0 row 104/1 health 100 random 91
#|tic 30 96 at 192.000000 1928.000000 facing 0.000 dir 0 row 97/3 health 100 random 93
#|tic 31 96 at 192.000000 1928.000000 facing 0.000 dir 0 row 97/2 health 100 random 93
#|tic 32 96 at 192.000000 1928.000000 facing 0.000 dir 0 row 97/1 health 100 random 93
#|tic 33 96 at 200.000000 1928.000000 facing 0.000 dir 0 row 98/3 health 100 random 94
#|tic 34 96 at 200.000000 1928.000000 facing 0.000 dir 0 row 98/2 health 100 random 94
#|tic 35 96 at 200.000000 1928.000000 facing 0.000 dir 0 row 98/1 health 100 random 95
#|sound tic 36 DSPOSACT from thing 96 vol 64 sep 78
#|tic 36 96 at 208.000000 1928.000000 facing 0.000 dir 0 row 99/3 health 100 random 97
#|tic 37 96 at 208.000000 1928.000000 facing 0.000 dir 0 row 99/2 health 100 random 97
#|tic 38 96 at 208.000000 1928.000000 facing 0.000 dir 0 row 99/1 health 100 random 97
#|tic 39 96 at 216.000000 1928.000000 facing 0.000 dir 0 row 100/3 health 100 random 98
#|tic 40 96 at 216.000000 1928.000000 facing 0.000 dir 0 row 100/2 health 100 random 99
#|tic 41 96 at 216.000000 1928.000000 facing 0.000 dir 0 row 100/1 health 100 random 99
#|tic 42 96 at 224.000000 1928.000000 facing 0.000 dir 0 row 101/3 health 100 random 100
#|tic 43 96 at 224.000000 1928.000000 facing 0.000 dir 0 row 101/2 health 100 random 100
#|tic 44 96 at 224.000000 1928.000000 facing 0.000 dir 0 row 101/1 health 100 random 100
#|tic 45 96 at 232.000000 1928.000000 facing 0.000 dir 0 row 102/3 health 100 random 101
#|tic 46 96 at 232.000000 1928.000000 facing 0.000 dir 0 row 102/2 health 100 random 101
#|tic 47 96 at 232.000000 1928.000000 facing 0.000 dir 0 row 102/1 health 100 random 101
#|tic 48 96 at 240.000000 1928.000000 facing 0.000 dir 0 row 103/3 health 100 random 102
#|tic 49 96 at 240.000000 1928.000000 facing 0.000 dir 0 row 103/2 health 100 random 102
#|tic 50 96 at 240.000000 1928.000000 facing 0.000 dir 0 row 103/1 health 100 random 102
#|tic 51 96 at 240.000000 1928.000000 facing 202.609 dir 0 row 187/10 health 100 random 103
#|tic 52 96 at 240.000000 1928.000000 facing 202.609 dir 0 row 187/9 health 100 random 103
#|tic 53 96 at 240.000000 1928.000000 facing 202.609 dir 0 row 187/8 health 100 random 103
#|tic 54 96 at 240.000000 1928.000000 facing 202.609 dir 0 row 187/7 health 100 random 103
#|tic 55 96 at 240.000000 1928.000000 facing 202.609 dir 0 row 187/6 health 100 random 103
#|tic 56 96 at 240.000000 1928.000000 facing 202.609 dir 0 row 187/5 health 100 random 103
#|tic 57 96 at 240.000000 1928.000000 facing 202.609 dir 0 row 187/4 health 100 random 103
#|tic 58 96 at 240.000000 1928.000000 facing 202.609 dir 0 row 187/3 health 100 random 103
#|tic 59 96 at 240.000000 1928.000000 facing 202.609 dir 0 row 187/2 health 100 random 103
#|tic 60 96 at 240.000000 1928.000000 facing 202.609 dir 0 row 187/1 health 100 random 103
#|sound tic 61 DSSHOTGN from thing 96 vol 64 sep 92
#|tic 61 96 at 240.000000 1928.000000 facing 202.609 dir 0 row 188/10 health 73 random 127
#|tic 62 96 at 240.000000 1928.000000 facing 202.609 dir 0 row 188/9 health 73 random 127
#|tic 63 96 at 240.000000 1928.000000 facing 202.609 dir 0 row 188/8 health 73 random 127
#|sound tic 64 DSPLPAIN from thing 4294967295 vol 64 sep 128
#|tic 64 96 at 240.000000 1928.000000 facing 202.609 dir 0 row 188/7 health 73 random 127
#|tic 65 96 at 240.000000 1928.000000 facing 202.609 dir 0 row 188/6 health 73 random 128
#|tic 66 96 at 240.000000 1928.000000 facing 202.609 dir 0 row 188/5 health 73 random 128
#|tic 67 96 at 240.000000 1928.000000 facing 202.609 dir 0 row 188/4 health 73 random 128
#|sound tic 68 stop thing 293
#|tic 68 96 at 240.000000 1928.000000 facing 202.609 dir 0 row 188/3 health 73 random 128
#|tic 69 96 at 240.000000 1928.000000 facing 202.609 dir 0 row 188/2 health 73 random 129
#|tic 70 96 at 240.000000 1928.000000 facing 202.609 dir 0 row 188/1 health 73 random 130
#|sounds drew to 138
#|shotgun pickup ready 1 pending 2 shells 8
#|key tic 1 ready 1 pending 2 shells 4 state Some(69) tics 1 at 1.000000 38.000000 flash None tics 0 at 1.000000 38.000000 random 61
#|mid switch tic 9 ready 1 pending 2 shells 4 state Some(69) tics 1 at 1.000000 86.000000 flash None tics 0 at 1.000000 86.000000 random 64
#|shotgun ready tic 33 ready 2 pending 255 shells 4 state Some(201) tics 1 at 1.000000 32.000000 flash None tics 0 at 1.000000 32.000000 random 65
#|trigger tic 34 ready 2 pending 255 shells 4 state Some(204) tics 3 at 1.000000 32.000000 flash None tics 0 at 1.000000 32.000000 random 65
#|sound tic 37 DSSHOTGN from thing 4294967295 vol 64 sep 128
#|blast tic 37 ready 2 pending 255 shells 3 state Some(205) tics 7 at 1.000000 32.000000 flash Some(213) tics 3 at 1.000000 32.000000 random 114
#|last trigger tic 1 ready 2 pending 255 shells 1 state Some(204) tics 3 at 1.000000 32.000000 flash None tics 0 at 1.000000 32.000000 random 61
#|sound tic 4 DSSHOTGN from thing 4294967295 vol 64 sep 128
#|last blast tic 4 ready 2 pending 255 shells 0 state Some(205) tics 7 at 1.000000 32.000000 flash Some(213) tics 3 at 1.000000 32.000000 random 110
#|switch away tic 74 ready 1 pending 255 shells 0 state Some(59) tics 1 at 1.000000 32.000000 flash None tics 0 at 1.000000 32.000000 random 119
#|sound tic 5 DSPUNCH from thing 4294967295 vol 64 sep 128
#|punch health 16 random 75 angle 270.000 at 992.000000 660.000000 momentum 0.000000 0.000000 pull 0
#|sound tic 5 DSPUNCH from thing 4294967295 vol 64 sep 128
#|berserk punch health 4294967276 random 75 angle 270.000 at 992.000000 660.000000 momentum 0.000000 0.000000 pull 0
#|sound tic 5 DSSAWHIT from thing 4294967295 vol 64 sep 128
#|saw hit health 6 random 84 angle 270.000 at 992.000000 660.000000 momentum 0.165481 -2.101348 pull 1
#|sound tic 6 DSPOSIT2 from thing 240 vol 50 sep 136
#|saw pull health 6 random 90 angle 270.000 at 992.000000 660.000000 momentum 0.151031 -4.736343 pull 0
#|sound tic 5 DSSAWFUL from thing 4294967295 vol 64 sep 128
#|saw miss health 20 random 67 angle 0.000 at -416.000000 256.000000 momentum 0.000000 0.000000 pull 0
#|key 1 saw tic 1 ready 1 pending 7 shells 0 state Some(69) tics 1 at 1.000000 38.000000 flash None tics 0 at 1.000000 38.000000 random 61
#|key 1 berserk tic 1 ready 7 pending 0 shells 0 state Some(225) tics 1 at 1.000000 38.000000 flash None tics 0 at 1.000000 38.000000 random 61
#|-
