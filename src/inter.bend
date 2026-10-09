# The shared level, intermission and finale path. Each scene steps on
# recorded commands and draws into the same 320 by 200 frame.
import Base
import ./vec.bend as V
import ./bytes.bend as B
import ./fixed.bend as F
import ./level.bend as L
import ./gfx.bend as G
import ./keys.bend as K
import ./random.bend as M
import ./draw.bend as D
import ./sim.bend as S
import ./tic.bend as Tic
import ./sound.bend as Sn
import ./channel.bend as C
import ./project.bend as P
import ./render.bend as R
import ./finale.bend as Fi

# The screen it shows, wi_stuff.c's stateenum_t: the counting one
# carries WI_updateStats' sp_state, 1 to 10, the next names the level to
# come, and the last is its ten tics before that level loads.
type Inter.Screen is Data:
  Count{sp: U32}
  Next{}
  Last{}

# One animation of the background: the frame it shows, 4294967295 for
# none yet, and the tic it turns on.
type Inter.Anim is Data:
  Anim{ctr: U32, nexttic: U32}

# The animations laid out so far and M_Random's index after their draws.
type Inter.Rolled is Data:
  Rolled{anims: List<&2, Inter.Anim>, mrnd: U32}

# The screen, the timer (WI_updateStats' cnt_pause while counting, cnt
# on the other two screens), the background's counter bcnt, the five
# counts shown (the kills, items and secret percentages, the time and
# the par, 4294967295 for one not shown yet) beside the five they climb
# to, the animations, M_Random's index and the player's attackdown and
# usedown as WI_checkForAccelerate last left them, in the bits BT_ATTACK
# and BT_USE take in a command. The pointer persists across intermissions
# as wi_stuff.c's static snl_pointeron does.
type Inter is Data:
  Inter{screen: Inter.Screen, cnt: U32, bcnt: U32, shown: V.Vec, target: V.Vec,
    anims: List<&2, Inter.Anim>, mrnd: U32, down: U32, pointer: Bool}

def Inter.screen(i: Inter) -> Inter.Screen:
  Inter{screen, cnt, bcnt, shown, target, anims, mrnd, down, pointer} = i
  screen

def Inter.cnt(i: Inter) -> U32:
  Inter{screen, cnt, bcnt, shown, target, anims, mrnd, down, pointer} = i
  cnt

def Inter.bcnt(i: Inter) -> U32:
  Inter{screen, cnt, bcnt, shown, target, anims, mrnd, down, pointer} = i
  bcnt

def Inter.shown(i: Inter) -> V.Vec:
  Inter{screen, cnt, bcnt, shown, target, anims, mrnd, down, pointer} = i
  shown

def Inter.target(i: Inter) -> V.Vec:
  Inter{screen, cnt, bcnt, shown, target, anims, mrnd, down, pointer} = i
  target

def Inter.mrnd(i: Inter) -> U32:
  Inter{screen, cnt, bcnt, shown, target, anims, mrnd, down, pointer} = i
  mrnd

def Inter.down(i: Inter) -> U32:
  Inter{screen, cnt, bcnt, shown, target, anims, mrnd, down, pointer} = i
  down

def Inter.pointer(i: Inter) -> Bool:
  Inter{screen, cnt, bcnt, shown, target, anims, mrnd, down, pointer} = i
  pointer

def Inter.pointed(pointer: Bool, i: Inter) -> Inter:
  Inter{screen, cnt, bcnt, shown, target, anims, mrnd, down, old} = i
  Inter{screen, cnt, bcnt, shown, target, anims, mrnd, down, pointer}

def Inter.drawn(draws: U32, i: Inter) -> Inter:
  Inter{screen, cnt, bcnt, shown, target, anims, mrnd, down, pointer} = i
  Inter{screen, cnt, bcnt, shown, target, anims, ((mrnd + draws : U32) .&. 255 : U32), down, pointer}

# The word WI_checkForAccelerate reads and leaves: attack in BT_ATTACK's
# bit, 1, and use in BT_USE's, 2.
def Inter.buttons(attack: Bool, use: Bool) -> U32:
  (Bool.to_u32(attack) .|. (Bool.to_u32(use) << 1n) : U32)

def Inter.attackdown(+wi: Inter) -> Bool:
  Bool.not(U32.is_zero((Inter.down(wi) .&. 1 : U32)))

def Inter.usedown(+wi: Inter) -> Bool:
  Bool.not(U32.is_zero((Inter.down(wi) .&. 2 : U32)))

def Inter.anims(i: Inter) -> List<&2, Inter.Anim>:
  Inter{screen, cnt, bcnt, shown, target, anims, mrnd, down, pointer} = i
  anims

def Inter.Anim.ctr(a: Inter.Anim) -> U32:
  Anim{ctr, nexttic} = a
  ctr

# A count not shown yet, Doom's -1.
def Inter.none() -> U32:
  4294967295

# How many animations the background has, and how many frames each: ten
# of three for WIMAP0.
def Inter.nanims() -> Nat:
  List.length(&2, G.Gfx.Spot, G.Gfx.wi.spots())

def Inter.frames() -> U32:
  3

# The period of every one of them, wi_stuff.c's TICRATE/3.
def Inter.period() -> U32:
  11

# A map's par in seconds, g_game.c's pars[1] for episode 1.
def Inter.par(+map: U32) -> U32:
  V.Vec.head(List.drop(&2, U32, [0, 30, 75, 120, 90, 165, 180, 180, 30, 165], U32.to_nat(map)))

# Where each count stands among the five: WI_updateStats counts them up
# in this order, a pause between.
def Inter.kills() -> U32:
  0

def Inter.items() -> U32:
  1

def Inter.secret() -> U32:
  2

def Inter.time() -> U32:
  3

def Inter.parat() -> U32:
  4

# The tally
# ---------

# WI_initVariables' guard against a level with nothing to count, which
# makes every percentage of it a hundred of nothing: a total of none
# counts as one.
def Inter.percent(+count: U32, +total: U32) -> U32:
  (count * 100 / Bool.pick(U32, U32.is_zero(total), 1, total) : U32)

# WI_initAnimatedBack for one animation: no frame drawn yet, and the
# first turn between one and a period after the counter stands, on a
# draw of M_Random.
def Inter.anims.one(+bcnt: U32, r: Inter.Rolled) -> Inter.Rolled:
  Rolled{anims, +mrnd} = r
  +drawn = M.Random.next(mrnd)
  Rolled{List.append(&2, Inter.Anim, anims,
      [Anim{Inter.none(), (bcnt + 1 + M.Random.at(drawn) % Inter.period() : U32)}]), drawn}

