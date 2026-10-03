# Doom's player_t inventory, as G_PlayerReborn starts it, and
# P_TouchSpecialThing's grants for the types Bendoom takes.
import Base
import ./vec.bend as V
import ./fixed.bend as F
import ./sound.bend as Sn
import ./message.bend as Msg

# Health and armour; key bits; ammo and caps; backpack and weapon bits;
# power timers; item, kill and secret counts; and pickup flash. The line
# packs message tics, message id, readyweapon and pendingweapon into
# four bytes. Pending 255 means wp_nochange. Packing keeps the native
# lane within its record-width budget (docs/bend.md).
type Inventory is Data:
  Inventory{health: U32, armour: U32, armourtype: U32, cards: U32, ammo: V.Vec, caps: V.Vec, backpack: Bool,
    weapons: U32, powers: V.Vec, items: U32, bonus: U32, line: U32, kills: U32, secrets: U32}

# 100 health, the fist and the pistol, fifty bullets, maxammo's caps.
def Inventory.start() -> Inventory:
  Inventory{100, 0, 0, 0, V.Vec.of_list([50, 0, 0, 0], 4), V.Vec.of_list([200, 50, 300, 50], 4), False{}, 3,
    V.Vec.of_list([0, 0, 0, 0, 0, 0], 6), 0, 0, 4278255616, 0, 0}

# What crosses into the next level: G_PlayerFinishLevel takes the keys,
# the powers and the pickup flash, P_SetupLevel zeroes the counts, and
# P_SpawnPlayer clears the message and brings the ready weapon up again.
# Health, armour, ammo, caps, backpack and weapons are kept.
def Inventory.finished(inv: Inventory) -> Inventory:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus, line, kills,
    secrets} = inv
  Inventory{health, armour, armourtype, 0, ammo, caps, backpack, weapons, V.Vec.of_list([0, 0, 0, 0, 0, 0], 6), 0,
    0, ((line .&. 16711680 : U32) .|. 4278190080 : U32), 0, 0}

def Inventory.items(inv: Inventory) -> U32:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus, line,
    kills, secrets} = inv
  items

def Inventory.kills(inv: Inventory) -> U32:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus, line,
    kills, secrets} = inv
  kills

def Inventory.secrets(inv: Inventory) -> U32:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus, line,
    kills, secrets} = inv
  secrets

def Inventory.killed(inv: Inventory) -> Inventory:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus, line,
    +kills, secrets} = inv
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus, line,
    (kills + 1 : U32), secrets}

def Inventory.secret(inv: Inventory) -> Inventory:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus, line,
    kills, +secrets} = inv
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus, line,
    kills, (secrets + 1 : U32)}

# Every count as text, for the tests and the tools. The message line is
# printed where a test is about it.
def Inventory.show(inv: Inventory) -> String:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus, +line, kills, secrets} = inv
  "inventory health " ++ U32.show(health) ++ " armour " ++ U32.show(armour) ++ " type " ++ U32.show(armourtype)
    ++ " cards " ++ U32.show(cards) ++ " ammo" ++ V.Vec.show(ammo, 4n, 0) ++ " caps" ++ V.Vec.show(caps, 4n, 0)
    ++ " backpack " ++ Bool.show(backpack) ++ " weapons " ++ U32.show(weapons) ++ " powers"
    ++ V.Vec.show(powers, 6n, 0) ++ " items " ++ U32.show(items) ++ " flash " ++ U32.show(bonus)

def Inventory.health(inv: Inventory) -> U32:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus, line, kills, secrets} = inv
  health

# Doom's PST_DEAD: the health P_DamageMobj holds at 0 has run out.
# Health is compared as a signed quantity, as vanilla's is.
def Inventory.dead(+inv: Inventory) -> Bool:
  F.Fixed.le(Inventory.health(inv), 0)

def Inventory.armour(inv: Inventory) -> U32:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus, line, kills, secrets} = inv
  armour

def Inventory.armourtype(inv: Inventory) -> U32:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus, line, kills, secrets} = inv
  armourtype

def Inventory.cards(inv: Inventory) -> U32:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus, line, kills, secrets} = inv
  cards

def Inventory.bonus(inv: Inventory) -> U32:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus, line, kills, secrets} = inv
  bonus

def Inventory.weapons(inv: Inventory) -> U32:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus, line, kills, secrets} = inv
  weapons

def Inventory.ready(inv: Inventory) -> U32:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus, line, kills, secrets} = inv
  ((line >> 16n : U32) .&. 255 : U32)

