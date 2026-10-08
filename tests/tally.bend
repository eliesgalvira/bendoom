# Freedoom E1M1's tally and map chaining. THINGS and SECTORS supply
# totals of 29 kills, 49 items and 4 secrets. wi_stuff.c supplies the
# 35-tic pauses, percentage increments of 2, time increments of 3,
# par times and episode destinations. f_wipe.c consumes 320 M_Random
# draws per melt; s_sound.c draws once per tally sound before the next
# screen's animation seeds when sgcock starts it.
# The route's level RNG and inventory values are regression pins.
# snl_pointeron's initial false value survives an arbitrary launch map;
# WI_drawNoState sets it true for subsequent intermissions and deaths.
import Base
import ../src/vec.bend as V
import ../src/fixed.bend as F
import ../src/angle.bend as A
import ../src/level.bend as L
import ../src/gfx.bend as G
import ../src/keys.bend as K
import ../src/sim.bend as S
import ../src/special.bend as Sp
import ../src/tic.bend as Tic
import ../src/inventory.bend as I
import ../src/inter.bend as W
import ../src/sound.bend as Sn
import ../src/things.bend as H

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
    case W.Playing{+state, didsecret, pointer}:
      tag ++ " level tic " ++ U32.show(S.State.clock(state)) ++ " " ++ S.Sim.Tally.show(S.Sim.tally(state))
    case W.Showing{+wi, after, trip}:
      tag ++ " " ++ W.Inter.show(wi)
    case W.Ending{f}:
      tag ++ " finale"

def told(tag: String, +play: W.Play) -> IO(W.Play):
  do IO<W.Play>:
    IO.print(line(tag, play))
    return play

# The play after a script's tics, with no map to load in them.
def replayed(script: List<&2, K.Cmd>, +level: L.Level, play: W.Play) -> W.Play:
  match script:
    case []:
      play
    case cmd <> rest:
      replayed(rest, level, W.Play.Step.play(W.Play.step(level, cmd, play)))

# The play after so many idle tics.
def run(n: Nat, +level: L.Level, play: W.Play) -> W.Play:
  replayed(idle(n), level, play)

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
        case W.Playing{state, didsecret, pointer}:
          "sound level" ++ sound.events(events) ++ "\n"
        case W.Showing{wi, after, trip}:
          "sound bcnt " ++ U32.show(W.Inter.bcnt(wi)) ++ sound.events(events) ++ "\n"
        case W.Ending{f}:
          "sound finale\n"

def sounds(script: List<&2, K.Cmd>, +level: L.Level, play: W.Play, log: String) -> String:
  match script:
    case []:
      log
    case +cmd <> rest:
      +step = W.Play.step(level, cmd, play)
      sounds(rest, level, W.Play.Step.play(step), log ++ sound.line(W.Play.Step.sounds(step), W.Play.Step.play(step)))

# A tic of use, which the tally reads as a press, after a tic of none.
def press(+level: L.Level, play: W.Play) -> W.Play:
  replayed(List.append(&2, K.Cmd, idle(1n), held(1n, 0, 0, 0, True{})), level, play)

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

# The player's place and original sector special, live secret eligibility
# and discoveries.
def secret.line(tag: String, +level: L.Level, +s: S.State, +p: S.Player, +sector: U32) -> String:
  tag ++ " tic " ++ U32.show(S.State.clock(s)) ++ " at " ++ F.Fixed.show(S.Player.x(p)) ++ " "
    ++ F.Fixed.show(S.Player.y(p)) ++ " sector " ++ U32.show(sector) ++ " special "
    ++ U32.show(L.Level.sector.special(level, sector)) ++ " left "
    ++ U32.show(Bool.to_u32(U32.is_eq(L.Level.sector.special(S.State.level(s), sector), 9))) ++ " counted "
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
  W.Play.after(False{}, False{}, took)

