# The exit's tally on E1M1 from the WAD named by BENDOOM_IWAD.
# First what G_DoCompleted hands it: the player's kills, items and
# secrets against the level's totals, and the time. Freedoom's E1M1
# spawns 49 things flagged MF_COUNTITEM on Hurt Me Plenty (30 of type
# 2014, 18 of 2015 and the berserk pack, read from its THINGS lump in
# nushell), 29 monsters flagged MF_COUNTKILL, and 4 sectors of special
# 9 (52, 86, 128 and 132).
# Then the intermission tic by tic, from the state a short route beside
# the exit switch leaves, which ends the level on tic 42. The tics are
# wi_stuff.c's: WI_initStats leaves sp_state 1 and cnt_pause TICRATE, so
# the pause ends and the kills begin at bcnt 35; each percentage climbs
# by 2 a tic from -1, which reaches a target of 0 in one tic; each of
# the four pauses lasts 35 tics; the time and the par climb by 3 a tic
# together from -1, the time reaching 1 second at once and the par 30
# after 11 tics, so sp_state 9 begins at bcnt 154 and the last state, 10,
# at bcnt 189, where the tally stands until a press. M_Random's index is
# the level's, 66 after the route's door and the switch's click, and
# WI_initAnimatedBack draws once an animation, ten of them, at the start
# and ten more when the next level's screen begins.
# Then the presses, each a tic of use with a tic of none before it, as
# WI_checkForAccelerate reads them: one while the counts climb shows
# them all at once and leaves sp_state 10, the next leaves for the
# screen that names E1M2 with its four seconds, the next cuts that
# short to the ten tics of WI_initNoState, and after them G_WorldDone
# starts E1M1 again, its things and its random index as they spawn.
# Last a secret sector counted: the player put in sector 86, which
# P_PlayerInSpecialSector counts on the tic it stands on its floor, then
# walked north into the pit it rings, sector 87, and back into 86, which
# counts no more, since the first entry cleared it.
import Base
import ../src/vec.bend as V
import ../src/fixed.bend as F
import ../src/angle.bend as A
import ../src/level.bend as L
import ../src/gfx.bend as G
import ../src/keys.bend as K
import ../src/sim.bend as S
import ../src/tic.bend as Tic
import ../src/inventory.bend as I
import ../src/inter.bend as W
import ../src/sound.bend as Sn

def held(n: Nat, forward: U32, side: U32, turn: U32, use: Bool) -> List<&2, K.Cmd>:
  List.replicate(K.Cmd, n, K.Cmd.demo(forward, side, turn, Bool.pick(U32, use, 2, 0)))

def idle(n: Nat) -> List<&2, K.Cmd>:
  held(n, 0, 0, 0, False{})

# The exit room's door used from inside, the walk to the switch, and the
# use that takes it, as tests/game.bend walks it.
def route() -> List<&2, K.Cmd>:
  List.concat(&2, K.Cmd, [held(1n, 0, 0, 16, False{}), idle(5n), held(1n, 0, 0, 0, True{})])

def beside() -> L.Level.Start:
  L.Start{F.Fixed.neg(F.Fixed.of_map(363)), F.Fixed.of_map(1316), A.Angle.of_thing(180)}

def line(tag: String, play: W.Play) -> String:
  match play:
    case W.Playing{+state}:
      tag ++ " level tic " ++ U32.show(S.State.clock(state)) ++ " " ++ S.Sim.Tally.show(S.Sim.tally(state))
    case W.Showing{+wi}:
      tag ++ " " ++ W.Inter.show(wi)

def told(tag: String, +play: W.Play) -> IO(W.Play):
  do IO<W.Play>:
    IO.print(line(tag, play))
    return play

# The play after so many idle tics.
def run(n: Nat, +level: L.Level, play: W.Play) -> W.Play:
  W.Play.replay(idle(n), level, play)

def sound.events(events: List<&2, Sn.Sound.Event>) -> String:
  match events:
    case []:
      ""
    case +event <> rest:
      " " ++ Sn.Sound.Event.show(event) ++ sound.events(rest)

def sound.line(events: List<&2, Sn.Sound.Event>, play: W.Play) -> String:
  match events:
    case []:
      ""
    case _:
      match play:
        case W.Playing{state}:
          "sound level" ++ sound.events(events) ++ "\n"
        case W.Showing{wi}:
          "sound bcnt " ++ U32.show(W.Inter.bcnt(wi)) ++ sound.events(events) ++ "\n"

def sounds(script: List<&2, K.Cmd>, +level: L.Level, play: W.Play, log: String) -> String:
  match script:
    case []:
      log
    case +cmd <> rest:
      +step = W.Play.step(level, cmd, False{}, play)
      sounds(rest, level, W.Play.Step.play(step), log ++ sound.line(W.Play.Step.sounds(step), W.Play.Step.play(step)))

