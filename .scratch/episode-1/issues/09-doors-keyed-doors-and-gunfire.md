# 09: Every door the shareware maps use, with keyed doors and gun-triggered lines

**Tier:** 2

**What to build:** the door specials of DOOM1.WAD's maps work as vanilla's `p_doors.c`: 16 (E1M6), 27 yellow-locked (E1M3 to E1M7), 28 red-locked (E1M2, E1M6, E1M7), 31 (E1M2 to E1M4, E1M7 to E1M9), 32 blue (E1M9), 33 red (E1M9), 34 yellow (E1M7, E1M9), 46 opened by gunfire (E1M2), 63 (E1M3, E1M7), 76 (E1M6), 86 (E1M4), 90 (E1M3 to E1M5, E1M7, E1M9) and 103 (E1M2, E1M3, E1M5, E1M6, E1M9); check the list against the WAD. Locked doors refuse the player without the key with vanilla's message and sound. Bullets that hit a gun-triggered line activate it, as vanilla's `P_ShootSpecialLine`. Monsters open the doors vanilla lets them open, including the manual locked ones. Switch textures change on every switch these use.

**Blocked by:** 01, 03 (keycards)

**Status:** ready-for-agent

- [ ] For each door special, a scripted demo on a map that has it compares with Chocolate Doom at the door fully open and, where it closes, fully closed again: zero differing pixels.
- [ ] A locked door without the key matches vanilla's frame with the message showing; with the key, it opens.
- [ ] Shooting E1M2's gun-triggered line opens its door, matching vanilla.
- [ ] A monster opening a door it may open is shown matching vanilla, or the ticket names the vanilla rule it checked and why no demo shows it.

**Where it stopped (2026-10-03, 16:15):** paused when Elies cut the night to tier 1. Branch `e1-09` (worktree `../bendoom-e1-09`) has the doors committed, unreviewed: 2bb58f1 (every shareware door, keyed doors, the gun-triggered line), merged with episode-1 at 947eb00. It was bisecting DEMO2/DEMO3 and had the monster-opens-a-door case next. Resume from that worktree: finish the evidence the acceptance list asks for, merge episode-1, then review on both axes before landing.
