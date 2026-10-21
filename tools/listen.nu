#!/usr/bin/env nu
# Records what Chocolate Doom plays, with no window and no sound card.
# SDL's dummy video driver draws nothing, and SDL's disk audio driver
# writes the sound to a file in place of a device. A scratch config
# names Chocolate Doom's default sound settings, so the user's plays no
# part: the OPL and digital devices, 44100 Hz, both volumes 8, eight
# channels, a 28 ms slice, no pitch shifting, no libsamplerate, no
# snd_dmxoption. It also turns off the ENDOOM screen, which would wait
# for a key after a demo's end.
#
# The music: E1M1's song alone, with sound effects off, or with --song
# another song in its place: a copy of the IWAD whose directory points
# D_E1M1 at that song's lump. The capture holds the given length of audio
# after the first note, at least two passes: Freedoom's E1M1 song is
# about 130.6 s a pass, the shareware one 96.0 s. The report gives the
# capture's frames, the lead (the frames before the first sample other
# than zero) and the frames whose left and right differ.
#
# The game: a Bendoom binary's own sound, recorded as it runs on a
# private Xvfb with a private PulseAudio null sink for its sound card,
# which drains at the real rate and plays nowhere. ALSA's file plugin
# between the two keeps every frame the game writes, as float, and
# ffmpeg makes 16-bit samples of it, which is exact, since each float is
# a 16-bit sample over 32768. A frame the device found no sample for is
# silence in the capture, as it is in the speaker. The game plays its
# sounds over the song, so a scene that starts none is the music alone.
# It runs until the capture holds the length asked after the first note,
# or until it quits, as the window bench does; the report adds what it
# printed. Keys can be pressed in its window, one a second from the
# first note. The desktop's sound and windows play no part.
#
# The sounds: a command script from a place, as tools/oracle.nu takes
# them, played as a demo with no music, or over the song with --music.
# The demo is tools/demo.nu's, which spawns the map's monsters, so a
# script whose place a monster can see hears that monster wake as well;
# milestone 6's ticket 08 records which places those are.
# Chocolate Doom quits at the demo's end, which ends the capture, so a
# script idles at its end for as long as its last sound lasts; timeout
# stops a run that goes a minute past the script. The report lists each
# sound: the frame it starts at, how far that is into its buffer, its
# frames, and its largest left and right samples. With sound effects on
# the device asks for 1024 frames at a time (4096 for the music alone),
# and Chocolate Doom starts a sound on a buffer's first frame, so a
# start further in is a sound that opens on zeros. A sound is a run of
# frames that differ from the reference, ended by 1024 frames that
# agree, so a sound that starts on top of another, or sooner than that
# after it, is not told apart. The reference is silence, or under
# --music a capture of the song alone (--against), recorded with --music
# from a script that starts no sound. The song's samples depend on the
# frame it starts at, which moves between runs, so the two captures
# must share it.
#
# The nixpkgs build runs on sdl2-compat over SDL3, whose disk driver
# reads SDL_AUDIO_DRIVER=disk, SDL_AUDIO_DISK_OUTPUT_FILE and
# SDL_AUDIO_DISK_TIMESCALE. SDL2's SDL_AUDIODRIVER and SDL_DISKAUDIOFILE
# work too, but SDL_DISKAUDIODELAY is ignored. The driver logs the
# format it writes, which the capture is checked against. Timescale 1
# keeps real time; 0 runs about 45 times faster, but the song's start
# then lands on another buffer, and I_OPL_PlaySong schedules the tracks
# without OPL_Lock, so the audio thread spinning beside it may start
# them apart. Chocolate Doom writes the song to $TMPDIR/doom.mid, so
# runs side by side each get their own.
#
# Needs chocolate-doom, Xvfb, PulseAudio and ffmpeg (in the dev shell).
# A kept capture stays in a scratch directory under $TMPDIR, which `nix
# develop -c` removes as it exits, so set TMPDIR to one that outlives it:
#
#   tools/listen.nu
#   tools/listen.nu --wad doom1.wad --length 200sec --keep
#   tools/listen.nu --wad doom1.wad --song D_E1M2 --keep
#   tools/listen.nu game --binary ./doom --wad doom1.wad --song D_E1M2 --keep
#   SCRIPT="35,50,0,0,0" tools/listen.nu game --binary ./window
#   tools/listen.nu compare a/capture.raw b/capture.raw
#   tools/listen.nu sounds -480 192 180 "20,0,0,0,0 1,0,0,0,1 30,0,0,0,0" --keep
#   tools/listen.nu sounds -480 192 180 "80,0,0,0,0" --music --keep
#   tools/listen.nu sounds -480 192 180 "20,0,0,0,0 1,0,0,0,1 59,0,0,0,0" --music --against a/capture.raw
#   tools/listen.nu starts b/capture.raw --against a/capture.raw

