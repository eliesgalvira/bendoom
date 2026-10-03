# Freedoom's sounds as src/sfx.bend reads and expands them, against
# Chocolate Doom 3.1.1: the use grunt DSNOWAY at 22050 Hz, where every
# other frame is resampled, the pickup DSITEMUP at 11025 Hz, which
# meets all four rows of taps, and DSRLAUNC at 16000 Hz, which SDL's
# converter is not given, so it expands to no frames. First the taps'
# bits hashed, the value tools/gen_sfx_taps.nu writes in
# src/sfx_taps.bend. Then each sound's rate and bytes played, as
# tools/wad.nu reads the lump:
#
#   nu -c 'source tools/wad.nu; open --raw $env.BENDOOM_IWAD | sound-lumps | where name in [DSNOWAY DSITEMUP DSRLAUNC]'
#
# "chunk" is an FNV-1a hash of the expansion's 16-bit samples, so of
# their count too. The expected value is the hash of the left samples
# of Chocolate Doom's own chunk, dumped from its memory under gdb on the
# run the capture tool makes; milestone 7's ticket 03 has the gdb
# script. The right samples equal the left.
#
# "heard" is what the capture holds. Both sounds play centred at the
# default volume, which I_SDL_UpdateSoundParams makes a left of 63 and a
# right of 64, and the mixer's Stream.side scales each side as
# SDL_mixer's _Eff_position_s16lsb does. The hash is over the
# sound's frames so scaled, each a 32-bit word with the left in the low
# half, and the lines after it are frames by index: the first ones, the
# loudest, the last. The expected values are read in nushell from
# captures kept by tools/listen.nu, both sounds starting at frame
# 118784, the grunt 16996 frames and the pickup 8692:
#
#   tools/listen.nu sounds -480 192 180 "20,0,0,0,0 1,0,0,0,1 30,0,0,0,0" --keep
#   tools/listen.nu sounds 832 384 90 "20,0,0,0,0 20,25,0,0,0 1,0,0,0,1 70,0,0,0,0 1,0,0,-64,0 210,0,0,0,0" --keep
#   let c = open --raw capture.raw | bytes at (118784 * 4)..<((118784 + 16996) * 4) | chunks 4
#   $c | each { into int --endian little } | reduce --fold 2166136261 {|x, h| (($h | bits xor $x) * 16777619) mod 4294967296 }
#   $c | get 2714 | [($in | bytes at 0..1) ($in | bytes at 2..3)] | each { into int --endian little --signed }
#
# Then SDL_Convert_F32_to_S16_SSE2 on four values, worked by hand: x +
# 257 has room for 1 / 32768 and no less, so 0.5 / 32768 is a tie that
# rounds to the even 0 and 1.5 / 32768 one that rounds to the even 2;
# 1.5 clamps to 32767 and -1.5 to -32768.
# Last, CacheSFX's refusals, on a 57-byte lump unless said: a lump under
# its 8-byte header, a format other than 3, a length of 48, and a length
# one past what follows the header are refused; a length of 49 that fits
# is played.
import Base
import ../src/fnv.bend as H
import ../src/wad.bend as W
import ../src/sfx.bend as X
import ../src/sfx_taps.bend as T
import ../src/stream.bend as A

def Test.bits(xs: List<&2, F32>) -> List<&2, U32>:
  match xs:
    case []:
      []
    case x <> rest:
      F32.bits(x) <> Test.bits(rest)

def Test.word(+s: U32) -> U32:
  (A.Stream.side(s, 63) .|. (A.Stream.side(s, 64) << 16n) : U32)

def Test.heard(samples: List<&2, U32>, h: U32) -> U32:
  match samples:
    case []:
      h
    case s <> rest:
      Test.heard(rest, H.Fnv.mix(h, Test.word(s)))

def Test.signed(+x: U32) -> String:
  Bool.pick(String, U32.is_ge(x, 32768), "-" ++ U32.show((65536 - x : U32)), U32.show(x))

