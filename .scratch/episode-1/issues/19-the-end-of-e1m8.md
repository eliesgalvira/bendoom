# 19: The end of E1M8

**Tier:** 3

**What to build:** on E1M8, vanilla's `A_BossDeath` lowers the floor tagged 666 to its lowest neighbour once every baron is dead. Sector special 11 hurts the grounded player and ends the level at vanilla's health threshold, leading straight to ticket 21's finale. `G_DoCompleted` skips the tally after map 8.

**Status:** ready-for-agent

- [x] Killing both barons on E1M8 lowers the tagged floor; the frame at rest matches Chocolate Doom's.
- [x] Standing in the final room ends the level at vanilla's health threshold; the following frame matches vanilla's.
- [x] Extend the unchanged tic_rest proof to cover sector 11.
- [x] Verify the corrected source with six affected native/JavaScript suites, Frame and six full-frame/palette comparisons.
- [x] Review the final correction independently on Standards and Spec.
- [ ] Build and measure final combined Doom, Film and window products on the integration candidate.
- [ ] Pass the orchestrator's full flake check before landing on episode-1.

## Integration gates

Verified source `5b52bd7` on worker `e1-19` includes green integration `54288b2` and candidate handoff `9255967`. LAWS.bend is unchanged. The pure predicate-order correction in `Sim.damage.final` clears rest_due's symbolic reduction failure. The proof splits the actual sector dispatcher before using the existing counted/secret helpers; rest_think takes its damaged State directly. The full proof passes and both independent reviews are clear.

Ending, baron, sectors, sim, fight and game pass on native and JavaScript. Frame builds with maximum native width 197, leaving 58 words. Frozen stock-things E1M8 controls at tics 2131, 2788, 3489, 3517, 3518 and 3519 match all 64,000 pixels and actual palettes 2, 0, 3, 4, 3 and 0. They cover the visibly lowered floor at 2788 and the first finale at 3519. The final integration merge was a no-op, followed by all six suite and frame/palette reruns passing at 2026-10-09 01:11:36 Madrid. Evidence is under ignored `research/resume19/`.

The orchestrator will build and measure Doom, Film and window once on the combined ticket 18/19 candidate, then run the full integration check. Their earlier widths 197, 203 and 197 predate the corrected source and do not certify it. Episode-1 remains green at `54288b2`; this ticket stays open until the remaining gates pass.

Only player placement changes in the frozen route; no original-start traversal is required. Reproduction and external provenance remain in ignored `research/ticket19-external-checkpoint.md` and `research/route19-ending.commands`. Preserve earlier failed proof, runner and oracle evidence.

Five additional failures at 2176, 2519, 2520, 2694 and 2830 remain failures, confined to the status-bar face. Green ticket 16 has the identical entire status bar at 2176, and cosmetic random indices differ before the last boss action. Ticket 22 owns further diagnosis. No masks or fitted phases count these as passes. Reproduction is in ignored `research/production19/face-handoff.md`.
