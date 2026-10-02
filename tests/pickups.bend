# The pickups, the keys and the things on the literal door level of
# tests/fixtures/closed.bend. A pickup's line is what is left after it:
# the names of the things still alive, the inventory, and the weapon
# ready and pending. The expected values are p_inter.c's
# P_TouchSpecialThing, P_GiveCard, P_GiveBody, P_GiveArmor, P_GivePower,
# P_GiveAmmo and P_GiveWeapon, d_items.c's clips, p_user.c's
# P_PlayerThink, p_doors.c's EV_VerticalDoor, p_map.c's line checks,
# p_mobj.c's P_SpawnMapThing and P_MobjThinker, info.c and m_random.c in
# Chocolate Doom 3.1.1, by hand. G_PlayerReborn's inventory has 100
# health, 50 bullets under caps of 200 50 300 50, the fist and the
# pistol (weapons 3), the pistol ready and no weapon pending (255).
import Base
import ../src/fixed.bend as F
import ../src/vec.bend as V
import ../src/level.bend as L
import ../src/sim.bend as S
import ../src/things.bend as H
import ../src/inventory.bend as I
import ../src/message.bend as Msg
import ./fixtures/closed.bend as Fx

def ids(xs: List<&2, U32>) -> String:
  match xs:
    case []:
      ""
    case x <> rest:
      " " ++ U32.show(x) ++ ids(rest)

def got(g: Fx.Closed.Got) -> String:
  Fx.Got{alive, +inv} = g
  "alive" ++ ids(alive) ++ ", " ++ I.Inventory.show(inv) ++ " ready " ++ U32.show(I.Inventory.ready(inv))
    ++ " pending " ++ U32.show(I.Inventory.pending(inv))

def offered(tag: String, g: Fx.Closed.Got) -> IO(Unit):
  IO.print(tag ++ " " ++ got(g))

def shown(l: Fx.Closed.Line) -> IO(Unit):
  Fx.Shown{message, tics} = l
  IO.print("line " ++ U32.show(message) ++ " " ++ U32.show(tics))

def thing(th: H.Thing) -> String:
  H.Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics, momz, +hurt} = th
  "thing " ++ U32.show(id) ++ " type " ++ U32.show(kind) ++ " at " ++ U32.show(x) ++ " " ++ U32.show(y)
    ++ " z " ++ U32.show(z) ++ " floor " ++ U32.show(floorz) ++ " ceiling " ++ U32.show(ceilz)
    ++ " angle " ++ U32.show(angle) ++ " sector " ++ U32.show(sector) ++ " state " ++ U32.show(state)
    ++ " tics " ++ U32.show(tics) ++ " momz " ++ U32.show(momz) ++ " hurt" ++ V.Vec.show(hurt, 12n, 0)

def things(+tag: String, ths: List<&2, H.Thing>) -> IO(Unit):
  match ths:
    case []:
      IO.pure(Unit, Unit{})
    case th <> rest:
      do IO<Unit>:
        IO.print(tag ++ " " ++ thing(th))
        things(tag, rest)

# The blue locked door, special 26, after a tic of use: with no card, or
# with the yellow card alone, it stays shut at 0; with the blue card or
# the blue skull it is the manual door, 2 up (131072).
def blue_door_locked() -> IO(Unit):
  IO.print("blue door none " ++ U32.show(Fx.Closed.ceil(Fx.Closed.used(0n, Fx.Closed.locked(I.Inventory.start())), 1))
    ++ " yellow " ++ U32.show(Fx.Closed.ceil(Fx.Closed.used(0n,
      Fx.Closed.locked(I.Inventory.card(2, Msg.Message.none(), I.Inventory.start()))), 1))
    ++ " card " ++ U32.show(Fx.Closed.ceil(Fx.Closed.used(0n,
      Fx.Closed.locked(I.Inventory.card(1, Msg.Message.none(), I.Inventory.start()))), 1))
    ++ " skull " ++ U32.show(Fx.Closed.ceil(Fx.Closed.used(0n,
      Fx.Closed.locked(I.Inventory.card(8, Msg.Message.none(), I.Inventory.start()))), 1)))

# The blue card, walked past north at 8 a tic with a bloody mess
# (record 3) beside it and another card (record 90) far ahead. Tic 1
# moves the player to 72, 40 short of the card, and the reach is its
# radius 20 and the player's 16. Friction leaves 7.25 a tic, so tic 2
# moves it to 79.25, 32.75 short: record 87 is gone and no other, the
# blue card is held (cards 1), and P_GiveCard's 6 and the pickup's 6 set
# the flash to 12. On tic 3, still in reach of where it was, nothing is
# touched again and the flash fades to 11.
def key_taken() -> IO(Unit):
  do IO<Unit>:
    offered("key tic 1", Fx.Closed.kept(Fx.Closed.idled(1n, Fx.Closed.passing())))
    offered("key tic 2", Fx.Closed.kept(Fx.Closed.idled(2n, Fx.Closed.passing())))
    offered("key tic 3", Fx.Closed.kept(Fx.Closed.idled(3n, Fx.Closed.passing())))

# A move of 20 a tic is tried in halves, to 74 and then 84, and a blue
# card at (32, 100) is in reach of both: the first takes it, the second
# finds it gone, so the flash is 12 and not 18.
def key_taken_once() -> IO(Unit):
  offered("key halves", Fx.Closed.kept(Fx.Closed.idled(1n, Fx.Closed.among(I.Inventory.start(), 2097152, 0, 1310720,
    [Fx.Closed.thing(87, 5, 2097152, 6553600, 0)]))))

