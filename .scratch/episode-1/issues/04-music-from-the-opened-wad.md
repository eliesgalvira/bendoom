# 04: Music is synthesized from the opened WAD while the game runs

**Tier:** 1

**What to build:** the song plays from the opened WAD: the current song lump and the WAD's GENMIDI, through the existing OPL emulation and its Chocolate Doom timing, synthesized buffer by buffer as the game runs instead of read from files rendered at build time. The song follows the scene: the map's own song (D_E1M1 to D_E1M9), D_INTER during the tally; ticket 21 adds D_VICTOR. Changing scene starts the new song as vanilla's `S_ChangeMusic` does. Delete the build-time music node, its packaged files and `BENDOOM_MUSIC`; the film exporter and the web build use the runtime path too.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] `tools/listen.nu` reports zero differing samples against Chocolate Doom for D_E1M1 and at least two other songs of DOOM1.WAD, captured from the running game.
- [ ] On E1M6 and E1M9, the largest shareware maps, the game holds 35 tics a second with the window bench's underrun counter at zero after the first second; report the per-tic cost of synthesis. If it does not fit, stop and report the measurements rather than lowering fidelity.
- [ ] The tally plays D_INTER and the next map plays its own song (testable on the E1M1 exit before ticket 06 lands).
- [ ] The film exporter's E1M1 video has the same audio as before, sample for sample.
- [ ] The web build plays music in the browser check of `nix flake check`.
- [ ] No build-time music renderer, packaged song file or `BENDOOM_MUSIC` remains.