def summary(+level: L.Level) -> IO(Unit):
  +took = Tic.Sim.replay(route(), Tic.State.at(level, beside()))
  do IO<Unit>:
    IO.print("start " ++ S.Sim.Tally.show(S.Sim.tally(Tic.State.start(level))))
    IO.print("exit " ++ S.Sim.Tally.show(S.Sim.tally(took)) ++ " ended " ++ S.Sim.Exit.show(S.State.ended(took))
      ++ " random " ++ U32.show(S.State.mrnd(took)))
    return Unit{}

# The map a play is on, its clock, where the player stands, what it
# carries and the random index; or the map the tally leads to.
def on(tag: String, play: W.Play) -> String:
  match play:
    case W.Playing{+state, didsecret, pointer}:
      +p = S.State.player(state)
      tag ++ " " ++ L.Level.Name.marker(L.Level.name(S.State.level(state))) ++ " tic " ++ U32.show(S.State.clock(state)) ++ " at "
        ++ F.Fixed.show(S.Player.x(p)) ++ " " ++ F.Fixed.show(S.Player.y(p)) ++ " "
        ++ I.Inventory.show(S.Player.inv(p)) ++ " random " ++ U32.show(S.State.rnd(state)) ++ " didsecret "
        ++ Bool.show(didsecret)
    case W.Showing{+wi, after, W.Trip{L.Name{e, last}, L.Name{f, next}, didsecret}}:
      tag ++ " tally for " ++ L.Level.marker(f, next) ++ " from " ++ L.Level.marker(e, last) ++ " par "
        ++ U32.show(V.Vec.get(W.Inter.target(wi), W.Inter.parat())) ++ " didsecret " ++ Bool.show(didsecret)
    case W.Ending{f}:
      tag ++ " finale " ++ W.Play.song(W.Ending{f})

def killed(play: W.Play) -> W.Play:
  match play:
    case W.Playing{+state, didsecret, pointer}:
      W.Playing{Tic.Sim.damage(H.Things.you(S.State.things(state)), 100, H.Thing.you(), H.Thing.you(), state),
        didsecret, pointer}
    case other:
      other

# A thing taken as P_TouchSpecialThing takes it, counted as an item or
# not.
def picked(kind: U32, counted: Bool, +inv: I.Inventory) -> I.Inventory:
  I.Inventory.took(counted, Maybe.default(&2, I.Inventory, I.Inventory.grant(kind, False{}, inv), inv))

def armed.of(+s: S.State, +p: S.Player) -> S.State:
  S.State.player.put(s, S.Player.holding(p, picked(2024, True{}, picked(5, False{}, picked(2013, True{},
    picked(2018, False{}, picked(2049, False{}, picked(2001, False{}, S.Player.inv(p)))))))))

# The player beside the switch with a shotgun, a box of shells, green
# armour, a soul sphere, the blue card and invisibility.
def armed(+level: L.Level) -> S.State:
  +s = Tic.State.at(level, beside())
  armed.of(s, S.State.player(s))

def weapon(+inv: I.Inventory) -> String:
  " ready " ++ U32.show(I.Inventory.ready(inv)) ++ " pending " ++ U32.show(I.Inventory.pending(inv))

def carries(tag: String, play: W.Play) -> String:
  match play:
    case W.Playing{+state, didsecret, pointer}:
      +inv = S.Player.inv(S.State.player(state))
      tag ++ " " ++ L.Level.Name.marker(L.Level.name(S.State.level(state))) ++ " " ++ I.Inventory.show(inv) ++ weapon(inv)
    case W.Showing{wi, +after, trip}:
      +inv = S.Player.inv(S.State.player(after))
      tag ++ " tally " ++ I.Inventory.show(inv) ++ weapon(inv)
    case W.Ending{f}:
      tag ++ " finale"

