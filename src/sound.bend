# Doom's sounds.c for the sounds Bendoom starts, and the placing half of
# s_sound.c: who makes a sound, what a tic reports of it, and
# S_AdjustSoundParams, the volume and stereo separation a listener hears
# a place at.
import Base
import ./vec.bend as V
import ./fixed.bend as F
import ./angle.bend as A

# A sound is named by its sfxenum_t number; 0 is vanilla's sfx_None, the
# sound that starts nothing.
def Sound.pistol() -> U32:
  1

def Sound.shotgn() -> U32:
  2

def Sound.sgcock() -> U32:
  3

def Sound.sawup() -> U32:
  10

def Sound.sawidl() -> U32:
  11

def Sound.sawful() -> U32:
  12

def Sound.sawhit() -> U32:
  13

def Sound.firsht() -> U32:
  16

def Sound.firxpl() -> U32:
  17

def Sound.claw() -> U32:
  55

def Sound.pstart() -> U32:
  18

def Sound.pstop() -> U32:
  19

def Sound.doropn() -> U32:
  20

def Sound.dorcls() -> U32:
  21

def Sound.stnmov() -> U32:
  22

def Sound.swtchn() -> U32:
  23

def Sound.plpain() -> U32:
  25

def Sound.slop() -> U32:
  31

def Sound.itemup() -> U32:
  32

# The sight calls of the four monster types: the former humans share
# three, the imp two, and the demon has its own.
def Sound.posit1() -> U32:
  36

def Sound.posit3() -> U32:
  38

def Sound.bgsit1() -> U32:
  39

def Sound.bgsit2() -> U32:
  40

def Sound.wpnup() -> U32:
  33

def Sound.oof() -> U32:
  34

def Sound.pldeth() -> U32:
  57

# The three zombie death sounds and the two imp ones are groups A_Scream
# draws one of; the demon's and the barrel's stand alone.
def Sound.podth1() -> U32:
  59

def Sound.bgdth1() -> U32:
  62

def Sound.barexp() -> U32:
  82

def Sound.punch() -> U32:
  83

def Sound.noway() -> U32:
  81

def Sound.bdopn() -> U32:
  88

def Sound.bdcls() -> U32:
  89

def Sound.getpow() -> U32:
  93

def Sound.telept() -> U32:
  35

# A row of S_sfx: the sound's number, its lump, and its priority, where
# less is more important.
type Sound.Sfx is Data:
  Sfx{id: U32, lump: String, priority: U32}

def Sound.table() -> List<&2, Sound.Sfx>:
  [Sfx{1, "DSPISTOL", 64}, Sfx{3, "DSSGCOCK", 64}, Sfx{10, "DSSAWUP", 64}, Sfx{11, "DSSAWIDL", 118},
    Sfx{12, "DSSAWFUL", 64}, Sfx{13, "DSSAWHIT", 64}, Sfx{18, "DSPSTART", 100}, Sfx{19, "DSPSTOP", 100}, Sfx{20, "DSDOROPN", 100},
    Sfx{21, "DSDORCLS", 100}, Sfx{22, "DSSTNMOV", 119}, Sfx{23, "DSSWTCHN", 78}, Sfx{25, "DSPLPAIN", 96},
    Sfx{32, "DSITEMUP", 78}, Sfx{33, "DSWPNUP", 78}, Sfx{34, "DSOOF", 96}, Sfx{57, "DSPLDETH", 32},
    Sfx{81, "DSNOWAY", 78}, Sfx{88, "DSBDOPN", 100}, Sfx{89, "DSBDCLS", 100}, Sfx{93, "DSGETPOW", 60},
    Sfx{26, "DSDMPAIN", 96}, Sfx{27, "DSPOPAIN", 96}, Sfx{31, "DSSLOP", 78}, Sfx{36, "DSPOSIT1", 98},
    Sfx{37, "DSPOSIT2", 98}, Sfx{38, "DSPOSIT3", 98}, Sfx{39, "DSBGSIT1", 98}, Sfx{40, "DSBGSIT2", 98},
    Sfx{41, "DSSGTSIT", 98}, Sfx{59, "DSPODTH1", 70}, Sfx{60, "DSPODTH2", 70}, Sfx{61, "DSPODTH3", 70},
    Sfx{62, "DSBGDTH1", 70}, Sfx{63, "DSBGDTH2", 70}, Sfx{64, "DSSGTDTH", 70}, Sfx{82, "DSBAREXP", 60},
    Sfx{2, "DSSHOTGN", 64}, Sfx{16, "DSFIRSHT", 70}, Sfx{17, "DSFIRXPL", 70}, Sfx{55, "DSCLAW", 70}, Sfx{83, "DSPUNCH", 64},
    Sfx{75, "DSPOSACT", 120}, Sfx{76, "DSBGACT", 120}, Sfx{77, "DSDMACT", 120}, Sfx{43, "DSBRSSIT", 94},
    Sfx{67, "DSBRSDTH", 32}, Sfx{35, "DSTELEPT", 32}]

# Who makes a sound, S_StartSound's origin: a thing by its name, a
# sector from the centre of its box, a fixed place, or nobody. A channel
# plays one sound a source, and nobody is a source too.
type Sound.Source is Data:
  Thing{id: U32}
  Sector{sector: U32}
  Spot{x: U32, y: U32}
  Nobody{}

