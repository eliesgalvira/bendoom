# A WAD as tables, for working out expected values before the code
# answers: the lump directory, a map's lines, sides, sectors, vertices
# and things, the sector under a point, the events of its song, the
# WAD's sounds, and the pixels a patch draws. --map names the map, E1M1
# when not given.
#
#   nu -c 'source tools/wad.nu; open --raw $env.BENDOOM_IWAD | linedefs | where special != 0'
#   nu -c 'source tools/wad.nu; open --raw $env.BENDOOM_IWAD | things --map E1M5 | where type == 1'
#   nu -c 'source tools/wad.nu; open --raw $env.BENDOOM_IWAD | song-events | song-counts'
#   nu -c 'source tools/wad.nu; open --raw $env.BENDOOM_IWAD | sound-lumps'

# A WAD's directory.
def lumps []: binary -> table<name: string, pos: int, size: int> {
  let wad = $in
  let count = $wad | bytes at 4..7 | into int --endian little
  let dir = $wad | bytes at 8..11 | into int --endian little
  0..<$count | each {|i|
    let at = $dir + $i * 16
    {
      name: ($wad | bytes at ($at + 8)..($at + 15) | decode utf-8 | str trim --char (char nul))
      pos: ($wad | bytes at $at..($at + 3) | into int --endian little)
      size: ($wad | bytes at ($at + 4)..($at + 7) | into int --endian little)
    }
  }
}

# Where the last lump of a name starts, the one W_GetNumForName finds.
def lump-pos [name: string]: binary -> int {
  $in | lumps | where name == $name | last | get pos
}

# The lump of a name after a map's marker.
def map-lump [map: string, name: string]: binary -> record<name: string, pos: int, size: int> {
  let all = $in | lumps | enumerate | flatten
  let marker = $all | where name == $map | first | get index
  $all | where index > $marker and name == $name | first | select name pos size
}

def word [at: int, --signed]: binary -> int {
  let two = $in | bytes at $at..($at + 1)
  if $signed { $two | into int --endian little --signed } else { $two | into int --endian little }
}

def name8 [at: int]: binary -> string {
  $in | bytes at $at..($at + 7) | decode utf-8 | str trim --char (char nul)
}

def linedefs [--map: string = "E1M1"]: binary -> table {
  let wad = $in
  let l = $wad | map-lump $map LINEDEFS
  0..<($l.size // 14) | each {|i| let at = $l.pos + $i * 14
    {i: $i, v1: ($wad | word $at), v2: ($wad | word ($at + 2)), flags: ($wad | word ($at + 4)), special: ($wad | word ($at + 6)),
      tag: ($wad | word ($at + 8)), front: ($wad | word ($at + 10)), back: ($wad | word ($at + 12))} }
}

def sidedefs [--map: string = "E1M1"]: binary -> table {
  let wad = $in
  let l = $wad | map-lump $map SIDEDEFS
  0..<($l.size // 30) | each {|i| let at = $l.pos + $i * 30
    {i: $i, xoff: ($wad | word $at --signed), yoff: ($wad | word ($at + 2) --signed), top: ($wad | name8 ($at + 4)),
      bottom: ($wad | name8 ($at + 12)), mid: ($wad | name8 ($at + 20)), sector: ($wad | word ($at + 28))} }
}

def sectordefs [--map: string = "E1M1"]: binary -> table {
  let wad = $in
  let l = $wad | map-lump $map SECTORS
  0..<($l.size // 26) | each {|i| let at = $l.pos + $i * 26
    {i: $i, floor: ($wad | word $at --signed), ceil: ($wad | word ($at + 2) --signed), floorpic: ($wad | name8 ($at + 4)),
      ceilpic: ($wad | name8 ($at + 12)), light: ($wad | word ($at + 20)), special: ($wad | word ($at + 22)), tag: ($wad | word ($at + 24))} }
}

