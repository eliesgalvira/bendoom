# 23: Cleanups the shareware-things review left

**Tier:** 1 (no behaviour change)

Ticket 03 landed every shareware thing type; its standards review found no hard violation and left these.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] `Thing.fight.row` in src/things.bend has identical `case 3002:` and `case 58:` rows; one branch can go.
- [ ] Comments that record open work belong in tickets, not code: `src/bar.bend` "RADIATIONPAL… is not picked yet" (ticket 20) and the two "is not here yet" notes, at `Sim.sector` in src/special.bend (the radiation suit) and `Sim.chase.face.at` in src/tic.bend (ticket 16's A_FaceTarget shadow spread).
- [ ] Comments still speak of "either map" / "either E1M1" (src/sim.bend around lines 686, 2645, 2748, 3355; src/special.bend around 678, 712, 745) though every shareware map now loads.
- [ ] `Thing.rows()`'s header describes how the table grew rather than where each row group sits.
- [ ] `Inventory.tic` nests four `Inventory.power.tic(...)` calls with `4294967295` for −1; a named step or a per-power row reads better. `Inventory.sound` mixes `||` with `Bool.or`.
- [ ] The player's link in `Sim.relink` and `State.entered.you` passes a literal 0 for flags rather than the player's own; `Things.edit.if` needs a name that says what it edits.
