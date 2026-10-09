# 22: The WAD's three demos replay in sync

**Tier:** 3 (the episode's acceptance)

**What to build:** DEMO1 (E1M5, 5,026 tics), DEMO2 (E1M3, 3,836 tics) and DEMO3 (E1M7, 2,134 tics) of DOOM1.WAD replay in Bendoom to their last tic without drifting from Chocolate Doom. Find and fix each desync at its cause; a fix that belongs to another ticket's mechanic is fixed here, with the cause named in the report.

**Blocked by:** none; all prerequisite mechanics have landed.

**Status:** ready-for-agent

- [ ] Each demo compares with Chocolate Doom with zero differing pixels at no fewer than five tics spread through it and at its last tic.
- [ ] Before reporting a desync, rule out the oracle (see `docs/agents/orchestrator.md`).
- [x] Resolve the inherited lethal-melee death-state discrepancy below, preserving fuzz phase through the actual draw history.
- [x] Resolve the inherited E1M8 status-face disagreement below at its first incorrect random draw or oracle event.
- [ ] If Freedoom's DEMO1 (E1M6, Hurt Me Plenty) also replays in sync, pin it as a flake-check test; if not, report its first diverging tic and the missing mechanic.
- [x] The README's project status describes the episode.
- [ ] All nine map start views match Chocolate Doom with zero differing pixels on the final episode build, as spec 54 requires.
- [ ] Each map song has a zero-sample-difference comparison through `tools/listen.nu`, as spec 56 requires. Keep valid earlier evidence where the relevant path is unchanged; one map's song does not establish the others.
- [ ] Compare sound-channel saturation and eviction with Chocolate Doom, including an expired channel when a new sound starts. Ticket 15's death case at tic 300 uses different physical slots because vanilla clears the expired channel after starting the next sound. Its complete waveform, event sequence and active voices still match; general channel parity is unproven. Preserve that distinction and fix any audible difference at its cause.
- [ ] The final browser build passes the episode parity checks required by spec 51, with music and sound effects from the opened WAD. Include the finale's full text and HELP2; ticket 21 verified native frames and exports, but its targeted browser RGB comparison did not finish.
- [ ] E1M6 and E1M9 hold 35 tics/s with music synthesizing and no audio underruns, using the window bench's counter as specified in spec 57.

## Inherited death-state discrepancy

On stock DOOM1.WAD, place the player at E1M7 `192 -384 90` and replay `800,0,0,0,0`. Extend it with `1,0,0,0,1 1,0,0,0,0` for rebirth at802. The original death/rebirth controls differed by33,920/73 pixels; their failed inputs and draw history remain in ignored research. Both now match all64,000 pixels and the active palette, without masks or fitted phase resets.

## Where it stopped

Worktree `../bendoom-e1-22`, branch `e1-22`. No prerequisite blockers remain.

The player body still uses a static height/flags representation after death. This is a separate source limitation from the reproduced corpse step-edge friction cause; the corrected lethal-melee control does not establish universal body-state parity.

Final-source start/demo controls, sound-channel saturation and expired-channel handling, and the optional Freedoom diagnostic remain open. Separate support workers own the remaining songs and browser/performance. Acceptance remains one ticket; root aggregates their evidence.
