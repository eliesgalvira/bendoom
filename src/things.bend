# Doom's info.c, P_SpawnMobj, P_SpawnMapThing, P_SetThingPosition,
# P_RemoveMobj, P_ZMovement and the state half of P_MobjThinker for the
# things Bendoom spawns: the definitions of the DoomEd types the
# shareware maps place, less the starts, the state rows they reach and
# the weapons' with their entries in d_items.c's weaponinfo, the
# map's THINGS records made the level's first things, the state half of
# a thing's tic, whose actions the sim runs, its rise by its vertical
# momentum under gravity, what a blow and a death leave on it, and the
# population with its blockmap and sector links.
import Base
import ./fixed.bend as F
import ./angle.bend as A
import ./level.bend as L
import ./random.bend as M
import ./vec.bend as V
import ./sound.bend as Sn

# A thing, Doom's mobj: its id, which names it for good (its THINGS
# record's index, or the next id past every one given for a thing spawned
# in play), its DoomEd type, its position with z on the floor or under the
# ceiling, the floor and ceiling it is held between, its facing, the
# sector under it, its state row, the tics left in it, its vertical
# momentum, and the rest of its mobj_t.
type Thing is Data:
  Thing{id: U32, kind: U32, x: U32, y: U32, z: U32, floorz: U32, ceilz: U32, angle: U32, sector: U32, state: U32,
    tics: U32, momz: U32, hurt: V.Vec}

# The rest of Doom's mobj_t, which the definition answers for until a
# blow, a death or a look changes it, twelve counts in one vector as
# the player's wound is: its health, the thing it is after (its own
# name for none), its reaction time, the threshold that keeps it on that
# target, the horizontal momentum a blow gave it, its flags, which
# P_KillMobj and A_Fall clear bits of, its height, which a death
# quarters, the player A_Look last looked at, the eight-way direction
# A_Chase walks it, the tics it keeps that direction, and its radius.
def Thing.hurt.health() -> U32:
  0

def Thing.hurt.target() -> U32:
  1

def Thing.hurt.reaction() -> U32:
  2

def Thing.hurt.threshold() -> U32:
  3

def Thing.hurt.momx() -> U32:
  4

def Thing.hurt.momy() -> U32:
  5

def Thing.hurt.flags() -> U32:
  6

def Thing.hurt.height() -> U32:
  7

def Thing.hurt.lastlook() -> U32:
  8

def Thing.hurt.movedir() -> U32:
  9

def Thing.hurt.movecount() -> U32:
  10

def Thing.hurt.radius() -> U32:
  11

# Doom's DI_NODIR, the ninth direction, which is none of the eight.
def Thing.nodir() -> U32:
  8

def Thing.hurt(th: Thing) -> V.Vec:
  Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics, momz, +hurt} = th
  hurt

def Thing.hurting(th: Thing, hurt: V.Vec) -> Thing:
  Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics, momz, was} = th
  Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics, momz, hurt}

# Doom's mobj->health, signed: a blow past it kills, and one past its
# negation gibs.
def Thing.health(th: Thing) -> U32:
  V.Vec.get(Thing.hurt(th), Thing.hurt.health())

# Doom's mobj->target: what the thing is after, its own name for
# nothing, which is what an explosion credits its kills to.
def Thing.target(th: Thing) -> U32:
  V.Vec.get(Thing.hurt(th), Thing.hurt.target())

def Thing.threshold(th: Thing) -> U32:
  V.Vec.get(Thing.hurt(th), Thing.hurt.threshold())

# One of the counts written back.
def Thing.counted(+th: Thing, +slot: U32, value: U32) -> Thing:
  Thing.hurting(th, V.Vec.set(Thing.hurt(th), slot, value))

def Thing.momx(th: Thing) -> U32:
  V.Vec.get(Thing.hurt(th), Thing.hurt.momx())

def Thing.momy(th: Thing) -> U32:
  V.Vec.get(Thing.hurt(th), Thing.hurt.momy())

# The mobj's live flags.
def Thing.flags(th: Thing) -> U32:
  V.Vec.get(Thing.hurt(th), Thing.hurt.flags())

# Doom's mobj->height in fixed point, the definition's until a death
# quarters it.
def Thing.height(th: Thing) -> U32:
  V.Vec.get(Thing.hurt(th), Thing.hurt.height())

# Whether a flag of the mask is set on the thing.
def Thing.flagged(th: Thing, +mask: U32) -> Bool:
  Bool.not(U32.is_zero((Thing.flags(th) .&. mask : U32)))

def Thing.ambush(th: Thing) -> Bool:
  Thing.flagged(th, 32)

def Thing.id(th: Thing) -> U32:
  Thing{+id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics, momz, hurt} = th
  id

def Thing.kind(th: Thing) -> U32:
  Thing{id, +kind, x, y, z, floorz, ceilz, angle, sector, state, tics, momz, hurt} = th
  kind

def Thing.x(th: Thing) -> U32:
  Thing{id, kind, +x, y, z, floorz, ceilz, angle, sector, state, tics, momz, hurt} = th
  x

def Thing.y(th: Thing) -> U32:
  Thing{id, kind, x, +y, z, floorz, ceilz, angle, sector, state, tics, momz, hurt} = th
  y

def Thing.z(th: Thing) -> U32:
  Thing{id, kind, x, y, +z, floorz, ceilz, angle, sector, state, tics, momz, hurt} = th
  z

def Thing.floorz(th: Thing) -> U32:
  Thing{id, kind, x, y, z, +floorz, ceilz, angle, sector, state, tics, momz, hurt} = th
  floorz

def Thing.momz(th: Thing) -> U32:
  Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics, +momz, hurt} = th
  momz

def Thing.tics(th: Thing) -> U32:
  Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, +tics, momz, hurt} = th
  tics

def Thing.angle(th: Thing) -> U32:
  Thing{id, kind, x, y, z, floorz, ceilz, +angle, sector, state, tics, momz, hurt} = th
  angle

def Thing.sector(th: Thing) -> U32:
  Thing{id, kind, x, y, z, floorz, ceilz, angle, +sector, state, tics, momz, hurt} = th
  sector

# The thing with some vertical momentum, which P_SpawnBlood gives.
def Thing.rising(th: Thing, momz: U32) -> Thing:
  Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics, was, hurt} = th
  Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics, momz, hurt}

# The thing with some tics left in the state it stands in.
def Thing.ticking(th: Thing, tics: U32) -> Thing:
  Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, was, momz, hurt} = th
  Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics, momz, hurt}

# The thing with the floor and ceiling a move left it between.
def Thing.between(th: Thing, +floorz: U32, +ceilz: U32) -> Thing:
  Thing{id, kind, x, y, z, was, old, angle, sector, state, tics, momz, hurt} = th
  Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics, momz, hurt}

# The player's id on a map with no start for it: one no record has.
def Thing.you() -> U32:
  4294967295

# Doom's S_NULL, the state that is no state: a thing that enters it
# removes itself, and a player sprite that enters it stops showing.
def Thing.null() -> U32:
  4294967295

# What a state row does as it is entered, Doom's action pointers: a
# weapon's A_Raise, A_WeaponReady, A_FirePistol, A_FireShotgun,
# A_FireCGun, A_Punch, A_Saw, A_ReFire and A_Lower, a mobj's A_Pain,
# A_Scream (A_PlayerScream on the player's own rows), A_XScream,
# A_Fall, A_Explode, A_Look, A_Chase, A_FaceTarget, A_PosAttack and
# A_SPosAttack, or nothing. A row of one kind never holds the other's.
type Thing.Action is Data:
  Null{}
  Raise{}
  WeaponReady{}
  FirePistol{}
  FireShotgun{}
  FireCGun{}
  Punch{}
  Saw{}
  ReFire{}
  Lower{}
  Pain{}
  Scream{}
  XScream{}
  Fall{}
  Explode{}
  Look{}
  Chase{}
  Face{}
  PosAttack{}
  SPosAttack{}
  TroopAttack{}
  SargAttack{}

# A state row, Doom's state_t: the sprite's four-letter name, the frame
# (0 for A), whether it is full-bright, its tics, the row after it, its
# action, and the extra light a muzzle flash showing it lends the view.
# A row of -1 tics lasts, and it stores itself as its next, where
# vanilla's is S_NULL; no tic reads it, and the sprite load's chase stops
# there. Vanilla sets the extra light from A_Light0, A_Light1 and
# A_Light2, which no state but a flash's carries and which always run as
# that state is entered, so the row says it and the player need not.
type Thing.Row is Data:
  Row{sprite: String, frame: U32, bright: Bool, tics: U32, next: U32, action: Thing.Action, light: U32}

