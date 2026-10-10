# 04: Assess music startup and transition timing

**Tier:** 1

**Blocked by:** None

**Status:** ready-for-agent

## Problem

Runtime WAD music is implemented and its synthesis checks pass. The film now advances the OPL chip through 4096 frames before starting music, about 93 ms at 44100 Hz, and song changes align to that buffer boundary. The old film started music at frame zero. Sound effects are mixed separately.

The lead matches a retained music-only Chocolate Doom capture. It is not a universal vanilla startup rule: startup depends on wall-clock timing, and the combined music/SFX device uses a different buffer size. Elies clarified on October 9 that his concern is a noticeable downgrade in playability or sound experience. A byte-level difference from the old film alone does not fail that criterion. He has not unconditionally approved the present timing.

## Acceptance

- Assess the practical effect of music startup, scene changes and SFX responsiveness against vanilla, reusing the retained waveform and performance evidence where it applies. Distinguish synthesized sample scheduling, device buffering and measured input-to-speaker latency.
- Establish whether the current path causes missing or cut-off sounds, sustained gaps, accumulating drift, or delayed gameplay effects. State which conclusions are measured and which remain perceptual judgments; do not claim to have listened when only samples were compared.
- If a defect affecting playability or sound is demonstrated, fix its cause and rerun the affected checks. Do not rewrite audio solely to reproduce incidental startup timing from one capture.
- Keep exact synthesis comparisons and vanilla's musical content intact. If human listening remains necessary, provide short, concrete comparison artifacts and the precise unresolved decision.
- Inspect the review note that `Stream.topped` has an unreachable empty-list case. Remove the invalid state if a simple checker-supported representation does so; otherwise explain the constraint without expanding this assessment into a broad refactor.

Delete this ticket when the practical concern is resolved. Keep detailed evidence in ignored research; earlier implementation evidence remains in Git and the episode handoff.