def Inter.anims.init(n: Nat, +bcnt: U32, r: Inter.Rolled) -> Inter.Rolled:
  match n:
    case 0n:
      r
    case 1n+m:
      Inter.anims.init(m, bcnt, Inter.anims.one(bcnt, r))

def Inter.start.of(t: S.Sim.Tally, par: U32, down: U32, r: Inter.Rolled) -> Inter:
  S.Tally{kills, items, secrets, maxkills, maxitems, maxsecret, time} = t
  Rolled{anims, mrnd} = r
  Inter{Count{1}, 35, 0,
    V.Vec.of_list([Inter.none(), Inter.none(), Inter.none(), Inter.none(), Inter.none()], 5),
    V.Vec.of_list([Inter.percent(kills, maxkills), Inter.percent(items, maxitems),
      Inter.percent(secrets, maxsecret), (time / 35 : U32), par], 5), anims, mrnd, down, False{}}

# WI_Start seeds ten animations; the first WI_Ticker precedes the tally melt.
# G_DoCompleted's attackdown and usedown prevent the exit press from
# also skipping the first count pause.
def Inter.start(t: S.Sim.Tally, par: U32, +mrnd: U32, down: U32) -> Inter:
  Inter.start.of(t, par, down, Inter.anims.init(Inter.nanims(), 0, Rolled{[], mrnd}))

# The tic
# -------

# WI_updateAnimatedBack for ANIM_ALWAYS: on its tic an animation shows
# its next frame, the first after the last, and turns again a period on.
def Inter.anim.tic(turns: Bool, +bcnt: U32, a: Inter.Anim) -> Inter.Anim:
  match turns:
    case False{}:
      a
    case True{}:
      Anim{+ctr, nexttic} = a
      Anim{((ctr + 1) % Inter.frames() : U32), (bcnt + Inter.period() : U32)}

def Inter.anims.tic(anims: List<&2, Inter.Anim>, +bcnt: U32) -> List<&2, Inter.Anim>:
  match anims:
    case []:
      []
    case Anim{ctr, +nexttic} <> rest:
      Inter.anim.tic(U32.is_eq(nexttic, bcnt), bcnt, Anim{ctr, nexttic}) <> Inter.anims.tic(rest, bcnt)

# The counting screen one state on when a count has reached its target.
def Inter.stepped(done: Bool, s: Inter.Screen) -> Inter.Screen:
  match done s:
    case True{} Count{+sp}:
      Count{(sp + 1 : U32)}
    case _ _:
      s

# A count on its way up: where it stands and whether it has arrived.
type Inter.Climb is Data:
  Climb{at: U32, done: Bool}

def Inter.climb.if(done: Bool, +at: U32, target: U32) -> Inter.Climb:
  match done:
    case True{}:
      Climb{target, True{}}
    case False{}:
      Climb{at, False{}}

# WI_updateStats' count-up: a count rises by its step and stops at its
# target, which it reaches from 4294967295, Doom's -1, in U32's wrapping
# arithmetic.
def Inter.climb(+shown: U32, +target: U32, step: U32) -> Inter.Climb:
  +at = (shown + step : U32)
  Inter.climb.if(U32.is_ge(at, target), at, target)

def Inter.climbed.put(done: Bool, +i: U32, +at: U32, wi: Inter) -> Inter:
  Inter{screen, cnt, bcnt, +shown, target, anims, mrnd, down, pointer} = wi
  Inter{Inter.stepped(done, screen), cnt, bcnt, V.Vec.set(shown, i, at), target, anims, mrnd, down, pointer}

def Inter.climbed.of(c: Inter.Climb, +i: U32, wi: Inter) -> Inter:
  Climb{at, done} = c
  Inter.climbed.put(done, i, at, wi)

# One of the three percentages counted up, two a tic.
def Inter.climbed(+i: U32, step: U32, +wi: Inter) -> Inter:
  Inter.climbed.of(Inter.climb(V.Vec.get(Inter.shown(wi), i), V.Vec.get(Inter.target(wi), i), step), i, wi)

def Inter.timed.put(t: Inter.Climb, p: Inter.Climb, wi: Inter) -> Inter:
  Climb{tat, tdone} = t
  Climb{pat, pdone} = p
  Inter{screen, cnt, bcnt, +shown, target, anims, mrnd, down, pointer} = wi
  Inter{Inter.stepped(Bool.and(tdone, pdone), screen), cnt, bcnt,
    V.Vec.set(V.Vec.set(shown, Inter.time(), tat), Inter.parat(), pat), target, anims, mrnd, down, pointer}

# WI_updateStats' eighth state: the time and the par climb three a tic
# together, and the screen moves on once both stand at their own.
def Inter.timed(+wi: Inter) -> Inter:
  Inter.timed.put(Inter.climb(V.Vec.get(Inter.shown(wi), Inter.time()),
      V.Vec.get(Inter.target(wi), Inter.time()), 3),
    Inter.climb(V.Vec.get(Inter.shown(wi), Inter.parat()), V.Vec.get(Inter.target(wi), Inter.parat()), 3), wi)

def Inter.paused(over: Bool, wi: Inter) -> Inter:
  match over:
    case False{}:
      Inter{screen, +cnt, bcnt, shown, target, anims, mrnd, down, pointer} = wi
      Inter{screen, (cnt - 1 : U32), bcnt, shown, target, anims, mrnd, down, pointer}
    case True{}:
      Inter{screen, cnt, bcnt, shown, target, anims, mrnd, down, pointer} = wi
      Inter{Inter.stepped(True{}, screen), 35, bcnt, shown, target, anims, mrnd, down, pointer}

# WI_updateStats' odd states: a second's pause, and then the next count.
def Inter.pause(+wi: Inter) -> Inter:
  Inter.paused(U32.is_eq(Inter.cnt(wi), 1), wi)

def Inter.next.of(r: Inter.Rolled, wi: Inter) -> Inter:
  Rolled{anims, mrnd} = r
  Inter{screen, cnt, bcnt, shown, target, old, was, down, pointer} = wi
  Inter{Next{}, 140, bcnt, shown, target, anims, mrnd, down, pointer}

# WI_initShowNextLoc: the screen that names the level to come, for four
# seconds, with the animations laid out again.
def Inter.next(+wi: Inter) -> Inter:
  Inter.next.of(Inter.anims.init(Inter.nanims(), Inter.bcnt(wi), Rolled{[], Inter.mrnd(wi)}), wi)

def Inter.leave(press: Bool, +wi: Inter) -> Inter:
  match press:
    case False{}:
      wi
    case True{}:
      Inter.next(Inter.drawn(Bool.to_u32(Sn.Sound.Event.draws(Sn.Sound.plain(Sn.Sound.sgcock(), Sn.Nobody{}))), wi))

