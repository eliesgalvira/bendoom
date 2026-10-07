# Doom's s_sound.c channels: the eight voices a level's sounds are
# allotted. They live outside the sim's state because vanilla frees a
# channel when the device has finished it and not on a tic. A channel is
# the span of the bank its sound has left to play, the sound and the
# source that made it, and the left and right volumes the device was
# given for it. The bank is every sound expanded once from the opened
# WAD, end to end in one array; the mixer plays from it, and this module
# allots the spans.
import Base
import ./vec.bend as V
import ./sound.bend as Sn
import ./sfx.bend as X

# A playing sound: the bank's frames from the one the mixer writes next
# to the one past its last.
type Channel is Data:
  Chan{at: U32, end: U32, sfx: U32, source: Sn.Sound.Source, left: U32, right: U32}

# A sound of the table, by its number, and its span of the bank.
type Channel.Sound is Data:
  Sound{id: U32, at: U32, end: U32}

# The expanded frames, 16-bit samples one a slot, and where each sound's
# lie.
type Channel.Bank is Type:
  Bank{frames: Array<U32>, sounds: List<&2, Channel.Sound>}

# The lumps of the table's rows.
def Channel.lumps(rows: List<&2, Sn.Sound.Sfx>) -> List<&2, String>:
  match rows:
    case []:
      []
    case Sn.Sfx{id, lump, priority} <> rest:
      lump <> Channel.lumps(rest)

def Channel.length(m: Maybe<&2, X.Sfx.Sound>) -> U32:
  match m:
    case None{}:
      0
    case Some{s}:
      X.Sfx.length(s)

# Each row's sound laid after the one before, from at.
def Channel.layout(rows: List<&2, Sn.Sound.Sfx>, reads: List<&2, Maybe<&2, X.Sfx.Sound>>, +at: U32) ->
  List<&2, Channel.Sound>:
  match rows reads:
    case Sn.Sfx{id, lump, priority} <> rs m <> ms:
      +end = (at + Channel.length(m) : U32)
      Sound{id, at, end} <> Channel.layout(rs, ms, end)
    case _ _:
      []

def Channel.expand(m: Maybe<&2, X.Sfx.Sound>, +at: U32, a: Array<U32>) -> Array<U32>:
  match m:
    case None{}:
      a
    case Some{s}:
      X.Sfx.expand(s, a, at)

def Channel.fill(reads: List<&2, Maybe<&2, X.Sfx.Sound>>, sounds: List<&2, Channel.Sound>, a: Array<U32>) -> Array<U32>:
  match reads sounds:
    case m <> ms Sound{id, at, end} <> ss:
      Channel.fill(ms, ss, Channel.expand(m, at, a))
    case _ _:
      a

def Channel.end(m: Maybe<&2, Channel.Sound>) -> U32:
  match m:
    case None{}:
      0
    case Some{Sound{id, at, end}}:
      end

def Channel.read(lumps: List<&2, List<&2, U32>>) -> List<&2, Maybe<&2, X.Sfx.Sound>>:
  match lumps:
    case []:
      []
    case l <> rest:
      X.Sfx.read(l) <> Channel.read(rest)

def Channel.bank.of(+reads: List<&2, Maybe<&2, X.Sfx.Sound>>, +sounds: List<&2, Channel.Sound>) -> Channel.Bank:
  Bank{Channel.fill(reads, sounds, Array.new(U32, V.Vec.depth(Channel.end(List.last(&2, Channel.Sound, sounds))), 0)), sounds}

# The rows' sounds expanded from their lumps, the lumps in the rows'
# order. A lump CacheSFX refuses is a sound of no frames.
def Channel.bank(+rows: List<&2, Sn.Sound.Sfx>, lumps: List<&2, List<&2, U32>>) -> Channel.Bank:
  +reads = Channel.read(lumps)
  Channel.bank.of(reads, Channel.layout(rows, reads, 0))

# A sound's span in the bank, none for a sound it lacks.
def Channel.find(sounds: List<&2, Channel.Sound>, +sfx: U32) -> Channel.Sound:
  match sounds:
    case []:
      Sound{sfx, 0, 0}
    case Sound{+id, +at, +end} <> rest:
      Bool.pick(Channel.Sound, U32.is_eq(id, sfx), Sound{id, at, end}, Channel.find(rest, sfx))

