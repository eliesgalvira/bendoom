# 06: Launch at any map, and the exits chain the episode

**Tier:** 1

**What to build:** the game starts at the map named by a `-warp <episode> <map>` launch option, as Chocolate Doom's, or at E1M1 by default, and from a demo's header when replaying one. The level's end becomes a kind (none, normal, secret). After the tally the next map loads by vanilla's `G_DoCompleted` and `G_WorldDone` rules for episode 1: E1M1 to E1M8 in order, E1M3's secret exit to E1M9, E1M9 to E1M4, and E1M8 to the finale (until ticket 21, the game may hold on the tally after E1M8). The player crosses a level change as vanilla's `G_PlayerFinishLevel` leaves them: health, armour, weapons, ammo and backpack kept, keys, powers and palette effects cleared. Dying restarts the current map from a pistol start. Delete the path that restarts E1M1 after the tally. Document `-warp` in the README.

**Blocked by:** 02

**Status:** ready-for-agent

- [ ] `-warp 1 5` starts on E1M5, and its start view matches Chocolate Doom's `-warp 1 5`.
- [ ] A scripted run takes E1M1's exit; after the tally, E1M2's first frame matches Chocolate Doom's, with the carried inventory on the status bar.
- [ ] The exit-kind rules are checked against vanilla's next-map logic for every E1 map, including E1M3's secret exit (the secret exit line itself is ticket 13; test the rule at its seam) and E1M9's return to E1M4.
- [ ] Dying on E1M2 restarts E1M2 with a pistol start, matching vanilla.
- [ ] The laws about the exit still check; restate them for exit kinds if they must change.
