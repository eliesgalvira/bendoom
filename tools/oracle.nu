#!/usr/bin/env nu
# Compares a frame after the same demo commands on the same IWAD.
# Scripts contain space-separated "count,forward,side,turn,buttons" runs
# (tools/demo.nu); --map defaults to E1M1. G_PlayerReborn leaves attack
# and use held, so either on the first command does nothing.
#
# The default Chocolate lane pauses the level, or waits on an intermission,
# and takes a PCX on a private X server. It masks the pause graphic and
# moving face on levels, and WIMAP0 animations on intermissions.
# --capture supplies a diagnostic Chocolate binary that writes its normal
# D_Display output at exactly the requested command. --unmasked compares
# all 64000 pixels and requires that lane. An undrawn command is unavailable.
# Palette reports Bend's selection; the raw/PCX palette is PLAYPAL 0.
#
# Build tools/frame.bend first. Examples:
#   tools/oracle.nu -416 256 0 --frame ./frame
#   tools/oracle.nu -224 -624 90 --map E1M5 --wad doom1.wad
#   tools/oracle.nu demo DEMO3 300 --wad doom1.wad
# --things rewrites only the named THINGS records in the oracle's WAD copy.
# Both engines play Hurt Me Plenty, player 1 alone, without demo options.

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
  let patch = $wad | lump-pos $name
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

