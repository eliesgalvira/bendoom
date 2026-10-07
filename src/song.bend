# A WAD's songs as Chocolate Doom plays them, looping, a buffer at a
# time as the mixer asks. Its SDL driver (opl/opl_sdl.c) fills
# 4096-frame buffers, each cut at every callback due in it: a cut is the
# whole frames that reach the callback's time, and time advances by the
# cut's microseconds, rounded down. The callbacks wait in opl_queue.c's
# heap and read the song's tracks (i_oplmusic.c). The song's time counts
# microseconds from its last start, where the heap is empty, so a song
# that loops for hours never wraps it.
import Base
import ./fixed.bend as F
import ./opl.bend as O
import ./midi.bend as M
import ./player.bend as P

# A callback due at a time: a track's next event (TrackTimerCallback),
# or with no track the restart 5 ms after the last track ends
# (RestartSong), where a pass ends.
type Song.Entry is Data:
  Entry{time: U32, track: Maybe<&2, U32>}

# The chip with the frames made and not yet taken, the player, the
# tracks, the callback heap as opl_queue.c's array, now (current_time),
# the frames made, the tracks still running, and the tempo in
# microseconds a beat.
type Song is Data:
  Song{sound: O.Opl.Frames, player: P.Player, tracks: List<&2, M.Midi.Track>,
    heap: List<&2, Song.Entry>, now: U32, made: U32, running: U32, tempo: U32}

# The chip's tables, the player's, and the song as its lump holds it.
type Song.Env is Data:
  Env{roms: O.Opl.Roms, tabs: P.Player.Tabs, file: M.Midi.File}

def Song.made(+m: Song) -> U32:
  Song{sound, player, tracks, heap, now, made, running, tempo} = m
  made

# The frames made and not yet taken, latest first.
def Song.out(+m: Song) -> List<&2, U32>:
  Song{sound, player, tracks, heap, now, made, running, tempo} = m
  O.Opl.Frames.out(sound)

# The frames of one of opl_sdl.c's buffers: GetSliceSize's largest power
# of two not over 100 ms.
def Song.buffer() -> U32:
  4096

# Those 100 ms in microseconds: a wait toward a callback stops there, so
# what follows is a cut of the buffer's rest.
def Song.slice() -> U32:
  100000

# A time now never reaches: past the heap's end an entry is never due.
def Song.never() -> U32:
  4294967295

# The callback heap
# -----------------

def Song.time(+e: Song.Entry) -> U32:
  Entry{time, track} = e
  time

# The entry at i; past the heap's end, one never due.
def Song.at(+q: List<&2, Song.Entry>, +i: U32) -> Song.Entry:
  Maybe.default(&2, Song.Entry, List.get(&2, Song.Entry, q, U32.to_nat(i)), Entry{Song.never(), None{}})

def Song.put(q: List<&2, Song.Entry>, +i: U32, e: Song.Entry) -> List<&2, Song.Entry>:
  List.set(&2, Song.Entry, q, U32.to_nat(i), e)

def Song.size(+q: List<&2, Song.Entry>) -> U32:
  U32.from_nat(List.length(&2, Song.Entry, q))

def Song.settled(+q: List<&2, Song.Entry>, +id: U32, +e: Song.Entry) -> Bool:
  U32.is_eq(id, 0) || U32.is_ge(Song.time(e), Song.time(Song.at(q, ((id - 1) / 2 : U32))))

def Song.up(n: Nat, stop: Bool, +q: List<&2, Song.Entry>, +id: U32, +e: Song.Entry) ->
  List<&2, Song.Entry>:
  match n stop:
    case _ True{}:
      Song.put(q, id, e)
    case 0n False{}:
      Song.put(q, id, e)
    case 1n+m False{}:
      +parent = ((id - 1) / 2 : U32)
      +q2 = Song.put(q, id, Song.at(q, parent))
      Song.up(m, Song.settled(q2, parent, e), q2, parent, e)

# OPL_Queue_Push.
def Song.push(+q: List<&2, Song.Entry>, +e: Song.Entry) -> List<&2, Song.Entry>:
  +q2 = List.append(&2, Song.Entry, q, [e])
  Song.up(8n, Song.settled(q2, Song.size(q), e), q2, Song.size(q), e)

