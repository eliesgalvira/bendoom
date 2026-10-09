# The game's frame functions measured on a private display and a
# real-rate draining sound device. FRAMES defaults to 3600; -warp uses
# the game's map selection. WALK=1 holds run, forward and left.
# SCRIPT runs before measurement. A reset or scene change invalidates
# the simulation-clock count. The first empty queue is startup.
import Base
import ../src/level.bend as L
import ../src/gfx.bend as G
import ../src/keys.bend as K
import ../src/game.bend as M
import ../src/stream.bend as A
import ../src/wad.bend as W
import ../src/inter.bend as I
import ../src/sim.bend as S
import ../src/project.bend as P
import ../src/demo.bend as D
import ../tools/script.bend as T

type Bench.Times is Data:
  Times{frames: Nat, tics: Nat, draw: Nat, step: Nat, mix: Nat, maxdraw: Nat, maxstep: Nat, maxmix: Nat,
    invalid: U32, startup: U32}

def Bench.input(+walk: Bool) -> K.Input:
  K.Input{K.Keys{walk, False{}, walk, False{}, False{}, False{}, walk, False{}, False{}, K.Keys.numbers.none()}, 0}

def Bench.clock(play: I.Play) -> U32:
  match play:
    case I.Playing{state, didsecret, pointer}:
      S.State.clock(state)
    case _:
      4294967295

def Bench.peek(g: M.Game) -> U32 & M.Game:
  M.Game{level, gfx, tables, +play, input, last, owed, mem, demo, music} = g
  (Bench.clock(play), M.Game{level, gfx, tables, play, input, last, owed, mem, demo, music})

def Bench.dry(music: Maybe<A.Stream>) -> U32 & Maybe<A.Stream>:
  match music:
    case None{}:
      (0, None{})
    case Some{A.Stream{audio, deck, chans, bank, +dry}}:
      (dry, Some{A.Stream{audio, deck, chans, bank, dry}})

def Bench.startup.g(level: L.Level, gfx: G.Gfx, tables: P.Project.Tables, play: I.Play, input: K.Input,
  last: Nat, owed: Nat, mem: Array<U32>, demo: Maybe<D.Demo.Rec>, p: U32 & Maybe<A.Stream>) -> U32 & M.Game:
  (dry, music) = p
  (dry, M.Game{level, gfx, tables, play, input, last, owed, mem, demo, music})

def Bench.startup(g: M.Game) -> U32 & M.Game:
  M.Game{level, gfx, tables, play, input, last, owed, mem, demo, music} = g
  Bench.startup.g(level, gfx, tables, play, input, last, owed, mem, demo, Bench.dry(music))

def Bench.audio(+startup: U32, dry: Maybe<U32>) -> String:
  match dry:
    case None{}:
      ", no audio device"
    case Some{n}:
      ", startup_empty=" ++ U32.show(startup) ++ ", underruns=" ++ U32.show((n - startup : U32))

def Bench.report(t0: Nat, t1: Nat, +accounted: Nat, stats: Bench.Times, dry: Maybe<U32>) -> IO(Unit):
  Times{+frames, +tics, draw, step, mix, maxdraw, maxstep, maxmix, invalid, startup} = stats
  +elapsed = Nat.sub(t1, t0)
  +expected = Nat.div(Nat.mul(accounted, 35n), 1000n)
  IO.print("frames=" ++ Nat.show(frames) ++ ", elapsed_ms=" ++ Nat.show(elapsed)
    ++ ", simulation_tics=" ++ Nat.show(tics) ++ ", tics_per_second_milli="
    ++ Nat.show(Nat.div(Nat.mul(tics, 1000000n), elapsed))
    ++ ", accounted_ms=" ++ Nat.show(accounted) ++ ", expected_tics=" ++ Nat.show(expected)
    ++ ", lost_tics=" ++ Nat.show(Nat.sub(expected, tics))
    ++ ", draw_ms=" ++ Nat.show(draw) ++ ", step_ms=" ++ Nat.show(step) ++ ", mix_ms=" ++ Nat.show(mix)
    ++ ", max_draw_ms=" ++ Nat.show(maxdraw) ++ ", max_step_ms=" ++ Nat.show(maxstep)
    ++ ", max_mix_ms=" ++ Nat.show(maxmix) ++ ", invalid_clock_frames=" ++ U32.show(invalid)
    ++ Bench.audio(startup, dry))