# WI_updateStats' first test: a press before the counting is done shows
# every count at once and leaves the screen at its last state.
def Inter.skip(jump: Bool, wi: Inter) -> Inter:
  match jump:
    case False{}:
      wi
    case True{}:
      Inter{screen, cnt, bcnt, shown, +target, anims, mrnd, down, pointer} = wi
      Inter{Count{10}, cnt, bcnt, target, target, anims, mrnd, down, pointer}

def Inter.stats.sp(sp: U32, press: Bool, wi: Inter) -> Inter:
  match sp:
    case 2:
      Inter.climbed(Inter.kills(), 2, wi)
    case 4:
      Inter.climbed(Inter.items(), 2, wi)
    case 6:
      Inter.climbed(Inter.secret(), 2, wi)
    case 8:
      Inter.timed(wi)
    case 10:
      Inter.leave(press, wi)
    case _:
      Inter.pause(wi)

# WI_updateStats: the pauses of a second, the three percentages two a
# tic, the time and the par three a tic, and, once every count stands, a
# press to leave for the next level's screen. A press before that jumps
# to that last state, where the same press does no more, since Doom
# clears acceleratestage as it jumps.
def Inter.stats(+sp: U32, +press: Bool, +wi: Inter) -> Inter:
  +ten = U32.is_eq(sp, 10)
  Inter.stats.sp(Bool.pick(U32, press, 10, sp), Bool.and(press, ten),
    Inter.skip(Bool.and(press, Bool.not(ten)), wi))

def Inter.shownext.put(over: Bool, +left: U32, wi: Inter) -> Inter:
  match over:
    case False{}:
      Inter{screen, cnt, bcnt, shown, target, anims, mrnd, down, pointer} = wi
      Inter{screen, left, bcnt, shown, target, anims, mrnd, down, U32.is_lt((left .&. 31 : U32), 20)}
    case True{}:
      Inter{screen, cnt, bcnt, shown, target, anims, mrnd, down, pointer} = wi
      Inter{Last{}, 10, bcnt, shown, target, anims, mrnd, down, True{}}

# WI_updateShowNextLoc: four seconds, or a press, and then WI_initNoState
# with its ten tics.
def Inter.shownext(press: Bool, +wi: Inter) -> Inter:
  +left = (Inter.cnt(wi) - 1 : U32)
  Inter.shownext.put(Bool.or(U32.is_zero(left), press), left, wi)

# WI_updateNoState: ten tics, and at the end G_WorldDone, which the play
# reads as the level to start.
def Inter.nostate(wi: Inter) -> Inter:
  Inter{screen, +cnt, bcnt, shown, target, anims, mrnd, down, pointer} = wi
  Inter{screen, (cnt - 1 : U32), bcnt, shown, target, anims, mrnd, down, pointer}

def Inter.tic.screen(screen: Inter.Screen, press: Bool, wi: Inter) -> Inter:
  match screen:
    case Count{sp}:
      Inter.stats(sp, press, wi)
    case Next{}:
      Inter.shownext(press, wi)
    case Last{}:
      Inter.nostate(wi)

def Inter.tic.on(+bcnt: U32, press: Bool, down: U32, wi: Inter) -> Inter:
  Inter{+screen, cnt, was, shown, target, anims, mrnd, old, pointer} = wi
  Inter.tic.screen(screen, press,
    Inter{screen, cnt, bcnt, shown, target, Inter.anims.tic(anims, bcnt), mrnd, down, pointer})

# WI_checkForAccelerate's press: attack or use down on this tic and not
# on the last.
def Inter.pressed(+down: U32, +wi: Inter) -> Bool:
  Bool.not(U32.is_zero((down .&. U32.not(Inter.down(wi)) : U32)))

def Inter.sound.finished(+sp: U32, screen: Inter.Screen) -> Bool:
  match screen:
    case Count{next}:
      Bool.not(U32.is_eq(sp, next))
    case _:
      True{}

def Inter.sound.counting(+sp: U32, +press: Bool, +bcnt: U32, after: Inter) ->
  List<&2, Sn.Sound.Event>:
  match press:
    case True{}:
      [Sn.Sound.plain(Bool.pick(U32, U32.is_eq(sp, 10), Sn.Sound.sgcock(), Sn.Sound.barexp()), Sn.Nobody{})]
    case False{}:
      +counts = Bool.or(U32.is_eq(sp, 2), Bool.or(U32.is_eq(sp, 4),
        Bool.or(U32.is_eq(sp, 6), U32.is_eq(sp, 8))))
      +ticks = Bool.and(counts, U32.is_zero((bcnt .&. 3 : U32)))
      +done = Bool.and(counts, Inter.sound.finished(sp, Inter.screen(after)))
      List.append(&2, Sn.Sound.Event,
        Bool.pick(List<&2, Sn.Sound.Event>, ticks, [Sn.Sound.plain(Sn.Sound.pistol(), Sn.Nobody{})], []),
        Bool.pick(List<&2, Sn.Sound.Event>, done, [Sn.Sound.plain(Sn.Sound.barexp(), Sn.Nobody{})], []))

def Inter.sound(+press: Bool, before: Inter, +after: Inter) -> List<&2, Sn.Sound.Event>:
  Inter{+screen, cnt, bcnt, shown, target, anims, mrnd, down, pointer} = before
  match screen:
    case Count{sp}:
      Inter.sound.counting(sp, press, Inter.bcnt(after), after)
    case _:
      []

def Inter.heard(events: List<&2, Sn.Sound.Event>, wi: Inter) -> Inter:
  match events:
    case []:
      wi
    case event <> rest:
      Inter.heard(rest, Inter.drawn(Bool.to_u32(Sn.Sound.Event.draws(event)), wi))

# The sgcock pitch was drawn before Next's animation seeds in Inter.leave.
def Inter.ticked(screen: Inter.Screen, before: Inter, +after: Inter, press: Bool) -> Inter:
  match screen:
    case Next{}:
      after
    case _:
      Inter.heard(Inter.sound(press, before, after), after)

# WI_Ticker: the background's counter, then WI_checkForAccelerate, then
# the screen's own update, which begins with the animations. Its first
# display consumes the tally melt after this update.
def Inter.tic(+down: U32, +wi: Inter) -> Inter:
  +press = Inter.pressed(down, wi)
  +after = Inter.tic.on((Inter.bcnt(wi) + 1 : U32), press, down, wi)
  Inter.drawn(Bool.pick(U32, U32.is_zero(Inter.bcnt(wi)), 320, 0),
    Inter.ticked(Inter.screen(after), wi, after, press))

def Inter.over.of(s: Inter.Screen, +cnt: U32) -> Bool:
  match s:
    case Last{}:
      U32.is_zero(cnt)
    case _:
      False{}

