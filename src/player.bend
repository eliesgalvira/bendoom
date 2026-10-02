# DMX's music player as Chocolate Doom's src/i_oplmusic.c reproduces it,
# for the Doom 1.9 driver in OPL2 mode (nine voices, every channel's pan
# 0x30) at music volume 8 (64 of 127): the register writes that set the
# chip up and play the song's channel events with the WAD's GENMIDI
# instruments. Writes are kept latest first.
import Base
import ./vec.bend as V
import ./bytes.bend as B
import ./fixed.bend as F
import ./opl.bend as O
import ./opl_tables.bend as T

# A MIDI channel: its instrument (a GENMIDI index), volume and pitch
# bend (signed).
type Player.Chan is Data:
  Chan{instr: U32, volume: U32, bend: U32}

# A voice: its instrument and which of the instrument's two voices, its
# channel, the MIDI key it plays and the note it sounds (a fixed note, or
# 60 for percussion), the frequency word, the note's velocity, and the
# level registers last written to its carrier and modulator.
type Player.Voice is Data:
  Voice{instr: U32, iv: U32, chan: Maybe<&2, U32>, key: U32, note: U32, freq: U32, vol: U32, car: U32,
    mod: U32}

type Player is Data:
  Player{chans: List<&2, Player.Chan>, voices: List<&2, Player.Voice>, free: List<&2, U32>,
    alloced: List<&2, U32>, writes: List<&2, O.Opl.Write>}

# The GENMIDI lump's bytes, the frequency curve and the volume mapping.
type Player.Tabs is Data:
  Tabs{gm: V.Vec, curve: V.Vec, vmt: V.Vec}

def Player.tabs(+gm: List<&2, U32>) -> Player.Tabs:
  Tabs{V.Vec.of(gm), V.Vec.of_list(T.OplTables.freq(), 668), V.Vec.of_list(T.OplTables.volume(), 128)}

def Player.volume() -> U32:
  64

# A voice's instrument before its first note: past GENMIDI's 175, so no
# note asks for it.
def Player.no_instr() -> U32:
  175

def Player.setup.go(n: Nat, +r: U32, +v: U32) -> List<&2, O.Opl.Write>:
  match n:
    case 0n:
      []
    case 1n+m:
      O.Write{r, v} <> Player.setup.go(m, (r + 1 : U32), v)

# OPL_InitRegisters in OPL2 mode, in order, less its writes to the timer
# registers 2 to 4, which opl_sdl.c keeps from the chip.
def Player.setup() -> List<&2, O.Opl.Write>:
  List.concat(&2, O.Opl.Write, [Player.setup.go(22n, 64, 63), Player.setup.go(150n, 96, 0), [O.Write{1, 0}],
    Player.setup.go(59n, 5, 0), [O.Write{1, 32}, O.Write{8, 64}]])

def Player.Voice.fresh() -> Player.Voice:
  Voice{Player.no_instr(), 0, None{}, 0, 0, 0, 0, 0, 0}

# InitChannel on every channel.
def Player.channels() -> List<&2, Player.Chan>:
  List.replicate(Player.Chan, 16n, Chan{0, U32.min(Player.volume(), 100), 0})

# InitVoices and InitChannel.
def Player.start() -> Player:
  Player{Player.channels(), List.replicate(Player.Voice, 9n, Player.Voice.fresh()),
    [0, 1, 2, 3, 4, 5, 6, 7, 8], [], []}

# RestartSong's InitChannel on every channel; the voices, the free and
# allocated lists and the pending writes keep theirs.
def Player.restart(p: Player) -> Player:
  Player{chans, voices, free, alloced, writes} = p
  Player{Player.channels(), voices, free, alloced, writes}

# GENMIDI
# -------

def Player.byte(+t: Player.Tabs, +at: U32) -> U32:
  Tabs{gm, curve, vmt} = t
  V.Vec.get(gm, at)

# Instrument i's header, after the lump's eight-byte "#OPL_II#": flags,
# fine tuning, fixed note.
def Player.instr(+i: U32) -> U32:
  (8 + (i * 36) : U32)

