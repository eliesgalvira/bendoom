#!/usr/bin/env nu

source xvfb.nu

def has-audio [file: path]: nothing -> bool {
  ($file | path exists) and ((open --raw $file | into binary | bytes remove --all 0x[00] | bytes length) > 0)
}

def check-archive [archive: path, audio: string] {
  let dir = mktemp --directory
  let capture = $dir | path join audio.raw
  let result = $dir | path join result.json
  let alsa = $dir | path join alsa.conf
  try {
    mkdir ($dir | path join game)
    ^tar -xzf $archive -C ($dir | path join game)
    'pcm.!default { type null }' | save $alsa
    let name = $"bendoom_smoke_($nu.pid)"
    let sink = if $audio != "null" {
      ^pactl load-module module-null-sink $"sink_name=($name)" rate=44100 channels=2 | str trim
    } else { null }
    try {
      if $audio != "null" {
        let target = if $audio == "pipewire" { "playback_node" } else { "device" }
        $'pcm.!default { type ($audio) ($target) "($name)" }' | save --force $alsa
        job spawn --description $dir {
          ^parec $"--device=($name).monitor" --raw --format=s16le --rate=44100 --channels=2 --latency-msec=10 o> $capture
        } | ignore
      }
      let display = xvfb $dir 1280x960
      let game = job spawn --description $dir {
        hide-env --ignore-errors WAYLAND_DISPLAY BENDOOM_IWAD ALSA_PLUGIN_DIR
        with-env {DISPLAY: $display} {
          (^bwrap --ro-bind / / --dev-bind /dev /dev --proc /proc --tmpfs /nix
            --bind $dir $dir --die-with-parent
            --setenv ALSA_CONFIG_PATH $alsa --setenv RECORD ($dir | path join run.lmp)
            ($dir | path join game bendoom)) | complete | to json | save $result
        }
      }
      with-env {DISPLAY: $display} {
        wait-for 200 {
          if $game not-in (job list | get id) { error make {msg: $"Game stopped: (open $result | get stderr)"} }
          (^xdotool search --onlyvisible --name '^Bendoom$' | complete | get stdout | str trim) != ""
        } "Bendoom's window did not open"
        let window = ^xdotool search --onlyvisible --name '^Bendoom$' | lines | first
        ^xdotool windowfocus --sync $window
        ^xdotool keydown --window $window Up
        sleep 1sec
        ^xdotool keyup --window $window Up
        if $audio != "null" { wait-for 100 { has-audio $capture } "No audio reached the private sink" }
        ^xdotool key --window $window Escape
      }
      wait-for 100 { $game not-in (job list | get id) } "Bendoom did not exit"
      let exited = open $result
      if $exited.exit_code != 0 { error make {msg: $exited.stderr} }
      if $audio != "null" { print $"PASS ($audio) audio: nonzero PCM from the private sink" }
      let demo = open --raw ($dir | path join run.lmp) | into binary
      let bytes = $demo | bytes length
      if not ($demo | bytes starts-with 0x[6d]) or not ($demo | bytes ends-with 0x[80]) or $bytes <= 14 or ($bytes - 14) mod 4 != 0 {
        error make {msg: "Invalid recorded demo"}
      }
      print $"PASS without /nix: window, assets, movement, recording and clean exit, ($bytes) demo bytes"
    } finally {
      process-stop $dir
      if $sink != null { ^pactl unload-module $sink }
    }
  } finally {
    rm --recursive $dir
  }
}

def main [...archives: path, --audio: string = "null"] {
  if $audio not-in ["null" pulse pipewire] { error make {msg: "--audio must be null, pulse or pipewire"} }
  if ($archives | is-empty) { error make {msg: "Provide at least one portable archive"} }
  for archive in $archives { check-archive $archive $audio }
}