# G_DoWorldDone on the map the tally names, as loaded, then a tic.
def entered(+level: L.Level, play: W.Play) -> W.Play:
  match play:
    case W.Showing{wi, after, trip}:
      W.Play.Step.play(W.Play.step(level, K.Cmd.idle(), W.Play.enter(level, wi, after, trip)))
    case playing:
      playing

# E1M2 from the WAD after the tally: its first tic, and a death there
# with use held seven tics, then a tic of none; then the armed player's
# exit and first tic there.
def arrived.gl(play: W.Play, +carrying: W.Play, gl: G.Gfx & L.Level) -> IO(Unit):
  (gfx, +next) = gl
  +arrival = entered(next, play)
  do IO<Unit>:
    IO.print(on("entered", arrival) ++ " song " ++ W.Play.song(arrival))
    IO.print(on("reborn", replayed(List.append(&2, K.Cmd, held(7n, 0, 0, 0, True{}), idle(1n)), next,
      killed(arrival))))
    IO.print(carries("carrying", carrying))
    IO.print(carries("carried", entered(next, carrying)))

def arrived(play: W.Play, carrying: W.Play, opened: Array<U32> & G.Gfx & L.Level) -> IO(Unit):
  (mem, gl) = opened
  arrived.gl(play, carrying, gl)

# The map G_WorldDone asks for once the tally is over.
def wants(play: W.Play) -> String:
  match play:
    case W.Showing{+wi, after, W.Trip{last, L.Name{episode, map}, didsecret}}:
      Bool.pick(String, W.Inter.over(wi), L.Level.marker(episode, map), "none")
    case _:
      "none"

# The tally, and the map it asks to load.
def asked(tag: String, +play: W.Play) -> IO(W.Play):
  do IO<W.Play>:
    IO.print(line(tag, play) ++ " wants " ++ wants(play))
    return play

def intermission(+level: L.Level) -> IO(Unit):
  do IO<Unit>:
    p0 : W.Play <- told("bcnt 0", initial(level))
    p1 : W.Play <- tics(steps(), level, 0, p0)
    p2 : W.Play <- told("jumped", press(level, run(40n, level, initial(level))))
    p3 : W.Play <- told("next", press(level, p2))
    p4 : W.Play <- told("cut short", press(level, run(20n, level, p3)))
    p5 : W.Play <- asked("nine tics on", run(9n, level, p4))
    p6 : W.Play <- asked("ten tics on", run(1n, level, p5))
    opened : Array<U32> & G.Gfx & L.Level <- W.Play.open(L.Name{1, 2})
    arrived(p6, W.Play.after(False{}, False{}, Tic.Sim.replay(route(), armed(level))), opened)

def finale.pending(play: W.Play) -> String:
  match play:
    case W.Playing{+state, didsecret, pointer}:
      "E1M8 exit " ++ S.Sim.Exit.show(S.State.ended(state)) ++ " "
        ++ W.Play.song(W.Playing{state, didsecret, pointer})
    case other:
      on("E1M8 exit", other)

# E1M1's exit under a map 8 scene isolates finale dispatch from the boss room.
def finale(+level: L.Level) -> IO(Unit):
  +before = Tic.Sim.replay(List.take(&2, K.Cmd, route(), 6n), Tic.State.at(level, beside()))
  +pending = W.Play.Step.play(W.Play.step(level, K.Cmd.demo(0, 0, 0, 2),
    W.Playing{before, False{}, False{}}))
  do IO<Unit>:
    IO.print(finale.pending(pending))
    IO.print(on("E1M8 normal", W.Play.Step.play(W.Play.step(level, K.Cmd.demo(0, 0, 0, 0), pending))))
    return Unit{}

# The seam the secret exit line fires: E1M3 ended by a secret exit shows
# the tally for E1M9, and E1M8 starts its finale. Then
# didsecret, the player's flag that E1M9 is done, which G_DoCompleted
# sets on leaving E1M9 and the map screen reads after each map on.
def seam(level: L.Level, name: L.Level.Name, secret: Bool, didsecret: Bool) -> W.Play:
  W.Play.after(False{}, didsecret, Sp.State.end(secret,
    Tic.Sim.replay(route(), Tic.State.at(L.Level.named(name, level), beside()))))

