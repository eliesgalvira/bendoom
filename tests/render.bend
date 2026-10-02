# Frames of E1M1 from the WAD named by BENDOOM_IWAD, rendered through
# the function the game draws with: for each, a 32-bit FNV-1a hash of the
# whole 320 by 200 frame, the view over the status bar, and the indices
# at six pixels (the view's centre, near its top left, near its bottom
# right, high on its centre column, column 1 row 2 of the arms
# panel's second number, which is grey 96 while the shotgun is not owned
# and yellow 160 in the two frames with a full inventory, and row 180
# column 155 of the marine's face, which the WAD read in nushell says is
# 72 in STFST00, 64 in STFST01, 59 in STFST02, 79 in STFEVL0 and 8 in
# STFDEAD0, so the pixel names the face every frame shows). The start,
# then hand-chosen places with the eye at rest on the floor and the
# angle a multiple of 45 degrees, each after
# the oracle's 20 idle tics: a bright metal wall, the dim bench room
# north of the start, the hazard-striped step under the computer panels,
# the lowered opening west of the start with a masked grate across it
# and the yard's trees behind, the hall under a ceiling of water, the
# yard under the open sky, the railed pit, and the dead former sergeant
# on its bench. Then the sprites' rules, each place found by rendering
# the map and each count below from drawing one sprite with and without
# the stored ranges: the medikit (record 258) in sector 8, which the
# walk enters through at least three of its nine subsectors (40, 34 and
# 35 store ranges) and which is drawn once, as a copy would leave the
# same pixels and no frame can show one; a near stalagmite (record 153)
# over a far tree (23), which shows 206 of its 1022 pixels; a hall where
# one-sided walls hide the sergeant and a hung leg, and ledges two
# corpses, all projected; and a corpse (record 171) beyond a raised
# bench, whose edge leaves 78 of its 220 pixels, and another (167) it
# hides whole. Then the masked pass's two depth orders, the yard and the
# bars: the yard's trees in front of the grate, which drawing every
# sprite before every masked texture changes by 837 pixels, the grate's
# top over the trees; and a hung body and the dead sergeant behind the
# bars east of the walls hall, which drawing every masked texture before
# every sprite changes by 516. Then the monsters' rotations, each from a
# place no monster of the map can see, so that none has woken in vanilla
# either: the demon of record 92 head on at rotation 1, 6 tics in, while
# its spawn's 7 tics still hold it before its first A_Look; the shotgun
# guy of record 94 from behind, rotation 5, and from its side, rotation
# 4; and the demon of record 3 at rotation 6, which SARGA4A6 draws
# mirrored. Moving the monster's record to the start changes 3758, 375,
# 736 and 1706 pixels of those frames, so each shows its monster. Then
# frames after scripts, which the oracle plays too: a stride, riding the
# lift down, off its east edge, a north room's door half open, the
# special 23 switch pressed, the exit
# switch pressed, a blinking wall at its dark level, the blue key on the
# last tic of its dim state, 22, and the first of its full-bright one,
# 23, then the pickups: the blue key on the tic before the player
# strafing past it takes it and on the tic it does, a health bonus on a
# step 24 up on the tic before a walk reaches it and on the tic it does,
# green armour 33 to the right of a walk on the tic before it reaches it
# and on the tic it does, a stimpack and a medikit before and after a
# walk across them and back at 100 health, which leaves both, the rocket
# in its nook strafed past facing 112.5 degrees on the tic before it is
# taken and the tic it is, and on that tic with every ammo type at its
# cap, where it stays, and the chainsaw on the key's script on the tic
# it is taken and, owned, on the tic it stays; each script is beside its
# frame below. Last the pistol, which every frame above holds at rest or
# bobbing: 8 tics into its rise, 74 down the screen, and on a walk east
# from the start at the bob's lowest, tic 48, and at its farthest right,
# tic 64; the stride has it far left. Then the dead view: 650 tics stood
# in the nukage of sector 173 while monsters attack leave the eye
# 6 units over the floor, the pistol off the bottom
# of the screen and the bar at no health. Every frame holds the things
# E1M1 spawns on Hurt Me Plenty, monsters among them, each in its state
# on that tic.
# Every frame carries the status bar the inventory of its state fills,
# so the bar at the start, after the rocket is taken, after the green
# armour and after the blue key are the frames named for those pickups,
# and the face ST_updateFaceWidget chose on that tic. The oracle masks
# the face's box, since vanilla's face keeps changing under the pause,
# but the dead one holds: its frame's face pixels are STFDEAD0's, all
# 591 of them, and the rested start's are STFST00's, all 578, each read
# from the WAD with tools/oracle.nu's patch-pixels.
# Remaining combat fidelity gaps are recorded in milestone 6's tickets.
# The exit and full-inventory fixtures are regression pins where a
# vanilla demo cannot reach the same state.
# The pickup frames show their pickup: the key is 44 pixels of the first
# key frame and would be 347 of the second, a bonus never
# taken would be 1465 of the second bonus frame, the green armour is 745
# of its first frame and would be 419 of its second, and a stimpack and
# a medikit taken at 100 health 2744 of theirs; a refused frame differs
# from its taken twin only in the pickup's sprite, 762 pixels of the
# rocket and 5092 of the chainsaw.
# Each frame is drawn twice, over a frame blanked to 0 and to 255: equal
# hashes mean every pixel of the 200 rows was written.
# Every line names the palette ST_doPaletteStuff chose for its frame,
# which the renderer answers beside the indices. The plain palette 0 is
# every frame's but the pickups' and the nukage's. A pickup adds 6 to
# the flash and the same tic's counters take one off, so 5 picks the
# first gold, 10: the health bonus, the green armour, the rocket and the
# chainsaw frames show it, and so does the run east at tic 66, which has
# just crossed the health bonus record 268 at 512 256. The blue key sets
# the flash to 6 and then adds 6, leaving 11, which picks the second
# gold, 11. A tic stood in the nukage of sector 173 leaves a damage
# count of 4, which picks the first red, 2; by the dead frame's tic 650
# it has long faded. Pinned to Freedoom.
# Before the frames, the renderer's arithmetic on chosen values, worked
# by hand from vanilla's r_*.c. A colormap prints as its table's
# address, 69120 plus 256 a map.
# - clip, gaps, covers: a range touching its neighbours joins them, 21
#   to 29 between 10 to 20 and 30 to 40; the fragments a wall from 5 to
#   45 leaves between solid ranges come out left to right; 10 to 20
#   covers 12 to 18 and not 12 to 25.
# - focal, tox: the view's edges at width 320. The focal length is 160
#   over the tangent 65586 of fine angle 3072, 10477766; through it the
#   tangent at 3072 lands on column 1 and the next on column 0, so
#   column 0's angle is fine angle 3073, Doom's clipangle 0x20080000; on
#   the other side 1023 lands on 320 and 1022 past it; the tangent 25 at
#   the view's centre lands on column 160.
# - xtoangle: columns 0, 1, 2, 319 and 320 of a sweep, which gives each
#   column the least fine angle whose column is not past it: over the
#   columns 321, 320, 2, 0, -1 of fine angles 0 to 4, columns 320 down
#   to 2 take angles 1 and 2, columns 1 and 0 take 3; as binary angles
#   less a quarter turn.
# - yslope: a row's slope is 160 over its distance from the centre row's
#   top edge plus a half: 320 at rows 83 and 84, 160 / 83.5 at rows 0 and
#   167.
# - scale: the wall scale from the global angle, looking east at a wall
#   whose normal faces the eye. At distance 160 it is 1, at the centre
#   and at column 0's angle alike; at 100/65536 the division would
#   overflow, so it is 64; at distance 2 it is 80, capped at 64; seen
#   edge on, the sine 25 makes it 25/65536, raised to 256.
# - scalelight, zlight: the light tables' ends. A wall's colormap is 60
#   less four a light number less half the scale index, held to 0 and
#   31: the darkest light is 31 at both ends of the scale, the brightest
#   0, light 8 runs from 28 to 5. A span's is the same start less half
#   of 160 over the distance index plus one: light 8 is 0 at index 0, 18
#   at 7, 28 at 127.
# - texcol, iscale, wall colormap: facing a wall 160 away head on with
#   texture offset 64. At the centre column the tangent 25 of the wall's
#   normal takes 4000/65536 off the offset, texture column 63; at column
#   0's angle the tangent 65686 takes 160.37, texture column -97, the
#   shift flooring the negative. The reciprocal of scale 1 is 65535, of
#   the cap 64 it is 1023, of the floor 1/256 it is 16777215. At light 8
#   scale 1 is light index 16, colormap 20; scale 64 is index 1024,
#   capped at 47, colormap 5.
# - silhouettes: a range's silhouette (1 clips below, 2 above), the
#   height it clips under and the one it clips over, MAXINT and MININT
#   for any height, with the eye 41 over a floor at 8 under a ceiling at
#   128. A one-sided wall clips both ways at any height. A masked texture
#   over a floor stepping down to 0 keeps the front's floor as the height
#   it clips under, and fills in the top at any height. A window between
#   two like sectors clips nothing. A door shut at the floor clips below
#   at any height, and above since its ceiling is under the eye.
# - sprite: R_ProjectSprite holds a sprite's columns to the screen, and
#   R_DrawVisSprite steps down a column by the scale's reciprocal. Each
#   vissprite prints x1, x2, scale, gx, gy, gz, gzt, texturemid,
#   startfrac, xiscale, patch, colormap, and its sector's rank and
#   thing's place. Facing east, a thing x ahead and y to the left has tz
#   = x and tx = -y; its scale is 160 / tz, and with the patch 64 wide
#   and its origin 32 in, x1 = 160 + (tx - 32) scale and x2 = 160 + (tx +
#   32) scale - 1, the first held to 0 and the last to 319. The patch's
#   column starts at 0, or at 64 less 1/65536 for a mirrored patch
#   (startfrac = width - 1), and steps xiscale = 1 / scale a column, its
#   negation when mirrored; a sprite cut on the left starts xiscale (x1 -
#   x1 unclipped) further. 160 ahead the scale and its reciprocal are 1:
#   straight ahead, x1 = 128 and x2 = 191; 150 left, x1 = -22, drawn from
#   0 at column 22 of the patch; mirrored and 150 right, x1 = 278 and x2
#   = 341, drawn to 319 from 64 less 1/65536 stepping -1; 400 left, x2 =
#   -209, culled. 320 ahead the scale is 1/2 and xiscale 2: straight
#   ahead, x1 = 160 - 16 = 144 and x2 = 176 - 1 = 175. Mirrored and 308
#   left, x1 = 160 - 170 = -10 and x2 = 160 - 138 - 1 = 21: drawn from 0,
#   its patch's column 64 less 1/65536 plus -2 times 10, 44 less 1/65536,
#   stepping -2.
# - sprite column: that last sprite's column 0 (x, top, scale,
#   texturemid, dc_iscale, colormap, and the clips), drawn with dc_iscale
#   2, the step's absolute value, and its top at 84 less half the 15 its
#   top stands over the eye, 76.5; the clips no range set are the
#   screen's edges.
# - sorted, shown: R_SortVisSprites draws the smallest scale first, and
#   of equal scales the vissprite made first: sectors in the order the
#   walk reached them, and in a sector its thing list's order, the order
#   its things are shown in. That list is vanilla's P_SetThingPosition's:
#   the last to spawn first, 9, 5, 2, and a thing that moves goes first,
#   as 2 does here moved a unit east.
# - skycol, flat: a plane's arithmetic, looking east from the origin.
#   The sky turns a column every 2^22 of angle: column 0's view angle is
#   column 128 of the sky, and a quarter turn on it is 256 more. At light
#   8 a span 200 away has light index 12, colormap 22; one 13120 away has
#   index 820, capped at 127, colormap 28. The frame's scales are 0 along
#   x and 409 along y. The centre row's slope 320 puts a plane 41 under
#   the eye 13120 away, so a span there steps 0 and 13120 * 409 a
#   column, and with a distance scale of 65537 it starts 13120.2 further
#   along x through the cosine 65535, and the sine 25 of that to the
#   south.
# - span: packed as the DOS span loop packs it, x 1.5 and y 2.25 are
#   0x06000900, texel 1 of row 2.
import Base
import ../src/bytes.bend as B
import ../src/vec.bend as V
import ../src/fixed.bend as F
import ../src/angle.bend as A
import ../src/tables.bend as T
import ../src/level.bend as L
import ../src/gfx.bend as G
import ../src/keys.bend as K
import ../src/sim.bend as S
import ../src/clip.bend as Cl
import ../src/project.bend as P
import ../src/draw.bend as D
import ../src/segs.bend as Sg
import ../src/planes.bend as N
import ../src/sprites.bend as Z
import ../src/masked.bend as Q
import ../src/render.bend as R
import ../src/fnv.bend as H
import ../src/inventory.bend as I
import ../src/message.bend as Msg
import ./fixtures/route.bend as Rt
import ./fixtures/combat.bend as C
import ./fixtures/closed.bend as Fx

