# The mixer, the game's one writer to the sound device: the scene's song,
# synthesized from the opened WAD as the device asks for it, with every
# playing channel's sound over it, 44100 frames a second, left then
# right, a frame of the loop at a time. A sound is one file of raw
# 16-bit little-endian mono, as the sounds node writes it, and the open
# file is its place.
import Base
import ./bytes.bend as B
import ./song.bend as S
import ./sound.bend as Sn
import ./channel.bend as C

# The mixer: the device, the music in a list of one, the channels
# playing over it, the directory their files come from, and the game
# frames whose top-up found the device's queue empty, which the window
# bench reports. A list is the one shape the native build holds by
# pointer; the deck's own words would not fit the game's frame
# (docs/bend.md).
type Stream is Type:
  Stream{audio: Audio, deck: List<&2, S.Song.Deck>, chans: List<Maybe<C.Channel>>, dir: String, dry: U32}

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
# the same sample, so the file is mono and the sides part here.
def Stream.mix(+left: U32, +right: U32, +s: U32, +w: U32) -> U32:
  (Stream.add(Stream.side(s, left), (w .&. 65535 : U32))
    .|. (Stream.add(Stream.side(s, right), (w >> 16n : U32)) << 16n) : U32)

# A channel's next frames added to what is mixed so far, as SDL_mixer
# adds a channel to the music. The mix ends where the shorter of the two
# does, and a channel whose file ran out is the shorter one.
def Stream.over(+left: U32, +right: U32, mono: List<&2, U32>, words: List<&2, U32>) -> List<&2, U32>:
  match mono words:
    case lo <> hi <> rest w <> ws:
      Stream.mix(left, right, B.Bytes.le16(lo, hi), w) <> Stream.over(left, right, rest, ws)
    case _ ws:
      ws

# A channel whose read came up short has played its sound out: its file
# closes and the channel frees itself.
def Stream.voice.kept(+short: Bool, file: File, +sfx: U32, source: Sn.Sound.Source, +left: U32, +right: U32,
  words: List<&2, U32>) -> IO(Maybe<C.Channel> & List<&2, U32>):
  match short:
    case True{}:
      do IO<Maybe<C.Channel> & List<&2, U32>>:
        File.close(file)
        return (None{}, words)
    case False{}:
      IO.pure(Maybe<C.Channel> & List<&2, U32>, (Some{C.Chan{file, sfx, source, left, right}}, words))

def Stream.voice.got(+want: U32, +sfx: U32, source: Sn.Sound.Source, +left: U32, +right: U32,
  words: List<&2, U32>, p: File & Result<&1, &1, U32 & String, List<&2, U32>>) ->
  IO(Maybe<C.Channel> & List<&2, U32>):
  (file, got) = p
  +bytes = Result.default(&1, &1, U32 & String, List<&2, U32>, got, [])
  Stream.voice.kept(U32.is_lt(U32.from_nat(List.length(&2, U32, bytes)), (want * 2 : U32)), file, sfx, source,
    left, right, Stream.over(left, right, bytes, words))

# One channel mixed into the frames about to be written: its own next
# frames, read from where its file stands.
def Stream.voice(+want: U32, c: Maybe<C.Channel>, words: List<&2, U32>) ->
  IO(Maybe<C.Channel> & List<&2, U32>):
  match c:
    case None{}:
      IO.pure(Maybe<C.Channel> & List<&2, U32>, (None{}, words))
    case Some{C.Chan{file, sfx, source, left, right}}:
      IO.bind(File & Result<&1, &1, U32 & String, List<&2, U32>>, Maybe<C.Channel> & List<&2, U32>,
        File.read_bytes(file, (want * 2 : U32)), p => Stream.voice.got(want, sfx, source, left, right, words, p))

def Stream.voices.cons(c: Maybe<C.Channel>, q: List<Maybe<C.Channel>> & List<&2, U32>) ->
  IO(List<Maybe<C.Channel>> & List<&2, U32>):
  (cs, words) = q
  IO.pure(List<Maybe<C.Channel>> & List<&2, U32>, (c <> cs, words))

def Stream.voices.on(p: Maybe<C.Channel> & List<&2, U32>,
  rest: List<&2, U32> -> IO(List<Maybe<C.Channel>> & List<&2, U32>)) ->
  IO(List<Maybe<C.Channel>> & List<&2, U32>):
  (c, words) = p
  IO.bind(List<Maybe<C.Channel>> & List<&2, U32>, List<Maybe<C.Channel>> & List<&2, U32>, rest(words),
    q => Stream.voices.cons(c, q))