# Whether G_WorldDone has run: the last screen's ten tics are up, and
# the next level loads on the tic after.
def Inter.over(+wi: Inter) -> Bool:
  Inter.over.of(Inter.screen(wi), Inter.cnt(wi))

# The screen and its counts, for the tests.
def Inter.Screen.show(s: Inter.Screen) -> String:
  match s:
    case Count{sp}:
      "count " ++ U32.show(sp)
    case Next{}:
      "next"
    case Last{}:
      "done"

def Inter.count.show(+n: U32) -> String:
  Bool.pick(String, U32.is_eq(n, Inter.none()), " -", " " ++ U32.show(n))

def Inter.counts.show(n: Nat, +v: V.Vec, +i: U32) -> String:
  match n:
    case 0n:
      ""
    case 1n+m:
      Inter.count.show(V.Vec.get(v, i)) ++ Inter.counts.show(m, v, (i + 1 : U32))

def Inter.anims.show(anims: List<&2, Inter.Anim>) -> String:
  match anims:
    case []:
      ""
    case +a <> rest:
      Inter.count.show(Inter.Anim.ctr(a)) ++ Inter.anims.show(rest)

def Inter.show(wi: Inter) -> String:
  Inter{screen, +cnt, +bcnt, +shown, target, +anims, +mrnd, down, pointer} = wi
  Inter.Screen.show(screen) ++ " cnt " ++ U32.show(cnt) ++ " bcnt " ++ U32.show(bcnt) ++ " shown"
    ++ Inter.counts.show(5n, shown, 0) ++ " anims" ++ Inter.anims.show(anims) ++ " random "
    ++ U32.show(mrnd)

# The draw
# --------

# Doom's V_DrawPatch: the patch of a name at x, y, its offsets taken
# off, over whatever the frame holds.
def Inter.patch(+gfx: G.Gfx, name: String, x: U32, y: U32, mem: Array<U32>) -> Array<U32>:
  D.Draw.patch(mem, G.Gfx.patch(gfx, name), x, y)

# A patch's width, height, left offset or top offset, as the array holds
# its header.
def Inter.word.of(p: Array<U32> & U32) -> Array<U32> & U32:
  (mem, w) = p
  (mem, w)

def Inter.word(+gfx: G.Gfx, name: String, field: U32, mem: Array<U32>) -> Array<U32> & U32:
  Inter.word.of(B.Bytes.u16(mem, (G.Gfx.patch(gfx, name) + field : U32)))

# A patch centred across the screen, as WI_drawLF and WI_drawEL centre
# the level names and their words.
def Inter.centre.at(+gfx: G.Gfx, name: String, +y: U32, p: Array<U32> & U32) -> Array<U32>:
  (mem, +w) = p
  Inter.patch(gfx, name, ((320 - w) / 2 : U32), y, mem)

def Inter.centre(+gfx: G.Gfx, +name: String, y: U32, mem: Array<U32>) -> Array<U32>:
  Inter.centre.at(gfx, name, y, Inter.word(gfx, name, 0, mem))

# The pen of a number being drawn right to left: the array and the
# column it has reached.
type Inter.Pen is Type:
  Pen{mem: Array<U32>, x: U32}

def Inter.Pen.mem(st: Inter.Pen) -> Array<U32>:
  Pen{mem, x} = st
  mem

def Inter.Pen.back(+by: U32, st: Inter.Pen) -> Inter.Pen:
  Pen{mem, +x} = st
  Pen{mem, (x - by : U32)}

def Inter.num.one(+gfx: G.Gfx, +d: U32, +y: U32, +fw: U32, st: Inter.Pen) -> Inter.Pen:
  Pen{mem, +x} = st
  Pen{Inter.patch(gfx, "WINUM" ++ U32.show(d), (x - fw : U32), y, mem), (x - fw : U32)}

# WI_drawNum: the digits right to left from the pen, the last first.
def Inter.num(k: Nat, +gfx: G.Gfx, +n: U32, +y: U32, +fw: U32, st: Inter.Pen) -> Inter.Pen:
  match k:
    case 0n:
      st
    case 1n+m:
      Inter.num(m, gfx, (n / 10 : U32), y, fw, Inter.num.one(gfx, (n % 10 : U32), y, fw, st))

def Inter.digits.go(fuel: Nat, done: Bool, +n: U32, d: Nat) -> Nat:
  match fuel done:
    case _ True{}:
      d
    case 0n _:
      d
    case 1n+f False{}:
      Inter.digits.go(f, U32.is_zero((n / 10 : U32)), (n / 10 : U32), 1n+d)

# How many digits WI_drawNum draws when it counts them itself: one for
# zero, else as many as the number has.
def Inter.digits(+n: U32) -> Nat:
  Bool.pick(Nat, U32.is_zero(n), 1n, Inter.digits.go(10n, False{}, n, 0n))

def Inter.percent.if(shows: Bool, +gfx: G.Gfx, +x: U32, +y: U32, +n: U32, +fw: U32, mem: Array<U32>) ->
  Array<U32>:
  match shows:
    case False{}:
      mem
    case True{}:
      Inter.Pen.mem(Inter.num(Inter.digits(n), gfx, n, y, fw,
        Pen{Inter.patch(gfx, "WIPCNT", x, y, mem), x}))

# WI_drawPercent: the sign at x with the number to its left; a count
# still unshown draws nothing.
def Inter.percent.draw(+gfx: G.Gfx, x: U32, y: U32, +n: U32, fw: U32, mem: Array<U32>) -> Array<U32>:
  Inter.percent.if(Bool.not(F.Fixed.is_neg(n)), gfx, x, y, n, fw, mem)

def Inter.colon(drawn: Bool, +gfx: G.Gfx, +y: U32, st: Inter.Pen) -> Inter.Pen:
  match drawn:
    case False{}:
      st
    case True{}:
      Pen{mem, +x} = st
      Pen{Inter.patch(gfx, "WICOLON", x, y, mem), x}

# One turn of WI_drawTime's loop: two digits of the minutes or seconds,
# then the colon before them, which the first turn always draws.
def Inter.time.step(+gfx: G.Gfx, +t: U32, +div: U32, +y: U32, +fw: U32, +cw: U32, st: Inter.Pen) ->
  Inter.Pen:
  Inter.colon(Bool.or(U32.is_eq((div * 60 : U32), 60), Bool.not(U32.is_zero((t / (div * 60) : U32)))),
    gfx, y, Inter.Pen.back(cw, Inter.num(2n, gfx, ((t / div) % 60 : U32), y, fw, st)))

