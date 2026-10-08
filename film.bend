# A demo as raw video: the demo named by DEMO played from the player 1
# start of the map its header names, from the WAD named by BENDOOM_IWAD,
# and each tic's frame printed in the window's colours, 320 by 200 RGB
# triples as a line of hex, 35 frames a second. Its audio, the scene's
# song and the sounds as the game mixes them, goes to the file AUDIO
# names, 1260 frames a tic. nix run .#film decodes and encodes both.
import Base
import ./src/bytes.bend as B
import ./src/vec.bend as Vec
import ./src/level.bend as L
import ./src/gfx.bend as G
import ./src/keys.bend as K
import ./src/sim.bend as S
import ./src/inter.bend as I
import ./src/sound.bend as Sn
import ./src/channel.bend as C
import ./src/stream.bend as M
import ./src/song.bend as Sg
import ./src/finale.bend as Fi
import ./src/show.bend as V
import ./src/demo.bend as D
import ./src/wad.bend as W

def Film.rgb(colours: List<&2, U32>) -> List<&2, U32>:
  match colours:
    case []:
      []
    case +c <> rest:
      ((c >> 16n) .&. 255 : U32) <> ((c >> 8n) .&. 255 : U32) <> (c .&. 255 : U32) <> Film.rgb(rest)

def Film.shot(p: Array<U32> & List<&2, U32>, rest: Array<U32> -> IO(Unit)) -> IO(Unit):
  (mem, colours) = p
  do IO<Unit>:
    IO.print(B.Bytes.hex(Film.rgb(colours)))
    rest(mem)

def Film.pcm(words: List<&2, U32>) -> List<&2, U32>:
  match words:
    case []:
      []
    case +w <> rest:
      (w .&. 255 : U32) <> ((w >> 8n : U32) .&. 255 : U32) <>
        ((w >> 16n : U32) .&. 255 : U32) <> ((w >> 24n : U32) .&. 255 : U32) <> Film.pcm(rest)

def Film.channels(play: I.Play, chans: List<&2, Maybe<&2, C.Channel>>) -> List<&2, Maybe<&2, C.Channel>>:
  match play:
    case I.Playing{+state, map, didsecret, pointer}:
      C.Channel.update(~S.State, ~(s => source => S.Sim.sound.parameters(False{}, s, source)), state, chans)
    case _:
      chans

def Film.mixed(audio: File, w: M.Stream.Window,
  next: File -> Sg.Song.Deck -> List<&2, Maybe<&2, C.Channel>> -> C.Channel.Bank -> IO(Unit)) -> IO(Unit):
  M.Window{bank, later, voices, words} = w
  IO.bind(File, Unit, B.Bytes.put_hex(audio, Film.pcm(words)),
    file => next(file, later, voices, bank))

# Complete the count-up and leave the scores visible for three seconds.
# Five pauses and the percentages fit in 500 tics; the seconds target
# bounds the time counter, which advances three seconds per tic.
def Film.outro.tics(fuel: Nat, screen: I.Inter.Screen, +wi: I.Inter) -> List<&2, K.Cmd>:
  match fuel screen:
    case _ I.Count{10}:
      List.replicate(K.Cmd, 105n, K.Cmd.idle())
    case 1n+f I.Count{sp}:
      +next = I.Inter.tic(0, wi)
      K.Cmd.idle() <> Film.outro.tics(f, I.Inter.screen(next), next)
    case _ _:
      []

def Film.outro.of(+wi: I.Inter) -> List<&2, K.Cmd>:
  Film.outro.tics(Nat.add(500n, U32.to_nat(Vec.Vec.get(I.Inter.target(wi), I.Inter.time()))), I.Inter.screen(wi), wi)

def Film.outro.pending(how: S.Sim.Exit) -> List<&2, K.Cmd>:
  match how:
    case S.Unended{}:
      []
    case S.Ended{secret}:
      List.replicate(K.Cmd, Fi.Finale.outro(Fi.Finale.start()), K.Cmd.idle())