# Every channel mixed in, in the order SDL_mixer takes them, since the
# clipping of one addition is what the next adds to.
def Stream.voices(+want: U32, chans: List<Maybe<C.Channel>>, words: List<&2, U32>) ->
  IO(List<Maybe<C.Channel>> & List<&2, U32>):
  match chans:
    case []:
      IO.pure(List<Maybe<C.Channel>> & List<&2, U32>, ([], words))
    case c <> rest:
      IO.bind(Maybe<C.Channel> & List<&2, U32>, List<Maybe<C.Channel>> & List<&2, U32>,
        Stream.voice(want, c, words), p => Stream.voices.on(p, ws => Stream.voices(want, rest, ws)))

def Stream.post(song: List<&2, U32>, words: List<&2, U32>) -> List<&2, U32>:
  match song words:
    case +s <> ss +w <> ws:
      (Stream.add((w .&. 65535 : U32), (s .&. 65535 : U32))
        .|. (Stream.add((w >> 16n : U32), (s >> 16n : U32)) << 16n) : U32) <> Stream.post(ss, ws)
    case _ ws:
      ws

def Stream.window.done(deck: S.Song.Deck, song: List<&2, U32>, q: List<Maybe<C.Channel>> & List<&2, U32>) ->
  IO(S.Song.Deck & List<Maybe<C.Channel>> & List<&2, U32>):
  (chans, words) = q
  IO.pure(S.Song.Deck & List<Maybe<C.Channel>> & List<&2, U32>, (deck, chans, Stream.post(song, words)))

def Stream.window.mixed(+want: U32, chans: List<Maybe<C.Channel>>, p: S.Song.Deck & List<&2, U32>) ->
  IO(S.Song.Deck & List<Maybe<C.Channel>> & List<&2, U32>):
  (deck, song) = p
  IO.bind(List<Maybe<C.Channel>> & List<&2, U32>, S.Song.Deck & List<Maybe<C.Channel>> & List<&2, U32>,
    Stream.voices(want, chans, List.replicate(U32, U32.to_nat(want), 0)), q => Stream.window.done(deck, song, q))

# The next want frames of the mix. Chocolate Doom registers
# OPL_Mix_Callback as MIX_CHANNEL_POST, so the song is added after the
# sound channels have clipped.
def Stream.window(+want: U32, deck: S.Song.Deck, chans: List<Maybe<C.Channel>>) ->
  IO(S.Song.Deck & List<Maybe<C.Channel>> & List<&2, U32>):
  Stream.window.mixed(want, chans, S.Song.Deck.take(want, deck))

# The frames the device holds between top-ups, of the ring's 4096: 52.2
# ms at 44100 Hz, against Chocolate Doom's 1024 frames and 23.2 ms.
# The fight bench found 2048 dry on its cold run, 1536 intermittently
# dry and 1024 routinely dry.
def Stream.top() -> U32:
  2304

def Stream.wrote(deck: List<&2, S.Song.Deck>, chans: List<Maybe<C.Channel>>, dir: String, dry: U32,
  p: Audio & U32) -> IO(Stream):
  (audio, queued) = p
  IO.pure(Stream, Stream{audio, deck, chans, dir, dry})

def Stream.filled(audio: Audio, dir: String, dry: U32, r: S.Song.Deck & List<Maybe<C.Channel>> & List<&2, U32>) ->
  IO(Stream):
  (deck, chans, words) = r
  IO.bind(Audio & U32, Stream, Audio.write(audio, Stream.samples(words)),
    q => Stream.wrote([deck], chans, dir, dry, q))

def Stream.topped(+song: String, deck: List<&2, S.Song.Deck>, chans: List<Maybe<C.Channel>>, dir: String, +dry: U32,
  p: Audio & U32) -> IO(Stream):
  match deck:
    case []:
      Stream.wrote([], chans, dir, dry, p)
    case d <> rest:
      (audio, +queued) = p
      IO.bind(S.Song.Deck & List<Maybe<C.Channel>> & List<&2, U32>, Stream,
        Stream.window((Stream.top() - queued : U32), S.Song.Deck.change(song, d), chans),
        r => Stream.filled(audio, dir, (dry + Bool.to_u32(U32.is_zero(queued)) : U32), r))