# Vertical reach. A tic moves the player to 72, 8 from a blue card at
# (32, 80); the card is taken with its bottom 56 over the player's feet
# and not 57, and 8 under them and not 9.
def key_reach() -> IO(Unit):
  do IO<Unit>:
    offered("key over 56", Fx.Closed.key_at(3670016))
    offered("key over 57", Fx.Closed.key_at(3735552))
    offered("key under 8", Fx.Closed.key_at(4294443008))
    offered("key under 9", Fx.Closed.key_at(4294377472))

def short_of_door(+s: S.State) -> IO(Unit):
  IO.print("key through door " ++ got(Fx.Closed.kept(s)) ++ " short "
    ++ Bool.show(F.Fixed.le(S.Player.x(S.State.player(s)), 3145728)))

# P_CheckPosition touches things before it checks lines. The move to 52
# puts the box across the shut door, whose opening refuses it, but its
# position check has already taken the card, 34 away; the slide that
# follows stops the player short of the door, at most 48 (3145728), from
# where the card is out of reach.
def key_through_door() -> IO(Unit):
  short_of_door(Fx.Closed.shut_out())

# The health bonus is always taken and counted. From 100 it makes 101,
# from 199 200, and at 200 it adds nothing and still goes; the flash is
# 6.
def health_bonus() -> IO(Unit):
  do IO<Unit>:
    offered("health bonus at 100", Fx.Closed.offer(I.Inventory.start(), 2014))
    offered("health bonus at 199", Fx.Closed.offer(Fx.Closed.inv([Fx.Health{199}]), 2014))
    offered("health bonus at 200", Fx.Closed.offer(Fx.Closed.inv([Fx.Health{200}]), 2014))

# The stimpack heals 10 up to 100 and is not counted: 89 makes 99, 99
# makes 100, and at 100 it stays, the inventory untouched.
def stimpack() -> IO(Unit):
  do IO<Unit>:
    offered("stimpack at 89", Fx.Closed.offer(Fx.Closed.inv([Fx.Health{89}]), 2011))
    offered("stimpack at 99", Fx.Closed.offer(Fx.Closed.inv([Fx.Health{99}]), 2011))
    offered("stimpack at 100", Fx.Closed.offer(I.Inventory.start(), 2011))

# The medikit heals 25 up to 100 and is not counted: 74 makes 99, 75
# and 99 make 100, and at 100, or at 150 from bonuses, it stays.
def medikit() -> IO(Unit):
  do IO<Unit>:
    offered("medikit at 74", Fx.Closed.offer(Fx.Closed.inv([Fx.Health{74}]), 2012))
    offered("medikit at 75", Fx.Closed.offer(Fx.Closed.inv([Fx.Health{75}]), 2012))
    offered("medikit at 99", Fx.Closed.offer(Fx.Closed.inv([Fx.Health{99}]), 2012))
    offered("medikit at 100", Fx.Closed.offer(I.Inventory.start(), 2012))
    offered("medikit at 150", Fx.Closed.offer(Fx.Closed.inv([Fx.Health{150}]), 2012))

# The soul sphere adds 100 up to 200 and is always taken and counted: 99
# makes 199, 100 and 101 make 200, and 200 stays 200.
def soul_sphere() -> IO(Unit):
  do IO<Unit>:
    offered("soul sphere at 99", Fx.Closed.offer(Fx.Closed.inv([Fx.Health{99}]), 2013))
    offered("soul sphere at 100", Fx.Closed.offer(I.Inventory.start(), 2013))
    offered("soul sphere at 101", Fx.Closed.offer(Fx.Closed.inv([Fx.Health{101}]), 2013))
    offered("soul sphere at 200", Fx.Closed.offer(Fx.Closed.inv([Fx.Health{200}]), 2013))

# The berserk pack is always taken and counted, and sets the strength
# counter, the second power, to 1, even over one already running at 40.
# It heals 1 to 100, leaves 100 at 100, and does not lower 150; the
# fist, weapon 0, is pending and the pistol still ready.
def berserk() -> IO(Unit):
  do IO<Unit>:
    offered("berserk at 1", Fx.Closed.offer(Fx.Closed.inv([Fx.Health{1}]), 2023))
    offered("berserk at 100", Fx.Closed.offer(I.Inventory.start(), 2023))
    offered("berserk at 150", Fx.Closed.offer(Fx.Closed.inv([Fx.Health{150}]), 2023))
    offered("berserk over 40", Fx.Closed.offer(Fx.Closed.inv([Fx.Strength{40}]), 2023))

# The armour bonus is always taken and counted: no armour makes 1 point
# of green armour's type, 199 points of blue make 200 and stay blue, and
# 200 points of green take nothing more.
def armour_bonus() -> IO(Unit):
  do IO<Unit>:
    offered("armour bonus at none", Fx.Closed.offer(I.Inventory.start(), 2015))
    offered("armour bonus at blue 199", Fx.Closed.offer(Fx.Closed.inv([Fx.Armour{199, 2}]), 2015))
    offered("armour bonus at green 200", Fx.Closed.offer(Fx.Closed.inv([Fx.Armour{200, 1}]), 2015))

# Green armour gives 100 points of type 1 over fewer points of any type,
# blue's 99 among them, and is not counted; with 100 points of green, or
# 150 of blue, it stays.
def green_armour() -> IO(Unit):
  do IO<Unit>:
    offered("green armour at none", Fx.Closed.offer(I.Inventory.start(), 2018))
    offered("green armour at blue 99", Fx.Closed.offer(Fx.Closed.inv([Fx.Armour{99, 2}]), 2018))
    offered("green armour at green 100", Fx.Closed.offer(Fx.Closed.inv([Fx.Armour{100, 1}]), 2018))
    offered("green armour at blue 150", Fx.Closed.offer(Fx.Closed.inv([Fx.Armour{150, 2}]), 2018))

