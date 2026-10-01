# Orchestrating a milestone

Read this before you dispatch a milestone's tickets, overnight or not. You dispatch, review and integrate. Ticket agents follow `docs/agents/ticket-agent.md`, and its rules on the lock, commits and merges bind you too. Dates below are from 2026.

## Memory and the lock

- The machine has 30 GB, about 19 GB of it free beside the desktop and T3 Code. Peaks measured on 10-01: `bend doom.bend` to C 12.2 GB in 31 s, then clang 2.0 GB in 106 s; a test file 5.3 GB in 18 s, then 64 s of clang; `bend tools/frame.bend` 7.5 GB in 1:43; the proof 2.1 GB in 7 s; a JS backend test 2.1 GB. Nix max-jobs is 1. Two game compiles at once can exhaust memory, so heavy commands share one lock.
- Run at most 5 Claude agents, or 3 Codex workers plus the root. Nine agents at once got T3 Code OOM-killed twice on 09-19.
- Keep the cap and the lock even when Elies asks to lift them, and tell him the risk instead. He asked on 09-19 and 09-20, and the machine ran out of memory both times.
- The lock limits throughput, not the agent count. On 09-21 it was held 213 of 271 minutes, and agents spent at least 418 minutes queued for it.

## Dispatch

- Do not implement tickets. The Codex root did on 09-21. It spent 24% of the night's tokens, compacted 7 times in 4 hours, and had no green flake check after 02:19. Small corrections to code you review are fine. Elies said on 09-19 he does not trust agents to shape code well.
- Give each ticket a fresh agent. Agents handed follow-up tickets took 79 to 138 minutes and compacted 2 to 4 times. Fresh agents closed theirs in 43 to 52.
- Launch only the runnable tickets of the blocked-by DAG. Give only the prompts due now, never re-send one, and name every free slot.
- When you are Claude Code, ticket agents run on Opus, `model: "opus"`, to spare Elies' usage.
- The dispatch names the ticket, a fresh worktree and branch, the integration branch, the commit identity, the shared table rows the ticket may take, and the tickets it builds on.
- Review each finished ticket on two axes, standards and spec, with two reviewer agents in parallel. Each takes 1 to 14 minutes. Skip neither under a deadline. On 09-20 eleven tickets landed in "deadline mode" with regression pins where oracle values belonged, and later checks found seven real mismatches with vanilla.
- Rule out the oracle before reporting a sim divergence. On 09-21 a 72-pixel "gameplay mismatch" came from the frame oracle's attack press, which advanced Chocolate Doom's intermission.
- Keep your own messages sparse. The 09-21 root sent 156 in one night.

## Integration

- Only you run `nix flake check`, under the lock, and you repeat the oracle checks a merge affects. The check takes 16 to 28 minutes, so batch two or three merges per check. Keep a green check on the integration branch at least every two hours.
- Run tickets that change every frame hash one at a time. Each rewrites every hash, so any sibling conflicts with it.
- Reserve each parallel ticket's rows of shared numbered tables, such as state-table rows and sound ids, in its dispatch. The 09-21 run reserved rows 190 to 214 this way.

## Commits

- The dispatch names the identity `Elies <68759092+eliesgalvira@users.noreply.github.com>`, with no Co-Authored-By trailer. Agents commit with the configured identity, so check that `git var GIT_AUTHOR_IDENT` prints it before you dispatch.
- Audit the range's emails before landing it: `git log --format='%ae %ce' <base>..<tip> | sort -u`. On 09-21 a Codex agent guessed `elies@users.noreply.github.com`, another GitHub user, and wrote it into the `.git/config` every worktree shares.
- Never plan a later squash to clean up subjects. On 09-21, 59 of 144 landed commits had "Merge branch" subjects, and the squash never happened.
- Never push notes, research or session reports. A research file pushed on 09-21 took a history rewrite to scrub. Warn Elies before any history rewrite.

## Stops and budget

- Before the night, check usage, and check that the laptop is on AC and will not sleep. Usage caps stopped the runs of 09-18, 09-20 and 09-21, and a power loss cost 4 hours on 09-20.
- Track usage during the run. At about 85%, stop dispatching, merge what is green and write the handoff. On 09-21 Codex hit its weekly cap mid-turn at 05:51, with three workers mid-task and the integration branch only local.
- Never promise or schedule a timed resume. A cron resume on 09-19 never fired and cost two hours.
- Keep `research/<milestone>/state.md` current with agent ids, worktrees, branches and what each still owes, so a successor can resume after a stop.
- Resume an agent with a message telling it to check `git status` and `git diff`, rerun any interrupted heavy command, and follow any rule changed since its dispatch. Its worktree holds an older copy of these docs.

## Timing and scope

- Log each ticket to `research/<milestone>/timing.tsv`: dispatch time, finish time, minutes, lock-minutes if known, review-fix minutes and outcome.
- After each ticket, recompute the remaining DAG's projected finish from the measured medians, never from estimates. Estimates were 2 to 4 times off in both directions.
- Seed the medians from past runs. A fresh-agent ticket took 43 to 74 minutes. A sim-mechanics ticket took about 110, with a p90 near 250, mostly from merges in `src/sim.bend`. Verification against Chocolate Doom took about 40. Review fixes added 25 to 50.
- The milestone spec orders its deliverables in tiers. Target the furthest tier the latest projection finishes by the deadline, and dispatch no ticket outside it. If the spec has no tiers, ask Elies before the night, since scope cuts are his call.
- By the deadline, leave the integration branch green with a passing flake check. Write each unfinished ticket's status and remaining work back to the ticket.