type Hash is Type:
  Hash{mem: Array<U32>, h: U32, pal: U32}

def hash.mix(h: U32, pal: U32, p: Array<U32> & U32) -> Hash:
  (mem, v) = p
  Hash{mem, H.Fnv.mix(h, v), pal}

def hash.px(i: Nat, st: Hash) -> Hash:
  Hash{mem, h, pal} = st
  hash.mix(h, pal, B.Bytes.at(mem, (G.Gfx.frame() + U32.from_nat(i) : U32)))

def shows(xs: List<&2, U32>) -> List<&2, String>:
  match xs:
    case []:
      []
    case x <> rest:
      U32.show(x) <> shows(rest)

def pixels(covered: Bool, h: U32, pal: U32, p: Array<U32> & List<&2, U32>) -> Array<U32> & String:
  (mem, xs) = p
  (mem, "hash " ++ U32.show(h) ++ " pixels " ++ String.join(shows(xs), " ") ++ " covered "
    ++ Bool.show(covered) ++ " palette " ++ U32.show(pal))

def line(+over0: U32, st: Hash) -> Array<U32> & String:
  Hash{mem, +h, pal} = st
  pixels(U32.is_eq(h, over0), h, pal, B.Bytes.each(~U32, ~B.Bytes.at, [(G.Gfx.frame() + 84 * 320 + 160 : U32),
    (G.Gfx.frame() + 10 * 320 + 10 : U32), (G.Gfx.frame() + 150 * 320 + 300 : U32),
    (G.Gfx.frame() + 20 * 320 + 160 : U32), (G.Gfx.frame() + 174 * 320 + 124 : U32),
    (G.Gfx.frame() + 180 * 320 + 155 : U32)], mem))

