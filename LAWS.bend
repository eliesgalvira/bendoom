# The laws. The human states them; PROOF.bend must prove them.
import Base
import ./tests/fixtures/closed.bend as Fx
import ./src/bytes.bend as B
import ./src/wad.bend as W
import ./src/vec.bend as V
import ./src/level.bend as L
import ./src/keys.bend as K
import ./src/sim.bend as S
import ./src/special.bend as Sp
import ./src/tic.bend as Tic
import ./src/things.bend as H
import ./src/inventory.bend as I
import ./src/sound.bend as Sn
import ./src/clip.bend as C
import ./src/draw.bend as D
import ./src/midi.bend as Mi
import ./src/player.bend as Pl
import ./src/song.bend as Sg
import ./src/sfx.bend as X
import ./src/channel.bend as Ch

# Bytes and the WAD
# -----------------

# LAW: a NUL ends a padded name: whatever follows it is dropped.
law text_nul_ends:
  for rest: List<&2, Char>
  {B.Bytes.text.cons(0, rest) == [] : List<&2, Char>}

# LAW: any other byte is kept, as its char, before what follows.
law text_byte_kept:
  for rest: List<&2, Char>
  {B.Bytes.text.cons(65, rest) == Char.from_u32(65) <> rest : List<&2, Char>}

# LAW: the first lump called name is at 0 when it heads the list.
law index_head:
  for +name: String
  for pos: U32
  for size: U32
  for rest: List<&2, W.Wad.Lump>
  {W.Wad.index(name, W.Lump{pos, size, name} <> rest) == Some{0n} : Maybe<Nat>}

# Keys
# ----

# LAW: the last press of a key wins: pressing or releasing a key twice
# leaves the keys as the second press alone would, whatever the key.
law last_press:
  for +code: U32
  for d1: Bool
  for +d2: Bool
  for +keys: K.Keys
  {K.Keys.press(code, d2, K.Keys.press(code, d1, keys))
    == K.Keys.press(code, d2, keys) : K.Keys}

# LAW: the arrows and WASD fold to the same keys: up and W, down and S.
law arrows_wasd:
  for +down: Bool
  for +keys: K.Keys
  {(K.Keys.press(63232, down, keys), K.Keys.press(63233, down, keys))
    == (K.Keys.press(119, down, keys), K.Keys.press(115, down, keys)) : K.Keys & K.Keys}

# LAW: the lowest held number key wins, whatever the higher ones do, as
# G_BuildTiccmd's loop breaks at the first: BT_CHANGE, 4, with the key's
# number less one at BT_WEAPONSHIFT, 3.
law lowest_number_wins:
  for two: Bool
  for three: Bool
  {(K.Keys.change(True{}, two, three), K.Keys.change(False{}, True{}, three),
    K.Keys.change(False{}, False{}, True{}), K.Keys.change(False{}, False{}, False{}))
    == (4, 12, 20, 0) : U32 & U32 & U32 & U32}

# The sim
# -------

# LAW: one tic of the idle command from rest leaves the player where it
# was, on any level, at any position.
law tic_rest:
  for +level: L.Level
  for +x: U32
  for +y: U32
  {(S.Player.x(S.State.player(Tic.Sim.tic(K.Cmd.idle(),
      Fx.Closed.state(S.Player{x, y, 0, 0, 0, 0, 0, 0, 8388608, 2686976, 0, 2686976, [], I.Inventory.start(), Fx.Closed.unarmed(), S.Sim.Hurt.start()}, level, 0)))),
    S.Player.y(S.State.player(Tic.Sim.tic(K.Cmd.idle(),
      Fx.Closed.state(S.Player{x, y, 0, 0, 0, 0, 0, 0, 8388608, 2686976, 0, 2686976, [], I.Inventory.start(), Fx.Closed.unarmed(), S.Sim.Hurt.start()}, level, 0)))))
    == (x, y) : U32 & U32}