def Inter.time.go(fuel: Nat, more: Bool, +gfx: G.Gfx, +t: U32, +div: U32, +y: U32, +fw: U32, +cw: U32,
  st: Inter.Pen) -> Inter.Pen:
  match fuel more:
    case 0n _:
      st
    case _ False{}:
      st
    case 1n+f True{}:
      Inter.time.go(f, Bool.not(U32.is_zero((t / (div * 60) : U32))), gfx, t, (div * 60 : U32), y, fw, cw,
        Inter.time.step(gfx, t, div, y, fw, cw, st))

def Inter.sucks.at(+gfx: G.Gfx, +x: U32, +y: U32, p: Array<U32> & U32) -> Array<U32>:
  (mem, +w) = p
  Inter.patch(gfx, "WISUCKS", (x - w : U32), y, mem)

def Inter.time.if(shows: Bool, quick: Bool, +gfx: G.Gfx, +x: U32, +y: U32, +t: U32, +fw: U32, +cw: U32,
  mem: Array<U32>) -> Array<U32>:
  match shows quick:
    case False{} _:
      mem
    case True{} True{}:
      Inter.Pen.mem(Inter.time.go(2n, True{}, gfx, t, 1, y, fw, cw, Pen{mem, x}))
    case True{} False{}:
      Inter.sucks.at(gfx, x, y, Inter.word(gfx, "WISUCKS", 0, mem))

# WI_drawTime: minutes and seconds right to left from x, or the word for
# a level that took over an hour; a time still unshown draws nothing.
def Inter.time.draw(+gfx: G.Gfx, x: U32, y: U32, +t: U32, fw: U32, cw: U32, mem: Array<U32>) -> Array<U32>:
  Inter.time.if(Bool.not(F.Fixed.is_neg(t)), U32.is_le(t, 3599), gfx, x, y, t, fw, cw, mem)

# WI_drawAnimatedBack: each animation that has a frame, at its place.
def Inter.back.one(shows: Bool, +ctr: U32, +gfx: G.Gfx, +spot: G.Gfx.Spot, +j: U32, mem: Array<U32>) ->
  Array<U32>:
  match shows:
    case False{}:
      mem
    case True{}:
      Inter.patch(gfx, "WIA00" ++ U32.show(j) ++ "0" ++ U32.show(ctr), G.Gfx.Spot.x(spot),
        G.Gfx.Spot.y(spot), mem)

def Inter.back.go(anims: List<&2, Inter.Anim>, spots: List<&2, G.Gfx.Spot>, +gfx: G.Gfx, +j: U32,
  mem: Array<U32>) -> Array<U32>:
  match anims spots:
    case Anim{+ctr, nexttic} <> rest spot <> more:
      Inter.back.go(rest, more, gfx, (j + 1 : U32),
        Inter.back.one(Bool.not(U32.is_eq(ctr, Inter.none())), ctr, gfx, spot, j, mem))
    case _ _:
      mem

# WI_slamBackground and the animations over it.
def Inter.back(+gfx: G.Gfx, anims: List<&2, Inter.Anim>, mem: Array<U32>) -> Array<U32>:
  Inter.back.go(anims, G.Gfx.wi.spots(), gfx, 0, Inter.patch(gfx, "WIMAP0", 0, 0, mem))

# What G_DoCompleted hands WI_Start for the map screen, its wminfo: the
# map left, the map to come, and whether E1M9 is done.
type Inter.Trip is Data:
  Trip{last: L.Level.Name, next: L.Level.Name, didsecret: Bool}

def Inter.Trip.next(t: Inter.Trip) -> L.Level.Name:
  Trip{last, next, didsecret} = t
  next

# A map's name, the patch WILV00 for E1M1.
def Inter.name(+map: U32) -> String:
  G.Gfx.wi.level() ++ U32.show((map - 1 : U32))

# WI_drawLF: the name of the map left at the top, and "Finished!" a name
# and a quarter under it.
def Inter.finished.of(+gfx: G.Gfx, p: Array<U32> & U32) -> Array<U32>:
  (mem, +h) = p
  Inter.centre(gfx, "WIF", (2 + 5 * h / 4 : U32), mem)

def Inter.finished(+gfx: G.Gfx, +name: String, mem: Array<U32>) -> Array<U32>:
  Inter.finished.of(gfx, Inter.word(gfx, name, 2, Inter.centre(gfx, name, 2, mem)))

# WI_drawEL: "Entering" at the top, and the name of the map to come
# under it.
def Inter.entering.of(+gfx: G.Gfx, name: String, p: Array<U32> & U32) -> Array<U32>:
  (mem, +h) = p
  Inter.centre(gfx, name, (2 + 5 * h / 4 : U32), mem)

def Inter.entering(+gfx: G.Gfx, +name: String, mem: Array<U32>) -> Array<U32>:
  Inter.entering.of(gfx, name, Inter.word(gfx, name, 2, Inter.centre(gfx, "WIENTER", 2, mem)))

# The counts' three rows, each a word on the left and a percentage on
# the right, a line and a half of digits apart.
def Inter.rows(+gfx: G.Gfx, +wi: Inter, +fw: U32, +lh: U32, mem: Array<U32>) -> Array<U32>:
  Inter.percent.draw(gfx, 270, (50 + 2 * lh : U32), V.Vec.get(Inter.shown(wi), Inter.secret()), fw,
    Inter.patch(gfx, "WISCRT2", 50, (50 + 2 * lh : U32),
      Inter.percent.draw(gfx, 270, (50 + lh : U32), V.Vec.get(Inter.shown(wi), Inter.items()), fw,
        Inter.patch(gfx, "WIOSTI", 50, (50 + lh : U32),
          Inter.percent.draw(gfx, 270, 50, V.Vec.get(Inter.shown(wi), Inter.kills()), fw,
            Inter.patch(gfx, "WIOSTK", 50, 50, mem))))))

# The time on the left of the bottom row and the par on the right.
def Inter.times(+gfx: G.Gfx, +wi: Inter, +fw: U32, +cw: U32, mem: Array<U32>) -> Array<U32>:
  Inter.time.draw(gfx, 304, 168, V.Vec.get(Inter.shown(wi), Inter.parat()), fw, cw,
    Inter.patch(gfx, "WIPAR", 176, 168,
      Inter.time.draw(gfx, 144, 168, V.Vec.get(Inter.shown(wi), Inter.time()), fw, cw,
        Inter.patch(gfx, "WITIME", 16, 168, mem))))

def Inter.stats.draw.of(+gfx: G.Gfx, +wi: Inter, +fw: U32, +cw: U32, p: Array<U32> & U32) -> Array<U32>:
  (mem, +nh) = p
  Inter.times(gfx, wi, fw, cw, Inter.rows(gfx, wi, fw, (3 * nh / 2 : U32), mem))

