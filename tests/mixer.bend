# The channels and the mixer, driven by hand-written events over
# Freedoom's expanded sounds and its song. No device is opened: the
# mixer's window is taken as the device would take it.
#
# First the channel table after each event of a scripted sequence, with
# the sound, the source and the left and right volumes of each of
# vanilla's eight channels. The expected tables are worked by hand from
# S_GetChannel and S_StopSound in s_sound.c, with the priorities of
# S_sfx: sounds 1 to 8 fill the table in order; the ninth (DSPLPAIN, 96)
# finds no free channel and kicks out the first whose sound is no more
# important, DSSTNMOV at 119; DSPLDETH from the same thing cuts it,
# since S_StartSound stops the source's own sound first, and takes the
# channel it freed; DSITEMUP (78) passes over DSPLDETH (32) and takes
# DSDOROPN (100); DSGETPOW (60) then takes it back from DSITEMUP; a
# second DSPLDETH (32) kicks out the first, since the rule is greater
# than or equal; DSSTNMOV (119) is less important than every channel and
# is dropped, so the table does not change; the removed thing's stop
# frees its channel; and DSNOWAY from nobody cuts DSSWTCHN from nobody
# through S_StopSound(NULL), then takes the first free channel.
# Updating moves the remaining sectors to volume 51 and separation 204,
# except sector 3 which leaves earshot and stops. The centred sound
# stays centred, and stopping NULL frees it. The sides are I_SDL_UpdateSoundParams': ((254 - sep) * vol) /
# 127 and (sep * vol) / 127. Centred at the default volume that is 63
# and 64; the door at volume 51 and separation 204 is 20 and 81, and at
# 64 and 129 it is 62 and 65.
#
# Then the mixer playing no song, so that the output is the channel alone:
# DSNOWAY started centred at the default volume, read in windows of 1,
# 7, 100, 2048, 33, 999, 3072, 5 and then 3072 frames until the file
# ends. Its 16996 frames must be what Chocolate Doom plays, so the hash
# and the frames are ticket 03's, read from the capture
# tools/listen.nu made of Chocolate Doom and from its own Mix_Chunk
# dumped under gdb: the same values tests/sfx.bend prints for DSNOWAY's
# "heard" lines, which pass through Stream.side, the scaling this file
# now drives through the mixer. The frame after the last is silence,
# and the channel has freed itself.
#
# Last the song from its first frame, past the chip's first buffer, with
# two sounds over it, DSDOROPN from a sector heard at 51 and 204 from
# that frame and DSNOWAY centred from frame 2156,
# read in the same uneven windows. The hash is over every frame of the
# run and the frames named are the first, the last before the second
# sound, the first two of the overlap and the last of the run. Those are
# regression pins; ticket 05 records separate sample-for-sample
# comparisons with Chocolate Doom, including its actual OPL output.
import Base
import ../src/fnv.bend as H
import ../src/sound.bend as Sn
import ../src/channel.bend as C
import ../src/song.bend as S
import ../src/stream.bend as A

def Test.slot(c: Maybe<C.Channel>) -> Maybe<C.Channel> & String:
  match c:
    case None{}:
      (None{}, "-")
    case Some{C.Chan{file, +sfx, +source, +left, +right}}:
      (Some{C.Chan{file, sfx, source, left, right}},
        Sn.Sound.lump(Sn.Sound.table(), sfx) ++ "/" ++ Sn.Sound.Source.show(source) ++ "/"
          ++ U32.show(left) ++ "," ++ U32.show(right))

def Test.table.cons(p: Maybe<C.Channel> & String, q: List<Maybe<C.Channel>> & List<&2, String>) ->
  List<Maybe<C.Channel>> & List<&2, String>:
  (c, s) = p
  (cs, ts) = q
  (c <> cs, s <> ts)

# The table given back with each channel shown.
def Test.table(chans: List<Maybe<C.Channel>>) -> List<Maybe<C.Channel>> & List<&2, String>:
  match chans:
    case []:
      ([], [])
    case c <> rest:
      Test.table.cons(Test.slot(c), Test.table(rest))