def vertexes [--map: string = "E1M1"]: binary -> table {
  let wad = $in
  let l = $wad | map-lump $map VERTEXES
  0..<($l.size // 4) | each {|i| {i: $i, x: ($wad | word ($l.pos + $i * 4) --signed), y: ($wad | word ($l.pos + $i * 4 + 2) --signed)} }
}

def things [--map: string = "E1M1"]: binary -> table {
  let wad = $in
  let l = $wad | map-lump $map THINGS
  0..<($l.size // 10) | each {|i| let at = $l.pos + $i * 10
    {i: $i, x: ($wad | word $at --signed), y: ($wad | word ($at + 2) --signed), angle: ($wad | word ($at + 4)),
      type: ($wad | word ($at + 6)), options: ($wad | word ($at + 8))} }
}

# The map's BSP and what a subsector stands in, for sector-at.
def bsp [--map: string = "E1M1"]: binary -> record {
  let wad = $in
  let n = $wad | map-lump $map NODES
  let ss = $wad | map-lump $map SSECTORS
  let sg = $wad | map-lump $map SEGS
  let lines = $wad | linedefs --map $map
  let sides = $wad | sidedefs --map $map
  {
    nodes: (0..<($n.size // 28) | each {|i| let at = $n.pos + $i * 28
      {x: ($wad | word $at --signed), y: ($wad | word ($at + 2) --signed), dx: ($wad | word ($at + 4) --signed),
        dy: ($wad | word ($at + 6) --signed), right: ($wad | word ($at + 24)), left: ($wad | word ($at + 26))} })
    sectors: (0..<($ss.size // 4) | each {|i| let seg = $sg.pos + ($wad | word ($ss.pos + $i * 4 + 2)) * 12
      let line = $lines | get ($wad | word ($seg + 6))
      $sides | get (if ($wad | word ($seg + 8)) == 0 { $line.front } else { $line.back }) | get sector })
  }
}

# Doom's R_PointOnSide for a point in whole map units: 1 on the back.
def point-on-side [x: int, y: int, node: record]: nothing -> int {
  if $node.dx == 0 {
    if $x <= $node.x { $node.dy > 0 | into int } else { $node.dy < 0 | into int }
  } else if $node.dy == 0 {
    if $y <= $node.y { $node.dx < 0 | into int } else { $node.dx > 0 | into int }
  } else {
    let dx = $x - $node.x
    let dy = $y - $node.y
    if ([($node.dy < 0) ($node.dx < 0) ($dx < 0) ($dy < 0)] | where $it | length) mod 2 == 1 {
      if ($node.dy < 0) != ($dx < 0) { 1 } else { 0 }
    } else if $dy * $node.dx < $node.dy * $dx { 0 } else { 1 }
  }
}

# Doom's R_PointInSubsector, answered with the subsector's sector.
def sector-at [x: int, y: int]: record -> int {
  let bsp = $in
  mut n = ($bsp.nodes | length) - 1
  while $n < 32768 {
    let node = $bsp.nodes | get $n
    $n = if (point-on-side $x $y $node) == 1 { $node.left } else { $node.right }
  }
  $bsp.sectors | get ($n - 32768)
}

# A channel event's name, by its status's high nibble from 0x80.
const channel_kinds = [off on touch controller program pressure bend]

# mus2mid.c's controller_map.
const mus_controllers = [0 32 1 7 10 11 91 93 64 67 120 123 126 127 121]

def bytes-list []: binary -> list<int> {
  $in | chunks 1 | each { into int }
}

# A variable-length quantity at $pos: seven bits a byte, the top bit set
# on all but the last. The value and the byte after it.
def vlq [b: list<int>, pos: int]: nothing -> record<val: int, pos: int> {
  mut val = 0
  mut at = $pos
  mut more = true
  while $more {
    let t = $b | get $at
    $at += 1
    $val = $val * 128 + ($t | bits and 127)
    $more = $t >= 128
  }
  {val: $val, pos: $at}
}

# A MUS lump's events as mus2mid.c converts them to one MIDI track: MUS
# channel 15 on MIDI's 9, the others on MIDI channels in the order of
# their first use, skipping 9, each sent an all-notes-off at that first
# use; the last velocity kept a channel; a group's delay before the next.
def mus-events []: binary -> table {
  let lump = $in
  let b = $lump | bytes at ($lump | word 6).. | bytes-list
  mut i = 0
  mut delta = 0
  mut chans = []
  mut vels = 0..15 | each { 127 }
  mut out = []
  loop {
    let d = $b | get $i
    $i += 1
    let c = $d | bits and 15
    mut ch = 9
    if $c != 15 {
      let at = $chans | enumerate | where item == $c | get index.0?
      let n = if $at == null { $chans | length } else { $at }
      $ch = if $n >= 9 { $n + 1 } else { $n }
      if $at == null {
        $chans = $chans | append $c
        $out = $out | append {delta: $delta kind: controller ch: $ch p1: 123 p2: 0}
        $delta = 0
      }
    }
    let op = $d | bits and 0x70
    if $op == 0x60 {
      $out = $out | append {delta: $delta kind: end ch: null p1: null p2: null}
      break
    }
    let x = $b | get $i
    $i += 1
    let event = if $op == 0x00 {
      {kind: off p1: ($x | bits and 127) p2: 0}
    } else if $op == 0x10 {
      if ($x | bits and 128) != 0 {
        $vels = $vels | update $ch (($b | get $i) | bits and 127)
        $i += 1
      }
      {kind: on p1: ($x | bits and 127) p2: ($vels | get $ch)}
    } else if $op == 0x20 {
      {kind: bend p1: (($x | bits and 1) * 64) p2: ($x | bits shr 1)}
    } else if $op == 0x30 and $x >= 10 and $x <= 14 {
      {kind: controller p1: ($mus_controllers | get $x) p2: 0}
    } else if $op == 0x40 and $x <= 9 {
      let v = $b | get $i
      $i += 1
      if $x == 0 { {kind: program p1: ($v | bits and 127) p2: 0} } else {
        {kind: controller p1: ($mus_controllers | get $x) p2: ([$v 127] | math min)}
      }
    } else {
      error make {msg: $"mus2mid.c refuses descriptor ($d) at score byte ($i - 2)"}
    }
    $out = $out | append ({delta: $delta ch: $ch} | merge $event)
    $delta = 0
    if ($d | bits and 128) != 0 {
      let delay = vlq $b $i
      $delta = $delay.val
      $i = $delay.pos
    }
  }
  $out | each { insert track 0 }
}

# A MIDI lump's events as midifile.c reads them: each track from after
# its header to its end-of-track, a data byte in a status's place
# repeating the last status.
def midi-events []: binary -> table {
  let lump = $in
  let b = $lump | bytes-list
  let tracks = $lump | bytes at 10..11 | into int --endian big
  mut pos = 14
  mut out = []
  for track in 0..<$tracks {
    $pos += 8
    mut status = 0
    mut done = false
    while not $done {
      let time = vlq $b $pos
      let delta = $time.val
      $pos = $time.pos
      if ($b | get $pos) >= 128 {
        $status = $b | get $pos
        $pos += 1
      }
      mut event: any = {kind: other ch: null p1: null p2: null}
      if $status == 0xFF or $status == 0xF0 or $status == 0xF7 {
        let meta = if $status == 0xFF { $pos += 1; $b | get ($pos - 1) } else { null }
        let len = vlq $b $pos
        let n = $len.val
        $pos = $len.pos
        if $meta == 0x2F {
          $event.kind = "end"
          $done = true
        } else if $meta == 0x51 and $n == 3 {
          $event.kind = "tempo"
          $event.p1 = $lump | bytes at $pos..($pos + 2) | into int --endian big
        }
        $pos += $n
      } else {
        let program = ($status | bits and 0xE0) == 0xC0
        $event = {
          kind: ($channel_kinds | get (($status | bits shr 4) - 8))
          ch: ($status | bits and 15)
          p1: ($b | get $pos)
          p2: (if $program { 0 } else { $b | get ($pos + 1) })
        }
        $pos += if $program { 1 } else { 2 }
      }
      $out = $out | append ({track: $track delta: $delta} | merge $event)
    }
  }
  $out
}

# A map's song as the events Chocolate Doom's player reads, a row each.
def song-events [--map: string = "E1M1"]: binary -> table {
  let wad = $in
  let l = $wad | lumps | where name == $"D_($map)" | first
  let song = $wad | bytes at $l.pos..<($l.pos + $l.size)
  if ($song | bytes at 0..3) == 0x[4D55531A] { $song | mus-events } else { $song | midi-events }
}

# The song's length in ticks, its longest track's, and its events by
# kind, in the order tests/music.bend prints them.
def song-counts []: table -> string {
  let events = $in
  let ticks = $events | group-by track | values | each { get delta | math sum } | math max
  let counts = $channel_kinds | append [tempo end other] | each {|k| $"($k) ($events | where kind == $k | length)" }
  $"song ticks ($ticks) events ($events | length) ($counts | str join ' ')"
}

# The WAD's digital sounds as Chocolate Doom's CacheSFX reads them: each
# DS lump's rate, the samples it plays (the header's length less the 16
# bytes DMX skips at either end), whether it is played at all (format 3,
# a length over 48 that fits the lump), and the path ExpandSoundData_SDL
# takes to 44100 Hz: SDL's converter where 44100 is the rate times a
# power of two, its own nearest-sample loop and low-pass filter where
# not.
def sound-lumps []: binary -> table<name: string, rate: int, samples: int, played: bool, path: string> {
  let wad = $in
  $wad | lumps | where name starts-with DS | each {|l|
    let rate = $wad | word ($l.pos + 2)
    let length = $wad | bytes at ($l.pos + 4)..($l.pos + 7) | into int --endian little
    {
      name: $l.name, rate: $rate, samples: ($length - 32)
      played: ($l.size >= 8 and ($wad | word $l.pos) == 3 and $length <= $l.size - 8 and $length > 48)
      path: (if 44100 mod $rate == 0 and 44100 // $rate in [1 2 4] { "SDL" } else { "nearest" })
    }
  }
}

# The posts of the patch column whose first is at the offset piped in:
# each one's first row in the patch, its length, and where its pixels
# start, up to the column's 255.
def posts [wad: binary]: int -> table<delta: int, length: int, pixels: int> {
  let first = $in
  generate {|at|
    let delta = $wad | bytes at $at..$at | into int
    if $delta != 255 {
      let length = $wad | bytes at ($at + 1)..($at + 1) | into int
      {out: {delta: $delta, length: $length, pixels: ($at + 3)}, next: ($at + $length + 4)}
    }
  } $first
}

# The pixels a patch covers when drawn at x, y, its offsets taken off as
# V_DrawPatch takes them: each one's frame index and colour.
def patch-pixels [wad: binary, name: string, x: int, y: int]: nothing -> table<at: int, colour: string> {
  let patch = $wad | lump-pos $name
  let width = $wad | bytes at $patch..($patch + 1) | into int --endian little
  let left = $x - ($wad | bytes at ($patch + 4)..($patch + 5) | into int --endian little --signed)
  let top = $y - ($wad | bytes at ($patch + 6)..($patch + 7) | into int --endian little --signed)
  0..<$width | each {|c|
    $patch + ($wad | bytes at ($patch + 8 + $c * 4)..($patch + 11 + $c * 4) | into int --endian little)
    | posts $wad
    | each {|post| 0..<$post.length | each {|k| {
        at: (($top + $post.delta + $k) * 320 + $left + $c)
        colour: ($wad | bytes at ($post.pixels + $k)..($post.pixels + $k) | encode hex | str lowercase)
      } } }
  } | flatten | flatten
}

# hu_lib.c's HUlib_drawTextLine at HU_MSGX, HU_MSGY for a message: the
# pixels the WAD's heads-up font draws, each one's frame index and
# colour. A character is upper-cased; one from '!' to '_' draws its
# STCFN patch and moves the line on by the patch's width, and any other,
# the space among them, moves it on by 4; the line stops at the screen's
# edge.
def hu-line [text: string]: binary -> table<at: int, colour: string> {
  let wad = $in
  let placed = $text | split chars | reduce --fold {x: 0, stop: false, on: []} {|c, st|
    let u = $c | str uppercase | into binary | bytes at 0..0 | into int
    let glyph = $u >= 33 and $u <= 95
    let name = $"STCFN0($u)"
    let w = if $glyph { $wad | word ($wad | lump-pos $name) } else { 4 }
    let fits = $st.x + $w <= 320
    if $st.stop {
      $st
    } else if $glyph and $fits {
      {x: ($st.x + $w), stop: false, on: ($st.on | append {name: $name, x: $st.x})}
    } else if $glyph {
      {x: $st.x, stop: true, on: $st.on}
    } else {
      {x: ($st.x + 4), stop: ($st.x + 4 >= 320), on: $st.on}
    }
  }
  $placed.on | each {|g| patch-pixels $wad $g.name $g.x 0 } | flatten
}
