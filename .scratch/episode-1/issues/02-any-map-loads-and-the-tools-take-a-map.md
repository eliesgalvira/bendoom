# 02: Any map loads, and the tools take a map and replay a demo to a tic

**Tier:** 1

**What to build:** the level loader takes an episode and map instead of assuming E1M1, and the verification tools follow: `tools/oracle.nu`, `tools/demo.nu`, `tools/wad.nu`, `tools/frame.bend` and `tools/walk.bend` take a map, and the oracle can replay a WAD demo lump (DEMO1, DEMO2, DEMO3) or a `.lmp` file up to a chosen tic and compare that frame with Chocolate Doom's. The game itself still starts at E1M1; ticket 06 adds the launch option.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] The frame dumper renders the start view of any map of either WAD.
- [ ] The oracle compares a start view on any map; with DOOM1.WAD, E1M1, E1M3, E1M4, E1M5, E1M7, E1M8 and E1M9 report zero differing pixels (the probe of 2026-10-01 measured this with a renamed-marker WAD). E1M2 (red keycard) and E1M6 (unspawned types) are known differences that ticket 03 closes.
- [ ] The oracle replays the first N tics of a WAD demo lump or `.lmp` and compares the frame at tic N. Show it on DEMO3 (E1M7) at an early tic where the frame already matches, and report the first tic where each of DEMO1 to DEMO3 diverges today, as a baseline for ticket 22.
- [ ] The demo writer puts the requested episode and map in the header; the WAD reader finds any map's marker.
- [ ] The existing E1M1 uses of every tool still work with no map given.
