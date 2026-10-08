# E1M1's level record and graphics from the WAD named by BENDOOM_IWAD,
# loaded by the game's loaders: samples of what the renderer reads. Each
# WAD value was read from Freedoom's bytes independently, in
# nushell, before the loader answered it; the multi-patch texels were
# composed there by vanilla's rule, patches pasted in order; the lines'
# specials were counted there, and the two sectors' block boxes worked
# out by P_GroupLines' rule from their lines' ends and the blockmap's
# origin (-712, -1072, 32 columns by 27 rows). The two switches the
# map names (SW1BRN1 on side 1166, SW1GRAY on side 615) have partners
# the map does not name, composed all the same: SW2BRN1 is 64 by 128 of
# 5 patches and SW2GRAY 64 by 128 of 3 in TEXTURE1; a switch's partner's
# partner is itself, and COMPUTE1 has none. The map touches four of
# Freedoom's 22 animations, by their first frames: NUKAGE1 (the WAD's
# flat 122, of 3; sector 23's floor), FWATER1 (flat 141, of 4; sector
# 36's ceiling), SFALL1 (texture 502, of 4; side 203's middle) and
# WFALL1 (texture 494, of 4; side 932's middle). Their frames are
# numbered after the finale's FLOOR4_8 at flat 0, textures from 1. The
# atlas indices are regression pins; their phases and texels follow
# P_UpdateSpecials' rule and the WAD's bytes. The flats' texels
# 0 and 2077 are NUKAGE1's and FWATER1's at clock 0, NUKAGE3's and
# FWATER2's at clock 1. THINGS has 292 records, kept as the lump stores
# them: player 1's start, the dead former sergeant (type 19) spawned on
# Hurt Me Plenty, and a record west of the origin. Its sprite, SPOSL0
# between S_START and S_END, is 52 wide with offsets 26 and 20; column
# 0 is one post at row 16, one texel long, and column 26's first post
# starts at row 1, 17 long, its column offsets being 216 and 659. The
# twitching impaled body's second state, S_LIVESTICK2, is reached only by
# animation; its POL6B0 is 28 wide with offsets 15 and 62, where POL6A0's
# left offset is 14. The pistol's ready and raise states, rows 59 and
# 60, no thing's, load PISGA0, 82 wide with offsets -125 and -97. Of
# info.c's frames, S_ARM1A's is full-bright and the sergeant's is not.
# Pain and gib entry rows load POSSG1, POSSM0, SPOSG1, SPOSM0,
# TROOH1, TROON0 and SARGH1. Their headers below come from the WAD,
# independently of the loader's state-chain walk.
# The status bar's patches are loaded by name, none of them a sprite's
# or a texture's: STTNUM0 and STTNUM1 are both 13 by 16 in Freedoom (the
# shareware WAD's STTNUM1 is 11 wide with a left offset, which is why
# STlib_drawNum steps by the zero's width), STYSNUM0 is 4 by 6, STTPRCNT
# 13 by 16, STKEYS0 7 by 5 and STKEYS3 7 by 7, STGNUM2 4 by 6, STARMS 38
# by 32 and STBAR 320 by 32.
# Then sprite definitions built from the sprite
# namespace by the rules of R_InitSpriteDefs and R_InstallSpriteLump,
# each rotation's lump and 1 if mirrored, rotation 1 first. No spawn
# state of milestone 5 has a rotated frame, so they are read here:
# PLAY's frame A, whose rotations 2 to 4 are mirrored to 8 to 6 (PLAYA1,
# PLAYA2A8, PLAYA3A7, PLAYA4A6, PLAYA5 in the WAD); POSS's frame A, eight
# lumps; SPOS's frame L, one lump for every side; PLAY's frame X, past
# its last, W; and four namespaces that vanilla refuses, written here,
# each refused in vanilla's I_Error words. PLAY's frame X fails the load,
# where vanilla's R_ProjectSprite would fail drawing it and name the
# sprite and frame by number, so its line is a regression pin.
import Base
import ../src/bytes.bend as B
import ../src/wad.bend as W
import ../src/things.bend as H
import ../src/fixed.bend as F
import ../src/angle.bend as A
import ../src/level.bend as L
import ../src/gfx.bend as G