def print(tag: String, p: Array<U32> & String) -> IO(Array<U32>):
  (mem, text) = p
  do IO<Array<U32>>:
    IO.print(tag ++ " " ++ text)
    return mem

def hashed.of(p: Array<U32> & U32) -> Hash:
  (mem, pal) = p
  D.Draw.each(~Hash, ~hash.px, U32.to_nat(64000), 0n, Hash{mem, H.Fnv.basis(), pal})

# A frame's hash and the palette the renderer named for it, drawn over a
# frame blanked to an index.
def hashed(+tables: P.Project.Tables, +gfx: G.Gfx, +s: S.State, blank: U32, mem: Array<U32>) -> Hash:
  hashed.of(R.Render.frame(tables, gfx, s, False{},
    D.Draw.set(U32.to_nat(64000), mem, G.Gfx.frame(), blank)))

def again(tables: P.Project.Tables, gfx: G.Gfx, s: S.State, st: Hash) -> Array<U32> & String:
  Hash{mem, h, pal} = st
  line(h, hashed(tables, gfx, s, 255, mem))

# A frame of the state, its line printed, and the array back.
def frame(tag: String, +tables: P.Project.Tables, +gfx: G.Gfx, +s: S.State, mem: Array<U32>) ->
  IO(Array<U32>):
  print(tag, again(tables, gfx, s, hashed(tables, gfx, s, 0, mem)))

# The frame's first eight rows, which is every row the font's tallest
# glyph reaches.
def band(p: Array<U32> & U32) -> Array<U32> & List<&2, U32>:
  (mem, pal) = p
  B.Bytes.each(~U32, ~B.Bytes.at, B.Bytes.fields(2560n, G.Gfx.frame(), 1, [0]), mem)

def said.at(+i: U32, +v: U32) -> String:
  " " ++ U32.show(i) ++ "," ++ U32.show(v)

# Where the frame with the message differs from the same frame without
# it: how many pixels, and the first four, each its index in the frame
# and the palette index the line left there.
def said.go(off: List<&2, U32>, on: List<&2, U32>, +i: U32, +n: U32, +text: String) -> U32 & String:
  match off on:
    case a <> as +b <> bs:
      +hit = Bool.not(U32.is_eq(a, b))
      said.go(as, bs, (i + 1 : U32), (n + Bool.to_u32(hit) : U32),
        Bool.pick(String, Bool.and(hit, U32.is_lt(n, 4)), text ++ said.at((i + G.Gfx.frame() : U32), b), text))
    case _ _:
      (n, text)

def said.show(+shown: U32, tics: U32, r: U32 & String, mem: Array<U32>) -> Array<U32> & String:
  (n, first) = r
  (mem, "message " ++ U32.show(shown) ++ " \"" ++ Msg.Message.text(shown) ++ "\" tics " ++ U32.show(tics)
    ++ " pixels " ++ U32.show(n) ++ first)

def said.diff(+s: S.State, off: List<&2, U32>, p: Array<U32> & List<&2, U32>) -> Array<U32> & String:
  (mem, on) = p
  said.show(S.State.message(s), S.State.msgtics(s), said.go(off, on, 0, 0, ""), mem)

def said.on(+tables: P.Project.Tables, +gfx: G.Gfx, +s: S.State, p: Array<U32> & List<&2, U32>) ->
  Array<U32> & String:
  (mem, off) = p
  said.diff(s, off, band(R.Render.frame(tables, gfx, s, True{}, mem)))

# A frame with its message line drawn, beside the same frame without it:
# the line's own pixels, which tools/wad.nu's hu-line answers from the
# WAD's font.
def said(tag: String, +tables: P.Project.Tables, +gfx: G.Gfx, +s: S.State, mem: Array<U32>) -> IO(Array<U32>):
  print(tag, said.on(tables, gfx, s, band(R.Render.frame(tables, gfx, s, False{}, mem))))