def Player.flags(+t: Player.Tabs, +i: U32) -> U32:
  B.Bytes.le16(Player.byte(t, Player.instr(i)), Player.byte(t, (Player.instr(i) + 1 : U32)))

def Player.fixed(+t: Player.Tabs, +i: U32) -> Bool:
  U32.is_eq((Player.flags(t, i) .&. 1 : U32), 1)

# Voice iv of instrument i: the modulator (tremolo, attack, sustain,
# waveform, scale, level), feedback, the carrier, a spare byte and the
# base note offset.
def Player.gm_voice(+i: U32, +iv: U32) -> U32:
  (Player.instr(i) + 4 + (iv * 16) : U32)

# Fields
# ------

def Player.chan(+p: Player, +ch: U32) -> Player.Chan:
  Player{chans, voices, free, alloced, writes} = p
  Maybe.default(&2, Player.Chan, List.get(&2, Player.Chan, chans, U32.to_nat(ch)), Chan{0, 0, 0})

def Player.voice(+p: Player, +v: U32) -> Player.Voice:
  Player{chans, voices, free, alloced, writes} = p
  Maybe.default(&2, Player.Voice, List.get(&2, Player.Voice, voices, U32.to_nat(v)), Player.Voice.fresh())

def Player.free(+p: Player) -> List<&2, U32>:
  Player{chans, voices, free, alloced, writes} = p
  free

def Player.alloced(+p: Player) -> List<&2, U32>:
  Player{chans, voices, free, alloced, writes} = p
  alloced

def Player.writes(+p: Player) -> List<&2, O.Opl.Write>:
  Player{chans, voices, free, alloced, writes} = p
  writes

def Player.Chan.volume(+c: Player.Chan) -> U32:
  Chan{instr, volume, bend} = c
  volume

def Player.Chan.bend(+c: Player.Chan) -> U32:
  Chan{instr, volume, bend} = c
  bend

def Player.Chan.instr(+c: Player.Chan) -> U32:
  Chan{instr, volume, bend} = c
  instr

def Player.Voice.instr(+v: Player.Voice) -> U32:
  Voice{instr, iv, chan, key, note, freq, vol, car, mod} = v
  instr

def Player.Voice.iv(+v: Player.Voice) -> U32:
  Voice{instr, iv, chan, key, note, freq, vol, car, mod} = v
  iv

def Player.Voice.vol(+v: Player.Voice) -> U32:
  Voice{instr, iv, chan, key, note, freq, vol, car, mod} = v
  vol

def Player.Voice.key(+v: Player.Voice) -> U32:
  Voice{instr, iv, chan, key, note, freq, vol, car, mod} = v
  key

def Player.Voice.freq(+v: Player.Voice) -> U32:
  Voice{instr, iv, chan, key, note, freq, vol, car, mod} = v
  freq

# A voice's channel in the order of their pointers, which
# ReplaceExistingVoice compares: none, the null pointer, before any.
def Player.Voice.rank(+v: Player.Voice) -> U32:
  Voice{instr, iv, chan, key, note, freq, vol, car, mod} = v
  match chan:
    case None{}:
      0
    case Some{c}:
      (c + 1 : U32)

# Whether voice v plays on channel ch.
def Player.Voice.on(+v: Player.Voice, +ch: U32) -> Bool:
  U32.is_eq(Player.Voice.rank(v), (ch + 1 : U32))

def Player.op1(+v: U32) -> U32:
  (((v / 3) * 8) + (v % 3) : U32)

def Player.op2(+v: U32) -> U32:
  (Player.op1(v) + 3 : U32)

# Voices
# ------

# A voice and the writes made so far, through the steps of programming it.
type Player.Voiced is Data:
  Voiced{voice: Player.Voice, writes: List<&2, O.Opl.Write>}

# LoadOperatorData: the level register, then tremolo, attack, sustain and
# waveform from the operator's data at `at`.
def Player.load(+t: Player.Tabs, +op: U32, +at: U32, +level: U32, ws: List<&2, O.Opl.Write>) ->
  List<&2, O.Opl.Write>:
  O.Write{(224 + op : U32), Player.byte(t, (at + 3 : U32))} <>
  O.Write{(128 + op : U32), Player.byte(t, (at + 2 : U32))} <>
  O.Write{(96 + op : U32), Player.byte(t, (at + 1 : U32))} <>
  O.Write{(32 + op : U32), Player.byte(t, at)} <>
  O.Write{(64 + op : U32), level} <> ws