def seg(+i: U32, s: L.Level.Seg) -> String:
  L.Seg{x1, y1, x2, y2, angle, offset, flags, side, front, back} = s
  "seg " ++ U32.show(i) ++ " from " ++ F.Fixed.show(x1) ++ " " ++ F.Fixed.show(y1) ++ " to "
    ++ F.Fixed.show(x2) ++ " " ++ F.Fixed.show(y2) ++ " angle " ++ A.Angle.show(angle)
    ++ " offset " ++ F.Fixed.show(offset) ++ " flags " ++ U32.show(flags) ++ " side "
    ++ U32.show(side) ++ " front " ++ U32.show(front) ++ " back " ++ U32.show(back)

def sub(s: L.Level.Sub) -> String:
  L.Sub{count, first} = s
  "subsector 681 segs " ++ U32.show(count) ++ " first " ++ U32.show(first)

def box(b: L.Level.Box) -> String:
  L.Box{top, bottom, left, right} = b
  F.Fixed.show(top) ++ " " ++ F.Fixed.show(bottom) ++ " " ++ F.Fixed.show(left) ++ " "
    ++ F.Fixed.show(right)

def names(xs: List<&2, String>) -> String:
  String.join(xs, " ")

def sector(+level: L.Level, +gfx: G.Gfx, +i: U32, s: L.Level.Sector) -> String:
  L.Sector{floor, ceil, light} = s
  "sector " ++ U32.show(i) ++ " floor " ++ F.Fixed.show(floor) ++ " ceil " ++ F.Fixed.show(ceil)
    ++ " light " ++ U32.show(light) ++ " flats " ++ names([L.Level.flat.name(level, L.Level.floorpic(level, i)),
      L.Level.flat.name(level, L.Level.ceilpic(level, i))])
    ++ " sky " ++ Bool.show(U32.is_eq(G.Gfx.ceilpic(gfx, level, i), G.Gfx.sky(gfx)))

def side(+level: L.Level, +i: U32, s: L.Level.Side) -> String:
  L.Side{xoff, yoff, sector} = s
  "side " ++ U32.show(i) ++ " offset " ++ F.Fixed.show(xoff) ++ " " ++ F.Fixed.show(yoff)
    ++ " sector " ++ U32.show(sector) ++ " textures " ++ names(L.Level.side_names(level, i))

def shows(xs: List<&2, U32>) -> List<&2, String>:
  match xs:
    case []:
      []
    case x <> rest:
      U32.show(x) <> shows(rest)

def show(xs: List<&2, U32>) -> String:
  String.join(shows(xs), " ")

# The palette at 4, 176 and 255; four colormap entries; the floor flat
# of sector 9 and the ceiling flat of sector 140 at texels 0 and 2077.
def peeks(+gfx: G.Gfx, +level: L.Level) -> List<&2, U32>:
  [(G.Gfx.palette() + 4 : U32), (G.Gfx.palette() + 176 : U32), (G.Gfx.palette() + 255 : U32),
    (G.Gfx.colormap() + 4 : U32), (G.Gfx.colormap() + 16 * 256 + 4 : U32),
    (G.Gfx.colormap() + 31 * 256 + 176 : U32), (G.Gfx.colormap() + 32 * 256 + 4 : U32),
    G.Gfx.flat(gfx, G.Gfx.floorpic(gfx, level, 9)), (G.Gfx.flat(gfx, G.Gfx.floorpic(gfx, level, 9)) + 2077 : U32),
    G.Gfx.flat(gfx, G.Gfx.ceilpic(gfx, level, 140)), (G.Gfx.flat(gfx, G.Gfx.ceilpic(gfx, level, 140)) + 2077 : U32)]

def texture(+gfx: G.Gfx, name: String, +t: U32) -> String:
  "texture " ++ name ++ " " ++ U32.show(G.Gfx.tex.width(gfx, t)) ++ "x"
    ++ F.Fixed.show(G.Gfx.tex.height(gfx, t)) ++ " patches " ++ U32.show(G.Gfx.tex.patches(gfx, t))
    ++ " mask " ++ U32.show(G.Gfx.tex.mask(gfx, t))

def from(+i: U32, offs: List<&2, U32>) -> List<&2, U32>:
  match offs:
    case []:
      []
    case o <> rest:
      (i + o - 3 : U32) <> from(i, rest)

