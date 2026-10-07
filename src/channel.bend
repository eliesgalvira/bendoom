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
import ./bytes.bend as B
import ./wad.bend as W

# A playing sound: the bank's frames from the one the mixer writes next
# to the one past its last.
type Channel is Data:
  Chan{at: U32, sfx: U32, source: Sn.Sound.Source, left: U32, right: U32, end: U32}

# A sound of the table, by its number, and its span of the bank.
type Channel.Sound is Data:
  Sound{id: U32, at: U32, end: U32}

# The expanded frames, 16-bit samples one a slot, and where each sound's
# lie.
type Channel.Bank is Type:
  Bank{frames: Array<U32>, sounds: List<&2, Channel.Sound>}

def Channel.length(m: Maybe<&2, X.Sfx.Sound>) -> U32:
  match m:
    case None{}:
      0
    case Some{s}:
      X.Sfx.length(s)

type Channel.Plan is Type:
  Plan{wad: Array<U32>, sounds: List<&2, Channel.Sound>, end: U32}

def Channel.plan.read(+id: U32, +at: U32, sounds: List<&2, Channel.Sound>, +size: U32,
  p: Array<U32> & List<&2, U32>) -> Channel.Plan:
  (a, bytes) = p
  +end = (at + Channel.length(X.Sfx.read.sized(size, bytes)) : U32)
  Plan{a, Sound{id, at, end} <> sounds, end}

def Channel.plan.at(id: U32, p: Channel.Plan, q: U32 & U32) -> Channel.Plan:
  Plan{a, sounds, at} = p
  (pos, +size) = q
  Channel.plan.read(id, at, sounds, size, B.Bytes.file.list(a, pos, U32.min(size, 8)))

def Channel.plan.one(row: Sn.Sound.Sfx, +dir: List<&2, W.Wad.Lump>, p: Channel.Plan) -> Channel.Plan:
  Sn.Sfx{id, +lump, priority} = row
  Channel.plan.at(id, p, W.Wad.find(dir, lump))

def Channel.plan(rows: List<&2, Sn.Sound.Sfx>, +dir: List<&2, W.Wad.Lump>, p: Channel.Plan) -> Channel.Plan:
  match rows:
    case []:
      p
    case row <> rest:
      Channel.plan(rest, dir, Channel.plan.one(row, dir, p))

def Channel.expand(m: Maybe<&2, X.Sfx.Sound>, +at: U32, a: Array<U32>) -> Array<U32>:
  match m:
    case None{}:
      a
    case Some{s}:
      X.Sfx.expand(s, a, at)

def Channel.fill.read(+at: U32, bank: Array<U32>, p: Array<U32> & List<&2, U32>) -> Array<U32> & Array<U32>:
  (wad, bytes) = p
  (wad, Channel.expand(X.Sfx.read(bytes), at, bank))

def Channel.fill.at(at: U32, p: Array<U32> & Array<U32>, q: U32 & U32) -> Array<U32> & Array<U32>:
  (wad, bank) = p
  (pos, size) = q
  Channel.fill.read(at, bank, B.Bytes.file.list(wad, pos, size))

def Channel.fill.one(row: Sn.Sound.Sfx, sound: Channel.Sound, +dir: List<&2, W.Wad.Lump>,
  p: Array<U32> & Array<U32>) -> Array<U32> & Array<U32>:
  Sn.Sfx{id, +lump, priority} = row
  Sound{number, at, end} = sound
  Channel.fill.at(at, p, W.Wad.find(dir, lump))

def Channel.fill(rows: List<&2, Sn.Sound.Sfx>, sounds: List<&2, Channel.Sound>, +dir: List<&2, W.Wad.Lump>,
  p: Array<U32> & Array<U32>) -> Array<U32> & Array<U32>:
  match rows sounds:
    case row <> rs sound <> ss:
      Channel.fill(rs, ss, dir, Channel.fill.one(row, sound, dir, p))
    case _ _:
      p

def Channel.filled(sounds: List<&2, Channel.Sound>, p: Array<U32> & Array<U32>) -> Array<U32> & Channel.Bank:
  (wad, frames) = p
  (wad, Bank{frames, sounds})

def Channel.planned(rows: List<&2, Sn.Sound.Sfx>, dir: List<&2, W.Wad.Lump>, p: Channel.Plan) ->
  Array<U32> & Channel.Bank:
  Plan{wad, +sounds, end} = p
  +ordered = List.reverse(&2, Channel.Sound, sounds)
  Channel.filled(ordered, Channel.fill(rows, ordered, dir, (wad, Array.new(U32, V.Vec.depth(end), 0))))

# The rows' sounds expanded one lump at a time from the opened WAD.
# A lump CacheSFX refuses is a sound of no frames.
def Channel.load(+rows: List<&2, Sn.Sound.Sfx>, p: Array<U32> & List<&2, W.Wad.Lump>) -> Array<U32> & Channel.Bank:
  (wad, +dir) = p
  Channel.planned(rows, dir, Channel.plan(rows, dir, Plan{wad, [], 0}))

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
    case Some{Chan{at, sfx, +was, left, right, end}}:
      Channel.kept(Sn.Sound.Source.same(source, was), Chan{at, sfx, was, left, right, end})

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
    case Some{Chan{at, sfx, source, left, right, end}}:
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
    Chan{at, sfx, source, left, right, end})

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
  Chan{at, sfx, source, left, right, end} = c
  (+vol, +sep) = p
  Channel.kept(U32.is_zero(vol), Chan{at, sfx, source, Channel.left(vol, sep), Channel.right(vol, sep), end})

def Channel.update.slot(~Ctx: Data, ~params: Ctx -> Sn.Sound.Source -> U32 & U32, +ctx: Ctx,
  c: Maybe<&2, Channel>) -> Maybe<&2, Channel>:
  match c:
    case None{}:
      None{}
    case Some{Chan{at, sfx, +source, left, right, end}}:
      Channel.moved(Chan{at, sfx, source, left, right, end}, params(ctx, source))

# S_UpdateSounds follows the current listener and source positions.
def Channel.update(~Ctx: Data, ~params: Ctx -> Sn.Sound.Source -> U32 & U32, +ctx: Ctx,
  chans: List<&2, Maybe<&2, Channel>>) -> List<&2, Maybe<&2, Channel>>:
  match chans:
    case []:
      []
    case c <> rest:
      Channel.update.slot(~Ctx, ~params, ctx, c) <> Channel.update(~Ctx, ~params, ctx, rest)