# SetVoiceInstrument past its early return: the carrier's operator, then
# the modulator's, at full attenuation but for a modulating modulator's
# own level, then feedback and connection with both sides on.
def Player.program(+t: Player.Tabs, +v: U32, +i: U32, +iv: U32, voice: Player.Voice,
  ws: List<&2, O.Opl.Write>) -> Player.Voiced:
  Voice{loaded_instr, loaded_iv, chan, key, note, freq, vol, car, mod} = voice
  +at = Player.gm_voice(i, iv)
  +fb = Player.byte(t, (at + 6 : U32))
  +carl = (Player.byte(t, (at + 11 : U32)) .|. 63 : U32)
  +modl = (Player.byte(t, (at + 4 : U32)) .|.
    Bool.pick(U32, U32.is_eq((fb .&. 1 : U32), 0), Player.byte(t, (at + 5 : U32)), 63) : U32)
  Voiced{Voice{i, iv, chan, key, note, freq, vol, carl, modl},
    O.Write{(192 + v : U32), (fb .|. 48 : U32)} <>
      Player.load(t, Player.op1(v), at, modl, Player.load(t, Player.op2(v), (at + 7 : U32), carl, ws))}

def Player.instrument.go(loaded: Bool, +t: Player.Tabs, +v: U32, +i: U32, +iv: U32, voice: Player.Voice,
  ws: List<&2, O.Opl.Write>) -> Player.Voiced:
  match loaded:
    case True{}:
      Voiced{voice, ws}
    case False{}:
      Player.program(t, v, i, iv, voice, ws)

def Player.instrument(+t: Player.Tabs, +v: U32, +i: U32, +iv: U32, +voice: Player.Voice,
  ws: List<&2, O.Opl.Write>) -> Player.Voiced:
  Player.instrument.go(U32.is_eq(Player.Voice.instr(voice), i) && U32.is_eq(Player.Voice.iv(voice), iv),
    t, v, i, iv, voice, ws)

# SetVoiceVolume: the carrier's level, and a non-modulating modulator's,
# written when they change.
def Player.level.go(+t: Player.Tabs, +v: U32, +chvol: U32, +velocity: U32, voice: Player.Voice,
  ws: List<&2, O.Opl.Write>) -> Player.Voiced:
  Tabs{gm, curve, +vmt} = t
  Voice{+instr, +iv, chan, key, note, freq, vol, +car, +mod} = voice
  +at = Player.gm_voice(instr, iv)
  +carv = (63 - ((V.Vec.get(vmt, velocity) * ((V.Vec.get(vmt, chvol) + 1) * 2)) >> 9n) : U32)
  +modl = Player.byte(t, (at + 5 : U32))
  +modv = (U32.max(modl, carv) .|. (mod .&. 192) : U32)
  +change = U32.is_ne(carv, (car .&. 63 : U32))
  +write_mod = change && U32.is_eq((Player.byte(t, (at + 6 : U32)) .&. 1 : U32), 1) && U32.is_ne(modl, 63)
    && U32.is_ne(modv, mod)
  +car2 = Bool.pick(U32, change, (carv .|. (car .&. 192) : U32), car)
  Voiced{Voice{instr, iv, chan, key, note, freq, velocity, car2, Bool.pick(U32, write_mod, modv, mod)},
    List.filter.put(O.Opl.Write,
      O.Write{(64 + Player.op1(v) : U32), (modv .|. (Player.byte(t, (at + 4 : U32)) .&. 192) : U32)},
      List.filter.put(O.Opl.Write, O.Write{(64 + Player.op2(v) : U32), car2}, ws, change), write_mod)}

def Player.level(+t: Player.Tabs, +v: U32, +chvol: U32, +velocity: U32, vw: Player.Voiced) -> Player.Voiced:
  Voiced{voice, ws} = vw
  Player.level.go(t, v, chvol, velocity, voice, ws)

