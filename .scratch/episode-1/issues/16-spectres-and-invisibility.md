# 16: Spectres and partial invisibility

**Tier:** 3

**What to build:** things with vanilla's shadow flag draw with vanilla's fuzz column, its offset table and its running position, so the spectre shimmers as in vanilla. Partial invisibility gives the player the shadow flag for vanilla's duration: monsters aim with vanilla's spread (A_FaceTarget's MF_SHADOW branch, missing from `Sim.chase.face.at` in src/tic.bend), and the weapon sprite draws fuzzed, with the blink before it runs out.

**Blocked by:** 03

**Status:** ready-for-agent

- [ ] A frame with a spectre in view matches Chocolate Doom with zero differing pixels (the fuzz position must match, so compare after the same commands from a map start).
- [ ] After picking up partial invisibility, the fuzzed weapon frame matches vanilla, and a monster's shot uses vanilla's spread (compare the outcome at a chosen tic).
- [ ] Freedoom's frame hashes are unchanged unless the oracle explains the change.
