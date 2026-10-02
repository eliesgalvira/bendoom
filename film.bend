# A demo as raw video: E1M1 from the WAD named by BENDOOM_IWAD, the demo
# named by DEMO played from the player 1 start, and each tic's frame
# printed in the window's colours, 320 by 200 RGB triples as a line of
# hex, 35 frames a second. Its audio, the scene's song and the sounds as
# the game mixes them, goes to the file AUDIO names, 1260 frames a tic.
# nix run .#film decodes and encodes both.
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
import ./src/project.bend as P
import ./src/show.bend as V
import ./src/demo.bend as D

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

def Film.channels(play: I.Play, chans: List<Maybe<C.Channel>>) -> IO(List<Maybe<C.Channel>>):
  match play:
    case I.Playing{+state}:
      C.Channel.update(~S.State, ~(s => source => S.Sim.sound.parameters(False{}, s, source)), state, chans)
    case I.Showing{wi}:
      IO.pure(List<Maybe<C.Channel>>, chans)

def Film.mixed(audio: File, mixed: Sg.Song.Deck & List<Maybe<C.Channel>> & List<&2, U32>,
  next: File -> Sg.Song.Deck -> List<Maybe<C.Channel>> -> IO(Unit)) -> IO(Unit):
  (later, voices, words) = mixed
  IO.bind(File, Unit, B.Bytes.put_hex(audio, Film.pcm(words)),
    file => next(file, later, voices))

# Complete the count-up and leave the scores visible for three seconds.
# Five pauses and the percentages fit in 500 tics; the seconds target
# bounds the time counter, which advances three seconds per tic.
def Film.outro.tics(fuel: Nat, screen: I.Inter.Screen, +wi: I.Inter) -> List<&2, K.Cmd>:
  match fuel screen:
    case _ I.Count{10}:
      List.replicate(K.Cmd, 105n, K.Cmd.idle())
    case 1n+f I.Count{sp}:
      +next = I.Inter.tic(False{}, wi)
      K.Cmd.idle() <> Film.outro.tics(f, I.Inter.screen(next), next)
    case _ _:
      []

def Film.outro(play: I.Play) -> List<&2, K.Cmd>:
  match play:
    case I.Playing{state}:
      []
    case I.Showing{+wi}:
      Film.outro.tics(Nat.add(500n, U32.to_nat(Vec.Vec.get(I.Inter.target(wi), I.Inter.time()))),
        I.Inter.screen(wi), wi)

def Film.go(outros: Nat, cmds: List<&2, K.Cmd>, +level: L.Level, +tables: P.Project.Tables, +gfx: G.Gfx, +play: I.Play,
  deck: Sg.Song.Deck, chans: List<Maybe<C.Channel>>, +dir: String, audio: File, mem: Array<U32>) ->
  IO(Unit):
  match outros cmds:
    case 0n Nil{}:
      File.close(audio)
    case 1n+o Nil{}:
      Film.go(o, Film.outro(play), level, tables, gfx, play, deck, chans, dir, audio, mem)
    case _ cmd <> rest:
      +step = I.Play.step(level, cmd, False{}, play)
      +next = I.Play.Step.play(step)
      do IO<Unit>:
        heard : List<Maybe<C.Channel>> <- C.Channel.hear(dir, I.Play.Step.sounds(step), chans)
        moved : List<Maybe<C.Channel>> <- Film.channels(next, heard)
        mixed : Sg.Song.Deck & List<Maybe<C.Channel>> & List<&2, U32> <-
          M.Stream.window(1260, Sg.Song.Deck.change(I.Play.song(next), deck), moved)
        Film.mixed(audio, mixed, file => later => voices =>
          Film.shot(V.Show.rgb(I.Play.frame(tables, gfx, next, True{}, mem)),
            m => Film.go(outros, rest, level, tables, gfx, next, later, voices, dir, file, m)))

def Film.play(demo: List<&2, U32>, +sounds: String, audio: File, mem: Array<U32>, gl: G.Gfx & L.Level) -> IO(Unit):
  (+gfx, +level) = gl
  do IO<Unit>:
    deck : Sg.Song.Deck <- Sg.Song.Deck.load(I.Play.songs())
    Film.go(1n, D.Demo.play(demo), level, P.Project.tables(level), gfx, I.Play.start(level), deck, C.Channel.none(),
      sounds, audio, mem)

def Film.start(demo: List<&2, U32>, sounds: String, audio: File, w: Array<U32> & G.Gfx & L.Level) -> IO(Unit):
  (mem, gl) = w
  Film.play(demo, sounds, audio, mem, gl)

def main() -> IO(Unit):
  do IO<Unit>:
    path : String <- IO.try(String, IO.get_env("DEMO"))
    audio_path : String <- IO.try(String, IO.get_env("AUDIO"))
    sounds : String <- IO.try(String, IO.get_env("BENDOOM_SOUNDS"))
    file : File <- IO.try(File, File.open(path, "r"))
    audio : File <- IO.try(File, File.open(audio_path, "w"))
    demo : List<&2, U32> <- B.Bytes.fold(~List<&2, U32>, ~(chunk => read => List.append(&2, U32, read, chunk)), file, [])
    world : Array<U32> & G.Gfx & L.Level <- G.Gfx.open()
    Film.start(demo, sounds, audio, world)
