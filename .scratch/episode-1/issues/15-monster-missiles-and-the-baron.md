# 15: Every monster missile, and the baron

**Tier:** 3

**What to build:** Typed monster missiles and vanilla baron attacks, pain, death and sounds. Missile death-entry actions run before explosion-duration randomization, including vertical impacts. E1M8 boss-death floors belong to ticket19.

**Status:** ready-for-agent

**Remaining:** Resolve sight/missile whole-wave audio using externally traced event and callback schedules, then run final gameplay/rest oracles on the integration candidate. Affected native/JavaScript suites, proof and native products pass. Both source review axes are clear.

Rows292–299 and projectile kind4294967291 are reserved for this ticket. Level.Geo owns the loaded Level.Name; Playing derives its identity from that level. Sound attenuation follows vanilla's gamemap8 rule. Native frame, game and window benchmark products measure197 words, leaving58 under the255-word limit; Film measures203, leaving52.

Reproducible E1M8 oracle cases use the same WAD fixtures in both games:

- Baron flight70 and impact82: player224,2592 facing0; baron record58 at608,2592 facing180. Impact selects palette8.
- Imp flight80 and impact100: replace record58 with an imp at the same position and facing.
- Actual rested corpse680: player416,2528 facing90; baron58 at416,2704 facing270. Commands: `40,0,0,0,0 1,25,0,0,0 39,0,0,0,0 520,0,0,0,2 80,0,0,0,0`, with normal shotgun, shells, armour and health pickups. Keep record59 an actual living baron at-128,-224, out of view, so the last-baron floor action cannot run.

These feature cases and all19 existing rest positions compare with zero unmasked pixels before the context correction. Repeat the affected comparisons on the final source. Expected positions, tics, states and audio come from Chocolate Doom and WAD data; no masks or output-derived repins may hide differences.

Claw and death full sound waves match after first-note alignment. Sight and combined projectile waves remain unresolved. Preserve uncropped waves and raw onsets; aligned waveform equality does not settle ticket04's buffer-lead decision.