# Offsets are from three before a column's texels, where its first
# post's header sits. Multi-patch COMPUTE1 and LITE3 (sides 1386 and
# 520) at rows 0, 1, 64 and 127 of column 0; single-patch STARGR1 (side
# 645) and the sky at rows 0, 1 and 64; masked CEILVINE (side 419)
# column 17's first two posts and AQMETL21 (side 216) column 0's first,
# each as top, length and first texel.
def texels(+gfx: G.Gfx) -> List<&2, U32>:
  List.concat(&2, U32, [
    from(G.Gfx.column(gfx, G.Gfx.mid(gfx, 1386), 0), [3, 4, 67, 130]),
    from(G.Gfx.column(gfx, G.Gfx.mid(gfx, 520), 0), [3, 4, 67, 130]),
    from(G.Gfx.column(gfx, G.Gfx.mid(gfx, 645), 0), [3, 4, 67]),
    from(G.Gfx.column(gfx, G.Gfx.skytex(gfx), 0), [3, 4, 67]),
    from(G.Gfx.column(gfx, G.Gfx.mid(gfx, 419), 17), [0, 1, 3, 20, 21, 23]),
    from(G.Gfx.column(gfx, G.Gfx.mid(gfx, 216), 0), [0, 1, 3])])

# What the four animated names show at a clock.
def animated(+gfx: G.Gfx, +level: L.Level) -> String:
  show([G.Gfx.floorpic(gfx, level, 23), G.Gfx.ceilpic(gfx, level, 36), G.Gfx.mid(gfx, 203), G.Gfx.mid(gfx, 932)])

def at(gfx: G.Gfx, +level: L.Level, clock: U32) -> G.Gfx:
  G.Gfx.of_state(gfx, L.Level.sidetex(level), clock)

# Where a status bar patch's width and height sit in the array, the
# first two words of its header.
def bar(+gfx: G.Gfx, k: U32) -> List<&2, U32>:
  +p = G.Gfx.bar(gfx, k)
  [p, (p + 2 : U32)]

def moving(+gfx: G.Gfx, +level: L.Level) -> List<&2, U32>:
  [G.Gfx.flat(gfx, G.Gfx.floorpic(gfx, level, 23)), (G.Gfx.flat(gfx, G.Gfx.floorpic(gfx, level, 23)) + 2077 : U32),
    G.Gfx.flat(gfx, G.Gfx.ceilpic(gfx, level, 36)), (G.Gfx.flat(gfx, G.Gfx.ceilpic(gfx, level, 36)) + 2077 : U32)]

# How many of the first n lines carry a special.
def carrying(n: Nat, +level: L.Level, +special: U32, +i: U32) -> U32:
  match n:
    case 0n:
      0
    case 1n+m:
      (Bool.to_u32(U32.is_eq(L.Level.special(level, i), special)) + carrying(m, level, special, (i + 1 : U32)) : U32)

# Freedoom's E1M1 has 1175 lines; the count of each special it carries.
def specials(+level: L.Level, which: List<&2, U32>) -> List<&2, String>:
  match which:
    case []:
      []
    case +k <> rest:
      (U32.show(k) ++ ":" ++ U32.show(carrying(U32.to_nat(1175), level, k, 0))) <> specials(level, rest)

def thing(+i: U32, t: L.Level.Thing) -> String:
  L.Thing{x, y, angle, kind, options} = t
  "thing " ++ U32.show(i) ++ " at " ++ F.Fixed.show(x) ++ " " ++ F.Fixed.show(y) ++ " angle " ++ U32.show(angle)
    ++ " type " ++ U32.show(kind) ++ " options " ++ U32.show(options)

# The sprite of state row 3, the dead former sergeant's: its width and
# offsets, then the header and first texel of column 0's post, the end
# marker after it, and column 26's first post's header and first texel.
def sprite(+gfx: G.Gfx) -> List<&2, U32>:
  +patch = G.Gfx.sprite(gfx, 3, 0, 0)
  [(patch + 216 : U32), (patch + 217 : U32), (patch + 219 : U32), (patch + 221 : U32), (patch + 659 : U32),
    (patch + 660 : U32), (patch + 662 : U32)]

def sprite.head(+gfx: G.Gfx, +state: U32) -> String:
  "sprite of state " ++ U32.show(state) ++ " width " ++ F.Fixed.show(G.Gfx.sprite(gfx, state, 0, 1)) ++ " offset "
    ++ F.Fixed.show(G.Gfx.sprite(gfx, state, 0, 2)) ++ " top " ++ F.Fixed.show(G.Gfx.sprite(gfx, state, 0, 3))

