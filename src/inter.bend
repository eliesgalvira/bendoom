# Doom's wi_stuff.c: the intermission the exit leads to, for one player
# on episode 1, and the two modes the game plays in, the level and the
# tally after it. The intermission is a value stepped by a pure function
# of itself and whether a key that accelerates is down, and drawn into
# the same 320 by 200 frame the renderer draws, so a test replays it and
# the film shows it.
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
import ./sound.bend as Sn
import ./project.bend as P
import ./render.bend as R

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
# to, the animations, M_Random's index and whether a key that
# accelerates was down last tic. Doom takes that press from attack or
# from use, each with a flag of its own; here one press stands for both,
# since both do the same thing.
type Inter is Data:
  Inter{screen: Inter.Screen, cnt: U32, bcnt: U32, shown: V.Vec, target: V.Vec,
    anims: List<&2, Inter.Anim>, mrnd: U32, down: Bool}

def Inter.screen(i: Inter) -> Inter.Screen:
  Inter{screen, cnt, bcnt, shown, target, anims, mrnd, down} = i
  screen

def Inter.cnt(i: Inter) -> U32:
  Inter{screen, cnt, bcnt, shown, target, anims, mrnd, down} = i
  cnt

def Inter.bcnt(i: Inter) -> U32:
  Inter{screen, cnt, bcnt, shown, target, anims, mrnd, down} = i
  bcnt

def Inter.shown(i: Inter) -> V.Vec:
  Inter{screen, cnt, bcnt, shown, target, anims, mrnd, down} = i
  shown

def Inter.target(i: Inter) -> V.Vec:
  Inter{screen, cnt, bcnt, shown, target, anims, mrnd, down} = i
  target

def Inter.mrnd(i: Inter) -> U32:
  Inter{screen, cnt, bcnt, shown, target, anims, mrnd, down} = i
  mrnd

def Inter.anims(i: Inter) -> List<&2, Inter.Anim>:
  Inter{screen, cnt, bcnt, shown, target, anims, mrnd, down} = i
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

# E1M1's par, g_game.c's pars[1][1] in seconds.
def Inter.par() -> U32:
  30

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

def Inter.start.of(t: S.Sim.Tally, down: Bool, r: Inter.Rolled) -> Inter:
  S.Tally{kills, items, secrets, maxkills, maxitems, maxsecret, time} = t
  Rolled{anims, mrnd} = r
  Inter{Count{1}, 35, 0,
    V.Vec.of_list([Inter.none(), Inter.none(), Inter.none(), Inter.none(), Inter.none()], 5),
    V.Vec.of_list([Inter.percent(kills, maxkills), Inter.percent(items, maxitems),
      Inter.percent(secrets, maxsecret), (time / 35 : U32), Inter.par()], 5), anims, mrnd, down}

# Doom's WI_Start for one player: WI_initStats, on the counts
# G_DoCompleted hands it. Every count starts unshown, the first pause
# lasts a second, and the animations are laid out from a background
# counter of zero, one draw of M_Random each; the index is the one the
# level left, since the intermission draws from the same table. Use
# counts as down when the level ended with it down, as the player's
# usedown flag does, so the press that took the exit does not also skip
# the first pause.
def Inter.start(t: S.Sim.Tally, +mrnd: U32, down: Bool) -> Inter:
  Inter.start.of(t, down, Inter.anims.init(Inter.nanims(), 0, Rolled{[], mrnd}))

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
  Inter{screen, cnt, bcnt, +shown, target, anims, mrnd, down} = wi
  Inter{Inter.stepped(done, screen), cnt, bcnt, V.Vec.set(shown, i, at), target, anims, mrnd, down}

def Inter.climbed.of(c: Inter.Climb, +i: U32, wi: Inter) -> Inter:
  Climb{at, done} = c
  Inter.climbed.put(done, i, at, wi)

# One of the three percentages counted up, two a tic.
def Inter.climbed(+i: U32, step: U32, +wi: Inter) -> Inter:
  Inter.climbed.of(Inter.climb(V.Vec.get(Inter.shown(wi), i), V.Vec.get(Inter.target(wi), i), step), i, wi)

def Inter.timed.put(t: Inter.Climb, p: Inter.Climb, wi: Inter) -> Inter:
  Climb{tat, tdone} = t
  Climb{pat, pdone} = p
  Inter{screen, cnt, bcnt, +shown, target, anims, mrnd, down} = wi
  Inter{Inter.stepped(Bool.and(tdone, pdone), screen), cnt, bcnt,
    V.Vec.set(V.Vec.set(shown, Inter.time(), tat), Inter.parat(), pat), target, anims, mrnd, down}