# LAW: a tic counts on the clock, and an ended level's tic changes
# nothing, whatever the command.
law tic_counts:
  for +cmd: K.Cmd
  for +p: S.Player
  for +level: L.Level
  for +clock: U32
  {(S.State.clock(Tic.Sim.tic(cmd, Fx.Closed.state(p, level, clock))),
    Tic.Sim.tic(cmd, S.State{p, level, Fx.Closed.none(), V.Leaf{0}, S.Thinkers{[], []}, 0, clock, True{}, False{}, [], S.Sim.Face.start(0), False{}, V.Leaf{0}}))
    == ((clock + 1 : U32),
      S.State{p, level, Fx.Closed.none(), V.Leaf{0}, S.Thinkers{[], []}, 0, clock, True{}, False{}, [], S.Sim.Face.start(0), False{}, V.Leaf{0}})
    : U32 & S.State}

# LAW: standing still on the floor of Level.room, one sector with no
# lines, the floor at 0 and the ceiling at 128 map units, puts the eye
# VIEWHEIGHT, 41, above it, at any position, whatever the eye was.
law eye_rest:
  for x: U32
  for y: U32
  {S.Player.viewz(Fx.Closed.room([K.Cmd.idle()], S.Player{x, y, 0, 0, 0, 0, 0, 0, 8388608, 2686976, 0, 0, [], I.Inventory.start(), Fx.Closed.unarmed(), S.Sim.Hurt.start()}, 0))
    == 2686976 : U32}

# LAW: use held across two tics fires on the first alone: after a live
# tic whose command holds use, no command is a press, whatever the
# state was.
law use_fires_once:
  for forward: U32
  for side: U32
  for turn: U32
  for buttons: U32
  for +next: K.Cmd
  for player: S.Player
  for level: L.Level
  for things: H.Things
  for sidetex: V.Vec
  for thinkers: S.Thinkers
  for rnd: U32
  for clock: U32
  for usedown: Bool
  for sounds: List<&2, Sn.Sound.Event>
  for mrnd: V.Vec
  for reborn: Bool
  for secrets: V.Vec
  for held: {True{} == K.Cmd.use(K.Cmd{forward, side, turn, buttons}) : Bool}
  {Tic.Sim.pressed(next, S.State.usedown(Tic.Sim.tic(K.Cmd{forward, side, turn, buttons},
    S.State{player, level, things, sidetex, thinkers, rnd, clock, False{}, usedown, sounds, mrnd, reborn, secrets}))) == False{} : Bool}

# LAW: once means once: a line fired for good has no special afterwards,
# whatever the state and the line.
law once_clears:
  for +line: U32
  for s: S.State
  {L.Level.special(S.State.level(Sp.Sim.once(line, s)), line) == 0 : U32}

# The door level of tests/fixtures/closed.bend with an exit switch: line
# 0's special is 11, the middle texture of its front side is numbered 1,
# and textures 1 and 2 are each other's partner.
def Exit.level() -> L.Level:
  L.Level.textured(L.Level.special.put(Fx.Closed.doors(), 0, 11), V.Vec.of_list([0, 0, 1], 3),
    V.Vec.of_list([0, 2, 1], 3))

# The west room's player after two idle tics and then a tic of use.
def Exit.used() -> S.State:
  Tic.Sim.replay([K.Cmd.idle(), K.Cmd.idle(), K.Cmd{0, 0, 0, 2}], S.State.populated([], 128,
    S.State{Fx.Closed.player(2097152, 4194304, 0, 8388608), Exit.level(), Fx.Closed.none(), L.Level.sidetex(Exit.level()),
      S.Thinkers{[], []}, 0, 0, False{}, False{}, [], S.Sim.Face.start(0), False{}, V.Leaf{0}}))

# exit_ends's claim on a state, its parameter, so the checker computes
# the state once.
def Exit.ended(+cmd: K.Cmd, +s: S.State) -> Type:
  {(S.State.ended(s), S.State.clock(s), L.Level.special(S.State.level(s), 0), V.Vec.get(S.State.sidetex(s), 2),
    Tic.Sim.tic(cmd, s))
    == (True{}, 3, 0, 2, s) : Bool & U32 & U32 & U32 & S.State}

