# 21: The episode's closing text

**Tier:** 3

**What to build:** when E1M8 ends, vanilla's finale for episode 1 runs: the E1 text types out at vanilla's speed over vanilla's background flat with D_VICTOR playing, then the shareware's end picture follows and stays until the player quits, as vanilla's `f_finale.c` does for DOOM1.WAD.

**Status:** ready-for-agent

Final review remains pending. Targeted browser RGB was not established and is retained for ticket 22's final parity work. Finale-only acceptance uses E1M1's exit under an E1M8 marker; it does not establish ticket 19's stock boss-room completion. The load test's compact animation-atlas indices are regression pins, not vanilla pixel evidence. Ticket 04's film startup-lead decision remains user-owned.

- [x] Frames partway through the typing and after it completes match Chocolate Doom's with zero differing pixels.
- [x] The end picture matches vanilla's.
- [x] D_VICTOR plays, and `tools/listen.nu` reports zero differing samples for it.