# Blue armour gives 200 points of type 2 over fewer, 199 among them, and
# is not counted; with 200 points of either type it stays.
def blue_armour() -> IO(Unit):
  do IO<Unit>:
    offered("blue armour at none", Fx.Closed.offer(I.Inventory.start(), 2019))
    offered("blue armour at green 199", Fx.Closed.offer(Fx.Closed.inv([Fx.Armour{199, 1}]), 2019))
    offered("blue armour at green 200", Fx.Closed.offer(Fx.Closed.inv([Fx.Armour{200, 1}]), 2019))
    offered("blue armour at blue 200", Fx.Closed.offer(Fx.Closed.inv([Fx.Armour{200, 2}]), 2019))

# A move of 20 a tic is tried in halves, to 74 and then 84, and a health
# bonus at (32, 80) is in reach of both: the first takes it and the
# second finds it gone, so health is 101, the tally 1 and the flash 6,
# not 102, 2 and 12.
def bonus_counted_once() -> IO(Unit):
  offered("health bonus halves", Fx.Closed.walk(1n, 1310720, I.Inventory.start(), 2014))

# P_PlayerThink counts strength up a tic before it counts the flash
# down, and both before the mobj moves: a berserk pack taken on the
# first tic leaves the counter at 1 and the flash at 6; the next two
# tics make 2 and 5, then 3 and 4.
def strength_counts() -> IO(Unit):
  do IO<Unit>:
    offered("berserk tic 1", Fx.Closed.walk(1n, 524288, I.Inventory.start(), 2023))
    offered("berserk tic 2", Fx.Closed.walk(2n, 524288, I.Inventory.start(), 2023))
    offered("berserk tic 3", Fx.Closed.walk(3n, 524288, I.Inventory.start(), 2023))

# P_GiveAmmo's clipammo on Hurt Me Plenty, which doubles nothing, from
# G_PlayerReborn's inventory, in ammotype_t order (bullets, shells,
# cells, rockets): a clip gives 10 bullets, shells 4, a cell 20, a
# rocket 1; the boxes give five clips, 50 bullets, 20 shells, 100 cells
# and 5 rockets. Each is taken, and flashes 6.
def ammo_amounts() -> IO(Unit):
  do IO<Unit>:
    offered("clip", Fx.Closed.offer(I.Inventory.start(), 2007))
    offered("shells", Fx.Closed.offer(I.Inventory.start(), 2008))
    offered("cell", Fx.Closed.offer(I.Inventory.start(), 2047))
    offered("rocket", Fx.Closed.offer(I.Inventory.start(), 2010))
    offered("box of bullets", Fx.Closed.offer(I.Inventory.start(), 2048))
    offered("box of shells", Fx.Closed.offer(I.Inventory.start(), 2049))
    offered("cell pack", Fx.Closed.offer(I.Inventory.start(), 17))
    offered("box of rockets", Fx.Closed.offer(I.Inventory.start(), 2046))

def capped(+tag: String, rounds: List<&2, U32>, kind: U32) -> IO(Unit):
  offered(tag, Fx.Closed.offer(Fx.Closed.inv([Fx.Ammo{rounds}]), kind))

# maxammo's caps, 200 bullets, 50 shells, 300 cells and 50 rockets. At
# each, the loose round and the box are refused, stay, and change
# nothing; one short of each, the box is taken and fills it to the cap.
def ammo_caps() -> IO(Unit):
  do IO<Unit>:
    capped("clip at cap", [200, 50, 300, 50], 2007)
    capped("box of bullets at cap", [200, 50, 300, 50], 2048)
    capped("shells at cap", [200, 50, 300, 50], 2008)
    capped("box of shells at cap", [200, 50, 300, 50], 2049)
    capped("cell at cap", [200, 50, 300, 50], 2047)
    capped("cell pack at cap", [200, 50, 300, 50], 17)
    capped("rocket at cap", [200, 50, 300, 50], 2010)
    capped("box of rockets at cap", [200, 50, 300, 50], 2046)
    capped("box of bullets short", [199, 49, 299, 49], 2048)
    capped("box of shells short", [199, 49, 299, 49], 2049)
    capped("cell pack short", [199, 49, 299, 49], 17)
    capped("box of rockets short", [199, 49, 299, 49], 2046)

# The first backpack doubles every cap, to 400 100 600 100, before it
# gives a clip of each ammo type: from the start 60 4 20 1, and from
# ammo at the old caps 210 54 320 51. Either way it is taken.
def backpack_first() -> IO(Unit):
  do IO<Unit>:
    offered("backpack", Fx.Closed.offer(I.Inventory.start(), 8))
    offered("backpack at caps", Fx.Closed.offer(Fx.Closed.inv([Fx.Ammo{[200, 50, 300, 50]}]), 8))

# A later backpack leaves the doubled caps as they are and gives the
# clips again, 60 4 20 1 to 70 8 40 2; at the doubled caps it gives
# nothing, and it is still taken.
def backpack_later() -> IO(Unit):
  do IO<Unit>:
    offered("second backpack", Fx.Closed.offer(Fx.Closed.inv([Fx.Ammo{[60, 4, 20, 1]}, Fx.Backpack{}]), 8))
    offered("second backpack at caps",
      Fx.Closed.offer(Fx.Closed.inv([Fx.Ammo{[400, 100, 600, 100]}, Fx.Backpack{}]), 8))