# The state rows by Bendoom's number, appended a group at a time as
# types and weapons arrived. Row 238 is vanilla's S_NULL row, which the
# teleport destination stands in. A monster's second pain row leads back
# to its see state. Only player sprites' rows have 0 tics: the A_ReFire
# that ends the chainsaw's and the chaingun's attacks, and S_LIGHTDONE,
# row 84, which carries A_Light0 in vanilla and here only puts the light
# out by being the last row before S_NULL.
def Thing.rows() -> List<&2, Thing.Row>:
  [Row{"PLAY", 13, False{}, 4294967295, 0, Null{}, 0}, Row{"PLAY", 22, False{}, 4294967295, 1, Null{}, 0},
    Row{"POSS", 11, False{}, 4294967295, 2, Null{}, 0}, Row{"SPOS", 11, False{}, 4294967295, 3, Null{}, 0},
    Row{"TROO", 12, False{}, 4294967295, 4, Null{}, 0}, Row{"SARG", 13, False{}, 4294967295, 5, Null{}, 0},
    Row{"ARM1", 0, False{}, 6, 7, Null{}, 0}, Row{"ARM1", 1, True{}, 7, 6, Null{}, 0}, Row{"ARM2", 0, False{}, 6, 9, Null{}, 0},
    Row{"ARM2", 1, True{}, 6, 8, Null{}, 0}, Row{"BAR1", 0, False{}, 6, 11, Null{}, 0},
    Row{"BAR1", 1, False{}, 6, 10, Null{}, 0}, Row{"BON1", 0, False{}, 6, 13, Null{}, 0},
    Row{"BON1", 1, False{}, 6, 14, Null{}, 0}, Row{"BON1", 2, False{}, 6, 15, Null{}, 0},
    Row{"BON1", 3, False{}, 6, 16, Null{}, 0}, Row{"BON1", 2, False{}, 6, 17, Null{}, 0},
    Row{"BON1", 1, False{}, 6, 12, Null{}, 0}, Row{"BON2", 0, False{}, 6, 19, Null{}, 0},
    Row{"BON2", 1, False{}, 6, 20, Null{}, 0}, Row{"BON2", 2, False{}, 6, 21, Null{}, 0},
    Row{"BON2", 3, False{}, 6, 22, Null{}, 0}, Row{"BON2", 2, False{}, 6, 23, Null{}, 0},
    Row{"BON2", 1, False{}, 6, 18, Null{}, 0}, Row{"BKEY", 0, False{}, 10, 25, Null{}, 0},
    Row{"BKEY", 1, True{}, 10, 24, Null{}, 0}, Row{"STIM", 0, False{}, 4294967295, 26, Null{}, 0},
    Row{"MEDI", 0, False{}, 4294967295, 27, Null{}, 0}, Row{"SOUL", 0, True{}, 6, 29, Null{}, 0},
    Row{"SOUL", 1, True{}, 6, 30, Null{}, 0}, Row{"SOUL", 2, True{}, 6, 31, Null{}, 0},
    Row{"SOUL", 3, True{}, 6, 32, Null{}, 0}, Row{"SOUL", 2, True{}, 6, 33, Null{}, 0},
    Row{"SOUL", 1, True{}, 6, 28, Null{}, 0}, Row{"PSTR", 0, True{}, 4294967295, 34, Null{}, 0},
    Row{"CLIP", 0, False{}, 4294967295, 35, Null{}, 0}, Row{"AMMO", 0, False{}, 4294967295, 36, Null{}, 0},
    Row{"ROCK", 0, False{}, 4294967295, 37, Null{}, 0}, Row{"BROK", 0, False{}, 4294967295, 38, Null{}, 0},
    Row{"CELL", 0, False{}, 4294967295, 39, Null{}, 0}, Row{"CELP", 0, False{}, 4294967295, 40, Null{}, 0},
    Row{"SHEL", 0, False{}, 4294967295, 41, Null{}, 0}, Row{"SBOX", 0, False{}, 4294967295, 42, Null{}, 0},
    Row{"BPAK", 0, False{}, 4294967295, 43, Null{}, 0}, Row{"MGUN", 0, False{}, 4294967295, 44, Null{}, 0},
    Row{"CSAW", 0, False{}, 4294967295, 45, Null{}, 0}, Row{"LAUN", 0, False{}, 4294967295, 46, Null{}, 0},
    Row{"PLAS", 0, False{}, 4294967295, 47, Null{}, 0}, Row{"SHOT", 0, False{}, 4294967295, 48, Null{}, 0},
    Row{"COLU", 0, True{}, 4294967295, 49, Null{}, 0}, Row{"POL5", 0, False{}, 4294967295, 50, Null{}, 0},
    Row{"POL6", 0, False{}, 6, 52, Null{}, 0}, Row{"POL6", 1, False{}, 8, 51, Null{}, 0},
    Row{"GOR4", 0, False{}, 4294967295, 53, Null{}, 0}, Row{"SMIT", 0, False{}, 4294967295, 54, Null{}, 0},
    Row{"CBRA", 0, True{}, 4294967295, 55, Null{}, 0}, Row{"TRE1", 0, False{}, 4294967295, 56, Null{}, 0},
    Row{"TRE2", 0, False{}, 4294967295, 57, Null{}, 0}, Row{"ELEC", 0, False{}, 4294967295, 58, Null{}, 0},
    Row{"PISG", 0, False{}, 1, 59, WeaponReady{}, 0}, Row{"PISG", 0, False{}, 1, 60, Raise{}, 0},
    Row{"POSS", 0, False{}, 10, 62, Look{}, 0}, Row{"POSS", 1, False{}, 10, 61, Look{}, 0},
    Row{"SPOS", 0, False{}, 10, 64, Look{}, 0}, Row{"SPOS", 1, False{}, 10, 63, Look{}, 0},
    Row{"TROO", 0, False{}, 10, 66, Look{}, 0}, Row{"TROO", 1, False{}, 10, 65, Look{}, 0},
    Row{"SARG", 0, False{}, 10, 68, Look{}, 0}, Row{"SARG", 1, False{}, 10, 67, Look{}, 0},
    Row{"PISG", 0, False{}, 1, 69, Lower{}, 0}, Row{"PLAY", 0, False{}, 4294967295, 70, Null{}, 0},
    Row{"PLAY", 6, False{}, 4, 72, Null{}, 0}, Row{"PLAY", 6, False{}, 4, 70, Pain{}, 0},
    Row{"PLAY", 7, False{}, 10, 74, Null{}, 0}, Row{"PLAY", 8, False{}, 10, 75, Scream{}, 0},
    Row{"PLAY", 9, False{}, 10, 76, Null{}, 0}, Row{"PLAY", 10, False{}, 10, 77, Null{}, 0},
    Row{"PLAY", 11, False{}, 10, 78, Null{}, 0}, Row{"PLAY", 12, False{}, 10, 0, Null{}, 0},
    Row{"PISG", 0, False{}, 4, 80, Null{}, 0}, Row{"PISG", 1, False{}, 6, 81, FirePistol{}, 0},
    Row{"PISG", 2, False{}, 4, 82, Null{}, 0}, Row{"PISG", 1, False{}, 5, 59, ReFire{}, 0},
    Row{"PISF", 0, True{}, 7, 84, Null{}, 1}, Row{"SHTG", 4, False{}, 0, 4294967295, Null{}, 0},
    Row{"PUFF", 0, True{}, 4, 86, Null{}, 0}, Row{"PUFF", 1, False{}, 4, 87, Null{}, 0},
    Row{"PUFF", 2, False{}, 4, 88, Null{}, 0}, Row{"PUFF", 3, False{}, 4, 4294967295, Null{}, 0},
    Row{"POSS", 0, False{}, 4, 90, Chase{}, 0}, Row{"POSS", 0, False{}, 4, 91, Chase{}, 0},
    Row{"POSS", 1, False{}, 4, 92, Chase{}, 0}, Row{"POSS", 1, False{}, 4, 93, Chase{}, 0},
    Row{"POSS", 2, False{}, 4, 94, Chase{}, 0}, Row{"POSS", 2, False{}, 4, 95, Chase{}, 0},
    Row{"POSS", 3, False{}, 4, 96, Chase{}, 0}, Row{"POSS", 3, False{}, 4, 89, Chase{}, 0},
    Row{"SPOS", 0, False{}, 3, 98, Chase{}, 0}, Row{"SPOS", 0, False{}, 3, 99, Chase{}, 0},
    Row{"SPOS", 1, False{}, 3, 100, Chase{}, 0}, Row{"SPOS", 1, False{}, 3, 101, Chase{}, 0},
    Row{"SPOS", 2, False{}, 3, 102, Chase{}, 0}, Row{"SPOS", 2, False{}, 3, 103, Chase{}, 0},
    Row{"SPOS", 3, False{}, 3, 104, Chase{}, 0}, Row{"SPOS", 3, False{}, 3, 97, Chase{}, 0},
    Row{"TROO", 0, False{}, 3, 106, Chase{}, 0}, Row{"TROO", 0, False{}, 3, 107, Chase{}, 0},
    Row{"TROO", 1, False{}, 3, 108, Chase{}, 0}, Row{"TROO", 1, False{}, 3, 109, Chase{}, 0},
    Row{"TROO", 2, False{}, 3, 110, Chase{}, 0}, Row{"TROO", 2, False{}, 3, 111, Chase{}, 0},
    Row{"TROO", 3, False{}, 3, 112, Chase{}, 0}, Row{"TROO", 3, False{}, 3, 105, Chase{}, 0},
    Row{"SARG", 0, False{}, 2, 114, Chase{}, 0}, Row{"SARG", 0, False{}, 2, 115, Chase{}, 0},
    Row{"SARG", 1, False{}, 2, 116, Chase{}, 0}, Row{"SARG", 1, False{}, 2, 117, Chase{}, 0},
    Row{"SARG", 2, False{}, 2, 118, Chase{}, 0}, Row{"SARG", 2, False{}, 2, 119, Chase{}, 0},
    Row{"SARG", 3, False{}, 2, 120, Chase{}, 0}, Row{"SARG", 3, False{}, 2, 113, Chase{}, 0},
    Row{"POSS", 6, False{}, 3, 122, Null{}, 0}, Row{"POSS", 6, False{}, 3, 89, Pain{}, 0},
    Row{"POSS", 7, False{}, 5, 124, Null{}, 0}, Row{"POSS", 8, False{}, 5, 125, Scream{}, 0},
    Row{"POSS", 9, False{}, 5, 126, Fall{}, 0}, Row{"POSS", 10, False{}, 5, 127, Null{}, 0},
    Row{"POSS", 11, False{}, 4294967295, 127, Null{}, 0}, Row{"POSS", 12, False{}, 5, 129, Null{}, 0},
    Row{"POSS", 13, False{}, 5, 130, XScream{}, 0}, Row{"POSS", 14, False{}, 5, 131, Fall{}, 0},
    Row{"POSS", 15, False{}, 5, 132, Null{}, 0}, Row{"POSS", 16, False{}, 5, 133, Null{}, 0},
    Row{"POSS", 17, False{}, 5, 134, Null{}, 0}, Row{"POSS", 18, False{}, 5, 135, Null{}, 0},
    Row{"POSS", 19, False{}, 5, 136, Null{}, 0}, Row{"POSS", 20, False{}, 4294967295, 136, Null{}, 0},
    Row{"SPOS", 6, False{}, 3, 138, Null{}, 0}, Row{"SPOS", 6, False{}, 3, 97, Pain{}, 0},
    Row{"SPOS", 7, False{}, 5, 140, Null{}, 0}, Row{"SPOS", 8, False{}, 5, 141, Scream{}, 0},
    Row{"SPOS", 9, False{}, 5, 142, Fall{}, 0}, Row{"SPOS", 10, False{}, 5, 143, Null{}, 0},
    Row{"SPOS", 11, False{}, 4294967295, 143, Null{}, 0}, Row{"SPOS", 12, False{}, 5, 145, Null{}, 0},
    Row{"SPOS", 13, False{}, 5, 146, XScream{}, 0}, Row{"SPOS", 14, False{}, 5, 147, Fall{}, 0},
    Row{"SPOS", 15, False{}, 5, 148, Null{}, 0}, Row{"SPOS", 16, False{}, 5, 149, Null{}, 0},
    Row{"SPOS", 17, False{}, 5, 150, Null{}, 0}, Row{"SPOS", 18, False{}, 5, 151, Null{}, 0},
    Row{"SPOS", 19, False{}, 5, 152, Null{}, 0}, Row{"SPOS", 20, False{}, 4294967295, 152, Null{}, 0},
    Row{"TROO", 7, False{}, 2, 154, Null{}, 0}, Row{"TROO", 7, False{}, 2, 105, Pain{}, 0},
    Row{"TROO", 8, False{}, 8, 156, Null{}, 0}, Row{"TROO", 9, False{}, 8, 157, Scream{}, 0},
    Row{"TROO", 10, False{}, 6, 158, Null{}, 0}, Row{"TROO", 11, False{}, 6, 159, Fall{}, 0},
    Row{"TROO", 12, False{}, 4294967295, 159, Null{}, 0}, Row{"TROO", 13, False{}, 5, 161, Null{}, 0},
    Row{"TROO", 14, False{}, 5, 162, XScream{}, 0}, Row{"TROO", 15, False{}, 5, 163, Null{}, 0},
    Row{"TROO", 16, False{}, 5, 164, Fall{}, 0}, Row{"TROO", 17, False{}, 5, 165, Null{}, 0},
    Row{"TROO", 18, False{}, 5, 166, Null{}, 0}, Row{"TROO", 19, False{}, 5, 167, Null{}, 0},
    Row{"TROO", 20, False{}, 4294967295, 167, Null{}, 0}, Row{"SARG", 7, False{}, 2, 169, Null{}, 0},
    Row{"SARG", 7, False{}, 2, 113, Pain{}, 0}, Row{"SARG", 8, False{}, 8, 171, Null{}, 0},
    Row{"SARG", 9, False{}, 8, 172, Scream{}, 0}, Row{"SARG", 10, False{}, 4, 173, Null{}, 0},
    Row{"SARG", 11, False{}, 4, 174, Fall{}, 0}, Row{"SARG", 12, False{}, 4, 175, Null{}, 0},
    Row{"SARG", 13, False{}, 4294967295, 175, Null{}, 0}, Row{"BEXP", 0, True{}, 5, 177, Null{}, 0},
    Row{"BEXP", 1, True{}, 5, 178, Scream{}, 0}, Row{"BEXP", 2, True{}, 5, 179, Null{}, 0},
    Row{"BEXP", 3, True{}, 10, 180, Explode{}, 0}, Row{"BEXP", 4, True{}, 10, 4294967295, Null{}, 0},
    Row{"BLUD", 2, False{}, 8, 182, Null{}, 0}, Row{"BLUD", 1, False{}, 8, 183, Null{}, 0},
    Row{"BLUD", 0, False{}, 8, 4294967295, Null{}, 0},
    Row{"POSS", 4, False{}, 10, 185, Face{}, 0}, Row{"POSS", 5, False{}, 8, 186, PosAttack{}, 0},
    Row{"POSS", 4, False{}, 8, 89, Null{}, 0},
    Row{"SPOS", 4, False{}, 10, 188, Face{}, 0}, Row{"SPOS", 5, True{}, 10, 189, SPosAttack{}, 0},
    Row{"SPOS", 4, False{}, 10, 97, Null{}, 0},
    Row{"TROO", 4, False{}, 8, 191, Face{}, 0}, Row{"TROO", 5, False{}, 8, 192, Face{}, 0},
    Row{"TROO", 6, False{}, 6, 105, TroopAttack{}, 0},
    Row{"SARG", 4, False{}, 8, 194, Face{}, 0}, Row{"SARG", 5, False{}, 8, 195, Face{}, 0},
    Row{"SARG", 6, False{}, 8, 113, SargAttack{}, 0},
    Row{"BAL1", 0, True{}, 4, 197, Null{}, 0}, Row{"BAL1", 1, True{}, 4, 196, Null{}, 0},
    Row{"BAL1", 2, True{}, 6, 199, Null{}, 0}, Row{"BAL1", 3, True{}, 6, 200, Null{}, 0},
    Row{"BAL1", 4, True{}, 6, 4294967295, Null{}, 0},
    Row{"SHTG", 0, False{}, 1, 201, WeaponReady{}, 0}, Row{"SHTG", 0, False{}, 1, 202, Lower{}, 0},
    Row{"SHTG", 0, False{}, 1, 203, Raise{}, 0}, Row{"SHTG", 0, False{}, 3, 205, Null{}, 0},
    Row{"SHTG", 0, False{}, 7, 206, FireShotgun{}, 0}, Row{"SHTG", 1, False{}, 5, 207, Null{}, 0},
    Row{"SHTG", 2, False{}, 5, 208, Null{}, 0}, Row{"SHTG", 3, False{}, 4, 209, Null{}, 0},
    Row{"SHTG", 2, False{}, 5, 210, Null{}, 0}, Row{"SHTG", 1, False{}, 5, 211, Null{}, 0},
    Row{"SHTG", 0, False{}, 3, 212, Null{}, 0}, Row{"SHTG", 0, False{}, 7, 201, ReFire{}, 0},
    Row{"SHTF", 0, True{}, 4, 214, Null{}, 1}, Row{"SHTF", 1, True{}, 3, 84, Null{}, 2},
    Row{"PUNG", 0, False{}, 1, 215, WeaponReady{}, 0}, Row{"PUNG", 0, False{}, 1, 216, Lower{}, 0},
    Row{"PUNG", 0, False{}, 1, 217, Raise{}, 0}, Row{"PUNG", 1, False{}, 4, 219, Null{}, 0},
    Row{"PUNG", 2, False{}, 4, 220, Punch{}, 0}, Row{"PUNG", 3, False{}, 5, 221, Null{}, 0},
    Row{"PUNG", 2, False{}, 4, 222, Null{}, 0}, Row{"PUNG", 1, False{}, 5, 215, ReFire{}, 0},
    Row{"SAWG", 2, False{}, 4, 224, WeaponReady{}, 0}, Row{"SAWG", 3, False{}, 4, 223, WeaponReady{}, 0},
    Row{"SAWG", 2, False{}, 1, 225, Lower{}, 0}, Row{"SAWG", 2, False{}, 1, 226, Raise{}, 0},
    Row{"SAWG", 0, False{}, 4, 228, Saw{}, 0}, Row{"SAWG", 1, False{}, 4, 229, Saw{}, 0},
    Row{"SAWG", 1, False{}, 0, 223, ReFire{}, 0},
    Row{"CHGG", 0, False{}, 1, 230, WeaponReady{}, 0}, Row{"CHGG", 0, False{}, 1, 231, Lower{}, 0},
    Row{"CHGG", 0, False{}, 1, 232, Raise{}, 0}, Row{"CHGG", 0, False{}, 4, 234, FireCGun{}, 0},
    Row{"CHGG", 1, False{}, 4, 235, FireCGun{}, 0}, Row{"CHGG", 1, False{}, 0, 230, ReFire{}, 0},
    Row{"CHGF", 0, True{}, 5, 84, Null{}, 1}, Row{"CHGF", 1, True{}, 5, 84, Null{}, 2},
    Row{"TROO", 0, False{}, 4294967295, 238, Null{}, 0},
    Row{"YKEY", 0, False{}, 10, 240, Null{}, 0}, Row{"YKEY", 1, True{}, 10, 239, Null{}, 0},
    Row{"RKEY", 0, False{}, 10, 242, Null{}, 0}, Row{"RKEY", 1, True{}, 10, 241, Null{}, 0},
    Row{"CAND", 0, True{}, 4294967295, 243, Null{}, 0},
    Row{"TRED", 0, True{}, 4, 245, Null{}, 0}, Row{"TRED", 1, True{}, 4, 246, Null{}, 0},
    Row{"TRED", 2, True{}, 4, 247, Null{}, 0}, Row{"TRED", 3, True{}, 4, 244, Null{}, 0},
    Row{"PINS", 0, True{}, 6, 249, Null{}, 0}, Row{"PINS", 1, True{}, 6, 250, Null{}, 0},
    Row{"PINS", 2, True{}, 6, 251, Null{}, 0}, Row{"PINS", 3, True{}, 6, 248, Null{}, 0},
    Row{"SUIT", 0, True{}, 4294967295, 252, Null{}, 0},
    Row{"PMAP", 0, True{}, 6, 254, Null{}, 0}, Row{"PMAP", 1, True{}, 6, 255, Null{}, 0},
    Row{"PMAP", 2, True{}, 6, 256, Null{}, 0}, Row{"PMAP", 3, True{}, 6, 257, Null{}, 0},
    Row{"PMAP", 2, True{}, 6, 258, Null{}, 0}, Row{"PMAP", 1, True{}, 6, 253, Null{}, 0},
    Row{"PVIS", 0, True{}, 6, 260, Null{}, 0}, Row{"PVIS", 1, False{}, 6, 259, Null{}, 0},
    Row{"BOSS", 0, False{}, 10, 262, Look{}, 0}, Row{"BOSS", 1, False{}, 10, 261, Look{}, 0},
    Row{"BOSS", 0, False{}, 3, 264, Chase{}, 0}, Row{"BOSS", 0, False{}, 3, 265, Chase{}, 0},
    Row{"BOSS", 1, False{}, 3, 266, Chase{}, 0}, Row{"BOSS", 1, False{}, 3, 267, Chase{}, 0},
    Row{"BOSS", 2, False{}, 3, 268, Chase{}, 0}, Row{"BOSS", 2, False{}, 3, 269, Chase{}, 0},
    Row{"BOSS", 3, False{}, 3, 270, Chase{}, 0}, Row{"BOSS", 3, False{}, 3, 263, Chase{}, 0},
    Row{"BOSS", 7, False{}, 2, 272, Null{}, 0}, Row{"BOSS", 7, False{}, 2, 263, Pain{}, 0},
    Row{"BOSS", 8, False{}, 8, 274, Null{}, 0}, Row{"BOSS", 9, False{}, 8, 275, Scream{}, 0},
    Row{"BOSS", 10, False{}, 8, 276, Null{}, 0}, Row{"BOSS", 11, False{}, 8, 277, Fall{}, 0},
    Row{"BOSS", 12, False{}, 8, 278, Null{}, 0}, Row{"BOSS", 13, False{}, 8, 279, Null{}, 0},
    Row{"BOSS", 14, False{}, 4294967295, 279, Null{}, 0}]