source demo.nu
source xvfb.nu

# A scratch directory holding the config, and the environment that runs
# Chocolate Doom in it with the capture as its sound card.
def scratch []: nothing -> record<dir: path, capture: path, sdl: record> {
  let dir = ^mktemp --directory | str trim
  let capture = $dir | path join capture.raw
  "snd_musicdevice 3\nsnd_sfxdevice 3\nmusic_volume 8\nsfx_volume 8\nsnd_channels 8\n" | save ($dir | path join default.cfg)
  "snd_samplerate 44100\nsnd_maxslicetime_ms 28\nsnd_pitchshift 0\nuse_libsamplerate 0\nsnd_dmxoption \"\"\nshow_endoom 0\n"
    | save ($dir | path join chocolate-doom.cfg)
  {dir: $dir, capture: $capture, sdl: {
    HOME: $dir, TMPDIR: $dir, SDL_VIDEO_DRIVER: dummy, SDL_AUDIO_DRIVER: disk
    SDL_AUDIO_DISK_OUTPUT_FILE: $capture, SDL_AUDIO_DISK_TIMESCALE: 1
  }}
}

# A finished run's capture, once the format the disk driver logged is
# the one every reader here assumes.
def heard []: record -> binary {
  let run = $in
  let spec = open ($run.dir | path join stderr) | parse --regex 'format=(?<format>\w+) channels=(?<channels>\d+) freq=(?<freq>\d+)' | first
  if $spec != {format: S16LE, channels: "2", freq: "44100"} {
    error make {msg: $"the disk driver wrote ($spec.format), ($spec.channels) channels at ($spec.freq) Hz"}
  }
  open --raw $run.capture | into binary
}

# A run's report, with the capture's path if the scratch directory is
# kept.
def kept [run: record, keep: bool]: record -> record {
  let report = $in
  if $keep { $report | insert capture $run.capture } else { rm --recursive $run.dir; $report }
}

# The first frame of a capture with a sample other than zero, or null.
def lead []: binary -> any {
  $in | chunks 4 | enumerate | where ($it.item | into int) != 0 | first 1 | get index.0?
}

# The IWAD, copied into a directory under its own name, with D_E1M1's
# directory entry pointing at another song's lump if one is named.
def iwad [dir: path, song: any]: path -> path {
  let wad = $in | path expand
  let copy = $dir | path join ($wad | path basename)
  if $song == null { return $wad }
  let bytes = open --raw $wad
  let all = $bytes | lumps | enumerate | flatten
  let entry = ($bytes | bytes at 8..11 | into int --endian little) + ($all | where name == D_E1M1 | first | get index) * 16
  let lump = $all | where name == $song | first
  [($bytes | bytes at 0..<$entry) ($lump.pos | le 4) ($lump.size | le 4) ($bytes | bytes at ($entry + 8)..)]
    | bytes collect | save $copy
  $copy
}

