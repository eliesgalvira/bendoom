# 12: Teleporters, with the wall law's one exception

**Tier:** 2

**What to build:** crossing teleport line 97 (E1M5, E1M8, E1M9; check the WAD for others) teleports as vanilla's `EV_Teleport` and `P_TeleportMove`: to the destination thing in the tagged sector, facing its angle, with the fog at both ends, the sound, the 18-tic freeze and the telefrag of anything standing on the destination. Monsters teleport as vanilla lets them. Vanilla does not check the destination against walls, so the law that positions change only through checked moves is restated with one narrow exception: a tic that does not teleport keeps the player in free space, and a teleport puts the player at a teleport destination thing. Record the exact LAWS.bend changes for maintainer review.

**Blocked by:** 01, 03 (teleport destinations)

**Status:** ready-for-agent

- [ ] On E1M5, a scripted demo through a teleporter compares with Chocolate Doom just after arrival and after the freeze: zero differing pixels.
- [ ] A telefrag matches vanilla, or the ticket names the vanilla rule it checked and why no demo shows it.
- [ ] The proof checks, and the ticket's report quotes the old and new law.