# P_GiveWeapon for a weapon found, which brings two clips. The shotgun,
# not owned, is owned (weapons 3 to 7) with 8 shells; owned, its 8
# shells alone take it; owned at 50 shells it stays; not owned at 50
# shells the weapon alone takes it. The chaingun brings 20 bullets and
# stays when owned at 200, the rocket launcher 2 rockets, the plasma
# rifle 40 cells. The chainsaw has no ammo: taken when not owned, left
# when owned. A newly owned weapon is pending, by its weapontype_t
# number, and the pistol stays ready.
def weapon_taken() -> IO(Unit):
  do IO<Unit>:
    offered("shotgun", Fx.Closed.offer(I.Inventory.start(), 2001))
    offered("shotgun owned", Fx.Closed.offer(Fx.Closed.inv([Fx.Ammo{[50, 8, 0, 0]}, Fx.Weapons{7}]), 2001))
    offered("shotgun owned at cap", Fx.Closed.offer(Fx.Closed.inv([Fx.Ammo{[50, 50, 0, 0]}, Fx.Weapons{7}]), 2001))
    offered("shotgun at cap", Fx.Closed.offer(Fx.Closed.inv([Fx.Ammo{[50, 50, 0, 0]}]), 2001))
    offered("chaingun", Fx.Closed.offer(I.Inventory.start(), 2002))
    offered("chaingun owned at cap", Fx.Closed.offer(Fx.Closed.inv([Fx.Ammo{[200, 0, 0, 0]}, Fx.Weapons{11}]), 2002))
    offered("rocket launcher", Fx.Closed.offer(I.Inventory.start(), 2003))
    offered("plasma rifle", Fx.Closed.offer(I.Inventory.start(), 2004))
    offered("chainsaw", Fx.Closed.offer(I.Inventory.start(), 2005))
    offered("chainsaw owned", Fx.Closed.offer(Fx.Closed.inv([Fx.Weapons{131}]), 2005))

# P_GiveAmmo's switch once a type that was empty is given: with the fist
# up, a clip brings up the chaingun when owned and else the pistol; with
# the pistol up, shells bring up the shotgun when owned.
def ammo_switch() -> IO(Unit):
  do IO<Unit>:
    offered("clip to the pistol", Fx.Closed.offer(Fx.Closed.inv([Fx.Ammo{[0, 0, 0, 0]}, Fx.Selection{0, 255}]), 2007))
    offered("clip to the chaingun",
      Fx.Closed.offer(Fx.Closed.inv([Fx.Ammo{[0, 0, 0, 0]}, Fx.Weapons{11}, Fx.Selection{0, 255}]), 2007))
    offered("shells to the shotgun", Fx.Closed.offer(Fx.Closed.inv([Fx.Weapons{7}]), 2008))

# The heads-up line, as its message and the tics it has left. d_englsh.h's
# string for each pickup type the two E1M1s hold, numbered by Bendoom's
# Message: the health bonus 3, the stimpack 5, the medikit 6, green
# armour 1, blue armour 2, the blue card 7, the chainsaw 15, the berserk
# pack 8 and the chaingun 18, then PD_BLUEK, 17, for the blue door that
# refuses; and
# hu_stuff.c's four seconds, HU_MSGTIMEOUT 140 tics. A pickup takes the
# line on its own tic with 140 tics left; a pickup the grant refuses
# (the stimpack at 100, green armour over 150 of blue) says nothing and
# leaves the line as it was, none or a line of 90 tics now 89; the
# counter falls by one a tic and the line goes out at zero. The door
# held open by the blue card says nothing.
def pickup_messages() -> IO(Unit):
  do IO<Unit>:
    shown(Fx.Closed.said(I.Inventory.start(), 2014))
    shown(Fx.Closed.said(Fx.Closed.inv([Fx.Health{99}]), 2011))
    shown(Fx.Closed.said(Fx.Closed.inv([Fx.Health{99}]), 2012))
    shown(Fx.Closed.said(I.Inventory.start(), 2018))
    shown(Fx.Closed.said(I.Inventory.start(), 2019))
    shown(Fx.Closed.said(I.Inventory.start(), 5))
    shown(Fx.Closed.said(I.Inventory.start(), 2005))
    shown(Fx.Closed.said(I.Inventory.start(), 2023))
    shown(Fx.Closed.said(I.Inventory.start(), 2002))
    shown(Fx.Closed.said(I.Inventory.start(), 2011))
    shown(Fx.Closed.said(Fx.Closed.inv([Fx.Armour{150, 2}]), 2018))
    shown(Fx.Closed.said(Fx.Closed.inv([Fx.Said{3, 90}]), 2011))
    shown(Fx.Closed.ticked(1n, Fx.Closed.inv([Fx.Said{3, 2}])))
    shown(Fx.Closed.ticked(2n, Fx.Closed.inv([Fx.Said{3, 2}])))
    shown(Fx.Closed.ticked(3n, Fx.Closed.inv([Fx.Said{3, 2}])))
    shown(Fx.Closed.line(Fx.Closed.used(0n, Fx.Closed.locked(I.Inventory.start()))))
    shown(Fx.Closed.line(Fx.Closed.used(0n,
      Fx.Closed.locked(I.Inventory.card(1, Msg.Message.none(), I.Inventory.start())))))

def wall() -> L.Level.Line:
  L.Line{0, 0, 0, 8388608, 0, 0, 65535}

def two_sided(flags: U32) -> L.Level.Line:
  L.Line{0, 0, 0, 8388608, flags, 0, 1}