def Test.frame(+samples: List<&2, U32>, +i: U32) -> String:
  +lr = Test.word(Maybe.default(&2, U32, List.get(&2, U32, samples, U32.to_nat(i)), 0))
  U32.show(i) ++ " " ++ Test.signed((lr .&. 65535 : U32)) ++ " " ++ Test.signed((lr >> 16n : U32))

def Test.frames(+samples: List<&2, U32>, at: List<&2, U32>) -> List<&2, String>:
  match at:
    case []:
      []
    case i <> rest:
      Test.frame(samples, i) <> Test.frames(samples, rest)

def Test.expanded(samples: List<&2, U32>, at: List<&2, U32>) -> String:
  match samples:
    case []:
      "no frames"
    case +s <> +rest:
      String.join(("chunk " ++ U32.show(H.Fnv.words(s <> rest))) <> ("heard " ++ U32.show(Test.heard(s <> rest, H.Fnv.basis())))
        <> Test.frames(s <> rest, at), "\n")

def Test.shape(s: X.Sfx.Sound) -> String:
  X.Sound{rate, count, bytes} = s
  U32.show(rate) ++ " Hz " ++ U32.show(count) ++ " bytes\n"

def Test.sound(m: Maybe<&2, X.Sfx.Sound>, at: List<&2, U32>) -> String:
  match m:
    case None{}:
      "refused"
    case Some{+s}:
      Test.shape(s) ++ Test.expanded(X.Sfx.expand(s), at)

# Each sound's lines, with the frames to show.
def Test.sounds(lumps: List<&2, List<&2, U32>>, names: List<&2, String>, ats: List<&2, List<&2, U32>>) ->
  List<&2, String>:
  match lumps names ats:
    case lump <> ls name <> ns at <> rest:
      (name ++ " " ++ Test.sound(X.Sfx.read(lump), at)) <> Test.sounds(ls, ns, rest)
    case _ _ _:
      []

def main() -> IO(Unit):
  do IO<Unit>:
    path : String <- IO.try(String, IO.get_env("BENDOOM_IWAD"))
    +names : List<&2, String> = ["DSNOWAY", "DSITEMUP", "DSRLAUNC"]
    lumps : List<&2, List<&2, U32>> <- W.Wad.read(path, names)
    IO.print("taps " ++ U32.show(H.Fnv.words(Test.bits(List.concat(&2, F32, T.SfxTaps.rows())))))
    IO.print(String.join(Test.sounds(lumps, names, [[0, 1, 3, 2714, 16995], [0, 1, 2, 3, 1322, 8691], []]), "\n"))
    IO.print("rounds " ++ String.join([Test.signed(X.Sfx.sample((0.5 / 32768.0 : F32))),
      Test.signed(X.Sfx.sample((1.5 / 32768.0 : F32))), Test.signed(X.Sfx.sample(1.5)), Test.signed(X.Sfx.sample(F32.neg(1.5)))], " "))
    IO.print("played " ++ List.show(~&2, ~Bool, ~Bool.show, [X.Sfx.played(7, 3, 0), X.Sfx.played(57, 2, 49),
      X.Sfx.played(57, 3, 48), X.Sfx.played(57, 3, 50), X.Sfx.played(57, 3, 49)]))

#|taps 896306797
#|DSNOWAY 22050 Hz 8498 bytes
#|chunk 973226569
#|heard 3631499139
#|0 63 64
#|1 49 50
#|3 -50 -50
#|2714 7399 7517
#|16995 -43 -44
#|DSITEMUP 11025 Hz 2173 bytes
#|chunk 4006389721
#|heard 3724800991
#|0 4427 4497
#|1 4893 4970
#|2 4893 4971
#|3 4599 4673
#|1322 -5019 -5099
#|8691 318 323
#|DSRLAUNC 16000 Hz 19619 bytes
#|no frames
#|rounds 0 2 32767 -32768
#|played [False, False, False, False, True]
