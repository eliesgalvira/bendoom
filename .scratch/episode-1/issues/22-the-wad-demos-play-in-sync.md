# 22: The WAD's three demos replay in sync

**Tier:** 3 (the episode's acceptance)

**What to build:** DEMO1 (E1M5, 5,026 tics), DEMO2 (E1M3, 3,836 tics) and DEMO3 (E1M7, 2,134 tics) of DOOM1.WAD replay in Bendoom to their last tic without drifting from Chocolate Doom. Find and fix each desync at its cause; a fix that belongs to another ticket's mechanic is fixed here, with the cause named in the report.

**Blocked by:** none; all prerequisite mechanics have landed.

**Status:** ready-for-agent

- [ ] Each demo compares with Chocolate Doom with zero differing pixels at no fewer than five tics spread through it and at its last tic.
- [ ] Before reporting a desync, rule out the oracle (see `docs/agents/orchestrator.md`).
- [ ] Resolve the inherited lethal-melee death-state discrepancy below, preserving fuzz phase through the actual draw history.
- [x] Resolve the inherited E1M8 status-face disagreement below at its first incorrect random draw or oracle event.
- [ ] If Freedoom's DEMO1 (E1M6, Hurt Me Plenty) also replays in sync, pin it as a flake-check test; if not, report its first diverging tic and the missing mechanic.
- [x] The README's project status describes the episode.
- [ ] All nine map start views match Chocolate Doom with zero differing pixels on the final episode build, as spec 54 requires.
- [ ] Each map song has a zero-sample-difference comparison through `tools/listen.nu`, as spec 56 requires. Keep valid earlier evidence where the relevant path is unchanged; one map's song does not establish the others.
- [ ] Compare sound-channel saturation and eviction with Chocolate Doom, including an expired channel when a new sound starts. Ticket 15's death case at tic 300 uses different physical slots because vanilla clears the expired channel after starting the next sound. Its complete waveform, event sequence and active voices still match; general channel parity is unproven. Preserve that distinction and fix any audible difference at its cause.
- [ ] The final browser build passes the episode parity checks required by spec 51, with music and sound effects from the opened WAD. Include the finale's full text and HELP2; ticket 21 verified native frames and exports, but its targeted browser RGB comparison did not finish.
- [ ] E1M6 and E1M9 hold 35 tics/s with music synthesizing and no audio underruns, using the window bench's counter as specified in spec 57.

## Inherited death-state discrepancy

On stock DOOM1.WAD, place the player at E1M7 `192 -384 90` and replay `800,0,0,0,0`. Both green `eb01743` and ticket16 checkpoint `9195547` finish with the same player position and angle, differing from Chocolate Doom: Bendoom x10188759/y4274209154/angle3337576432 versus vanilla x10279438/y−20669014/angle3325546168. Viewz2490368, health0 and gameplay PRNG151 agree. These are fixed-point coordinates and binary angles. The first momentum divergence is at tic 328; see the current checkpoint below.

The resulting death view differs by33920 pixels. Its different draw history also changes fuzz phase,46 versus32, and leaves73 differing pixels after rebirth at802. Extend the script with `1,0,0,0,1 1,0,0,0,0` for that restart. Diagnose the state divergence before changing renderer phase handling; ticket16 uses a separate hazard-death fixture for its lifecycle check. Preserve the failed reproduction, without masks or fitted phase resets.

## Where it stopped

The reviewed firing fix is `284c71a`; `82ab1c0` deletes two obsolete pistol pain-event expectations from external source ordering. Successful firing now cancels pending player pain through the existing state transition. Proofs and five affected suites pass in native and JS. On rebuilt Frame, all nine starts, all six DEMO2 checkpoints, all six DEMO3 checkpoints and all five inherited E1M8 face controls match all 64,000 pixels and the active palette. Neutral traces also match E1M8 player state, gameplay PRNG and M_Random through 2176; the first incorrect pain event at 1833 is resolved.

DEMO1 passes 20/1000/2000 and still differs at 3000/4000/5026 by 50,979/54,391/52,715 pixels; its 3000 palette differs. The earliest remaining confirmed event discrepancy is a delayed platform start: Chocolate emits DSPSTART at 2088, Bend at 2093. Player position first differs at 2104 and gameplay PRNG at 2123. Platform activation and sector heights need diagnosis before assigning a cause.

Death800/rebirth802 still differ by 33,920/73 pixels, with matching active palettes. The first wrong momentum is at 328, one friction step before position diverges at 329. The dead player stands at z=floorz=40 while its centre sector floor is 32. Vanilla skips corpse friction at this step edge; the independent source/WAD replay exactly reconstructs both resulting slide positions. A bounded shared-predicate correction and externally grounded regression are next. Corpse height is a separate concern and does not explain this divergence.

The final-source start/demo checks, saturation/expired-channel evidence and optional Freedoom diagnostic remain open. Separate support workers own remaining songs and browser/performance; their gates are not claimed here. The completed verification batch preserved 29 passing and five failing complete controls individually. Exact timings and retained inputs are in ignored research/checkpoint.md.
