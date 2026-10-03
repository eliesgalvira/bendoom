# E1M1's song from the WAD, as the deck reads and plays it. First the
# song as the reader hands it to the player: its length in ticks (its
# longest track's) and its events by kind, as tools/wad.nu counts them
# from the lump:
#
#   nu -c 'source tools/wad.nu; open --raw $env.BENDOOM_IWAD | song-events | song-counts'
#
# Then Freedoom's song as the deck plays it from the sound's start, in
# uneven takes as the mixer asks, over its first 72000 frames: the
# chip's first buffer before the song, the song's two tempo changes at
# tick 0, which rescale every track's first callback, its first note at
# frame 4536 and its first voice steal, a note on channel 9 with all
# nine voices busy. Frame 67843 is the first the steal changes. It
# prints an FNV-1a hash of the frames (each a 32-bit word, left in the
# low half), and frames on either side of the first note and of the
# steal. The expected lines are Chocolate Doom's, read in nushell from a
# real-time capture (tools/listen.nu --keep) as the same words:
#
#   let c = open --raw music.raw | bytes at 0..<(72000 * 4) | chunks 4 | each { into int --endian little }
#   $c | reduce --fold 2166136261 {|x, h| (($h | bits xor $x) * 16777619) mod 4294967296 }
#   $c | get 67843 | [($in | bits and 65535) ($in | bits shr 16)] | each { if $in >= 32768 { $in - 65536 } else { $in } }
#
# Then S_ChangeMusic after the first 10000 frames, against the song
# playing on: the first frame of the next 10000 that differs. The same
# song again changes nothing, so none does and the line is 20000. A
# change to D_INTER waits for the buffer being mixed to end, so no frame
# before 12288 differs; which one first does is a regression pin.
#
# Then OPL_Queue_AdjustCallbacks on callbacks overdue as the tempo
# changes, worked by hand from C's conversions: 993 at now 1000 with the
# factor (float) 500000 / 480000 is 1000 + (int64) (-7 / 1.0416666f) =
# 994, and 90 at now 100 with the factor 0.75 is 100 + (int64) (-10 /
# 0.75f) = 87. Freedoom reaches that path only with the factor 1.
# Then lumps built by hand, each read as the reader hands the song over:
# its division, and its first track's events, each after its delta, as
# its kind, channel and two data bytes.
# First a MUS score as mus2mid.c converts it. Channel 3, used first, is
# MIDI channel 0 and gets an all-notes-off (controller 123) with the
# delta before its first event; percussion channel 15 is 9 and gets
# none. A key with its top bit set carries a velocity, masked to 7 bits,
# which later presses on the channel reuse, whatever other channels do.
# The pitch wheel's byte b is bend 64 * (b & 1), b >> 1; system event 14
# is controller 121; controller 0 is a program change and 3 is volume,
# 144 cut to 127. The nine channels used next take MIDI 1 to 8 and then
# 10. A set top bit on a descriptor ends its group, and the delay that
# follows, 5, 128 and 257 in two bytes each, and 3, falls on the next
# event, the end included. The division is mus2mid.c's 70.
# Then a SMPTE division, 0xE728, which means 25 frames a second of 40
# ticks, but MIDI_GetFileTimeDivision divides the whole short, -6360, by
# 256 toward zero: 24 * 40 ticks a beat.
# Then the lumps the deck refuses, True, in order, and near misses it
# takes, False: neither MUS nor MIDI. MIDI, after the smallest track it
# takes: a status byte of 0xF3; a data byte before any status; a delta
# of five bytes, but not of four; a track cut short; format 2; a track
# header other than MTrk. MUS, after the smallest score it takes:
# controller 10 in a controller change; event type 5; system event 9; a
# delay of 2^28 ticks; a delay of 2^28 - 1, which mus2mid.c writes but
# whose microseconds pass the 2^31 the deck counts, though a delay of
# 300000 ticks, 35.7 minutes at 140 a second, is taken; a score cut
# short; and a score of 49144 releases in a lump of 96 KiB, which
# i_oplmusic.c does not convert.
# Then the 1025th write queued on a reset chip, which finds
# OPL3_WriteRegBuffered's buffer full: the first, due at sample 2, is
# applied at once and the sample count moves to 2, while the new write
# is due at 2050, two after the 1024th; the line is the sample count,
# the last write's time and the writes pending.
# Last, callbacks due at the same time, each its time and track, do not
# pop in the order they were pushed: after the first, OPL_Queue_Pop moves
# the last entry to the top, so the third pushed runs before the second.
import Base
import ../src/fnv.bend as H
import ../src/midi.bend as M
import ../src/song.bend as S
import ../src/channel.bend as C
import ../src/stream.bend as A
import ../src/opl.bend as O
import ./fixtures/closed.bend as Fx

