# 18: The rocket launcher and its blast

**Tier:** 3

**What to build:** the rocket launcher fires rockets as vanilla's `A_FireMissile`, through the general missile spawn from ticket 15, and a rocket's explosion damages everything in its radius, the player included, reusing the radius damage the barrels use. Key 5 selects it if owned.

**Blocked by:** 15, 17 (both change weapon selection)

**Status:** ready-for-agent

- [ ] A scripted demo fires a rocket at a wall and at a monster; frames at the rocket mid-flight and at the explosion match Chocolate Doom with zero differing pixels.
- [ ] Firing a rocket at a wall next to the player hurts the player as vanilla's does.
- [ ] The README's controls table lists key 5.
