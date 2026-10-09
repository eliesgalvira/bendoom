# The mixer, the game's one writer to the sound device: the scene's song,
# synthesized from the opened WAD as the device asks for it, with every
# playing channel's sound over it, 44100 frames a second, left then
# right, a frame of the loop at a time.
import Base
import ./bytes.bend as B
import ./wad.bend as W
import ./song.bend as S
import ./sound.bend as Sn
import ./channel.bend as C

# The mixer: the device, the music in a list of one, the channels
# playing over it, the bank they play from, and the game frames whose
# top-up found the device's queue empty, which the window bench reports.
# A list is the one shape the native build holds by pointer; the deck's
# own words would not fit the game's frame (docs/bend.md).
type Stream is Type:
  Stream{audio: Audio, deck: List<&2, S.Song.Deck>, chans: List<&2, Maybe<&2, C.Channel>>, bank: C.Channel.Bank,
    dry: U32}

# A 16-bit sample as the device takes it: its sign bit flipped is its
# value over 32768, offset by a half.
def Stream.sample(+x: U32) -> F32:
  +half = U32.to_f32(32768)
  ((U32.to_f32((x .^. 32768 : U32)) - half : F32) / half : F32)

# The frames of the mix as Audio.write takes them, left then right.
def Stream.samples(words: List<&2, U32>) -> List<&2, F32>:
  match words:
    case +w <> rest:
      Stream.sample((w .&. 65535 : U32)) <> Stream.sample((w >> 16n : U32)) <> Stream.samples(rest)
    case []:
      []

# SDL_mixer's _Eff_position_s16lsb on one side: (Sint16) ((float) sample
# * (side / 255.0f)), whose cast truncates toward zero, so a negative
# sample is scaled as its magnitude.
def Stream.side(+s: U32, +side: U32) -> U32:
  +neg = U32.is_ge(s, 32768)
  +q = F32.to_u32((U32.to_f32(Bool.pick(U32, neg, (65536 - s : U32), s)) * (U32.to_f32(side) / 255.0 : F32) : F32))
  (Bool.pick(U32, neg, (65536 - q : U32), q) .&. 65535 : U32)

# SDL3's SDL_MixAudio at full volume, which SDL_mixer calls once a
# channel: the two samples added and clipped to 16 bits. Each sign bit
# flipped puts the sum in 0 to 131070, so it cannot run below zero.
def Stream.add(+a: U32, +b: U32) -> U32:
  ((U32.clamp(((a .^. 32768 : U32) + (b .^. 32768 : U32) : U32), 32768, 98303) - 32768 : U32) .^. 32768 : U32)

# One frame of a channel over one frame of the mix: the sound's sample
# scaled to each side and added there. Both sides of the expansion hold
# the same sample, so the expansion is mono and the sides part here.
def Stream.mix(+left: U32, +right: U32, +s: U32, +w: U32) -> U32:
  (Stream.add(Stream.side(s, left), (w .&. 65535 : U32))
    .|. (Stream.add(Stream.side(s, right), (w >> 16n : U32)) << 16n) : U32)

# A channel's next frames added to what is mixed so far, as SDL_mixer
# adds a channel to the music. The mix ends where the shorter of the two
# does.
def Stream.over(+left: U32, +right: U32, frames: List<&2, U32>, words: List<&2, U32>) -> List<&2, U32>:
  match frames words:
    case s <> rest w <> ws:
      Stream.mix(left, right, s, w) <> Stream.over(left, right, rest, ws)
    case _ ws:
      ws

def Stream.voice.over(+left: U32, +right: U32, words: List<&2, U32>, q: Array<U32> & List<&2, U32>) ->
  Array<U32> & List<&2, U32>:
  (a, frames) = q
  (a, Stream.over(left, right, frames, words))

def Stream.voice.read(+left: U32, +right: U32, +at: U32, +n: U32, p: Array<U32> & List<&2, U32>) ->
  Array<U32> & List<&2, U32>:
  (a, words) = p
  Stream.voice.over(left, right, words, B.Bytes.list(a, at, n))

def Stream.voice(+want: U32, c: Maybe<&2, C.Channel>, p: Array<U32> & List<&2, U32>) -> Array<U32> & List<&2, U32>:
  match c:
    case None{}:
      p
    case Some{C.Chan{+at, sfx, source, +left, +right, +end}}:
      Stream.voice.read(left, right, at, U32.min(want, (end - at : U32)), p)

# Every channel mixed in, in the order SDL_mixer takes them, since the
# clipping of one addition is what the next adds to.
def Stream.voices(+want: U32, chans: List<&2, Maybe<&2, C.Channel>>, p: Array<U32> & List<&2, U32>) ->
  Array<U32> & List<&2, U32>:
  match chans:
    case []:
      p
    case c <> rest:
      Stream.voices(want, rest, Stream.voice(want, c, p))