# Events by kind: the channel events by their status's high nibble from
# 0x80, then tempo, end and any other.
def Test.kinds() -> List<&2, String>:
  ["off", "on", "touch", "controller", "program", "pressure", "bend", "tempo", "end", "other"]

def Test.slot(e: M.Midi.Event) -> U32:
  match e:
    case M.Chan{kind, ch, p1, p2}:
      ((kind >> 4n) - 8 : U32)
    case M.Tempo{us}:
      7
    case M.End{}:
      8
    case M.Other{}:
      9

def Test.bump(+counts: List<&2, U32>, +i: U32) -> List<&2, U32>:
  List.set(&2, U32, counts, U32.to_nat(i),
    (Maybe.default(&2, U32, List.get(&2, U32, counts, U32.to_nat(i)), 0) + 1 : U32))

# A track's length in ticks and its events by kind.
type Test.Tally is Data:
  Tally{ticks: U32, counts: List<&2, U32>}

# The events from g on, the first d ticks after the track's last.
def Test.walk(n: Nat, g: M.Midi.Got, +d: U32, +ticks: U32, counts: List<&2, U32>) -> Test.Tally:
  match n g:
    case _ M.Got{M.End{}, rest}:
      Tally{(ticks + d : U32), Test.bump(counts, 8)}
    case 0n M.Got{e, rest}:
      Tally{ticks, counts}
    case 1n+m M.Got{+e, +rest}:
      Test.walk(m, M.Midi.next(rest), M.Midi.delta(rest), (ticks + d : U32), Test.bump(counts, Test.slot(e)))

def Test.add(xs: List<&2, U32>, ys: List<&2, U32>) -> List<&2, U32>:
  match xs ys:
    case [] _:
      ys
    case x <> xr Nil{}:
      x <> xr
    case x <> xr y <> yr:
      (x + y : U32) <> Test.add(xr, yr)

def Test.merge(a: Test.Tally, b: Test.Tally) -> Test.Tally:
  Tally{+ta, ca} = a
  Tally{+tb, cb} = b
  Tally{U32.max(ta, tb), Test.add(ca, cb)}

def Test.tracks(ts: List<&2, M.Midi.Track>) -> Test.Tally:
  match ts:
    case []:
      Tally{0, List.replicate(U32, 10n, 0)}
    case +t <> rest:
      Test.merge(Test.walk(U32.to_nat(M.Midi.most()), M.Midi.next(t), M.Midi.delta(t), 0, List.replicate(U32, 10n, 0)),
        Test.tracks(rest))

def Test.named(names: List<&2, String>, counts: List<&2, U32>) -> List<&2, String>:
  match names counts:
    case [] _:
      []
    case n <> nr Nil{}:
      []
    case n <> nr c <> cr:
      (n ++ " " ++ U32.show(c)) <> Test.named(nr, cr)

def Test.sum(xs: List<&2, U32>, +acc: U32) -> U32:
  match xs:
    case []:
      acc
    case x <> rest:
      Test.sum(rest, (acc + x : U32))