def Bench.stop(+t0: Nat, stats: Bench.Times, window: Window, g: M.Game) -> IO(Unit):
  M.Game{level, gfx, tables, play, input, +last, owed, mem, demo, music} = g
  do IO<Unit>:
    t1 : Nat <- IO.now()
    dry : Maybe<U32> <- M.Game.shut(window, M.Game{level, gfx, tables, play, input, last, owed, mem, demo, music})
    Bench.report(t0, t1, Nat.sub(last, t0), stats, dry)

def Bench.measured(+before: U32, +after: U32, +draw: Nat, +step: Nat, +mix: Nat, startup: U32,
  stats: Bench.Times) -> Bench.Times:
  Times{+frames, tics, draws, steps, mixes, maxdraw, maxstep, maxmix, invalid, initial} = stats
  +bad = Bool.or(U32.is_lt(after, before), U32.is_eq(after, 4294967295))
  Times{Nat.add(frames, 1n), Nat.add(tics, U32.to_nat(Bool.pick(U32, bad, 0, (after - before : U32)))),
    Nat.add(draws, draw), Nat.add(steps, step), Nat.add(mixes, mix), Nat.max(maxdraw, draw),
    Nat.max(maxstep, step), Nat.max(maxmix, mix), (invalid + Bool.to_u32(bad) : U32),
    Bool.pick(U32, Nat.is_eq(frames, 0n), startup, initial)}

def Bench.counted(quit: Bool, before: U32, after: U32, draw: Nat, step: Nat, mix: Nat, stats: Bench.Times,
  window: Window, rest: Bool -> Window -> M.Game -> Bench.Times -> IO(Unit), p: U32 & M.Game) -> IO(Unit):
  (startup, g) = p
  rest(quit, window, g, Bench.measured(before, after, draw, step, mix, startup, stats))

def Bench.clocked(quit: Bool, before: U32, draw: Nat, step: Nat, mix: Nat, stats: Bench.Times,
  window: Window, rest: Bool -> Window -> M.Game -> Bench.Times -> IO(Unit), p: U32 & M.Game) -> IO(Unit):
  (after, g) = p
  Bench.counted(quit, before, after, draw, step, mix, stats, window, rest, Bench.startup(g))

def Bench.mixed(before: U32, draw: Nat, step: Nat, tmix: Nat, stats: Bench.Times,
  window: Window, rest: Bool -> Window -> M.Game -> Bench.Times -> IO(Unit), p: Bool & M.Game) -> IO(Unit):
  (quit, g) = p
  do IO<Unit>:
    tend : Nat <- IO.now()
    Bench.clocked(quit, before, draw, step, Nat.sub(tend, tmix), stats, window, rest, Bench.peek(g))

def Bench.stepped(before: U32, draw: Nat, +tstep: Nat, stats: Bench.Times,
  window: Window, rest: Bool -> Window -> M.Game -> Bench.Times -> IO(Unit), p: Bool & M.Game) -> IO(Unit):
  do IO<Unit>:
    +tmix : Nat <- IO.now()
    mixed : Bool & M.Game <- M.Game.mixed(p)
    Bench.mixed(before, draw, Nat.sub(tmix, tstep), tmix, stats, window, rest, mixed)