# The distance condition on numbers: a one-sided wall from (0, 0) to
# (0, 128) is touched and crossed by the player's box, radius 16, at
# (8, 64), and neither at (40, 64); at (24, 64) a barrel's box of radius
# 10 is clear of it and the big tree's of 32 crosses it. The wall is
# solid; a two-sided line (flags 4) without the blocking flag 1 is not,
# one with it is; one blocking monsters (flags 2) stops a thing's box
# (mask 3) and not the player's (mask 1).
def line_geometry() -> IO(Unit):
  do IO<Unit>:
    IO.print("wall at 8 touches " ++ Bool.show(S.Sim.box_touches(524288, 4194304, 1048576, wall()))
      ++ " crosses " ++ Bool.show(S.Sim.box_crosses(524288, 4194304, 1048576, wall())))
    IO.print("wall at 40 touches " ++ Bool.show(S.Sim.box_touches(2621440, 4194304, 1048576, wall()))
      ++ " crosses " ++ Bool.show(S.Sim.box_crosses(2621440, 4194304, 1048576, wall())))
    IO.print("wall at 24 barrel crosses " ++ Bool.show(S.Sim.box_crosses(1572864, 4194304, 655360, wall()))
      ++ " tree crosses " ++ Bool.show(S.Sim.box_crosses(1572864, 4194304, 2097152, wall())))
    IO.print("solid wall " ++ Bool.show(S.Sim.solid(1, wall())) ++ " two-sided "
      ++ Bool.show(S.Sim.solid(1, two_sided(4))) ++ " blocking " ++ Bool.show(S.Sim.solid(1, two_sided(5)))
      ++ " monster line to player " ++ Bool.show(S.Sim.solid(1, two_sided(6)))
      ++ " to thing " ++ Bool.show(S.Sim.solid(3, two_sided(6))))

# Over every type Bendoom spawns: none is wider than Doom's MAXRADIUS,
# 32, which the thing check widens its box by; none is both solid and
# special, info.c's flags 2 and 1, so no pickup takes a solid thing
# away, since only a grant removes a thing and only a special thing is
# offered one; every type the tally counts as a kill, info.c's flag
# 4194304, is solid and shootable, so a monster stops the player as a
# solid thing does and a mover as a barrel does. Every type's spawn
# state is a row of the table, and every row's next state is a row of it
# or S_NULL, which removes the thing or stops the sprite showing, so
# nothing enters the empty row Thing.row gives past its end.
def defs() -> IO(Unit):
  do IO<Unit>:
    IO.print("within maxradius " ++ Bool.show(List.all(~&2, ~H.Thing.Def, ~Fx.Closed.within, H.Thing.defs())))
    IO.print("solid stays " ++ Bool.show(List.all(~&2, ~H.Thing.Def, ~Fx.Closed.lasting, H.Thing.defs())))
    IO.print("monsters block " ++ Bool.show(List.all(~&2, ~H.Thing.Def, ~Fx.Closed.blocks, H.Thing.defs())))
    IO.print("states exist " ++ Bool.show(Bool.and(List.all(~&2, ~H.Thing.Row, ~Fx.Closed.leads, H.Thing.rows()),
      List.all(~&2, ~H.Thing.Def, ~Fx.Closed.spawns, H.Thing.defs()))))

# The spawn, vanilla's P_SpawnMapThing, on the literal level with player
# 1's start at (32, 64), a health bonus (record 1) at (16, 32) and green
# armour (record 2) at (16, 96), each in the west room, sector 0, on its
# floor at 0 under its ceiling at 128. Each thing's hurt is P_SpawnMobj's
# mobj_t: spawn health 1000, no target, reaction 8, no threshold or
# momentum, its flags (the bonus special and counted, 8388609; the
# armour special, 1), height 16 and radius 20, and its lastlook. The
# player draws the random table's entry 1. The bonus draws entry 2 for
# P_SpawnMobj, then entry 3, 220, for its first state's tics:
# 1 + 220 mod 6 = 5. The armour draws entry 4, then entry 5, 241:
# 1 + 241 mod 6 = 2. The index is 5. P_SpawnMobj's own draw is each
# one's lastlook, the entry modulo MAXPLAYERS: 109 mod 4 = 1 for the
# bonus and 222 mod 4 = 2 for the armour. The rows are Bendoom's numbers
# for info.c's states: S_BON1 12, then S_BON1A to S_BON1E 13 to 17, 6
# tics each, then S_BON1 again; S_ARM1 6, 6 tics, and S_ARM1A 7, 7 tics,
# in turn.
def spawn_phase(+s: S.State) -> IO(Unit):
  do IO<Unit>:
    things("spawn", Fx.Closed.things(s))
    IO.print("spawn random " ++ U32.show(S.State.rnd(s)))

def cycle(+tag: String, n: Nat) -> IO(Unit):
  things(tag, Fx.Closed.things(Fx.Closed.idled(n, Fx.Closed.stocked())))

def cycled(+s: S.State) -> IO(Unit):
  do IO<Unit>:
    things("tic 35", Fx.Closed.things(s))
    IO.print("tic 35 random " ++ U32.show(S.State.rnd(s)) ++ " clock " ++ U32.show(S.State.clock(s)))

