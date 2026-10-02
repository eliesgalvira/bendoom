# S_AdjustSoundParams replayed over vanilla's tables.c, for working out a
# sound's expected volume and separation before the Bend code answers:
# R_PointToAngle2 by octant and SlopeDiv, s_sound.c's distance, volume at
# snd_SfxVolume 64 and separation, and P_GroupLines' soundorg, the middle
# of the box of a sector's lines.
#
#   nu -c 'source tools/wad.nu; source tools/sound.nu
#     let t = tables /path/to/chocolate-doom/src/tables.c
#     heard $t 832.0 423.0 90.0 (open --raw $env.BENDOOM_IWAD | soundorg 10)'
#
# Places are map units, as the tests print them; angles are degrees.

const two32 = 4294967296

# The fine sine and arctangent tables of a tables.c.
def tables [tables_c: path]: nothing -> record<finesine: list<int>, tantoangle: list<int>> {
  let src = open --raw $tables_c
  let of = {|name, size|
    let pattern = ['(?s)' $name '\[' $size '\]\s*=\s*\{(?<body>.*?)\};'] | str join
    $src | parse --regex $pattern | get body.0 | parse --regex '(?<v>-?\d+)' | get v | into int
  }
  {finesine: (do $of finesine 10240), tantoangle: (do $of tantoangle 2049)}
}

def fixed [units: float]: nothing -> int {
  $units * 65536 | math round | into int
}

def slope-div [num: int, den: int]: nothing -> int {
  if $den < 512 { 2048 } else { [((($num * 8) mod $two32) // ($den // 256)) 2048] | math min }
}

# R_PointToAngle2 for a vector in fixed point, as a 32-bit angle.
def point-to-angle [t: record, x: int, y: int]: nothing -> int {
  let at = {|num, den| $t.tantoangle | get (slope-div $num $den) }
  let ax = $x | math abs
  let ay = $y | math abs
  let angle = if $x == 0 and $y == 0 { 0
    } else if $x >= 0 and $y >= 0 { if $ax > $ay { do $at $ay $ax } else { 1073741824 - 1 - (do $at $ax $ay) }
    } else if $x >= 0 { if $ax > $ay { 0 - (do $at $ay $ax) } else { 3221225472 + (do $at $ax $ay) }
    } else if $y >= 0 { if $ax > $ay { 2147483648 - 1 - (do $at $ay $ax) } else { 1073741824 + (do $at $ax $ay) }
    } else { if $ax > $ay { 2147483648 + (do $at $ay $ax) } else { 3221225472 - 1 - (do $at $ax $ay) } }
  ($angle + $two32) mod $two32
}

# The middle of the box of a sector's lines, in map units, on --map
# (E1M1 when not given).
def soundorg [sector: int, --map: string = "E1M1"]: binary -> record<x: float, y: float> {
  let wad = $in
  let sides = $wad | sidedefs --map $map
  let lines = $wad | linedefs --map $map | where {|l|
    ($sides | get $l.front | get sector) == $sector or ($l.back != 65535 and ($sides | get $l.back | get sector) == $sector) }
  let v = $wad | vertexes --map $map
  let ends = $lines | each {|l| [$l.v1 $l.v2] } | flatten | each {|i| $v | get $i }
  let half = {|a, b| let sum = (fixed ($a | into float)) + (fixed ($b | into float))
    (if $sum < 0 { 0 - ((0 - $sum) // 2) } else { $sum // 2 }) / 65536 }
  {x: (do $half ($ends.x | math min) ($ends.x | math max)), y: (do $half ($ends.y | math min) ($ends.y | math max))}
}

# What a listener at (x, y) facing an angle hears of a source at a place:
# the distance, and vanilla's volume and separation. Volume 0 is a sound
# S_StartSound drops.
def heard [t: record, x: float, y: float, degrees: float, source: record<x: float, y: float>]: nothing -> record {
  let lx = fixed $x
  let ly = fixed $y
  let sx = fixed $source.x
  let sy = fixed $source.y
  let facing = $degrees / 360 * $two32 | math round | into int
  let adx = $lx - $sx | math abs
  let ady = $ly - $sy | math abs
  let dist = $adx + $ady - ([$adx $ady] | math min) // 2
  let angle = point-to-angle $t ($sx - $lx) ($sy - $ly)
  let turned = if $angle > $facing { $angle - $facing } else { ($angle + 4294967295 - $facing) mod $two32 }
  let sine = $t.finesine | get ($turned // 524288)
  let sep = if $lx == $sx and $ly == $sy { 128 } else { 128 - ((6291456 * $sine // 65536) // 65536) }
  let vol = if $dist < 13107200 { 64 } else if $dist > 78643200 { 0 } else { 64 * ((78643200 - $dist) // 65536) // 1000 }
  {dist: ($dist / 65536), vol: $vol, sep: $sep}
}