def Film.outro(play: I.Play) -> List<&2, K.Cmd>:
  match play:
    case I.Playing{state, L.Name{episode, 8}, didsecret, pointer}:
      Film.outro.pending(S.State.ended(state))
    case I.Playing{state, map, didsecret, pointer}:
      []
    case I.Showing{wi, after, trip}:
      Film.outro.of(wi)
    case I.Ending{f}:
      List.replicate(K.Cmd, Fi.Finale.outro(f), K.Cmd.idle())

# A tic at a time, each in the world loaded for it, its frame and its
# audio written.
def Film.go(outros: Nat, cmds: List<&2, K.Cmd>, world: I.Play.World, deck: Sg.Song.Deck,
  chans: List<&2, Maybe<&2, C.Channel>>, bank: C.Channel.Bank, audio: File) -> IO(Unit):
  match outros cmds:
    case 0n Nil{}:
      File.close(audio)
    case 1n+o Nil{}:
      I.World{+play, mem, gfx, tables, level} = world
      Film.go(o, Film.outro(play), I.World{play, mem, gfx, tables, level}, deck, chans, bank, audio)
    case _ cmd <> rest:
      I.World{play, mem, +gfx, +tables, +level} = world
      C.Bank{frames, +sounds} = bank
      +step = I.Play.step(level, cmd, play)
      +events = I.Play.Step.sounds(step)
      +next = I.Play.Step.play(step)
      Film.mixed(audio, M.Stream.window(1260, Sg.Song.Deck.change(I.Play.song(next), deck),
          Film.channels(next, C.Channel.hear(sounds, events, chans)), C.Bank{frames, sounds}),
        file => later => voices => kept =>
          Film.shot(V.Show.rgb(I.Play.frame(tables, gfx, next, True{}, mem)),
            m => IO.bind(I.Play.World, Unit, I.Play.load(I.World{next, m, gfx, tables, level}),
              loaded => Film.go(outros, rest, loaded, later, voices, kept, file))))

def Film.start(demo: List<&2, U32>, audio: File, world: I.Play.World, loaded: Sg.Song.Deck & C.Channel.Bank) ->
  IO(Unit):
  (deck, bank) = loaded
  Film.go(1n, D.Demo.play(demo), world, deck, C.Channel.none(), bank, audio)

def Film.world(+map: L.Level.Name, demo: List<&2, U32>, audio: File, dir: Array<U32> & List<&2, W.Wad.Lump>,
  loaded: Sg.Song.Deck & C.Channel.Bank) -> IO(Unit):
  L.Name{+episode, +number} = map
  IO.bind(Array<U32> & G.Gfx & L.Level, Unit,
    IO.pass(Array<U32> & G.Gfx & L.Level, G.Gfx.load(episode, number, dir)),
    world => Film.start(demo, audio, I.Play.World.start(map, world), loaded))

def Film.ready(+demo: List<&2, U32>, audio: File, dir: List<&2, W.Wad.Lump>,
  p: Array<U32> & Sg.Song.Deck & C.Channel.Bank) -> IO(Unit):
  (a, deck, bank) = p
  Film.world(D.Demo.map(demo), demo, audio, (a, dir), (deck, bank))

def Film.open(demo: List<&2, U32>, audio: File, p: Array<U32> & List<&2, W.Wad.Lump>) -> IO(Unit):
  (a, +dir) = p
  Film.ready(demo, audio, dir, M.Stream.read(I.Play.songs(), Sn.Sound.table(), (a, dir)))

def Film.load(demo: List<&2, U32>, audio: File) -> IO(Unit):
  do IO<Unit>:
    wad : Array<U32> & List<&2, W.Wad.Lump> <- W.Wad.open()
    Film.open(demo, audio, wad)

def main() -> IO(Unit):
  do IO<Unit>:
    path : String <- IO.try(String, IO.get_env("DEMO"))
    audio_path : String <- IO.try(String, IO.get_env("AUDIO"))
    audio : File <- IO.try(File, File.open(audio_path, "w"))
    demo : List<&2, U32> <- D.Demo.read(path)
    Film.load(demo, audio)
