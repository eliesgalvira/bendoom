# The game's frame, from the WAD named by BENDOOM_IWAD: a clock reading
# and the frame's key events in, the state and what it prints out. No
# window opens. Each line is the clock, whether the level has ended, the
# player, the thinkers running that are no mobj's, the floor and ceiling
# of sector 64 (the exit room's door), line 407's special (the exit
# switch, 11 as loaded), whether its side shows the switch's partner, how
# many things there are and the random index.
# First the state the game starts with. Then a game handed a player
# killed on the spot in the nukage at 1600, 1000: a frame 200 ms on with
# Space pressed runs 7 tics: on the first the dead player's use asks
# for the level again, as P_DeathThink reads it, and G_DoReborn answers
# on the next, so the other six run on the map loaded again from a
# pistol start, its random index carried on from the death's. The same
# game is then handed the
# state a script leaves beside Freedoom's exit switch, 6 tics in. A
# frame 200 ms on with Space pressed runs 7 tics: the first ends the
# level and the rest count down the tally's first pause. A held Space
# repeating, as X sends it, a release and a press in one frame, skips
# nothing, nor does its release, nor a press of Enter with no time gone,
# since the tally reads a press on a tic. Esc quits.
# Before the game, what a tic of use beside the switch is heard to
# start, and M_Random's index after it. P_ChangeSwitchTexture clears the
# line's special before it looks for the exit's 11, so the click is
# sfx_swtchn, and it comes from nobody, since no button runs. The index
# is 64 after the wipe and 66 once the six tics and the click have
# drawn, which is a pin.
# First of all, the map each command line starts on, by d_main.c's
# -warp: none, the episode and map, the map left out, -warp with nothing
# after it, a second -warp after the first, and arguments read by their
# first characters.
# Then the time of a few clocks, worked out by hand in milestone 4's
# ticket 09. The door's height is the hand computation's (4 under
# sector 68's ceiling of -56); the positions are regression pins.
import Base
import ../src/vec.bend as V
import ../src/fixed.bend as F
import ../src/angle.bend as A
import ../src/level.bend as L
import ../src/gfx.bend as G
import ../src/keys.bend as K
import ../src/sim.bend as S
import ../src/things.bend as H
import ../src/project.bend as P
import ../src/game.bend as M
import ../src/inter.bend as I
import ../src/sound.bend as Sn

def pressed(+level: L.Level, sidetex: V.Vec) -> Bool:
  U32.is_eq(V.Vec.get(sidetex, (615 * 3 + 2 : U32)),
    L.Level.switch(level, V.Vec.get(L.Level.sidetex(level), (615 * 3 + 2 : U32))))

# How many thinkers are not mobjs': the lights, movers and buttons.
def specials(ts: List<&2, S.Thinker>) -> U32:
  match ts:
    case []:
      0
    case S.Mobj{id} <> rest:
      specials(rest)
    case _ <> rest:
      (1 + specials(rest) : U32)

def line(tag: String, +s: S.State) -> String:
  +p = S.State.player(s)
  +level = S.State.level(s)
  tag ++ " tic " ++ U32.show(S.State.clock(s)) ++ " ended " ++ S.Sim.Exit.show(S.State.ended(s)) ++ " at "
    ++ F.Fixed.show(S.Player.x(p)) ++ " " ++ F.Fixed.show(S.Player.y(p)) ++ " " ++ A.Angle.show(S.Player.angle(p))
    ++ " thinkers " ++ U32.show(specials(S.State.thinkers(s))) ++ " sector 64 "
    ++ F.Fixed.show(L.Level.floor(level, 64)) ++ " " ++ F.Fixed.show(L.Level.ceil(level, 64)) ++ " special "
    ++ U32.show(L.Level.special(level, 407)) ++ " pressed " ++ Bool.show(pressed(level, S.State.sidetex(s)))
    ++ " things " ++ Nat.show(List.length(&2, H.Thing, H.Things.list(S.State.things(s)))) ++ " random "
    ++ U32.show(S.State.rnd(s))

def heard(es: List<&2, Sn.Sound.Event>) -> String:
  match es:
    case []:
      ""
    case e <> rest:
      " " ++ Sn.Sound.Event.show(e) ++ heard(rest)

def clicked(+s: S.State) -> String:
  "use heard" ++ heard(S.State.sounds(s)) ++ " drew to " ++ U32.show(S.State.mrnd(s))

def told(tag: String, +state: S.State, g: M.Game) -> IO(Maybe<M.Game>):
  do IO<Maybe<M.Game>>:
    IO.print(line(tag, state))
    return Some{g}

def told.play(tag: String, play: I.Play, g: M.Game) -> IO(Maybe<M.Game>):
  match play:
    case I.Playing{state, map}:
      told(tag, state, g)
    case I.Showing{wi, after, next}:
      do IO<Maybe<M.Game>>:
        IO.print(tag ++ " tally " ++ I.Inter.show(wi))
        return Some{g}

def reported(quit: Bool, tag: String, g: M.Game) -> IO(Maybe<M.Game>):
  match quit:
    case True{}:
      do IO<Maybe<M.Game>>:
        IO.print(tag ++ " quit")
        return None{}
    case False{}:
      M.Game{level, gfx, tables, +play, input, again, last, owed, mem, demo, music} = g
      told.play(tag, play, M.Game{level, gfx, tables, play, input, again, last, owed, mem, demo, music})

def report(tag: String, p: Bool & M.Game) -> IO(Maybe<M.Game>):
  (quit, g) = p
  reported(quit, tag, g)

