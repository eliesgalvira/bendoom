# Working a ticket

Read `AGENTS.md`, `docs/bend.md`, the ticket and its spec if present.
The dispatch names the worktree, branch, integration branch and commit identity. Work only in that worktree and never push; the orchestrator merges your branch. Kill only processes you started.

Use `nix develop -c <command>` for the toolchain. The dev shell uses Freedoom. Keep game code in Bend; use Nushell for tools and scratch calculations.
Scratch files and research go in the worktree's ignored `research/`, never `/tmp`. Reboots wiped `/tmp` on 2026-09-19 and 09-20.

## Memory

One game compile peaks at 12 GB, and the machine has about 19 GB free, so heavy commands share one lock.

- Run these under `flock /tmp/bendoom-heavy.lock`: every Bend compile, including `--check-only`, test files and `tools/frame.bend`; every clang compile; every `nix build`; and the proof, as `flock /tmp/bendoom-heavy.lock nix develop -c bend PROOF.bend`.
- Wait for the lock in one foreground command with your tool's longest timeout, and rerun it if the timeout ends it. Never poll with `pgrep`, and never end your turn while queued.
- Never run heavy jobs in parallel yourself. Six proofs under `xargs -P 6` rebooted the machine on 2026-09-19.
- Never run `nix flake check`. The orchestrator runs it on the integration branch.

## Verification

- Use Chocolate Doom's source or WAD data for expected values, as `AGENTS.md` requires.
- Run affected Bend tests on native and JavaScript backends; `nix/tests.nix` defines both.
- Check changed rendering against `tools/oracle.nu`. Build the frame dump first and pass its path with `--frame`. Regenerate frame hashes only after the oracle reports zero differing pixels.
- Run one oracle run or audio capture at a time. Parallel runs failed, and under load sound timing slipped by up to 116 ms. A display you start is a private Xvfb numbered by `-displayfd`, as `tools/oracle.nu` does.
- Never touch the desktop's audio sinks or windows. A null sink loaded on the desktop at 04:38 on 2026-09-21 stayed until the next afternoon.
- Run the proof when you change laws or proofs.

## Commits and merges

- Commit with a conventional prefix and no co-author trailer, as the identity the dispatch names. Check it with `git var GIT_AUTHOR_IDENT`, and stop and report if it differs. Never run `git config` or `git -c user.email`. Every worktree shares `.git/config`, and a guessed email reached it on 2026-09-21.
- Add record fields at the end of a record, so sibling branches merge cleanly.
- As your last step, merge the integration branch into yours and rerun the affected checks. Branches left waiting on 2026-09-20 hit a 23-hunk conflict in `src/sim.bend`, and one ticket was abandoned 28 commits behind.
- Give a merge commit a real subject, never `git merge --no-edit`. On 2026-09-21, 59 of 144 landed commits had "Merge branch" subjects.
- Before committing a merge, `git grep -nE '^(<<<<<<<|=======|>>>>>>>)( |$)'` must print nothing. `LAWS.bend` and `PROOF.bend` were committed with markers on 2026-09-23.

## Handoff

Update an unfinished ticket with blockers or missing evidence. Once verified complete, delete it; keep session reports out of tracked documentation.
Send one final report: commit hashes, checks run, failures and remaining work. Each message costs the orchestrator context.