# WI_updateStats' eighth state: the time and the par climb three a tic
# together, and the screen moves on once both stand at their own.
def Inter.timed(+wi: Inter) -> Inter:
  Inter.timed.put(Inter.climb(V.Vec.get(Inter.shown(wi), Inter.time()),
      V.Vec.get(Inter.target(wi), Inter.time()), 3),
    Inter.climb(V.Vec.get(Inter.shown(wi), Inter.parat()), V.Vec.get(Inter.target(wi), Inter.parat()), 3), wi)

def Inter.paused(over: Bool, wi: Inter) -> Inter:
  match over:
    case False{}:
      Inter{screen, +cnt, bcnt, shown, target, anims, mrnd, down} = wi
      Inter{screen, (cnt - 1 : U32), bcnt, shown, target, anims, mrnd, down}
    case True{}:
      Inter{screen, cnt, bcnt, shown, target, anims, mrnd, down} = wi
      Inter{Inter.stepped(True{}, screen), 35, bcnt, shown, target, anims, mrnd, down}

# WI_updateStats' odd states: a second's pause, and then the next count.
def Inter.pause(+wi: Inter) -> Inter:
  Inter.paused(U32.is_eq(Inter.cnt(wi), 1), wi)

def Inter.next.of(r: Inter.Rolled, wi: Inter) -> Inter:
  Rolled{anims, mrnd} = r
  Inter{screen, cnt, bcnt, shown, target, old, was, down} = wi
  Inter{Next{}, 140, bcnt, shown, target, anims, mrnd, down}

# WI_initShowNextLoc: the screen that names the level to come, for four
# seconds, with the animations laid out again.
def Inter.next(+wi: Inter) -> Inter:
  Inter.next.of(Inter.anims.init(Inter.nanims(), Inter.bcnt(wi), Rolled{[], Inter.mrnd(wi)}), wi)

def Inter.leave(press: Bool, +wi: Inter) -> Inter:
  match press:
    case False{}:
      wi
    case True{}:
      Inter.next(wi)

# WI_updateStats' first test: a press before the counting is done shows
# every count at once and leaves the screen at its last state.
def Inter.skip(jump: Bool, wi: Inter) -> Inter:
  match jump:
    case False{}:
      wi
    case True{}:
      Inter{screen, cnt, bcnt, shown, +target, anims, mrnd, down} = wi
      Inter{Count{10}, cnt, bcnt, target, target, anims, mrnd, down}

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
      Inter{screen, cnt, bcnt, shown, target, anims, mrnd, down} = wi
      Inter{screen, left, bcnt, shown, target, anims, mrnd, down}
    case True{}:
      Inter{screen, cnt, bcnt, shown, target, anims, mrnd, down} = wi
      Inter{Last{}, 10, bcnt, shown, target, anims, mrnd, down}

# WI_updateShowNextLoc: four seconds, or a press, and then WI_initNoState
# with its ten tics.
def Inter.shownext(press: Bool, +wi: Inter) -> Inter:
  +left = (Inter.cnt(wi) - 1 : U32)
  Inter.shownext.put(Bool.or(U32.is_zero(left), press), left, wi)

# WI_updateNoState: ten tics, and at the end G_WorldDone, which the play
# reads as the level to start.
def Inter.nostate(wi: Inter) -> Inter:
  Inter{screen, +cnt, bcnt, shown, target, anims, mrnd, down} = wi
  Inter{screen, (cnt - 1 : U32), bcnt, shown, target, anims, mrnd, down}

def Inter.tic.screen(screen: Inter.Screen, press: Bool, wi: Inter) -> Inter:
  match screen:
    case Count{sp}:
      Inter.stats(sp, press, wi)
    case Next{}:
      Inter.shownext(press, wi)
    case Last{}:
      Inter.nostate(wi)

def Inter.tic.on(+bcnt: U32, press: Bool, down: Bool, wi: Inter) -> Inter:
  Inter{+screen, cnt, was, shown, target, anims, mrnd, old} = wi
  Inter.tic.screen(screen, press,
    Inter{screen, cnt, bcnt, shown, target, Inter.anims.tic(anims, bcnt), mrnd, down})

# WI_Ticker: the background's counter, then WI_checkForAccelerate, whose
# press is the tic a key goes down and not one it is held, then the
# screen's own update, which begins with the animations.
def Inter.tic(+down: Bool, wi: Inter) -> Inter:
  Inter{screen, cnt, +bcnt, shown, target, anims, mrnd, +was} = wi
  Inter.tic.on((bcnt + 1 : U32), Bool.and(down, Bool.not(was)), down,
    Inter{screen, cnt, bcnt, shown, target, anims, mrnd, was})

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
  Inter{+screen, cnt, bcnt, shown, target, anims, mrnd, down} = before
  match screen:
    case Count{sp}:
      Inter.sound.counting(sp, press, Inter.bcnt(after), after)
    case _:
      []

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
  Inter{screen, +cnt, +bcnt, +shown, target, +anims, +mrnd, down} = wi
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

