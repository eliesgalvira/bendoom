# 13: Lights, damaging floors and the secret exit

**Tier:** 2

**What to build:** the light and damage specials and the secret exit of DOOM1.WAD's maps work as vanilla's `p_lights.c` and `p_spec.c`: sector specials 2 and 3 (E1M2, E1M4 to E1M7), 13 (E1M2, E1M4) and 16, the 20% damage floor (E1M3, E1M9); line 35, lights to very dark (E1M3); line 51, the secret exit switch (E1M3), which ends the level with the secret exit kind from ticket 06. Check the lists against the WAD. Damage follows vanilla's tic timing and its radiation-suit rule (the suit itself is ticket 20). The law about the tic's rest, which hardcodes the nukage case, is restated for the general damage rule.

**Status:** ready-for-agent

- [x] Each light special compares with Chocolate Doom at two or more tics of its cycle: zero differing pixels.
- [ ] Standing on a 20% floor on E1M3 hurts as vanilla's: the health and the pain flash match at a chosen tic.
- [ ] Pressing E1M3's secret exit leads to the tally and then to E1M9, matching vanilla's frames: `tools/oracle.nu --screen tally` and `--screen entering` from E1M3 (ticket 07 tested the secret path only at its seam, an ended state of kind Secret).
- [x] The proof checks; report how LAWS.bend changed.

**Remaining acceptance:** observe Chocolate Doom's active damage palette at the already matched E1M3 damage probe, and compare the actual line51 route through the entering screen to E1M9. The direct line51 press already matches the tally. Sectors, sim, render, game, route and tally pass on native and JavaScript; frame, doom and film each measure251 live words with4 spare.

**Verified source and frames:** all six source-derived light2/3/13 phase captures, line35, damage indices/health, actual secret-exit tally, the original06 stock E1M2 reload,25's next-map stock three-pixel case, and10's original isolated stock70/98 floor cases match all64000 pixels with no masks. No output pins changed. Line35's occupied-mover test preserves the mover while changing all tagged lights. LAWS.tic_rest is unchanged; PROOF uses the shared Boolean damage classification and passes. State.secrets remains for24. No sector4/5 occurs in DOOM1.WAD E1M1–9. Exact recipes, controls and frame evidence are in ignored research/.