# Where OPL_Queue_Pop's percolation takes the last entry from i: the
# lesser child earlier than it, if any.
def Song.child(+q: List<&2, Song.Entry>, +n: U32, +i: U32, +last: Song.Entry) -> Maybe<&2, U32>:
  +c1 = ((i * 2) + 1 : U32)
  +c2 = ((i * 2) + 2 : U32)
  +t1 = Song.time(Song.at(q, c1))
  +t2 = Song.time(Song.at(q, c2))
  Bool.pick(Maybe<&2, U32>, U32.is_lt(c1, n) && U32.is_lt(t1, Song.time(last)),
    Some{Bool.pick(U32, U32.is_lt(c2, n) && U32.is_lt(t2, t1), c2, c1)},
    Bool.pick(Maybe<&2, U32>, U32.is_lt(c2, n) && U32.is_lt(t2, Song.time(last)), Some{c2}, None{}))

def Song.down(f: Nat, next: Maybe<&2, U32>, +q: List<&2, Song.Entry>, +i: U32, +last: Song.Entry,
  +n: U32) -> List<&2, Song.Entry>:
  match f next:
    case _ None{}:
      Song.put(q, i, last)
    case 0n Some{c}:
      Song.put(q, i, last)
    case 1n+m Some{+c}:
      +q2 = Song.put(q, i, Song.at(q, c))
      Song.down(m, Song.child(q2, n, c, last), q2, c, last, n)

# OPL_Queue_Pop, less the entry it hands out.
def Song.pop(+q: List<&2, Song.Entry>) -> List<&2, Song.Entry>:
  +n = (Song.size(q) - 1 : U32)
  +last = Song.at(q, n)
  +q2 = List.take(&2, Song.Entry, q, U32.to_nat(n))
  Song.down(8n, Song.child(q2, n, 0, last), q2, 0, last, n)

# OPL_Queue_AdjustCallbacks for one time: its offset from now, an int64
# made a float, over the factor, truncated toward zero (cvttss2si, which
# gcc emits for the cast to uint64_t below 2^63) and added back. An
# offset below zero, a callback overdue as the tempo changes, stays
# overdue.
def Song.rescale(+now: U32, +factor: F32, +time: U32) -> U32:
  +off = (time - now : U32)
  +neg = F.Fixed.is_neg(off)
  +q = F32.to_u32((U32.to_f32(Bool.pick(U32, neg, (0 - off : U32), off)) / factor : F32))
  (now + Bool.pick(U32, neg, (0 - q : U32), q) : U32)

def Song.adjust(q: List<&2, Song.Entry>, +now: U32, +factor: F32) -> List<&2, Song.Entry>:
  match q:
    case []:
      []
    case Entry{+time, track} <> rest:
      Entry{Song.rescale(now, factor, time), track} <> Song.adjust(rest, now, factor)

# Callbacks
# ---------

# ScheduleTrack: the track's next event after its delta in ticks, turned
# to microseconds at the tempo.
def Song.schedule(+env: Song.Env, +k: U32, t: M.Midi.Track, m: Song) -> Song:
  Env{roms, tabs, file} = env
  M.File{+division, tracks} = file
  Song{sound, player, tracks, heap, +now, made, running, +tempo} = m
  +delta = M.Midi.delta(t)
  Song{sound, player, tracks, Song.push(heap, Entry{(now + (delta * (tempo / division)) +
    (((delta * (tempo % division)) / division)) : U32), Some{k}}), now, made, running, tempo}

# A channel event: the player's writes go to the chip's buffer.
def Song.event(+env: Song.Env, +kind: U32, +raw: U32, +p1: U32, +p2: U32, m: Song) -> Song:
  Env{roms, +tabs, file} = env
  Song{sound, player, tracks, heap, now, made, running, tempo} = m
  +p = P.Player.event(tabs, kind, raw, p1, p2, player)
  Song{O.Opl.Frames.queue(P.Player.taken(p), sound), P.Player.clear(p), tracks, heap, now, made, running, tempo}

# MetaSetTempo: the heap rescaled by the old tempo over the new, in
# single precision.
def Song.retempo(+new: U32, m: Song) -> Song:
  Song{sound, player, tracks, heap, +now, made, running, tempo} = m
  Song{sound, player, tracks, Song.adjust(heap, now, (U32.to_f32(tempo) / U32.to_f32(new) : F32)), now,
    made, running, new}