def seams(+level: L.Level) -> IO(Unit):
  do IO<Unit>:
    IO.print(on("E1M3 secret", seam(level, L.Name{1, 3}, True{}, False{})))
    finale(L.Level.named(L.Name{1, 8}, level))
    IO.print(on("E1M9 normal", seam(level, L.Name{1, 9}, False{}, False{})))
    IO.print(on("E1M4 normal", seam(level, L.Name{1, 4}, False{}, True{})))

# A tic keeps didsecret, and G_PlayerReborn clears it once a death asks
# for the level again.
def done(+level: L.Level) -> W.Play:
  W.Playing{Tic.State.at(level, beside()), True{}, False{}}

def didsecret(+level: L.Level) -> IO(Unit):
  do IO<Unit>:
    IO.print(on("E1M4 a tic", replayed(idle(1n), level, done(level))))
    IO.print(on("E1M4 reborn", replayed(List.append(&2, K.Cmd, held(7n, 0, 0, 0, True{}), idle(1n)), level,
      killed(done(level)))))

def soundcheck(+level: L.Level) -> IO(Unit):
  do IO<Unit>:
    +p1 : W.Play = run(191n, level, initial(level))
    IO.print(sounds(List.append(&2, K.Cmd, idle(40n), held(1n, 0, 0, 0, True{})), level, initial(level), "")
      ++ sounds(held(1n, 0, 0, 0, True{}), level, p1, ""))
    return Unit{}

def secret.original(level: L.Level) -> S.State:
  Tic.State.at(level, L.Start{F.Fixed.of_map(400), F.Fixed.of_map(2040), A.Angle.of_thing(270)})

def secrets(+level: L.Level) -> IO(Unit):
  do IO<Unit>:
    s0 : S.State <- secret("in the secret", level, secret.original(level))
    s1 : S.State <- secret("stood a tic", level, Tic.Sim.tic(K.Cmd.idle(), s0))
    s2 : S.State <- secret("out south", level, Tic.Sim.replay(out(), s1))
    s3 : S.State <- secret("back north", level, Tic.Sim.replay(back(), s2))
    return Unit{}

# p_spec.c counts initial special 9 in P_SpawnSpecials, then discovers
# only live special 9 at floor height and clears it. p_floor.c's special
# copies and p_plats.c's clears never change that initial total.
def secret.changed(+special: U32, +s: S.State) -> S.State:
  +level = S.State.level(s)
  +sector = L.Level.sector_at(level, S.Player.x(S.State.player(s)), S.Player.y(S.State.player(s)))
  Sp.Sim.floor.change(sector, L.Level.floorpic(level, sector), special, s)

def secret.tally.of(t: S.Sim.Tally) -> String:
  S.Tally{kills, items, secrets, maxkills, maxitems, maxsecret, time} = t
  U32.show(secrets) ++ "/" ++ U32.show(maxsecret)

def secret.tally(tag: String, +s: S.State) -> String:
  tag ++ " secrets " ++ secret.tally.of(S.Sim.tally(s)) ++ " special "
    ++ U32.show(L.Level.sector.special(S.State.level(s),
      L.Level.sector_at(S.State.level(s), S.Player.x(S.State.player(s)), S.Player.y(S.State.player(s)))))

def secret.copied(level: L.Level) -> S.State:
  Sp.Sim.sector.secret(secret.changed(9,
    Tic.State.at(level, L.Start{F.Fixed.of_map(400), F.Fixed.of_map(1936), A.Angle.of_thing(270)})))