def Inventory.pending(inv: Inventory) -> U32:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus, line, kills, secrets} = inv
  (line >> 24n : U32)

def Inventory.weaponstate(+ready: U32, +pending: U32, inv: Inventory) -> Inventory:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus, +line, kills, secrets} = inv
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus,
    ((line .&. 65535 : U32) .|. (ready << 16n : U32) .|. (pending << 24n : U32) : U32), kills, secrets}

def Inventory.weaponbit(+weapon: U32) -> U32:
  match weapon:
    case 0: 1
    case 1: 2
    case 2: 4
    case 3: 8
    case 4: 16
    case 5: 32
    case 6: 64
    case 7: 128
    case _: 0

def Inventory.owns(+weapon: U32, inv: Inventory) -> Bool:
  Bool.not(U32.is_zero((Inventory.weapons(inv) .&. Inventory.weaponbit(weapon) : U32)))

def Inventory.want(+weapon: U32, +inv: Inventory) -> Inventory:
  Inventory.weaponstate(Inventory.ready(inv), weapon, inv)

# The rounds of an ammo type and the cap on them, Doom's ammo[t] and
# maxammo[t].
def Inventory.rounds(+t: U32, inv: Inventory) -> U32:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus, line, kills, secrets} = inv
  V.Vec.get(ammo, t)

def Inventory.cap(+t: U32, inv: Inventory) -> U32:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus, line, kills, secrets} = inv
  V.Vec.get(caps, t)

# The armour types.
def Inventory.green_armour() -> U32:
  1

def Inventory.blue_armour() -> U32:
  2

# The bits among the cards of card_t's it_bluecard, it_yellowcard and
# it_redcard. Each skull's is its card's three bits up.
def Inventory.bluecard() -> U32:
  1

def Inventory.yellowcard() -> U32:
  2

def Inventory.redcard() -> U32:
  4

# ammotype_t's indexes.
def Inventory.am_clip() -> U32:
  0

def Inventory.am_shell() -> U32:
  1

def Inventory.am_cell() -> U32:
  2

def Inventory.am_misl() -> U32:
  3

# The world weapons' bits among the weapons owned.
def Inventory.shotgun() -> U32:
  4

def Inventory.chaingun() -> U32:
  8

def Inventory.launcher() -> U32:
  16

def Inventory.plasma() -> U32:
  32

def Inventory.chainsaw() -> U32:
  128

# powertype_t's indexes of the powers the shareware maps give.
def Inventory.pw_strength() -> U32:
  1

def Inventory.pw_invisibility() -> U32:
  2

def Inventory.pw_ironfeet() -> U32:
  3

def Inventory.pw_allmap() -> U32:
  4

def Inventory.pw_infrared() -> U32:
  5

# Doom's INVISTICS, INFRATICS and IRONTICS: a timed power's tics.
def Inventory.invistics() -> U32:
  2100

def Inventory.infratics() -> U32:
  4200

def Inventory.irontics() -> U32:
  2100

# A power's counter: the tics a timed power has left, the computer map's
# 1 once it is had, and the berserk power's count up from 1 while on.
def Inventory.power.of(+power: U32, inv: Inventory) -> U32:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus, line, kills, secrets} = inv
  V.Vec.get(powers, power)

def Inventory.strength(+inv: Inventory) -> U32:
  Inventory.power.of(Inventory.pw_strength(), inv)

# Whether a card or its skull is owned, the key to its colour's doors.
def Inventory.key(+card: U32, inv: Inventory) -> Bool:
  Bool.not(U32.is_zero((Inventory.cards(inv) .&. (card .|. (card << 3n) : U32) : U32)))

# P_DamageMobj's saved: green armour absorbs a third of a blow and blue
# a half, and neither more than the points worn. No armour absorbs
# nothing.
def Inventory.saved(worn: Bool, +armourtype: U32, +armour: U32, +damage: U32) -> U32:
  match worn:
    case False{}:
      0
    case True{}:
      U32.min(armour, Bool.pick(U32, U32.is_eq(armourtype, Inventory.green_armour()), (damage / 3 : U32),
        (damage / 2 : U32)))

def Inventory.hurt.fin(+saved: U32, inv: Inventory, +damage: U32) -> Inventory & U32:
  Inventory{+health, +armour, +armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus, line, kills, secrets} = inv
  +left = (damage - saved : U32)
  (Inventory{F.Fixed.max((health - left : U32), 0), (armour - saved : U32),
    Bool.pick(U32, U32.is_eq(armour, saved), 0, armourtype), cards, ammo, caps, backpack, weapons, powers, items,
    bonus, line, kills, secrets}, left)