def Test.told(+tag: String, p: List<Maybe<C.Channel>> & List<&2, String>) -> IO(List<Maybe<C.Channel>>):
  (chans, names) = p
  do IO<List<Maybe<C.Channel>>>:
    IO.print(tag ++ " " ++ String.join(names, " "))
    return chans

# One event given to the channels, and the table it leaves.
def Test.step(+dir: String, +tag: String, e: Sn.Sound.Event, chans: List<Maybe<C.Channel>>) ->
  IO(List<Maybe<C.Channel>>):
  IO.bind(List<Maybe<C.Channel>>, List<Maybe<C.Channel>>, C.Channel.hear(dir, [e], chans),
    cs => Test.told(tag, Test.table(cs)))

def Test.run.on(acc: List<&2, U32>, p: S.Song.Deck & List<Maybe<C.Channel>> & List<&2, U32>,
  rest: S.Song.Deck -> List<Maybe<C.Channel>> -> List<&2, U32> ->
    IO(S.Song.Deck & List<Maybe<C.Channel>> & List<&2, U32>)) ->
  IO(S.Song.Deck & List<Maybe<C.Channel>> & List<&2, U32>):
  (deck, chans, words) = p
  rest(deck, chans, List.append(&2, U32, acc, words))

# A window of each of the frame counts, its frames gathered in order.
def Test.run(sizes: List<&2, U32>, deck: S.Song.Deck, chans: List<Maybe<C.Channel>>,
  acc: List<&2, U32>) -> IO(S.Song.Deck & List<Maybe<C.Channel>> & List<&2, U32>):
  match sizes:
    case []:
      IO.pure(S.Song.Deck & List<Maybe<C.Channel>> & List<&2, U32>, (deck, chans, acc))
    case n <> more:
      IO.bind(S.Song.Deck & List<Maybe<C.Channel>> & List<&2, U32>,
        S.Song.Deck & List<Maybe<C.Channel>> & List<&2, U32>, A.Stream.window(n, deck, chans),
        p => Test.run.on(acc, p, t => cs => ws => Test.run(more, t, cs, ws)))

def Test.signed(+x: U32) -> String:
  Bool.pick(String, U32.is_ge(x, 32768), "-" ++ U32.show((65536 - x : U32)), U32.show(x))

def Test.frame(+words: List<&2, U32>, +i: U32) -> String:
  +w = Maybe.default(&2, U32, List.get(&2, U32, words, U32.to_nat(i)), 0)
  U32.show(i) ++ " " ++ Test.signed((w .&. 65535 : U32)) ++ " " ++ Test.signed((w >> 16n : U32))

def Test.frames(+words: List<&2, U32>, at: List<&2, U32>) -> List<&2, String>:
  match at:
    case []:
      []
    case i <> rest:
      Test.frame(words, i) <> Test.frames(words, rest)

# The windows a run is read in: the uneven ones, then whole game frames.
def Test.sizes() -> List<&2, U32>:
  [1, 7, 100, 2048, 33, 999, 3072, 5, 3072, 3072, 3072, 3072]

def Test.alone.told(+tag: String, +words: List<&2, U32>, at: List<&2, U32>, +take: U32) -> IO(Unit):
  IO.print(tag ++ " " ++ U32.show(H.Fnv.words(List.take(&2, U32, words, U32.to_nat(take)))) ++ " "
    ++ String.join(Test.frames(words, at), " "))

def Test.alone.done(p: S.Song.Deck & List<Maybe<C.Channel>> & List<&2, U32>) -> IO(Unit):
  (deck, chans, words) = p
  do IO<Unit>:
    Test.alone.told("grunt", words, [0, 1, 3, 2714, 16995, 16996], 16996)
    kept : List<Maybe<C.Channel>> <- Test.told("after", Test.table(chans))
    C.Channel.stop(kept)

# The grunt alone, over a deck that plays no song.
def Test.alone(+dir: String, deck: S.Song.Deck, chans: List<Maybe<C.Channel>>) -> IO(Unit):
  IO.bind(S.Song.Deck & List<Maybe<C.Channel>> & List<&2, U32>, Unit,
    Test.run(Test.sizes(), deck, chans, []), Test.alone.done)

