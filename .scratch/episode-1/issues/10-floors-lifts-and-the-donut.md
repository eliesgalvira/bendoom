# 10: Floors, lifts and the donut

**Tier:** 2

**What to build:** the floor and platform specials of DOOM1.WAD's maps work as vanilla's `p_floor.c`, `p_plats.c` and `p_spec.c`: 5 (E1M4), 9 donut (E1M2), 18 (E1M4), 20 (E1M3, E1M9) and 22 (E1M5, E1M7), which raise to the next floor and change the floor's texture and special, 70 (E1M5, E1M7), 82 (E1M8), 91 (E1M5, E1M7, E1M8) and 98 (E1M5, E1M7); check the list against the WAD. Floor texture and special changes use the sector state from ticket 08. Sounds as vanilla's.

**Status:** ready-for-agent

- [ ] For each special, a scripted demo on a map that has it compares with Chocolate Doom at rest after the move, with zero differing pixels, including the changed floor texture for 20 and 22 and both moved sectors for the donut.
- [ ] Standing on a moving floor carries the player as vanilla's does (compare a frame mid-move).
- [x] The laws still check.

**Remaining evidence:** implementation is on `e1-10`, based on integration `62b3fa7`. Sector, blocking, rendering and game tests pass on native and JavaScript; frame, walk and Doom native builds pass; native width is 251, with four words free. The shareware WAD confirms every listed special. Ignored `research/cases.nu` contains isolated scripts for all nine specials and a mid-rise player-carry case; the walk tool confirms activation and WAD-derived destinations, but no current-source Chocolate pixel comparisons have run. Complete those comparisons, including visible changed flats, then merge current integration and obtain both reviews.

**Open obstruction edge:** Chocolate's `EV_DoPlat` leaves `low` uninitialized for `raiseToNearestAndChange`; `T_PlatRaise` reads it after an obstruction. The current mover retries its rise. The selected acceptance routes have player clearance, but E1M3 tag 27 sector 66 rises beside closed sector 51, whose floor and ceiling are both 64. No things spawn in sector 66; switch line 360 is far away. Establish whether normal single-player play can obstruct that rise before deciding how to handle this undefined vanilla state. Do not invent a descent target.