# P_DamageMobj's blow on the inventory: the armour absorbs its share and
# loses its type where the share used it up, and the health takes the
# rest and stops at 0, as player->health does. The inventory after, and
# the damage that reached the player, which the damage count takes.
def Inventory.hurt(+inv: Inventory, +damage: U32) -> Inventory & U32:
  Inventory.hurt.fin(Inventory.saved(Bool.not(U32.is_zero(Inventory.armourtype(inv))), Inventory.armourtype(inv),
    Inventory.armour(inv), damage), inv, damage)

# 1 for a counter that runs, 0 for one at rest.
def Inventory.on(+n: U32) -> U32:
  Bool.to_u32(Bool.not(U32.is_zero(n)))

def Inventory.line(inv: Inventory) -> U32:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus, line, kills, secrets} = inv
  line

# The message the heads-up line shows, and the tics it has left there.
def Inventory.message(+inv: Inventory) -> U32:
  ((Inventory.line(inv) >> 8n : U32) .&. 255 : U32)

def Inventory.msgtics(+inv: Inventory) -> U32:
  (Inventory.line(inv) .&. 255 : U32)

# Doom's player->message = s, where p_inter.c and p_doors.c set it, with
# HU_Ticker's own install folded in: the message takes the line at once
# and for HU_MSGTIMEOUT tics, which the counters count down from the
# next tic on, since they have already run when a pickup or a use
# happens. A newer message replaces an older, as vanilla's later write
# does, and no message leaves the line as it was, since vanilla's code
# sets one or returns.
def Inventory.saying(+msg: U32, inv: Inventory) -> Inventory:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus, +line, kills, secrets} = inv
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus,
    Bool.pick(U32, U32.is_zero(msg), line,
      ((line .&. 4294901760 : U32) .|. (msg << 8n : U32) .|. Msg.Message.timeout() : U32)), kills, secrets}

# Doom's P_GiveCard, with the message p_inter.c sets on the same test
# just before it: a card not owned yet sets the flash to 6 and names
# itself, and one already owned leaves the line as it was.
def Inventory.card(+bit: U32, +msg: U32, inv: Inventory) -> Inventory:
  Inventory{health, armour, armourtype, +cards, ammo, caps, backpack, weapons, powers, items, bonus, line, kills, secrets} = inv
  +fresh = U32.is_zero((cards .&. bit : U32))
  Inventory.saying(Bool.pick(U32, fresh, msg, Msg.Message.none()),
    Inventory{health, armour, armourtype, (cards .|. bit : U32), ammo, caps, backpack, weapons, powers, items,
      Bool.pick(U32, fresh, 6, bonus), line, kills, secrets})

# A grant's answer: the inventory saying its message when the thing is
# taken, none when it stays, as each of p_inter.c's cases returns before
# it sets one.
def Inventory.taken(taken: Bool, msg: U32, inv: Inventory) -> Maybe<&2, Inventory>:
  match taken:
    case True{}:
      Some{Inventory.saying(msg, inv)}
    case False{}:
      None{}

# A count raised by an amount up to a cap, and never lowered by it: a
# count already at or past the cap stays.
def Inventory.upto(+v: U32, +amount: U32, +cap: U32) -> U32:
  U32.max(v, U32.min((v + amount : U32), cap))

# Health healed by an amount up to a cap.
def Inventory.heal(+amount: U32, +cap: U32, inv: Inventory) -> Inventory:
  Inventory{+health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus, line, kills, secrets} = inv
  Inventory{Inventory.upto(health, amount, cap), armour, armourtype, cards, ammo, caps, backpack, weapons, powers,
    items, bonus, line, kills, secrets}

# Doom's P_GiveBody: under 100 health, heal by an amount up to 100; at
# 100 or more the thing stays.
def Inventory.body(+amount: U32, msg: U32, +inv: Inventory) -> Maybe<&2, Inventory>:
  Inventory.taken(U32.is_lt(Inventory.health(inv), 100), msg, Inventory.heal(amount, 100, inv))

# P_GivePower's counter set: a power on for so many tics, or at 1 for
# the berserk power and the computer map.
def Inventory.power(+power: U32, +tics: U32, inv: Inventory) -> Inventory:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus, line, kills, secrets} = inv
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, V.Vec.set(powers, power, tics), items,
    bonus, line, kills, secrets}