# A tic of use, which the tally reads as a press, after a tic of none.
def press(+level: L.Level, play: W.Play) -> W.Play:
  W.Play.replay(List.append(&2, K.Cmd, idle(1n), held(1n, 0, 0, 0, True{})), level, play)

# The tally at the tics wi_stuff.c's counts change, the gaps between
# them run in turn.
def steps() -> List<&2, U32>:
  [1, 33, 1, 1, 35, 1, 35, 1, 35, 1, 1, 9, 1, 34, 1, 1]

def tics(gaps: List<&2, U32>, +level: L.Level, +at: U32, play: W.Play) -> IO(W.Play):
  match gaps:
    case []:
      IO.pure(W.Play, play)
    case +gap <> rest:
      do IO<W.Play>:
        shown : W.Play <- told("bcnt " ++ U32.show((at + gap : U32)),
          run(U32.to_nat(gap), level, play))
        tics(rest, level, (at + gap : U32), shown)

# Where the player stands, the special of the sector under it, whether
# that sector's secret is still to count, and how many it has counted.
def secret.line(tag: String, +level: L.Level, +s: S.State, +p: S.Player, +sector: U32) -> String:
  tag ++ " tic " ++ U32.show(S.State.clock(s)) ++ " at " ++ F.Fixed.show(S.Player.x(p)) ++ " "
    ++ F.Fixed.show(S.Player.y(p)) ++ " sector " ++ U32.show(sector) ++ " special "
    ++ U32.show(L.Level.sector.special(level, sector)) ++ " left "
    ++ U32.show(V.Vec.get(S.State.secrets(s), sector)) ++ " counted "
    ++ U32.show(I.Inventory.secrets(S.Player.inv(p)))

def secret.at(tag: String, +level: L.Level, +s: S.State, +p: S.Player) -> String:
  secret.line(tag, level, s, p, L.Level.sector_at(level, S.Player.x(p), S.Player.y(p)))

def secret(tag: String, +level: L.Level, +s: S.State) -> IO(S.State):
  do IO<S.State>:
    IO.print(secret.at(tag, level, s, S.State.player(s)))
    return s

# The walk south out of sector 86 into the pit it rings, sector 87, and
# the turn and walk back into 86; a turn of 128 in a demo's units is
# half a circle.
def out() -> List<&2, K.Cmd>:
  List.concat(&2, K.Cmd, [held(15n, 25, 0, 0, False{}), idle(8n)])

def back() -> List<&2, K.Cmd>:
  List.concat(&2, K.Cmd, [held(1n, 0, 0, 128, False{}), held(15n, 25, 0, 0, False{}), idle(8n)])

def initial(+level: L.Level) -> W.Play:
  +took = Tic.Sim.replay(route(), Tic.State.at(level, beside()))
  W.Play.ended(S.State.ended(took), took)

def summary(+level: L.Level) -> IO(Unit):
  +took = Tic.Sim.replay(route(), Tic.State.at(level, beside()))
  do IO<Unit>:
    IO.print("start " ++ S.Sim.Tally.show(S.Sim.tally(Tic.State.start(level))))
    IO.print("exit " ++ S.Sim.Tally.show(S.Sim.tally(took)) ++ " ended " ++ Bool.show(S.State.ended(took))
      ++ " random " ++ U32.show(S.State.mrnd(took)))
    return Unit{}

def intermission(+level: L.Level) -> IO(Unit):
  do IO<Unit>:
    p0 : W.Play <- told("bcnt 0", initial(level))
    p1 : W.Play <- tics(steps(), level, 0, p0)
    p2 : W.Play <- told("jumped", press(level, run(40n, level, initial(level))))
    p3 : W.Play <- told("next", press(level, p2))
    p4 : W.Play <- told("cut short", press(level, run(20n, level, p3)))
    p5 : W.Play <- told("nine tics on", run(9n, level, p4))
    p6 : W.Play <- told("ten tics on", run(1n, level, p5))
    p7 : W.Play <- told("the level again", run(1n, level, p6))
    return Unit{}

def soundcheck(+level: L.Level) -> IO(Unit):
  do IO<Unit>:
    +p1 : W.Play = run(191n, level, initial(level))
    IO.print(sounds(List.append(&2, K.Cmd, idle(40n), held(1n, 0, 0, 0, True{})), level, initial(level), "")
      ++ sounds(held(1n, 0, 0, 0, True{}), level, p1, ""))
    return Unit{}

def secrets(+level: L.Level) -> IO(Unit):
  do IO<Unit>:
    s0 : S.State <- secret("in the secret", level, Tic.State.at(level, L.Start{F.Fixed.of_map(400),
      F.Fixed.of_map(2040), A.Angle.of_thing(270)}))
    s1 : S.State <- secret("stood a tic", level, Tic.Sim.tic(K.Cmd.idle(), s0))
    s2 : S.State <- secret("out south", level, Tic.Sim.replay(out(), s1))
    s3 : S.State <- secret("back north", level, Tic.Sim.replay(back(), s2))
    return Unit{}

