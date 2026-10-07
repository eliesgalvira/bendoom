# A sound lump as Chocolate Doom 3.1.1 loads it (CacheSFX in
# src/i_sdlsound.c) and expands it to 44100 Hz (ExpandSoundData_SDL).
# At 11025, 22050 and 44100 Hz, the rates ConvertibleRatio lets through,
# the expansion is SDL's converter, which in the nixpkgs build is
# sdl2-compat handing the whole sound to an SDL 3.4.14 audio stream:
# unsigned bytes made floats, resampled as mono by twelve taps around
# each source sample (ResampleFrame_Generic_SSE), doubled to stereo and
# made 16-bit. Both sides of Chocolate Doom's chunk hold the same
# sample, so the expansion here is mono. Any other rate takes Chocolate
# Doom's nearest-sample loop, which no shareware sound needs (Freedoom's
# DSRLAUNC and DSHOOF do), so such a sound expands to nothing.
import Base
import ./bytes.bend as B
import ./sfx_taps.bend as T

# A lump's rate, how many bytes Chocolate Doom plays, and the lump from
# the first of them on.
type Sfx.Sound is Data:
  Sound{rate: U32, count: U32, bytes: List<&2, U32>}

# The lump reader
# ---------------

# CacheSFX's checks on a lump of size bytes: format 3, and a length that
# fits after the 8-byte header and is over 48.
def Sfx.played(+size: U32, format: U32, +length: U32) -> Bool:
  U32.is_ge(size, 8) && U32.is_eq(format, 3) && U32.is_le(length, (size - 8 : U32)) && U32.is_gt(length, 48)

def Sfx.size(xs: List<&2, U32>, +n: U32) -> U32:
  match xs:
    case []:
      n
    case x <> rest:
      Sfx.size(rest, (n + 1 : U32))

# DMX skips the first 16 and the last 16 bytes of the length.
def Sfx.read.at(ok: Bool, rate: U32, +length: U32, rest: List<&2, U32>) -> Maybe<&2, Sfx.Sound>:
  match ok:
    case False{}:
      None{}
    case True{}:
      Some{Sound{rate, (length - 32 : U32), List.drop(&2, U32, rest, 16n)}}

# The sound in a lump's bytes, or none for a lump CacheSFX refuses; a
# missing lump has no bytes, which it refuses.
def Sfx.read.sized(+size: U32, lump: List<&2, U32>) -> Maybe<&2, Sfx.Sound>:
  match lump:
    case f0 <> f1 <> r0 <> r1 <> l0 <> l1 <> l2 <> l3 <> rest:
      +length = B.Bytes.le32(l0, l1, l2, l3)
      Sfx.read.at(Sfx.played(size, B.Bytes.le16(f0, f1), length), B.Bytes.le16(r0, r1), length, rest)
    case _:
      None{}

def Sfx.read(+lump: List<&2, U32>) -> Maybe<&2, Sfx.Sound>:
  Sfx.read.sized(Sfx.size(lump, 0), lump)

# The expansion
# -------------

# SDL_Convert_U8_to_F32: (b - 128) / 128, exact.
def Sfx.float(b: U32) -> F32:
  ((U32.to_f32(b) - 128.0 : F32) / 128.0 : F32)