# A timed power's pickup, always taken: P_GivePower sets its counter
# whether it ran or not.
def Inventory.timed(+power: U32, +tics: U32, +msg: U32, inv: Inventory) -> Maybe<&2, Inventory>:
  Some{Inventory.saying(msg, Inventory.power(power, tics, inv))}

# The armour bonus: a point more up to 200, and green armour's type if
# none is worn.
def Inventory.helmet(inv: Inventory) -> Inventory:
  Inventory{health, +armour, +armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus, line, kills, secrets} = inv
  Inventory{health, Inventory.upto(armour, 1, 200), U32.max(armourtype, Inventory.green_armour()), cards, ammo,
    caps, backpack, weapons, powers, items, bonus, line, kills, secrets}

# Doom's P_GiveArmor: a type's 100 points each, and the type, over fewer
# points of any type; with as many or more the thing stays.
def Inventory.suit(+kind: U32, msg: U32, inv: Inventory) -> Maybe<&2, Inventory>:
  Inventory{health, +armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus, line, kills, secrets} = inv
  Inventory.taken(U32.is_lt(armour, (kind * 100 : U32)), msg,
    Inventory{health, (kind * 100 : U32), kind, cards, ammo, caps, backpack, weapons, powers, items, bonus, line, kills, secrets})

# Doom's clipammo: the rounds in a clip of each ammo type.
def Inventory.clip(+t: U32) -> U32:
  V.Vec.get(V.Vec.of_list([10, 4, 20, 1], 4), t)

# Doom's DecreaseAmmo: a shot spends rounds of its weapon's type. No
# weapon Bendoom carries has an ammo type past the four, so vanilla's
# overflow into the caps has no caller.
def Inventory.spend(+t: U32, +amount: U32, inv: Inventory) -> Inventory:
  Inventory{health, armour, armourtype, cards, +ammo, caps, backpack, weapons, powers, items, bonus, line, kills, secrets} = inv
  Inventory{health, armour, armourtype, cards, V.Vec.set(ammo, t, (V.Vec.get(ammo, t) - amount : U32)), caps,
    backpack, weapons, powers, items, bonus, line, kills, secrets}

# Whether an ammo type is short of its cap: P_GiveAmmo gives nothing
# otherwise.
def Inventory.room(+t: U32, inv: Inventory) -> Bool:
  Inventory{health, armour, armourtype, cards, +ammo, +caps, backpack, weapons, powers, items, bonus, line, kills, secrets} = inv
  Bool.not(U32.is_eq(V.Vec.get(ammo, t), V.Vec.get(caps, t)))

# P_GiveAmmo's switch once a type that was empty is given: bullets
# bring the fist up to the chaingun if owned, else the pistol, and
# shells bring the fist or the pistol up to the shotgun if owned.
def Inventory.ammo.switch(empty: Bool, t: U32, +inv: Inventory) -> Inventory:
  match empty t:
    case False{} _:
      inv
    case True{} 0:
      Bool.pick(Inventory, U32.is_eq(Inventory.ready(inv), 0),
        Inventory.want(Bool.pick(U32, Inventory.owns(3, inv), 3, 1), inv), inv)
    case True{} 1:
      Bool.pick(Inventory, Bool.and(Bool.or(U32.is_eq(Inventory.ready(inv), 0), U32.is_eq(Inventory.ready(inv), 1)),
        Inventory.owns(2, inv)), Inventory.want(2, inv), inv)
    case True{} _:
      inv

# P_GiveAmmo's rounds: clips of an ammo type, up to its cap. Only the
# easiest and hardest skills double them, never Hurt Me Plenty.
def Inventory.give(+t: U32, +clips: U32, inv: Inventory) -> Inventory:
  Inventory{health, armour, armourtype, cards, +ammo, +caps, backpack, weapons, powers, items, bonus, line, kills, secrets} = inv
  +old = V.Vec.get(ammo, t)
  +given = {Inventory{health, armour, armourtype, cards,
    V.Vec.set(ammo, t, Inventory.upto(old,
      Bool.pick(U32, U32.is_zero(clips), (Inventory.clip(t) / 2 : U32), (clips * Inventory.clip(t) : U32)),
      V.Vec.get(caps, t))),
    caps, backpack, weapons, powers, items, bonus, line, kills, secrets} : Inventory}
  Inventory.ammo.switch(U32.is_zero(old), t, given)

