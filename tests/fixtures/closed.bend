# The literal levels, states and readers the tests share. Some of
# LAWS.bend's laws stand on the same levels and states.
import Base
import ../../src/vec.bend as V
import ../../src/fixed.bend as F
import ../../src/tables.bend as T
import ../../src/level.bend as L
import ../../src/keys.bend as K
import ../../src/sim.bend as S
import ../../src/special.bend as Sp
import ../../src/tic.bend as Tic
import ../../src/things.bend as H
import ../../src/inventory.bend as I
import ../../src/sound.bend as Sn
import ../../src/project.bend as P
import ../../src/gfx.bend as G
import ../../src/sprites.bend as Z
import ../../src/opl.bend as O
import ../../src/midi.bend as Mi

# No things.
def Closed.none() -> H.Things:
  H.Things.none(0, H.Thing.you(), 0, 0)

# No player sprite showing, which a tic leaves as it is: what the players
# of the movement tests and laws carry.
def Closed.unarmed() -> S.Psprites:
  S.Psprites{S.Psprite{None{}, 0, 0, 0}, S.Psprite{None{}, 0, 0, 0}}

# A level's first state with the player as given, at a clock, as
# written: the player's mobj thinks and is linked nowhere, which a law
# over every level can compute.
def Closed.state(p: S.Player, level: L.Level, clock: U32) -> S.State:
  S.State{p, level, Closed.none(), V.Leaf{0}, S.Thinkers{[], [S.Mobj{H.Thing.you()}]}, 0, clock, S.Unended{}, False{},
    [], S.Sim.Face.start(0), False{}, V.Leaf{0}}

# A state with the player as given and some thinkers, among things named
# under 128, all of them entered: linked where they stand, their mobjs
# thinking.
def Closed.at(p: S.Player, level: L.Level, ts: List<&2, S.Thinker>, things: List<&2, H.Thing>) -> S.State:
  S.State.populated(things, 128, S.State{p, level, Closed.none(), V.Leaf{0}, S.Thinkers{[], ts}, 0, 0, S.Unended{},
    False{}, [], S.Sim.Face.start(0), False{}, V.Leaf{0}})

# The thinkers running that are no mobj's.
def Closed.running.go(ts: List<&2, S.Thinker>) -> List<&2, S.Thinker>:
  match ts:
    case []:
      []
    case S.Mobj{id} <> rest:
      Closed.running.go(rest)
    case t <> rest:
      t <> Closed.running.go(rest)

def Closed.running(s: S.State) -> List<&2, S.Thinker>:
  Closed.running.go(S.State.thinkers(s))

# The player after a script in the room, from a player and a clock.
def Closed.room(script: List<&2, K.Cmd>, p: S.Player, clock: U32) -> S.Player:
  S.State.player(Tic.Sim.replay(script, Closed.state(p, L.Level.room(0, 128), clock)))

# The pistol at rest, the state A_Raise leaves it in.
def Closed.ready() -> S.Psprites:
  S.Psprites{S.Psprite{Some{59}, 1, 65536, 2097152}, S.Psprite{None{}, 0, 65536, 2097152}}

def Closed.armoured.of(inv: I.Inventory, kind: U32, points: U32) -> I.Inventory:
  I.Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus, line, kills, secrets} = inv
  I.Inventory{health, points, kind, cards, ammo, caps, backpack, weapons, powers, items, bonus, line, kills, secrets}

# The starting inventory wearing armour of a type, 0 for none, with some
# points.
def Closed.armoured(kind: U32, points: U32) -> I.Inventory:
  Closed.armoured.of(I.Inventory.start(), kind, points)

def Closed.hurt(got: I.Inventory & U32) -> U32 & U32 & U32 & U32:
  (+inv, left) = got
  (I.Inventory.health(inv), I.Inventory.armour(inv), I.Inventory.armourtype(inv), left)

# The health, the armour points, the armour type and the damage that
# reached the player, after a blow on an inventory wearing that armour.
def Closed.absorbed(kind: U32, points: U32, damage: U32) -> U32 & U32 & U32 & U32:
  Closed.hurt(I.Inventory.hurt(Closed.armoured(kind, points), damage))

def Closed.counted(+s: S.State) -> U32 & U32:
  (I.Inventory.health(S.Player.inv(S.State.player(s))),
    S.Sim.Hurt.damage(S.Player.hurt(S.State.player(s))))

# The health and the damage count left by a blow from nobody on a player
# at rest in the room with a hundred health.
def Closed.blow.at(damage: U32, +s: S.State) -> U32 & U32:
  Closed.counted(Tic.Sim.damage(H.Things.you(S.State.things(s)), damage, H.Thing.you(), H.Thing.you(), s))