def secret.recopied(n: Nat, s: S.State) -> S.State:
  match n:
    case 0n:
      s
    case 1n+m:
      secret.recopied(m, Sp.Sim.sector.secret(secret.changed(9, s)))

def secret.airborne(+s: S.State) -> S.State:
  +level = S.State.level(s)
  +p = S.State.player(s)
  +sector = L.Level.sector_at(level, S.Player.x(p), S.Player.y(p))
  Sp.Sim.sector.secret(S.State.player.put(s, S.Player.at.fin(S.Player.x(p), S.Player.y(p), S.Player.angle(p),
    (L.Level.floor(level, sector) + F.Fixed.unit() : U32), L.Level.ceil(level, sector), S.Player.inv(p))))

def secret.totals(+level: L.Level) -> IO(Unit):
  do IO<Unit>:
    IO.print(secret.tally("cleared", Sp.Sim.sector.secret(secret.changed(0, secret.original(level)))))
    IO.print(secret.tally("found", Sp.Sim.sector.secret(secret.original(level))))
    IO.print(secret.tally("found again", Sp.Sim.sector.secret(Sp.Sim.sector.secret(secret.original(level)))))
    IO.print(secret.tally("copied", secret.copied(level)))
    IO.print(secret.tally("copied again", Sp.Sim.sector.secret(secret.changed(9, secret.copied(level)))))
    IO.print(secret.tally("copies exceed total", secret.recopied(4n, secret.copied(level))))
    IO.print(secret.tally("airborne", secret.airborne(secret.original(level))))

# WI_checkForAccelerate permits a new attack while use stays held,
# then a new use while attack stays held; neither held button repeats.
def buttons() -> String:
  +wi = W.Inter.start(S.Tally{0, 0, 0, 1, 1, 1, 0}, 30, 0, W.Inter.buttons(False{}, True{}))
  +both = W.Inter.tic(W.Inter.buttons(True{}, True{}), wi)
  +attack = W.Inter.tic(W.Inter.buttons(True{}, False{}), both)
  "buttons " ++ Bool.show(W.Inter.pressed(3, wi)) ++ " " ++ Bool.show(W.Inter.pressed(3, both))
    ++ " " ++ Bool.show(W.Inter.pressed(1, both)) ++ " " ++ Bool.show(W.Inter.pressed(3, attack))
    ++ " down " ++ Bool.show(W.Inter.attackdown(attack)) ++ " " ++ Bool.show(W.Inter.usedown(attack))

def pointer(play: W.Play) -> Bool:
  match play:
    case W.Playing{state, didsecret, pointer}:
      pointer
    case W.Showing{wi, after, trip}:
      W.Inter.pointer(wi)
    case W.Ending{f}:
      False{}

def exited(play: W.Play) -> W.Play:
  match play:
    case W.Playing{state, didsecret, pointer}:
      W.Play.after(pointer, didsecret, Sp.State.end(False{}, state))
    case showing:
      showing

def pointers(+level: L.Level) -> String:
  +first = press(level, press(level, exited(W.Play.start(L.Level.named(L.Name{1, 5}, level)))))
  +firston = pointer(first)
  +ticon = pointer(run(1n, level, first))
  +last = press(level, first)
  +laston = pointer(last)
  +arrival = entered(level, last)
  +nexton = pointer(press(level, press(level, exited(arrival))))
  +reborn = replayed(List.append(&2, K.Cmd, held(7n, 0, 0, 0, True{}), idle(1n)), level, killed(arrival))
  "pointer first " ++ Bool.show(firston) ++ " tic1 " ++ Bool.show(ticon)
    ++ " last " ++ Bool.show(laston) ++ " next " ++ Bool.show(nexton)
    ++ " reborn " ++ Bool.show(pointer(press(level, press(level, exited(reborn)))))