# Signed n up by 12 until it is not negative, then down by 12 until it is
# at most 95.
def Player.octaves(+n: U32) -> U32:
  +up = Bool.pick(U32, F.Fixed.is_neg(n), (n + ((((0 - n) + 11) / 12) * 12) : U32), n)
  Bool.pick(U32, F.Fixed.gt(up, 95), (up - ((((up - 95) + 11) / 12) * 12) : U32), up)

# FrequencyForVoice.
def Player.frequency(+t: Player.Tabs, +bend: U32, +voice: Player.Voice) -> U32:
  Tabs{gm, +curve, vmt} = t
  Voice{+instr, +iv, chan, key, +note, freq, vol, car, mod} = voice
  +at = Player.gm_voice(instr, iv)
  +offset = B.Bytes.le16(Player.byte(t, (at + 14 : U32)), Player.byte(t, (at + 15 : U32)))
  +signed = Bool.pick(U32, U32.is_ge(offset, 32768), (offset - 65536 : U32), offset)
  +n = Player.octaves(Bool.pick(U32, Player.fixed(t, instr), note, (note + signed : U32)))
  +fine = Bool.pick(U32, U32.is_eq(iv, 0), 0,
    ((Player.byte(t, (Player.instr(instr) + 2 : U32)) / 2) - 64 : U32))
  +raw = (64 + (32 * n) + bend + fine : U32)
  +idx = Bool.pick(U32, F.Fixed.is_neg(raw), 0, raw)
  Bool.pick(U32, U32.is_lt(idx, 284), V.Vec.get(curve, idx),
    (V.Vec.get(curve, (((idx - 284) % 384) + 284 : U32)) .|. (U32.min(((idx - 284) / 384 : U32), 7) << 10n)
      : U32))

def Player.tune.go(same: Bool, +v: U32, +f: U32, voice: Player.Voice, ws: List<&2, O.Opl.Write>) ->
  Player.Voiced:
  match same:
    case True{}:
      Voiced{voice, ws}
    case False{}:
      Voice{instr, iv, chan, key, note, freq, vol, car, mod} = voice
      Voiced{Voice{instr, iv, chan, key, note, f, vol, car, mod},
        O.Write{(176 + v : U32), ((f >> 8n) .|. 32 : U32)} <> O.Write{(160 + v : U32), (f .&. 255 : U32)} <>
          ws}

def Player.tune.at(+v: U32, +f: U32, +voice: Player.Voice, ws: List<&2, O.Opl.Write>) -> Player.Voiced:
  Player.tune.go(U32.is_eq(f, Player.Voice.freq(voice)), v, f, voice, ws)

# UpdateVoiceFrequency: the frequency word, with the key on, if it changed.
def Player.tune(+t: Player.Tabs, +v: U32, +bend: U32, vw: Player.Voiced) -> Player.Voiced:
  Voiced{+voice, ws} = vw
  Player.tune.at(v, Player.frequency(t, bend, voice), voice, ws)

# Voice v and the player's writes, from a programming step.
def Player.put(p: Player, +v: U32, vw: Player.Voiced) -> Player:
  Player{chans, voices, free, alloced, writes} = p
  Voiced{voice, ws} = vw
  Player{chans, List.set(&2, Player.Voice, voices, U32.to_nat(v), voice), free, alloced, ws}

def Player.without(vs: List<&2, U32>, +v: U32) -> List<&2, U32>:
  match vs:
    case []:
      []
    case +x <> rest:
      List.filter.put(U32, x, Player.without(rest, v), U32.is_ne(x, v))

def Player.released(+v: U32, voice: Player.Voice, p: Player) -> Player:
  Voice{instr, iv, chan, key, note, +freq, vol, car, mod} = voice
  Player{chans, voices, free, alloced, writes} = p
  Player{chans,
    List.set(&2, Player.Voice, voices, U32.to_nat(v), Voice{instr, iv, None{}, key, 0, freq, vol, car, mod}),
    List.append(&2, U32, free, [v]), Player.without(alloced, v),
    O.Write{(176 + v : U32), (freq >> 8n : U32)} <> writes}

# ReleaseVoice: voice v keyed off, off its channel, and moved from the
# allocated list to the end of the free list.
def Player.release(+v: U32, +p: Player) -> Player:
  Player.released(v, Player.voice(p, v), p)

