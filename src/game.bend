# The game's state and its frame loop: each frame draws the latest tic's
# state, shows it, folds the frame's key events into the held keys, and
# runs the tics the clock owes. The game runs it without end; the window
# bench runs it for a count of frames.
import Base
import ./level.bend as L
import ./gfx.bend as G
import ./keys.bend as K
import ./inter.bend as I
import ./sim.bend as S
import ./project.bend as P
import ./show.bend as V
import ./demo.bend as D
import ./sound.bend as Sn
import ./stream.bend as M

# The clock is read each frame; the tics it owes accumulate in
# thousandths of a tic, and at most eight run per frame, the rest
# forgiven, so a stall cannot snowball. The array is the frame and the
# graphics, redrawn each frame from the play's latest tic, the level or
# the tally after it. The level is the map as loaded, which the tally
# builds a fresh state from. Again is whether Space or Enter is down,
# which accelerates the tally. The demo is the one being recorded, until
# the level ends, and the music the mixer, if there is a sound device.
type Game is Type:
  Game{level: L.Level, gfx: G.Gfx, tables: P.Project.Tables, play: I.Play, input: K.Input,
    again: Bool, last: Nat, owed: Nat, mem: Array<U32>, demo: Maybe<D.Demo.Rec>, music: Maybe<M.Stream>}

def Game.shown(level: L.Level, gfx: G.Gfx, tables: P.Project.Tables, play: I.Play, input: K.Input,
  again: Bool, last: Nat, owed: Nat, demo: Maybe<D.Demo.Rec>, music: Maybe<M.Stream>,
  p: Array<U32> & Image) -> Game & Image:
  (mem, image) = p
  (Game{level, gfx, tables, play, input, again, last, owed, mem, demo, music}, image)

def Game.view(g: Game) -> Game & Image:
  Game{level, +gfx, +tables, +play, input, again, last, owed, mem, demo, music} = g
  Game.shown(level, gfx, tables, play, input, again, last, owed, demo, music,
    V.Show.image(I.Play.frame(tables, gfx, play, True{}, mem)))

def Game.key(+code: U32, +down: Bool, g: Game) -> Game:
  Game{level, gfx, tables, play, input, again, last, owed, mem, demo, music} = g
  Game{level, gfx, tables, play, K.Input.press(code, down, input),
    K.Keys.set(U32.is_eq(code, 32) || U32.is_eq(code, 13), down, again), last, owed, mem, demo, music}

def Game.quit(p: Bool & Game) -> Bool & Game:
  (quit, g) = p
  (True{}, g)

def Game.press(+code: U32, +down: Bool, p: Bool & Game) -> Bool & Game:
  (quit, g) = p
  (quit, Game.key(code, down, g))

# The frame's events folded in, and whether one of them quits.
def Game.event(e: Event, p: Bool & Game) -> Bool & Game:
  match e:
    case Key{27, True{}}:
      Game.quit(p)
    case Key{code, down}:
      Game.press(code, down, p)
    case Close{}:
      Game.quit(p)
    case _:
      p

def Game.events(events: List<Event>, p: Bool & Game) -> Bool & Game:
  match events:
    case []:
      p
    case e <> rest:
      Game.events(rest, Game.event(e, p))

def Game.owed(capped: Bool, due: Nat) -> Nat:
  match capped:
    case True{}:
      0n
    case False{}:
      Nat.mod(due, 1000n)

# The frame whose tics ended the level ends the demo, as vanilla's
# G_CheckDemoStatus does at the exit.
def Game.ended(ending: Bool, demo: Maybe<D.Demo.Rec>) -> IO(Maybe<D.Demo.Rec>):
  match ending:
    case True{}:
      do IO<Maybe<D.Demo.Rec>>:
        D.Demo.stop(demo)
        return None{}
    case False{}:
      IO.pure(Maybe<D.Demo.Rec>, demo)

type Game.Steps is Data:
  Steps{play: I.Play, sounds: List<&2, Sn.Sound.Event>}