# The device cursor stops at the end; S_UpdateSounds owns the channel.
def Stream.played.slot(+want: U32, c: Maybe<&2, C.Channel>) -> Maybe<&2, C.Channel>:
  match c:
    case None{}:
      None{}
    case Some{C.Chan{+at, sfx, source, left, right, +end}}:
      Some{C.Chan{(at + U32.min(want, (end - at : U32)) : U32), sfx, source, left, right, end}}

# The channels past want frames.
def Stream.played(+want: U32, chans: List<&2, Maybe<&2, C.Channel>>) -> List<&2, Maybe<&2, C.Channel>>:
  match chans:
    case []:
      []
    case c <> rest:
      Stream.played.slot(want, c) <> Stream.played(want, rest)

def Stream.post(song: List<&2, U32>, words: List<&2, U32>) -> List<&2, U32>:
  match song words:
    case +s <> ss +w <> ws:
      (Stream.add((w .&. 65535 : U32), (s .&. 65535 : U32))
        .|. (Stream.add((w >> 16n : U32), (s >> 16n : U32)) << 16n) : U32) <> Stream.post(ss, ws)
    case _ ws:
      ws

# A window of the mix: the bank, the deck, the channels after it, and
# its frames.
type Stream.Window is Type:
  Window{bank: C.Channel.Bank, deck: S.Song.Deck, chans: List<&2, Maybe<&2, C.Channel>>, words: List<&2, U32>}

def Stream.window.done(+sounds: List<&2, C.Channel.Sound>, deck: S.Song.Deck, chans: List<&2, Maybe<&2, C.Channel>>,
  song: List<&2, U32>, p: Array<U32> & List<&2, U32>) -> Stream.Window:
  (a, words) = p
  Window{C.Bank{a, sounds}, deck, chans, Stream.post(song, words)}

def Stream.window.mixed(+want: U32, +chans: List<&2, Maybe<&2, C.Channel>>, bank: C.Channel.Bank,
  p: S.Song.Deck & List<&2, U32>) -> Stream.Window:
  C.Bank{a, +sounds} = bank
  (deck, song) = p
  Stream.window.done(sounds, deck, Stream.played(want, chans), song,
    Stream.voices(want, chans, (a, List.replicate(U32, U32.to_nat(want), 0))))

# The next want frames of the mix. Chocolate Doom registers
# OPL_Mix_Callback as MIX_CHANNEL_POST, so the song is added after the
# sound channels have clipped.
def Stream.window(+want: U32, deck: S.Song.Deck, +chans: List<&2, Maybe<&2, C.Channel>>, bank: C.Channel.Bank) ->
  Stream.Window:
  Stream.window.mixed(want, chans, bank, S.Song.Deck.take(want, deck))

# The frames the device holds between top-ups, of the ring's 4096: 52.2
# ms at 44100 Hz, against Chocolate Doom's 1024 frames and 23.2 ms.
# The fight bench found 2048 dry on its cold run, 1536 intermittently
# dry and 1024 routinely dry.
def Stream.top() -> U32:
  2304

def Stream.wrote(deck: List<&2, S.Song.Deck>, chans: List<&2, Maybe<&2, C.Channel>>, bank: C.Channel.Bank,
  dry: U32, p: Audio & U32) -> IO(Stream):
  (audio, queued) = p
  IO.pure(Stream, Stream{audio, deck, chans, bank, dry})

def Stream.filled(audio: Audio, dry: U32, w: Stream.Window) -> IO(Stream):
  Window{bank, deck, chans, words} = w
  IO.bind(Audio & U32, Stream, Audio.write(audio, Stream.samples(words)),
    q => Stream.wrote([deck], chans, bank, dry, q))

def Stream.topped(+song: String, deck: List<&2, S.Song.Deck>, chans: List<&2, Maybe<&2, C.Channel>>,
  bank: C.Channel.Bank, +dry: U32, p: Audio & U32) -> IO(Stream):
  match deck:
    case []:
      Stream.wrote([], chans, bank, dry, p)
    case d <> rest:
      (audio, +queued) = p
      Stream.filled(audio, (dry + Bool.to_u32(U32.is_zero(queued)) : U32),
        Stream.window((Stream.top() - queued : U32), S.Song.Deck.change(song, d), chans, bank))

# A frame of the mix with the scene's song, which S_ChangeMusic starts
# if another is playing: a write of no samples reads the queue, and the
# frames that bring it back to the top follow it. The song's place and
# each sound's therefore follow the device's clock, not the tic clock.
def Stream.frame(+song: String, m: Stream) -> IO(Stream):
  Stream{audio, deck, chans, bank, dry} = m
  IO.bind(Audio & U32, Stream, Audio.write(audio, []), p => Stream.topped(song, deck, chans, bank, dry, p))

