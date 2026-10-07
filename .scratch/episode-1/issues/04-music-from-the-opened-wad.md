# 04: Music is synthesized from the opened WAD while the game runs

**Tier:** 1

**What to build:** the song plays from the opened WAD: the current song lump and the WAD's GENMIDI, through the existing OPL emulation and its Chocolate Doom timing, synthesized buffer by buffer as the game runs instead of read from files rendered at build time. The song follows the scene: the map's own song (D_E1M1 to D_E1M9), D_INTER during the tally; ticket 21 adds D_VICTOR. Changing scene starts the new song as vanilla's `S_ChangeMusic` does. Delete the build-time music node, its packaged files and `BENDOOM_MUSIC`; the film exporter and the web build use the runtime path too.

**Blocked by:** None

**Status:** ready-for-human

- [x] `tools/listen.nu compare` finds 0 differing samples between Chocolate Doom and the running game (`tools/listen.nu game`) on DOOM1.WAD: D_E1M1 over 8,822,344 frames, D_E1M6 over 7,946,745 and D_INTER over 9,492,808, each through a full pass and its restart.
- [x] E1M6 and E1M9 (renamed-marker WADs, each with its own song and the shareware sounds) run the window bench at 50 to 53 frames a second, standing and with `WALK=1`, the queue empty only on the first frame. The deck costs 2.5 to 2.8 ms a tic natively (`bench/music.bend`).
- [x] The route demo replayed to E1M1's exit switch, then used and the tally skipped by keys: the capture equals the deck changing to D_INTER at frame 81,920 and back to D_E1M1 at 258,048, buffer boundaries, sample for sample.
- [ ] The film exporter's E1M1 audio as before, sample for sample: see below.
- [x] The browser check hears the song's first 1024 frames as Chocolate Doom plays them.
- [x] No build-time music renderer, packaged song file or `BENDOOM_MUSIC` remains.

## Open: the film's audio changed on purpose

The deck mixes Chocolate Doom's first buffer (4096 frames) before the first song, as every `-warp` capture has it. The old render started the song at frame 0, so the chip's tremolo, vibrato and envelope clocks ran out of phase with Chocolate Doom's: the old render differs from Chocolate's capture in 7,782,301 samples of its first pass. With that buffer removed in a scratch build, the film's audio of the route demo equals the old film's for the first 2,596,873 frames, everything before the exit, sounds included; past the exit D_INTER now plays. The committed film starts its song 4096 frames later, in phase with Chocolate Doom. Elies decides whether that change stands.

The spec review questioned that lead. How many buffers Chocolate Doom mixes before `S_Start` follows wall-clock startup, not a rule in `i_oplmusic.c`; `tools/listen.nu` itself notes the start frame moves between runs. With sound effects on, `i_sdlsound.c` opens the mixer at `GetSliceSize()`, 1024 frames, and `opl_sdl.c` opens its own 4096-frame device only when sound effects are off. So the 4096 lead and `Song.change`'s rounding to 4096-frame boundaries match the music-only capture, not necessarily the game or the film with sound effects.

## Open: left after review

- `Stream.topped`'s `case []:` can never run, since the deck is always a one-element list; a recursive holder type may remove it, if the checker accepts it.