# The first n bytes as floats, after acc's reversed, and six of
# silence after them: SDL pads past the sound's end with silence, and
# the last sample's taps reach six past it.
def Sfx.floats(n: Nat, bytes: List<&2, U32>, acc: List<&2, F32>) -> List<&2, F32>:
  match n bytes:
    case 0n _:
      List.reverse.go(&2, F32, acc, [0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
    case 1n+m Nil{}:
      List.reverse.go(&2, F32, acc, [0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
    case 1n+m b <> rest:
      Sfx.floats(m, rest, Sfx.float(b) <> acc)

# Twelve taps times twelve samples, the products added as
# ResampleFrame_Generic_SSE adds them: three vectors of four summed lane
# by lane, then lanes 0 and 1, lanes 2 and 3, and the two sums. libSDL3
# holds no fused multiply-add.
def Sfx.dot(row: List<&2, F32>, xs: List<&2, F32>) -> F32:
  match row xs:
    case t0 <> t1 <> t2 <> t3 <> t4 <> t5 <> t6 <> t7 <> t8 <> t9 <> t10 <> t11 <> tr
      x0 <> x1 <> x2 <> x3 <> x4 <> x5 <> x6 <> x7 <> x8 <> x9 <> x10 <> x11 <> xr:
      (((((t0 * x0 : F32) + (t4 * x4 : F32) : F32) + (t8 * x8 : F32) : F32)
        + (((t1 * x1 : F32) + (t5 * x5 : F32) : F32) + (t9 * x9 : F32) : F32) : F32)
        + ((((t2 * x2 : F32) + (t6 * x6 : F32) : F32) + (t10 * x10 : F32) : F32)
          + (((t3 * x3 : F32) + (t7 * x7 : F32) : F32) + (t11 * x11 : F32) : F32) : F32) : F32)
    case _ _:
      0.0

# SDL_Convert_F32_to_S16_SSE2: x + 257 rounds x to the nearest 1 / 32768,
# ties to even, and the result's bits less 256's are the sample plus
# 32768, which packs_epi32 clamps to 16 bits. The sample is returned as
# its 16 bits.
def Sfx.sample(x: F32) -> U32:
  (F32.to_u32(F32.clamp((((x + 257.0 : F32) - 256.0 : F32) * 32768.0 : F32), 0.0, 65535.0)) .^. 32768 : U32)

# The frames one source sample makes, written from i on.
def Sfx.frames(rows: List<&2, List<&2, F32>>, +xs: List<&2, F32>, a: Array<U32>, +i: U32) -> Array<U32>:
  match rows:
    case []:
      a
    case row <> rest:
      Sfx.frames(rest, xs, Array.set(U32, a, i, Sfx.sample(Sfx.dot(row, xs))), (i + 1 : U32))

def Sfx.expand.go(n: Nat, +rows: List<&2, List<&2, F32>>, +step: U32, xs: List<&2, F32>, a: Array<U32>, +i: U32) ->
  Array<U32>:
  match n xs:
    case 0n _:
      a
    case 1n+m Nil{}:
      a
    case 1n+m +x <> +rest:
      Sfx.expand.go(m, rows, step, rest, Sfx.frames(rows, x <> rest, a, i), (i + step : U32))

# The resampler's phase advances by 8 * rate / 44100 a frame, and the
# table holds the even phases, so a frame's row is every rate / 11025th.
def Sfx.rows(rows: List<&2, List<&2, F32>>, +every: U32, +i: U32) -> List<&2, List<&2, F32>>:
  match rows:
    case []:
      []
    case row <> rest:
      List.filter.put(List<&2, F32>, row, Sfx.rows(rest, every, (i + 1 : U32)), U32.is_zero((i % every : U32)))

def Sfx.served(+rate: U32) -> Bool:
  U32.is_eq(rate, 11025) || U32.is_eq(rate, 22050) || U32.is_eq(rate, 44100)

def Sfx.length.at(ok: Bool, +rate: U32, +count: U32) -> U32:
  match ok:
    case False{}:
      0
    case True{}:
      (count * (44100 / rate) : U32)

# The frames a sound expands to: 44100 / rate a byte played, none at a
# rate SDL's converter is not given.
def Sfx.length(s: Sfx.Sound) -> U32:
  Sound{+rate, count, bytes} = s
  Sfx.length.at(Sfx.served(rate), rate, count)

def Sfx.expand.at(ok: Bool, +rate: U32, +count: U32, bytes: List<&2, U32>, a: Array<U32>, +at: U32) -> Array<U32>:
  match ok:
    case False{}:
      a
    case True{}:
      Sfx.expand.go(U32.to_nat(count), Sfx.rows(T.SfxTaps.rows(), (rate / 11025 : U32), 0), (44100 / rate : U32),
        Sfx.floats(U32.to_nat(count), bytes, [0.0, 0.0, 0.0, 0.0, 0.0]), a, at)

# A sound's 16-bit samples at 44100 Hz written into the array from at,
# the five source samples before its first silence as SDL's history is;
# nothing at a rate SDL's converter is not given.
def Sfx.expand(s: Sfx.Sound, a: Array<U32>, +at: U32) -> Array<U32>:
  Sound{+rate, count, bytes} = s
  Sfx.expand.at(Sfx.served(rate), rate, count, bytes, a, at)
