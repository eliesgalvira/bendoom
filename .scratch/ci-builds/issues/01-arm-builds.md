# Complete the ARM CI builds

Status: ready-for-agent

## Problem

Build run 39664520715 at 73935ed2 passed proofs and tests on all three
platforms, but ARM Linux killed Bend while generating C for the film exporter
with builder exit 137. macOS completed the film compiler and then exceeded
the 120-minute job limit while compiling the game. Linux x86-64 passed.

## Acceptance

- Diagnose the compiler resource failure with a measured reproducer or remote
  resource evidence. Distinguish confirmed causes from hypotheses.
- Make ARM Linux and macOS complete the existing proof, native/JavaScript,
  exporter, game, portable archive and runtime-dependency checks in CI.
- Preserve all three platforms, release gating and current game behavior.
- Keep the locked toolchain and serial build policy. Do not hide failures,
  remove required outputs, or raise local memory caps.
- Prefer a small change supported by measurements. Record verification in
  ignored research and delete this ticket when the work is complete.

## Reproduction

https://github.com/eliesgalvira/bendoom/actions/runs/39664520715

The failing command is `nix build -L .#bendoom .#bendoom-freedoom .#film
.#film-freedoom --no-link`. The workflow runs it after `nix flake check -L`.
The macOS annotation states that the job exceeded its two-hour limit.

Blockers: hosted ARM Linux and macOS acceptance remains pending. ARM Linux
still killed Bend during film C emission after adding 4 GiB of swap. The
failure-only kernel query used an invalid option, so the hosted kill's cause
remains unconfirmed. The next run samples compiler RSS high-water marks,
process limits, cgroup limits/events and memory pressure, and collects kernel
and systemd-oomd evidence with supported commands. Keep the 240-minute budget
until macOS completion is known. Local memory-cap comparisons and generated-C
hashes are retained in ignored research; they do not establish the ARM cause.