def Closed.blow(damage: U32) -> U32 & U32:
  Closed.blow.at(damage,
    Closed.state(S.Player{0, 0, 0, 0, 0, 0, 0, 0, 8388608, 2686976, 0, 2686976, [], I.Inventory.start(),
      Closed.unarmed(), S.Sim.Hurt.start()}, L.Level.room(0, 128), 0))

# The movers' tests stand on a literal level: a west room (sector
# 0, ceiling 128), a door (sector 1, shut at 0) and an east room (sector
# 2, ceiling 72), all floors at 0, 16 units of door from x 64 to x 80.
# Line 0 is the door's west face, its front to the west, special 1; line
# 1 its east face, its front to the east, special 117. One blockmap
# cell lists both, and one subsector stands for every point. Every
# number below is computed by hand from vanilla's constants. The
# blockmap's origin is a parameter: at 0 a player in the west room is in
# the one cell, so a mover re-clips it; moved east, the player is in no
# sector's block box. Its THINGS records, so many, are a parameter too.
def Closed.level(ox: U32, records: V.Vec, count: U32) -> L.Level:
  L.Level.grouped(L.Level{L.Geo{V.Vec.of_list([0, 1, 4, 0, 1, 2, 3, 4, 2, 3], 10),
    V.Vec.of_list([0, 0, 0, 0, 0, 1, 0, 0, 2, 0, 0, 1], 12), V.Vec.of_list([64, 128, 64, 0, 80, 0, 80, 128], 8),
    V.Vec.of_list([0, 1, 0, 0, 0, 0], 6), V.Vec.of_list([1, 0], 2), V.Leaf{0}, 32768,
    L.Blockmap{V.Vec.of_list([0, 0, 1, 1, 5, 0, 0, 1, 65535], 9), ox, 0, 1, 1},
    L.Things{records, count}, [], [],
    V.Vec.of_list(T.Tables.finesine(), 10240), V.Vec.of_list(T.Tables.tantoangle(), 2049), V.Leaf{0}, 2, 3,
    V.Leaf{0}, V.Leaf{0}, V.Leaf{0}},
    V.Vec.of_list([0, 8388608, 160, 0, 0, 160, 0, 4718592, 160], 9), V.Vec.of_list([1, 0, 117, 0], 4), V.Vec.of_list([], 3)})

def Closed.doors() -> L.Level:
  Closed.level(0, V.Leaf{0}, 0)

# A player at rest on the floor at 0, under a ceiling.
def Closed.player(x: U32, y: U32, angle: U32, ceilz: U32) -> S.Player:
  S.Player{x, y, 0, angle, 0, 0, 0, 0, ceilz, 2686976, 0, 2686976, [], I.Inventory.start(), Closed.unarmed(), S.Sim.Hurt.start()}

# The west room's player, 32 units from the door and facing it, and the
# east room's.
def Closed.west() -> S.State:
  Closed.at(Closed.player(2097152, 4194304, 0, 8388608), Closed.doors(), [], [])

def Closed.east() -> S.State:
  Closed.at(Closed.player(7340032, 4194304, 2147483648, 4718592), Closed.doors(), [], [])

# The door level with a barrel, radius 10, standing between its two
# faces at x 72, y 64, linked into the one cell as P_SetThingPosition
# links it. The player stands at (200, 64), off the blockmap, so its own
# mobj is in no cell and the ray meets the barrel alone; vanilla's
# PIT_AddThingIntercepts gathers the shooter's mobj too, and it is its
# visitor that passes over it.
def Closed.barrel() -> S.State:
  Closed.at(Closed.player(13107200, 4194304, 0, 8388608), Closed.doors(), [],
    [H.Thing{0, 2035, 4718592, 4194304, 0, 0, 8388608, 0, 0, 0, 4294967295, 0, H.Thing.Hurt.of(2035)}])

# What a ray of the use key's 64 units, east from (32, 64), meets, and
# what the use key's visitor makes of the same ray.
def Closed.met(+s: S.State) -> List<&2, S.Sim.Meet>:
  S.Sim.meets(S.State.level(s), S.State.things(s), S.State.player(s), True{}, True{}, 2097152, 4194304, 6291456,
    4194304)

def Closed.reach(+s: S.State) -> Sp.Sim.Reach:
  S.Sim.path(~Sp.Sim.Reach, ~Sp.Sim.use.visit, S.State.level(s), S.State.things(s), S.State.player(s), True{},
    False{}, 2097152, 4194304, 6291456, 4194304, Sp.Nothing{})