# D_DoomLoop's first command and D_RunFrame's next command precede
# wipe_initMelt; the third ST_Ticker reads random table index67.
def startup.melt(+level: L.Level) -> String:
  +first = Tic.Sim.tic(K.Cmd.idle(), Tic.State.start(level))
  +one = S.State.mrnd(first)
  +second = Tic.Sim.tic(K.Cmd.idle(), first)
  +two = S.State.mrnd(second)
  +third = Tic.Sim.tic(K.Cmd.idle(), second)
  "startup draws " ++ U32.show(one) ++ " " ++ U32.show(two) ++ " " ++ U32.show(S.State.mrnd(third))

def random.draws() -> String:
  +start = W.Inter.start(S.Tally{0, 0, 0, 1, 1, 1, 0}, 30, 0, 0)
  +skip = W.Inter.tic(1, start)
  +next = W.Inter.tic(1, W.Inter.tic(0, skip))
  "draws seeds " ++ U32.show(W.Inter.mrnd(start)) ++ " skip " ++ U32.show(W.Inter.mrnd(skip))
    ++ " next " ++ U32.show(W.Inter.mrnd(next))

def play(+level: L.Level) -> IO(Unit):
  do IO<Unit>:
    summary(level)
    IO.print(startup.melt(level))
    intermission(level)
    seams(level)
    didsecret(L.Level.named(L.Name{1, 4}, level))
    soundcheck(level)
    secrets(level)
    secret.totals(level)
    IO.print(buttons())
    IO.print(pointers(level))
    IO.print(random.draws())

def start(w: Array<U32> & G.Gfx & L.Level) -> IO(Unit):
  (mem, gl) = w
  (gfx, level) = gl
  play(level)

def main() -> IO(Unit):
  do IO<Unit>:
    world : Array<U32> & G.Gfx & L.Level <- G.Gfx.open(1, 1)
    start(world)
