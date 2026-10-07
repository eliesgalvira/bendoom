# 26: The browser flake check uses Freedoom

**Tier:** 1

**Problem:** the milestone requires a flake check that needs no unfree WAD, but `nix/web.mod.nix` feeds the public shareware web package to `checks.web`, and its music expectation is from DOOM1.WAD. Construct a Freedoom check artifact while preserving the public shareware package. Opening the full Freedoom WAD currently exhausts the existing browser-style heap before sound expansion, so the storage cause must be fixed before changing that wiring.

**Blocked by:** 05 (runtime WAD loading and browser acceptance; its final source is under review)

**Status:** ready-for-agent

- [ ] Opening the complete 28,795,084-byte Freedoom WAD, loading audio/graphics and starting live gameplay succeeds with the existing runtime heap and wasm memory settings. Diagnose the duplicate/storage pressure and remove its cause; do not trim the WAD, substitute shareware, or increase the memory limits.
- [ ] `checks.web` builds and tests a Freedoom artifact. Its dependency closure needs no shareware WAD; the public shareware web package remains available.
- [ ] The music expectation comes from a short Chocolate Doom capture with an explicit Freedoom IWAD and preserved provenance. Normal browser playback and the isolated pistol input/audio check pass with that artifact.
- [ ] The verified shareware E1M1/E1M6 browser paths still pass. Run affected native/JS tests and proof if storage code changes; report whole-program native width if relevant. The orchestrator runs the final flake check.

**Evidence:** ticket05's unchanged-heap probe requested2026-10-07T05:11:39+02:00, acquired05:22:53 and failed in under one second, before any audio-expansion line. Class22 allocation attempted131421KB high-water against113483KB capacity; class22 totals65536KB, classes0/1 only64/96KB. The wrapper's trailing date masked the binary failure with exit0, so use explicit failure propagation. Probe source/scripts/output remain in `../bendoom-e1-05/research/`; start by locating those exact artifacts and verifying what they measure. The existing native runtime uses wider addresses than wasm; confirm the controlled probe reproduces actual storage behavior.

**Where it starts:** worktree `../bendoom-e1-26`, branch `e1-26`, based on ticket05's review tip `a5a8bbd`. First phase is read-only diagnosis while both05 reviews run. Before code changes, merge its final reviewed fixes and current `episode-1`. Root's integration remains green at62b3fa7. No numbered state rows, messages or Thinker variants are reserved for this ticket.