# snd_channels at Chocolate Doom's default, every one free.
def Channel.none() -> List<&2, Maybe<&2, Channel>>:
  [None{}, None{}, None{}, None{}, None{}, None{}, None{}, None{}]

# One side of I_SDL_UpdateSoundParams: a share of the separation times
# the volume over 127, clamped to a byte.
def Channel.side(+share: U32, +vol: U32) -> U32:
  U32.min(((share * vol : U32) / 127 : U32), 255)

# Its left, ((254 - sep) * vol) / 127. A separation of 255 leaves the
# share below zero, which C divides toward zero and clamps to none, so
# the share stops at 0 here.
def Channel.left(+vol: U32, +sep: U32) -> U32:
  Channel.side((254 - U32.min(sep, 254) : U32), vol)

# Its right, (sep * vol) / 127.
def Channel.right(+vol: U32, +sep: U32) -> U32:
  Channel.side(sep, vol)

def Channel.kept(hit: Bool, c: Channel) -> Maybe<&2, Channel>:
  match hit:
    case True{}:
      None{}
    case False{}:
      Some{c}

def Channel.hush.slot(+source: Sn.Sound.Source, c: Maybe<&2, Channel>) -> Maybe<&2, Channel>:
  match c:
    case None{}:
      None{}
    case Some{Chan{at, end, sfx, +was, left, right}}:
      Channel.kept(Sn.Sound.Source.same(source, was), Chan{at, end, sfx, was, left, right})

# S_StopSound: the source's channel is freed. A source holds one channel
# at a time, so there is at most one to free.
def Channel.hush(+source: Sn.Sound.Source, chans: List<&2, Maybe<&2, Channel>>) -> List<&2, Maybe<&2, Channel>>:
  match chans:
    case []:
      []
    case c <> rest:
      Channel.hush.slot(source, c) <> Channel.hush(source, rest)

# The sound put in the channel of that number, whose own sound stops,
# S_GetChannel's S_StopChannel. A number past the last channel is the
# sound dropped.
def Channel.put(chans: List<&2, Maybe<&2, Channel>>, n: Nat, new: Channel) -> List<&2, Maybe<&2, Channel>>:
  match chans n:
    case [] _:
      []
    case c <> rest 0n:
      Some{new} <> rest
    case c <> rest 1n+m:
      c <> Channel.put(rest, m, new)

type Channel.Pick is Data:
  Pick{free: Nat, victim: Nat, size: Nat}

type Channel.Voice is Data:
  Voice{mine: Bool, priority: Nat}

def Channel.model.none() -> List<&2, Maybe<&2, Channel.Voice>>:
  [None{}, None{}, None{}, None{}, None{}, None{}, None{}, None{}]

def Channel.pick.busy(+take: Bool, p: Channel.Pick) -> Channel.Pick:
  Pick{free, victim, size} = p
  Pick{1n+free, Bool.pick(Nat, take, 0n, 1n+victim), 1n+size}

def Channel.pick.slot(+pri: Nat, c: Maybe<&2, Nat>, p: Channel.Pick) -> Channel.Pick:
  match c:
    case None{}:
      Pick{free, victim, size} = p
      Pick{0n, 1n+victim, 1n+size}
    case Some{old}:
      Channel.pick.busy(Nat.is_le(pri, old), p)

# S_GetChannel's two searches, independent of the files they allot: the
# first free slot and the first sound no more important than the new one.
def Channel.pick(+pri: Nat, slots: List<&2, Maybe<&2, Nat>>) -> Channel.Pick:
  match slots:
    case []:
      Pick{0n, 0n, 0n}
    case c <> rest:
      Channel.pick.slot(pri, c, Channel.pick(pri, rest))

def Channel.choice.free(p: Channel.Pick) -> Nat:
  Pick{+free, victim, size} = p
  Bool.pick(Nat, Nat.is_lt(free, size), free, victim)

def Channel.choice(+pri: Nat, slots: List<&2, Maybe<&2, Nat>>) -> Nat:
  Channel.choice.free(Channel.pick(pri, slots))