# VoiceKeyOn on voice v, the free list's first.
def Player.voice_on(+t: Player.Tabs, +ch: U32, +i: U32, +iv: U32, +key: U32, +note: U32, +velocity: U32,
  +v: U32, +c: Player.Chan, p: Player, voice: Player.Voice) -> Player:
  Player{chans, voices, free, alloced, writes} = p
  Voice{loaded_instr, loaded_iv, chan, old_key, old_note, freq, vol, car, mod} = voice
  Player.put(Player{chans, voices, List.drop(&2, U32, free, 1n), List.append(&2, U32, alloced, [v]), []}, v,
    Player.tune(t, v, Player.Chan.bend(c), Player.level(t, v, Player.Chan.volume(c), velocity,
      Player.instrument(t, v, i, iv, Voice{loaded_instr, loaded_iv, Some{ch}, key,
        Bool.pick(U32, Player.fixed(t, i), Player.byte(t, (Player.instr(i) + 3 : U32)), note), 0, vol, car,
        mod}, writes))))

def Player.voice_on.pick(some: Maybe<&2, U32>, +t: Player.Tabs, +ch: U32, +i: U32, +iv: U32, +key: U32,
  +note: U32, +velocity: U32, +p: Player) -> Player:
  match some:
    case None{}:
      p
    case Some{+v}:
      Player.voice_on(t, ch, i, iv, key, note, velocity, v, Player.chan(p, ch), p, Player.voice(p, v))

# With no free voice, no note.
def Player.voice_key_on(+t: Player.Tabs, +ch: U32, +i: U32, +iv: U32, +key: U32, +note: U32, +velocity: U32,
  +p: Player) -> Player:
  Player.voice_on.pick(List.head(&2, U32, Player.free(p)), t, ch, i, iv, key, note, velocity, p)

# ReplaceExistingVoice's choice among vs: the last that plays an
# instrument's second voice or sits on a channel at least as high as the
# choice before it.
def Player.victim(vs: List<&2, U32>, +p: Player, +best: U32, +rank: U32) -> U32:
  match vs:
    case []:
      best
    case +v <> rest:
      +voice = Player.voice(p, v)
      +take = U32.is_ne(Player.Voice.iv(voice), 0) || U32.is_ge(Player.Voice.rank(voice), rank)
      Player.victim(rest, p, Bool.pick(U32, take, v, best),
        Bool.pick(U32, take, Player.Voice.rank(voice), rank))

# The Doom 1.9 driver frees a voice for a note when none is free.
def Player.room(full: Bool, +p: Player) -> Player:
  match full:
    case True{}:
      Player.release(Player.victim(Player.alloced(p), p, 0, 0), p)
    case False{}:
      p

def Player.key_on.second(double: Bool, +t: Player.Tabs, +ch: U32, +i: U32, +key: U32, +note: U32,
  +velocity: U32, first: Player) -> Player:
  match double:
    case True{}:
      Player.voice_key_on(t, ch, i, 1, key, note, velocity, first)
    case False{}:
      first

def Player.key_on.go(skip: Bool, +t: Player.Tabs, +ch: U32, +i: U32, +key: U32, +note: U32, +velocity: U32,
  +p: Player) -> Player:
  match skip:
    case True{}:
      p
    case False{}:
      Player.key_on.second(U32.is_eq((Player.flags(t, i) .&. 4 : U32), 4), t, ch, i, key, note, velocity,
        Player.voice_key_on(t, ch, i, 0, key, note, velocity,
          Player.room(List.is_empty(&2, U32, Player.free(p)), p)))

# KeyOnEvent for the Doom 1.9 driver: a double-voice instrument's second
# voice after its first. MIDI's percussion channel 9 plays GENMIDI's
# instrument 128 + key - 35 at note 60.
def Player.key_on(+t: Player.Tabs, +raw: U32, +ch: U32, +key: U32, +velocity: U32, +p: Player) -> Player:
  +perc = U32.is_eq(raw, 9)
  Player.key_on.go(perc && (U32.is_lt(key, 35) || U32.is_gt(key, 81)), t, ch,
    Bool.pick(U32, perc, (key + 93 : U32), Player.Chan.instr(Player.chan(p, ch))), key,
    Bool.pick(U32, perc, 60, key), velocity, p)

