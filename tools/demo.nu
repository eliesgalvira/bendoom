# What Chocolate Doom is handed to replay a command script: a copy of
# the IWAD whose map starts the player where the script does, and the
# script as a vanilla demo. A script is runs a space apart, each
# "count,forward,side,turn,buttons" in a demo's units, but for the
# buttons: use 1, attack 2, a change of weapon 4 and eight times the
# weapon's number from 0 (the key 1 is 4, the key 2 is 12, the key 3 is
# 20). That is the demo's byte with its two low bits trading places,
# since the scripts written when use was the one button say 1 for it.
# A map is named by its marker, E1M5. Sourced by tools/oracle.nu and
# tools/listen.nu.

source wad.nu

# An integer's low bytes, little-endian.
def le [width: int]: int -> binary {
  $in | into binary | bytes at 0..<$width
}

# The IWAD with record i of a map's THINGS replaced in place by a thing
# of a type at x, y facing angle on every skill, and every other byte
# kept. A whole IWAD and not a PWAD, since Doom refuses -file with the
# shareware one.
def rewrite [map: string, i: int, x: int, y: int, angle: int, type: int]: binary -> binary {
  let wad = $in
  let at = ($wad | map-lump $map THINGS | get pos) + $i * 10
  let record = [($x | le 2) ($y | le 2) ($angle | le 2) ($type | le 2) (7 | le 2)] | bytes collect
  [($wad | bytes at 0..<$at) $record ($wad | bytes at ($at + 10)..)] | bytes collect
}

# The IWAD with the map's records things names, each "record,type,x,y",
# rewritten facing 0.
def retyped [map: string, things: string]: binary -> binary {
  let wad = $in
  $things | split row ' ' | where $it != '' | reduce --fold $wad {|t, wad|
    let f = $t | split row ',' | into int
    $wad | rewrite $map $f.0 $f.2 $f.3 0 $f.1
  }
}

# The IWAD with the map's player 1 starting at x, y facing angle, and
# the records things names rewritten.
def placed [map: string, x: int, y: int, angle: int, things: string]: binary -> binary {
  let wad = $in
  $wad | rewrite $map ($wad | things --map $map | where type == 1 | first | get i) $x $y $angle 1
  | retyped $map $things
}

# A script's runs: how many tics, and the four bytes a demo keeps of the
# tic's command (G_ReadDemoTiccmd: forward, side, the turn's high byte,
# the buttons: BT_ATTACK 1, BT_USE 2, BT_CHANGE 4, the weapon from 8).
def runs []: string -> table<tics: int, bytes: binary> {
  $in | split row ' ' | each {|run|
    let f = $run | split row ',' | into int
    if $f.0 < 0 { error make {msg: "script tic counts must be non-negative"} }
    let buttons = ($f.4 bit-and 0xfc) + ($f.4 bit-and 1) * 2 + ($f.4 bit-and 2) // 2
    {tics: $f.0, bytes: ([($f.1 | le 1) ($f.2 | le 1) ($f.3 | le 1) ($buttons | le 1)] | bytes collect)}
  }
}

# The runs' tics, four bytes each.
def tics []: table<tics: int, bytes: binary> -> binary {
  $in | each {|run| 0..<$run.tics | each { $run.bytes } } | flatten | bytes collect
}

# A version 109 demo's header for a map: Hurt Me Plenty, no deathmatch,
# respawn, fast or -nomonsters, console player 0, player 1 alone in the
# game.
def header [map: string]: nothing -> binary {
  let at = $map | parse 'E{episode}M{map}' | first
  [0x[6d 02] ($at.episode | into int | le 1) ($at.map | into int | le 1) 0x[00 00 00 00 00 01 00 00 00]]
  | bytes collect
}

# The marker of the map a demo's header names.
def header-map []: binary -> string {
  let h = $in
  $"E($h | bytes at 2..2 | into int)M($h | bytes at 3..3 | into int)"
}

# The tics after a header, and the 0x80 that ends a demo. Under
# -playdemo Chocolate Doom quits when it reads the end.
def demo [header: binary]: binary -> binary {
  [$header $in 0x[80]] | bytes collect
}
