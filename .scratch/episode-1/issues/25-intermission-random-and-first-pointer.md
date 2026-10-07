# 25: The intermission's M_Random draws and its first pointer frame

**Tier:** 1

Ticket 07’s masked tally and map comparisons left two behaviors unchecked.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] M_Random's index through the intermission counts what Chocolate Doom draws: `wipe_initMelt` (f_wipe.c) on the melt into the tally and on the melt out of it, and `S_StartSound`'s pitch draws (s_sound.c) for the tally's sounds. Bendoom counts only `WI_initAnimatedBack`'s. The index sets WIMAP0's animation phases, which the oracle masks, and the next map's `st_randomnumber` for the face, which it also masks. The melt itself stays out of scope; only its draws count. Compare with an oracle run that leaves the masks off once the draws are counted.
- [ ] `snl_pointeron` is static in wi_stuff.c: on the tic a press opens the map screen, `WI_drawShowNextLoc` reads the value left by the last screen drawn, which is false in the game's first intermission and true in every later one (`WI_drawNoState` sets it). Bendoom computes `(cnt & 31) < 20` from cnt 140 and draws the pointer on that frame every time. That is one frame off, in the first intermission only.