# A frame of the mix with the scene's song, which S_ChangeMusic starts
# if another is playing: a write of no samples reads the queue, and the
# frames that bring it back to the top follow it. The song's place and
# each sound's therefore follow the device's clock, not the tic clock.
def Stream.frame(+song: String, m: Stream) -> IO(Stream):
  Stream{audio, deck, chans, dir, dry} = m
  IO.bind(Audio & U32, Stream, Audio.write(audio, []), p => Stream.topped(song, deck, chans, dir, dry, p))

def Stream.play(+song: String, m: Maybe<Stream>) -> IO(Maybe<Stream>):
  match m:
    case None{}:
      IO.pure(Maybe<Stream>, None{})
    case Some{s}:
      IO.bind(Stream, Maybe<Stream>, Stream.frame(song, s), kept => IO.pure(Maybe<Stream>, Some{kept}))

def Stream.heard(audio: Audio, deck: List<&2, S.Song.Deck>, dir: String, dry: U32, chans: List<Maybe<C.Channel>>) ->
  IO(Maybe<Stream>):
  IO.pure(Maybe<Stream>, Some{Stream{audio, deck, chans, dir, dry}})

# The sounds a frame's tics reported, given to the channels before the
# frame's write, so that a sound is in the write that follows its tic.
def Stream.hear(events: List<&2, Sn.Sound.Event>, m: Maybe<Stream>) -> IO(Maybe<Stream>):
  match m:
    case None{}:
      IO.pure(Maybe<Stream>, None{})
    case Some{Stream{audio, deck, chans, +dir, dry}}:
      IO.bind(List<Maybe<C.Channel>>, Maybe<Stream>, C.Channel.hear(dir, events, chans),
        cs => Stream.heard(audio, deck, dir, dry, cs))

def Stream.update(~Ctx: Data, ~params: Ctx -> Sn.Sound.Source -> U32 & U32, +ctx: Ctx,
  m: Maybe<Stream>) -> IO(Maybe<Stream>):
  match m:
    case None{}:
      IO.pure(Maybe<Stream>, None{})
    case Some{Stream{audio, deck, chans, dir, dry}}:
      IO.bind(List<Maybe<C.Channel>>, Maybe<Stream>, C.Channel.update(~Ctx, ~params, ctx, chans),
        cs => Stream.heard(audio, deck, dir, dry, cs))

# The sounds directory the launcher names, or none, which is one line
# and a game with the music alone.
def Stream.sounds(dir: Result<&1, &1, U32 & String, String>) -> IO(String):
  match dir:
    case Fail{e}:
      do IO<String>:
        IO.print_err("bendoom: BENDOOM_SOUNDS names no sounds; playing the music alone")
        return ""
    case Done{d}:
      IO.pure(String, d)

# A game with no sound device says so once and plays on in silence.
def Stream.silent() -> IO(Maybe<Stream>):
  do IO<Maybe<Stream>>:
    IO.print_err("bendoom: no sound device; playing silent")
    return None{}

def Stream.device(deck: S.Song.Deck, dir: String, audio: Result<&1, &1, U32 & String, Audio>) -> IO(Maybe<Stream>):
  match audio:
    case Fail{e}:
      Stream.silent()
    case Done{a}:
      IO.pure(Maybe<Stream>, Some{Stream{a, [deck], C.Channel.none(), dir, 0}})

# The named songs of the opened WAD, the directory the sounds are read
# from, and the device at 44100 Hz, or silence.
def Stream.open(songs: List<&2, String>) -> IO(Maybe<Stream>):
  do IO<Maybe<Stream>>:
    sounds : Result<&1, &1, U32 & String, String> <- IO.get_env("BENDOOM_SOUNDS")
    dir : String <- Stream.sounds(sounds)
    deck : S.Song.Deck <- S.Song.Deck.load(songs)
    audio : Result<&1, &1, U32 & String, Audio> <- Audio.open(44100)
    Stream.device(deck, dir, audio)

# The device and every playing sound let go; the frames that found the
# queue empty, if the mixer ran.
def Stream.stop(m: Maybe<Stream>) -> IO(Maybe<U32>):
  match m:
    case None{}:
      IO.pure(Maybe<U32>, None{})
    case Some{Stream{audio, deck, chans, dir, dry}}:
      do IO<Maybe<U32>>:
        Audio.close(audio)
        C.Channel.stop(chans)
        return Some{dry}
