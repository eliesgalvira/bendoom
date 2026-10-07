# 10: Floors, lifts and the donut

**Tier:** 2

**What to build:** the floor and platform specials of DOOM1.WAD's maps work as vanilla's `p_floor.c`, `p_plats.c` and `p_spec.c`: 5 (E1M4), 9 donut (E1M2), 18 (E1M4), 20 (E1M3, E1M9) and 22 (E1M5, E1M7), which raise to the next floor and change the floor's texture and special, 70 (E1M5, E1M7), 82 (E1M8), 91 (E1M5, E1M7, E1M8) and 98 (E1M5, E1M7); check the list against the WAD. Floor texture and special changes use the sector state from ticket 08. Sounds as vanilla's.

**Status:** ready-for-agent

- [ ] For each special, a scripted demo on a map that has it compares with Chocolate Doom at rest after the move, with zero differing pixels, including the changed floor texture for 20 and 22 and both moved sectors for the donut.
- [x] Standing on a moving floor carries the player as vanilla's does (compare a frame mid-move).
- [x] The laws still check.

**Remaining evidence:** native and JavaScript simulation, sector, render and game tests and the proof pass with reviewed melt/pointer timing. Tic-exact, unmasked Chocolate comparisons match all 64,000 pixels for 5, 9, 18, 20, 22, 82, 91 and mid-rise player carry. The donut's two moved sectors and changed flats for 20/22 are visible. Native width is 251, with four words free. Both formal reviews and final integration verification remain.

**Blocked by ticket 13:** stock E1M7 special70 has 428 differing pixels; stock E1M5 special98 has 12. Both repeat exactly, and both no-activation controls match. Clearing only each map's strobe specials makes the identical activation replay match all pixels: E1M7 sectors34/112/129/139; E1M5 sectors20/35/82/101. Geometry, flats, lights, things and movement scripts otherwise remain unchanged. Keep stock acceptance open until the strobes land; do not replace it with the control. Ignored `research/cases.nu`, `diag70.nu` and `diag98.nu` preserve the commands and captures.