def Inter.stats.draw.cw(+gfx: G.Gfx, +wi: Inter, +fw: U32, p: Array<U32> & U32) -> Array<U32>:
  (mem, cw) = p
  Inter.stats.draw.of(gfx, wi, fw, cw, Inter.word(gfx, "WINUM0", 2, mem))

def Inter.stats.draw.fw(+gfx: G.Gfx, +wi: Inter, p: Array<U32> & U32) -> Array<U32>:
  (mem, fw) = p
  Inter.stats.draw.cw(gfx, wi, fw, Inter.word(gfx, "WICOLON", 0, mem))

# WI_drawStats: the background and its animations, the level's name over
# "Finished!", the three counts, and the time beside the par.
def Inter.stats.draw(+gfx: G.Gfx, +wi: Inter, +name: String, mem: Array<U32>) -> Array<U32>:
  Inter.stats.draw.fw(gfx, wi, Inter.word(gfx, "WINUM0", 0,
    Inter.finished(gfx, name, Inter.back(gfx, Inter.anims(wi), mem))))

# WI_drawOnLnode's fit: a patch fits when its box, its offsets taken
# off, is inside the screen.
def Inter.fits.box(+x: U32, +y: U32, +w: U32, +h: U32) -> Bool:
  Bool.and(Bool.and(F.Fixed.ge(x, 0), U32.is_lt((x + w : U32), 320)),
    Bool.and(F.Fixed.ge(y, 0), U32.is_lt((y + h : U32), 200)))

def Inter.fits.of(+x: U32, +y: U32, p: Array<U32> & List<&2, U32>) -> Array<U32> & Bool:
  (mem, +box) = p
  (mem, Inter.fits.box((x - G.Gfx.s16(V.Vec.head(List.drop(&2, U32, box, 2n))) : U32),
    (y - G.Gfx.s16(V.Vec.head(List.drop(&2, U32, box, 3n))) : U32), V.Vec.head(box),
    V.Vec.head(List.drop(&2, U32, box, 1n))))

# Whether a patch of a name fits at a place: its width, height and two
# offsets, read from the array as V_DrawPatch reads them.
def Inter.fits(+gfx: G.Gfx, name: String, x: U32, y: U32, mem: Array<U32>) -> Array<U32> & Bool:
  Inter.fits.of(x, y, B.Bytes.each(~U32, ~B.Bytes.u16, B.Bytes.fields(4n, G.Gfx.patch(gfx, name), 2, [0]),
    mem))

def Inter.lnode.last(fits: Bool, +gfx: G.Gfx, name: String, +x: U32, +y: U32, mem: Array<U32>) ->
  Array<U32>:
  match fits:
    case True{}:
      Inter.patch(gfx, name, x, y, mem)
    case False{}:
      mem

def Inter.lnode.last.of(+gfx: G.Gfx, name: String, +x: U32, +y: U32, p: Array<U32> & Bool) -> Array<U32>:
  (mem, fits) = p
  Inter.lnode.last(fits, gfx, name, x, y, mem)

# The candidates after the first, of which vanilla tries one more.
def Inter.lnode.rest(names: List<&2, String>, +gfx: G.Gfx, +x: U32, +y: U32, mem: Array<U32>) ->
  Array<U32>:
  match names:
    case []:
      mem
    case +name <> rest:
      Inter.lnode.last.of(gfx, name, x, y, Inter.fits(gfx, name, x, y, mem))

def Inter.lnode.first(fits: Bool, +gfx: G.Gfx, name: String, rest: List<&2, String>, +x: U32, +y: U32,
  mem: Array<U32>) -> Array<U32>:
  match fits:
    case True{}:
      Inter.patch(gfx, name, x, y, mem)
    case False{}:
      Inter.lnode.rest(rest, gfx, x, y, mem)

def Inter.lnode.first.of(+gfx: G.Gfx, name: String, rest: List<&2, String>, +x: U32, +y: U32,
  p: Array<U32> & Bool) -> Array<U32>:
  (mem, fits) = p
  Inter.lnode.first(fits, gfx, name, rest, x, y, mem)

# WI_drawOnLnode: the first of the patches that fits at the place, drawn
# there; none fitting draws nothing, where vanilla prints its complaint.
# Vanilla tries at most two, and so does this.
def Inter.lnode(names: List<&2, String>, +gfx: G.Gfx, +x: U32, +y: U32, mem: Array<U32>) -> Array<U32>:
  match names:
    case []:
      mem
    case +name <> rest:
      Inter.lnode.first.of(gfx, name, rest, x, y, Inter.fits(gfx, name, x, y, mem))

# wi_stuff.c's lnodes[0]: where each map of episode 1 stands on WIMAP0.
def Inter.lnodes() -> List<&2, G.Gfx.Spot>:
  [G.Spot{185, 164}, G.Spot{148, 143}, G.Spot{69, 122}, G.Spot{209, 102}, G.Spot{116, 89},
    G.Spot{166, 55}, G.Spot{71, 56}, G.Spot{135, 29}, G.Spot{71, 24}]

def Inter.on.at(names: List<&2, String>, +gfx: G.Gfx, spots: List<&2, G.Gfx.Spot>, mem: Array<U32>) ->
  Array<U32>:
  match spots:
    case []:
      mem
    case +spot <> rest:
      Inter.lnode(names, gfx, G.Gfx.Spot.x(spot), G.Gfx.Spot.y(spot), mem)

# WI_drawOnLnode on a map of the episode, at its place.
def Inter.on(names: List<&2, String>, +gfx: G.Gfx, +map: U32, mem: Array<U32>) -> Array<U32>:
  Inter.on.at(names, gfx, List.drop(&2, G.Gfx.Spot, Inter.lnodes(), U32.to_nat((map - 1 : U32))), mem)

# A splat on each of n maps from a map on.
def Inter.splats(n: Nat, +gfx: G.Gfx, +map: U32, mem: Array<U32>) -> Array<U32>:
  match n:
    case 0n:
      mem
    case 1n+m:
      Inter.splats(m, gfx, (map + 1 : U32), Inter.on(["WISPLAT"], gfx, map, mem))

# The patches to try on a place while they show, and none while not.
def Inter.showing(shows: Bool, names: List<&2, String>) -> List<&2, String>:
  Bool.pick(List<&2, String>, shows, names, [])

# WI_drawShowNextLoc's marks: a splat on every map up to the one left,
# or up to the one before the map to come when the one left is E1M9; a
# splat on E1M9 once it is done; and the pointer on the map to come
# while it shows.
def Inter.marks(+gfx: G.Gfx, +last: U32, +next: U32, didsecret: Bool, on: Bool, mem: Array<U32>) ->
  Array<U32>:
  Inter.on(Inter.showing(on, ["WIURH0", "WIURH1"]), gfx, next,
    Inter.on(Inter.showing(didsecret, ["WISPLAT"]), gfx, 9,
      Inter.splats(U32.to_nat(Bool.pick(U32, U32.is_eq(last, 9), (next - 1 : U32), last)), gfx, 1, mem)))

