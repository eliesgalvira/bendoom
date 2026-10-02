# 21: The episode's closing text

**Tier:** 3

**What to build:** when E1M8 ends, vanilla's finale for episode 1 runs: the E1 text types out at vanilla's speed over vanilla's background flat with D_VICTOR playing, then the shareware's end picture follows and stays until the player quits, as vanilla's `f_finale.c` does for DOOM1.WAD.

**Blocked by:** 04 (song changes), 07

**Status:** ready-for-agent

- [ ] Frames partway through the typing and after it completes match Chocolate Doom's with zero differing pixels.
- [ ] The end picture matches vanilla's.
- [ ] D_VICTOR plays, and `tools/listen.nu` reports zero differing samples for it.