def Test.counts(t: Test.Tally) -> String:
  Tally{ticks, +counts} = t
  "song ticks " ++ U32.show(ticks) ++ " events " ++ U32.show(Test.sum(counts, 0)) ++ " "
    ++ String.join(Test.named(Test.kinds(), counts), " ")

def Test.song(f: M.Midi.File) -> String:
  M.File{division, tracks} = f
  Test.counts(Test.tracks(tracks))

def Test.signed(+x: U32) -> String:
  Bool.pick(String, U32.is_ge(x, 32768), "-" ++ U32.show((65536 - x : U32)), U32.show(x))

def Test.frame(+frames: List<&2, U32>, +i: U32) -> String:
  +lr = Maybe.default(&2, U32, List.get(&2, U32, frames, U32.to_nat(i)), 0)
  U32.show(i) ++ " " ++ Test.signed((lr .&. 65535 : U32)) ++ " " ++ Test.signed((lr >> 16n : U32))

# The deck's frames, latest first, and the deck after them.
type Test.Run is Data:
  Run{deck: S.Song.Deck, frames: List<&2, U32>}

def Test.got(frames: List<&2, U32>, p: S.Song.Deck & List<&2, U32>) -> Test.Run:
  (deck, taken) = p
  Run{deck, List.reverse.go(&2, U32, taken, frames)}

def Test.take(+n: U32, r: Test.Run) -> Test.Run:
  Run{deck, frames} = r
  Test.got(frames, S.Song.Deck.take(n, deck))

# A take of each size in turn.
def Test.run(sizes: List<&2, U32>, r: Test.Run) -> Test.Run:
  match sizes:
    case []:
      r
    case +n <> rest:
      Test.run(rest, Test.take(n, r))

# The frames a run took, in order.
def Test.taken(r: Test.Run) -> List<&2, U32>:
  Run{deck, frames} = r
  List.reverse(&2, U32, frames)

# The run from here on: its deck, with no frames yet.
def Test.on(r: Test.Run) -> Test.Run:
  Run{deck, frames} = r
  Run{deck, []}

def Test.cued(+name: String, r: Test.Run) -> Test.Run:
  Run{deck, frames} = r
  Run{S.Song.Deck.change(name, deck), []}

# 72000 frames in uneven takes, as the mixer asks for them.
def Test.sizes() -> List<&2, U32>:
  List.concat(&2, U32, [[1, 7, 100, 2048, 33, 999, 3072, 5], List.replicate(U32, 21n, 3072), [1223]])

def Test.differs.pick(same: Bool, +i: U32, rest: U32) -> U32:
  match same:
    case True{}:
      rest
    case False{}:
      i

# The first index at which two runs of frames differ, or their length.
def Test.differs(xs: List<&2, U32>, ys: List<&2, U32>, +i: U32) -> U32:
  match xs ys:
    case +x <> xr +y <> yr:
      Test.differs.pick(U32.is_eq(x, y), i, Test.differs(xr, yr, (i + 1 : U32)))
    case _ _:
      i

def Test.print(+playing: Test.Run, +songs: List<&2, S.Song.Lump>) -> IO(Unit):
  +frames = Test.taken(Test.run(Test.sizes(), playing))
  +later = Test.run([10000], playing)
  +on = Test.taken(Test.run([10000], Test.on(later)))
  do IO<Unit>:
    IO.print(Test.song(S.Song.find(songs, "D_E1M1")))
    IO.print("hash " ++ U32.show(H.Fnv.words(frames)))
    IO.print(Test.frame(frames, 4535))
    IO.print(Test.frame(frames, 4536))
    IO.print(Test.frame(frames, 67842))
    IO.print(Test.frame(frames, 67843))
    IO.print(Test.frame(frames, 70000))
    IO.print(Test.frame(frames, 71999))
    IO.print("again " ++ U32.show(Test.differs(Test.taken(Test.run([10000], Test.cued("D_E1M1", later))), on, 10000)))
    IO.print("inter " ++ U32.show(Test.differs(Test.taken(Test.run([10000], Test.cued("D_INTER", later))), on, 10000)))
    IO.print("rescale " ++ U32.show(S.Song.rescale(1000, (U32.to_f32(500000) / U32.to_f32(480000) : F32), 993))
      ++ " " ++ U32.show(S.Song.rescale(100, (U32.to_f32(3) / U32.to_f32(4) : F32), 90)))