# The state after a tic of use and then idle tics.
def Closed.used(idle: Nat, s: S.State) -> S.State:
  Tic.Sim.replay(K.Cmd{0, 0, 0, 2} <> List.replicate(K.Cmd, idle, K.Cmd.idle()), s)

def Closed.ceil(s: S.State, sector: U32) -> U32:
  L.Level.ceil(S.State.level(s), sector)

# A state of the literal level with one mover running and a player at
# rest at a place under a ceiling.
def Closed.moving(level: L.Level, t: S.Thinker, x: U32, y: U32, ceilz: U32) -> S.State:
  Closed.at(Closed.player(x, y, 0, ceilz), level, [t], [])

def Closed.idled(n: Nat, s: S.State) -> S.State:
  Tic.Sim.replay(List.replicate(K.Cmd, n, K.Cmd.idle()), s)

# The literal level with line 0 a walk-over turbo floor (special 36; its
# tag 0 is every sector), the door sector's floor at 16, its ceiling and
# the east room's at 128, and a player at x moving east at a speed.
def Closed.turbo(x: U32, momx: U32) -> S.State:
  Closed.at(S.Player{x, 4194304, 0, 0, momx, 0, 0, 0, 8388608, 2686976, 0, 2686976, [], I.Inventory.start(), Closed.unarmed(), S.Sim.Hurt.start()},
    L.Level.special.put(L.Level.plane.put(L.Level.plane.put(L.Level.plane.put(Closed.doors(), 1, False{},
      1048576), 1, True{}, 8388608), 2, True{}, 8388608), 0, 36), [], [])

def Closed.floors(+s: S.State) -> U32 & U32 & U32:
  (L.Level.floor(S.State.level(s), 0), L.Level.floor(S.State.level(s), 1), L.Level.floor(S.State.level(s), 2))

# The literal level for the switched movers: the door sector's floor at
# -32 and its ceiling at 128, line 0 a switch of the given special (its
# tag 0 is every sector), its front's middle texture 1, a switch whose
# partner is 2, and the blockmap's origin 48 east, so the west room's
# player at (32, 64) is in no block box.
def Closed.switched(special: U32) -> S.State:
  S.State.populated([], 128, S.State{Closed.player(2097152, 4194304, 0, 8388608),
    L.Level.textured(L.Level.special.put(L.Level.plane.put(L.Level.plane.put(Closed.level(3145728, V.Leaf{0}, 0), 1,
      False{}, 4292870144), 1, True{}, 8388608), 0, special), V.Vec.of_list([0, 0, 1], 12), V.Vec.of_list([0, 2, 1], 3)),
    Closed.none(), V.Vec.of_list([0, 0, 1], 12), S.Thinkers{[], []}, 0, 0, S.Unended{}, False{}, [], S.Sim.Face.start(0), False{}, V.Leaf{0}})

def Closed.lifts() -> S.State:
  Closed.switched(62)

def Closed.seen(+s: S.State) -> U32 & U32:
  (L.Level.floor(S.State.level(s), 0), V.Vec.get(S.State.sidetex(s), 2))

# What a listener d units south of a source hears, facing an angle.
def Closed.heard(d: U32, facing: U32) -> U32 & U32:
  Sn.Sound.adjust(True{}, L.Level.sine(L.Level.room(0, 128)), L.Level.tanto(L.Level.room(0, 128)), 0,
    F.Fixed.neg(F.Fixed.of_map(d)), facing, 0, 0)

def Closed.coincident(starting: Bool) -> U32 & U32:
  Sn.Sound.adjust(starting, L.Level.sine(L.Level.room(0, 128)), L.Level.tanto(L.Level.room(0, 128)),
    0, 0, 1073741824, 0, 0)

# The lights' tests stand on the literal level with the west room
# at a light and the door sector, light 160, given the light Doom spawns
# for a sector special, the random index at 1 as it is once Doom has
# spawned the player.
def Closed.lit(special: U32, west: U32) -> S.State:
  Sp.Sim.light.spawn(special, 1, S.State.populated([], 128, S.State{Closed.player(2097152, 4194304, 0, 8388608),
    L.Level.light.put(Closed.doors(), 0, west), Closed.none(), V.Leaf{0}, S.Thinkers{[], []}, 1, 0, S.Unended{}, False{},
    [], S.Sim.Face.start(0), False{}, V.Leaf{0}}))

def Closed.light(s: S.State) -> U32:
  L.Level.sector.light(S.State.level(s), 1)

# The west room's player holding an inventory, beside the door with
# line 0 made vanilla's blue locked door, special 26.
def Closed.locked(inv: I.Inventory) -> S.State:
  Closed.at(S.Player.holding(Closed.player(2097152, 4194304, 0, 8388608), inv),
    L.Level.special.put(Closed.doors(), 0, 26), [], [])