# LAW: the exit switch, vanilla's special 11: P_ChangeSwitchTexture, then
# G_ExitLevel, and the tic runs on. Used on tic 3, the level has ended
# with the clock at 3, the line's special is gone and its side shows the
# switch's partner; a tic of any command after that changes nothing.
law exit_ends:
  for +cmd: K.Cmd
  Exit.ended(cmd, Exit.used())

# LAW: replaying two scripts in turn is replaying their concatenation,
# for all scripts and states.
law replay_append:
  for a: List<&2, K.Cmd>
  for b: List<&2, K.Cmd>
  for s: S.State
  {Tic.Sim.replay(List.append(&2, K.Cmd, a, b), s) == Tic.Sim.replay(b, Tic.Sim.replay(a, s)) : S.State}

# LAW: free is pinned to the geometry: when a position is free, every
# line listed in the blockmap cells its box touches satisfies the
# distance condition, whichever position in the list it holds.
law free_pins_lines:
  for +level: L.Level
  for +x: U32
  for +y: U32
  for k: Nat
  for i: U32
  for listed: {Some{i} == List.get(&2, U32, S.Sim.lines(level, (x - S.Sim.radius() : U32),
    (y - S.Sim.radius() : U32), (x + S.Sim.radius() : U32), (y + S.Sim.radius() : U32)), k)
    : Maybe<&2, U32>}
  for free: {True{} == S.Sim.free(level, x, y) : Bool}
  {True{} == S.Sim.line_ok(level, x, y, S.Sim.radius(), 1, i) : Bool}

# LAW: a tic leaves the geometry as it was: the lines, sides, vertices,
# nodes and blockmap that free reads are the same trees after it, for
# all commands and states. The things' links are no part of it: they are
# the population's, and a tic that moves, spawns or removes a mobj
# changes them.
law tic_keeps_geometry:
  for +cmd: K.Cmd
  for +s: S.State
  {L.Level.geo(S.State.level(Tic.Sim.tic(cmd, s))) == L.Level.geo(S.State.level(s)) : L.Level.Geo}

# A state whose player passes its level's line check: no solid line
# crosses its box.
def Free(+s: S.State) -> Type:
  {True{} == S.Sim.free(S.State.level(s), S.Player.x(S.State.player(s)), S.Player.y(S.State.player(s)))
    : Bool}

# LAW: one tic from a free state answers a free state, for all commands
# and states.
law tic_keeps_free:
  for +cmd: K.Cmd
  for +s: S.State
  for free: Free(s)
  Free(Tic.Sim.tic(cmd, s))

# LAW: the wall law: replaying any script from a free state, the start
# included, leaves the player free.
law replay_keeps_free:
  for script: List<&2, K.Cmd>
  for +s: S.State
  for free: Free(s)
  Free(Tic.Sim.replay(script, s))

# LAW: the freedom law, for every mobj: a place passes P_CheckPosition
# only when no mobj near stops the box, whatever is moved, among any
# things, with any player, against any lines (clear_pins_things reads
# that on each mobj near). Every move is tried through this check, as
# the things stand when it is tried: links change as mobjs move, spawn
# and leave, so no law can speak of them a tic later.
law check_is_clear:
  for +level: L.Level
  for +things: H.Things
  for +p: S.Player
  for +m: S.Sim.Body
  for +mask: U32
  for passed: {True{} == S.Sim.Fit.ok(S.Sim.check(level, things, p, m, mask)) : Bool}
  {None{} == S.Sim.blocked(level, things, p, m) : Maybe<&2, U32>}

# LAW: the player's move is taken only where its mobj's box passes the
# check, for all levels, things, players and places.
law move_is_checked:
  for +level: L.Level
  for +things: H.Things
  for +p: S.Player
  for +x: U32
  for +y: U32
  for taken: {True{} == S.Sim.Try.ok(S.Sim.try_move(level, things, p, x, y)) : Bool}
  {True{} == S.Sim.Fit.ok(S.Sim.check(level, things, p,
    S.Sim.Body.at(S.Player.body(p, H.Things.you(things)), x, y), 1)) : Bool}

