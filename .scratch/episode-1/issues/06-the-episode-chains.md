# 06: Launch at any map, and the exits chain the episode — review fixes

**Tier:** 1

The chain landed on episode-1 (merge 096ffaa): `-warp`, exit kinds, vanilla's next-map rule, `G_PlayerFinishLevel`'s carry, the death reload and each map's song. Its review against Chocolate Doom 3.1.1's source confirmed the next-map rule, the carry, the reload and the status bar's arms rule. What follows is what the review left.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] `-warp` applies `G_InitNew`'s clamps: on DOOM1.WAD (shareware) an episode above 1 becomes 1, and the map is held to 1–9, so `-warp 2 1` and `-warp 1 0` play E1M1 as in Chocolate Doom instead of failing. The clamps depend on the WAD's game mode (Freedoom is "ultimate"); `tests/game.bend` pins `-WARP 2` as E2M1 today, which vanilla does not do on shareware.
- [ ] A committed test tells carrying from resetting: `tests/tally.bend` reaches E1M2 with pistol-start values, the same as after a death. Pin a run that carries something (the oracle run carried a shotgun, 8 shells and 100% armour to E1M2 with 0 differing pixels at tics 5 and 30; that evidence was not committed).
- [ ] Rerun the death check on E1M2 after ticket 03 lands: it showed 5 differing pixels at (163–165, 83–84), attributed to the missing red keycard.
- [ ] `Play.next` takes the exit kind (`S.Sim.Exit`) instead of a Bool, so `Play.ended`'s two identical arms and LAWS.bend's `Exit.kind(secret: Bool)` helper go; consider `Unended | Ended{secret}` if it merges the duplicated `Normal`/`Secret` arms in `tic_counts`, `tic_keeps_geometry` and `tic_keeps_free`.
- [ ] `Play.back`'s episode 2–4 cases (`2→6, 3→7, 4→3`) are beyond this milestone; keep episode 1's rule unless Freedoom's maps need the others.
- [ ] `Play.wants` and `Play.enter` both match `Play`, and `enter`'s `Playing` arm cannot run; match once.
- [ ] `Inventory.finished` names its masks (`16711680`, `4278190080`) and shares `Inventory.start`'s powers literal; the face slot holding weapons owned at `ST_Start` gets a name that says so.
- [ ] `nix/tests.nix` has a narrating comment in `buildPhase` that repeats `docs/bend.md`; delete it. The `docs/bend.md` note says "32 MB stack" while `BUN_JSC_maxPerThreadStackUsage` is 16 MB (32 MB is the ulimit), and its "about 20000 on bun" depth is stale. `tools/frame.bend`'s header has an unwrapped line.
- [ ] `State.carried` feeds one value to both use-down and attack-down; vanilla's `WI_checkForAccelerate` tracks them apart (matters once the rocket launcher lands).