def Channel.model.keys.none(
  p: List<&2, Maybe<&2, Channel.Voice>> & List<&2, Maybe<&2, Nat>>) ->
  List<&2, Maybe<&2, Channel.Voice>> & List<&2, Maybe<&2, Nat>>:
  (slots, keys) = p
  (None{} <> slots, None{} <> keys)

def Channel.model.keys.some(+mine: Bool, +priority: Nat,
  p: List<&2, Maybe<&2, Channel.Voice>> & List<&2, Maybe<&2, Nat>>) ->
  List<&2, Maybe<&2, Channel.Voice>> & List<&2, Maybe<&2, Nat>>:
  (slots, keys) = p
  (Some{Voice{mine, priority}} <> slots,
    Bool.pick(Maybe<&2, Nat>, mine, None{}, Some{priority}) <> keys)

def Channel.model.keys.cons(c: Maybe<&2, Channel.Voice>,
  p: List<&2, Maybe<&2, Channel.Voice>> & List<&2, Maybe<&2, Nat>>) ->
  List<&2, Maybe<&2, Channel.Voice>> & List<&2, Maybe<&2, Nat>>:
  match c:
    case None{}:
      Channel.model.keys.none(p)
    case Some{Voice{mine, +priority}}:
      Channel.model.keys.some(mine, priority, p)

def Channel.model.keys(slots: List<&2, Maybe<&2, Channel.Voice>>) ->
  List<&2, Maybe<&2, Channel.Voice>> & List<&2, Maybe<&2, Nat>>:
  match slots:
    case []:
      ([], [])
    case c <> rest:
      Channel.model.keys.cons(c, Channel.model.keys(rest))

def Channel.model.table(p: List<&2, Maybe<&2, Channel.Voice>> & List<&2, Maybe<&2, Nat>>) ->
  List<&2, Maybe<&2, Channel.Voice>>:
  (slots, keys) = p
  slots

def Channel.model.clear(c: Maybe<&2, Channel.Voice>) -> Maybe<&2, Channel.Voice>:
  match c:
    case None{}:
      None{}
    case Some{Voice{mine, priority}}:
      Some{Voice{False{}, priority}}

def Channel.model.clear.all(slots: List<&2, Maybe<&2, Channel.Voice>>) ->
  List<&2, Maybe<&2, Channel.Voice>>:
  match slots:
    case []:
      []
    case c <> rest:
      Channel.model.clear(c) <> Channel.model.clear.all(rest)

def Channel.model.replace(slots: List<&2, Maybe<&2, Channel.Voice>>, +n: Nat, +priority: Nat) ->
  List<&2, Maybe<&2, Channel.Voice>>:
  match slots n:
    case [] _:
      []
    case c <> rest 0n:
      Some{Voice{True{}, priority}} <> Channel.model.clear.all(rest)
    case c <> rest 1n+m:
      Channel.model.clear(c) <> Channel.model.replace(rest, m, priority)

def Channel.model.start.hushed(+priority: Nat,
  p: List<&2, Maybe<&2, Channel.Voice>> & List<&2, Maybe<&2, Nat>>) ->
  List<&2, Maybe<&2, Channel.Voice>>:
  (slots, keys) = p
  Channel.model.replace(slots, Channel.choice(priority, keys), priority)

def Channel.model.start(+priority: Nat, slots: List<&2, Maybe<&2, Channel.Voice>>) ->
  List<&2, Maybe<&2, Channel.Voice>>:
  Channel.model.start.hushed(priority, Channel.model.keys(slots))

def Channel.model.size(slots: List<&2, Maybe<&2, Channel.Voice>>) -> Nat:
  match slots:
    case []:
      0n
    case c <> rest:
      1n+Channel.model.size(rest)

def Channel.model.size.keys(slots: List<&2, Maybe<&2, Nat>>) -> Nat:
  match slots:
    case []:
      0n
    case c <> rest:
      1n+Channel.model.size.keys(rest)

def Channel.model.one(slots: List<&2, Maybe<&2, Channel.Voice>>, +seen: Bool) -> Bool:
  match slots:
    case []:
      True{}
    case None{} <> rest:
      Channel.model.one(rest, seen)
    case Some{Voice{+mine, priority}} <> rest:
      Bool.and(Bool.not(Bool.and(seen, mine)),
        Channel.model.one(rest, Bool.or(seen, mine)))