# WI_drawLF: the level's name at the top, and "Finished!" a name and a
# quarter under it.
def Inter.finished.of(+gfx: G.Gfx, p: Array<U32> & U32) -> Array<U32>:
  (mem, +h) = p
  Inter.centre(gfx, "WIF", (2 + 5 * h / 4 : U32), mem)

def Inter.finished(+gfx: G.Gfx, mem: Array<U32>) -> Array<U32>:
  Inter.finished.of(gfx, Inter.word(gfx, "WILV00", 2, Inter.centre(gfx, "WILV00", 2, mem)))

# WI_drawEL: "Entering" at the top, and the name of the level to come,
# which is E1M2's, under it. Bendoom starts E1M1 again there, since it
# has no second map.
def Inter.entering.of(+gfx: G.Gfx, p: Array<U32> & U32) -> Array<U32>:
  (mem, +h) = p
  Inter.centre(gfx, "WILV01", (2 + 5 * h / 4 : U32), mem)

def Inter.entering(+gfx: G.Gfx, mem: Array<U32>) -> Array<U32>:
  Inter.entering.of(gfx, Inter.word(gfx, "WILV01", 2, Inter.centre(gfx, "WIENTER", 2, mem)))

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
def Inter.stats.draw(+gfx: G.Gfx, +wi: Inter, mem: Array<U32>) -> Array<U32>:
  Inter.stats.draw.fw(gfx, wi, Inter.word(gfx, "WINUM0", 0,
    Inter.finished(gfx, Inter.back(gfx, Inter.anims(wi), mem))))

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

# wi_stuff.c's lnodes for episode 1: where E1M1 and E1M2 stand on the
# map. The seven levels after them have places of their own, which
# Bendoom never shows, since its tally always leaves for E1M2.
def Inter.lnodes() -> List<&2, G.Gfx.Spot>:
  [G.Spot{185, 164}, G.Spot{148, 143}]

def Inter.pointer(on: Bool, +gfx: G.Gfx, +spot: G.Gfx.Spot, mem: Array<U32>) -> Array<U32>:
  match on:
    case False{}:
      mem
    case True{}:
      Inter.lnode(["WIURH0", "WIURH1"], gfx, G.Gfx.Spot.x(spot), G.Gfx.Spot.y(spot), mem)

def Inter.here(+gfx: G.Gfx, on: Bool, spots: List<&2, G.Gfx.Spot>, mem: Array<U32>) -> Array<U32>:
  match spots:
    case +last <> +next <> rest:
      Inter.pointer(on, gfx, next,
        Inter.lnode(["WISPLAT"], gfx, G.Gfx.Spot.x(last), G.Gfx.Spot.y(last), mem))
    case _:
      mem

# WI_drawShowNextLoc: the background, a splat on the level just left, the
# pointer on the one to come while it shows, and its name.
def Inter.next.draw(+gfx: G.Gfx, +wi: Inter, on: Bool, mem: Array<U32>) -> Array<U32>:
  Inter.entering(gfx, Inter.here(gfx, on, Inter.lnodes(), Inter.back(gfx, Inter.anims(wi), mem)))

def Inter.frame.of(s: Inter.Screen, +gfx: G.Gfx, +wi: Inter, mem: Array<U32>) -> Array<U32>:
  match s:
    case Count{sp}:
      Inter.stats.draw(gfx, wi, mem)
    case Next{}:
      Inter.next.draw(gfx, wi, U32.is_lt((Inter.cnt(wi) .&. 31 : U32), 20), mem)
    case Last{}:
      Inter.next.draw(gfx, wi, True{}, mem)

# WI_Drawer: the counting screen, the one that names the next level with
# its pointer flashing, and the last, which holds that pointer on.
def Inter.frame(+gfx: G.Gfx, +wi: Inter, mem: Array<U32>) -> Array<U32>:
  Inter.frame.of(Inter.screen(wi), gfx, wi, mem)

# The play
# --------

# The game's two modes, Doom's GS_LEVEL and GS_INTERMISSION: the level
# playing, or the tally the exit leads to. The level's state is done
# with once the tally starts, since the level that follows is built from
# the map as loaded.
type Play is Data:
  Playing{state: S.State}
  Showing{inter: Inter}

type Play.Step is Data:
  Step{play: Play, sounds: List<&2, Sn.Sound.Event>}

