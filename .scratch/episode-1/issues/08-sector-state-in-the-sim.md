# 08: Sector state belongs to the sim

**Tier:** 2

**What to build:** a sector's floor and ceiling flats, light level, special and tag become sim state, which the renderer reads, alongside the heights the movers already move. Today the special lives in the level geometry, which the tic restores every tic, so a special that changes a flat or a sector's special would be silently undone. Behaviour does not change in this ticket; it makes tickets 10 and 13 possible.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] Flats, light level, special and tag are read from the sim's state by the renderer and by the per-tic sector work.
- [ ] No behaviour changes: every test passes unchanged on both backends and every frame hash is identical.
- [ ] The laws about the tic's rest and kept geometry are re-proved over the new state; report exactly how LAWS.bend changed.
- [ ] Report the native width margin of every record this grows (the cap is 255 live words).