def Test.played(+d: S.Song.Deck) -> IO(Unit):
  S.Deck{songs, name, env, song} = d
  Test.print(Run{d, []}, songs)

def Test.kind(+e: M.Midi.Event) -> String:
  Maybe.default(&2, String, List.get(&2, String, Test.kinds(), U32.to_nat(Test.slot(e))), "")

def Test.data(e: M.Midi.Event) -> String:
  match e:
    case M.Chan{kind, ch, p1, p2}:
      " " ++ U32.show(ch) ++ " " ++ U32.show(p1) ++ " " ++ U32.show(p2)
    case M.Tempo{us}:
      " " ++ U32.show(us)
    case _:
      ""

def Test.events(+tag: String, events: List<&2, Fx.Closed.At>) -> String:
  match events:
    case []:
      ""
    case Fx.At{delta, +e} <> rest:
      "\n" ++ tag ++ " " ++ U32.show(delta) ++ " " ++ Test.kind(e) ++ Test.data(e) ++ Test.events(tag, rest)

def Test.lump(+tag: String, song: U32 & List<&2, Fx.Closed.At>) -> String:
  (division, events) = song
  tag ++ " division " ++ U32.show(division) ++ Test.events(tag, events)

# n zeros before a tail, as a loop: List.replicate's recursion over a
# 96 KiB lump overflows bun's stack.
def Test.zeros(n: Nat, tail: List<&2, U32>) -> List<&2, U32>:
  match n:
    case 0n:
      tail
    case 1n+m:
      Test.zeros(m, 0 <> tail)

def Test.buffer(b: U32 & U32 & Nat) -> String:
  (count, last, pending) = b
  "buffer " ++ U32.show(count) ++ " " ++ U32.show(last) ++ " " ++ Nat.show(pending)

def Test.entry(e: S.Song.Entry) -> String:
  S.Entry{time, track} = e
  U32.show(time) ++ " " ++ Maybe.show(~&2, ~U32, ~U32.show, track)