def Player.key_off.one(hit: Bool, +v: U32, +p: Player) -> Player:
  match hit:
    case True{}:
      Player.release(v, p)
    case False{}:
      p

def Player.key_off.go(vs: List<&2, U32>, +ch: U32, +key: U32, +all: Bool, +p: Player) -> Player:
  match vs:
    case []:
      p
    case +v <> rest:
      +voice = Player.voice(p, v)
      Player.key_off.go(rest, ch, key, all, Player.key_off.one(
        Player.Voice.on(voice, ch) && (all || U32.is_eq(Player.Voice.key(voice), key)), v, p))

# KeyOffEvent, or AllNotesOff when all: the allocated voices on channel
# ch playing key, or all of them, released in allocated order.
def Player.key_off(+ch: U32, +key: U32, +all: Bool, +p: Player) -> Player:
  Player.key_off.go(Player.alloced(p), ch, key, all, p)

def Player.stop.go(n: Nat, +ch: U32, +p: Player) -> Player:
  match n:
    case 0n:
      p
    case 1n+m:
      Player.stop.go(m, (ch + 1 : U32), Player.key_off(ch, 0, True{}, p))

# I_OPL_StopSong's AllNotesOff on each of the sixteen channels in turn.
def Player.stop(+p: Player) -> Player:
  Player.stop.go(16n, 0, p)

# Channels
# --------

def Player.set_chan(p: Player, +ch: U32, c: Player.Chan) -> Player:
  Player{chans, voices, free, alloced, writes} = p
  Player{List.set(&2, Player.Chan, chans, U32.to_nat(ch), c), voices, free, alloced, writes}

def Player.relevel.one(on: Bool, +t: Player.Tabs, +chvol: U32, +v: U32, +p: Player, +voice: Player.Voice) ->
  Player:
  match on:
    case True{}:
      Player.put(p, v, Player.level(t, v, chvol, Player.Voice.vol(voice), Voiced{voice, Player.writes(p)}))
    case False{}:
      p

# SetVoiceVolume on each voice of channel ch, in voice order.
def Player.relevel(n: Nat, +t: Player.Tabs, +ch: U32, +chvol: U32, +v: U32, +p: Player) -> Player:
  match n:
    case 0n:
      p
    case 1n+m:
      +voice = Player.voice(p, v)
      Player.relevel(m, t, ch, chvol, (v + 1 : U32),
        Player.relevel.one(Player.Voice.on(voice, ch), t, chvol, v, p, voice))

# SetChannelVolume from a controller: capped by the music volume, both
# the current one and the song's starting one.
def Player.chan_volume.set(+t: Player.Tabs, +ch: U32, +val: U32, p: Player, c: Player.Chan) -> Player:
  Chan{instr, volume, bend} = c
  +vol = U32.min(val, Player.volume())
  Player.relevel(9n, t, ch, vol, 0, Player.set_chan(p, ch, Chan{instr, vol, bend}))

def Player.chan_volume(+t: Player.Tabs, +ch: U32, +val: U32, +p: Player) -> Player:
  Player.chan_volume.set(t, ch, val, p, Player.chan(p, ch))

def Player.program_change.set(+ch: U32, i: U32, p: Player, c: Player.Chan) -> Player:
  Chan{instr, volume, bend} = c
  Player.set_chan(p, ch, Chan{i, volume, bend})

def Player.program_change(+ch: U32, i: U32, +p: Player) -> Player:
  Player.program_change.set(ch, i, p, Player.chan(p, ch))

def Player.retune.one(on: Bool, +t: Player.Tabs, +bend: U32, +v: U32, +p: Player, +voice: Player.Voice) ->
  Player:
  match on:
    case True{}:
      Player.put(p, v, Player.tune(t, v, bend, Voiced{voice, Player.writes(p)}))
    case False{}:
      p

def Player.retune(vs: List<&2, U32>, +t: Player.Tabs, +ch: U32, +bend: U32, +p: Player) -> Player:
  match vs:
    case []:
      p
    case +v <> rest:
      +voice = Player.voice(p, v)
      Player.retune(rest, t, ch, bend, Player.retune.one(Player.Voice.on(voice, ch), t, bend, v, p, voice))

