# 15: Every monster missile, and the baron

**Tier:** 3

**What to build:** Typed monster missiles and vanilla baron attacks, pain, death and sounds. The shared missile path must run death-entry actions before randomizing explosion duration, including vertical impacts. E1M8 boss-death floor behavior belongs to ticket 19.

**Remaining:** Native checks, proof and gameplay/audio acceptance. Ticket 12's law and landing were approved on October 7.

**Status:** ready-for-agent

Typed spawn/impact metadata and baron rows 292–299 use projectile kind 4294967291. Runtime BAL7 loading now follows the existing spawn and hurt graph traversals alongside the other runtime effects. The shared missile callback runs the entered row's action before randomizing its duration; plain death rows preserve plain state entry.

- [ ] On E1M8, visible baron ball mid-flight and impact compare with Chocolate Doom with zero differing pixels.
- [ ] The imp's existing tests and frame pins pass unchanged on native and JavaScript.
- [ ] A baron's actual gameplay death compares with vanilla at rest.
- [ ] Baron sight, death, claw and missile attack events match Chocolate Doom audio exactly.
- [ ] Focused externally derived baron/callback checks pass on native and JavaScript; native game, frame and film builds measure remaining headroom under the 255-word limit.

Expected values come from installed Chocolate Doom source and WAD data. Rest-frame oracles remain zero; no masks or frame repins may hide mismatches.

The sim and source-derived focused baron JavaScript checks pass. Proof reached the known Enter-key binding mismatch from ticket 14; the reviewed one-expression correction is merged for retry. The earlier type-inventory expectation was corrected from a direct Freedoom E1M1 THINGS query; no behavior or frame pins changed. The queued native/proof batch was cancelled before acquisition for review scheduling. The loader fold still needs compilation through a graphics consumer. Proof, native checks/products/width, visual oracles and exact audio acceptance remain pending.
