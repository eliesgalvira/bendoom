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

The reviewed firing fix is `284c71a`; `82ab1c0` deletes two obsolete pistol pain-event expectations from external source ordering. Successful firing now cancels pending player pain through the existing state transition. Proofs and five affected suites pass in native and JS. On rebuilt Frame, all nine starts, all six DEMO2 checkpoints, all six DEMO3 checkpoints and all five inherited E1M8 face controls match all 64,000 pixels and the active palette. Neutral traces also match E1M8 player state, gameplay PRNG and M_Random through 2176; the first incorrect pain event at 1833 is resolved.

DEMO1 passes 20/1000/2000 and still differs at 3000/4000/5026 by 50,979/54,437/52,715 pixels; its 3000 palette differs. The earliest remaining confirmed event discrepancy is a delayed platform start: Chocolate emits DSPSTART at 2088, Bend at 2093. The player has not crossed the trigger at2088; identify the external activator before changing the common movement path. Player position first differs at2104 and gameplay PRNG at2123.

The corpse correction shares the existing step-edge sliding predicate with player friction. At328 the dead player stands at z=floorz=40 while its centre sector floor is32; vanilla preserves momentum there. Independent source/WAD math reconstructs both old and corrected slide positions. The corrected trace matches ten observed player fields through800 and five motion/floor fields through799 logged commands. Proofs and corpse-friction/player/sim/fight suites pass in native and JS. Frame/Doom/Film/window widths remain197/197/203/197. Static corpse height is a separate source concern; this evidence establishes the reproduced death/rebirth controls, not universal body-state parity.

The final-source start/demo checks, saturation/expired-channel evidence and optional Freedoom diagnostic remain open. Separate support workers own remaining songs and browser/performance; their gates are not claimed here. The completed verification batch preserved31 passing and three failing complete controls individually. Exact timings and retained inputs are in ignored research/checkpoint.md.