def Song.last(done: Bool, +now: U32, heap: List<&2, Song.Entry>) -> List<&2, Song.Entry>:
  match done:
    case True{}:
      Song.push(heap, Entry{(now + 5000 : U32), None{}})
    case False{}:
      heap

# A track's end: it is not scheduled again, and the last track's end
# schedules the restart.
def Song.ended(m: Song) -> Song:
  Song{sound, player, tracks, heap, +now, made, +running, tempo} = m
  Song{sound, player, tracks, Song.last(U32.is_eq(running, 1), now, heap), now, made, (running - 1 : U32),
    tempo}

def Song.handle(e: M.Midi.Event, +env: Song.Env, +k: U32, t: M.Midi.Track, m: Song) -> Song:
  match e:
    case M.Chan{kind, raw, p1, p2}:
      Song.schedule(env, k, t, Song.event(env, kind, raw, p1, p2, m))
    case M.Tempo{us}:
      Song.schedule(env, k, t, Song.retempo(us, m))
    case M.End{}:
      Song.ended(m)
    case M.Other{}:
      Song.schedule(env, k, t, m)

def Song.got(+env: Song.Env, +k: U32, m: Song, g: M.Midi.Got) -> Song:
  Song{sound, player, tracks, heap, now, made, running, tempo} = m
  M.Got{event, +t} = g
  Song.handle(event, env, k, t,
    Song{sound, player, List.set(&2, M.Midi.Track, tracks, U32.to_nat(k), t), heap, now, made, running, tempo})

# TrackTimerCallback for track k, the heap's first entry.
def Song.callback(+env: Song.Env, +k: U32, m: Song) -> Song:
  Song{sound, player, +tracks, +heap, now, made, running, tempo} = m
  Song.got(env, k, Song{sound, player, tracks, Song.pop(heap), now, made, running, tempo},
    M.Midi.next(Maybe.default(&2, M.Midi.Track, List.get(&2, M.Midi.Track, tracks, U32.to_nat(k)),
      M.Track{[], 0})))

# Starting
# --------

def Song.begin.go(+env: Song.Env, ts: List<&2, M.Midi.Track>, +k: U32, m: Song) -> Song:
  match ts:
    case []:
      m
    case t <> rest:
      Song.begin.go(env, rest, (k + 1 : U32), Song.schedule(env, k, t, m))

# Every track from its start, scheduled at now, which starts the song's
# time again, all running, and every channel set up. I_OPL_PlaySong and
# RestartSong both do this; neither touches the voices or the chip.
def Song.begin(+env: Song.Env, m: Song) -> Song:
  Env{roms, tabs, file} = env
  M.File{division, +tracks} = file
  Song{sound, player, old, heap, now, made, running, tempo} = m
  Song.begin.go(env, tracks, 0, Song{sound, P.Player.restart(player), tracks, heap, 0, made,
    U32.from_nat(List.length(&2, M.Midi.Track, tracks)), tempo})

# RestartSong, where the restart is due: the song starts again at now,
# overshoot included, at the tempo it ended with (only I_OPL_PlaySong
# sets the default).
def Song.restart(+env: Song.Env, m: Song) -> Song:
  Song{sound, player, tracks, +heap, now, made, running, tempo} = m
  Song.begin(env, Song{sound, player, tracks, Song.pop(heap), now, made, running, tempo})

# The heap's first callback: TrackTimerCallback for its track, or with
# none RestartSong.
def Song.call(track: Maybe<&2, U32>, +env: Song.Env, m: Song) -> Song:
  match track:
    case None{}:
      Song.restart(env, m)
    case Some{+k}:
      Song.callback(env, k, m)

# Turning
# -------

# One cut of OPL_Mix_Callback's loop: frames up to the next callback's
# time, d microseconds away, or the buffer's end.
def Song.cut(+env: Song.Env, +d: U32, m: Song) -> Song:
  Env{+roms, tabs, file} = env
  Song{sound, player, tracks, heap, +now, +made, running, tempo} = m
  +n = U32.min((((d * 441) + 9999) / 10000 : U32), (Song.buffer() - (made % Song.buffer()) : U32))
  Song{O.Opl.frames(U32.to_nat(n), roms, sound), player, tracks, heap, (now + ((n * 10000) / 441) : U32),
    (made + n : U32), running, tempo}

