# 18: The rocket launcher and its blast

**Tier:** 3

**What to build:** the rocket launcher fires rockets as vanilla's `A_FireMissile`, through the general missile spawn from ticket 15, and a rocket's explosion damages everything in its radius, the player included, reusing the radius damage the barrels use. Key 5 selects it if owned.

**Blocked by:** 15, 17 (both change weapon selection)

**Status:** ready-for-agent

- [x] A scripted demo fires a rocket at a wall and at a monster; frames at the rocket mid-flight and at the explosion match Chocolate Doom with zero differing pixels.
- [x] Firing a rocket at a wall next to the player hurts the player as vanilla's does.
- [x] The README's controls table lists key 5.

## Where it stopped

Branch `e1-18`, worktree `../bendoom-e1-18`, based on integration `54288b2`. Source through `b5a5a17` passes source/proof and rocket, baron, keys, sim and fight on native and JavaScript. Frame rebuilt. Launcher and rocket rows300–313, shared missile spawn/first-step, vertical clamp and barrel radius damage are implemented. Key5 and README/browser controls are updated. No LAWS declarations changed.

All eight preserved wall/monster/self flight and blast captures match64000 pixels and their active palettes. The delayed shotgun-pickup control at680 also matches64000 pixels/palette0. The first-display weapon ownership fix preserves later pickup background restoration. Complete controlled wall audio matches957600 bytes; independently generated120-tic events, physical channels and active voices match. This uses1260-frame callbacks plus70 drain, and does not settle ticket04 startup or production1024-frame device timing.

Remaining gates belong to root integration: independent Standards/Spec reviews, combined18+19 Doom/Film/window builds and final native widths, merged affected frame/proof checks and full flake. Verified local Frame width197 and controlledFilm203 remain below255. Root will delete this ticket after those gates pass. Immutable references and all failed/passed evidence remain in ignored `research/rocket18/`; no masks or output-derived values were used. No job is active or queued.
