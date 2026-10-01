# 03: Every thing type in the shareware maps spawns and draws

**Tier:** 1

**What to build:** every DoomEd thing type that appears in DOOM1.WAD's maps, on any skill, gets vanilla's `mobjinfo` row and the states it needs to spawn and draw, with vanilla's random draws at spawn, so every map's start matches vanilla. Missing today: 6 yellow keycard (E1M3 to E1M7, E1M9), 13 red keycard (E1M2, E1M6, E1M7), 14 teleport destination (E1M5, E1M8, E1M9), 34 candle (E1M9), 46 tall red torch (E1M8, E1M9), 58 spectre (E1M3, E1M5 to E1M9), 2024 partial invisibility (E1M3, E1M5 to E1M9), 2025 radiation suit (E1M4 to E1M7), 2026 computer map (E1M5 to E1M8), 2045 light amplification (E1M5, E1M6), 3003 baron (E1M8). Check the list against the WAD yourself.

The keycards are picked up, shown on the status bar and announced with vanilla's message and sound. The powerups are picked up with their message, sound and item count; their effects come in tickets 16 and 20. The spectre spawns and acts as vanilla's demon does, drawn normally until ticket 16 adds the fuzz. The baron spawns, wakes and chases; its attacks come in ticket 15.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] With ticket 02's oracle (or a renamed-marker WAD if 02 has not landed), the start view of every map E1M1 to E1M9 shows zero differing pixels against Chocolate Doom.
- [ ] Picking up each keycard and each powerup matches vanilla's frame (status bar, message, palette flash) at a rest moment after the pickup, on a map that has it.
- [ ] Freedoom's pinned tests and frame hashes are unchanged, or any change is explained and re-pinned after a zero oracle.
- [ ] Reserve state-table rows and sound ids as the dispatch names, so tickets 15 to 20 can add theirs in parallel.
