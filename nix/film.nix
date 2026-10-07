{ lib, callPackage, writers, bend, coreutils, ffmpeg-headless, iwad }:

let
  inherit (lib.lists) singleton;
  inherit (lib.meta) getExe;

  frames = callPackage ./program.nix {
    inherit bend;
    pname = "bendoom-film-frames";
    root = ../film.bend;
    sources = singleton ../src;
  };
in
(writers.writeNuBin "bendoom-film" /* nu */ ''
  # Encodes a demo Bendoom recorded as an MP4, 35 frames a second.
  def main [demo: path, video: path] {
    let scratch = mktemp --directory
    let audio_hex = $scratch | path join audio.hex
    let audio_raw = $scratch | path join audio.raw
    let video_hex = $scratch | path join video.hex
    let video_raw = $scratch | path join video.raw
    try {
      with-env {
        DEMO: $demo
        AUDIO: $audio_hex
        BENDOOM_IWAD: ($env.BENDOOM_IWAD? | default "${iwad}")
      } { ^${getExe frames} --threads 1 } o> $video_hex
      ^${coreutils}/bin/basenc --base16 -d $audio_hex o> $audio_raw
      ^${coreutils}/bin/basenc --base16 -d $video_hex o> $video_raw
      (^${getExe ffmpeg-headless} -loglevel error -stats -n
        -f rawvideo -pix_fmt rgb24 -s 320x200 -framerate 35 -i $video_raw
        -f s16le -ar 44100 -ac 2 -i $audio_raw
        -filter_complex "[0:v]scale=1600:1200:flags=neighbor[v]"
        -map "[v]" -map 1:a -c:v libx264 -crf 18 -pix_fmt yuv420p -c:a aac -shortest
        -movflags +faststart $video)
    } finally {
      rm --recursive $scratch
    }
  }
'').overrideAttrs {
  preferLocalBuild = false;
  allowSubstitutes = true;
}
