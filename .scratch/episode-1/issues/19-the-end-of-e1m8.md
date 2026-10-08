# 19: The end of E1M8

**Tier:** 3

**What to build:** on E1M8, vanilla's `A_BossDeath` lowers the floor tagged 666 to its lowest neighbour once every baron is dead. Sector special 11 hurts the grounded player and ends the level at vanilla's health threshold, leading straight to ticket 21's finale. `G_DoCompleted` skips the tally after map 8.

**Status:** ready-for-agent

- [x] Killing both barons on E1M8 lowers the tagged floor; the frame at rest matches Chocolate Doom's.
- [x] Standing in the final room ends the level at vanilla's health threshold; the following frame matches vanilla's.
- [x] Extend the unchanged tic_rest proof to cover sector 11.
- [ ] Verify the final correction with affected native/JavaScript tests, products and six full-frame/palette comparisons.
- [ ] Review the final correction independently on Standards and Spec.
- [ ] Pass the orchestrator's full flake check before landing on episode-1.

## Remaining verification

Worker `e1-19` lives in `/home/bigweld/Repos/bendoom-e1-19`. It includes green integration `54288b2` and candidate handoff `9255967`. The pure predicate-order correction in `Sim.damage.final` clears the old rest_due reduction failure. The proof now splits the actual sector dispatcher before using the existing counted/secret helpers, and rest_think takes its damaged State directly. LAWS.bend is unchanged. The full proof passed on 2026-10-09 at 00:15:08 Madrid; final native/JavaScript and product builds await AC power. Failed proof attempts remain in ignored `research/production19/` and `research/resume19/`.

Before this correction, reviewed source `81ca382` passed ending, baron, sectors, sim, fight and game on native and JavaScript. Frame, Doom, Film and window native widths were 197, 197, 203 and 197. These passes do not certify the corrected source. The existing frozen stock-things E1M8 route must be rerun at tics 2131, 2788, 3489, 3517, 3518 and 3519, comparing all 64,000 pixels and actual palettes. It covers the visibly lowered floor at 2788 and the first finale at 3519. Only player placement changes; no original-start traversal is required. Reproduction and external provenance remain in ignored `research/ticket19-external-checkpoint.md` and `research/route19-ending.commands`.

Five additional failures at 2176, 2519, 2520, 2694 and 2830 remain failures, confined to the status-bar face. Green ticket 16 has the identical entire status bar at 2176, and cosmetic random indices differ before the last boss action. Ticket 22 owns further diagnosis. No masks or fitted phases count these as passes. Reproduction is in ignored `research/production19/face-handoff.md`.

The earlier source passed both independent reviews. The corrected diff requires its own reviews and the full integration check. Episode-1 remains green at `54288b2`; candidate is unlanded. Preserve prior failed runner and oracle evidence.