def Stream.play(+song: String, m: Maybe<Stream>) -> IO(Maybe<Stream>):
  match m:
    case None{}:
      IO.pure(Maybe<Stream>, None{})
    case Some{s}:
      IO.bind(Stream, Maybe<Stream>, Stream.frame(song, s), kept => IO.pure(Maybe<Stream>, Some{kept}))

# The sounds a frame's tics reported, given to the channels before the
# frame's write, so that a sound is in the write that follows its tic.
def Stream.hear(events: List<&2, Sn.Sound.Event>, m: Maybe<Stream>) -> Maybe<Stream>:
  match m:
    case None{}:
      None{}
    case Some{Stream{audio, deck, chans, C.Bank{a, +sounds}, dry}}:
      Some{Stream{audio, deck, C.Channel.hear(sounds, events, chans), C.Bank{a, sounds}, dry}}

def Stream.update(~Ctx: Data, ~params: Ctx -> Sn.Sound.Source -> U32 & U32, +ctx: Ctx,
  m: Maybe<Stream>) -> Maybe<Stream>:
  match m:
    case None{}:
      None{}
    case Some{Stream{audio, deck, chans, bank, dry}}:
      Some{Stream{audio, deck, C.Channel.update(~Ctx, ~params, ctx, chans), bank, dry}}

def Stream.read.songs(songs: List<&2, String>, bank: C.Channel.Bank,
  p: Array<U32> & List<&2, List<&2, U32>>) -> Array<U32> & S.Song.Deck & C.Channel.Bank:
  (a, lumps) = p
  (a, S.Song.Deck.of(songs, lumps), bank)

def Stream.read.bank(+songs: List<&2, String>, dir: List<&2, W.Wad.Lump>, p: Array<U32> & C.Channel.Bank) ->
  Array<U32> & S.Song.Deck & C.Channel.Bank:
  (a, bank) = p
  Stream.read.songs(songs, bank, W.Wad.lumps("GENMIDI" <> songs, dir, a))

# Songs and sounds expanded from the same opened WAD the graphics reads.
# Only one sound's raw bytes are held while its samples enter the bank.
def Stream.read(songs: List<&2, String>, rows: List<&2, Sn.Sound.Sfx>, p: Array<U32> & List<&2, W.Wad.Lump>) ->
  Array<U32> & S.Song.Deck & C.Channel.Bank:
  (a, +dir) = p
  Stream.read.bank(songs, dir, C.Channel.load(rows, (a, dir)))

def Stream.load.done(p: Array<U32> & S.Song.Deck & C.Channel.Bank) -> S.Song.Deck & C.Channel.Bank:
  (a, deck, bank) = p
  (deck, bank)

# The standalone mixer bench and tests read the same runtime bank.
def Stream.load(songs: List<&2, String>, rows: List<&2, Sn.Sound.Sfx>) -> IO(S.Song.Deck & C.Channel.Bank):
  do IO<S.Song.Deck & C.Channel.Bank>:
    wad : Array<U32> & List<&2, W.Wad.Lump> <- W.Wad.open()
    return Stream.load.done(Stream.read(songs, rows, wad))

# A game with no sound device says so once and plays on in silence.
def Stream.silent() -> IO(Maybe<Stream>):
  do IO<Maybe<Stream>>:
    IO.print_err("bendoom: no sound device; playing silent")
    return None{}

def Stream.device(audio: Result<&1, &1, U32 & String, Audio>, deck: S.Song.Deck, bank: C.Channel.Bank) ->
  IO(Maybe<Stream>):
  match audio:
    case Fail{e}:
      Stream.silent()
    case Done{a}:
      IO.pure(Maybe<Stream>, Some{Stream{a, [deck], C.Channel.none(), bank, 0}})

def Stream.opened(audio: Result<&1, &1, U32 & String, Audio>, p: S.Song.Deck & C.Channel.Bank) ->
  IO(Maybe<Stream>):
  (deck, bank) = p
  Stream.device(audio, deck, bank)

# The loaded songs and sounds on the device at 44100 Hz, or silence.
def Stream.open(loaded: S.Song.Deck & C.Channel.Bank) -> IO(Maybe<Stream>):
  do IO<Maybe<Stream>>:
    audio : Result<&1, &1, U32 & String, Audio> <- Audio.open(44100)
    Stream.opened(audio, loaded)

# The device let go; the frames that found the queue empty, if the mixer
# ran.
def Stream.stop(m: Maybe<Stream>) -> IO(Maybe<U32>):
  match m:
    case None{}:
      IO.pure(Maybe<U32>, None{})
    case Some{Stream{audio, deck, chans, bank, dry}}:
      do IO<Maybe<U32>>:
        Audio.close(audio)
        return Some{dry}
