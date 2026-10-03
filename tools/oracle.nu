#!/usr/bin/env nu
# Diffs a frame of ours against vanilla's at the same tic of the same
# demo. Chocolate Doom plays the demo, followed by a tic whose buttons
# press pause (BT_SPECIAL with BTS_PAUSE) and a minute of idle tics, in
# real time in a scratch directory, at screen size 10, on a headless X
# server of its own; a paused game runs no playsim tic but keeps reading
# the demo, so the tail holds the frame of the demo's last tic for a
# minute, and one paletted screenshot is taken inside it. A shot counts
# once it shows the pause graphic. It is compared with the frame
# tools/frame.bend dumps after the same demo on the same IWAD, over all
# 200 rows but for the pause graphic and the box the marine's face
# covers: the status bar's ticker runs on while the playsim is paused,
# so the face keeps changing under the screenshot. The report counts
# that box separately, as `face`, which is 0 only where the face holds
# still under the pause, as the dead one does.
#
# The demo is a command script from a place, or the first tics of a
# recorded one. A script is runs a space apart, each
# "count,forward,side,turn,buttons" (tools/demo.nu), played on --map
# (E1M1 when not given) from a copy of the IWAD whose player 1 starts
# at x, y facing angle; the default script idles 20 tics, past the
# pistol's rise. `demo` takes a demo lump of the IWAD, such as DEMO1, or
# a .lmp file, and plays its first tics on the map its header names.
# Bendoom plays Hurt Me Plenty with player 1 alone and no options, and
# a header that asks for anything else is refused. Either way --things
# rewrites the map's records it names in the copy and leaves its other
# things as they are.
#
# --tally compares the tally the exit leads to instead. Its demo takes
# the exit and then idles long enough for WI_updateStats to settle,
# after which the screen stands still until a press, so no pause tic is
# written: its buttons byte carries BT_ATTACK, which
# WI_checkForAccelerate would read as that press, and vanilla would
# leave the counts and load the next level. A shot counts once it shows
# "Finished!" where WI_drawLF puts it, and the mask is the ten
# animations of WIMAP0, which keep turning on the wall clock while the
# shot is taken, and not the bar's face, which the tally covers.
#
# Needs chocolate-doom, Xvfb and xdotool (all in the dev shell) and the
# frame dump built:
#
#   bend tools/frame.bend -o frame
#   tools/oracle.nu -416 256 0
#   tools/oracle.nu -416 256 0 "20,0,0,0,0 34,50,0,0,0" --frame ./frame --keep
#   tools/oracle.nu 832 384 90 "40,25,0,0,0 1,0,0,0,1" --things "35,2035,800,528"
#   tools/oracle.nu -363 1316 180 "1,0,0,16,0 5,0,0,0,0 1,0,0,0,1 250,0,0,0,0" --tally
#   tools/oracle.nu -224 -624 90 --map E1M5 --wad doom1.wad
#   tools/oracle.nu demo DEMO3 300 --wad doom1.wad
#   tools/oracle.nu demo run.lmp 1000

source demo.nu
source xvfb.nu

# The palette indices of a Chocolate Doom screenshot, row by row. It
# writes every byte of 0xc0 and over as 0xc1 then the byte, and no other
# runs, so dropping each marker left to right decodes it.
def pcx-indices []: binary -> list<string> {
  let pcx = $in
  $pcx | bytes at 128..<(($pcx | bytes length) - 769) | encode hex | str lowercase
  | str replace --all --regex '(..)' '$1 '
  | str replace --all --regex 'c1 (..)' '$1'
  | str trim | split row ' '
}

# Vanilla writes PLAYPAL 0 into PCX even when the hardware palette is
# tinted. `palette` reports Bend's selection; checking the tint also
# requires capturing Chocolate Doom's active palette.
def pcx-palette []: binary -> string {
  let pcx = $in
  $pcx | bytes at (($pcx | bytes length) - 768).. | encode hex | str lowercase
}