def Thing.row(s: U32) -> Thing.Row:
  Maybe.default(&2, Thing.Row, List.get(&2, Thing.Row, Thing.rows(), U32.to_nat(s)),
    Row{"", 0, False{}, 0, 0, Null{}, 0})

def Thing.Row.tics(r: Thing.Row) -> U32:
  Row{sprite, frame, bright, tics, next, action, light} = r
  tics

def Thing.Row.bright(r: Thing.Row) -> Bool:
  Row{sprite, frame, bright, tics, next, action, light} = r
  bright

def Thing.Row.next(r: Thing.Row) -> U32:
  Row{sprite, frame, bright, tics, next, action, light} = r
  next

def Thing.Row.action(r: Thing.Row) -> Thing.Action:
  Row{sprite, frame, bright, tics, next, action, light} = r
  action

# Doom's extralight for a player sprite showing this row.
def Thing.Row.light(r: Thing.Row) -> U32:
  Row{sprite, frame, bright, tics, next, action, light} = r
  light

# A weapon's row in Doom's weaponinfo: the states it rises, is ready,
# sinks and fires in, its muzzle flash's, and the ammotype_t it spends,
# which the status bar counts.
type Thing.Weapon is Data:
  Weapon{up: U32, ready: U32, down: U32, ammo: U32, atk: U32, flash: U32}