# A frame of the game, then its state's line; a game that has quit stays
# quit.
def frame(tag: String, now: Nat, events: List<Event>, m: Maybe<M.Game>) -> IO(Maybe<M.Game>):
  match m:
    case None{}:
      IO.pure(Maybe<M.Game>, None{})
    case Some{g}:
      IO.bind(Bool & M.Game, Maybe<M.Game>, M.Game.frame(now, events, g), after => report(tag, after))

# The turn to 202.5 degrees beside Freedoom's exit switch, where the use
# reaches through the alcove past the shotgun guy of record 289. The
# walk west that used to carry the player here is gone: with ticket 16
# that shotgun guy chases and shoots, and it blocks the walk long before
# the switch, so the player is put where the walk left it.
def route() -> List<&2, K.Cmd>:
  List.concat(&2, K.Cmd, [[K.Cmd.demo(0, 0, 16, 0)], List.replicate(K.Cmd, 5n, K.Cmd.idle())])

# The game handed another state, to put a second case to the same loop.
def restaged(g: M.Game, s: S.State) -> M.Game:
  M.Game{level, gfx, tables, was, input, again, last, owed, mem, demo, music} = g
  M.Game{level, gfx, tables, I.Playing{s, L.Name{1, 1}}, input, again, last, owed, mem, demo, music}

def staged(s: S.State, m: Maybe<M.Game>) -> Maybe<M.Game>:
  match m:
    case None{}:
      None{}
    case Some{g}:
      Some{restaged(g, s)}

# A player killed where it stands in the nukage of sector 173, which
# five health a blow would take 609 tics to do.
def killed.at(+s: S.State) -> S.State:
  S.Sim.damage(H.Things.you(S.State.things(s)), 100, H.Thing.you(), H.Thing.you(), s)

def killed(level: L.Level) -> S.State:
  killed.at(S.State.at(level, L.Start{F.Fixed.of_map(1600), F.Fixed.of_map(1000), A.Angle.of_thing(90)}))


def warped.at(at: L.Level.Name) -> String:
  L.Name{episode, map} = at
  " " ++ L.Level.marker(episode, map)

def warped(args: List<String>) -> String:
  warped.at(M.Game.warp(args))

def play(mem: Array<U32>, gl: G.Gfx & L.Level) -> IO(Unit):
  (gfx, +level) = gl
  +beside = S.Sim.replay(route(), S.State.at(level, L.Start{F.Fixed.neg(F.Fixed.of_map(363)), F.Fixed.of_map(1316),
    A.Angle.of_thing(180)}))
  do IO<Unit>:
    IO.print("warp" ++ warped([]) ++ warped(["-warp", "1", "5"]) ++ warped(["-WARP", "2"]) ++ warped(["-warp"])
      ++ warped(["-nomonsters", "-warp", "1", "9", "-warp", "1", "2"]) ++ warped(["-warp", "15", "37"]))
    IO.print(line("start", S.State.start(level)))
    IO.print(line("beside", beside))
    IO.print(clicked(S.Sim.tic(K.Cmd.demo(0, 0, 0, 2), beside)))
    d : Maybe<M.Game> <- frame("dead space", 200n, [Key{32, True{}}], Some{M.Game{level, gfx,
      P.Project.tables(level), I.Playing{killed(level), L.Name{1, 1}},
      K.Input{K.Keys.none(), 0}, False{}, 0n, 0n, mem, None{}, None{}}})
    g1 : Maybe<M.Game> <- frame("space", 400n, [Key{32, True{}}], staged(beside, d))
    g2 : Maybe<M.Game> <- frame("repeat", 600n, [Key{32, False{}}, Key{32, True{}}], g1)
    g3 : Maybe<M.Game> <- frame("release", 800n, [Key{32, False{}}], g2)
    g4 : Maybe<M.Game> <- frame("enter", 800n, [Key{13, True{}}], g3)
    g5 : Maybe<M.Game> <- frame("esc", 1400n, [Key{27, True{}}], g4)
    return Unit{}

def start(w: Array<U32> & G.Gfx & L.Level) -> IO(Unit):
  (mem, gl) = w
  play(mem, gl)

def main() -> IO(Unit):
  do IO<Unit>:
    world : Array<U32> & G.Gfx & L.Level <- G.Gfx.open(1, 1)
    start(world)
#|warp E1M1 E1M5 E2M1 E1M1 E1M9 E1M3
#|start tic 0 ended none at -416.000000 256.000000 0.000 thinkers 9 sector 64 -128.000000 -128.000000 special 11 pressed False things 209 random 59
#|beside tic 6 ended none at -363.000000 1316.000000 202.500 thinkers 9 sector 64 -128.000000 -128.000000 special 11 pressed False things 209 random 66
#|use heard DSSWTCHN from nobody vol 64 sep 128 drew to 73
#|dead space tic 6 ended none at -416.000000 256.000000 0.000 thinkers 9 sector 64 -128.000000 -128.000000 special 11 pressed False things 209 random 125
#|space tally count 1 cnt 29 bcnt 6 shown - - - - - anims 0 0 0 - - 0 0 - - 0 random 83
#|repeat tally count 1 cnt 22 bcnt 13 shown - - - - - anims 0 1 0 0 0 0 1 0 0 1 random 83
#|release tally count 1 cnt 15 bcnt 20 shown - - - - - anims 1 1 1 1 0 1 1 0 1 1 random 83
#|enter tally count 1 cnt 15 bcnt 20 shown - - - - - anims 1 1 1 1 0 1 1 0 1 1 random 83
#|esc quit