def Game.tics(cmds: List<&2, K.Cmd>, +held: Bool, +level: L.Level, play: I.Play,
  sounds: List<&2, Sn.Sound.Event>) -> Game.Steps:
  match cmds:
    case []:
      Steps{play, sounds}
    case cmd <> rest:
      +step = I.Play.step(level, cmd, held, play)
      Game.tics(rest, held, level, I.Play.Step.play(step),
        List.append(&2, Sn.Sound.Event, sounds, I.Play.Step.sounds(step)))

def Game.started(+play: I.Play, demo: Maybe<D.Demo.Rec>, +level: L.Level, gfx: G.Gfx,
  tables: P.Project.Tables, input: K.Input, +again: Bool, last: Nat, owed: Nat, mem: Array<U32>,
  music: Maybe<M.Stream>, steps: Game.Steps) -> IO(Bool & Game):
  Steps{+next, events} = steps
  do IO<Bool & Game>:
    playing : Maybe<M.Stream> <- M.Stream.hear(events, music)
    kept : Maybe<D.Demo.Rec> <- Game.ended(Bool.and(I.Play.playing(play), Bool.not(I.Play.playing(next))),
      demo)
    return (False{}, Game{level, gfx, tables, next, input, again, last, owed, mem, kept, playing})

def Game.advanced(+play: I.Play, played: Maybe<D.Demo.Rec> & List<&2, K.Cmd>, +level: L.Level, gfx: G.Gfx,
  tables: P.Project.Tables, input: K.Input, +again: Bool, last: Nat, owed: Nat, mem: Array<U32>,
  music: Maybe<M.Stream>) -> IO(Bool & Game):
  (demo, cmds) = played
  Game.started(play, demo, level, gfx, tables, input, again, last, owed, mem, music,
    Game.tics(cmds, again, level, I.Play.ready(level, play), []))

# The play runs the tics the clock owes since the last frame, each on
# the command built from the held keys, as the demo holds it, and with
# Space or Enter held as the press that accelerates the tally, which the
# tally itself reads on its first tic down.
def Game.advance(+now: Nat, g: Game) -> IO(Bool & Game):
  Game{+level, gfx, tables, play, +input, +again, last, owed, mem, demo, music} = g
  +due = Nat.add(owed, Nat.mul(Nat.sub(now, last), 35n))
  +capped = Nat.is_gt(Nat.div(due, 1000n), 8n)
  +tics = Bool.pick(Nat, capped, 8n, Nat.div(due, 1000n))
  do IO<Bool & Game>:
    played : Maybe<D.Demo.Rec> & List<&2, K.Cmd> <- D.Demo.record(demo, K.Input.script(tics, input))
    Game.advanced(play, played, level, gfx, tables, K.Input.after(tics, input), again, now,
      Game.owed(capped, due), mem, music)

# A frame that quits runs no tics.
def Game.step(quit: Bool, now: Nat, g: Game) -> IO(Bool & Game):
  match quit:
    case True{}:
      IO.pure(Bool & Game, (True{}, g))
    case False{}:
      Game.advance(now, g)

def Game.stepped(now: Nat, p: Bool & Game) -> IO(Bool & Game):
  (quit, g) = p
  Game.step(quit, now, g)

# A frame of the loop at a time: the events folded in, then the tics;
# and whether one of the events quits.
def Game.frame(now: Nat, events: List<Event>, g: Game) -> IO(Bool & Game):
  Game.stepped(now, Game.events(events, (False{}, g)))

def Game.wrote(+quit: Bool, g: Game) -> IO(Bool & Game):
  Game{level, gfx, tables, +play, input, again, last, owed, mem, demo, music} = g
  match play:
    case I.Playing{+state}:
      do IO<Bool & Game>:
        moved : Maybe<M.Stream> <- M.Stream.update(~S.State,
          ~(s => source => S.Sim.sound.parameters(False{}, s, source)), state, music)
        playing : Maybe<M.Stream> <- M.Stream.play(I.Play.song(I.Playing{state}), moved)
        return (quit, Game{level, gfx, tables, I.Playing{state}, input, again, last, owed, mem, demo, playing})
    case I.Showing{+wi}:
      IO.bind(Maybe<M.Stream>, Bool & Game, M.Stream.play(I.Play.song(I.Showing{wi}), music),
        playing => IO.pure(Bool & Game, (quit, Game{level, gfx, tables, I.Showing{wi}, input, again, last, owed,
          mem, demo, playing})))