# d_items.c's weaponinfo for the pistol: it rises in row 60, rests in
# row 59, sinks in row 69, spends am_clip, ammotype_t 0, fires from row
# 79 and flashes in row 83.
def Thing.pistol() -> Thing.Weapon:
  Weapon{60, 59, 69, 0, 79, 83}

def Thing.shotgun() -> Thing.Weapon:
  Weapon{203, 201, 202, 1, 204, 213}

def Thing.fist() -> Thing.Weapon:
  Weapon{217, 215, 216, 4, 218, 0}

def Thing.saw() -> Thing.Weapon:
  Weapon{226, 223, 225, 4, 227, 0}

def Thing.chaingun() -> Thing.Weapon:
  Weapon{232, 230, 231, 0, 233, 236}

# weaponinfo by weapontype_t, from wp_fist. The launcher, the plasma
# rifle and the BFG fire nothing yet and hold the pistol's row.
def Thing.weapons() -> List<&2, Thing.Weapon>:
  [Thing.fist(), Thing.pistol(), Thing.shotgun(), Thing.chaingun(), Thing.pistol(), Thing.pistol(), Thing.pistol(),
    Thing.saw()]

def Thing.weapon(+weapon: U32) -> Thing.Weapon:
  Maybe.default(&2, Thing.Weapon, List.get(&2, Thing.Weapon, Thing.weapons(), U32.to_nat(weapon)), Thing.pistol())

def Thing.Weapon.down(w: Thing.Weapon) -> U32:
  Weapon{up, ready, down, ammo, atk, flash} = w
  down