# LAW: a thing's move is taken only where its box passes the check,
# for all bodies, things, levels and places. The twin of
# move_is_checked for everything that is not the player: the mask is 3,
# since the lines that block monsters stop a thing as well.
law thing_move_is_checked:
  for +m: S.Sim.Body
  for th: H.Thing
  for +id: U32
  for +level: L.Level
  for +x: U32
  for +y: U32
  for +ts: H.Things
  for +p: S.Player
  for s: S.State
  for taken: {True{} == S.Sim.Walk.ok(Tic.Sim.chase.step.met(m, th, id, level, x, y,
    S.Sim.met(level, ts, p, S.Sim.Body.at(m, x, y)), s)) : Bool}
  {True{} == S.Sim.Fit.ok(S.Sim.check(level, ts, p, S.Sim.Body.at(m, x, y), 3)) : Bool}

# LAW: clear is pinned to the mobjs: when nothing stops a box, every
# mobj linked in the cells around it, whichever position in the list it
# holds, does not stop it (tests/blocking.bend shows the numbers). That the
# links hold every living thing once, in the cell of its centre, rests
# on tests/sim.bend's links checks; that none linked in a further cell
# can reach the box rests on milestone 5's ticket 09's argument, since
# the checker cannot compute the cell arithmetic.
law clear_pins_things:
  for +level: L.Level
  for +things: H.Things
  for +p: S.Player
  for +m: S.Sim.Body
  for k: Nat
  for id: U32
  for listed: {Some{id} == List.get(&2, U32, S.Sim.nearby(level, things, m), k) : Maybe<&2, U32>}
  for clear: {None{} == S.Sim.blocked(level, things, p, m) : Maybe<&2, U32>}
  {False{} == S.Sim.stops.at(things, p, m, id) : Bool}

# Things
# ------

# LAW: a thing in a lasting state, of -1 tics, leaves the state where
# its tic found it, for every thing, every name and every state: Doom's
# P_MobjThinker counts no state of -1 tics down and enters no other.
law lasting_stays:
  for +id: U32
  for +kind: U32
  for +x: U32
  for +y: U32
  for +z: U32
  for s: S.State
  {Tic.Sim.thing.step(H.Thing.lasting(Fx.Closed.thing(id, kind, x, y, z)),
    H.Thing.over(Fx.Closed.thing(id, kind, x, y, z)), Fx.Closed.thing(id, kind, x, y, z), id, s) == s : S.State}

# Sight
# -----

# LAW: a pair of sectors REJECT rules out never sees, for any two mobjs
# in any level: P_CheckSight answers the lump before it walks the BSP,
# and nothing the walk could find brings the sight back.
law rejected_never_sees:
  for level: L.Level
  for m: S.Sim.Body
  for t: S.Sim.Body
  {S.Sim.sight.between(True{}, level, m, t) == False{} : Bool}

# The renderer
# ------------

# LAW: the solid columns stay sorted: clipping any wall range into a
# sorted list of solid ranges, each from a first column to a last no
# less with at least one open column before the next, leaves such a
# list, for all lists and ranges.
law solid_sorted:
  for +first: Nat
  for +last: Nat
  for +rs: List<&2, C.Clip.Range>
  for ordered: {True{} == Nat.is_le(first, last) : Bool}
  for sorted: {True{} == C.Clip.sorted(rs) : Bool}
  {True{} == C.Clip.sorted(C.Clip.add(first, last, rs)) : Bool}

# A checker to ride the draw's loop: whether every index so far was the
# one expected, and the one expected next.
type Seq is Data:
  Seq{ok: Bool, next: Nat}

def Seq.see(i: Nat, st: Seq) -> Seq:
  Seq{ok, +next} = st
  Seq{Bool.and(ok, Nat.is_eq(i, next)), 1n+next}

