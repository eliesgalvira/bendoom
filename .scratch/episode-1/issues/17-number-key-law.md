# 17: Prove selection for all five number keys

**Tier:** 3

**Status:** ready-for-agent

**Blocked by:** None

## Problem

`lowest_number_wins` currently states the result for first-held keys 1, 2 and 4, plus no key. It dropped the old key-3 case and does not cover key 5. Weapon selection is implemented, but the law leaves two supported cases unproved. Elies authorized strengthening the law on October 9.

## Acceptance

- State and prove the result for each first-held key from 1 through 5, with arbitrary higher keys held, and for none of the five supported keys held.
- Derive the command bits from Chocolate Doom's source before checking Bendoom's result. Preserve the existing lowest-key priority and runtime behavior.
- Run the proof and any affected checks under the shared lock and memory cap. Record the exact old and new declarations in ignored research for the integration report.
- Delete this ticket when verified; do not retain the weaker declaration or add duplicate assertions that merely mirror the proof.
