# 24: One record of which sectors are secret

**Tier:** 2 (no behaviour change on the shareware maps)

Since ticket 08 a sector's special is sim state, so `State.secrets`, a per-sector copy of "special == 9", is a second record of the same fact. Finding a secret clears `State.secrets[s]` (src/special.bend, `Sim.sector.secret`) where vanilla's P_PlayerInSpecialSector zeroes `sector->special`, and `Sim.tally` recounts the total from the live specials where vanilla counts `totalsecret` once at spawn (P_SpawnSpecials). Once a floor special zeroes or copies a sector's special (tickets 10 and 13), a secret could still be found and the tally's total would shrink; both differ from vanilla.

**Blocked by:** 10, 13 (both write sector specials; this removes a `State` field, about 170 patterns, so it runs alone after them)

**Status:** ready-for-agent

- [ ] `State.secrets` and its copy are deleted; finding a secret sets the sector's special to 0, as vanilla does.
- [ ] The secret total is counted once when the level loads and carried to the tally, as `totalsecret`.
- [ ] Every test passes unchanged on both backends and the tally of E1M1 matches `tools/oracle.nu --screen tally`.