# The level's first state with the player at rest on the floor at a
# place: x and y in map units, west and south given as negatives, the
# angle in degrees.
def at(+level: L.Level, x: U32, y: U32, degrees: U32) -> S.State:
  S.State.at(level, L.Start{x, y, A.Angle.of_thing(degrees)})

def east(units: U32) -> U32:
  F.Fixed.of_map(units)

def west(units: U32) -> U32:
  F.Fixed.neg(F.Fixed.of_map(units))

# The state after running east from the start for some tics.
def ran(+level: L.Level, tics: Nat) -> S.State:
  S.Sim.replay(List.replicate(K.Cmd, tics, K.Cmd.demo(50, 0, 0, 0)),
    S.State.start(level))

# The state after runs of commands in a demo's units from a place: the
# scripts the oracle plays.
def after(runs: List<&2, List<&2, K.Cmd>>, s: S.State) -> S.State:
  S.Sim.replay(List.concat(&2, K.Cmd, runs), s)

def strafe(n: Nat) -> List<&2, K.Cmd>:
  List.replicate(K.Cmd, n, K.Cmd.demo(0, 4294967272, 0, 0))

def idle(n: Nat) -> List<&2, K.Cmd>:
  List.replicate(K.Cmd, n, K.Cmd.idle())

# A place after the oracle's 20 idle tics.
def rested(+level: L.Level, x: U32, y: U32, degrees: U32) -> S.State:
  S.Sim.replay(idle(20n), at(level, x, y, degrees))

def walk(n: Nat) -> List<&2, K.Cmd>:
  List.replicate(K.Cmd, n, K.Cmd.demo(25, 0, 0, 0))

def back(n: Nat) -> List<&2, K.Cmd>:
  List.replicate(K.Cmd, n, K.Cmd.demo(4294967271, 0, 0, 0))

# Ctrl held for one tic, then the four tics S_PISTOL1 lasts: the frame
# is the one A_FirePistol made, with the muzzle flash showing and its
# extra light on every wall, plane and sprite.
def fired(n: Nat) -> List<&2, K.Cmd>:
  List.append(&2, K.Cmd, [K.Cmd.demo(0, 0, 0, 1)], idle(n))

def first() -> List<&2, K.Cmd>:
  [K.Cmd.demo(0, 0, 0, 4)]

# A pickup strafed past: the idle tics, a turn, then strafing left.
def strafed(turn: U32, n: Nat, s: S.State) -> S.State:
  after([idle(20n), [K.Cmd.demo(0, 0, turn, 0)], strafe(n)], s)

# Every weapon and every ammo type at its cap, so that no ammo or weapon
# pickup can be taken.
def maxed(inv: I.Inventory) -> I.Inventory:
  I.Inventory{health, armour, armourtype, cards, ammo, +caps, backpack, weapons, powers, items, bonus, line,
    kills, secrets} = inv
  I.Inventory{health, armour, armourtype, cards, caps, caps, backpack, 511, powers, items, bonus, line,
    kills, secrets}

def full(s: S.State) -> S.State:
  S.State{p, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn, secrets} = s
  S.State{S.Player.holding(p, maxed(I.Inventory.start())), level, things, sidetex, thinkers, rnd, clock, ended,
    usedown, sounds, mrnd, reborn, secrets}