def installs(vs: List<&2, G.Gfx.Install>) -> List<&2, String>:
  match vs:
    case []:
      []
    case G.Install{frame, rot, name, flip} <> rest:
      (name ++ " " ++ U32.show(flip)) <> installs(rest)

def views(r: Result<&1, &1, U32 & String, List<&2, G.Gfx.Install>>) -> String:
  match r:
    case Fail{e}:
      Pair.snd(U32, String, e)
    case Done{vs}:
      String.join(installs(vs), " ")

def test(names: List<&2, String>) -> List<&2, W.Wad.Lump>:
  match names:
    case []:
      []
    case name <> rest:
      W.Lump{0, 0, name} <> test(rest)

# A row of a sprite's frame; the definition reads nothing else of it.
def row(sprite: String, frame: U32) -> H.Thing.Row:
  H.Row{sprite, frame, False{}, 0, 0, H.Null{}, 0}

def defs(p: Array<U32> & List<&2, W.Wad.Lump>) -> IO(Unit):
  (bytes, lumps) = p
  +space = G.Gfx.sprite.space(lumps, False{})
  do IO<Unit>:
    IO.print("PLAY A " ++ views(G.Gfx.sprite.def(space, row("PLAY", 0))))
    IO.print("POSS A " ++ views(G.Gfx.sprite.def(space, row("POSS", 0))))
    IO.print("SPOS L " ++ views(G.Gfx.sprite.def(space, row("SPOS", 11))))
    IO.print("PLAY X " ++ views(G.Gfx.sprite.def(space, row("PLAY", 23))))
    IO.print(views(G.Gfx.sprite.def(test(["TESTA0", "TESTA1"]), row("TEST", 0))))
    IO.print(views(G.Gfx.sprite.def(test(["TESTA0", "TESTA0"]), row("TEST", 0))))
    IO.print(views(G.Gfx.sprite.def(test(["TESTA1", "TESTA2", "TESTA3", "TESTA4", "TESTA5", "TESTA6", "TESTA7"]),
      row("TEST", 0))))
    IO.print(views(G.Gfx.sprite.def(test(["TESTA0", "TESTC0"]), row("TEST", 0))))

def blocks(b: L.Level.Box) -> String:
  L.Box{top, bottom, left, right} = b
  "top " ++ U32.show(top) ++ " bottom " ++ U32.show(bottom) ++ " left " ++ U32.show(left) ++ " right "
    ++ U32.show(right)

def peeked(tag: String, p: Array<U32> & List<&2, U32>) -> IO(Array<U32>):
  (mem, xs) = p
  do IO<Array<U32>>:
    IO.print(tag ++ " " ++ show(xs))
    return mem