def Test.song.told(+words: List<&2, U32>) -> IO(Unit):
  IO.print("song " ++ U32.show(H.Fnv.words(words)) ++ " "
    ++ String.join(Test.frames(words, [0, 1, 2155, 2156, 2157, 15480]), " "))

def Test.song.done(p: S.Song.Deck & List<Maybe<C.Channel>> & List<&2, U32>) -> IO(Unit):
  (deck, chans, words) = p
  do IO<Unit>:
    Test.song.told(words)
    kept : List<Maybe<C.Channel>> <- Test.told("playing", Test.table(chans))
    C.Channel.stop(kept)

def Test.song.on(+dir: String, p: S.Song.Deck & List<Maybe<C.Channel>> & List<&2, U32>) ->
  IO(Unit):
  (deck, chans, acc) = p
  do IO<Unit>:
    both : List<Maybe<C.Channel>> <- C.Channel.hear(dir, [Sn.Start{Sn.Sound.noway(), Sn.Nobody{}, 64, 128}],
      chans)
    after : S.Song.Deck & List<Maybe<C.Channel>> & List<&2, U32> <-
      Test.run([33, 999, 3072, 5, 3072, 3072, 3072], deck, both, acc)
    Test.song.done(after)

def Test.started(p: S.Song.Deck & List<&2, U32>) -> S.Song.Deck:
  (deck, idle) = p
  deck

# The song from its first frame, after the chip's first buffer, with a
# door from that frame and the grunt from 2156.
def Test.song(+dir: String, deck: S.Song.Deck) -> IO(Unit):
  do IO<Unit>:
    door : List<Maybe<C.Channel>> <- C.Channel.hear(dir,
      [Sn.Start{Sn.Sound.doropn(), Sn.Sector{2}, 51, 204}], C.Channel.none())
    first : S.Song.Deck & List<Maybe<C.Channel>> & List<&2, U32> <-
      Test.run([1, 7, 100, 2048], Test.started(S.Song.Deck.take(4096, S.Song.Deck.change("D_E1M1", deck))), door, [])
    Test.song.on(dir, first)

def Test.played(+dir: String, +deck: S.Song.Deck, chans: List<Maybe<C.Channel>>) -> IO(Unit):
  do IO<Unit>:
    Test.alone(dir, deck, chans)
    Test.song(dir, deck)

def Test.params(ctx: Unit, source: Sn.Sound.Source) -> U32 & U32:
  match source:
    case Sn.Nobody{}:
      (64, 128)
    case Sn.Sector{3}:
      (0, 128)
    case _:
      (51, 204)

