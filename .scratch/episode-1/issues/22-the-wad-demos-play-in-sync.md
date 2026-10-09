# 22: The WAD's three demos replay in sync

**Tier:** 3 (the episode's acceptance)

**What to build:** DEMO1 (E1M5, 5,026 tics), DEMO2 (E1M3, 3,836 tics) and DEMO3 (E1M7, 2,134 tics) of DOOM1.WAD replay in Bendoom to their last tic without drifting from Chocolate Doom. Find and fix each desync at its cause; a fix that belongs to another ticket's mechanic is fixed here, with the cause named in the report.

**Blocked by:** none; all prerequisite mechanics have landed.

**Status:** ready-for-agent

- [ ] Each demo compares with Chocolate Doom with zero differing pixels at no fewer than five tics spread through it and at its last tic.
- [ ] Before reporting a desync, rule out the oracle (see `docs/agents/orchestrator.md`).
- [ ] Resolve the inherited lethal-melee death-state discrepancy below, preserving fuzz phase through the actual draw history.
- [ ] Resolve the inherited E1M8 status-face disagreement below at its first incorrect random draw or oracle event.
- [ ] If Freedoom's DEMO1 (E1M6, Hurt Me Plenty) also replays in sync, pin it as a flake-check test; if not, report its first diverging tic and the missing mechanic.
- [ ] The README's project status describes the episode.
- [ ] All nine map start views match Chocolate Doom with zero differing pixels on the final episode build, as spec 54 requires.
- [ ] Each map song has a zero-sample-difference comparison through `tools/listen.nu`, as spec 56 requires. Keep valid earlier evidence where the relevant path is unchanged; one map's song does not establish the others.
- [ ] Compare sound-channel saturation and eviction with Chocolate Doom, including an expired channel when a new sound starts. Ticket 15's death case at tic 300 uses different physical slots because vanilla clears the expired channel after starting the next sound. Its complete waveform, event sequence and active voices still match; general channel parity is unproven. Preserve that distinction and fix any audible difference at its cause.
- [ ] The final browser build passes the episode parity checks required by spec 51, with music and sound effects from the opened WAD. Include the finale's full text and HELP2; ticket 21 verified native frames and exports, but its targeted browser RGB comparison did not finish.
- [ ] E1M6 and E1M9 hold 35 tics/s with music synthesizing and no audio underruns, using the window bench's counter as specified in spec 57.

## Baseline (ticket 02, 2026-10-02)

`tools/oracle.nu demo <lump> <tic>` compares the frame after `<tic>` tics. First diverging tic before the special and thing tickets:

| Demo | Last match | First difference | Likely cause |
|---|---|---|---|
| DEMO1 (E1M5) | 20 | 21 (52 pixels) | unspawned E1M5 types shifting the spawn random draws (ticket 03); unconfirmed |
| DEMO2 (E1M3) | 53 | 54 (21,178 pixels) | use of the special-31 door at lines 995/996 (ticket 09) |
| DEMO3 (E1M7) | 72 | 73 (20,691 pixels) | use of the special-31 door at lines 949/950 (ticket 09) |

## Inherited death-state discrepancy

On stock DOOM1.WAD, place the player at E1M7 `192 -384 90` and replay `800,0,0,0,0`. Both green `eb01743` and ticket16 checkpoint `9195547` finish with the same player position and angle, differing from Chocolate Doom: Bendoom x10188759/y4274209154/angle3337576432 versus vanilla x10279438/y−20669014/angle3325546168. Viewz2490368, health0 and gameplay PRNG151 agree. These are fixed-point coordinates and binary angles. The first divergence is not yet located.

The resulting death view differs by33920 pixels. Its different draw history also changes fuzz phase,46 versus32, and leaves73 differing pixels after rebirth at802. Extend the script with `1,0,0,0,1 1,0,0,0,0` for that restart. Diagnose the state divergence before changing renderer phase handling; ticket16 uses a separate hazard-death fixture for its lifecycle check. Preserve the failed reproduction, without masks or fitted phase resets.

## Pending pain when firing

Chocolate Doom's `P_FireWeapon` enters `S_PLAY_ATK1` before the weapon attack state. `A_FirePistol`, `A_FireShotgun` and a loaded `A_FireCGun` enter `S_PLAY_ATK2` before firing. These transitions replace any pending player pain action. The corresponding existing Bendoom fire helpers omit that player-state transition. This is a source finding, not yet an observed waveform mismatch; compare a shared demo where firing overlaps the pending `A_Pain` action before claiming or fixing an audible difference.

Ticket18 handles its new `A_GunFlash` transition using the existing standing row. In the current first-person player model, the attack chain has no actions, random draws, rendered sprite or movement predicate, so collapsing it to standing preserves its observable behavior. Literal attack rows are not required merely to match internal state numbers. Any correction to the older fire paths should preserve the common transition timing and remove the cause of a surviving pain action.

## Inherited E1M8 status-face disagreement

Ticket19's placed-player E1M8 route retains all stock things and changes only the player start to `-160 864 0`. Fixture SHA256 is `f65d1ebb68f31c629c02bd6fd70f15df298885cc852ee1d2c2435eb366934fc1`; complete demo SHA256 is `e86bc8240dfd2e29740b9b12934c41f67dad4a367baebce1ca701980c597ab8e`. The saved command stream is `research/route19-ending.commands` in `../bendoom-e1-19`; `research/production19/face-handoff.md` records the reproduction and external trace.

Full-frame comparisons differ at tics2176/2519/2520/2694/2830 by538/497/497/538/503 pixels, all within the status face. At2176, the green16 binary and ticket19 have byte-identical entire status bars, including the same538 differing pixels. This establishes an inherited failure, not a passing cropped comparison. The six other predefined mechanic and ending views pass all64000 pixels and the active palette.

The bounded trace at clocks2100..2175 puts Bendoom's M_Random index two draws ahead of Chocolate Doom throughout:0 versus254 at2100,34 versus32 at2131,79 versus77 at2175. The last BossDeath acts at2176, after this discrepancy. Locate the first differing draw and rule out the oracle before changing code; do not fit an offset, change capture tics or mask the face.

## Where it stopped

Worktree `/home/bigweld/Repos/bendoom-e1-22`, branch `e1-22`, has merged released integration `ddf7b99`. All nine stock map starts after twenty idle commands match all 64,000 pixels and the active palette on that build.

All eighteen proposed WAD-demo checkpoints have complete comparisons. DEMO1 passes 20/1000/2000 and differs at 3000/4000/5026 by 50,979/54,391/52,711 pixels; its 3000 palette also differs. DEMO2 passes 53/750/3836 and has 459/34/34 face pixels differing at 1500/2250/3000. DEMO3 passes 72/400/800/1700/2134 and has 494 face pixels differing at 1200. These are checkpoint failures, not identified first divergences. The seven inherited face/death/rebirth comparisons still fail by their recorded pixel counts on the released build, with matching active palettes.

Diagnosis is running against frozen Chocolate inputs and an assertion-based DEMO2/1500 loop. The initial minimal trace omitted the graphics loader's switch table and is not valid evidence for late random indices; the corrected trace uses the production loader. No game fix is verified yet. Remaining song and browser/performance gates are assigned to separate support workers. Evidence and exact command timings are in ignored `research/checkpoint.md`; earlier plans are not passing evidence.