def report.go(mem: Array<U32>, gl: G.Gfx & L.Level) -> IO(Unit):
  (+gfx, +level) = gl
  do IO<Unit>:
    IO.print(seg(0, L.Level.seg(level, 0)))
    IO.print(seg(75, L.Level.seg(level, 75)))
    IO.print(sub(L.Level.sub(level, 681)))
    IO.print("node 680 right " ++ box(L.Level.box(level, 680, 0)) ++ " left " ++ box(L.Level.box(level, 680, 1)))
    IO.print(sector(level, gfx, 14, L.Level.sector(level, 14)))
    IO.print(sector(level, gfx, 140, L.Level.sector(level, 140)))
    IO.print(side(level, 0, L.Level.side(level, 0)))
    IO.print(side(level, 5, L.Level.side(level, 5)))
    IO.print("specials " ++ names(specials(level, [1, 2, 11, 23, 26, 62, 88, 117, 48, 36])))
    IO.print("line 528 special " ++ U32.show(L.Level.special(level, 528)) ++ " tag " ++ U32.show(L.Level.tag(level, 528)))
    IO.print("things " ++ U32.show(L.Level.nthings(level)))
    IO.print(thing(157, L.Level.thing(level, 157)))
    IO.print(thing(245, L.Level.thing(level, 245)))
    IO.print(thing(42, L.Level.thing(level, 42)))
    IO.print(sprite.head(gfx, 3))
    IO.print(sprite.head(gfx, 52))
    IO.print(sprite.head(gfx, 59))
    IO.print(sprite.head(gfx, 60))
    IO.print(sprite.head(gfx, 35))
    IO.print(sprite.head(gfx, 48))
    IO.print(sprite.head(gfx, 121))
    IO.print(sprite.head(gfx, 128))
    IO.print(sprite.head(gfx, 137))
    IO.print(sprite.head(gfx, 144))
    IO.print(sprite.head(gfx, 153))
    IO.print(sprite.head(gfx, 160))
    IO.print(sprite.head(gfx, 168))
    IO.print(sprite.head(gfx, 196))
    IO.print(sprite.head(gfx, 198))
    IO.print("bright of states 3 and 7 " ++ U32.show(G.Gfx.sprite(gfx, 3, 0, 5)) ++ " "
      ++ U32.show(G.Gfx.sprite(gfx, 7, 0, 5)))
    IO.print("bright of fireball states 196 and 198 " ++ U32.show(G.Gfx.sprite(gfx, 196, 0, 5)) ++ " "
      ++ U32.show(G.Gfx.sprite(gfx, 198, 0, 5)))
    IO.print("zombie firing bright " ++ U32.show(G.Gfx.sprite(gfx, 185, 0, 5)))
    IO.print("sector 10 blocks " ++ blocks(L.Level.blockbox(level, 10)))
    IO.print("sector 98 blocks " ++ blocks(L.Level.blockbox(level, 98)))
    IO.print(texture(gfx, "COMPUTE1", G.Gfx.mid(gfx, 1386)))
    IO.print(texture(gfx, "DOOR1", G.Gfx.top(gfx, 526)))
    IO.print(texture(gfx, "SKY1", G.Gfx.skytex(gfx)))
    IO.print("side 526 textures " ++ U32.show(G.Gfx.top(gfx, 526)) ++ " " ++ U32.show(G.Gfx.bottom(gfx, 526))
      ++ " " ++ U32.show(G.Gfx.mid(gfx, 526)))
    IO.print(texture(gfx, "SW2BRN1", L.Level.switch(level, G.Gfx.mid(gfx, 1166))))
    IO.print(texture(gfx, "SW2GRAY", L.Level.switch(level, G.Gfx.mid(gfx, 615))))
    IO.print("switches " ++ show([G.Gfx.mid(gfx, 1166), L.Level.switch(level, G.Gfx.mid(gfx, 1166)),
      L.Level.switch(level, L.Level.switch(level, G.Gfx.mid(gfx, 1166))), L.Level.switch(level, G.Gfx.mid(gfx, 1386))]))
    IO.print("animations " ++ String.join([animated(at(gfx, level, 0), level), animated(at(gfx, level, 1), level),
      animated(at(gfx, level, 8), level), animated(at(gfx, level, 9), level), animated(at(gfx, level, 41), level)], ", "))
    read : Array<U32> <- peeked("palette colormap flats texels",
      B.Bytes.each(~U32, ~B.Bytes.at, List.concat(&2, U32, [peeks(gfx, level), texels(gfx), moving(at(gfx, level, 0), level),
        moving(at(gfx, level, 1), level), sprite(gfx)]), mem))
    IO.print("bar patches " ++ show(Pair.snd(Array<U32>, List<&2, U32>,
      B.Bytes.each(~U32, ~B.Bytes.u16, List.concat(&2, U32, [bar(gfx, 0), bar(gfx, 1), bar(gfx, 10),
        bar(gfx, 20), bar(gfx, 21), bar(gfx, 24), bar(gfx, 27), bar(gfx, 33), bar(gfx, 34)]), read))))

def report(w: Array<U32> & G.Gfx & L.Level) -> IO(Unit):
  (mem, gl) = w
  report.go(mem, gl)

def main() -> IO(Unit):
  do IO<Unit>:
    world : Array<U32> & G.Gfx & L.Level <- G.Gfx.open(1, 1)
    report(world)
    path : String <- IO.try(String, IO.get_env("BENDOOM_IWAD"))
    bytes : Array<U32> <- IO.try(Array<U32>, B.Bytes.read(path))
    defs(W.Wad.dir(bytes))