# The pixels of a patch centred across the screen at y, as WI_drawLF
# and WI_drawEL centre theirs.
def centred [wad: binary, name: string, y: int]: nothing -> table<at: int, colour: string> {
  let p = $wad | lump-pos $name
  patch-pixels $wad $name ((320 - ($wad | bytes at $p..($p + 1) | into int --endian little)) // 2) $y
}

# The name of map m of episode 1, WILV00 for E1M1.
def level-name [m: int]: nothing -> string { $"WILV0($m - 1)" }

# The row under a name where WI_drawLF and WI_drawEL draw the next
# patch: a name and a quarter down from the title's row.
def under [wad: binary, name: string]: nothing -> int {
  let p = $wad | lump-pos $name
  2 + 5 * ($wad | bytes at ($p + 2)..($p + 3) | into int --endian little) // 4
}

# WI_drawLF's "Finished!", centred under the name of map m: the pixels
# that say the tally is showing its counts.
def finished [wad: binary, m: int]: nothing -> table<at: int, colour: string> {
  centred $wad WIF (under $wad (level-name $m))
}

# wi_stuff.c's lnodes[0]: where each map of episode 1 stands on WIMAP0.
const lnodes = [[185 164] [148 143] [69 122] [209 102] [116 89] [166 55] [71 56] [135 29] [71 24]]

# WI_drawEL's "Entering" and the name of the map after map m, and the
# pointer WI_drawShowNextLoc puts on that map's place where the two
# words, drawn after it, leave it showing: the pixels that say the map
# screen shows with its pointer on. WIURH0 fits at every place of
# episode 1, so WI_drawOnLnode never tries WIURH1 there.
def entering [wad: binary, m: int]: nothing -> table<at: int, colour: string> {
  let next = if $m == 9 { 4 } else { $m + 1 }
  let name = level-name $next
  let words = (centred $wad WIENTER 2) ++ (centred $wad $name (under $wad $name))
  let node = $lnodes | get ($next - 1)
  let covered = $words | get at
  $words ++ (patch-pixels $wad WIURH0 $node.0 $node.1 | where at not-in $covered)
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
# the pause froze, the tally's "Finished!" or the map screen's words and
# pointer. The config sets screen size 10, the full 320 by 168 view over
# the status bar that Bendoom draws (Doom's default 9 borders a 288 by
# 144 view), and shows messages only with --messages; the extra config binds F1,
# scancode 59, to the screenshot, since -devparm, which binds it too,
# writes its frame-rate dots over the bar's last row.
def vanilla [iwad: binary, name: string, script: binary, tics: int, told: table<at: int, colour: string>, dir: path, messages: bool]: nothing -> record<indices: list<string>, palette: string> {
  $iwad | save --force ($dir | path join $name)
  $script | save --force ($dir | path join script.lmp)
  $"screenblocks 10\nshow_messages (if $messages { 1 } else { 0 })\n" | save --force ($dir | path join default.cfg)
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

# A diagnostic Chocolate Doom build can dump I_VideoBuffer after D_Display
# at the requested demo command. It consumes the normal melt and sound
# draws, and changes no game logic. Its raw dump avoids wall-clock animation
# and face drift when comparing the pixels normally masked below.
# Official timedemo mode supplies one command per frame; undrawn tics
# are rejected by the diagnostic binary rather than drawing extra frames.
def captured [iwad: binary, name: string, script: binary, count: int, binary: path, screen: string, dir: path, messages: bool]: nothing -> record<indices: list<string>, palette: string> {
  $iwad | save --force ($dir | path join $name)
  $script | save --force ($dir | path join script.lmp)
  $"screenblocks 10\nshow_messages (if $messages { 1 } else { 0 })\n" | save --force ($dir | path join default.cfg)
  "show_endoom 0\n" | save --force ($dir | path join extra.cfg)
  let target = $dir | path join frame.raw
  let result = try {
    let display = xvfb $dir 1024x768
    cd $dir
    hide-env --ignore-errors WAYLAND_DISPLAY
    with-env {XDG_DATA_HOME: $dir, DISPLAY: $display, SDL_VIDEODRIVER: x11, SDL_AUDIODRIVER: dummy,
      BENDOOM_CAPTURE_TIC: ($count | into string), BENDOOM_CAPTURE_FRAME: $target} {
      ^$binary -iwad $name -timedemo script -config default.cfg -extraconfig extra.cfg -window -nosound o> ($dir | path join capture.log) e> ($dir | path join trace.log)
    }
    let trace = open --raw ($dir | path join trace.log)
    let frames = $trace | lines | parse 'CAPTURE tic {tic} gamestate {gamestate} wi {wi}'
    if ($frames | is-empty) { error make {msg: $"Chocolate did not capture command ($count): ($trace | lines | last)"} }
    let scene = $frames | first
    let finale = $trace | lines | parse 'FINALE tic {tic} stage {stage} count {count}'
    let right = match $screen {
      level => ($scene.gamestate == "0")
      tally => ($scene.gamestate == "1" and $scene.wi == "0")
      entering => ($scene.gamestate == "1" and $scene.wi in ["1" "-1"])
      finale-text => ($scene.gamestate == "2" and ($finale | get 0.stage?) == "0")
      finale-art => ($scene.gamestate == "2" and ($finale | get 0.stage?) == "1")
    }
    if not $right { error make {msg: $"captured frame is not ($screen): ($scene)"} }
    let raw = open --raw $target | into binary
    if ($raw | bytes length) != 64000 { error make {msg: "capture is not a 320 by 200 frame"} }
    let playpal = $iwad | lump-pos PLAYPAL
    {indices: ($raw | encode hex | str lowercase | str replace --all --regex '(..)' '$1 ' | str trim | split row ' '),
      palette: ($iwad | bytes at $playpal..($playpal + 767) | encode hex | str lowercase)}
  } finally {
    for id in (job list | where description == $dir | get id | reverse) { job kill $id }
  }
  $result
}

# Our frame and vanilla's after the tics of a demo on the IWAD copy
# given, and where they differ. The run is the flags both commands take.
def compare [
  iwad: binary, header: binary, tics: binary
  run: record<wad: path, frame: path, screen: string, keep: bool, capture: string, unmasked: bool, messages: bool>
]: nothing -> record {
  if $run.unmasked and $run.capture == "" { error make {msg: "--unmasked requires a tic-exact --capture binary"} }
  if ($run.screen | str starts-with "finale-") and (not $run.unmasked or $run.capture == "") {
    error make {msg: "finale frames require --capture and --unmasked"}
  }
  let capture = if $run.capture == "" { "" } else { $run.capture | path expand }
  hide-env --ignore-errors LD_LIBRARY_PATH
  let count = ($tics | bytes length) // 4
  let m = $header | bytes at 3..3 | into int
  let told = match $run.screen {
    tally => (finished $iwad $m)
    entering => (entering $iwad $m)
    level => (patch-pixels $iwad M_PAUSE 126 4)
    finale-text | finale-art => []
    _ => (error make {msg: $"--screen ($run.screen) is none of level, tally, entering, finale-text or finale-art"})
  }
  let inter = $run.screen != level
  let scratch = pwd | path join research oracle
  mkdir $scratch
  let dir = mktemp --directory --tmpdir-path $scratch oracle.XXXXXX
  let name = $run.wad | path basename
  let idle = 0..<2100 | each { 0x[00 00 00 00] } | bytes collect
  let tail = if $inter { $idle } else { [0x[00 00 00 81] $idle] | bytes collect }
  let shot = if $run.capture == "" {
    vanilla $iwad $name ([$tics $tail] | bytes collect | demo $header) $count $told $dir $run.messages
  } else { captured $iwad $name ([$tics $idle] | bytes collect | demo $header) $count $capture $run.screen $dir $run.messages }
  $tics | demo $header | save ($dir | path join ours.lmp)
  let dump = with-env {BENDOOM_IWAD: ($dir | path join $name), DEMO: ($dir | path join ours.lmp), BENDOOM_MESSAGES: (if $run.messages { "1" } else { "0" })} { ^$run.frame } | lines
  if $run.keep { $dump | str join "\n" | save --force ($dir | path join ours.hex) }
  let ours = $dump | skip 1 | each {|row| $row | str replace --all --regex '(..)' '$1 ' | str trim | split row ' ' } | flatten
  let face = face-box $iwad
  let masked = if $run.unmasked { [] } else if $inter { anim-boxes $iwad } else { ($told | get at) ++ $face }
  let off = 0..<(200 * 320) | where {|i| ($shot.indices | get $i) != ($ours | get $i) }
  let differing = $off | where $it not-in $masked
  let playpal = $iwad | lump-pos PLAYPAL
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
  --screen: string = "level"              # level, tally, entering, finale-text or finale-art
  --capture: string = ""                  # diagnostic Chocolate binary with tic-exact raw capture
  --unmasked                               # include animations and the face; requires --capture
  --messages                               # show messages in both engines
  --keep                                   # keep the scratch directory
]: nothing -> record {
  let wad = $wad | default $env.BENDOOM_IWAD
  let iwad = open --raw $wad | placed $map $x $y $angle $things
  {map: $map, place: $"($x) ($y) ($angle)", script: $script}
  | merge (compare $iwad (header $map) ($script | runs | tics) {wad: $wad, frame: $frame, screen: $screen, keep: $keep, capture: $capture, unmasked: $unmasked, messages: $messages})
}

# The first tics of a recorded demo.
def "main demo" [
  demo: string                             # a demo lump of the IWAD, such as DEMO1, or a .lmp file
  tic: int                                 # the tics to play: the frame compared is the one after them
  --wad: path                              # the IWAD (default $env.BENDOOM_IWAD)
  --things: string = ""                    # records to rewrite, each "record,type,x,y", facing 0
  --frame: path = ./frame                  # the frame dump, built from tools/frame.bend
  --screen: string = "level"              # level, tally, entering, finale-text or finale-art
  --capture: string = ""                  # diagnostic Chocolate binary with tic-exact raw capture
  --unmasked                               # include animations and the face; requires --capture
  --messages                               # show messages in both engines
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
    {wad: $wad, frame: $frame, screen: $screen, keep: $keep, capture: $capture, unmasked: $unmasked, messages: $messages})
}