# The west room's player holding an inventory at (x, 64), on the floor
# under a ceiling at 128, moving by a momentum a tic, among things named
# under 128, on the literal level.
def Closed.among(inv: I.Inventory, x: U32, momx: U32, momy: U32, things: List<&2, H.Thing>) -> S.State:
  Closed.at(S.Player{x, 4194304, 0, 0, momx, momy, 0, 0, 8388608, 2686976, 0, 2686976, [], inv, Closed.unarmed(), S.Sim.Hurt.start()},
    Closed.doors(), [], things)

# A thing named id of a type at (x, y) and z in the west room, in a
# state that lasts, so its tics change nothing. Its floor is the room's,
# at 0.
def Closed.thing(id: U32, +kind: U32, x: U32, y: U32, z: U32) -> H.Thing:
  H.Thing{id, kind, x, y, z, 0, 8388608, 0, 0, 0, 4294967295, 0, H.Thing.Hurt.of(kind)}

# The same on a floor of its own height, so that P_ZMovement leaves it
# where it is: a thing under the room's floor would otherwise be lifted
# onto it before anything reached it, as vanilla lifts one.
def Closed.floored(id: U32, +kind: U32, x: U32, y: U32, +z: U32) -> H.Thing:
  H.Thing{id, kind, x, y, z, z, 8388608, 0, 0, 0, 4294967295, 0, H.Thing.Hurt.of(kind)}

# A change to an inventory: its health, its armour points and type, its
# cards as bits in card_t order, its ammo in ammotype_t order (bullets,
# shells, cells, rockets), the backpack with the caps it doubles, 400
# 100 600 100, the weapons owned, a power's counter, the tally or the
# flash.
type Closed.Edit is Data:
  Health{n: U32}
  Armour{points: U32, kind: U32}
  Cards{bits: U32}
  Ammo{rounds: List<&2, U32>}
  Backpack{}
  Weapons{bits: U32}
  Selection{ready: U32, pending: U32}
  Power{power: U32, n: U32}
  Items{n: U32}
  Flash{n: U32}
  Said{n: U32, tics: U32}

def Closed.edit(inv: I.Inventory, e: Closed.Edit) -> I.Inventory:
  match inv e:
    case I.Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items,
      bonus, line, kills, secrets} Health{n}:
      I.Inventory{n, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus, line, kills, secrets}
    case I.Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items,
      bonus, line, kills, secrets} Armour{points, kind}:
      I.Inventory{health, points, kind, cards, ammo, caps, backpack, weapons, powers, items, bonus, line, kills, secrets}
    case I.Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items,
      bonus, line, kills, secrets} Cards{bits}:
      I.Inventory{health, armour, armourtype, bits, ammo, caps, backpack, weapons, powers, items, bonus, line, kills, secrets}
    case I.Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items,
      bonus, line, kills, secrets} Ammo{rounds}:
      I.Inventory{health, armour, armourtype, cards, V.Vec.of_list(rounds, 4), caps, backpack, weapons, powers, items,
        bonus, line, kills, secrets}
    case I.Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items,
      bonus, line, kills, secrets} Backpack{}:
      I.Inventory{health, armour, armourtype, cards, ammo, V.Vec.of_list([400, 100, 600, 100], 4), True{}, weapons,
        powers, items, bonus, line, kills, secrets}
    case I.Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items,
      bonus, line, kills, secrets} Weapons{bits}:
      I.Inventory{health, armour, armourtype, cards, ammo, caps, backpack, bits, powers, items, bonus, line, kills, secrets}
    case I.Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items,
      bonus, line, kills, secrets} Selection{ready, pending}:
      I.Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus,
        ((line .&. 65535 : U32) .|. (ready << 16n : U32) .|. (pending << 24n : U32) : U32), kills, secrets}
    case I.Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items,
      bonus, line, kills, secrets} Power{power, n}:
      I.Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons,
        V.Vec.set(powers, power, n), items, bonus, line, kills, secrets}
    case I.Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items,
      bonus, line, kills, secrets} Items{n}:
      I.Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, n, bonus, line, kills, secrets}
    case I.Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items,
      bonus, line, kills, secrets} Flash{n}:
      I.Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, n, line, kills, secrets}
    case I.Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items,
      bonus, line, kills, secrets} Said{n, tics}:
      I.Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus,
        ((line .&. 4294901760 : U32) .|. (n << 8n : U32) .|. tics : U32), kills, secrets}

# G_PlayerReborn's inventory with changes.
def Closed.inv(es: List<&2, Closed.Edit>) -> I.Inventory:
  List.foldl(~&2, ~Closed.Edit, ~I.Inventory, ~Closed.edit, es, I.Inventory.start())