# What OPL_Mix_Callback does next: a cut toward the heap's first
# callback, or the callback if due. Past 100 ms a cut is the buffer's
# rest, so the wait stops there. Full is where the frames asked for are
# made, and the turn hands them over.
type Song.Step is Data:
  Cut{d: U32}
  Call{track: Maybe<&2, U32>}
  Full{}

# With no callback waiting, the wait is a slice at a time.
def Song.step.at(+now: U32, full: Bool, e: Maybe<&2, Song.Entry>) -> Song.Step:
  match full e:
    case True{} _:
      Full{}
    case False{} None{}:
      Cut{Song.slice()}
    case False{} Some{Entry{+time, track}}:
      Bool.pick(Song.Step, U32.is_ge(now, time), Call{track}, Cut{U32.min((time - now : U32), Song.slice())})

def Song.step(+upto: U32, +m: Song) -> Song.Step:
  Song{sound, player, tracks, heap, +now, +made, running, tempo} = m
  Song.step.at(now, U32.is_ge(made, upto), List.get(&2, Song.Entry, heap, 0n))

def Song.turn.go(n: Nat, s: Song.Step, +upto: U32, +env: Song.Env, m: Song) -> Song:
  match n s:
    case _ Full{}:
      m
    case 0n _:
      m
    case 1n+f Call{track}:
      +m2 = Song.call(track, env, m)
      Song.turn.go(f, Song.step(upto, m2), upto, env, m2)
    case 1n+f Cut{+d}:
      +m2 = Song.cut(env, d, m)
      Song.turn.go(f, Song.step(upto, m2), upto, env, m2)

# OPL_Mix_Callback until the song has made upto frames: each turn is the
# callback due or a cut toward the next. A cut makes a frame at least
# and a callback reads an event, so a turn for every frame asked and
# every event a lump holds outlasts any song Chocolate Doom plays; a
# song that wants more hands over the frames it made.
def Song.turn(+upto: U32, +env: Song.Env, +m: Song) -> Song:
  Song.turn.go(U32.to_nat(((upto - Song.made(m)) + M.Midi.most() : U32)), Song.step(upto, m), upto, env, m)

def Song.took(+want: U32, m: Song) -> List<&2, U32> & Song:
  Song{sound, player, tracks, heap, now, made, running, tempo} = m
  O.Frames{opl, out} = sound
  +oldest = List.reverse(&2, U32, out)
  (List.take(&2, U32, oldest, U32.to_nat(want)), Song{O.Frames{opl, List.reverse(&2, U32,
    List.drop(&2, U32, oldest, U32.to_nat(want)))}, player, tracks, heap, now, made, running, tempo})

# The song's next want frames, oldest first, and the song after them:
# what the turn's last cut made past them waits for the next take.
def Song.take(+want: U32, +env: Song.Env, +m: Song) -> List<&2, U32> & Song:
  Song.took(want, Song.turn(((Song.made(m) - U32.from_nat(List.length(&2, U32, Song.out(m)))) + want : U32),
    env, m))

# Changing
# --------

# A song of no tracks: what plays before the first, and in place of a
# lump Chocolate Doom refuses.
def Song.none() -> M.Midi.File:
  M.File{0, []}

def Song.registered.of(fault: Maybe<&2, String>, file: M.Midi.File) -> M.Midi.File:
  match fault:
    case None{}:
      file
    case Some{why}:
      Song.none()

# I_OPL_RegisterSong: the lump as the player reads it, or no song if
# Chocolate Doom would not play it.
def Song.registered(+file: M.Midi.File) -> M.Midi.File:
  Song.registered.of(M.Midi.fault.file(file), file)

# The chip as Chocolate Doom's sound starts it, playing no song: reset,
# with its first buffer mixed before a level's song starts, as a capture
# has it, and OPL_InitRegisters' writes waiting in its buffer after.
def Song.silence(+roms: O.Opl.Roms) -> Song:
  Song{O.Opl.Frames.queue(P.Player.setup(), O.Opl.frames(U32.to_nat(Song.buffer()), roms,
    O.Frames{O.Opl.reset(), []})), P.Player.start(), [], [], 0, Song.buffer(), 0, 500000}

