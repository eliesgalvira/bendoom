# 01: The line specials and movers live in their own module

**Tier:** 2 (gates every special ticket, so dispatch it first)

**What to build:** a behaviour-preserving move. The line-special dispatch (crossing, use, and the special switch tables), the movers (doors, lifts, floors), the switches and the sector lights and damage move out of the sim's main module into a module of their own, so that the doors, floors, teleporter and light tickets can run in parallel without colliding in one 6,300-line file. The sim's tic calls into the new module. Types both need move to wherever the dependency order requires, since Bend has no mutual recursion between modules (see `docs/bend.md`).

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] The special and mover code is in its own module, and the sim's main module keeps the tic, movement, combat and monsters.
- [ ] No behaviour changes: every test passes unchanged on both backends, every frame hash in the render test is identical, and the proof checks.
- [ ] The new module reads as one concept: one entry for a crossed line, one for a used line, one for the per-tic sector work, so later tickets add a case to a table, not a branch to the tic.
- [ ] Land it quickly, since tickets editing other parts of the sim run in parallel; move code, do not rewrite it.
