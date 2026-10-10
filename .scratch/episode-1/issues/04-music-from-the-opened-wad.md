# 04: Judge the remaining music timing difference

**Tier:** 1

**Blocked by:** Elies' practical sound judgment

**Status:** ready-for-human

## Open decision

Runtime WAD music and controlled effects match vanilla within the retained synthesis checks. No practical defect is demonstrated. Keep the current implementation unless listening establishes a noticeable downgrade in playability or sound experience, Elies' clarified criterion. He has not unconditionally accepted the present timing.

The film advances the OPL chip4096 frames before starting music, approximately93ms, and song changes retain already synthesized old-song samples through that buffer boundary. This changes onset and OPL phase relative to the old exporter. Repeated requests for the same song bypass `Song.change`, so scene selection does not postpone a restart indefinitely. Effects mix separately; the music lead does not add93ms to every gunshot. Already queued audio still precedes newly heard effects.

Retained full-score and first-loop comparisons show exact synthesis without internal gaps or accumulating drift. Controlled effects and channel traces match vanilla, including expiration and eviction. Native E1M6/E1M9 runs show no post-start underruns or lost tics. These checks do not measure input-to-speaker latency. No listening or perceptual-equivalence claim is made.

## Concrete comparison

The final assessment worktree's ignored [assessment](../../../../bendoom-e1-04-audio-final/research/audio-assessment/assessment.md) and [clip provenance](../../../../bendoom-e1-04-audio-final/research/audio-assessment/clips.json) bind these excerpts, with unchanged rate, channels and level:

- Actual retained Freedoom film startup, first3seconds: [old exporter](../../../../bendoom-e1-04-audio-final/research/audio-assessment/startup-old-freedoom.wav) and [runtime exporter](../../../../bendoom-e1-04-audio-final/research/audio-assessment/startup-runtime-freedoom.wav). First nonzero frame443 versus4536 exposes the approximately93ms onset difference and changed OPL phase. These are historical outputs rather than fresh final-runtime captures.
- Current stock-Doom controlled transition,3.657seconds: [production Film14](../../../../bendoom-e1-04-audio-final/research/audio-assessment/transition-current-doom.wav) and [vanilla](../../../../bendoom-e1-04-audio-final/research/audio-assessment/transition-vanilla-doom.wav). They are byte-identical, retain E1M1→INTER→E1M2 cues at1.02857seconds and2.8seconds, and deliberately silence effects. They do not measure native device or wipe timing.

Does the short later music onset or old-song continuation at these scene changes noticeably worsen the sound experience? Delete this ticket once that concern is resolved; do not rewrite audio solely to reproduce incidental vanilla startup timing.

## Representation constraint

`Stream.topped`'s empty deck case is unreachable from its producers. The singleton list is the established recursive pointer holder that avoids native arity expansion, documented in `docs/bend.md`. A custom recursive holder's checker and native representation are unverified. No simple demonstrated replacement was found in the bounded source audit, so this assessment does not attempt that refactor.