# I_OPL_StopSong: the callbacks cleared and every voice freed, its
# key-off waiting in the chip's buffer.
def Song.stop(m: Song) -> Song:
  Song{sound, player, tracks, heap, now, made, running, tempo} = m
  +p = P.Player.stop(player)
  Song{O.Opl.Frames.queue(P.Player.taken(p), sound), P.Player.clear(p), tracks, [], now, made, running, tempo}

# I_OPL_PlaySong: the song from its start at the default tempo.
def Song.play(+env: Song.Env, m: Song) -> Song:
  Song{sound, player, tracks, heap, now, made, running, tempo} = m
  Song.begin(env, Song{sound, player, tracks, heap, now, made, running, 500000})

# S_ChangeMusic as Chocolate Doom's mixer meets it: the buffer being
# mixed ends with the old song, and the new one starts on the next
# buffer's first frame.
def Song.change(+old: Song.Env, +new: Song.Env, +m: Song) -> Song:
  Song.play(new, Song.stop(Song.turn(((((Song.made(m) + Song.buffer()) - 1) / Song.buffer()) * Song.buffer() : U32),
    old, m)))

# The deck
# --------

# A song lump by name, as the player reads it.
type Song.Lump is Data:
  Lump{name: String, file: M.Midi.File}

# The music as the mixer plays it: the songs a scene can name, read once
# from the opened WAD, the name of the one playing and its tables, and
# the song.
type Song.Deck is Data:
  Deck{songs: List<&2, Song.Lump>, name: String, env: Song.Env, song: Song}

def Song.find.pick(hit: Bool, file: M.Midi.File, rest: M.Midi.File) -> M.Midi.File:
  match hit:
    case True{}:
      file
    case False{}:
      rest

# The song called name, or none.
def Song.find(songs: List<&2, Song.Lump>, +name: String) -> M.Midi.File:
  match songs:
    case []:
      Song.none()
    case Lump{n, file} <> rest:
      Song.find.pick(String.eq(n, name), file, Song.find(rest, name))

def Song.Env.with(env: Song.Env, file: M.Midi.File) -> Song.Env:
  Env{roms, tabs, old} = env
  Env{roms, tabs, file}

def Song.Deck.cue(same: Bool, +name: String, +songs: List<&2, Song.Lump>, playing: String, +env: Song.Env,
  song: Song) -> Song.Deck:
  match same:
    case True{}:
      Deck{songs, playing, env, song}
    case False{}:
      +new = Song.Env.with(env, Song.registered(Song.find(songs, name)))
      Deck{songs, name, new, Song.change(env, new, song)}

# S_ChangeMusic: a song other than the one playing starts, and the one
# playing plays on.
def Song.Deck.change(+name: String, d: Song.Deck) -> Song.Deck:
  Deck{songs, +playing, env, song} = d
  Song.Deck.cue(String.eq(name, playing), name, songs, playing, env, song)

def Song.Deck.took(songs: List<&2, Song.Lump>, name: String, env: Song.Env, p: List<&2, U32> & Song) ->
  Song.Deck & List<&2, U32>:
  (frames, song) = p
  (Deck{songs, name, env, song}, frames)

# The next want frames, oldest first, each a word with the left sample
# in its low half.
def Song.Deck.take(+want: U32, d: Song.Deck) -> Song.Deck & List<&2, U32>:
  Deck{songs, name, +env, song} = d
  Song.Deck.took(songs, name, env, Song.take(want, env, song))

def Song.lumps(names: List<&2, String>, songs: List<&2, List<&2, U32>>) -> List<&2, Song.Lump>:
  match names songs:
    case name <> ns bytes <> ss:
      Lump{name, M.Midi.file(bytes)} <> Song.lumps(ns, ss)
    case _ _:
      []

def Song.Deck.open(genmidi: List<&2, U32>, songs: List<&2, Song.Lump>) -> Song.Deck:
  +roms = O.Opl.roms()
  Deck{songs, "", Env{roms, P.Player.tabs(genmidi), Song.none()}, Song.silence(roms)}

# The named songs, from GENMIDI and their lumps in that order, playing
# none yet.
def Song.Deck.of(names: List<&2, String>, lumps: List<&2, List<&2, U32>>) -> Song.Deck:
  match lumps:
    case []:
      Song.Deck.open([], [])
    case genmidi <> songs:
      Song.Deck.open(genmidi, Song.lumps(names, songs))
