# 18: The rocket launcher and its blast

**Tier:** 3

**What to build:** the rocket launcher fires rockets as vanilla's `A_FireMissile`, through the general missile spawn from ticket 15, and a rocket's explosion damages everything in its radius, the player included, reusing the radius damage the barrels use. Key 5 selects it if owned.

**Blocked by:** 15, 17 (both change weapon selection)

**Status:** ready-for-agent

- [ ] A scripted demo fires a rocket at a wall and at a monster; frames at the rocket mid-flight and at the explosion match Chocolate Doom with zero differing pixels.
- [ ] Firing a rocket at a wall next to the player hurts the player as vanilla's does.
- [ ] The README's controls table lists key 5.

## Where it stopped

Branch `e1-18`, worktree `/home/bigweld/Repos/bendoom-e1-18`, based on integration `54288b2`. Commit `fb3caac` saves the partly verified launcher; `acda90d` adds the unverified shared vertical clamp and floor/ceiling height assertions. Launcher and rocket rows300–313, shared missile spawn/first-step and barrel radius damage are implemented. Key5 and README/browser controls are updated.

Last verified checks: source term checking and proof passed before the final ammo/sprite corrections. After those corrections, rocket, baron and key-selection tests passed on native and JavaScript, and Frame rebuilt, ending2026-10-08 11:10:53 Madrid. An earlier wall80 comparison failed because launcher ammo used cells instead of rockets; corrected ammo and sprite roots have not yet been compared. No zero-pixel or waveform-equality claim.

Remaining: verify the vertical clamp and affected imp/baron/missile paths on native and JavaScript; rebuild Frame for the latest source; compare wall flight/blast, monster direct/radius damage and near-wall self-damage frames and active palettes against the preserved Chocolate references. Compare complete controlled launch/blast audio and independently generated events. Build final game/Film/window products, measure native widths, run independent Standards/Spec reviews and integration checks. Merge the current integration branch before final verification. Source inputs and failed/passed external evidence remain in ignored `research/rocket18/`. No job is active or queued.