#|start kills 0/29 items 0/49 secrets 0/4 time 0
#|exit kills 0/29 items 0/49 secrets 0/4 time 7 ended normal random 73
#|startup draws 1 66 67
#|bcnt 0 count 1 cnt 35 bcnt 0 shown - - - - - anims - - - - - - - - - - random 83
#|bcnt 1 count 1 cnt 34 bcnt 1 shown - - - - - anims - 0 - - - - - - - 0 random 147
#|bcnt 34 count 1 cnt 1 bcnt 34 shown - - - - - anims 2 0 2 2 2 2 2 2 2 0 random 147
#|bcnt 35 count 2 cnt 35 bcnt 35 shown - - - - - anims 2 0 2 2 2 2 0 2 2 0 random 147
#|bcnt 36 count 3 cnt 35 bcnt 36 shown 0 - - - - anims 0 0 2 2 2 2 0 2 2 0 random 149
#|bcnt 71 count 4 cnt 35 bcnt 71 shown 0 - - - - anims 0 0 2 2 2 2 0 2 2 0 random 149
#|bcnt 72 count 5 cnt 35 bcnt 72 shown 0 0 - - - anims 0 0 0 2 2 0 0 2 2 0 random 151
#|bcnt 107 count 6 cnt 35 bcnt 107 shown 0 0 - - - anims 0 0 0 0 2 0 0 2 0 0 random 151
#|bcnt 108 count 7 cnt 35 bcnt 108 shown 0 0 0 - - anims 0 0 0 0 2 0 0 2 0 0 random 153
#|bcnt 143 count 8 cnt 35 bcnt 143 shown 0 0 0 - - anims 0 0 0 0 0 0 0 0 0 0 random 153
#|bcnt 144 count 8 cnt 35 bcnt 144 shown 0 0 0 0 2 anims 0 1 0 0 0 0 0 0 0 1 random 154
#|bcnt 145 count 8 cnt 35 bcnt 145 shown 0 0 0 0 5 anims 0 1 0 0 0 0 1 0 0 1 random 154
#|bcnt 154 count 9 cnt 35 bcnt 154 shown 0 0 0 0 30 anims 1 1 1 1 1 1 1 1 1 1 random 157
#|bcnt 155 count 9 cnt 34 bcnt 155 shown 0 0 0 0 30 anims 1 2 1 1 1 1 1 1 1 2 random 157
#|bcnt 189 count 10 cnt 35 bcnt 189 shown 0 0 0 0 30 anims 1 2 1 1 1 1 2 1 1 2 random 157
#|bcnt 190 count 10 cnt 35 bcnt 190 shown 0 0 0 0 30 anims 2 2 1 1 1 1 2 1 1 2 random 157
#|bcnt 191 count 10 cnt 35 bcnt 191 shown 0 0 0 0 30 anims 2 2 1 1 1 1 2 1 1 2 random 157
#|jumped count 10 cnt 30 bcnt 42 shown 0 0 0 0 30 anims 0 0 0 0 2 0 0 2 0 0 random 150
#|next next cnt 140 bcnt 44 shown 0 0 0 0 30 anims - - - - - - - - - - random 161
#|cut short done cnt 10 bcnt 66 shown 0 0 0 0 30 anims 1 1 1 1 1 1 1 1 1 1 random 161
#|nine tics on done cnt 1 bcnt 75 shown 0 0 0 0 30 anims 2 2 2 2 1 2 2 2 2 2 random 161 wants none
#|ten tics on done cnt 0 bcnt 76 shown 0 0 0 0 30 anims 2 2 2 2 2 2 2 2 2 2 random 161 wants E1M2
#|entered E1M2 tic 1 at 608.000000 48.000000 inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 random 3 didsecret False song D_E1M2
#|reborn E1M2 tic 7 at 608.000000 48.000000 inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 random 199 didsecret False
#|carrying tally inventory health 200 armour 100 type 1 cards 1 ammo 50 28 0 0 caps 200 50 300 50 backpack False weapons 7 powers 0 0 2093 0 0 0 items 2 flash 11 ready 1 pending 2
#|carried E1M2 inventory health 200 armour 100 type 1 cards 0 ammo 50 28 0 0 caps 200 50 300 50 backpack False weapons 7 powers 0 0 0 0 0 0 items 0 flash 0 ready 1 pending 255
#|E1M3 secret tally for E1M9 from E1M3 par 120 didsecret False
#|E1M8 exit normal D_E1M8
#|E1M8 normal finale D_VICTOR
#|E1M9 normal tally for E1M4 from E1M9 par 165 didsecret True
#|E1M4 normal tally for E1M5 from E1M4 par 90 didsecret True
#|E1M4 a tic E1M4 tic 1 at -363.000000 1316.000000 inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 random 61 didsecret True
#|E1M4 reborn E1M4 tic 7 at -416.000000 256.000000 inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 random 126 didsecret False
#|sound bcnt 36 DSPISTOL from nobody vol 64 sep 128 DSBAREXP from nobody vol 64 sep 128
#|sound bcnt 41 DSBAREXP from nobody vol 64 sep 128
#|sound bcnt 192 DSSGCOCK from nobody vol 64 sep 128
#|
#|in the secret tic 0 at 400.000000 2040.000000 sector 86 special 9 left 1 counted 0
#|stood a tic tic 1 at 400.000000 2040.000000 sector 86 special 9 left 0 counted 1
#|out south tic 24 at 400.037475 1935.800521 sector 87 special 0 left 0 counted 1
#|back north tic 48 at 400.011810 1994.541183 sector 86 special 9 left 0 counted 1
#|cleared secrets 0/4 special 0
#|found secrets 1/4 special 0
#|found again secrets 1/4 special 0
#|copied secrets 1/4 special 0
#|copied again secrets 2/4 special 0
#|copies exceed total secrets 5/4 special 0
#|airborne secrets 0/4 special 9

#|buttons True False False True down True False

#|pointer first False tic1 True last True next True reborn True
#|draws seeds 10 skip 75 next 86
