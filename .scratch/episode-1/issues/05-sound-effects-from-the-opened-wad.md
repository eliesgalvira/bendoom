# 05: Sound effects come from the opened WAD, and the table is complete

**Tier:** 1

**What to build:** every sound effect is expanded from the opened WAD's sound lumps when the game starts, with the existing SDL-resampler expansion, instead of at build time. The sound table grows to every sound the shareware content can play, which fixes the demon's attack (sgtatk), silent today. Delete the build-time sounds node, its packaged files and `BENDOOM_SOUNDS`; the film exporter and the web build use the runtime path.

**Blocked by:** final Freedoom-only web check setup and separate Standards/Spec reviews. Ticket 04 is integrated; its human decision on the film's 4096-frame lead remains open.

**Status:** ready-for-agent

- [x] Each expanded sound matches the build-time expansion it replaces sample for sample, and the demon's attack plays and matches Chocolate Doom in `tools/listen.nu`.
- [x] Report the startup cost of expanding every sound; the game still opens without a noticeable pause.
- [x] The film exporter's E1M1 video has the same audio as before, plus the demon's attack.
- [x] The web build plays sound effects in the browser check.
- [x] No build-time sound renderer, packaged sound file or `BENDOOM_SOUNDS` remains.

**Where it stopped (2026-10-07):** branch `e1-05` includes reviewed intermission integration `aa3ace5` and verified browser/spec checkpoint `7435b46`. Native and JS sound, mixer, music and WAD tests, proof, native products and both oracle paths pass. The 47 replaced expansions match both WADs byte for byte. Silencing only Freedoom's demon-attack samples restores the old film audio exactly; the shareware demon fixture differs from Chocolate Doom by zero samples. Runtime expansion takes 503–548 ms after the WAD is opened. The unchanged-heap browser check passes live shareware E1M1 and E1M6, plus an isolated pistol control. Generated native roots use at most 251 argument words, leaving four.

The inherited flake web check still builds a shareware artifact and pins shareware music, despite spec story 60 requiring Freedoom-only checks. Finishing that setup requires a Freedoom web artifact, an independently captured Freedoom music expectation and an actual browser pass. The fixed-heap full Freedoom startup probe fails while opening the 28,795,084-byte WAD, before audio expansion. Its class-22 allocation attempts a 131,421 KB high-water mark against 113,483 KB capacity. This inherited full-WAD browser startup limit needs a separate storage decision before the Freedoom check can pass; runtime and caps remain unchanged. Keep this ticket open for that dependency and the two reviews.