# The scripted sequence, one event a step.
def Test.script(+dir: String) -> IO(Unit):
  do IO<Unit>:
    c1 : List<Maybe<C.Channel>> <- Test.step(dir, "01", Sn.Start{Sn.Sound.stnmov(), Sn.Sector{1}, 64, 128},
      C.Channel.none())
    c2 : List<Maybe<C.Channel>> <- Test.step(dir, "02", Sn.Start{Sn.Sound.doropn(), Sn.Sector{2}, 51, 204}, c1)
    c3 : List<Maybe<C.Channel>> <- Test.step(dir, "03", Sn.Start{Sn.Sound.dorcls(), Sn.Sector{3}, 64, 129}, c2)
    c4 : List<Maybe<C.Channel>> <- Test.step(dir, "04", Sn.Start{Sn.Sound.pstart(), Sn.Sector{4}, 64, 128}, c3)
    c5 : List<Maybe<C.Channel>> <- Test.step(dir, "05", Sn.Start{Sn.Sound.pstop(), Sn.Sector{5}, 64, 128}, c4)
    c6 : List<Maybe<C.Channel>> <- Test.step(dir, "06", Sn.Start{Sn.Sound.bdopn(), Sn.Sector{6}, 64, 128}, c5)
    c7 : List<Maybe<C.Channel>> <- Test.step(dir, "07", Sn.Start{Sn.Sound.bdcls(), Sn.Sector{7}, 64, 128}, c6)
    c8 : List<Maybe<C.Channel>> <- Test.step(dir, "08", Sn.Start{Sn.Sound.swtchn(), Sn.Nobody{}, 64, 128}, c7)
    c9 : List<Maybe<C.Channel>> <- Test.step(dir, "09", Sn.Start{Sn.Sound.plpain(), Sn.Thing{1}, 64, 128}, c8)
    c10 : List<Maybe<C.Channel>> <- Test.step(dir, "10", Sn.Start{Sn.Sound.pldeth(), Sn.Thing{1}, 64, 128}, c9)
    c11 : List<Maybe<C.Channel>> <- Test.step(dir, "11", Sn.Start{Sn.Sound.itemup(), Sn.Sector{8}, 64, 128}, c10)
    c12 : List<Maybe<C.Channel>> <- Test.step(dir, "12", Sn.Start{Sn.Sound.getpow(), Sn.Sector{9}, 64, 128}, c11)
    c13 : List<Maybe<C.Channel>> <- Test.step(dir, "13", Sn.Start{Sn.Sound.pldeth(), Sn.Thing{2}, 64, 128}, c12)
    c14 : List<Maybe<C.Channel>> <- Test.step(dir, "14", Sn.Start{Sn.Sound.stnmov(), Sn.Sector{10}, 64, 128}, c13)
    c15 : List<Maybe<C.Channel>> <- Test.step(dir, "15", Sn.Stop{Sn.Thing{2}}, c14)
    c16 : List<Maybe<C.Channel>> <- Test.step(dir, "16", Sn.Start{Sn.Sound.noway(), Sn.Nobody{}, 64, 128}, c15)
    moved : List<Maybe<C.Channel>> <- C.Channel.update(~Unit, ~Test.params, Unit{}, c16)
    c17 : List<Maybe<C.Channel>> <- Test.told("17", Test.table(moved))
    c18 : List<Maybe<C.Channel>> <- Test.step(dir, "18", Sn.Stop{Sn.Nobody{}}, c17)
    C.Channel.stop(c18)

def main() -> IO(Unit):
  do IO<Unit>:
    +dir : String <- IO.try(String, IO.get_env("BENDOOM_SOUNDS"))
    deck : S.Song.Deck <- S.Song.Deck.load(["D_E1M1"])
    Test.script(dir)
    grunt : List<Maybe<C.Channel>> <- C.Channel.hear(dir, [Sn.Start{Sn.Sound.noway(), Sn.Nobody{}, 64, 128}],
      C.Channel.none())
    Test.played(dir, deck, grunt)
    IO.print("postmix " ++ Test.frame(A.Stream.post([(35536 << 16n : U32)],
      [A.Stream.mix(0, 255, 30000, A.Stream.mix(0, 255, 30000, 0))]), 0))