# A patch's size and where its offsets put it when drawn at x, y.
def patch-box [wad: binary, name: string, x: int, y: int]: nothing -> list<int> {
  let patch = $wad | lumps | where name == $name | last | get pos
  let width = $wad | bytes at $patch..($patch + 1) | into int --endian little
  let height = $wad | bytes at ($patch + 2)..($patch + 3) | into int --endian little
  let left = $x - ($wad | bytes at ($patch + 4)..($patch + 5) | into int --endian little --signed)
  let top = $y - ($wad | bytes at ($patch + 6)..($patch + 7) | into int --endian little --signed)
  0..<$height | each {|r| 0..<$width | each {|c| (($top + $r) * 320 + $left + $c) } } | flatten
}

# wi_stuff.c's epsd0animinfo: where each of WIMAP0's ten animations is
# drawn, three frames apiece.
const anims = [[224 104] [184 160] [112 136] [72 112] [88 96] [64 48] [192 40] [136 16] [80 16] [64 24]]

# Every pixel those animations can cover, which the tally's comparison
# leaves out.
def anim-boxes [wad: binary]: nothing -> list<int> {
  $anims | enumerate | each {|a|
    0..<3 | each {|i| patch-box $wad $"WIA00($a.index)0($i)" ($a.item | get 0) ($a.item | get 1) }
  } | flatten | flatten | uniq
}