# What a pickup leaves: the names of the things alive, and the
# inventory.
type Closed.Got is Data:
  Got{ids: List<&2, U32>, inv: I.Inventory}

def Closed.ids(things: List<&2, H.Thing>) -> List<&2, U32>:
  match things:
    case []:
      []
    case H.Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics, momz, hurt} <> rest:
      id <> Closed.ids(rest)

# The inventory with the heads-up line taken off it, which Closed.line
# reads on its own.
def Closed.hushed(inv: I.Inventory) -> I.Inventory:
  I.Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus, line, kills, secrets} = inv
  I.Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus,
    (line .&. 4294901760 : U32), kills, secrets}

def Closed.kept(+s: S.State) -> Closed.Got:
  Got{Closed.ids(H.Things.list(S.State.things(s))), Closed.hushed(S.Player.inv(S.State.player(s)))}

# What the heads-up line shows and how long it has left there.
type Closed.Line is Data:
  Shown{message: U32, tics: U32}

def Closed.line(+s: S.State) -> Closed.Line:
  Shown{I.Inventory.message(S.Player.inv(S.State.player(s))),
    I.Inventory.msgtics(S.Player.inv(S.State.player(s)))}

# The line after the tic that brings the player 8 from a thing of a
# type, in its reach.
def Closed.said(inv: I.Inventory, kind: U32) -> Closed.Line:
  Closed.line(Closed.idled(1n, Closed.among(inv, 2097152, 0, 524288, [Closed.thing(1, kind, 2097152, 5242880, 0)])))

# The line after n tics of a player with nothing to pick up.
def Closed.ticked(n: Nat, inv: I.Inventory) -> Closed.Line:
  Closed.line(Closed.idled(n, Closed.among(inv, 2097152, 0, 0, [])))

# What is left after n tics of the west room's player, holding an
# inventory, walking north by a momentum a tic toward a thing of a type
# at (32, 80), record 1.
def Closed.walk(n: Nat, momy: U32, inv: I.Inventory, kind: U32) -> Closed.Got:
  Closed.kept(Closed.idled(n, Closed.among(inv, 2097152, 0, momy, [Closed.thing(1, kind, 2097152, 5242880, 0)])))

# What is left after the tic that brings the player 8 from the thing, in
# its reach.
def Closed.offer(inv: I.Inventory, kind: U32) -> Closed.Got:
  Closed.walk(1n, 524288, inv, kind)

# Moving north at 8 a tic from (32, 64) past a bloody mess (record 3)
# and a blue card (record 87), both at (32, 112), toward another blue
# card (record 90) at (32, 400).
def Closed.passing() -> S.State:
  Closed.among(I.Inventory.start(), 2097152, 0, 524288, [Closed.thing(3, 10, 2097152, 7340032, 0),
    Closed.thing(87, 5, 2097152, 7340032, 0), Closed.thing(90, 5, 2097152, 26214400, 0)])

def Closed.key_at(z: U32) -> Closed.Got:
  Closed.kept(Closed.idled(1n, Closed.among(I.Inventory.start(), 2097152, 0, 524288,
    [Closed.floored(87, 5, 2097152, 5242880, z)])))

# The player at (40, 64) moving east at 12 a tic into the shut door,
# with a blue card at (86, 64) past it.
def Closed.shut_out() -> S.State:
  Closed.idled(1n, Closed.among(I.Inventory.start(), 2621440, 786432, 0, [Closed.thing(87, 5, 5636096, 4194304, 0)]))

def Closed.within(d: H.Thing.Def) -> Bool:
  H.Def{kind, state, radius, height, flags} = d
  U32.is_le(F.Fixed.of_map(radius), S.Sim.maxradius())

def Closed.lasting(d: H.Thing.Def) -> Bool:
  H.Def{kind, state, radius, height, flags} = d
  Bool.not(U32.is_eq((flags .&. 3 : U32), 3))

def Closed.blocks(d: H.Thing.Def) -> Bool:
  H.Def{kind, state, radius, height, +flags} = d
  Bool.or(U32.is_zero((flags .&. 4194304 : U32)), U32.is_eq((flags .&. 6 : U32), 6))

def Closed.row(+s: U32) -> Bool:
  U32.is_lt(s, U32.from_nat(List.length(&2, H.Thing.Row, H.Thing.rows())))

def Closed.next(+next: U32) -> Bool:
  Bool.or(Closed.row(next), U32.is_eq(next, H.Thing.null()))

def Closed.leads(r: H.Thing.Row) -> Bool:
  Closed.next(H.Thing.Row.next(r))

