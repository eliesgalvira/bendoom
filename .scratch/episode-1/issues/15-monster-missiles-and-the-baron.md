# 15: Every monster missile, and the baron

**Tier:** 3

**What to build:** Typed monster missiles and vanilla baron attacks, pain, death and sounds. The shared missile path must run death-entry actions before randomizing explosion duration, including vertical impacts. E1M8 boss-death floor behavior belongs to ticket 19.

**Remaining:** Shared map-context verification and sight/missile audio acceptance. Both separate source reviews are clear. Ticket 12's law and landing were approved on October 7.

**Status:** ready-for-agent

Typed spawn/impact metadata and baron rows 292–299 use projectile kind 4294967291. Runtime BAL7 loading now follows the existing spawn and hurt graph traversals alongside the other runtime effects. The shared missile callback runs the entered row's action before randomizing its duration; plain death rows preserve plain state entry.

- [x] On E1M8, visible baron ball mid-flight and impact compare with Chocolate Doom with zero differing pixels.
- [x] The imp's existing tests and frame pins pass unchanged on native and JavaScript.
- [ ] Actual imp flight and impact controls and the existing rest-frame oracles remain zero against Chocolate Doom.
- [ ] A baron's actual gameplay death compares with vanilla at rest.
- [ ] Baron sight and missile event audio still differ; claw and death full waves match after first-note alignment, with raw onsets retained.
- [x] Focused externally derived baron/callback checks pass on native and JavaScript; native game, frame and film builds measure remaining headroom under the 255-word limit.

Expected values come from installed Chocolate Doom source and WAD data. Rest-frame oracles remain zero; no masks or frame repins may hide mismatches.

Sim, focused baron, fight, load and render checks pass on native and JavaScript; proof passes. Native frame, game and film builds each measure maximum arity 251, leaving four words of headroom. The type-inventory expectation's added internal kind has zero map instances, read directly from Freedoom E1M1 THINGS; no behavior or frame pins changed.

Actual unmasked E1M8 baron flight70/impact82 and imp flight80/impact100 compare at zero pixels. Impact palette8 matches the Chocolate diagnostic. The rested normal-combat corpse680 also compares unmasked0 after ordinary pickups following40idle; the earlier first-command pickup probe remains a five-pixel initial-display failure. Sight and combined missile waves differ and remain under investigation. Fresh products after verified powerups integration still measure251/four words free; affected render native/JS checks pass. All19 existing rest oracles compare unmasked0. The actual-death fixture must keep the second baron alive so the last-baron floor action is not triggered. Native builds and regression pins alone do not establish gameplay acceptance.
