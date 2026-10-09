# 22: The WAD's three demos replay in sync

**Tier:** 3 (the episode's acceptance)

**What to build:** DEMO1 (E1M5, 5,026 tics), DEMO2 (E1M3, 3,836 tics) and DEMO3 (E1M7, 2,134 tics) of DOOM1.WAD replay in Bendoom to their last tic without drifting from Chocolate Doom. Find and fix each desync at its cause; a fix that belongs to another ticket's mechanic is fixed here, with the cause named in the report.

**Blocked by:** none; all prerequisite mechanics have landed.

**Status:** ready-for-agent

- [x] Each demo compares with Chocolate Doom with zero differing pixels at no fewer than five tics spread through it and at its last tic, including the complete frame and active palette.
- [x] Before reporting a desync, rule out the oracle (see `docs/agents/orchestrator.md`).
- [x] Resolve the inherited lethal-melee death-state discrepancy below, preserving fuzz phase through the actual draw history.
- [x] Resolve the inherited E1M8 status-face disagreement below at its first incorrect random draw or oracle event.
- [ ] If Freedoom's DEMO1 (E1M6, Hurt Me Plenty) also replays in sync, pin it as a flake-check test; if not, report its first diverging tic and the missing mechanic.
- [x] The README's project status describes the episode.
- [x] All nine map start views match Chocolate Doom with zero differing pixels and the active palette on the final episode build, as spec 54 requires.
- [x] Each map song has a zero-sample-difference comparison through `tools/listen.nu`, as spec 56 requires. Valid earlier evidence is retained where the relevant path is unchanged; controlled startup lead caveats remain.
- [x] Compare sound-channel saturation and eviction with Chocolate Doom, including an expired channel when a new sound starts. Complete waveform and logical/physical channel comparisons cover rejection before cleanup and acceptance afterward, including repeated mixes after expiry. Ticket 15's historical physical-slot difference had matching waveform, events and active voices; it was not an audible failure. Showing and finale cleanup and the retained transition audio also agree.
- [ ] The final browser build passes the episode parity checks required by spec 51, with music and sound effects from the opened WAD. Include the finale's full text and HELP2; ticket 21 verified native frames and exports, but its targeted browser RGB comparison did not finish.
- [x] E1M6 and E1M9 hold 35 tics/s with music synthesizing and no audio underruns, using the window bench's counter as specified in spec 57.

## Inherited death-state discrepancy

On stock DOOM1.WAD, place the player at E1M7 `192 -384 90` and replay `800,0,0,0,0`. Extend it with `1,0,0,0,1 1,0,0,0,0` for rebirth at 802. These death/rebirth controls match the complete frame and active palette through their actual draw history.

## Optional Freedoom diagnostic

Freedoom's DEMO1 first differs at drawn tic 2 by 64 pixels, with a matching active palette. Removing only the two unsupported lost souls accounts for 28 sprite pixels; 36 floor pixels remain unexplained. The final-source recheck is identical to the earlier frame. No sync pin or complete cause is established.

## Where it stopped

Worktree `../bendoom-e1-22`, branch `e1-22`. No prerequisite blockers remain.

The player body still uses a static height/flags representation after death. This is a separate source limitation from the reproduced corpse step-edge friction cause; the corrected lethal-melee control does not establish universal body-state parity.

Browser episode parity remains open, including deterministic frame controls and production map/input/audio/finale checks. Keep this ticket open and the README's acceptance-in-progress status until that gate is resolved. The optional Freedoom diagnostic remains partial; unsupported lost souls are outside the shareware episode's scope.
