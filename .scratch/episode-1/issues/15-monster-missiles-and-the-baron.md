# 15: Every monster missile, and the baron

**Tier:** 3

**What to build:** Typed monster missiles and vanilla baron attacks, pain, death and sounds. The shared missile path must run death-entry actions before randomizing explosion duration, including vertical impacts. E1M8 boss-death floor behavior belongs to ticket 19.

**Blocked by:** Explicit approval of ticket 12's reviewed law changes before either branch lands. Longer ticket 15 acceptance waits for root's next release.

**Status:** ready-for-agent

Typed spawn/impact metadata and baron rows 292–299 use projectile kind 4294967291. Runtime BAL7 sprite loading is mandatory unfinished source work: the sprite loader currently marks the imp ball and teleport fog explicitly, so the new definition alone does not load the baron ball. Add its flight and death graphs through the existing traversal before any rendering acceptance.

- [ ] On E1M8, visible baron ball mid-flight and impact compare with Chocolate Doom with zero differing pixels.
- [ ] The imp's existing tests and frame pins pass unchanged on native and JavaScript.
- [ ] A baron's actual gameplay death compares with vanilla at rest.
- [ ] Baron sight, death, claw and missile attack events match Chocolate Doom audio exactly.
- [ ] Focused externally derived baron/callback checks pass on native and JavaScript; native game, frame and film builds measure remaining headroom under the 255-word limit.

Expected values come from installed Chocolate Doom source and WAD data. Rest-frame oracles remain zero; no masks or frame repins may hide mismatches.

Validation is unverified. The first sim JavaScript comparison failed only because the new internal projectile kind was absent from the type-inventory expectation. Its zero count was confirmed directly from Freedoom E1M1 THINGS and the expectation was corrected. The retry did not run and proof/native/captures remain pending.