# The voices of vs on channel ch, or those on others.
def Player.split(vs: List<&2, U32>, +p: Player, +ch: U32, +on: Bool) -> List<&2, U32>:
  match vs:
    case []:
      []
    case +v <> rest:
      List.filter.put(U32, v, Player.split(rest, p, ch, on),
        Bool.not(Bool.xor(Player.Voice.on(Player.voice(p, v), ch), on)))

def Player.pitch_bend.order(+ch: U32, +p: Player) -> Player:
  Player{chans, voices, free, +alloced, writes} = p
  Player{chans, voices, free,
    List.append(&2, U32, Player.split(alloced, p, ch, False{}), Player.split(alloced, p, ch, True{})), writes}

def Player.pitch_bend.set(+ch: U32, +b: U32, +t: Player.Tabs, +p: Player, c: Player.Chan) -> Player:
  Chan{instr, volume, bend} = c
  Player.pitch_bend.order(ch, Player.retune(Player.alloced(p), t, ch, b,
    Player.set_chan(p, ch, Chan{instr, volume, b})))

# PitchBendEvent: the bend's high byte less 64, the channel's voices
# retuned and moved behind the others in the allocated list.
def Player.pitch_bend(+t: Player.Tabs, +ch: U32, +val: U32, +p: Player) -> Player:
  Player.pitch_bend.set(ch, (val - 64 : U32), t, p, Player.chan(p, ch))

# What ProcessEvent does with a channel event. Pan moves nothing in OPL2
# mode, and the other controllers and both aftertouches nothing at all.
type Player.Act is Data:
  KeyOn{}
  KeyOff{}
  Volume{}
  AllOff{}
  Program{}
  Bend{}
  Nothing{}

def Player.act(+kind: U32, +p1: U32, +p2: U32) -> Player.Act:
  +on = U32.is_eq(kind, 144)
  Bool.pick(Player.Act, on && U32.is_ne(p2, 0), KeyOn{},
    Bool.pick(Player.Act, on || U32.is_eq(kind, 128), KeyOff{},
      Bool.pick(Player.Act, U32.is_eq(kind, 176) && U32.is_eq(p1, 7), Volume{},
        Bool.pick(Player.Act, U32.is_eq(kind, 176) && U32.is_eq(p1, 123), AllOff{},
          Bool.pick(Player.Act, U32.is_eq(kind, 192), Program{},
            Bool.pick(Player.Act, U32.is_eq(kind, 224), Bend{}, Nothing{}))))))

def Player.event.go(a: Player.Act, +t: Player.Tabs, +raw: U32, +ch: U32, +p1: U32, +p2: U32, +p: Player) ->
  Player:
  match a:
    case KeyOn{}:
      Player.key_on(t, raw, ch, p1, p2, p)
    case KeyOff{}:
      Player.key_off(ch, p1, False{}, p)
    case Volume{}:
      Player.chan_volume(t, ch, p2, p)
    case AllOff{}:
      Player.key_off(ch, p1, True{}, p)
    case Program{}:
      Player.program_change(ch, p1, p)
    case Bend{}:
      Player.pitch_bend(t, ch, p2, p)
    case Nothing{}:
      p

# A channel event of MIDI channel raw, whose DMX channel swaps 9 and 15.
def Player.event(+t: Player.Tabs, +kind: U32, +raw: U32, +p1: U32, +p2: U32, +p: Player) -> Player:
  Player.event.go(Player.act(kind, p1, p2), t, raw,
    Bool.pick(U32, U32.is_eq(raw, 9), 15, Bool.pick(U32, U32.is_eq(raw, 15), 9, raw)), p1, p2, p)

# The writes made, oldest first, and the player without them.
def Player.taken(p: Player) -> List<&2, O.Opl.Write>:
  Player{chans, voices, free, alloced, writes} = p
  List.reverse(&2, O.Opl.Write, writes)

def Player.clear(p: Player) -> Player:
  Player{chans, voices, free, alloced, writes} = p
  Player{chans, voices, free, alloced, []}