def Thing.Weapon.up(w: Thing.Weapon) -> U32:
  Weapon{up, ready, down, ammo, atk, flash} = w
  up

def Thing.Weapon.ready(w: Thing.Weapon) -> U32:
  Weapon{up, ready, down, ammo, atk, flash} = w
  ready

def Thing.Weapon.ammo(w: Thing.Weapon) -> U32:
  Weapon{up, ready, down, ammo, atk, flash} = w
  ammo

def Thing.Weapon.atk(w: Thing.Weapon) -> U32:
  Weapon{up, ready, down, ammo, atk, flash} = w
  atk

def Thing.Weapon.flash(w: Thing.Weapon) -> U32:
  Weapon{up, ready, down, ammo, atk, flash} = w
  flash

# The player mobj's rows in Doom's mobjinfo: the state it stands in,
# the one it flinches in and the one its death begins with. Its spawn
# health, 100, is the inventory's.
def Thing.play() -> U32:
  70

def Thing.play.pain() -> U32:
  71

def Thing.play.death() -> U32:
  73

def Thing.state(th: Thing) -> U32:
  Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics, momz, hurt} = th
  state

# Whether the state lasts, Doom's tics of -1.
def Thing.lasting(th: Thing) -> Bool:
  Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, +tics, momz, hurt} = th
  U32.is_eq(tics, 4294967295)

# Whether the tic about to be spent is the state's last.
def Thing.over(th: Thing) -> Bool:
  Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, +tics, momz, hurt} = th
  U32.is_eq(tics, 1)

# One tic of the state spent.
def Thing.spent(th: Thing) -> Thing:
  Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, +tics, momz, hurt} = th
  Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, (tics - 1 : U32), momz, hurt}

# The thing having looked: Doom's P_LookForPlayers leaves lastlook at
# the one player in the game whether it found it or not.
def Thing.looked(+th: Thing) -> Thing:
  Thing.hurting(th, V.Vec.set(Thing.hurt(th), Thing.hurt.lastlook(), 0))

# Doom's P_LookForPlayers with one player in the game: the loop starts
# at lastlook and stops at (lastlook - 1) & 3, so a monster that spawned
# looking at player 2 reaches player 1 on the turn that stops it and
# sees nothing at all. Every other start reaches player 1 first.
def Thing.blind(th: Thing) -> Bool:
  U32.is_eq(V.Vec.get(Thing.hurt(th), Thing.hurt.lastlook()), 1)

# The state half of Doom's P_SetMobjState: the thing in a state, for
# that state's tics. The action the state runs on entry is the sim's,
# which has the rest of the game to run it against.
def Thing.entering(th: Thing, +state: U32) -> Thing:
  Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, was, tics, momz, hurt} = th
  Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, Thing.Row.tics(Thing.row(state)), momz, hurt}

# A type's mobjinfo_t: its DoomEd type, its spawn state's row, its
# radius and height in map units, vanilla's flags: 1 special, 2
# solid, 4 shootable, 8 in no sector's list, 16 in no blockmap cell, 256
# hung from the ceiling, 512 no gravity, 262144 shadow, 524288 no blood,
# 4194304 a kill and 8388608 an item the tally counts, 33554432 not in
# deathmatch.
type Thing.Def is Data:
  Def{kind: U32, state: U32, radius: U32, height: U32, flags: U32}

def Thing.defs() -> List<&2, Thing.Def>:
  [Def{5, 24, 20, 16, 33554433}, Def{8, 43, 20, 16, 1}, Def{10, 1, 20, 16, 0}, Def{12, 1, 20, 16, 0},
    Def{15, 0, 20, 16, 0}, Def{17, 40, 20, 16, 1}, Def{18, 2, 20, 16, 0}, Def{19, 3, 20, 16, 0},
    Def{20, 4, 20, 16, 0}, Def{21, 5, 20, 16, 0}, Def{24, 50, 20, 16, 0}, Def{26, 51, 16, 16, 2},
    Def{35, 55, 16, 16, 2}, Def{43, 56, 16, 16, 2}, Def{47, 54, 16, 16, 2}, Def{48, 58, 16, 16, 2},
    Def{54, 57, 32, 16, 2}, Def{60, 53, 20, 68, 768}, Def{2001, 48, 20, 16, 1}, Def{2002, 44, 20, 16, 1},
    Def{2003, 46, 20, 16, 1}, Def{2004, 47, 20, 16, 1}, Def{2005, 45, 20, 16, 1}, Def{2007, 35, 20, 16, 1},
    Def{2008, 41, 20, 16, 1}, Def{2010, 37, 20, 16, 1}, Def{2011, 26, 20, 16, 1}, Def{2012, 27, 20, 16, 1},
    Def{2013, 28, 20, 16, 8388609}, Def{2014, 12, 20, 16, 8388609}, Def{2015, 18, 20, 16, 8388609},
    Def{2018, 6, 20, 16, 1}, Def{2019, 8, 20, 16, 1}, Def{2023, 34, 20, 16, 8388609}, Def{2028, 49, 16, 16, 2},
    Def{2035, 10, 10, 42, 524294}, Def{2046, 38, 20, 16, 1}, Def{2047, 39, 20, 16, 1}, Def{2048, 36, 20, 16, 1},
    Def{2049, 42, 20, 16, 1}, Def{3004, 61, 20, 56, 4194310}, Def{9, 63, 20, 56, 4194310},
    Def{3001, 65, 20, 56, 4194310}, Def{3002, 67, 30, 56, 4194310}, Def{4294967295, 85, 20, 16, 528},
    Def{4294967294, 181, 20, 16, 16}, Def{4294967293, 196, 6, 8, 328208}, Def{6, 239, 20, 16, 33554433},
    Def{13, 241, 20, 16, 33554433}, Def{14, 238, 20, 16, 24}, Def{34, 243, 20, 16, 0}, Def{46, 244, 16, 16, 2},
    Def{58, 67, 30, 56, 4456454}, Def{2024, 248, 20, 16, 8388609}, Def{2025, 252, 20, 16, 1},
    Def{2026, 253, 20, 16, 8388609}, Def{2045, 259, 20, 16, 8388609}, Def{3003, 261, 24, 64, 4194310}]

# MT_PUFF's DoomEd type, -1: no THINGS record can name it, so the puff
# only ever spawns from a shot.
def Thing.puff() -> U32:
  4294967295

# MT_BLOOD's DoomEd type, -1 in vanilla too: the one type here that
# needs a name of its own, since the puff has taken -1. Nothing but a
# bullet in flesh spawns it.
def Thing.blood() -> U32:
  4294967294

def Thing.fireball() -> U32:
  4294967293

def Thing.Def.kind(d: Thing.Def) -> U32:
  Def{kind, state, radius, height, flags} = d
  kind

# A type's spawn state, Doom's mobjinfo spawnstate.
def Thing.Def.state(d: Thing.Def) -> U32:
  Def{kind, state, radius, height, flags} = d
  state

# A type's radius in fixed point.
def Thing.Def.radius(d: Thing.Def) -> U32:
  Def{kind, state, radius, height, flags} = d
  F.Fixed.of_map(radius)

# A type's height in map units.
def Thing.Def.height(d: Thing.Def) -> U32:
  Def{kind, state, radius, height, flags} = d
  height

def Thing.Def.flags(d: Thing.Def) -> U32:
  Def{kind, state, radius, height, flags} = d
  flags

# The rest of Doom's mobjinfo, read by kind and not kept in the
# definition, because a record's width is a budget the whole program
# shares. Its fields in info.c's order: the spawn health, the see state
# A_Look sends the type to and the sound it makes on sight, the sound
# A_Chase starts as it enters the melee state, the pain state, the pain
# chance and the sound A_Pain starts, the melee and missile states A_Chase
# enters to claw and to shoot, the death and gib death states and the
# sound A_Scream starts, the map units a chasing thing walks a move tic,
# the mass a thrust divides by, and the call a chasing thing makes on a
# draw under 3. A state the type has none of is 0 for the see, melee and
# missile states and S_NULL for the others, and silence is 0. The baron's
# melee and missile states are 0 until its attack rows exist, which keeps
# its A_Chase from attacking. The fireball's sight sound is P_SpawnMissile's,
# which the sim starts itself. Every other type is scenery at vanilla's
# default health of 1000 and mass of 100, which no blow reaches, since
# nothing that is not shootable is ever damaged.
def Thing.fight.row(kind: U32) -> List<&2, U32>:
  match kind:
    case 3004:
      [20, 89, 36, 0, 121, 200, 27, 0, 184, 123, 128, 59, 8, 100, 75]
    case 9:
      [30, 97, 37, 0, 137, 170, 27, 0, 187, 139, 144, 60, 8, 100, 75]
    case 3001:
      [60, 105, 39, 0, 153, 200, 27, 190, 190, 155, 160, 62, 8, 100, 76]
    case 3002:
      [150, 113, 41, 52, 168, 180, 26, 193, 0, 170, 4294967295, 64, 10, 400, 77]
    case 58:
      [150, 113, 41, 52, 168, 180, 26, 193, 0, 170, 4294967295, 64, 10, 400, 77]
    case 3003:
      [1000, 263, 43, 0, 271, 50, 26, 0, 0, 273, 4294967295, 67, 8, 1000, 77]
    case 2035:
      [20, 0, 0, 0, 4294967295, 0, 0, 0, 0, 176, 4294967295, 82, 0, 100, 0]
    case 4294967293:
      [1000, 0, 0, 0, 4294967295, 0, 0, 0, 0, 198, 4294967295, 17, 0, 100, 0]
    case _:
      [1000, 0, 0, 0, 4294967295, 0, 0, 0, 0, 4294967295, 4294967295, 0, 0, 100, 0]