# LAW: the loop under every column and span reaches the indices from its
# first, in order, as many as it is asked and no other: the checker
# riding it from i sees each index be the one expected and ends
# expecting n + i, for all n and i. So a column draw, which writes only
# the row its index names, changes no pixel outside its top and bottom
# rows.
law each_in_order:
  for n: Nat
  for +i: Nat
  {D.Draw.each(~Seq, ~Seq.see, n, i, Seq{True{}, i}) == Seq{True{}, Nat.add(n, i)} : Seq}

# Music
# -----

# LAW: a sysex event is its length and as many bytes, which midifile.c
# reads past, whatever follows: the next event starts after them, under
# the sysex's running status.
law sysex_skipped:
  for rest: List<&2, U32>
  {Mi.Midi.next(Mi.Track{0 <> 240 <> 2 <> 7 <> 7 <> rest, 0})
    == Mi.Got{Mi.Other{}, Mi.Track{rest, 240}} : Mi.Midi.Got}

# LAW: a track ends at its end-of-track event, and the next track's
# header follows it, whatever that is: ReadTrack stops there, not at the
# chunk's length.
law end_of_track_ends:
  for rest: List<&2, U32>
  {Mi.Midi.end(1n, Mi.Midi.next(Mi.Track{0 <> 255 <> 47 <> 0 <> rest, 0})) == Mi.Track{rest, 255} : Mi.Midi.Track}

# LAW: any callback pushed on the empty heap is its first, and popping
# it empties the heap.
law heap_one:
  for +e: Sg.Song.Entry
  {(Sg.Song.push([], e), Sg.Song.pop(Sg.Song.push([], e))) == ([e], [])
    : List<&2, Sg.Song.Entry> & List<&2, Sg.Song.Entry>}

# LAW: before any note, a note off or an all-notes-off on any channel
# releases nothing and writes nothing.
law quiet_offs:
  for +t: Pl.Player.Tabs
  for +raw: U32
  for +key: U32
  for +vel: U32
  {(Pl.Player.event(t, 128, raw, key, vel, Pl.Player.start()),
    Pl.Player.event(t, 176, raw, 123, vel, Pl.Player.start()))
    == (Pl.Player.start(), Pl.Player.start()) : Pl.Player & Pl.Player}

# Sound lumps
# -----------

# LAW: the default table has exactly eight slots, and starting a sound
# preserves the size of every table.
law channels_capacity:
  for priority: Nat
  for slots: List<&2, Maybe<&2, Ch.Channel.Voice>>
  {(Ch.Channel.model.size(Ch.Channel.model.start(priority, slots)),
    Ch.Channel.model.size(Ch.Channel.model.none()))
    == (Ch.Channel.model.size(slots), 8n) : Nat & Nat}

# LAW: after any start, its source occurs in at most one slot.
law channels_unique_source:
  for priority: Nat
  for slots: List<&2, Maybe<&2, Ch.Channel.Voice>>
  {True{} == Ch.Channel.model.one(Ch.Channel.model.start(priority, slots), False{}) : Bool}

# LAW: a full table whose sounds are all more important refuses the new
# sound: the shared allocator returns the table size, its drop sentinel.
law channels_priority:
  for priority: Nat
  for slots: List<&2, Maybe<&2, Nat>>
  for protected: {True{} == Ch.Channel.model.protected(priority, slots) : Bool}
  {Ch.Channel.model.size.keys(slots) == Ch.Channel.choice(priority, slots) : Nat}

# LAW: a sound at 16000 or 17990 Hz, the rates of Freedoom's two sounds
# that SDL's converter is not given, has no run, whatever it holds.
law sfx_rates_unserved:
  for count: U32
  for bytes: List<&2, U32>
  {(X.Sfx.run(X.Sound{16000, count, bytes}), X.Sfx.run(X.Sound{17990, count, bytes}))
    == (None{}, None{}) : Maybe<&2, X.Sfx.Run> & Maybe<&2, X.Sfx.Run>}