def frames(mem: Array<U32>, gl: G.Gfx & L.Level) -> IO(Unit):
  (+gfx, +level) = gl
  +tables = P.Project.tables(level)
  do IO<Unit>:
    fight : List<&2, K.Cmd> <- Rt.Route.fight()
    m1 : Array<U32> <- frame("start", tables, gfx, S.Sim.replay(idle(20n), S.State.start(level)), mem)
    m2 : Array<U32> <- frame("lit 736 464 135", tables, gfx, rested(level, east(736), east(464), 135), m1)
    m3 : Array<U32> <- frame("dark -416 256 90", tables, gfx, rested(level, west(416), east(256), 90), m2)
    m4 : Array<U32> <- frame("step 137 256 45", tables, gfx, rested(level, east(137), east(256), 45), m3)
    m5 : Array<U32> <- frame("grate -416 256 180", tables, gfx, rested(level, west(416), east(256), 180), m4)
    m6 : Array<U32> <- frame("water 3 256 0", tables, gfx, rested(level, east(3), east(256), 0), m5)
    m7 : Array<U32> <- frame("sky -640 256 90", tables, gfx, rested(level, west(640), east(256), 90), m6)
    m8 : Array<U32> <- frame("pit 488 320 0", tables, gfx, rested(level, east(488), east(320), 0), m7)
    m9 : Array<U32> <- frame("sergeant 1144 259 315", tables, gfx, rested(level, east(1144), east(259), 315), m8)
    s1 : Array<U32> <- frame("once 256 1088 0", tables, gfx, rested(level, east(256), east(1088), 0), m9)
    s2 : Array<U32> <- frame("overlap 2752 960 0", tables, gfx, rested(level, east(2752), east(960), 0), s1)
    s3 : Array<U32> <- frame("walls 704 256 0", tables, gfx, rested(level, east(704), east(256), 0), s2)
    s4 : Array<U32> <- frame("ledge 256 128 90", tables, gfx, rested(level, east(256), east(128), 90), s3)
    d1 : Array<U32> <- frame("yard -640 256 0", tables, gfx, rested(level, west(640), east(256), 0), s4)
    d2 : Array<U32> <- frame("bars 1024 200 0", tables, gfx, rested(level, east(1024), east(200), 0), d1)
    n1 : Array<U32> <- frame("demon head on 48 1616 180", tables, gfx,
      S.Sim.replay(idle(6n), at(level, east(48), east(1616), 180)), d2)
    n2 : Array<U32> <- frame("shotgun guy from behind 896 2048 270", tables, gfx,
      rested(level, east(896), east(2048), 270), n1)
    n3 : Array<U32> <- frame("shotgun guy from the side 987 1947 225", tables, gfx,
      rested(level, east(987), east(1947), 225), n2)
    n4 : Array<U32> <- frame("demon mirrored 2448 2112 0", tables, gfx,
      rested(level, east(2448), east(2112), 0), n3)
    m10 : Array<U32> <- frame("stride U!:34", tables, gfx, ran(level, 34n), n4)
    m11 : Array<U32> <- frame("air U!:56", tables, gfx, ran(level, 56n), m10)
    m12 : Array<U32> <- frame("landed U!:66", tables, gfx, ran(level, 66n), m11)
    m13 : Array<U32> <- frame("door half open", tables, gfx, after([idle(20n), walk(20n),
      [K.Cmd.demo(0, 0, 0, 2)], idle(20n)],
      at(level, east(448), east(1968), 90)), m12)
    m14 : Array<U32> <- frame("switch pressed", tables, gfx, after([idle(20n), walk(10n),
      [K.Cmd.demo(0, 0, 0, 2)], idle(27n)],
      at(level, east(2064), west(260), 90)), m13)
    m15 : Array<U32> <- frame("exit pressed", tables, gfx, after([idle(20n), [K.Cmd.demo(0, 0, 0, 2)],
      idle(10n)], at(level, west(352), east(1296), 180)), m14)
    m16 : Array<U32> <- frame("blink dark", tables, gfx, after([idle(66n)], at(level, east(640), east(712), 180)),
      m15)
    m17 : Array<U32> <- frame("key 2380 600 180 22", tables, gfx, after([idle(22n)],
      at(level, east(2380), east(600), 180)), m16)
    m18 : Array<U32> <- frame("key bright 23", tables, gfx, after([idle(23n)], at(level, east(2380), east(600), 180)),
      m17)
    m19 : Array<U32> <- frame("key before", tables, gfx, strafed(4294967280, 12n,
      at(level, east(2246), east(592), 180)), m18)
    m20 : Array<U32> <- frame("key after", tables, gfx, strafed(4294967280, 13n,
      at(level, east(2246), east(592), 180)), m19)
    m21 : Array<U32> <- frame("bonus before", tables, gfx, after([idle(20n), walk(18n)],
      at(level, east(2590), east(780), 90)), m20)
    m22 : Array<U32> <- frame("bonus after", tables, gfx, after([idle(20n), walk(19n)],
      at(level, east(2590), east(780), 90)), m21)
    m23 : Array<U32> <- frame("green armour before", tables, gfx, after([idle(20n), walk(11n)],
      at(level, east(1631), east(1008), 90)), m22)
    m24 : Array<U32> <- frame("green armour after", tables, gfx, after([idle(20n), walk(12n)],
      at(level, east(1631), east(1008), 90)), m23)
    m25 : Array<U32> <- frame("stimpack and medikit before", tables, gfx, rested(level, east(0), east(400), 90), m24)
    m26 : Array<U32> <- frame("stimpack and medikit refused", tables, gfx, after([idle(20n), walk(16n), back(24n)],
      at(level, east(0), east(400), 90)), m25)
    m27 : Array<U32> <- frame("rocket before", tables, gfx, strafed(16, 11n, at(level, east(714), west(1011), 90)), m26)
    m28 : Array<U32> <- frame("rocket after", tables, gfx, strafed(16, 12n, at(level, east(714), west(1011), 90)), m27)
    m29 : Array<U32> <- frame("rocket refused", tables, gfx, strafed(16, 12n,
      full(at(level, east(714), west(1011), 90))), m28)
    m30 : Array<U32> <- frame("chainsaw after", tables, gfx, strafed(4294967280, 13n,
      at(level, east(3158), east(2176), 180)), m29)
    m31 : Array<U32> <- frame("chainsaw refused", tables, gfx, strafed(4294967280, 13n,
      full(at(level, east(3158), east(2176), 180))), m30)
    w1 : Array<U32> <- frame("pistol rising 8", tables, gfx, after([idle(8n)], S.State.start(level)), m31)
    w2 : Array<U32> <- frame("pistol bob low 48", tables, gfx, after([idle(20n), walk(28n)], S.State.start(level)), w1)
    w3 : Array<U32> <- frame("pistol bob right 64", tables, gfx, after([idle(20n), walk(44n)], S.State.start(level)),
      w2)
    d1 : Array<U32> <- frame("dead 1600 1000 90", tables, gfx, after([idle(650n)],
      at(level, east(1600), east(1000), 90)), w3)
    r1 : Array<U32> <- frame("nukage 1600 1000 90", tables, gfx, after([idle(1n)],
      at(level, east(1600), east(1000), 90)), d1)
    w4 : Array<U32> <- frame("pistol firing 25", tables, gfx, after([idle(20n), fired(4n)], S.State.start(level)),
      r1)
    w5 : Array<U32> <- frame("pistol flash over 32", tables, gfx, after([idle(20n), fired(11n)],
      S.State.start(level)), w4)
    w6 : Array<U32> <- frame("puff on the ledge 25", tables, gfx, after([idle(20n), fired(4n)],
      at(level, east(704), east(256), 0)), w5)
    w7 : Array<U32> <- frame("shotgun lowering", tables, gfx, after([idle(20n), walk(5n), idle(8n)],
      at(level, east(824), east(896), 0)), w6)
    w8 : Array<U32> <- frame("shotgun at rest", tables, gfx, after([idle(20n), walk(5n), idle(40n)],
      at(level, east(824), east(896), 0)), w7)
    w9 : Array<U32> <- frame("shotgun firing", tables, gfx, after([idle(20n), walk(5n), idle(40n), fired(3n)],
      at(level, east(824), east(896), 0)), w8)
    w10 : Array<U32> <- frame("fist at rest", tables, gfx, after([idle(20n), first(), idle(40n)],
      S.State.start(level)), w9)
    w11 : Array<U32> <- frame("fist attacking", tables, gfx, after([idle(20n), first(), idle(40n), fired(4n)],
      S.State.start(level)), w10)
    w12 : Array<U32> <- frame("saw at rest", tables, gfx, after([idle(40n)], strafed(4294967280, 13n,
      at(level, east(3158), east(2176), 180))), w11)
    w13 : Array<U32> <- frame("saw attacking", tables, gfx, after([idle(40n), fired(4n)], strafed(4294967280, 13n,
      at(level, east(3158), east(2176), 180))), w12)
    w14 : Array<U32> <- frame("long fight 1453", tables, gfx,
      S.Sim.replay(fight, S.State.start(level)), w13)
    w15 : Array<U32> <- frame("zombieman firing 53", tables, gfx, after([idle(53n)],
      at(level, east(488), east(256), 0)), w14)
    w16 : Array<U32> <- frame("shotgun guy firing 61", tables, gfx, after([idle(61n)],
      at(level, east(144), east(1888), 0)), w15)
    g1 : Array<U32> <- frame("corpse crushed by door", tables, gfx, C.Combat.crushed(level), w16)
    n1 : Array<U32> <- said("said armour", tables, gfx, after([idle(20n), walk(12n)],
      at(level, east(1631), east(1008), 90)), g1)
    n2 : Array<U32> <- said("said key", tables, gfx, strafed(4294967280, 13n,
      at(level, east(2246), east(592), 180)), n1)
    n3 : Array<U32> <- said("said chainsaw", tables, gfx, strafed(4294967280, 13n,
      at(level, east(3158), east(2176), 180)), n2)
    n4 : Array<U32> <- said("said none", tables, gfx, S.Sim.replay(idle(20n), S.State.start(level)), n3)
    IO.print("end")