def Closed.spawns(d: H.Thing.Def) -> Bool:
  H.Def{kind, state, radius, height, flags} = d
  Closed.row(state)

# The west room's player at (32, 64) on the literal level among a floor
# lamp (type 2028: radius 16, height 16, solid) at (32, 112), a dead
# player (type 15: no flags) at (32, 32), a barrel (type 2035: radius 10,
# height 42, solid and shootable) at (96, 112) and another 100 up at
# (160, 112), entered in that order, the player's mobj last.
def Closed.linked() -> S.State:
  Closed.at(Closed.player(2097152, 4194304, 0, 8388608), Closed.doors(), [],
    [Closed.thing(8, 2028, 2097152, 7340032, 0), Closed.thing(15, 15, 2097152, 2097152, 0),
      Closed.thing(24, 2035, 6291456, 7340032, 0), Closed.thing(30, 2035, 10485760, 7340032, 6553600)])

# Whether the mobj an id names stops a box of a radius, a height and
# flags at a place among those things.
def Closed.stops(id: U32, x: U32, y: U32, z: U32, radius: U32, height: U32, flags: U32, self: U32) -> Bool:
  S.Sim.stops.at(S.State.things(Closed.linked()), S.State.player(Closed.linked()),
    S.Body{self, x, y, z, radius, height, flags}, id)

# The west room's player, its id a record's, moving east by a momentum
# among three dead players at (32, 32) named 2, 5 and 9.
def Closed.ranked(you: U32, x: U32, momx: U32) -> S.State:
  S.State.populated([Closed.thing(2, 15, 2097152, 2097152, 0), Closed.thing(5, 15, 2097152, 2097152, 0),
    Closed.thing(9, 15, 2097152, 2097152, 0)], 128, S.State{S.Player{x, 4194304, 0, 0, momx, 0, 0, 0, 8388608, 2686976,
      0, 2686976, [], I.Inventory.start(), Closed.unarmed(), S.Sim.Hurt.start()}, Closed.doors(), H.Things.none(0, you, 0, 0), V.Leaf{0},
    S.Thinkers{[], []}, 0, 0, S.Unended{}, False{}, [], S.Sim.Face.start(0), False{}, V.Leaf{0}})

# The mobjs the one cell lists.
def Closed.cell(s: S.State) -> List<&2, U32>:
  S.Sim.near(Closed.doors(), S.State.things(s), 2097152, 4194304, 1048576)

# A run of the thinkers cut short: the fuel is a list of one, whose
# elements the run does not read, so one thinker takes its turn and the
# rest stay due, where an action's spawn joins them.
def Closed.midrun(+s: S.State) -> S.State:
  Tic.Sim.thinkers.go([S.Mobj{0}], K.Cmd.idle(), L.Level.geo(S.State.level(s)), s)

# A health bonus spawned into the west room once the player's mobj, the
# only thinker there, has taken its turn.
def Closed.spawned() -> S.State:
  S.Sim.spawn(H.Thing.info(2014), 2097152, 4194304, H.Thing.onfloor(),
    Closed.midrun(Closed.at(Closed.player(2097152, 4194304, 0, 8388608), Closed.doors(), [], [])))

# The rest of that run.
def Closed.spawned.ran() -> S.State:
  Tic.Sim.thinkers.all(8n, K.Cmd.idle(), L.Level.geo(Closed.doors()), Closed.spawned())

def Closed.tics(m: Maybe<&2, H.Thing>) -> Maybe<&2, U32>:
  match m:
    case None{}:
      None{}
    case Some{H.Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics, momz, hurt}}:
      Some{tics}

def Closed.north(things: List<&2, H.Thing>, n: Nat) -> U32:
  S.Player.y(S.State.player(Closed.idled(n, Closed.among(I.Inventory.start(), 2097152, 0, 524288, things))))

# A state of the literal level with one mover and a player at rest at
# (x, 64) under the west room's ceiling, among things.
def Closed.moving.among(level: L.Level, t: S.Thinker, x: U32, things: List<&2, H.Thing>) -> S.State:
  Closed.at(Closed.player(x, 4194304, 0, 8388608), level, [t], things)

def Closed.things(s: S.State) -> List<&2, H.Thing>:
  H.Things.list(S.State.things(s))

def Closed.lowering(n: Nat) -> List<&2, H.Thing>:
  Closed.things(Closed.idled(n, Closed.moving.among(Closed.doors(),
    S.Mover{0, False{}, 262144, [S.Travel{True{}, 4293918720}], [S.Travel{True{}, 4293918720}], Sp.Sim.noise.floor()}, 13107200,
    [Closed.thing(29, 60, 2097152, 6553600, 3932160), Closed.thing(24, 2035, 2097152, 1048576, 0)])))