def Game.mixed(p: Bool & Game) -> IO(Bool & Game):
  (+quit, g) = p
  Game.wrote(quit, g)

def Game.tick(events: List<Event>, g: Game) -> IO(Bool & Game):
  do IO<Bool & Game>:
    now : Nat <- IO.now()
    stepped : Bool & Game <- Game.frame(now, events, g)
    Game.mixed(stepped)

# The window, the demo and the mixer let go, whether the game quits or
# its fuel runs out: the frames whose top-up found the device's queue
# empty, if the mixer ran.
def Game.shut(window: Window, g: Game) -> IO(Maybe<U32>):
  Game{level, gfx, tables, play, input, again, last, owed, mem, demo, music} = g
  do IO<Maybe<U32>>:
    Window.close(window)
    D.Demo.stop(demo)
    M.Stream.stop(music)

def Game.over(quit: Bool, window: Window, g: Game, rest: Window -> Game -> IO(Maybe<U32>)) -> IO(Maybe<U32>):
  match quit:
    case True{}:
      Game.shut(window, g)
    case False{}:
      rest(window, g)

def Game.next(window: Window, rest: Window -> Game -> IO(Maybe<U32>), p: Bool & Game) -> IO(Maybe<U32>):
  (quit, g) = p
  Game.over(quit, window, g, rest)

def Game.turn(shown: Window & Image & List<Event>, g: Game,
  rest: Window -> Game -> IO(Maybe<U32>)) -> IO(Maybe<U32>):
  (window, image, events) = shown
  IO.bind(Bool & Game, Maybe<U32>, Game.tick(events, g), p => Game.next(window, rest, p))

def Game.draw(window: Window, drawn: Game & Image, rest: Window -> Game -> IO(Maybe<U32>)) ->
  IO(Maybe<U32>):
  (g, image) = drawn
  do IO<Maybe<U32>>:
    shown : Window & Image & List<Event> <- Window.frame(window, image)
    Game.turn(shown, g, rest)

# Base's App.run drops each frame on the GPU lane, which makes the
# binary compile for the GPU at launch; this loop draws the same way
# without it.
def Game.loop(fuel: Nat, window: Window, g: Game) -> IO(Maybe<U32>):
  match fuel:
    case 0n:
      Game.shut(window, g)
    case 1n+f:
      Game.draw(window, Game.view(g), w => h => Game.loop(f, w, h))

def Game.start.go(frames: Nat, input: K.Input, script: List<&2, K.Cmd>, demo: Maybe<D.Demo.Rec>, now: Nat,
  mem: Array<U32>, gl: G.Gfx & L.Level) -> IO(Maybe<U32>):
  (+gfx, +level) = gl
  do IO<Maybe<U32>>:
    window : Window <- IO.try(Window, Window.open("Bendoom", 1280, 960))
    music : Maybe<M.Stream> <- M.Stream.open(I.Play.songs())
    Game.loop(frames, window, Game{level, gfx, P.Project.tables(level),
      I.Play.replay(script, level, I.Play.start(level)), input, False{}, now, 0n, mem, demo, music})

# The window opened and the loop run for at most so many frames, from
# the player 1 start after a script, with the given input at first,
# recording the demo if one is open. Each frame plays the scene's song,
# which starts as vanilla's does at the level's load and the tally's
# start. It answers what Game.shut does.
def Game.start(frames: Nat, input: K.Input, script: List<&2, K.Cmd>, demo: Maybe<D.Demo.Rec>, now: Nat,
  world: Array<U32> & G.Gfx & L.Level) -> IO(Maybe<U32>):
  (mem, gl) = world
  Game.start.go(frames, input, script, demo, now, mem, gl)