#|seg 0 from 448.000000 896.000000 to 256.000000 896.000000 angle 180.000 offset 0.000000 flags 4 side 344 front 122 back 8
#|seg 75 from -208.000000 1472.000000 to 0.000000 1472.000000 angle 0.000 offset 112.000000 flags 4 side 337 front 135 back 36
#|subsector 681 segs 4 first 2053
#|node 680 right 2336.000000 64.000000 -704.000000 3248.000000 left 64.000000 -1064.000000 -128.000000 2544.000000
#|sector 14 floor -80.000000 ceil 536.000000 light 224 flats RROCK18 F_SKY1 sky True
#|sector 140 floor 0.000000 ceil 128.000000 light 192 flats AQF054 SLIME14 sky False
#|side 0 offset 53.000000 -24.000000 sector 15 textures - - MC5
#|side 5 offset 94.000000 0.000000 sector 46 textures - MC18 -
#|specials 1:20 2:6 11:1 23:1 26:4 62:4 88:5 117:1 48:0 36:0
#|line 528 special 2 tag 5
#|things 292
#|thing 157 at -416.000000 256.000000 angle 0 type 1 options 7
#|thing 245 at 1248.000000 224.000000 angle 90 type 19 options 15
#|thing 42 at -160.000000 1328.000000 angle 225 type 2048 options 23
#|sprite of state 3 width 52.000000 offset 26.000000 top 20.000000
#|sprite of state 52 width 28.000000 offset 15.000000 top 62.000000
#|sprite of state 59 width 82.000000 offset -125.000000 top -97.000000
#|sprite of state 60 width 82.000000 offset -125.000000 top -97.000000
#|sprite of state 35 width 7.000000 offset 4.000000 top 12.000000
#|sprite of state 48 width 38.000000 offset 21.000000 top 13.000000
#|sprite of state 121 width 39.000000 offset 19.000000 top 51.000000
#|sprite of state 128 width 44.000000 offset 22.000000 top 57.000000
#|sprite of state 137 width 32.000000 offset 16.000000 top 50.000000
#|sprite of state 144 width 41.000000 offset 18.000000 top 61.000000
#|sprite of state 153 width 49.000000 offset 26.000000 top 59.000000
#|sprite of state 160 width 49.000000 offset 25.000000 top 59.000000
#|sprite of state 168 width 33.000000 offset 15.000000 top 47.000000
#|sprite of state 196 width 15.000000 offset 8.000000 top 11.000000
#|sprite of state 198 width 34.000000 offset 17.000000 top 21.000000
#|bright of states 3 and 7 0 1
#|bright of fireball states 196 and 198 1 1
#|zombie firing bright 1
#|sector 10 blocks top 12 bottom 12 left 11 right 12
#|sector 98 blocks top 11 bottom 9 left 5 right 7
#|texture COMPUTE1 128x128.000000 patches 10 mask 127
#|texture DOOR1 64x72.000000 patches 1 mask 63
#|texture SKY1 256x128.000000 patches 1 mask 255
#|side 526 textures 67 68 0
#|texture SW2BRN1 64x128.000000 patches 5 mask 63
#|texture SW2GRAY 64x128.000000 patches 3 mask 63
#|switches 105 121 105 0
#|animations 1 4 1 5, 3 5 3 7, 3 5 3 7, 1 6 4 8, 2 6 4 8
#|palette colormap flats texels 16777215 16711680 10972011 4 97 0 0 149 148 6 15 98 97 98 104 108 108 108 7 110 110 108 87 87 92 0 16 122 20 7 78 86 4 106 123 125 206 207 125 125 243 207 16 1 64 255 1 17 8
#|bar patches 13 16 13 16 4 6 13 16 7 5 7 7 4 6 38 32 320 32
#|PLAY A PLAYA1 0 PLAYA2A8 0 PLAYA3A7 0 PLAYA4A6 0 PLAYA5 0 PLAYA4A6 1 PLAYA3A7 1 PLAYA2A8 1
#|POSS A POSSA1 0 POSSA2 0 POSSA3 0 POSSA4 0 POSSA5 0 POSSA6 0 POSSA7 0 POSSA8 0
#|SPOS L SPOSL0 0 SPOSL0 0 SPOSL0 0 SPOSL0 0 SPOSL0 0 SPOSL0 0 SPOSL0 0 SPOSL0 0
#|PLAY X R_ProjectSprite: no frame X of sprite PLAY
#|R_InitSprites: Sprite TEST frame A has rotations and a rot=0 lump
#|R_InitSprites: Sprite TEST frame A has multip rot=0 lump
#|R_InitSprites: Sprite TEST frame A is missing rotations
#|R_InitSprites: No patches found for TEST frame B