# One complete cycle of the bonus, vanilla's P_MobjThinker. Its 5 tics
# are down to 1 after tic 4; tic 5 enters S_BON1A for 6; tics 11, 17, 23
# and 29 enter the next four states, and tic 35 is back in S_BON1 for 6.
# The armour enters S_ARM1A for 7 on tic 2, S_ARM1 for 6 on tic 9, and
# so on each 13 tics. No thing draws a random number, and the clock
# counts 35.
def bonus_cycle() -> IO(Unit):
  do IO<Unit>:
    cycle("tic 4", 4n)
    cycle("tic 5", 5n)
    cycle("tic 11", 11n)
    cycle("tic 17", 17n)
    cycle("tic 23", 23n)
    cycle("tic 29", 29n)
    cycled(Fx.Closed.idled(35n, Fx.Closed.stocked()))

def main() -> IO(Unit):
  do IO<Unit>:
    blue_door_locked()
    key_taken()
    key_taken_once()
    key_reach()
    key_through_door()
    health_bonus()
    stimpack()
    medikit()
    soul_sphere()
    berserk()
    armour_bonus()
    green_armour()
    blue_armour()
    bonus_counted_once()
    strength_counts()
    ammo_amounts()
    ammo_caps()
    backpack_first()
    backpack_later()
    weapon_taken()
    ammo_switch()
    pickup_messages()
    line_geometry()
    defs()
    spawn_phase(Fx.Closed.stocked())
    bonus_cycle()