# The level as loaded, at its start: Doom's G_DoLoadLevel, shared by
# death and intermission restarts.
def Play.start(+level: L.Level) -> Play:
  Playing{S.State.start(level)}

def Play.restarted(reborn: Bool, +level: L.Level, state: S.State) -> Play:
  match reborn:
    case True{}:
      Play.start(level)
    case False{}:
      Playing{state}

def Play.ready(+level: L.Level, play: Play) -> Play:
  match play:
    case Playing{+state}:
      Play.restarted(S.State.reborn(state), level, state)
    case Showing{wi}:
      Showing{wi}

# G_DoCompleted: the tic that ends the level hands the tally its counts,
# the totals and the time.
def Play.ended(ended: Bool, +after: S.State) -> Play:
  match ended:
    case False{}:
      Playing{after}
    case True{}:
      Showing{Inter.start(S.Sim.tally(after), S.State.mrnd(after), S.State.usedown(after))}

def Play.after(+after: S.State) -> Play:
  Play.ended(S.State.ended(after), after)

# Whether the tally is accelerated this tic: WI_checkForAccelerate reads
# attack and use from the command, and the game's window adds Enter,
# which it has held since milestone 4 as the key that starts the level
# again.
def Play.pressed(+held: Bool, +cmd: K.Cmd) -> Bool:
  Bool.or(held, K.Cmd.use(cmd))

def Play.step.showing(over: Bool, +level: L.Level, +cmd: K.Cmd, +press: Bool, +wi: Inter) -> Play.Step:
  match over:
    case True{}:
      Step{Play.after(S.Sim.tic(cmd, S.State.start(level))), []}
    case False{}:
      +after = Inter.tic(press, wi)
      Step{Showing{after}, Inter.sound(press, wi, after)}

def Play.step(+level: L.Level, +cmd: K.Cmd, +held: Bool, play: Play) -> Play.Step:
  match play:
    case Playing{state}:
      +after = S.Sim.tic(cmd, state)
      Step{Play.after(after), S.State.sounds(after)}
    case Showing{+wi}:
      +press = Play.pressed(held, cmd)
      Play.step.showing(Inter.over(wi), level, cmd, press, wi)

def Play.Step.play(step: Play.Step) -> Play:
  Step{play, sounds} = step
  play

def Play.Step.sounds(step: Play.Step) -> List<&2, Sn.Sound.Event>:
  Step{play, sounds} = step
  sounds

# A tic of the play: the level's tic while it runs, then the tally's,
# and, on the tic after the tally is done, the first tic of a level
# built from the map as loaded, where Doom's G_DoWorldDone loads the
# next. Held is a key outside the command that accelerates the tally,
# which the level pays no heed.
def Play.tic(+level: L.Level, +cmd: K.Cmd, +held: Bool, play: Play) -> Play:
  Play.Step.play(Play.step(level, cmd, held, play))

# A tic for each command of a list, with a key held throughout: a frame
# of the game's loop.
def Play.tics(script: List<&2, K.Cmd>, +held: Bool, +level: L.Level, play: Play) -> Play:
  match script:
    case []:
      play
    case cmd <> rest:
      Play.tics(rest, held, level, Play.tic(level, cmd, held, play))

# A tic for each command of a list, the press from the commands alone,
# as a demo's tics drive the tally.
def Play.replay(script: List<&2, K.Cmd>, +level: L.Level, play: Play) -> Play:
  Play.tics(script, False{}, level, play)

# Whether the level is still running, which the demo is recorded for.
def Play.playing(play: Play) -> Bool:
  match play:
    case Playing{state}:
      True{}
    case Showing{inter}:
      False{}

# The scene's song, as S_Start and WI_Start name it: the level's own, or
# D_INTER through the tally.
def Play.song(play: Play) -> String:
  match play:
    case Playing{state}:
      "D_E1M1"
    case Showing{inter}:
      "D_INTER"

# The songs a scene of the episode can name.
def Play.songs() -> List<&2, String>:
  ["D_E1M1", "D_E1M2", "D_E1M3", "D_E1M4", "D_E1M5", "D_E1M6", "D_E1M7", "D_E1M8", "D_E1M9", "D_INTER"]

# The frame the play shows: the level from the player's eye, or the
# tally, both in the same 320 by 200 array.
def Play.frame(tables: P.Project.Tables, gfx: G.Gfx, play: Play, messages: Bool, mem: Array<U32>) -> Array<U32> & U32:
  match play:
    case Playing{+state}:
      R.Render.frame(tables, gfx, state, messages, mem)
    case Showing{+wi}:
      (Inter.frame(gfx, wi, mem), 0)