def Channel.model.protected(+priority: Nat, slots: List<&2, Maybe<&2, Nat>>) -> Bool:
  match slots:
    case []:
      True{}
    case None{} <> rest:
      False{}
    case Some{old} <> rest:
      Bool.and(Bool.not(Nat.is_le(priority, old)), Channel.model.protected(priority, rest))

def Channel.key(c: Maybe<&2, Channel>) -> Maybe<&2, Nat>:
  match c:
    case None{}:
      None{}
    case Some{Chan{at, end, sfx, source, left, right}}:
      Some{U32.to_nat(Sn.Sound.priority(Sn.Sound.table(), sfx))}

def Channel.keys(chans: List<&2, Maybe<&2, Channel>>) -> List<&2, Maybe<&2, Nat>>:
  match chans:
    case []:
      []
    case c <> rest:
      Channel.key(c) <> Channel.keys(rest)

# S_GetChannel: a free channel takes the sound, or else the first
# channel of no greater importance is kicked out, and if every one is
# more important the sound is dropped. A sound the bank holds no frames
# of takes its channel too, as one whose lump CacheSFX refuses does, and
# frees it at the next mix.
def Channel.start(s: Channel.Sound, source: Sn.Sound.Source, +left: U32, +right: U32,
  +chans: List<&2, Maybe<&2, Channel>>) -> List<&2, Maybe<&2, Channel>>:
  Sound{+sfx, at, end} = s
  Channel.put(chans, Channel.choice(U32.to_nat(Sn.Sound.priority(Sn.Sound.table(), sfx)), Channel.keys(chans)),
    Chan{at, end, sfx, source, left, right})

# What the sim reported, played: S_StartSound's tail after the
# audibility test, where the source's old sound is stopped and the new
# one takes a channel at the sides the volume and separation give.
def Channel.event(+sounds: List<&2, Channel.Sound>, e: Sn.Sound.Event, chans: List<&2, Maybe<&2, Channel>>) ->
  List<&2, Maybe<&2, Channel>>:
  match e:
    case Sn.Start{sfx, +source, +vol, +sep}:
      Channel.start(Channel.find(sounds, sfx), source, Channel.left(vol, sep), Channel.right(vol, sep),
        Channel.hush(source, chans))
    case Sn.Stop{source}:
      Channel.hush(source, chans)

# The channels after the sounds of a frame's tics, in the order the tics
# made them.
def Channel.hear(+sounds: List<&2, Channel.Sound>, events: List<&2, Sn.Sound.Event>,
  chans: List<&2, Maybe<&2, Channel>>) -> List<&2, Maybe<&2, Channel>>:
  match events:
    case []:
      chans
    case e <> rest:
      Channel.hear(sounds, rest, Channel.event(sounds, e, chans))

def Channel.moved(c: Channel, p: U32 & U32) -> Maybe<&2, Channel>:
  Chan{at, end, sfx, source, left, right} = c
  (+vol, +sep) = p
  Channel.kept(U32.is_zero(vol), Chan{at, end, sfx, source, Channel.left(vol, sep), Channel.right(vol, sep)})

def Channel.update.slot(~Ctx: Data, ~params: Ctx -> Sn.Sound.Source -> U32 & U32, +ctx: Ctx,
  c: Maybe<&2, Channel>) -> Maybe<&2, Channel>:
  match c:
    case None{}:
      None{}
    case Some{Chan{at, end, sfx, +source, left, right}}:
      Channel.moved(Chan{at, end, sfx, source, left, right}, params(ctx, source))

# S_UpdateSounds follows the current listener and source positions.
def Channel.update(~Ctx: Data, ~params: Ctx -> Sn.Sound.Source -> U32 & U32, +ctx: Ctx,
  chans: List<&2, Maybe<&2, Channel>>) -> List<&2, Maybe<&2, Channel>>:
  match chans:
    case []:
      []
    case c <> rest:
      Channel.update.slot(~Ctx, ~params, ctx, c) <> Channel.update(~Ctx, ~params, ctx, rest)