def Thing.fight(+kind: U32) -> V.Vec:
  V.Vec.of(Thing.fight.row(kind))

def Thing.spawnhealth(+kind: U32) -> U32:
  V.Vec.get(Thing.fight(kind), 0)

def Thing.see(+kind: U32) -> U32:
  V.Vec.get(Thing.fight(kind), 1)

def Thing.seesound(+kind: U32) -> U32:
  V.Vec.get(Thing.fight(kind), 2)

def Thing.attacksound(+kind: U32) -> U32:
  V.Vec.get(Thing.fight(kind), 3)

def Thing.painstate(+kind: U32) -> U32:
  V.Vec.get(Thing.fight(kind), 4)

def Thing.painchance(+kind: U32) -> U32:
  V.Vec.get(Thing.fight(kind), 5)

def Thing.painsound(+kind: U32) -> U32:
  V.Vec.get(Thing.fight(kind), 6)

def Thing.melee(+kind: U32) -> U32:
  V.Vec.get(Thing.fight(kind), 7)

def Thing.missile(+kind: U32) -> U32:
  V.Vec.get(Thing.fight(kind), 8)

def Thing.deathstate(+kind: U32) -> U32:
  V.Vec.get(Thing.fight(kind), 9)

def Thing.xdeathstate(+kind: U32) -> U32:
  V.Vec.get(Thing.fight(kind), 10)

def Thing.deathsound(+kind: U32) -> U32:
  V.Vec.get(Thing.fight(kind), 11)

def Thing.speed(+kind: U32) -> U32:
  V.Vec.get(Thing.fight(kind), 12)

def Thing.mass(+kind: U32) -> U32:
  V.Vec.get(Thing.fight(kind), 13)

def Thing.activesound(+kind: U32) -> U32:
  V.Vec.get(Thing.fight(kind), 14)

# Doom's mobj_t as P_SpawnMobj leaves it: the type's spawn health, no
# target, vanilla's reaction time of 8, no threshold, no momentum, the
# type's flags and height, which only a death changes, the player the
# spawn's draw left it looking at, and a direction of east with no tics
# on it: P_SpawnMobj clears the whole mobj and DI_EAST is the zero of
# dirtype_t, so a thing's first A_Chase snaps its facing to the eight
# directions and turns it, where DI_NODIR would leave it alone.
def Thing.Hurt.start(+kind: U32, flags: U32, height: U32, radius: U32, lastlook: U32) -> V.Vec:
  V.Vec.of([Thing.spawnhealth(kind), Thing.you(), 8, 0, 0, 0, flags, height, lastlook, 0, 0, radius])

def Thing.def.put(d: Thing.Def, found: Maybe<&2, Thing.Def>, hit: Bool) -> Maybe<&2, Thing.Def>:
  match hit:
    case True{}:
      Some{d}
    case False{}:
      found

def Thing.def.go(defs: List<&2, Thing.Def>, +kind: U32) -> Maybe<&2, Thing.Def>:
  match defs:
    case []:
      None{}
    case +d <> rest:
      Thing.def.put(d, Thing.def.go(rest, kind), U32.is_eq(Thing.Def.kind(d), kind))

# The definition of a DoomEd type, none for a type Bendoom does not
# spawn.
def Thing.def(kind: U32) -> Maybe<&2, Thing.Def>:
  Thing.def.go(Thing.defs(), kind)

# The definition of a spawned thing's type.
def Thing.info(+kind: U32) -> Thing.Def:
  Maybe.default(&2, Thing.Def, Thing.def(kind), Def{kind, 0, 0, 0, 0})

# What P_SpawnMobj leaves on a thing of a type that never looked, for a
# caller that has the type and not its definition in hand.
def Thing.Hurt.of(+kind: U32) -> V.Vec:
  Thing.Hurt.start(kind, Thing.Def.flags(Thing.info(kind)),
    F.Fixed.of_map(Thing.Def.height(Thing.info(kind))), Thing.Def.radius(Thing.info(kind)), 0)

# Doom's P_ZMovement's clip, under the ceiling: a rising mobj that meets
# it stops there.
def Thing.zmove.ceiling(hit: Bool, +z: U32, +momz: U32, +ceilz: U32, +height: U32) -> U32 & U32:
  match hit:
    case True{}:
      ((ceilz - height : U32), Bool.pick(U32, F.Fixed.gt(momz, 0), 0, momz))
    case False{}:
      (z, momz)

# Doom's GRAVITY, a unit a tic, doubled on the tic a mobj first falls.
def Thing.zmove.pull(+momz: U32) -> U32:
  Bool.pick(U32, U32.is_zero(momz), F.Fixed.neg((F.Fixed.unit() * 2 : U32)), (momz - F.Fixed.unit() : U32))

# Doom's P_ZMovement for the things Bendoom moves: the mobj rises by its
# momentum and stops where the floor or the ceiling is, and off the
# floor gravity pulls it down unless its flags say otherwise. A mobj
# that lands keeps a rising momentum, as vanilla clears a falling one
# alone.
def Thing.zmove.floor(hit: Bool, gravity: Bool, +z: U32, +momz: U32, +floorz: U32, +ceilz: U32, +height: U32) ->
  U32 & U32:
  match hit gravity:
    case True{} _:
      Thing.zmove.ceiling(F.Fixed.gt((floorz + height : U32), ceilz), floorz,
        Bool.pick(U32, F.Fixed.lt(momz, 0), 0, momz), ceilz, height)
    case False{} False{}:
      Thing.zmove.ceiling(F.Fixed.gt((z + height : U32), ceilz), z, momz, ceilz, height)
    case False{} True{}:
      Thing.zmove.ceiling(F.Fixed.gt((z + height : U32), ceilz), z, Thing.zmove.pull(momz), ceilz, height)

def Thing.zmove.put(thing: Thing, zm: U32 & U32) -> Thing:
  Thing{id, kind, x, y, was, floorz, ceilz, angle, sector, state, tics, old, hurt} = thing
  (z, momz) = zm
  Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics, momz, hurt}

def Thing.zmove(thing: Thing) -> Thing:
  Thing{id, kind, x, y, +z, +floorz, +ceilz, angle, sector, state, tics, +momz, +hurt} = thing
  +height = V.Vec.get(hurt, Thing.hurt.height())
  +falls = U32.is_zero((V.Vec.get(hurt, Thing.hurt.flags()) .&. 512 : U32))
  Thing.zmove.put(Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics, momz, hurt},
    Thing.zmove.floor(F.Fixed.le((z + momz : U32), floorz), falls, (z + momz : U32), momz, floorz, ceilz, height))

# Whether a thing has entered S_NULL and so removed itself.
def Thing.gone(thing: Thing) -> Bool:
  Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, +state, tics, momz, hurt} = thing
  U32.is_eq(state, Thing.null())

# Doom's ONFLOORZ and ONCEILINGZ: a z that asks P_SpawnMobj for the
# floor, or for the thing's height under the ceiling.
def Thing.onfloor() -> U32:
  2147483648

def Thing.onceiling() -> U32:
  2147483647