def Bench.shown(before: U32, tdraw: Nat, stats: Bench.Times, g: M.Game,
  rest: Bool -> Window -> M.Game -> Bench.Times -> IO(Unit), p: Window & Image & List<Event>) -> IO(Unit):
  (window, image, events) = p
  do IO<Unit>:
    +tstep : Nat <- IO.now()
    stepped : Bool & M.Game <- M.Game.frame(tstep, events, g)
    Bench.stepped(before, Nat.sub(tstep, tdraw), tstep, stats, window, rest, stepped)

def Bench.drawn(before: U32, tdraw: Nat, stats: Bench.Times, window: Window,
  rest: Bool -> Window -> M.Game -> Bench.Times -> IO(Unit), p: M.Game & Image) -> IO(Unit):
  (g, image) = p
  IO.bind(Window & Image & List<Event>, Unit, Window.frame(window, image),
    shown => Bench.shown(before, tdraw, stats, g, rest, shown))

def Bench.frame(stats: Bench.Times, window: Window,
  rest: Bool -> Window -> M.Game -> Bench.Times -> IO(Unit), p: U32 & M.Game) -> IO(Unit):
  (before, g) = p
  do IO<Unit>:
    tdraw : Nat <- IO.now()
    Bench.drawn(before, tdraw, stats, window, rest, M.Game.view(g))

def Bench.loop(fuel: Nat, quit: Bool, +t0: Nat, stats: Bench.Times, window: Window, g: M.Game) -> IO(Unit):
  match fuel quit:
    case _ True{}:
      Bench.stop(t0, stats, window, g)
    case 0n False{}:
      Bench.stop(t0, stats, window, g)
    case 1n+rest False{}:
      Bench.frame(stats, window, quit => w => h => times => Bench.loop(rest, quit, t0, times, w, h), Bench.peek(g))

def Bench.started(frames: Nat, input: K.Input, music: Maybe<A.Stream>, steps: I.Play.Run) -> IO(Unit):
  I.Ran{I.World{play, mem, gfx, tables, level}, sounds} = steps
  do IO<Unit>:
    window : Window <- IO.try(Window, Window.open("Bendoom", 1280, 960))
    +t0 : Nat <- IO.now()
    Bench.loop(frames, False{}, t0, Times{0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n, 0, 0}, window,
      M.Game{level, gfx, tables, play, input, t0, 0n, mem, None{}, music})

def Bench.start(frames: Nat, input: K.Input, script: List<&2, K.Cmd>, p: Array<U32> & G.Gfx & L.Level & Maybe<A.Stream>) -> IO(Unit):
  (mem, gfx, level, music) = p
  IO.bind(I.Play.Run, Unit, I.Play.run(script, I.Ran{I.Play.World.start((mem, gfx, level)), []}),
    steps => Bench.started(frames, input, music, steps))

def Bench.load(frames: Nat, input: K.Input, script: List<&2, K.Cmd>, args: List<String>, wad: Array<U32> & List<&2, W.Wad.Lump>) -> IO(Unit):
  (mem, +dir) = wad
  IO.bind(Array<U32> & G.Gfx & L.Level & Maybe<A.Stream>, Unit, M.Game.load(M.Game.warp(dir, args), (mem, dir)),
    ready => Bench.start(frames, input, script, ready))

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    walk : Result<&1, &1, U32 & String, String> <- IO.get_env("WALK")
    script : Result<&1, &1, U32 & String, String> <- IO.get_env("SCRIPT")
    frames : Result<&1, &1, U32 & String, String> <- IO.get_env("FRAMES")
    wad : Array<U32> & List<&2, W.Wad.Lump> <- W.Wad.open()
    Bench.load(U32.to_nat(Maybe.default(&2, U32, U32.read(Result.default(&1, &1, U32 & String, String, frames, "3600")), 3600)),
      Bench.input(Result.is_done(&1, &1, U32 & String, String, walk)),
      List.concat(&2, K.Cmd, T.Script.runs(String.split(Result.default(&1, &1, U32 & String, String, script, ""), ' '))), args, wad)
