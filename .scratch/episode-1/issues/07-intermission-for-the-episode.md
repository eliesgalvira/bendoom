# 07: The intermission is right for every map of the episode

**Tier:** 1

**What to build:** the tally shows each map's name, par time and the next map's name from vanilla's episode 1 tables, the map screen marks every finished map and points at the next one with vanilla's "you are here" spots, and a secret exit shows E1M9 as the next map. Replace the fixed E1M1 values (par 30, two spots, two name lumps).

**Blocked by:** 06

**Status:** ready-for-agent

- [ ] `tools/oracle.nu --tally` reports zero differing pixels after the exits of at least E1M1, E1M2, E1M5 and E1M7 (vanilla shows no tally after E1M8), and after E1M3's secret exit if ticket 13 has landed (otherwise test the secret path at its seam and note it).
- [ ] The map screen after the tally (the "entering" screen) matches vanilla for at least two maps.
- [ ] The tally's counts, sounds and timing stay as they are for E1M1.

**Note from ticket 06:** the play now carries the map it is on and the next one, for the tally to read. `didsecret` is not carried yet: `G_WorldDone` sets it after a secret exit and `G_PlayerReborn` clears it, and the map screen after E1M9 needs it. The tally's M_Random index does not yet count the melt into the tally or the tally's sound pitch draws.