# Doom's P_SpawnMobj, less its random draw, which its caller makes and
# passes here as lastlook, the draw modulo MAXPLAYERS: a thing of a type
# named id at (x, y) and z, in its first state for that state's tics,
# facing east, held between the floor and ceiling of the sector under
# it.
def Thing.mobj(d: Thing.Def, +level: L.Level, id: U32, +x: U32, +y: U32, +z: U32, lastlook: U32) -> Thing:
  Def{+kind, +state, radius, +height, +flags} = d
  +sector = L.Level.sector_at(level, x, y)
  +floor = L.Level.floor(level, sector)
  +ceil = L.Level.ceil(level, sector)
  Thing{id, kind, x, y, Bool.pick(U32, U32.is_eq(z, Thing.onfloor()), floor,
      Bool.pick(U32, U32.is_eq(z, Thing.onceiling()), (ceil - F.Fixed.of_map(height) : U32), z)), floor, ceil, 0,
    sector, state, Thing.Row.tics(Thing.row(state)), 0,
    Thing.Hurt.start(kind, flags, F.Fixed.of_map(height), F.Fixed.of_map(radius), lastlook)}

# The thing with its centre at another place, in the sector under it.
def Thing.at(th: Thing, level: L.Level, +x: U32, +y: U32) -> Thing:
  Thing{id, kind, ox, oy, z, floorz, ceilz, angle, was, state, tics, momz, hurt} = th
  Thing{id, kind, x, y, z, floorz, ceilz, angle, L.Level.sector_at(level, x, y), state, tics, momz, hurt}

# The things spawned, the last first while they spawn, the random
# index, and player 1's start record, the player's own name before one
# spawns.
type Thing.Spawn is Data:
  Spawn{things: List<&2, Thing>, rnd: U32, you: U32}

def Thing.spawn.facing(th: Thing, angle: U32, tics: U32) -> Thing:
  Thing{id, kind, x, y, z, floorz, ceilz, east, sector, state, first, momz, hurt} = th
  Thing{id, kind, x, y, z, floorz, ceilz, A.Angle.of_thing(angle), sector, state, tics, momz, hurt}

# The rest of Doom's P_SpawnMapThing: one random number drawn for the
# mobj, whose remainder by MAXPLAYERS is its lastlook, and one more for
# a state that runs out, which lasts that number modulo its tics, plus
# one. It stands on the floor or hangs from the ceiling, and faces the
# record's angle.
def Thing.spawn.mobj(+d: Thing.Def, +level: L.Level, id: U32, x: U32, y: U32, angle: U32, s: Thing.Spawn) ->
  Thing.Spawn:
  Def{kind, state, radius, height, flags} = d
  Spawn{things, rnd, you} = s
  +tics = Thing.Row.tics(Thing.row(state))
  +drawn = M.Random.next(rnd)
  +runs = F.Fixed.gt(tics, 0)
  +after = Bool.pick(U32, runs, M.Random.next(drawn), drawn)
  Spawn{Thing.spawn.facing(Thing.mobj(d, level, id, x, y,
      Bool.pick(U32, U32.is_zero((flags .&. 256 : U32)), Thing.onfloor(), Thing.onceiling()),
      (M.Random.at(drawn) % 4 : U32)), angle,
    Bool.pick(U32, runs, (M.Random.at(after) % tics + 1 : U32), tics)) <> things, after, you}

def Thing.spawn.if(player: Bool, skill: Bool, info: Maybe<&2, Thing.Def>, +level: L.Level, +id: U32, +x: U32,
  +y: U32, angle: U32, options: U32, s: Thing.Spawn) -> Thing.Spawn:
  match player skill info:
    case True{} _ _:
      Spawn{things, rnd, +you} = s
      Spawn{things, M.Random.next(rnd), Bool.pick(U32, U32.is_lt(id, you), id, you)}
    case False{} True{} Some{Def{kind, state, radius, height, flags}}:
      Thing.spawn.mobj(Def{kind, state, radius, height, (flags .|. ((options .&. 8) << 2n) : U32)},
        level, id, x, y, angle, s)
    case _ _ _:
      s

# Doom's P_SpawnMapThing on Hurt Me Plenty with one player: player 1's
# start spawns the player, who draws a random number too and takes the
# first such record's index for its name, the start
# Level.start_of places it at; another record spawns when its options
# set that skill's bit, 2, and not the multiplayer bit, 16, and its type
# has a definition.
def Thing.spawn.one(+level: L.Level, id: U32, record: L.Level.Thing, s: Thing.Spawn) -> Thing.Spawn:
  L.Thing{x, y, angle, +kind, +options} = record
  Thing.spawn.if(U32.is_eq(kind, 1), Bool.and(Bool.not(U32.is_zero((options .&. 2 : U32))),
    U32.is_zero((options .&. 16 : U32))), Thing.def(kind), level, id, x, y, angle, options, s)

def Thing.spawn.go(n: Nat, +level: L.Level, +i: U32, s: Thing.Spawn) -> Thing.Spawn:
  match n:
    case 0n:
      s
    case 1n+m:
      Thing.spawn.go(m, level, (i + 1 : U32), Thing.spawn.one(level, i, L.Level.thing(level, i), s))

def Thing.spawn.done(s: Thing.Spawn) -> Thing.Spawn:
  Spawn{things, rnd, you} = s
  Spawn{List.reverse(&2, Thing, things), rnd, you}

# The level's first things, in the order of their records, and the
# random index once they have spawned, from 0.
def Thing.spawn(+level: L.Level) -> Thing.Spawn:
  Thing.spawn.done(Thing.spawn.go(U32.to_nat(L.Level.nthings(level)), level, 0, Spawn{[], 0, Thing.you()}))

def Thing.Spawn.things(s: Thing.Spawn) -> List<&2, Thing>:
  Spawn{things, rnd, you} = s
  things

type Thing.Totals is Data:
  Totals{kills: U32, items: U32}

def Thing.totals.flagged(+flags: U32, +bit: U32) -> U32:
  Bool.to_u32(Bool.not(U32.is_zero((flags .&. bit : U32))))

def Thing.totals.one(+flags: U32, t: Thing.Totals) -> Thing.Totals:
  Totals{+kills, +items} = t
  Totals{(kills + Thing.totals.flagged(flags, 4194304) : U32),
    (items + Thing.totals.flagged(flags, 8388608) : U32)}

def Thing.totals.go(things: List<&2, Thing>, t: Thing.Totals) -> Thing.Totals:
  match things:
    case []:
      t
    case Thing{id, +kind, x, y, z, floorz, ceilz, angle, sector, state, tics, momz, hurt} <> rest:
      Thing.totals.go(rest, Thing.totals.one(Thing.Def.flags(Thing.info(kind)), t))

def Thing.totals(+level: L.Level) -> Thing.Totals:
  Thing.totals.go(Thing.Spawn.things(Thing.spawn(level)), Totals{0, 0})

# The population
# --------------

# The things alive by id, among ids from 0 to count, the player's id,
# and Doom's links: the ids in each blockmap cell and in each sector,
# the last linked first, the player's among them. A thing spawned in
# play takes the count for its id, so no id ever names two things. Last,
# what the things did that is heard and the state has not reported yet:
# a position check has no state to tell.
type Things is Data:
  Things{tree: V.Tree<Thing>, count: U32, you: U32, cells: V.Tree<List<&2, U32>>,
    sectors: V.Tree<List<&2, U32>>, heard: List<&2, Sn.Sound.Event>}

# No things, the ids under count kept for the map's records, with a
# list for each of so many blockmap cells and sectors.
def Things.none(+count: U32, you: U32, ncells: U32, nsectors: U32) -> Things:
  Things{V.Tree.empty(Thing, V.Vec.depth(count)), count, you, V.Tree.empty(List<&2, U32>, V.Vec.depth(ncells)),
    V.Tree.empty(List<&2, U32>, V.Vec.depth(nsectors)), []}

def Things.get(ts: Things, +id: U32) -> Maybe<&2, Thing>:
  Things{tree, count, you, cells, sectors, heard} = ts
  V.Tree.get(Thing, tree, id)

def Things.put(ts: Things, +id: U32, m: Maybe<&2, Thing>) -> Things:
  Things{tree, count, you, cells, sectors, heard} = ts
  Things{V.Tree.set(Thing, tree, id, m), count, you, cells, sectors, heard}

# The things after one of them was heard.
def Things.sounded(ts: Things, e: Sn.Sound.Event) -> Things:
  Things{tree, count, you, cells, sectors, heard} = ts
  Things{tree, count, you, cells, sectors, List.append(&2, Sn.Sound.Event, heard, [e])}

def Things.you(ts: Things) -> U32:
  Things{tree, count, you, cells, sectors, heard} = ts
  you

def Things.count(ts: Things) -> U32:
  Things{tree, count, you, cells, sectors, heard} = ts
  count

def Things.fresh.if(full: Bool, tree: V.Tree<Thing>) -> V.Tree<Thing>:
  match full:
    case False{}:
      tree
    case True{}:
      V.Tree.grown(Thing, tree)

