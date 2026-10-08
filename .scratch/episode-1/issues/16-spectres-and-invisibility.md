# 16: Spectres and partial invisibility

**Tier:** 3

**What to build:** things with vanilla's shadow flag draw with vanilla's fuzz column, its offset table and its running position, so the spectre shimmers as in vanilla. Partial invisibility gives the player the shadow flag for vanilla's duration: monsters aim with vanilla's spread (A_FaceTarget's MF_SHADOW branch, missing from `Sim.chase.face.at` in src/tic.bend), and the weapon sprite draws fuzzed, with the blink before it runs out.

**Blocked by:** 03

**Status:** ready-for-agent

- [x] A frame with a spectre in view matches Chocolate Doom with zero differing pixels (the fuzz position must match, so compare after the same commands from a map start).
- [ ] After picking up partial invisibility, the fuzzed weapon frame matches vanilla, and a monster's shot uses vanilla's spread (compare the outcome at a chosen tic).
- [ ] Freedoom's frame hashes are unchanged unless the oracle explains the change.

Core checkpoint has full-frame zero comparisons for a placed stock E1M7 spectre at command12 and the actual E1M6 invisibility pickup at commands12,1972,1973,1974,1982,2100,2101. The latter covers blink and expiry. Native and JavaScript fuzz, powerups, player and baron tests pass. FaceTarget and missile angle/random-position expectations come from Chocolate's source.

Remaining acceptance: external monster shot outcomes, nonzero phase through map transition and rebirth, Film against its actual draw schedule while preserving frame/audio counts, product widths and remaining affected checks. Native render currently differs only at `long fight 1453`, including weapon coverage; its expected hash is unchanged pending external diagnosis. That failure stopped the sequential check before render JavaScript, game and proof. No hashes have been repinned.
