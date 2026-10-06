# 10: Floors, lifts and the donut

**Tier:** 2

**What to build:** the floor and platform specials of DOOM1.WAD's maps work as vanilla's `p_floor.c`, `p_plats.c` and `p_spec.c`: 5 (E1M4), 9 donut (E1M2), 18 (E1M4), 20 (E1M3, E1M9) and 22 (E1M5, E1M7), which raise to the next floor and change the floor's texture and special, 70 (E1M5, E1M7), 82 (E1M8), 91 (E1M5, E1M7, E1M8) and 98 (E1M5, E1M7); check the list against the WAD. Floor texture and special changes use the sector state from ticket 08. Sounds as vanilla's.

**Blocked by:** 08

**Status:** ready-for-agent

- [ ] For each special, a scripted demo on a map that has it compares with Chocolate Doom at rest after the move, with zero differing pixels, including the changed floor texture for 20 and 22 and both moved sectors for the donut.
- [ ] Standing on a moving floor carries the player as vanilla's does (compare a frame mid-move).
- [ ] The laws still check.

**Where it stopped (2026-10-03, 16:15):** paused when Elies cut the night to tier 1. Worktree `../bendoom-e1-10` (branch `e1-10`, at 2a8fb63) holds ~260 lines of uncommitted work on 5 files; nothing is committed or verified. It was fixing a linearity error. Resume from that worktree: finish the evidence the acceptance list asks for, merge episode-1, then review on both axes before landing.