#|blue door none 0 yellow 0 card 131072 skull 131072
#|key tic 1 alive 3 87 90, inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 ready 1 pending 255
#|key tic 2 alive 3 90, inventory health 100 armour 0 type 0 cards 1 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 12 ready 1 pending 255
#|key tic 3 alive 3 90, inventory health 100 armour 0 type 0 cards 1 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 11 ready 1 pending 255
#|key halves alive, inventory health 100 armour 0 type 0 cards 1 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 12 ready 1 pending 255
#|key over 56 alive, inventory health 100 armour 0 type 0 cards 1 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 12 ready 1 pending 255
#|key over 57 alive 87, inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 ready 1 pending 255
#|key under 8 alive, inventory health 100 armour 0 type 0 cards 1 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 12 ready 1 pending 255
#|key under 9 alive 87, inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 ready 1 pending 255
#|key through door alive, inventory health 100 armour 0 type 0 cards 1 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 12 ready 1 pending 255 short True
#|health bonus at 100 alive, inventory health 101 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 1 flash 6 ready 1 pending 255
#|health bonus at 199 alive, inventory health 200 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 1 flash 6 ready 1 pending 255
#|health bonus at 200 alive, inventory health 200 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 1 flash 6 ready 1 pending 255
#|stimpack at 89 alive, inventory health 99 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 6 ready 1 pending 255
#|stimpack at 99 alive, inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 6 ready 1 pending 255
#|stimpack at 100 alive 1, inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 ready 1 pending 255
#|medikit at 74 alive, inventory health 99 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 6 ready 1 pending 255
#|medikit at 75 alive, inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 6 ready 1 pending 255
#|medikit at 99 alive, inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 6 ready 1 pending 255
#|medikit at 100 alive 1, inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 ready 1 pending 255
#|medikit at 150 alive 1, inventory health 150 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 ready 1 pending 255
#|soul sphere at 99 alive, inventory health 199 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 1 flash 6 ready 1 pending 255
#|soul sphere at 100 alive, inventory health 200 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 1 flash 6 ready 1 pending 255
#|soul sphere at 101 alive, inventory health 200 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 1 flash 6 ready 1 pending 255
#|soul sphere at 200 alive, inventory health 200 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 1 flash 6 ready 1 pending 255
#|berserk at 1 alive, inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 1 0 0 0 0 items 1 flash 6 ready 1 pending 0
#|berserk at 100 alive, inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 1 0 0 0 0 items 1 flash 6 ready 1 pending 0
#|berserk at 150 alive, inventory health 150 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 1 0 0 0 0 items 1 flash 6 ready 1 pending 0
#|berserk over 40 alive, inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 1 0 0 0 0 items 1 flash 6 ready 1 pending 0
#|armour bonus at none alive, inventory health 100 armour 1 type 1 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 1 flash 6 ready 1 pending 255
#|armour bonus at blue 199 alive, inventory health 100 armour 200 type 2 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 1 flash 6 ready 1 pending 255
#|armour bonus at green 200 alive, inventory health 100 armour 200 type 1 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 1 flash 6 ready 1 pending 255
#|green armour at none alive, inventory health 100 armour 100 type 1 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 6 ready 1 pending 255
#|green armour at blue 99 alive, inventory health 100 armour 100 type 1 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 6 ready 1 pending 255
#|green armour at green 100 alive 1, inventory health 100 armour 100 type 1 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 ready 1 pending 255
#|green armour at blue 150 alive 1, inventory health 100 armour 150 type 2 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 ready 1 pending 255
#|blue armour at none alive, inventory health 100 armour 200 type 2 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 6 ready 1 pending 255
#|blue armour at green 199 alive, inventory health 100 armour 200 type 2 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 6 ready 1 pending 255
#|blue armour at green 200 alive 1, inventory health 100 armour 200 type 1 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 ready 1 pending 255
#|blue armour at blue 200 alive 1, inventory health 100 armour 200 type 2 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 ready 1 pending 255
#|health bonus halves alive, inventory health 101 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 1 flash 6 ready 1 pending 255
#|berserk tic 1 alive, inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 1 0 0 0 0 items 1 flash 6 ready 1 pending 0
#|berserk tic 2 alive, inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 2 0 0 0 0 items 1 flash 5 ready 1 pending 0
#|berserk tic 3 alive, inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 3 0 0 0 0 items 1 flash 4 ready 1 pending 0
#|clip alive, inventory health 100 armour 0 type 0 cards 0 ammo 60 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 6 ready 1 pending 255
#|shells alive, inventory health 100 armour 0 type 0 cards 0 ammo 50 4 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 6 ready 1 pending 255
#|cell alive, inventory health 100 armour 0 type 0 cards 0 ammo 50 0 20 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 6 ready 1 pending 255
#|rocket alive, inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 1 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 6 ready 1 pending 255
#|box of bullets alive, inventory health 100 armour 0 type 0 cards 0 ammo 100 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 6 ready 1 pending 255
#|box of shells alive, inventory health 100 armour 0 type 0 cards 0 ammo 50 20 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 6 ready 1 pending 255
#|cell pack alive, inventory health 100 armour 0 type 0 cards 0 ammo 50 0 100 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 6 ready 1 pending 255
#|box of rockets alive, inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 5 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 6 ready 1 pending 255
#|clip at cap alive 1, inventory health 100 armour 0 type 0 cards 0 ammo 200 50 300 50 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 ready 1 pending 255
#|box of bullets at cap alive 1, inventory health 100 armour 0 type 0 cards 0 ammo 200 50 300 50 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 ready 1 pending 255
#|shells at cap alive 1, inventory health 100 armour 0 type 0 cards 0 ammo 200 50 300 50 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 ready 1 pending 255
#|box of shells at cap alive 1, inventory health 100 armour 0 type 0 cards 0 ammo 200 50 300 50 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 ready 1 pending 255
#|cell at cap alive 1, inventory health 100 armour 0 type 0 cards 0 ammo 200 50 300 50 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 ready 1 pending 255
#|cell pack at cap alive 1, inventory health 100 armour 0 type 0 cards 0 ammo 200 50 300 50 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 ready 1 pending 255
#|rocket at cap alive 1, inventory health 100 armour 0 type 0 cards 0 ammo 200 50 300 50 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 ready 1 pending 255
#|box of rockets at cap alive 1, inventory health 100 armour 0 type 0 cards 0 ammo 200 50 300 50 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 ready 1 pending 255
#|box of bullets short alive, inventory health 100 armour 0 type 0 cards 0 ammo 200 49 299 49 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 6 ready 1 pending 255
#|box of shells short alive, inventory health 100 armour 0 type 0 cards 0 ammo 199 50 299 49 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 6 ready 1 pending 255
#|cell pack short alive, inventory health 100 armour 0 type 0 cards 0 ammo 199 49 300 49 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 6 ready 1 pending 255
#|box of rockets short alive, inventory health 100 armour 0 type 0 cards 0 ammo 199 49 299 50 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 6 ready 1 pending 255
#|backpack alive, inventory health 100 armour 0 type 0 cards 0 ammo 60 4 20 1 caps 400 100 600 100 backpack True weapons 3 powers 0 0 0 0 0 0 items 0 flash 6 ready 1 pending 255
#|backpack at caps alive, inventory health 100 armour 0 type 0 cards 0 ammo 210 54 320 51 caps 400 100 600 100 backpack True weapons 3 powers 0 0 0 0 0 0 items 0 flash 6 ready 1 pending 255
#|second backpack alive, inventory health 100 armour 0 type 0 cards 0 ammo 70 8 40 2 caps 400 100 600 100 backpack True weapons 3 powers 0 0 0 0 0 0 items 0 flash 6 ready 1 pending 255
#|second backpack at caps alive, inventory health 100 armour 0 type 0 cards 0 ammo 400 100 600 100 caps 400 100 600 100 backpack True weapons 3 powers 0 0 0 0 0 0 items 0 flash 6 ready 1 pending 255
#|shotgun alive, inventory health 100 armour 0 type 0 cards 0 ammo 50 8 0 0 caps 200 50 300 50 backpack False weapons 7 powers 0 0 0 0 0 0 items 0 flash 6 ready 1 pending 2
#|shotgun owned alive, inventory health 100 armour 0 type 0 cards 0 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 7 powers 0 0 0 0 0 0 items 0 flash 6 ready 1 pending 255
#|shotgun owned at cap alive 1, inventory health 100 armour 0 type 0 cards 0 ammo 50 50 0 0 caps 200 50 300 50 backpack False weapons 7 powers 0 0 0 0 0 0 items 0 flash 0 ready 1 pending 255
#|shotgun at cap alive, inventory health 100 armour 0 type 0 cards 0 ammo 50 50 0 0 caps 200 50 300 50 backpack False weapons 7 powers 0 0 0 0 0 0 items 0 flash 6 ready 1 pending 2
#|chaingun alive, inventory health 100 armour 0 type 0 cards 0 ammo 70 0 0 0 caps 200 50 300 50 backpack False weapons 11 powers 0 0 0 0 0 0 items 0 flash 6 ready 1 pending 3
#|chaingun owned at cap alive 1, inventory health 100 armour 0 type 0 cards 0 ammo 200 0 0 0 caps 200 50 300 50 backpack False weapons 11 powers 0 0 0 0 0 0 items 0 flash 0 ready 1 pending 255
#|rocket launcher alive, inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 2 caps 200 50 300 50 backpack False weapons 19 powers 0 0 0 0 0 0 items 0 flash 6 ready 1 pending 4
#|plasma rifle alive, inventory health 100 armour 0 type 0 cards 0 ammo 50 0 40 0 caps 200 50 300 50 backpack False weapons 35 powers 0 0 0 0 0 0 items 0 flash 6 ready 1 pending 5
#|chainsaw alive, inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 131 powers 0 0 0 0 0 0 items 0 flash 6 ready 1 pending 7
#|chainsaw owned alive 1, inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 131 powers 0 0 0 0 0 0 items 0 flash 0 ready 1 pending 255
#|clip to the pistol alive, inventory health 100 armour 0 type 0 cards 0 ammo 10 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 6 ready 0 pending 1
#|clip to the chaingun alive, inventory health 100 armour 0 type 0 cards 0 ammo 10 0 0 0 caps 200 50 300 50 backpack False weapons 11 powers 0 0 0 0 0 0 items 0 flash 6 ready 0 pending 3
#|shells to the shotgun alive, inventory health 100 armour 0 type 0 cards 0 ammo 50 4 0 0 caps 200 50 300 50 backpack False weapons 7 powers 0 0 0 0 0 0 items 0 flash 6 ready 1 pending 2
#|line 3 140
#|line 5 140
#|line 6 140
#|line 1 140
#|line 2 140
#|line 7 140
#|line 15 140
#|line 8 140
#|line 18 140
#|line 0 0
#|line 0 0
#|line 3 89
#|line 3 1
#|line 3 0
#|line 3 0
#|line 17 140
#|line 0 0
#|wall at 8 touches True crosses True
#|wall at 40 touches False crosses False
#|wall at 24 barrel crosses False tree crosses True
#|solid wall True two-sided False blocking True monster line to player False to thing True
#|within maxradius True
#|solid stays True
#|monsters block True
#|states exist True
#|spawn thing 1 type 2014 at 1048576 2097152 z 0 floor 0 ceiling 8388608 angle 0 sector 0 state 12 tics 5 momz 0 hurt 1000 4294967295 8 0 0 0 8388609 1048576 1 0 0 1310720
#|spawn thing 2 type 2018 at 1048576 6291456 z 0 floor 0 ceiling 8388608 angle 0 sector 0 state 6 tics 2 momz 0 hurt 1000 4294967295 8 0 0 0 1 1048576 2 0 0 1310720
#|spawn random 5
#|tic 4 thing 1 type 2014 at 1048576 2097152 z 0 floor 0 ceiling 8388608 angle 0 sector 0 state 12 tics 1 momz 0 hurt 1000 4294967295 8 0 0 0 8388609 1048576 1 0 0 1310720
#|tic 4 thing 2 type 2018 at 1048576 6291456 z 0 floor 0 ceiling 8388608 angle 0 sector 0 state 7 tics 5 momz 0 hurt 1000 4294967295 8 0 0 0 1 1048576 2 0 0 1310720
#|tic 5 thing 1 type 2014 at 1048576 2097152 z 0 floor 0 ceiling 8388608 angle 0 sector 0 state 13 tics 6 momz 0 hurt 1000 4294967295 8 0 0 0 8388609 1048576 1 0 0 1310720
#|tic 5 thing 2 type 2018 at 1048576 6291456 z 0 floor 0 ceiling 8388608 angle 0 sector 0 state 7 tics 4 momz 0 hurt 1000 4294967295 8 0 0 0 1 1048576 2 0 0 1310720
#|tic 11 thing 1 type 2014 at 1048576 2097152 z 0 floor 0 ceiling 8388608 angle 0 sector 0 state 14 tics 6 momz 0 hurt 1000 4294967295 8 0 0 0 8388609 1048576 1 0 0 1310720
#|tic 11 thing 2 type 2018 at 1048576 6291456 z 0 floor 0 ceiling 8388608 angle 0 sector 0 state 6 tics 4 momz 0 hurt 1000 4294967295 8 0 0 0 1 1048576 2 0 0 1310720
#|tic 17 thing 1 type 2014 at 1048576 2097152 z 0 floor 0 ceiling 8388608 angle 0 sector 0 state 15 tics 6 momz 0 hurt 1000 4294967295 8 0 0 0 8388609 1048576 1 0 0 1310720
#|tic 17 thing 2 type 2018 at 1048576 6291456 z 0 floor 0 ceiling 8388608 angle 0 sector 0 state 7 tics 5 momz 0 hurt 1000 4294967295 8 0 0 0 1 1048576 2 0 0 1310720
#|tic 23 thing 1 type 2014 at 1048576 2097152 z 0 floor 0 ceiling 8388608 angle 0 sector 0 state 16 tics 6 momz 0 hurt 1000 4294967295 8 0 0 0 8388609 1048576 1 0 0 1310720
#|tic 23 thing 2 type 2018 at 1048576 6291456 z 0 floor 0 ceiling 8388608 angle 0 sector 0 state 6 tics 5 momz 0 hurt 1000 4294967295 8 0 0 0 1 1048576 2 0 0 1310720
#|tic 29 thing 1 type 2014 at 1048576 2097152 z 0 floor 0 ceiling 8388608 angle 0 sector 0 state 17 tics 6 momz 0 hurt 1000 4294967295 8 0 0 0 8388609 1048576 1 0 0 1310720
#|tic 29 thing 2 type 2018 at 1048576 6291456 z 0 floor 0 ceiling 8388608 angle 0 sector 0 state 7 tics 6 momz 0 hurt 1000 4294967295 8 0 0 0 1 1048576 2 0 0 1310720
#|tic 35 thing 1 type 2014 at 1048576 2097152 z 0 floor 0 ceiling 8388608 angle 0 sector 0 state 12 tics 6 momz 0 hurt 1000 4294967295 8 0 0 0 8388609 1048576 1 0 0 1310720
#|tic 35 thing 2 type 2018 at 1048576 6291456 z 0 floor 0 ceiling 8388608 angle 0 sector 0 state 6 tics 6 momz 0 hurt 1000 4294967295 8 0 0 0 1 1048576 2 0 0 1310720
#|tic 35 random 5 clock 35