# WI_drawShowNextLoc: the background, the marks, and the name of the
# map to come.
def Inter.next.draw(+gfx: G.Gfx, +wi: Inter, trip: Inter.Trip, on: Bool, mem: Array<U32>) -> Array<U32>:
  Trip{L.Name{e, +last}, L.Name{f, +next}, didsecret} = trip
  Inter.entering(gfx, Inter.name(next), Inter.marks(gfx, last, next, didsecret, on,
    Inter.back(gfx, Inter.anims(wi), mem)))

def Inter.frame.of(s: Inter.Screen, +gfx: G.Gfx, +wi: Inter, +trip: Inter.Trip, mem: Array<U32>) ->
  Array<U32>:
  match s:
    case Count{sp}:
      Trip{L.Name{e, +last}, next, didsecret} = trip
      Inter.stats.draw(gfx, wi, Inter.name(last), mem)
    case Next{}:
      Inter.next.draw(gfx, wi, trip, Inter.pointer(wi), mem)
    case Last{}:
      Inter.next.draw(gfx, wi, trip, True{}, mem)

# WI_Drawer: the counting screen, the one that names the map to come
# with its pointer flashing, and the last, which holds that pointer on.
def Inter.frame(+gfx: G.Gfx, +wi: Inter, +trip: Inter.Trip, mem: Array<U32>) -> Array<U32>:
  Inter.frame.of(Inter.screen(wi), gfx, wi, trip, mem)

# The play
# --------

# GS_LEVEL carries didsecret and WI_Drawer's static pointer through
# loads and deaths. GS_INTERMISSION keeps the ended level and its trip.
type Play is Data:
  Playing{state: S.State, didsecret: Bool, pointer: Bool}
  Showing{inter: Inter, after: S.State, trip: Inter.Trip}
  Ending{finale: Fi.Finale}

type Play.Step is Data:
  Step{play: Play, sounds: List<&2, Sn.Sound.Event>}

def Play.channels(play: Play, chans: List<&2, Maybe<&2, C.Channel>>) -> List<&2, Maybe<&2, C.Channel>>:
  match play:
    case Playing{+state, didsecret, pointer}:
      C.Channel.update(~S.State, ~(s => source => S.Sim.sound.parameters(False{}, s, source)), state, chans)
    case _:
      C.Channel.finished(chans)

# A new game on a map: G_InitNew, then G_DoLoadLevel.
def Play.start(level: L.Level) -> Play:
  Playing{Tic.State.start(level), False{}, False{}}

def Play.destination(secret: Bool, +episode: U32, +map: U32) -> L.Level.Name:
  match secret:
    case True{}:
      L.Name{episode, 9}
    case False{}:
      L.Name{episode, Bool.pick(U32, U32.is_eq(map, 9), 4, (map + 1 : U32))}

def Play.shown(pointer: Bool, +last: L.Level.Name, next: L.Level.Name, didsecret: Bool, +after: S.State) -> Play:
  L.Name{e, +map} = last
  Showing{Inter.pointed(pointer, Inter.start(S.Sim.tally(after), Inter.par(map), S.State.mrnd(after),
      Inter.buttons(S.Sim.Face.attackdown(S.State.face(after)), S.State.usedown(after)))), after,
    Trip{last, next, Bool.or(didsecret, U32.is_eq(map, 9))}}

def Play.after.ended(how: S.Sim.Exit, pointer: Bool, map: L.Level.Name, didsecret: Bool, +after: S.State) -> Play:
  match how map:
    case S.Unended{} name:
      Playing{after, didsecret, pointer}
    case S.Ended{secret} L.Name{+episode, +map}:
      Play.shown(pointer, L.Name{episode, map}, Play.destination(secret, episode, map), didsecret, after)

def Play.after(pointer: Bool, didsecret: Bool, +after: S.State) -> Play:
  Play.after.ended(S.State.ended(after), pointer, L.Level.name(S.State.level(after)), didsecret, after)

# G_DoReborn ahead of the tic: a death that asked for the level again
# has the map as loaded reloaded.
def Play.reborn(reborn: Bool, +level: L.Level, state: S.State) -> S.State:
  match reborn:
    case True{}:
      Tic.State.reloaded(level, state)
    case False{}:
      state

# The sounds a level's tic started; none once it has ended, since an
# ended level runs no tic.
def Play.sounds(before: S.Sim.Exit, +after: S.State) -> List<&2, Sn.Sound.Event>:
  match before:
    case S.Unended{}:
      S.State.sounds(after)
    case _:
      []

def Play.ticked(before: S.Sim.Exit, pointer: Bool, map: L.Level.Name, didsecret: Bool, +after: S.State) -> Play:
  match before map:
    case S.Unended{} L.Name{episode, 8}:
      Playing{after, didsecret, pointer}
    case S.Ended{secret} L.Name{episode, 8}:
      Ending{Fi.Finale.tic(Fi.Finale.start())}
    case _ name:
      Play.after(pointer, didsecret, after)

# A tic of the current scene: the level, tally or finale. A reload makes
# the player anew, as G_PlayerReborn does, so E1M9 is no longer done.
def Play.step(+level: L.Level, +cmd: K.Cmd, play: Play) -> Play.Step:
  match play:
    case Playing{+state, didsecret, pointer}:
      +ended = S.State.ended(state)
      +reborn = S.State.reborn(state)
      +after = Tic.Sim.tic(cmd, Play.reborn(reborn, level, state))
      Step{Play.ticked(ended, pointer, L.Level.name(S.State.level(after)), Bool.and(didsecret, Bool.not(reborn)), after), Play.sounds(ended, after)}
    case Showing{+wi, after, trip}:
      +down = Inter.buttons(K.Cmd.attack(cmd), K.Cmd.use(cmd))
      +ticked = Inter.tic(down, wi)
      Step{Showing{ticked, after, trip}, Inter.sound(Inter.pressed(down, wi), wi, ticked)}
    case Ending{f}:
      Step{Ending{Fi.Finale.tic(f)}, []}

def Play.Step.play(step: Play.Step) -> Play:
  Step{play, sounds} = step
  play

def Play.Step.sounds(step: Play.Step) -> List<&2, Sn.Sound.Event>:
  Step{play, sounds} = step
  sounds