def words(xs: List<&2, U32>) -> String:
  List.show(~&2, ~U32, ~U32.show, xs)

def range(r: Cl.Clip.Range) -> String:
  Cl.Range{first, last} = r
  Nat.show(first) ++ ".." ++ Nat.show(last)

def ranges(rs: List<&2, Cl.Clip.Range>) -> String:
  List.show(~&2, ~Cl.Clip.Range, ~range, rs)

def some(m: Maybe<&2, U32>) -> String:
  Maybe.show(~&2, ~U32, ~U32.show, m)

def sil(s: U32 & U32 & U32) -> String:
  (kind, bottom, top) = s
  words([kind, bottom, top])

def vis(v: Z.Sprites.Vis) -> String:
  Z.Vis{x1, x2, scale, gx, gy, gz, gzt, mid, frac, step, patch, cmap, rank, nth} = v
  words([x1, x2, scale, gx, gy, gz, gzt, mid, frac, step, patch, cmap, rank, nth])

def viss(vs: List<&2, Z.Sprites.Vis>) -> String:
  List.show(~&2, ~Z.Sprites.Vis, ~vis, vs)

def col(c: Q.Masked.Col) -> String:
  Q.Col{x, top, scale, mid, iscale, cmap, cc, fc} = c
  words([x, top, scale, mid, iscale, cmap, cc, fc])

def step(s: N.Planes.Step) -> String:
  N.Step{xfrac, yfrac, xstep, ystep, cmap} = s
  words([xfrac, yfrac, xstep, ystep, cmap])

# A view from the origin at an angle, with the sine and tangent tables,
# and every column's angle, every row's slope and every column's
# distance scale one value.
def view(angle: U32, sine: V.Vec, tangent: V.Vec, xtoangle: U32, yslope: U32, distscale: U32) -> P.View:
  P.View{0, 0, 0, angle, 0, 0, P.Tables{sine, tangent, V.Leaf{0}, V.Leaf{0}, V.Leaf{xtoangle}, V.Leaf{yslope},
    V.Leaf{distscale}, V.Leaf{0}, 0}, 0}

def arithmetic() -> IO(Unit):
  +sines = V.Vec.of_list(T.Tables.finesine(), 10240)
  +tans = V.Vec.of_list(T.Tables.finetangent(), 4096)
  +solid = {[Cl.Range{10n, 20n}, Cl.Range{30n, 40n}, Cl.Range{50n, 60n}] : List<&2, Cl.Clip.Range>}
  +cols = P.Project.xtoangle([321, 320, 2, 0, 4294967295])
  do IO<Unit>:
    IO.print("clip " ++ ranges(Cl.Clip.add(21n, 29n, solid)))
    IO.print("gaps " ++ ranges(Cl.Clip.gaps(5n, 45n, solid)))
    IO.print("covers " ++ List.show(~&2, ~Bool, ~Bool.show, [Cl.Clip.covers(12n, 18n, [Cl.Range{10n, 20n}]),
      Cl.Clip.covers(12n, 25n, [Cl.Range{10n, 20n}])]))
    IO.print("focal " ++ U32.show(P.Project.focal(tans)))
    IO.print("tox " ++ words([P.Project.tox(65586, 10477766), P.Project.tox(65686, 10477766),
      P.Project.tox(4294901710, 10477766), P.Project.tox(4294901610, 10477766), P.Project.tox(25, 10477766)]))
    IO.print("xtoangle " ++ String.join([some(List.get(&2, U32, cols, 0n)), some(List.get(&2, U32, cols, 1n)),
      some(List.get(&2, U32, cols, 2n)), some(List.get(&2, U32, cols, 319n)), some(List.get(&2, U32, cols, 320n))], " "))
    IO.print("yslope " ++ words([P.Project.yslope(0), P.Project.yslope(83), P.Project.yslope(84), P.Project.yslope(167)]))
    IO.print("scale " ++ words([P.View.scale(view(0, sines, V.Leaf{0}, 0, 0, 0), 0, 0, 10485760),
      P.View.scale(view(0, sines, V.Leaf{0}, 0, 0, 0), 537395200, 0, 10485760),
      P.View.scale(view(0, sines, V.Leaf{0}, 0, 0, 0), 0, 0, 100),
      P.View.scale(view(0, sines, V.Leaf{0}, 0, 0, 0), 0, 0, 131072),
      P.View.scale(view(0, sines, V.Leaf{0}, 0, 0, 0), 0, 1073741824, 10485760)]))
    IO.print("scalelight " ++ words([P.Project.scalelight(0, 0), P.Project.scalelight(0, 47),
      P.Project.scalelight(15, 0), P.Project.scalelight(15, 47), P.Project.scalelight(8, 0),
      P.Project.scalelight(8, 47)]))
    IO.print("zlight " ++ words([P.Project.zlight(8, 0), P.Project.zlight(8, 7), P.Project.zlight(8, 127)]))
    IO.print("texcol " ++ words([Sg.Segs.texcol(view(0, V.Leaf{0}, tans, 0, 0, 0), 10485760, 4194304, 1073741824, 0),
      Sg.Segs.texcol(view(0, V.Leaf{0}, tans, 537395200, 0, 0), 10485760, 4194304, 1073741824, 0)]))
    IO.print("iscale " ++ words([Sg.Segs.iscale(65536), Sg.Segs.iscale(4194304), Sg.Segs.iscale(256)]))
    IO.print("wall colormap " ++ words([Sg.Segs.colormap(8, 65536), Sg.Segs.colormap(8, 4194304)]))
    IO.print("silhouettes " ++ String.join([
      sil(Sg.Segs.sil.of(True{}, False{}, L.Sector{524288, 8388608, 160}, L.Sector{0, 0, 0}, 3211264)),
      sil(Sg.Segs.sil.of(False{}, True{}, L.Sector{524288, 8388608, 160}, L.Sector{0, 8388608, 160}, 3211264)),
      sil(Sg.Segs.sil.of(False{}, False{}, L.Sector{524288, 8388608, 160}, L.Sector{524288, 8388608, 160}, 3211264)),
      sil(Sg.Segs.sil.of(False{}, False{}, L.Sector{524288, 8388608, 160}, L.Sector{524288, 524288, 160}, 3211264))],
      " "))
    IO.print("sprite 160 ahead " ++ viss(Fx.Sprite.at(1, 10485760, 0, 0)))
    IO.print("sprite 150 left " ++ viss(Fx.Sprite.at(2, 10485760, 9830400, 0)))
    IO.print("sprite 150 right mirrored " ++ viss(Fx.Sprite.at(3, 10485760, 4285136896, 1)))
    IO.print("sprite 400 left " ++ viss(Fx.Sprite.at(4, 10485760, 26214400, 0)))
    IO.print("sprite 320 ahead " ++ viss(Fx.Sprite.at(5, 20971520, 0, 0)))
    IO.print("sprite 308 left mirrored " ++ viss(Fx.Sprite.at(6, 20971520, 20185088, 1)))
    IO.print("sprite column " ++ col(Z.Sprites.col.of(0, Z.Vis{0, 21, 32768, 20971520, 20185088, 0, 3670016, 983040,
      2883583, 4294836224, 2000, 69120, 1, 6}, Z.Sprites.unclipped(), Z.Sprites.unclipped())))
    IO.print("sorted " ++ viss(List.sort(~Z.Sprites.Vis, ~Z.Sprites.before, [Fx.Sprite.vis(131072, 1, 5),
      Fx.Sprite.vis(65536, 2, 3), Fx.Sprite.vis(65536, 1, 9), Fx.Sprite.vis(65536, 1, 4)])))
    IO.print("shown " ++ words(Fx.Sprite.shown(Fx.Closed.ranked(6, 2097152, 0))))
    IO.print("shown moved " ++ words(Fx.Sprite.shown(Fx.Sprite.moved(Fx.Closed.ranked(6, 2097152, 0)))))
    IO.print("skycol " ++ words([N.Planes.skycol(view(0, V.Leaf{0}, V.Leaf{0}, 537395200, 0, 0), 0),
      N.Planes.skycol(view(1073741824, V.Leaf{0}, V.Leaf{0}, 537395200, 0, 0), 0)]))
    IO.print("flat colormap " ++ words([N.Planes.colormap(8, 13107200), N.Planes.colormap(8, 859832320)]))
    IO.print("flat scales " ++ words([N.Planes.xscale(view(0, sines, V.Leaf{0}, 0, 0, 0)),
      N.Planes.yscale(view(0, sines, V.Leaf{0}, 0, 0, 0))]))
    IO.print("flat step " ++ step(N.Planes.step(N.Flat{view(0, sines, V.Leaf{0}, 0, 20971520, 65537), 0, 409, 2686976,
      8, 0}, 84, 0)))
    IO.print("span " ++ words([D.Draw.span.pack(98304, 147456), D.Draw.span.spot(100665600)]))