# The door open at 68 and closing, 2 a tic, over a thing, the west room's
# player at (32, 64) in the one cell.
def Closed.closing(th: H.Thing) -> S.State:
  Closed.moving.among(L.Level.plane.put(Closed.doors(), 1, True{}, 4456448),
    S.Mover{1, True{}, 131072, [S.Travel{True{}, 0}], [S.Travel{False{}, 4456448}, S.Hold{150}, S.Travel{True{}, 0}], Sp.Sim.noise.door()},
    2097152, [th])

def Closed.over_barrel() -> S.State:
  Closed.at(Closed.player(2097152, 4194304, 0, 8388608), Closed.doors(), [],
    [Closed.thing(24, 2035, 4718592, 6553600, 0)])

# The things' tests stand on the literal level with three THINGS
# records on every skill: player 1's start at (32, 64) in the west room,
# a health bonus at (16, 32) and green armour at (16, 96). The one
# subsector's seg is line 0's front, so each stands in the west room, on
# its floor at 0. Their rows are Bendoom's numbers for info.c's states:
# S_BON1 12, then S_BON1A to S_BON1E 13 to 17, 6 tics each, then S_BON1
# again; S_ARM1 6, 6 tics, and S_ARM1A 7, 7 tics, in turn.
def Closed.stocked() -> S.State:
  Tic.State.at(Closed.level(0, V.Vec.of_list([32, 64, 0, 1, 7, 16, 32, 0, 2014, 7, 16, 96, 0, 2018, 7], 15), 3),
    L.Start{2097152, 4194304, 0})

def Closed.looking(a: H.Thing.Action) -> Bool:
  match a:
    case H.Look{}:
      True{}
    case _:
      False{}

def Closed.chasing(a: H.Thing.Action) -> Bool:
  match a:
    case H.Chase{}:
      True{}
    case _:
      False{}

def Closed.wakes(d: H.Thing.Def) -> Bool:
  H.Def{+kind, +state, radius, height, flags} = d
  Bool.or(U32.is_zero(H.Thing.seesound(kind)),
    Bool.and(Closed.looking(H.Thing.Row.action(H.Thing.row(state))),
      Bool.and(Closed.row(H.Thing.see(kind)),
        Closed.chasing(H.Thing.Row.action(H.Thing.row(H.Thing.see(kind)))))))

# A sprite's view from the origin facing east along the x axis, the
# eye 41 up, with the sine and cosine of the angle exactly 0 and 1; the
# graphics hold two state rows' sprites, 64 wide with its origin 32 in
# and 56 down, full-bright: row 0's patch at 1000, row 1's at 2000 and
# mirrored, the same seen from every side.
def Sprite.view() -> P.View:
  P.View{0, 0, 2686976, 0, 0, 65536, P.Tables{V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, V.Leaf{0},
    V.Leaf{0}, V.Leaf{0}, 0}, 0}

def Sprite.slots(n: Nat, +patch: U32, +flip: U32) -> List<&2, U32>:
  match n:
    case 0n:
      []
    case 1n+m:
      patch <> 4194304 <> 2097152 <> 3670016 <> flip <> 1 <> Sprite.slots(m, patch, flip)

def Sprite.gfx() -> G.Gfx:
  G.Gfx{V.Leaf{0}, V.Leaf{0}, 0, V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, 0,
    V.Vec.of_list(List.append(&2, U32, Sprite.slots(8n, 1000, 0), Sprite.slots(8n, 2000, 1)), 96),
    G.Anims{G.Anim{[], 0, V.Leaf{0}}, G.Anim{[], 0, V.Leaf{0}}, 0}, V.Leaf{0}, V.Leaf{0}}

# Thing id in a state row, x ahead of the eye and y to its left.
def Sprite.at(+id: U32, x: U32, y: U32, state: U32) -> List<&2, Z.Sprites.Vis>:
  Z.Sprites.project(Sprite.view(), Closed.doors(), Sprite.gfx(), 1, id,
    H.Thing{id, 2014, x, y, 0, 0, 0, 0, 0, state, 4294967295, 0, H.Thing.Hurt.of(2014)}, [])

# A sprite of a scale, its sector's rank in the walk and its thing's
# place among the things shown.
def Sprite.vis(scale: U32, rank: U32, nth: U32) -> Z.Sprites.Vis:
  Z.Vis{0, 0, scale, 0, 0, 0, 0, 0, 0, 0, 0, 0, rank, nth}