# An ammo pickup: P_GiveAmmo, refused at the cap.
def Inventory.ammo(+t: U32, clips: U32, msg: U32, +inv: Inventory) -> Maybe<&2, Inventory>:
  Inventory.taken(Inventory.room(t, inv), msg, Inventory.give(t, clips, inv))

# P_GiveWeapon for a weapon found on the map, from the inventory its
# ammo left: it is taken when ammo was given or the weapon was not
# owned before. A newly owned weapon becomes pending.
def Inventory.weapon(+bit: U32, +weapon: U32, gave: Bool, msg: U32, inv: Inventory) -> Maybe<&2, Inventory>:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, +weapons, powers, items, bonus, line, kills, secrets} = inv
  +new = U32.is_zero((weapons .&. bit : U32))
  +got = {Inventory{health, armour, armourtype, cards, ammo, caps, backpack, (weapons .|. bit : U32), powers, items, bonus, line, kills, secrets} : Inventory}
  Inventory.taken(Bool.or(gave, new), msg, Bool.pick(Inventory, new, Inventory.want(weapon, got), got))

# A placed weapon carries two clips; a dropped one carries one.
def Inventory.armed(bit: U32, weapon: U32, +t: U32, dropped: Bool, msg: U32, +inv: Inventory) -> Maybe<&2, Inventory>:
  Inventory.weapon(bit, weapon, Inventory.room(t, inv), msg,
    Inventory.give(t, Bool.pick(U32, dropped, 1, 2), inv))

# The caps once a backpack is taken: the first doubles each.
def Inventory.bag(had: Bool, caps: V.Vec) -> V.Vec:
  match had:
    case True{}:
      caps
    case False{}:
      V.Vec.doubled(caps)

# P_TouchSpecialThing's backpack, always taken: the caps as the bag
# leaves them, then a clip of each ammo type in turn.
def Inventory.backpack(inv: Inventory) -> Inventory:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus, line, kills, secrets} = inv
  Inventory.give(Inventory.am_misl(), 1, Inventory.give(Inventory.am_cell(), 1, Inventory.give(Inventory.am_shell(),
    1, Inventory.give(Inventory.am_clip(), 1, Inventory{health, armour, armourtype, cards, ammo,
      Inventory.bag(backpack, caps), True{}, weapons, powers, items, bonus, line, kills, secrets}))))

