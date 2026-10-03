# 05: Sound effects come from the opened WAD, and the table is complete

**Tier:** 1

**What to build:** every sound effect is expanded from the opened WAD's sound lumps when the game starts, with the existing SDL-resampler expansion, instead of at build time. The sound table grows to every sound the shareware content can play, which fixes the demon's attack (sgtatk), silent today. Delete the build-time sounds node, its packaged files and `BENDOOM_SOUNDS`; the film exporter and the web build use the runtime path.

**Blocked by:** 04 (both reshape the mixer; run them in sequence)

**Status:** ready-for-agent

- [ ] Each expanded sound matches the build-time expansion it replaces sample for sample, and the demon's attack plays and matches Chocolate Doom in `tools/listen.nu`.
- [ ] Report the startup cost of expanding every sound; the game still opens without a noticeable pause.
- [ ] The film exporter's E1M1 video has the same audio as before, plus the demon's attack.
- [ ] The web build plays sound effects in the browser check.
- [ ] No build-time sound renderer, packaged sound file or `BENDOOM_SOUNDS` remains.

**Where it stopped (2026-10-03, 17:45):** stopped by Elies. Branch `e1-05` (worktree `../bendoom-e1-05`) has 3 unreviewed commits: 3a17912 (one WAD directory parser for the whole-file and streaming readers), dd80cdd (every sound expanded from the opened WAD at start), e3cccda (one Xvfb launch and wait-for shared by listen, oracle and the smoke test). About 260 uncommitted lines on 9 files (including LAWS.bend) rework the sound bank from a list to an array; it was chasing an out-of-memory failure in a patched runtime when stopped. Not merged with episode-1 since 2a8fb63.
