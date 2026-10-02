# 19: The end of E1M8

**Tier:** 3

**What to build:** on E1M8, vanilla's `A_BossDeath` lowers the floor tagged 666 to its lowest neighbour once every baron is dead, and sector special 11 hurts the player and ends the level when health falls low enough, as vanilla's does, leading straight to the finale (ticket 21): `G_DoCompleted` skips the tally after map 8.

**Blocked by:** 10, 13, 15

**Status:** ready-for-agent

- [ ] Killing both barons on E1M8 lowers the tagged floor; the frame at rest matches Chocolate Doom's.
- [ ] Standing in the final room ends the level at vanilla's health threshold, and the frame that follows matches vanilla's.