# The population with one id more, its old count, and room for it: the
# tree is full when the count is a power of two.
def Things.fresh(ts: Things) -> Things:
  Things{tree, +count, you, cells, sectors, heard} = ts
  Things{Things.fresh.if(U32.is_zero((count .&. (count - 1) : U32)), tree), (count + 1 : U32), you, cells, sectors,
    heard}

# Links
# -----

def Things.first(ids: List<&2, U32>, +id: U32) -> List<&2, U32>:
  id <> ids

def Things.without(ids: List<&2, U32>, +id: U32) -> List<&2, U32>:
  match ids:
    case []:
      []
    case +h <> rest:
      V.Vec.keep(~U32, Bool.not(U32.is_eq(h, id)), h, Things.without(rest, id))

# List i of some lists with an id put first in it, or taken out of it.
def Things.edit(~edit: @ids: List<&2, U32> -> @+id: U32 -> List<&2, U32>, +lists: V.Tree<List<&2, U32>>, +i: U32,
  id: U32) -> V.Tree<List<&2, U32>>:
  V.Tree.set(List<&2, U32>, lists, i,
    Some{edit(Maybe.default(&2, List<&2, U32>, V.Tree.get(List<&2, U32>, lists, i), []), id)})

def Things.edit.if(~edit: @ids: List<&2, U32> -> @+id: U32 -> List<&2, U32>, listed: Bool,
  lists: V.Tree<List<&2, U32>>, i: U32, id: U32) -> V.Tree<List<&2, U32>>:
  match listed:
    case False{}:
      lists
    case True{}:
      Things.edit(~edit, lists, i, id)

# A mobj with some flags at (x, y) in a sector, in the list of the
# blockmap cell its centre is in and in its sector's; off the map, or
# flagged MF_NOBLOCKMAP, it is in no cell, and flagged MF_NOSECTOR, in no
# sector's list.
def Things.placed(~edit: @ids: List<&2, U32> -> @+id: U32 -> List<&2, U32>, ts: Things, +bm: L.Level.Blockmap,
  +flags: U32, +id: U32, x: U32, y: U32, sector: U32) -> Things:
  Things{tree, count, you, cells, sectors, heard} = ts
  L.Blockmap{words, ox, oy, +cols, +rows} = bm
  +c = L.Level.cell_of(bm, x, y)
  Things{tree, count, you, Things.edit.if(~edit, Bool.and(U32.is_zero((flags .&. 16 : U32)),
      L.Level.cell.inside(cols, rows, c)), cells, L.Level.cell.number(cols, c), id),
    Things.edit.if(~edit, U32.is_zero((flags .&. 8 : U32)), sectors, sector, id), heard}

# Doom's P_SetThingPosition: the mobj goes first in its cell's list and
# first in its sector's.
def Things.link(ts: Things, bm: L.Level.Blockmap, flags: U32, id: U32, x: U32, y: U32, sector: U32) -> Things:
  Things.placed(~Things.first, ts, bm, flags, id, x, y, sector)

# Doom's P_UnsetThingPosition: the mobj leaves both lists.
def Things.unlink(ts: Things, bm: L.Level.Blockmap, flags: U32, id: U32, x: U32, y: U32, sector: U32) -> Things:
  Things.placed(~Things.without, ts, bm, flags, id, x, y, sector)

# The population with a thing in it, linked where it is: one that
# spawned, or one that moved, once unlinked from where it was.
def Things.entered(ts: Things, bm: L.Level.Blockmap, th: Thing) -> Things:
  Thing{+id, +kind, +x, +y, z, floorz, ceilz, angle, +sector, state, tics, momz, hurt} = th
  Things.link(Things.put(ts, id, Some{Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics, momz,
    hurt}}), bm, Thing.Def.flags(Thing.info(kind)), id, x, y, sector)

def Things.unlinked(ts: Things, bm: L.Level.Blockmap, th: Thing) -> Things:
  Thing{id, +kind, x, y, z, floorz, ceilz, angle, sector, state, tics, momz, hurt} = th
  Things.unlink(ts, bm, Thing.Def.flags(Thing.info(kind)), id, x, y, sector)

# A thing at another place, once unlinked from where it was: Doom's
# P_UnsetThingPosition and P_SetThingPosition about a move.
def Things.moved(ts: Things, +bm: L.Level.Blockmap, was: Thing, now: Thing) -> Things:
  Things.entered(Things.unlinked(ts, bm, was), bm, now)

# Doom's P_RemoveMobj: the thing unlinked and gone, its id never used
# again, and its sound stopped.
def Things.removed(ts: Things, bm: L.Level.Blockmap, th: Thing) -> Things:
  Thing{+id, +kind, x, y, z, floorz, ceilz, angle, sector, state, tics, momz, hurt} = th
  Things.sounded(Things.put(Things.unlinked(ts, bm,
    Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics, momz, hurt}), id, None{}),
    Sn.Stop{Sn.Thing{id}})

def Things.linked.at(inside: Bool, cells: V.Tree<List<&2, U32>>, i: U32) -> List<&2, U32>:
  match inside:
    case False{}:
      []
    case True{}:
      Maybe.default(&2, List<&2, U32>, V.Tree.get(List<&2, U32>, cells, i), [])

def Things.linked.go(cs: List<&2, L.Level.Cell>, +cols: U32, +rows: U32, +cells: V.Tree<List<&2, U32>>) ->
  List<&2, U32>:
  match cs:
    case []:
      []
    case +c <> rest:
      List.append(&2, U32, Things.linked.at(L.Level.cell.inside(cols, rows, c), cells, L.Level.cell.number(cols, c)),
        Things.linked.go(rest, cols, rows, cells))

# The mobjs linked in each of some blockmap cells in turn, a cell's
# last linked first: the order Doom's P_BlockThingsIterator meets them.
def Things.linked(ts: Things, bm: L.Level.Blockmap, cs: List<&2, L.Level.Cell>) -> List<&2, U32>:
  Things{tree, count, you, cells, sectors, heard} = ts
  L.Blockmap{words, ox, oy, cols, rows} = bm
  Things.linked.go(cs, cols, rows, cells)

# Lists
# -----

def Things.cons(m: Maybe<&2, Thing>, rest: List<&2, Thing>) -> List<&2, Thing>:
  match m:
    case None{}:
      rest
    case Some{th}:
      th <> rest

def Things.list.go(n: Nat, +t: V.Tree<Thing>, +i: U32) -> List<&2, Thing>:
  match n:
    case 0n:
      []
    case 1n+m:
      Things.cons(V.Tree.get(Thing, t, i), Things.list.go(m, t, (i + 1 : U32)))

# The things alive, in the order of their ids.
def Things.list(ts: Things) -> List<&2, Thing>:
  Things{+tree, +count, you, cells, sectors, heard} = ts
  Things.list.go(U32.to_nat(count), tree, 0)

def Things.ids(lists: V.Tree<List<&2, U32>>) -> List<&2, U32>:
  match lists:
    case V.Slot{m}:
      Maybe.default(&2, List<&2, U32>, m, [])
    case V.Fork{l, r}:
      List.append(&2, U32, Things.ids(l), Things.ids(r))

def Things.those(ids: List<&2, U32>, +tree: V.Tree<Thing>) -> List<&2, Thing>:
  match ids:
    case []:
      []
    case id <> rest:
      Things.cons(V.Tree.get(Thing, tree, id), Things.those(rest, tree))

# The things alive, sector by sector, a sector's in the order of its
# list: the order Doom's R_AddSprites meets the things of a sector in.
# The player's mobj is no thing, so it is not among them.
def Things.shown(ts: Things) -> List<&2, Thing>:
  Things{tree, count, you, cells, sectors, heard} = ts
  Things.those(Things.ids(sectors), tree)

# The name of a thing the population lacks, before rest; rest alone for
# one it has.
def Things.gone.name(m: Maybe<&2, Thing>, +id: U32, rest: String) -> String:
  match m:
    case None{}:
      " " ++ U32.show(id) ++ rest
    case Some{_}:
      rest

# The names of the things of a list gone from a population, as text.
def Things.gone(before: List<&2, Thing>, +after: Things) -> String:
  match before:
    case []:
      ""
    case Thing{+id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics, momz, hurt} <> rest:
      Things.gone.name(Things.get(after, id), id, Things.gone(rest, after))

# How many things are left and the names of those gone since a first
# population, as text.
def Things.tally(first: List<&2, Thing>, +things: Things) -> String:
  " things " ++ Nat.show(List.length(&2, Thing, Things.list(things))) ++ " taken" ++ Things.gone(first, things)