def start(w: Array<U32> & G.Gfx & L.Level) -> IO(Unit):
  (mem, gl) = w
  frames(mem, gl)

def main() -> IO(Unit):
  do IO<Unit>:
    arithmetic()
    world : Array<U32> & G.Gfx & L.Level <- G.Gfx.open(1, 1)
    start(world)

#|clip [10..40, 50..60]
#|gaps [5..9, 21..29, 41..45]
#|covers [True, False]
#|focal 10477766
#|tox [1, 0, 320, 321, 160]
#|xtoangle Some(3222798336) Some(3222798336) Some(3222274048) Some(3222274048) Some(3221749760)
#|yslope [125577, 20971520, 20971520, 125577]
#|scale [65536, 65536, 4194304, 4194304, 256]
#|scalelight [31, 31, 0, 0, 28, 5]
#|zlight [0, 18, 28]
#|texcol [63, 4294967199]
#|iscale [65535, 1023, 16777215]
#|wall colormap [74240, 70400]
#|silhouettes [3, 2147483647, 2147483648] [3, 524288, 2147483648] [0, 0, 0] [3, 2147483647, 2147483648]
#|sprite 160 ahead [[128, 191, 65536, 10485760, 0, 0, 3670016, 983040, 0, 65536, 1000, 69120, 1, 1]]
#|sprite 150 left [[0, 41, 65536, 10485760, 9830400, 0, 3670016, 983040, 1441792, 65536, 1000, 69120, 1, 2]]
#|sprite 150 right mirrored [[278, 319, 65536, 10485760, 4285136896, 0, 3670016, 983040, 4194303, 4294901760, 2000, 69120, 1, 3]]
#|sprite 400 left []
#|sprite 320 ahead [[144, 175, 32768, 20971520, 0, 0, 3670016, 983040, 0, 131072, 1000, 69120, 1, 5]]
#|sprite 308 left mirrored [[0, 21, 32768, 20971520, 20185088, 0, 3670016, 983040, 2883583, 4294836224, 2000, 69120, 1, 6]]
#|sprite column [0, 5013504, 32768, 983040, 131072, 69120, 4294967295, 168]
#|sorted [[0, 0, 65536, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 4], [0, 0, 65536, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 9], [0, 0, 65536, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 3], [0, 0, 131072, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 5]]
#|shown [9, 5, 2]
#|shown moved [2, 9, 5]
#|skycol [128, 384]
#|flat colormap [74752, 76288]
#|flat scales [0, 409]
#|flat step [859832319, 4294639291, 0, 5366080, 76288]
#|span [100665600, 129]
#|start hash 3501647150 pixels 1 1 7 5 96 72 covered True palette 0
#|lit 736 464 135 hash 1888788078 pixels 106 8 95 105 96 72 covered True palette 0
#|dark -416 256 90 hash 1364473328 pixels 110 107 0 238 96 72 covered True palette 0
#|step 137 256 45 hash 2880593419 pixels 8 0 79 6 96 72 covered True palette 0
#|grate -416 256 180 hash 442390666 pixels 3 111 106 93 96 72 covered True palette 0
#|water 3 256 0 hash 1102040513 pixels 2 6 77 6 96 72 covered True palette 0
#|sky -640 256 90 hash 4130793025 pixels 239 14 239 105 96 72 covered True palette 0
#|pit 488 320 0 hash 1510042988 pixels 79 110 150 6 96 72 covered True palette 0
#|sergeant 1144 259 315 hash 4195031459 pixels 111 108 0 1 96 72 covered True palette 0
#|once 256 1088 0 hash 2442400286 pixels 110 79 105 7 96 64 covered True palette 0
#|overlap 2752 960 0 hash 17648109 pixels 79 125 10 78 96 72 covered True palette 0
#|walls 704 256 0 hash 2399935752 pixels 7 111 15 2 96 64 covered True palette 0
#|ledge 256 128 90 hash 1443497237 pixels 7 5 15 110 96 72 covered True palette 0
#|yard -640 256 0 hash 1684750053 pixels 1 100 78 8 96 72 covered True palette 0
#|bars 1024 200 0 hash 439285215 pixels 109 79 5 5 96 72 covered True palette 0
#|demon head on 48 1616 180 hash 3057454219 pixels 2 7 111 243 96 59 covered True palette 0
#|shotgun guy from behind 896 2048 270 hash 3729950378 pixels 5 109 0 5 96 72 covered True palette 0
#|shotgun guy from the side 987 1947 225 hash 3040449328 pixels 5 6 109 108 96 72 covered True palette 0
#|demon mirrored 2448 2112 0 hash 2350286645 pixels 39 2 6 79 96 72 covered True palette 0
#|stride U!:34 hash 250131952 pixels 2 5 164 6 96 72 covered True palette 0
#|air U!:56 hash 2263461618 pixels 5 110 15 6 96 64 covered True palette 0
#|landed U!:66 hash 36073354 pixels 6 110 14 79 96 64 covered True palette 10
#|door half open hash 1169190636 pixels 7 14 110 79 96 64 covered True palette 0
#|switch pressed hash 644900545 pixels 3 110 107 7 96 64 covered True palette 0
#|exit pressed hash 786890588 pixels 102 95 102 3 96 72 covered True palette 0
#|blink dark hash 2817285794 pixels 95 72 103 93 96 65 covered True palette 0
#|key 2380 600 180 22 hash 3985974813 pixels 5 1 6 110 96 72 covered True palette 0
#|key bright 23 hash 4138847691 pixels 5 1 6 110 96 72 covered True palette 0
#|key before hash 1404948097 pixels 6 10 5 89 96 72 covered True palette 0
#|key after hash 3335266453 pixels 105 10 2 89 96 72 covered True palette 11
#|bonus before hash 3197225618 pixels 11 79 78 6 96 59 covered True palette 0
#|bonus after hash 3441438830 pixels 10 78 2 11 96 59 covered True palette 10
#|green armour before hash 123771255 pixels 110 110 6 1 96 72 covered True palette 0
#|green armour after hash 4258495022 pixels 8 110 103 2 96 72 covered True palette 10
#|stimpack and medikit before hash 1702492025 pixels 111 109 7 111 96 72 covered True palette 0
#|stimpack and medikit refused hash 1432617097 pixels 110 108 2 107 96 59 covered True palette 0
#|rocket before hash 470823295 pixels 105 109 105 77 96 72 covered True palette 0
#|rocket after hash 3313621550 pixels 106 109 105 77 96 72 covered True palette 10
#|rocket refused hash 1341841577 pixels 106 109 105 77 160 72 covered True palette 0
#|chainsaw after hash 1752609615 pixels 5 5 137 141 96 79 covered True palette 10
#|chainsaw refused hash 2891739476 pixels 5 5 137 141 160 64 covered True palette 0
#|pistol rising 8 hash 1914842866 pixels 1 1 7 5 96 59 covered True palette 0
#|pistol bob low 48 hash 3833298116 pixels 1 79 1 245 96 59 covered True palette 0
#|pistol bob right 64 hash 1365740933 pixels 2 5 111 6 96 59 covered True palette 0
#|dead 1600 1000 90 hash 170486482 pixels 78 7 122 2 96 8 covered True palette 0
#|nukage 1600 1000 90 hash 3477668975 pixels 11 2 107 1 96 77 covered True palette 2
#|pistol firing 25 hash 3767616058 pixels 1 1 7 111 96 72 covered True palette 0
#|pistol flash over 32 hash 1365649270 pixels 1 1 7 5 96 72 covered True palette 0
#|puff on the ledge 25 hash 2607485146 pixels 7 110 15 2 96 64 covered True palette 0
#|shotgun lowering hash 68118957 pixels 158 79 79 93 96 64 covered True palette 0
#|shotgun at rest hash 4025498722 pixels 151 127 79 93 96 56 covered True palette 6
#|shotgun firing hash 3949973150 pixels 157 79 79 93 96 56 covered True palette 5
#|fist at rest hash 3224378688 pixels 1 1 7 5 96 59 covered True palette 0
#|fist attacking hash 1112766053 pixels 1 1 7 5 96 59 covered True palette 0
#|saw at rest hash 526584844 pixels 5 5 106 104 96 79 covered True palette 0
#|saw attacking hash 1344905693 pixels 5 5 107 104 96 79 covered True palette 0
#|long fight 1453 hash 275693603 pixels 2 2 143 2 160 44 covered True palette 10
#|zombieman firing 53 hash 1045804030 pixels 8 6 111 1 96 64 covered True palette 0
#|shotgun guy firing 61 hash 2580103865 pixels 8 7 5 7 96 79 covered True palette 5
#|corpse crushed by door hash 1079062495 pixels 7 75 106 79 96 64 covered True palette 0
#|said armour message 1 "Picked up the armor." tics 140 pixels 730 0,47 1,45 2,45 3,45
#|said key message 7 "Picked up a blue keycard." tics 140 pixels 901 0,47 1,45 2,45 3,45
#|said chainsaw message 15 "A chainsaw!  Find some meat!" tics 140 pixels 1030 3,47 4,45 5,189 16,47
#|said none message 0 "" tics 0 pixels 0
#|end
