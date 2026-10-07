# 13: Lights, damaging floors and the secret exit

**Tier:** 2

**What to build:** the light and damage specials and the secret exit of DOOM1.WAD's maps work as vanilla's `p_lights.c` and `p_spec.c`: sector specials 2 and 3 (E1M2, E1M4 to E1M7), 13 (E1M2, E1M4) and 16, the 20% damage floor (E1M3, E1M9); line 35, lights to very dark (E1M3); line 51, the secret exit switch (E1M3), which ends the level with the secret exit kind from ticket 06. Check the lists against the WAD. Damage follows vanilla's tic timing and its radiation-suit rule (the suit itself is ticket 20). The law about the tic's rest, which hardcodes the nukage case, is restated for the general damage rule.

**Blocked by:** 01, 06 (exit kinds)

**Status:** ready-for-agent

- [ ] Each light special compares with Chocolate Doom at two or more tics of its cycle: zero differing pixels.
- [ ] Standing on a 20% floor on E1M3 hurts as vanilla's: the health and the pain flash match at a chosen tic.
- [ ] Pressing E1M3's secret exit leads to the tally and then to E1M9, matching vanilla's frames: `tools/oracle.nu --screen tally` and `--screen entering` from E1M3 (ticket 07 tested the secret path only at its seam, an ended state of kind Secret).
- [ ] The proof checks; report how LAWS.bend changed.

**E1M2 reload dependency from ticket 06:** after a death and reload, the red key differs at five pixels in (163–165, 83–84). The same pixels and colours occur in the preserved pre-change frame binary. Reproduce on DOOM1.WAD with `tools/oracle.nu -32 -240 90 "60,0,0,0,2 40,0,0,0,0 1,0,0,0,1 30,0,0,0,0" --map E1M2 --things "11,2035,-32,-210 12,2035,-32,-178" --wad /path/to/doom1.wad --frame frame`.

Clearing only E1M2 SECTORS' special words for sectors 87, 90, 128, 146, 148 (special 3) and 193 (special 2) in a WAD copy makes this exact probe zero; clearing only special 13 leaves the same five pixels. Each field is the little-endian word at `SECTORS.pos + sector * 26 + 22`; the control changes no other byte. Vanilla's `P_SpawnStrobeFlash` draws `P_Random` for non-synchronised strobes, while the current `Sim.light.spawn` ignores 2/3. Preserve those spawn draws and rerun this probe when implementing the strobes. This is a light-special dependency, not a missing red-key type or a ticket 06 regression.
