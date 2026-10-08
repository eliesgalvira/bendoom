# 22: The WAD's three demos replay in sync

**Tier:** 3 (the episode's acceptance)

**What to build:** DEMO1 (E1M5, 5,026 tics), DEMO2 (E1M3, 3,836 tics) and DEMO3 (E1M7, 2,134 tics) of DOOM1.WAD replay in Bendoom to their last tic without drifting from Chocolate Doom. Find and fix each desync at its cause; a fix that belongs to another ticket's mechanic is fixed here, with the cause named in the report.

**Blocked by:** 09, 10, 11, 12, 13, 15, 16, 17, 18, 19, 20, 21

**Status:** ready-for-agent

- [ ] Each demo compares with Chocolate Doom with zero differing pixels at no fewer than five tics spread through it and at its last tic.
- [ ] Before reporting a desync, rule out the oracle (see `docs/agents/orchestrator.md`).
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