def main() -> IO(Unit):
  do IO<Unit>:
    loaded : S.Song.Deck & List<&2, C.Channel.Sound> <- A.Stream.load(["D_E1M1", "D_INTER"], [])
    Test.played(S.Song.Deck.change("D_E1M1", Pair.fst(S.Song.Deck, List<&2, C.Channel.Sound>, loaded)))
    IO.print(Test.lump("mus", Fx.Closed.song(M.Midi.file(Fx.Closed.mus([147, 188, 100, 5, 19, 62, 31, 164, 133, 35, 129, 51, 14, 67, 0,
      133, 195, 3, 144, 129, 0, 0, 60, 1, 60, 2, 60, 4, 60, 5, 60, 6, 60, 7, 60, 8, 60, 137, 188, 130, 1, 147, 64, 3,
      96])))))
    IO.print(Test.lump("smpte", Fx.Closed.song(M.Midi.file(Fx.Closed.midi([0, 0, 0, 1, 231, 40], [0, 255, 47, 0])))))
    IO.print("faults " ++ List.show(~&2, ~Bool, ~Bool.show, [Fx.Closed.fails([1, 2, 3, 4, 5, 6, 7, 8]),
      Fx.Closed.fails(Fx.Closed.midi([0, 0, 0, 1, 0, 96], [0, 255, 47, 0])),
      Fx.Closed.fails(Fx.Closed.midi([0, 0, 0, 1, 0, 96], [0, 243, 0, 255, 47, 0])),
      Fx.Closed.fails(Fx.Closed.midi([0, 0, 0, 1, 0, 96], [0, 60, 100, 0, 255, 47, 0])),
      Fx.Closed.fails(Fx.Closed.midi([0, 0, 0, 1, 0, 96], [129, 128, 128, 128, 0, 255, 47, 0])),
      Fx.Closed.fails(Fx.Closed.midi([0, 0, 0, 1, 0, 96], [128, 128, 128, 0, 255, 47, 0])),
      Fx.Closed.fails(Fx.Closed.midi([0, 0, 0, 1, 0, 96], [0, 144, 60])),
      Fx.Closed.fails(Fx.Closed.midi([0, 2, 0, 1, 0, 96], [0, 255, 47, 0])),
      Fx.Closed.fails([77, 84, 104, 100, 0, 0, 0, 6, 0, 0, 0, 1, 0, 96, 77, 84, 114, 120, 0, 0, 0, 0, 0, 255, 47, 0]),
      Fx.Closed.fails(Fx.Closed.mus([96])),
      Fx.Closed.fails(Fx.Closed.mus([64, 10, 0, 96])),
      Fx.Closed.fails(Fx.Closed.mus([80, 96])),
      Fx.Closed.fails(Fx.Closed.mus([48, 9, 96])),
      Fx.Closed.fails(Fx.Closed.mus([128, 60, 129, 128, 128, 128, 0, 96])),
      Fx.Closed.fails(Fx.Closed.mus([128, 60, 255, 255, 255, 127, 96])),
      Fx.Closed.fails(Fx.Closed.mus([128, 60, 146, 167, 96, 96])),
      Fx.Closed.fails(Fx.Closed.mus([16])),
      Fx.Closed.fails(Fx.Closed.mus(Test.zeros(U32.to_nat(98288), [96])))]))
    IO.print(Test.buffer(Fx.Closed.buffer(O.Opl.queue(List.replicate(O.Opl.Write, U32.to_nat(1025), O.Write{1, 0}),
      O.Opl.reset()))))
    IO.print("heap " ++ List.show(~&2, ~S.Song.Entry, ~Test.entry, S.Song.pop(S.Song.push(S.Song.push(S.Song.push([],
      S.Entry{5, Some{0}}), S.Entry{5, Some{1}}), S.Entry{5, Some{2}}))))

#|song ticks 26114 events 12478 off 5483 on 5483 touch 0 controller 439 program 80 pressure 0 bend 955 tempo 3 end 18 other 17
#|hash 1145462143
#|4535 0 0
#|4536 29 0
#|67842 1862 1895
#|67843 1875 1881
#|70000 649 662
#|71999 1518 1335
#|again 20000
#|inter 12304
#|rescale 994 87
#|mus division 70
#|mus 0 controller 0 123 0
#|mus 0 on 0 60 100
#|mus 5 on 0 62 100
#|mus 0 on 9 36 5
#|mus 0 bend 0 64 64
#|mus 0 controller 0 121 0
#|mus 0 program 0 5 0
#|mus 0 controller 0 7 127
#|mus 128 controller 1 123 0
#|mus 0 off 1 60 0
#|mus 0 controller 2 123 0
#|mus 0 off 2 60 0
#|mus 0 controller 3 123 0
#|mus 0 off 3 60 0
#|mus 0 controller 4 123 0
#|mus 0 off 4 60 0
#|mus 0 controller 5 123 0
#|mus 0 off 5 60 0
#|mus 0 controller 6 123 0
#|mus 0 off 6 60 0
#|mus 0 controller 7 123 0
#|mus 0 off 7 60 0
#|mus 0 controller 8 123 0
#|mus 0 off 8 60 0
#|mus 0 controller 10 123 0
#|mus 0 off 10 60 0
#|mus 257 on 0 64 100
#|mus 3 end
#|smpte division 960
#|smpte 0 end
#|faults [True, False, True, True, True, False, True, True, True, False, True, True, True, True, True, False, True, True]
#|buffer 2 2050 1024
#|heap [5 Some(2), 5 Some(1)]
