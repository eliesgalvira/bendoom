# 14: Recordings and films span the maps

**Tier:** 2

**Status:** ready-for-agent

Recording headers, lifetime across exits, launcher publication, cross-engine
replay and film frames/music are verified. Enter now aliases use before recording; live tally and replay consume the same
commands. The separate Game.again flag and held override are removed. Actual
Enter press, hold, release and repress pass the game regression on native and
JavaScript, along with keys and tally checks. Remaining verification is pending.

- [x] Encode Enter tally acceleration before recording and make live/replay play consume the same commands. Remove the separate tally control path.
- [x] Verify actual Enter press/release and holds over tics in native/JS game checks.
- [ ] Finish affected route, demo and film checks on native/JS, plus native doom, film and frame products.
- [ ] Build the live Enter recording driver and verify production recording/quit/launcher, Film and Chocolate through E1M2; inspect tally and both map frames.
- [ ] Confirm the new film music matches the unchanged continuous vanilla reference.

Chocolate Doom's `WI_checkForAccelerate` in `src/doom/wi_stuff.c` reads rising
`BT_ATTACK` and `BT_USE` from player commands. `G_BuildTiccmd` encodes use as
`BT_USE`. Existing continuous music evidence remains valid on unchanged audio
paths; ticket 04's absolute startup lead remains pending.

The route binary compiled, but its runtime failed because the check script ran
from research while the fixture path is relative to the repository root. The
remaining-only script corrects that working directory. Its queued run was
cancelled before acquisition to free review slots; no remaining check or fresh
Enter capture has run. Prior completed recording/video/audio evidence is retained
in ignored research and does not substitute for this regression.