def main [
  --wad: path                   # the IWAD (default $env.BENDOOM_IWAD)
  --song: string                # a song to play in D_E1M1's place
  --length: duration = 270sec   # audio to record after the first note
  --keep                        # keep the scratch directory and the capture
]: nothing -> record {
  hide-env --ignore-errors LD_LIBRARY_PATH
  let frames = $length / 1sec * 44100 | into int
  let run = scratch
  let wad = $wad | default $env.BENDOOM_IWAD | iwad $run.dir $song
  let game = job spawn {
    cd $run.dir
    with-env $run.sdl {
      ^chocolate-doom -iwad $wad -config default.cfg -extraconfig chocolate-doom.cfg -warp 1 1 -nomonsters -nosfx e> stderr | ignore
    }
  }
  mut first: any = null
  let failed = try {
    loop {
      sleep 1sec
      if $game not-in (job list | get id) { error make {msg: "Chocolate Doom stopped"} }
      let bytes = if ($run.capture | path exists) { ls $run.capture | get 0.size | into int } else { 0 }
      if $first == null and $bytes > 0 { $first = open --raw $run.capture | into binary | lead }
      if $first == null and $bytes > 10 * 44100 * 4 { error make {msg: "no note in the capture's first 10 s"} }
      if $first != null and $bytes >= ($first + $frames) * 4 { break }
    }
  } catch {|e| $e.msg }
  job kill $game
  if $failed != null { error make {msg: $failed} }
  let audio = $run | heard
  {
    frames: (($audio | bytes length) // 4)
    lead: ($audio | lead)
    sides_differ: ($audio | chunks 4 | where {|f| ($f | bytes at 0..1) != ($f | bytes at 2..3) } | length)
  } | kept $run $keep
}

def "main game" [
  --binary: path = ./doom       # the game, built natively: bend doom.bend -o doom
  --wad: path                   # the IWAD (default $env.BENDOOM_IWAD)
  --song: string                # a song to play in D_E1M1's place
  --length: duration = 270sec   # audio to record after the first note
  --keys: string = ""           # keys a space apart, each held a fifth of a second, one a second from the first note
  --keep                        # keep the scratch directory and the capture
]: nothing -> record {
  hide-env --ignore-errors LD_LIBRARY_PATH WAYLAND_DISPLAY
  let binary = $binary | path expand
  let frames = $length / 1sec * 44100 | into int
  let dir = ^mktemp --directory | str trim
  let float = $dir | path join capture.f32
  let socket = $dir | path join native
  let wad = $wad | default $env.BENDOOM_IWAD | iwad $dir $song
  [
    $'pcm.!default { type file; slave.pcm "sink"; file "($float)"; format "raw" }'
    $'pcm.sink { type pulse; server "unix:($socket)" }'
  ] | str join (char newline) | save ($dir | path join alsa.conf)
  mkdir ($dir | path join pulse)
  let failed = try {
    let display = xvfb $dir 1280x960
    job spawn --description $dir {
      $env.DBUS_SESSION_BUS_ADDRESS = "disabled:"
      with-env {HOME: $dir, XDG_RUNTIME_DIR: ($dir | path join pulse), PULSE_RUNTIME_PATH: ($dir | path join pulse),
        PULSE_STATE_PATH: ($dir | path join pulse)} {
        (^pulseaudio -n --daemonize=no --use-pid-file=no --exit-idle-time=-1 --log-target=stderr
          -L "module-null-sink sink_name=capture rate=44100 channels=2"
          -L $"module-native-protocol-unix socket=($socket) auth-anonymous=1") e> ($dir | path join pulse.log)
      }
    } | ignore
    wait-for 100 { $socket | path exists } "PulseAudio did not start"
    let game = job spawn --description $dir {
      with-env {DISPLAY: $display, ALSA_CONFIG_PATH: ($dir | path join alsa.conf), PULSE_SERVER: $"unix:($socket)",
        BENDOOM_IWAD: $wad} {
        ^$binary --threads 1 | complete | to json | save ($dir | path join game.json)
      }
    }
    mut first: any = null
    mut keys = $keys | split row ' ' | where $it != ''
    loop {
      sleep 1sec
      if $game not-in (job list | get id) { break }
      let bytes = if ($float | path exists) { ls $float | get 0.size | into int } else { 0 }
      if $first != null and ($keys | is-not-empty) {
        let key = $keys | first
        with-env {DISPLAY: $display} {
          let window = ^xdotool search --name '^Bendoom$' | lines | first
          ^xdotool keydown --window $window $key
          sleep 200ms
          ^xdotool keyup --window $window $key
        }
        $keys = $keys | skip 1
      }
      if $first == null and $bytes > 0 {
        $first = open --raw $float | into binary | chunks 8 | enumerate | where $it.item != 0x[0000000000000000] | first 1 | get index.0?
      }
      if $first == null and $bytes > 10 * 44100 * 8 { error make {msg: "no note in the capture's first 10 s"} }
      if $first != null and $bytes >= ($first + $frames) * 8 {
        with-env {DISPLAY: $display} {
          let window = ^xdotool search --name '^Bendoom$' | lines | first
          ^xdotool windowfocus --sync $window
          ^xdotool key --window $window Escape
        }
        wait-for 100 { $game not-in (job list | get id) } "the game did not quit"
        break
      }
    }
  } catch {|e| $e.msg }
  process-stop $dir
  if $failed != null { error make {msg: $failed} }
  let ran = open ($dir | path join game.json)
  if $ran.exit_code != 0 { error make {msg: $"the game left with ($ran.exit_code): ($ran.stderr)"} }
  let capture = $dir | path join capture.raw
  ^ffmpeg -loglevel error -f f32le -ar 44100 -ac 2 -i $float -f s16le $capture
  rm $float
  let audio = open --raw $capture | into binary
  let report = {frames: (($audio | bytes length) // 4), lead: ($audio | lead), printed: ($ran.stdout | str trim)}
  if $keep { $report | insert capture $capture } else { rm --recursive $dir; $report }
}

# A capture's 16-bit samples, left and right in turn.
def samples []: binary -> list<int> {
  $in | chunks 2 | each { into int --endian little --signed }
}

# A capture from its first note.
def from-lead []: binary -> binary {
  let audio = $in
  $audio | bytes at (($audio | lead) * 4)..
}

# Where two runs of frames differ, over the shorter: each differing
# sample's index (even left, odd right) and by how much.
def differences [a: binary, b: binary]: nothing -> list<record<at: int, by: int>> {
  let end = [($a | bytes length) ($b | bytes length)] | math min | $in // 4 * 4
  let block = 4096
  seq 0 $block ($end - 1) | each {|at|
    let x = $a | bytes at $at..<([($at + $block) $end] | math min)
    let y = $b | bytes at $at..<([($at + $block) $end] | math min)
    if $x != $y {
      $x | samples | zip ($y | samples) | enumerate
        | each {|p| {at: ($at // 2 + $p.index), by: ($p.item.0 - $p.item.1 | math abs)} } | where by != 0
    }
  } | flatten
}

# Two captures from their first notes, over the shorter: how many
# samples differ and by how much at most, both sides counted.
def "main compare" [a: path, b: path]: nothing -> record {
  let a = open --raw $a | into binary | from-lead
  let b = open --raw $b | into binary | from-lead
  let d = differences $a $b
  {frames: ([($a | bytes length) ($b | bytes length)] | math min | $in // 4), differing: ($d | length),
    largest: ($d | get by | append 0 | math max)}
}

# The frames the device asks for at a time with sound effects on:
# GetSliceSize for 28 ms at 44100 Hz.
const buffer = 1024

# Silence as long as the capture piped in.
def silence []: binary -> binary {
  let length = $in | bytes length
  mut zeros = 0x[00 00 00 00]
  while ($zeros | bytes length) < $length { $zeros = bytes build $zeros $zeros }
  $zeros | bytes at 0..<$length
}

# The sounds in the capture piped in, against silence or a capture of
# the song alone: each one's first frame, how far that is into its
# buffer, its length and its largest difference on each side.
def sounds [against: any]: binary -> table<start: int, into_buffer: int, frames: int, left: int, right: int> {
  let audio = $in
  let reference = if $against == null { $audio | silence } else {
    let song = open --raw $against
    if ($song | lead) != ($audio | lead) {
      error make {msg: $"the song starts at frame ($audio | lead) here and at ($song | lead) in the reference: record one of them again"}
    }
    $song
  }
  let d = differences $audio $reference
  if ($d | is-empty) { return [] }
  let cuts = $d | get at | window 2 | enumerate | where ($it.item.1 // 2 - $it.item.0 // 2) > $buffer | each { $in.index + 1 }
  [0] ++ $cuts | zip ($cuts ++ [($d | length)]) | each {|run|
    let part = $d | slice $run.0..<$run.1
    let start = ($part | first | get at) // 2
    {start: $start, into_buffer: ($start mod $buffer), frames: (($part | last | get at) // 2 - $start + 1),
      left: ($part | where at mod 2 == 0 | get by | append 0 | math max),
      right: ($part | where at mod 2 == 1 | get by | append 0 | math max)}
  }
}

# The sounds in a kept capture.
def "main starts" [capture: path, --against: path]: nothing -> table {
  open --raw $capture | sounds $against
}

def "main sounds" [
  x: int                # the start's x, in map units
  y: int                # the start's y
  angle: int            # its facing in degrees, a multiple of 45
  script: string        # the commands, runs of "count,forward,side,turn,buttons"
  --wad: path           # the IWAD (default $env.BENDOOM_IWAD)
  --map: string = "E1M1" # the map, by its marker
  --things: string = "" # records to rewrite, each "record,type,x,y", facing 0
  --music               # play the song under the sounds
  --against: path       # a capture of the song alone, the reference under --music
  --keep                # keep the scratch directory and the capture
]: nothing -> string {
  hide-env --ignore-errors LD_LIBRARY_PATH
  let wad = $wad | default $env.BENDOOM_IWAD
  let runs = $script | runs
  let run = scratch
  let name = $wad | path basename
  open --raw $wad | placed $map $x $y $angle $things | save ($run.dir | path join $name)
  $runs | tics | demo (header $map) | save ($run.dir | path join script.lmp)
  let limit = ($runs | get tics | math sum) // 35 + 60
  let game = do { cd $run.dir; with-env $run.sdl {
    ^timeout $limit chocolate-doom -iwad $name -playdemo script -config default.cfg -extraconfig chocolate-doom.cfg ...(if $music { [] } else { [-nomusic] }) e> stderr | complete
  } }
  if $game.exit_code != 0 { error make {msg: $"Chocolate Doom left with ($game.exit_code) before the demo's end"} }
  let audio = $run | heard
  {frames: (($audio | bytes length) // 4), sounds: ($audio | sounds $against)} | kept $run $keep | table --expand
}