# P_TouchSpecialThing's switch for the types Bendoom spawns: the
# inventory after the grant, saying the message that case sets, and none
# when the thing stays. The cards, the two bonuses, the soul sphere, the
# backpack and the timed powers are always taken, and so is the berserk
# pack, P_GivePower's strength with P_GiveBody's 100 whether it heals or
# not; the computer map is taken once; the stimpack heals 10, the medikit
# 25; a box holds five clips; a weapon brings two clips of its ammo, and
# the chainsaw has none. A type whose message is none says nothing.
def Inventory.grant(kind: U32, dropped: Bool, +inv: Inventory) -> Maybe<&2, Inventory>:
  match kind:
    case 5:
      Some{Inventory.card(Inventory.bluecard(), Msg.Message.gotbluecard(), inv)}
    case 6:
      Some{Inventory.card(Inventory.yellowcard(), Msg.Message.gotyelwcard(), inv)}
    case 13:
      Some{Inventory.card(Inventory.redcard(), Msg.Message.gotredcard(), inv)}
    case 8:
      Some{Inventory.backpack(inv)}
    case 17:
      Inventory.ammo(Inventory.am_cell(), 5, Msg.Message.none(), inv)
    case 2001:
      Inventory.armed(Inventory.shotgun(), 2, Inventory.am_shell(), dropped, Msg.Message.gotshotgun(), inv)
    case 2002:
      Inventory.armed(Inventory.chaingun(), 3, Inventory.am_clip(), dropped, Msg.Message.gotchaingun(), inv)
    case 2003:
      Inventory.armed(Inventory.launcher(), 4, Inventory.am_misl(), dropped, Msg.Message.none(), inv)
    case 2004:
      Inventory.armed(Inventory.plasma(), 5, Inventory.am_cell(), dropped, Msg.Message.none(), inv)
    case 2005:
      Inventory.weapon(Inventory.chainsaw(), 7, False{}, Msg.Message.gotchainsaw(), inv)
    case 2007:
      Inventory.ammo(Inventory.am_clip(), Bool.pick(U32, dropped, 0, 1), Msg.Message.gotclip(), inv)
    case 2008:
      Inventory.ammo(Inventory.am_shell(), 1, Msg.Message.gotshells(), inv)
    case 2010:
      Inventory.ammo(Inventory.am_misl(), 1, Msg.Message.gotrocket(), inv)
    case 2011:
      Inventory.body(10, Msg.Message.gotstim(), inv)
    case 2012:
      Inventory.body(25, Msg.Message.gotmedikit(), inv)
    case 2013:
      Some{Inventory.heal(100, 200, inv)}
    case 2014:
      Some{Inventory.saying(Msg.Message.goththbonus(), Inventory.heal(1, 200, inv))}
    case 2015:
      Some{Inventory.saying(Msg.Message.gotarmbonus(), Inventory.helmet(inv))}
    case 2018:
      Inventory.suit(Inventory.green_armour(), Msg.Message.gotarmor(), inv)
    case 2019:
      Inventory.suit(Inventory.blue_armour(), Msg.Message.gotmega(), inv)
    case 2023:
      Some{Inventory.want(0, Inventory.saying(Msg.Message.gotberserk(),
        Inventory.power(Inventory.pw_strength(), 1, Inventory.heal(100, 100, inv))))}
    case 2024:
      Inventory.timed(Inventory.pw_invisibility(), Inventory.invistics(), Msg.Message.gotinvis(), inv)
    case 2025:
      Inventory.timed(Inventory.pw_ironfeet(), Inventory.irontics(), Msg.Message.gotsuit(), inv)
    case 2026:
      Inventory.taken(U32.is_zero(Inventory.power.of(Inventory.pw_allmap(), inv)), Msg.Message.gotmap(),
        Inventory.power(Inventory.pw_allmap(), 1, inv))
    case 2045:
      Inventory.timed(Inventory.pw_infrared(), Inventory.infratics(), Msg.Message.gotvisor(), inv)
    case 2046:
      Inventory.ammo(Inventory.am_misl(), 5, Msg.Message.gotrockbox(), inv)
    case 2047:
      Inventory.ammo(Inventory.am_cell(), 1, Msg.Message.gotcell(), inv)
    case 2048:
      Inventory.ammo(Inventory.am_clip(), 5, Msg.Message.gotclipbox(), inv)
    case 2049:
      Inventory.ammo(Inventory.am_shell(), 5, Msg.Message.gotshellbox(), inv)
    case _:
      None{}

# P_TouchSpecialThing's sound for a type taken: the weapons' (2001 to
# 2005), the power's for the soul sphere, the visor and the powers from
# 2022 to 2026, and the item's for the rest.
def Inventory.sound(+kind: U32) -> U32:
  Bool.pick(U32, Bool.and(U32.is_ge(kind, 2001), U32.is_le(kind, 2005)), Sn.Sound.wpnup(),
    Bool.pick(U32, Bool.and(U32.is_ge(kind, 2022), U32.is_le(kind, 2026)) || U32.is_eq(kind, 2013)
      || U32.is_eq(kind, 2045), Sn.Sound.getpow(), Sn.Sound.itemup()))

# The end of P_TouchSpecialThing for a thing taken: the tally counts an
# item flagged for it, and the flash grows by 6.
def Inventory.took(counted: Bool, inv: Inventory) -> Inventory:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus, line, kills, secrets} = inv
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers,
    (items + Bool.to_u32(counted) : U32), (bonus + 6 : U32), line, kills, secrets}

# A power's counter one tic on, by one more for one that counts up and
# one less for one that counts down, and left where it is at zero.
def Inventory.power.tic(+powers: V.Vec, +power: U32, +step: U32) -> V.Vec:
  +n = V.Vec.get(powers, power)
  V.Vec.set(powers, power, (n + step * Inventory.on(n) : U32))

# P_PlayerThink's counters, with HU_Ticker's: strength counts up once
# on, the timed powers run down, the flash fades by one a tic, and so
# does the heads-up line's counter, which goes out at zero.
def Inventory.tic(inv: Inventory) -> Inventory:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, +bonus, +line, kills, secrets} = inv
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons,
    Inventory.power.tic(Inventory.power.tic(Inventory.power.tic(Inventory.power.tic(powers, Inventory.pw_strength(), 1),
      Inventory.pw_invisibility(), 4294967295), Inventory.pw_infrared(), 4294967295), Inventory.pw_ironfeet(),
      4294967295), items,
    (bonus - Inventory.on(bonus) : U32), (line - Inventory.on((line .&. 255 : U32)) : U32), kills, secrets}
