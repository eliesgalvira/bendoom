# 19: The end of E1M8

**Tier:** 3

**What to build:** on E1M8, vanilla's `A_BossDeath` lowers the floor tagged 666 to its lowest neighbour once every baron is dead, and sector special 11 hurts the player and ends the level when health falls low enough, as vanilla's does, leading straight to the finale (ticket 21): `G_DoCompleted` skips the tally after map 8.

**Status:** ready-for-agent

- [x] Killing both barons on E1M8 lowers the tagged floor; the frame at rest matches Chocolate Doom's.
- [x] Standing in the final room ends the level at vanilla's health threshold, and the frame that follows matches vanilla's.
- [ ] Finish the affected-check rerun after the final integration merge, independent reviews and the orchestrator's full flake check.

## Where it stopped

Source `81ca382` includes episode baseline `54288b2`. Ending, baron, sectors, sim, fight and game tests passed on native and JavaScript. Frame, Doom, Film and window native builds passed; widths are 197, 197, 203 and 197. Actual stock-things E1M8 captures at 2131, 2788, 3489, 3517, 3518 and 3519 match all 64,000 pixels and palettes. The route only places the player; it does not complete an original-start traversal.

The final no-op integration merge was followed by passing ending, baron, sectors and sim reruns on both backends. The retry script then changed directories and fight could not find `tests/fixtures/freedoom.lmp`. Fight/game and the six accepted frame reruns were not reached. Run the corrected `research/production19/final-checks.sh` from the repository root under the capped shared lock when resumed. Original passes remain valid on identical source; the incomplete final rerun and full integration verification remain due.

Five additional full-frame failures are preserved at 2176, 2519, 2520, 2694 and 2830. Their differences are confined to the status-bar face. The verified ticket 16 baseline has the identical status bar at 2176, and cosmetic random indices differ before the last boss action. Ticket 22 owns further diagnosis. No masks or phase fitting count these failures as passes. Bounded reproduction and provenance are in ignored `research/production19/face-handoff.md` and `research/ticket19-external-checkpoint.md`.
