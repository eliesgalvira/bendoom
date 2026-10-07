# 20: The radiation suit and light amplification

**Tier:** 3

**What remains:** verify the implemented suit palette and visor fixed colormap against Chocolate Doom after actual stock pickups, during stable effects and their final blink. Ticket 13 already implements floor protection and suit leakage. Native and JavaScript powerup, player, pickup, sector and render tests pass; frame, game and film builds and the proof pass. Stock frames, active palette and health evidence remain pending.

**Status:** ready-for-agent

- [ ] After picking up the suit on a map that has one, standing in nukage leaves health as vanilla's does, and the tinted frame matches Chocolate Doom.
- [ ] After picking up light amplification on E1M5 or E1M6, a dark room's frame matches vanilla's, and so does a frame during the blink.