def play(+level: L.Level) -> IO(Unit):
  do IO<Unit>:
    summary(level)
    intermission(level)
    soundcheck(level)
    secrets(level)

def start(w: Array<U32> & G.Gfx & L.Level) -> IO(Unit):
  (mem, gl) = w
  (gfx, level) = gl
  play(level)

def main() -> IO(Unit):
  do IO<Unit>:
    world : Array<U32> & G.Gfx & L.Level <- G.Gfx.open()
    start(world)
#|start kills 0/29 items 0/49 secrets 0/4 time 0
#|exit kills 0/29 items 0/49 secrets 0/4 time 7 ended True random 73
#|bcnt 0 count 1 cnt 35 bcnt 0 shown - - - - - anims - - - - - - - - - - random 83
#|bcnt 1 count 1 cnt 34 bcnt 1 shown - - - - - anims - 0 - - - - - - - 0 random 83
#|bcnt 34 count 1 cnt 1 bcnt 34 shown - - - - - anims 2 0 2 2 2 2 2 2 2 0 random 83
#|bcnt 35 count 2 cnt 35 bcnt 35 shown - - - - - anims 2 0 2 2 2 2 0 2 2 0 random 83
#|bcnt 36 count 3 cnt 35 bcnt 36 shown 0 - - - - anims 0 0 2 2 2 2 0 2 2 0 random 83
#|bcnt 71 count 4 cnt 35 bcnt 71 shown 0 - - - - anims 0 0 2 2 2 2 0 2 2 0 random 83
#|bcnt 72 count 5 cnt 35 bcnt 72 shown 0 0 - - - anims 0 0 0 2 2 0 0 2 2 0 random 83
#|bcnt 107 count 6 cnt 35 bcnt 107 shown 0 0 - - - anims 0 0 0 0 2 0 0 2 0 0 random 83
#|bcnt 108 count 7 cnt 35 bcnt 108 shown 0 0 0 - - anims 0 0 0 0 2 0 0 2 0 0 random 83
#|bcnt 143 count 8 cnt 35 bcnt 143 shown 0 0 0 - - anims 0 0 0 0 0 0 0 0 0 0 random 83
#|bcnt 144 count 8 cnt 35 bcnt 144 shown 0 0 0 0 2 anims 0 1 0 0 0 0 0 0 0 1 random 83
#|bcnt 145 count 8 cnt 35 bcnt 145 shown 0 0 0 0 5 anims 0 1 0 0 0 0 1 0 0 1 random 83
#|bcnt 154 count 9 cnt 35 bcnt 154 shown 0 0 0 0 30 anims 1 1 1 1 1 1 1 1 1 1 random 83
#|bcnt 155 count 9 cnt 34 bcnt 155 shown 0 0 0 0 30 anims 1 2 1 1 1 1 1 1 1 2 random 83
#|bcnt 189 count 10 cnt 35 bcnt 189 shown 0 0 0 0 30 anims 1 2 1 1 1 1 2 1 1 2 random 83
#|bcnt 190 count 10 cnt 35 bcnt 190 shown 0 0 0 0 30 anims 2 2 1 1 1 1 2 1 1 2 random 83
#|bcnt 191 count 10 cnt 35 bcnt 191 shown 0 0 0 0 30 anims 2 2 1 1 1 1 2 1 1 2 random 83
#|jumped count 10 cnt 30 bcnt 42 shown 0 0 0 0 30 anims 0 0 0 0 2 0 0 2 0 0 random 83
#|next next cnt 140 bcnt 44 shown 0 0 0 0 30 anims - - - - - - - - - - random 93
#|cut short done cnt 10 bcnt 66 shown 0 0 0 0 30 anims 1 1 1 1 1 1 1 1 1 1 random 93
#|nine tics on done cnt 1 bcnt 75 shown 0 0 0 0 30 anims 1 2 2 2 2 2 1 1 1 1 random 93
#|ten tics on done cnt 0 bcnt 76 shown 0 0 0 0 30 anims 1 2 2 2 2 2 2 2 2 1 random 93
#|the level again level tic 1 kills 0/29 items 0/49 secrets 0/4 time 1
#|sound bcnt 36 DSPISTOL from nobody vol 64 sep 128 DSBAREXP from nobody vol 64 sep 128
#|sound bcnt 41 DSBAREXP from nobody vol 64 sep 128
#|sound bcnt 192 DSSGCOCK from nobody vol 64 sep 128
#|
#|in the secret tic 0 at 400.000000 2040.000000 sector 86 special 9 left 1 counted 0
#|stood a tic tic 1 at 400.000000 2040.000000 sector 86 special 9 left 0 counted 1
#|out south tic 24 at 400.037475 1935.800521 sector 87 special 0 left 0 counted 1
#|back north tic 48 at 400.011810 1994.541183 sector 86 special 9 left 0 counted 1