#|01 DSSTNMOV/sector 1/63,64 - - - - - - -
#|02 DSSTNMOV/sector 1/63,64 DSDOROPN/sector 2/20,81 - - - - - -
#|03 DSSTNMOV/sector 1/63,64 DSDOROPN/sector 2/20,81 DSDORCLS/sector 3/62,65 - - - - -
#|04 DSSTNMOV/sector 1/63,64 DSDOROPN/sector 2/20,81 DSDORCLS/sector 3/62,65 DSPSTART/sector 4/63,64 - - - -
#|05 DSSTNMOV/sector 1/63,64 DSDOROPN/sector 2/20,81 DSDORCLS/sector 3/62,65 DSPSTART/sector 4/63,64 DSPSTOP/sector 5/63,64 - - -
#|06 DSSTNMOV/sector 1/63,64 DSDOROPN/sector 2/20,81 DSDORCLS/sector 3/62,65 DSPSTART/sector 4/63,64 DSPSTOP/sector 5/63,64 DSBDOPN/sector 6/63,64 - -
#|07 DSSTNMOV/sector 1/63,64 DSDOROPN/sector 2/20,81 DSDORCLS/sector 3/62,65 DSPSTART/sector 4/63,64 DSPSTOP/sector 5/63,64 DSBDOPN/sector 6/63,64 DSBDCLS/sector 7/63,64 -
#|08 DSSTNMOV/sector 1/63,64 DSDOROPN/sector 2/20,81 DSDORCLS/sector 3/62,65 DSPSTART/sector 4/63,64 DSPSTOP/sector 5/63,64 DSBDOPN/sector 6/63,64 DSBDCLS/sector 7/63,64 DSSWTCHN/nobody/63,64
#|09 DSPLPAIN/thing 1/63,64 DSDOROPN/sector 2/20,81 DSDORCLS/sector 3/62,65 DSPSTART/sector 4/63,64 DSPSTOP/sector 5/63,64 DSBDOPN/sector 6/63,64 DSBDCLS/sector 7/63,64 DSSWTCHN/nobody/63,64
#|10 DSPLDETH/thing 1/63,64 DSDOROPN/sector 2/20,81 DSDORCLS/sector 3/62,65 DSPSTART/sector 4/63,64 DSPSTOP/sector 5/63,64 DSBDOPN/sector 6/63,64 DSBDCLS/sector 7/63,64 DSSWTCHN/nobody/63,64
#|11 DSPLDETH/thing 1/63,64 DSITEMUP/sector 8/63,64 DSDORCLS/sector 3/62,65 DSPSTART/sector 4/63,64 DSPSTOP/sector 5/63,64 DSBDOPN/sector 6/63,64 DSBDCLS/sector 7/63,64 DSSWTCHN/nobody/63,64
#|12 DSPLDETH/thing 1/63,64 DSGETPOW/sector 9/63,64 DSDORCLS/sector 3/62,65 DSPSTART/sector 4/63,64 DSPSTOP/sector 5/63,64 DSBDOPN/sector 6/63,64 DSBDCLS/sector 7/63,64 DSSWTCHN/nobody/63,64
#|13 DSPLDETH/thing 2/63,64 DSGETPOW/sector 9/63,64 DSDORCLS/sector 3/62,65 DSPSTART/sector 4/63,64 DSPSTOP/sector 5/63,64 DSBDOPN/sector 6/63,64 DSBDCLS/sector 7/63,64 DSSWTCHN/nobody/63,64
#|14 DSPLDETH/thing 2/63,64 DSGETPOW/sector 9/63,64 DSDORCLS/sector 3/62,65 DSPSTART/sector 4/63,64 DSPSTOP/sector 5/63,64 DSBDOPN/sector 6/63,64 DSBDCLS/sector 7/63,64 DSSWTCHN/nobody/63,64
#|15 - DSGETPOW/sector 9/63,64 DSDORCLS/sector 3/62,65 DSPSTART/sector 4/63,64 DSPSTOP/sector 5/63,64 DSBDOPN/sector 6/63,64 DSBDCLS/sector 7/63,64 DSSWTCHN/nobody/63,64
#|16 DSNOWAY/nobody/63,64 DSGETPOW/sector 9/63,64 DSDORCLS/sector 3/62,65 DSPSTART/sector 4/63,64 DSPSTOP/sector 5/63,64 DSBDOPN/sector 6/63,64 DSBDCLS/sector 7/63,64 -
#|17 DSNOWAY/nobody/63,64 DSGETPOW/sector 9/20,81 - DSPSTART/sector 4/20,81 DSPSTOP/sector 5/20,81 DSBDOPN/sector 6/20,81 DSBDCLS/sector 7/20,81 -
#|18 - DSGETPOW/sector 9/20,81 - DSPSTART/sector 4/20,81 DSPSTOP/sector 5/20,81 DSBDOPN/sector 6/20,81 DSBDCLS/sector 7/20,81 -
#|grunt 3631499139 0 63 64 1 49 50 3 -50 -50 2714 7399 7517 16995 -43 -44 16996 0 0
#|after - - - - - - - -
#|song 4183762350 0 -20 -81 1 -22 -91 2155 -698 -1447 2156 -828 -1245 2157 -1038 -1548 15480 2248 6736
#|playing DSDOROPN/sector 2/20,81 DSNOWAY/nobody/63,64 - - - - - -
#|postmix 0 0 2767
