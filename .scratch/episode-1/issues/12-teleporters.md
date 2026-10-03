# 12: Teleporters, with the wall law's one exception

**Tier:** 2

**What to build:** crossing teleport line 97 (E1M5, E1M8, E1M9; check the WAD for others) teleports as vanilla's `EV_Teleport` and `P_TeleportMove`: to the destination thing in the tagged sector, facing its angle, with the fog at both ends, the sound, the 18-tic freeze and the telefrag of anything standing on the destination. Monsters teleport as vanilla lets them. Vanilla does not check the destination against walls, so the law that positions change only through checked moves is restated with one narrow exception: a tic that does not teleport keeps the player in free space, and a teleport puts the player at a teleport destination thing. Elies was asleep when this was decided; record exactly how LAWS.bend changed so he can review it.

**Blocked by:** 01, 03 (teleport destinations)

**Status:** ready-for-agent

- [ ] On E1M5, a scripted demo through a teleporter compares with Chocolate Doom just after arrival and after the freeze: zero differing pixels.
- [ ] A telefrag matches vanilla, or the ticket names the vanilla rule it checked and why no demo shows it.
- [ ] The proof checks, and the ticket's report quotes the old and new law.

**Where it stopped (2026-10-03, 16:15):** paused when Elies cut the night to tier 1. Branch `e1-12` (worktree `../bendoom-e1-12`) has the teleporters committed, unreviewed: 31dfb5f (EV_Teleport and the wall law's one exception), merged with episode-1 at 922ba02. The LAWS.bend change there is for Elies to review before it lands. Resume from that worktree: finish the evidence the acceptance list asks for, merge episode-1, then review on both axes before landing.