# WI_drawLF's "Finished!", centred under the level's name: the pixels
# that say the tally is showing its counts.
def finished [wad: binary]: nothing -> table<at: int, colour: string> {
  let name = $wad | lumps | where name == "WILV00" | last | get pos
  let f = $wad | lumps | where name == "WIF" | last | get pos
  let height = $wad | bytes at ($name + 2)..($name + 3) | into int --endian little
  let width = $wad | bytes at $f..($f + 1) | into int --endian little
  patch-pixels $wad WIF ((320 - $width) // 2) (2 + 5 * $height // 4)
}

# Every frame pixel the marine's face can cover: the box around the
# places ST_loadGraphics' 42 face patches take at the face widget's
# ST_FACESX and ST_FACESY, each less its own offsets.
def face-box [wad: binary]: nothing -> list<int> {
  let names = ((0..4 | each {|i| [$"STFST($i)0", $"STFST($i)1", $"STFST($i)2", $"STFTR($i)0", $"STFTL($i)0",
    $"STFOUCH($i)", $"STFEVL($i)", $"STFKILL($i)"] } | flatten) ++ ["STFGOD0", "STFDEAD0"])
  let boxes = $names | each {|n|
    let found = $wad | lumps | where name == $n
    if ($found | is-empty) { null } else {
      let patch = $found | last | get pos
      let left = 143 - ($wad | bytes at ($patch + 4)..($patch + 5) | into int --endian little --signed)
      let top = 168 - ($wad | bytes at ($patch + 6)..($patch + 7) | into int --endian little --signed)
      {left: $left, top: $top
       right: ($left + ($wad | bytes at $patch..($patch + 1) | into int --endian little) - 1)
       bottom: ($top + ($wad | bytes at ($patch + 2)..($patch + 3) | into int --endian little) - 1)}
    }
  } | compact
  let top = $boxes | get top | math min
  let bottom = $boxes | get bottom | math max
  let left = $boxes | get left | math min
  let right = $boxes | get right | math max
  $top..$bottom | each {|row| $left..$right | each {|col| $row * 320 + $col } } | flatten
}

# Chocolate Doom's frame after the demo's script, paused. It can only
# take a screenshot while it runs, so it runs on an X server of its own
# with no screen, Xvfb, where nothing shows on the desktop and no window
# takes the focus; the server picks its display number and writes it
# out, so runs side by side never share one. Once the script has had
# its time, xdotool presses the screenshot key until a shot shows the
# patch that tells the frame is the one wanted whole: the pause graphic
# the pause froze, or the tally's "Finished!". The config
# sets screen size 10, the full 320 by 168 view over the status bar that
# Bendoom draws (Doom's default 9 borders a 288 by 144 view), and turns
# messages off; the extra config binds F1, scancode 59, to the
# screenshot, since -devparm, which binds it too, writes its frame-rate
# dots over the bar's last row.
def vanilla [iwad: binary, name: string, script: binary, tics: int, told: table<at: int, colour: string>, dir: path]: nothing -> record<indices: list<string>, palette: string> {
  $iwad | save --force ($dir | path join $name)
  $script | save --force ($dir | path join script.lmp)
  "screenblocks 10\nshow_messages 0\n" | save --force ($dir | path join default.cfg)
  "key_menu_screenshot 59\n" | save --force ($dir | path join extra.cfg)
  let display = xvfb $dir 1024x768
  let game = job spawn {
    cd $dir
    hide-env --ignore-errors WAYLAND_DISPLAY
    with-env {HOME: $dir, DISPLAY: $display, SDL_VIDEODRIVER: x11, SDL_AUDIODRIVER: dummy} {
      ^chocolate-doom -iwad $name -playdemo script -config default.cfg -extraconfig extra.cfg -window -nosound | ignore
    }
  }
  let shot = try { with-env {DISPLAY: $display} {
    let opened = 0..<150 | each {|_| sleep 200ms; ^xdotool search --name "Chocolate Doom" | complete | get stdout | lines }
      | where ($it | is-not-empty) | first 1 | flatten
    if ($opened | is-empty) { error make {msg: "Chocolate Doom's window did not open"} }
    sleep (($tics * 1000 / 35 | into int) * 1ms + 2sec)
    0..<40 | each {|n|
      let target = ^xdotool search --name "Chocolate Doom" | lines | last
      ^xdotool keydown --window $target F1
      sleep 30ms
      ^xdotool keyup --window $target F1
      sleep 400ms
      let file = $dir | path join $"DOOM($n | fill --alignment right --character '0' --width 2).pcx"
      if ($file | path exists) {
        let pcx = open --raw $file
        {indices: ($pcx | pcx-indices), palette: ($pcx | pcx-palette)}
      } else { {indices: [], palette: ""} }
    } | where {|shot| ($shot.indices | is-not-empty) and ($told | all {|p| ($shot.indices | get $p.at) == $p.colour }) } | first 1
  } } finally {
    job kill $game
    for id in (job list | where description == $dir | get id) { job kill $id }
  }
  if ($shot | is-empty) { error make {msg: "no screenshot showed the patch asked for"} }
  $shot | first
}

# Our frame and vanilla's after the tics of a demo on the IWAD copy
# given, and where they differ. The run is the flags both commands take.
def compare [
  iwad: binary, header: binary, tics: binary
  run: record<wad: path, frame: path, tally: bool, keep: bool>
]: nothing -> record {
  hide-env --ignore-errors LD_LIBRARY_PATH
  let count = ($tics | bytes length) // 4
  let told = if $run.tally { finished $iwad } else { patch-pixels $iwad M_PAUSE 126 4 }
  let dir = mktemp --directory
  let name = $run.wad | path basename
  let idle = 0..<2100 | each { 0x[00 00 00 00] } | bytes collect
  let tail = if $run.tally { $idle } else { [0x[00 00 00 81] $idle] | bytes collect }
  let shot = vanilla $iwad $name ([$tics $tail] | bytes collect | demo $header) $count $told $dir
  $tics | demo $header | save ($dir | path join ours.lmp)
  let dump = with-env {BENDOOM_IWAD: ($dir | path join $name), DEMO: ($dir | path join ours.lmp)} { ^$run.frame } | lines
  let ours = $dump | skip 1 | each {|row| $row | str replace --all --regex '(..)' '$1 ' | str trim | split row ' ' } | flatten
  let face = face-box $iwad
  let masked = if $run.tally { anim-boxes $iwad } else { ($told | get at) ++ $face }
  let off = 0..<(200 * 320) | where {|i| ($shot.indices | get $i) != ($ours | get $i) }
  let differing = $off | where $it not-in $masked
  let playpal = $iwad | lumps | where name == "PLAYPAL" | last | get pos
  if not $run.keep { rm --recursive $dir }
  {
    differing: ($differing | length)
    face: ($off | where $it in $face | length)
    masked: ($masked | uniq | where $it < 200 * 320 | length)
    palette: ($"0x($dump | first)" | into int)
    shot_plain: ($shot.palette == ($iwad | bytes at $playpal..($playpal + 767) | encode hex | str lowercase))
    first: ($differing | first 5 | each {|i| {x: ($i mod 320), y: ($i // 320), vanilla: ($shot.indices | get $i), ours: ($ours | get $i)} })
    scratch: (if $run.keep { $dir } else { null })
  }
}

def main [
  x: int                                   # the start's x, in map units
  y: int                                   # the start's y
  angle: int                               # its facing in degrees, a multiple of 45
  script: string = "20,0,0,0,0"            # the commands, runs of "count,forward,side,turn,buttons"
  --wad: path                              # the IWAD (default $env.BENDOOM_IWAD)
  --map: string = "E1M1"                   # the map, by its marker
  --things: string = ""                    # records to rewrite, each "record,type,x,y", facing 0
  --frame: path = ./frame                  # the frame dump, built from tools/frame.bend
  --tally                                  # the script takes the exit: compare the tally it leads to
  --keep                                   # keep the scratch directory
]: nothing -> record {
  let wad = $wad | default $env.BENDOOM_IWAD
  let iwad = open --raw $wad | placed $map $x $y $angle $things
  {map: $map, place: $"($x) ($y) ($angle)", script: $script}
  | merge (compare $iwad (header $map) ($script | runs | tics) {wad: $wad, frame: $frame, tally: $tally, keep: $keep})
}

# The first tics of a recorded demo.
def "main demo" [
  demo: string                             # a demo lump of the IWAD, such as DEMO1, or a .lmp file
  tic: int                                 # the tics to play: the frame compared is the one after them
  --wad: path                              # the IWAD (default $env.BENDOOM_IWAD)
  --things: string = ""                    # records to rewrite, each "record,type,x,y", facing 0
  --frame: path = ./frame                  # the frame dump, built from tools/frame.bend
  --tally                                  # the tics take the exit: compare the tally they lead to
  --keep                                   # keep the scratch directory
]: nothing -> record {
  let wad = $wad | default $env.BENDOOM_IWAD
  let bytes = open --raw $wad
  let lump = $bytes | lumps | where name == $demo | last 1 | get 0?
  let lmp = if ($demo | path exists) { open --raw $demo | into binary } else if $lump != null {
    $bytes | bytes at $lump.pos..<($lump.pos + $lump.size)
  } else { error make {msg: $"($demo) is neither a file nor a lump of ($wad)"} }
  let header = $lmp | bytes at 0..12
  let map = $header | header-map
  if $header != (header $map) {
    error make {msg: $"($demo)'s header ($header | encode hex) is not one Bendoom plays, (header $map | encode hex)"}
  }
  let length = $lmp | bytes at 13.. | chunks 4 | enumerate | where ($it.item | bytes at 0..0) == 0x[80] | get index.0?
  if $length == null { error make {msg: $"($demo) has no end marker, 0x80"} }
  if $tic > $length { error make {msg: $"($demo) ends after ($length) tics"} }
  {demo: $demo, map: $map, tic: $tic}
  | merge (compare ($bytes | retyped $map $things) $header ($lmp | bytes at 13..<(13 + 4 * $tic))
    {wad: $wad, frame: $frame, tally: $tally, keep: $keep})
}
