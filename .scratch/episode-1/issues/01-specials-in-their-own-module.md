# 01: The line specials and movers live in their own module

**Tier:** 2 (gates every special ticket, so dispatch it first)

**What to build:** a behaviour-preserving move. The line-special dispatch (crossing, use, and the special switch tables), the movers (doors, lifts, floors), the switches and the sector lights and damage move out of the sim's main module into a module of their own, so that the doors, floors, teleporter and light tickets can run in parallel without colliding in one 6,300-line file. The sim's tic calls into the new module. Types both need move to wherever the dependency order requires, since Bend has no mutual recursion between modules (see `docs/bend.md`).

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] The special and mover code is in its own module, and the sim's main module keeps the tic, movement, combat and monsters.
- [ ] No behaviour changes: every test passes unchanged on both backends, every frame hash in the render test is identical, and the proof checks.
- [ ] The new module reads as one concept: one entry for a crossed line, one for a used line, one for the per-tic sector work, so later tickets add a case to a table, not a branch to the tic.
- [ ] Land it quickly, since tickets editing other parts of the sim run in parallel; move code, do not rewrite it.

**Where it stopped (2026-10-02, 08:40):** stopped by the orchestrator, unreviewed and unlanded. The move is on branch `e1-01` (worktree `../bendoom-e1-01`): 152e9d9, then merges of episode-1 up to 3f2070c (daec1db). Its last test batch on daec1db had 8 of 15 tests passing on both backends when it was stopped; the rest and the proof did not finish. Next: merge episode-1 (it lacks ticket 03), rerun the tests and the proof, review on both axes, land it alone before any tier 2 ticket.