def Sprite.moved.some(m: Maybe<&2, H.Thing>, +s: S.State) -> S.State:
  match m:
    case None{}:
      s
    case Some{+th}:
      S.State.moved(S.Try{True{}, S.State.player(s), H.Things.moved(S.State.things(s),
        L.Level.blockmap_of(S.State.level(s)), th, H.Thing.at(th, S.State.level(s), 2162688, 2097152))},
        S.State.level(s), s)

# A state with thing 2 moved to (33, 32).
def Sprite.moved(+s: S.State) -> S.State:
  Sprite.moved.some(H.Things.get(S.State.things(s), 2), s)

# The ids of the things a state shows, in the order it shows them.
def Sprite.shown(s: S.State) -> List<&2, U32>:
  Closed.ids(H.Things.shown(S.State.things(s)))

# An event after its delta.
type Closed.At is Data:
  At{delta: U32, event: Mi.Midi.Event}

# A track's events to its end, each after its delta, at most n.
def Closed.events(n: Nat, g: Mi.Midi.Got, +d: U32) -> List<&2, Closed.At>:
  match n g:
    case _ Mi.Got{Mi.End{}, t}:
      [At{d, Mi.End{}}]
    case 0n Mi.Got{e, t}:
      []
    case 1n+m Mi.Got{e, +t}:
      At{d, e} <> Closed.events(m, Mi.Midi.next(t), Mi.Midi.delta(t))

def Closed.track(+t: Mi.Midi.Track) -> List<&2, Closed.At>:
  Closed.events(40n, Mi.Midi.next(t), Mi.Midi.delta(t))

# A song's division, and its first track's events.
def Closed.song(f: Mi.Midi.File) -> U32 & List<&2, Closed.At>:
  Mi.File{division, tracks} = f
  (division, Closed.track(Maybe.default(&2, Mi.Midi.Track, List.head(&2, Mi.Midi.Track, tracks), Mi.Bad{""})))

# A MUS lump of a score: its header, the score at byte 16.
def Closed.mus(score: List<&2, U32>) -> List<&2, U32>:
  List.append(&2, U32, [77, 85, 83, 26, 0, 0, 16, 0, 0, 0, 0, 0, 0, 0, 0, 0], score)

# A MIDI lump of one track, at a division of 96 unless the header says.
def Closed.midi(header: List<&2, U32>, track: List<&2, U32>) -> List<&2, U32>:
  List.concat(&2, U32, [[77, 84, 104, 100, 0, 0, 0, 6], header, [77, 84, 114, 107, 0, 0, 0, 0], track])

def Closed.fails(+lump: List<&2, U32>) -> Bool:
  Maybe.is_some(&2, String, Mi.Midi.fault(lump))

def Closed.buffer(o: O.Opl) -> U32 & U32 & Nat:
  O.Opl{core, count, last, pending, rcnt, oldl, oldr, curl, curr} = o
  (count, last, List.length(&2, O.Opl.Pending, pending))

# Words as a line, each after a space.
def words(xs: List<&2, U32>) -> String:
  match xs:
    case []:
      ""
    case x <> rest:
      " " ++ U32.show(x) ++ words(rest)

def psprite(psp: S.Psprite) -> String:
  S.Psprite{state, tics, sx, sy} = psp
  " " ++ Maybe.show(~&2, ~U32, ~U32.show, state) ++ words([tics, sx, sy])

def psprites(ps: S.Psprites) -> String:
  S.Psprites{weapon, flash} = ps
  psprite(weapon) ++ psprite(flash)

def crossings(cs: List<&2, S.Sim.Cross>) -> String:
  match cs:
    case []:
      ""
    case S.Cross{line, x, y, z, angle} <> rest:
      words([line, x, y, z, angle]) ++ crossings(rest)

def rest(cs: List<&2, S.Sim.Cross>, +inv: I.Inventory, ps: S.Psprites, +hurt: V.Vec) -> String:
  crossings(cs) ++ " | " ++ I.Inventory.show(inv)
    ++ words([I.Inventory.line(inv), I.Inventory.kills(inv), I.Inventory.secrets(inv)]) ++ " |" ++ psprites(ps)
    ++ " |" ++ V.Vec.show(hurt, 7n, 0)

# Whether the rest of a player is as it began, compared as printed: no
# line crossed, G_PlayerReborn's inventory, no weapon sprite showing and
# the mobj unhurt.
def began(cs: List<&2, S.Sim.Cross>, inv: I.Inventory, ps: S.Psprites, hurt: V.Vec) -> Bool:
  String.eq(rest(cs, inv, ps, hurt), rest([], I.Inventory.start(), Closed.unarmed(), S.Sim.Hurt.start()))