# What a tic reports: a sound started by a source, at the volume (0 to
# 127) and separation (0 to 255, 128 the centre) the player heard it at
# then, or a source's sound stopped.
type Sound.Event is Data:
  Start{sfx: U32, source: Sound.Source, vol: U32, sep: U32}
  Stop{source: Sound.Source}

def Sound.lump(rows: List<&2, Sound.Sfx>, +sfx: U32) -> String:
  match rows:
    case []:
      ""
    case Sfx{id, lump, priority} <> rest:
      Bool.pick(String, U32.is_eq(id, sfx), lump, Sound.lump(rest, sfx))

def Sound.Source.show(source: Sound.Source) -> String:
  match source:
    case Thing{id}:
      "thing " ++ U32.show(id)
    case Sector{sector}:
      "sector " ++ U32.show(sector)
    case Spot{x, y}:
      "spot " ++ F.Fixed.show(x) ++ " " ++ F.Fixed.show(y)
    case Nobody{}:
      "nobody"

# An event as text, for the tests and the tools.
def Sound.Event.show(e: Sound.Event) -> String:
  match e:
    case Start{sfx, source, vol, sep}:
      Sound.lump(Sound.table(), sfx) ++ " from " ++ Sound.Source.show(source) ++ " vol " ++ U32.show(vol)
        ++ " sep " ++ U32.show(sep)
    case Stop{source}:
      "stop " ++ Sound.Source.show(source)

# snd_SfxVolume at Chocolate Doom's default: the menu's 8 of 15, times 8.
def Sound.volume() -> U32:
  64

# NORM_SEP, the centre.
def Sound.centre() -> U32:
  128

# A sound with no place, or the listener's own: full volume, centred.
def Sound.plain(sfx: U32, source: Sound.Source) -> Sound.Event:
  Start{sfx, source, Sound.volume(), Sound.centre()}

# Whether S_StartSound draws a pitch for a start, which it never uses:
# every sound but the item pickup's (and sfx_tink, which no E1M1 starts).
def Sound.Event.draws(e: Sound.Event) -> Bool:
  match e:
    case Start{sfx, source, vol, sep}:
      Bool.not(U32.is_eq(sfx, Sound.itemup()))
    case Stop{source}:
      False{}

# The volume at a distance: full under S_CLOSE_DIST, 200, none past
# S_CLIPPING_DIST, 1200, and between them the whole units left to 1200
# over S_ATTENUATOR, 1000. The last 15 units round down to silence.
def Sound.volume.at(+dist: U32) -> U32:
  Bool.pick(U32, F.Fixed.lt(dist, 13107200), Sound.volume(),
    Bool.pick(U32, F.Fixed.gt(dist, 78643200), 0,
      ((Sound.volume() * ((78643200 - dist : U32) >> 16n) : U32) / 1000 : U32)))

# The separation of a source at an angle from a listener facing another:
# 128 less S_STEREO_SWING, 96, times the sine of the angle between them,
# floored. Vanilla takes one more off an angle not past the facing, so a
# source dead ahead sits at 129.
def Sound.sep(sine: V.Vec, +angle: U32, +facing: U32) -> U32:
  (128 - F.Fixed.sarn(F.Fixed.mul(6291456, A.Angle.sin(sine,
    A.Angle.fine((angle - facing - Bool.to_u32(U32.is_le(angle, facing)) : U32)))), 16n) : U32)

# Doom's S_AdjustSoundParams: the volume and separation a listener at
# (lx, ly) facing an angle hears a source at (sx, sy) at. Volume 0 is
# inaudible. Only S_StartSound centres a coincident source; the per-tic
# update uses the calculated separation even at that position.
def Sound.adjust(starting: Bool, sine: V.Vec, tanto: V.Vec, +lx: U32, +ly: U32, facing: U32, +sx: U32, +sy: U32) -> U32 & U32:
  (Sound.volume.at(F.Fixed.approx((lx - sx : U32), (ly - sy : U32))),
    Bool.pick(U32, Bool.and(starting, Bool.and(U32.is_eq(lx, sx), U32.is_eq(ly, sy))), Sound.centre(),
      Sound.sep(sine, A.Angle.of(tanto, (sx - lx : U32), (sy - ly : U32)), facing)))

# The priority of a sound, where less is more important. A sound with no
# row of its own is the least important there is.
def Sound.priority(rows: List<&2, Sound.Sfx>, +sfx: U32) -> U32:
  match rows:
    case []:
      255
    case Sfx{id, lump, priority} <> rest:
      Bool.pick(U32, U32.is_eq(id, sfx), priority, Sound.priority(rest, sfx))

# Whether a sound from one source cuts a sound from another, as
# S_StopSound compares origins. A sound from nobody has no origin to
# compare, so it cuts nothing.
def Sound.Source.same(a: Sound.Source, b: Sound.Source) -> Bool:
  match a b:
    case Thing{i} Thing{j}:
      U32.is_eq(i, j)
    case Sector{i} Sector{j}:
      U32.is_eq(i, j)
    case Spot{x, y} Spot{u, v}:
      Bool.and(U32.is_eq(x, u), U32.is_eq(y, v))
    case Nobody{} Nobody{}:
      True{}
    case _ _:
      False{}