# G_DoWorldDone on the map the tally's trip names, as loaded. G_WorldDone
# also marks E1M9 done after the secret exit; that is left out, since
# leaving E1M9 marks it again before anything reads it.
def Play.enter(+level: L.Level, +wi: Inter, after: S.State, trip: Inter.Trip) -> Play:
  Trip{last, next, didsecret} = trip
  Playing{Tic.State.carried(level, Inter.mrnd(wi), Inter.usedown(wi), Inter.attackdown(wi), after), didsecret, Inter.pointer(wi)}

# A play and what it is drawn from: the frame's array, the graphics, the
# tables and the map as loaded.
type Play.World is Type:
  World{play: Play, mem: Array<U32>, gfx: G.Gfx, tables: P.Project.Tables, level: L.Level}

def Play.World.start.gl(mem: Array<U32>, gl: G.Gfx & L.Level) -> Play.World:
  (+gfx, +level) = gl
  World{Play.start(level), mem, gfx, P.Project.tables(level), level}

# A new game on a map, in the world opened for it.
def Play.World.start(p: Array<U32> & G.Gfx & L.Level) -> Play.World:
  (mem, gl) = p
  Play.World.start.gl(mem, gl)

def Play.World.of.gl(+wi: Inter, after: S.State, trip: Inter.Trip, mem: Array<U32>, gl: G.Gfx & L.Level) ->
  Play.World:
  (+gfx, +level) = gl
  World{Play.enter(level, wi, after, trip), mem, gfx, P.Project.tables(level), level}

# A map, its graphics and the frame's array from the WAD BENDOOM_IWAD
# names.
def Play.open(at: L.Level.Name) -> IO(Array<U32> & G.Gfx & L.Level):
  L.Name{+episode, +map} = at
  G.Gfx.open(episode, map)

def Play.loaded(phase: U32, wi: Inter, after: S.State, trip: Inter.Trip,
  p: Array<U32> & G.Gfx & L.Level) -> Play.World:
  (mem, gl) = p
  Play.World.of.gl(wi, after, trip, Array.set(U32, mem, G.Gfx.fuzzpos(), phase), gl)

def Play.load.next(wi: Inter, after: S.State, +trip: Inter.Trip, p: Array<U32> & U32) -> IO(Play.World):
  (mem, phase) = p
  IO.bind(Array<U32> & G.Gfx & L.Level, Play.World, Play.open(Inter.Trip.next(trip)),
    opened => IO.pure(Play.World, Play.loaded(phase, wi, after, trip, opened)))

# G_WorldDone once the tally's last screen is over: the map the trip
# names opened and entered.
def Play.load.if(over: Bool, wi: Inter, after: S.State, +trip: Inter.Trip, mem: Array<U32>, gfx: G.Gfx,
  tables: P.Project.Tables, level: L.Level) -> IO(Play.World):
  match over:
    case False{}:
      IO.pure(Play.World, World{Showing{wi, after, trip}, mem, gfx, tables, level})
    case True{}:
      Play.load.next(wi, after, trip, B.Bytes.at(mem, G.Gfx.fuzzpos()))

# The world before a tic: the map the tally asks for, if it asks for
# one, which loads before the next tic.
def Play.load(w: Play.World) -> IO(Play.World):
  World{play, mem, gfx, tables, level} = w
  match play:
    case Showing{+wi, after, trip}:
      Play.load.if(Inter.over(wi), wi, after, trip, mem, gfx, tables, level)
    case playing:
      IO.pure(Play.World, World{playing, mem, gfx, tables, level})

def Play.World.stepped(mem: Array<U32>, gfx: G.Gfx, tables: P.Project.Tables, level: L.Level, step: Play.Step) ->
  Play.World & List<&2, Sn.Sound.Event>:
  Step{play, sounds} = step
  (World{play, mem, gfx, tables, level}, sounds)

# A tic of the play in its world.
def Play.World.step(cmd: K.Cmd, w: Play.World) -> Play.World & List<&2, Sn.Sound.Event>:
  World{play, mem, gfx, tables, +level} = w
  Play.World.stepped(mem, gfx, tables, level, Play.step(level, cmd, play))

# A play in its world after some tics, and the sounds they started, in
# order.
type Play.Run is Type:
  Ran{world: Play.World, sounds: List<&2, Sn.Sound.Event>}

def Play.heard(sounds: List<&2, Sn.Sound.Event>, p: Play.World & List<&2, Sn.Sound.Event>) -> Play.Run:
  (world, more) = p
  Ran{world, List.append(&2, Sn.Sound.Event, sounds, more)}

# A tic for each command, each after the
# map the play asks for, if it asks for one, has loaded.
def Play.run(cmds: List<&2, K.Cmd>, run: Play.Run) -> IO(Play.Run):
  match cmds:
    case []:
      IO.pure(Play.Run, run)
    case +cmd <> rest:
      Ran{world, sounds} = run
      IO.bind(Play.World, Play.Run, Play.load(world),
        loaded => Play.run(rest, Play.heard(sounds, Play.World.step(cmd, loaded))))

# The scene's song, as S_Start and WI_Start name it: the map's own,
# mus_e1m1 plus the episode's nine maps before it and the map's place,
# which is D_ before the map's name, D_INTER through the tally, and
# D_VICTOR through the finale.
def Play.song(play: Play) -> String:
  match play:
    case Playing{state, didsecret, pointer}:
      "D_" ++ L.Level.Name.marker(L.Level.name(S.State.level(state)))
    case Showing{inter, after, trip}:
      "D_INTER"
    case Ending{f}:
      "D_VICTOR"

# The songs a scene of the episode can name.
def Play.songs() -> List<&2, String>:
  ["D_E1M1", "D_E1M2", "D_E1M3", "D_E1M4", "D_E1M5", "D_E1M6", "D_E1M7", "D_E1M8", "D_E1M9", "D_INTER", "D_VICTOR"]

def Play.frame.show(first: Bool, tables: P.Project.Tables, gfx: G.Gfx, wi: Inter,
  after: S.State, trip: Inter.Trip, messages: Bool, mem: Array<U32>) -> Array<U32> & U32:
  match first:
    case True{}:
      R.Render.frame(tables, gfx, after, messages, mem)
    case False{}:
      (Inter.frame(gfx, wi, trip, mem), 0)

# Each scene draws into the same 320 by 200 array. The completion tic
# still draws its level; WI_Drawer starts after the first WI_Ticker.
def Play.frame(tables: P.Project.Tables, gfx: G.Gfx, play: Play, messages: Bool, mem: Array<U32>) -> Array<U32> & U32:
  match play:
    case Playing{+state, didsecret, pointer}:
      R.Render.frame(tables, gfx, state, messages, mem)
    case Showing{+wi, after, trip}:
      Play.frame.show(U32.is_zero(Inter.bcnt(wi)), tables, gfx, wi, after, trip, messages, mem)
    case Ending{f}:
      (Fi.Finale.frame(gfx, f, mem), 0)
