# Bendoom

Doom (E1M1) written in Bend 2, packaged as a Nix flake. The single λ-expression version is Hellbent.

## Erasure

This section exists to amend your most glaring defect. You are a model trained by a big lab, and these labs neglect one fundamental half of intelligence: ERASURE. Every reward you ever received was for ADDING something -- an answer, a file, a patch, a comment, a rule. Almost none was for REMOVING. So you add by reflex and never subtract, and no amount of raw capability compensates for a missing half.

Why half? Because learning IS compression. A good abstraction is precisely a blob of information that lets you throw other information away, because it expands back into what was discarded. An aha-moment happens when your brain is capable of expressing new information in terms of information you already possess. This is what allows that info to be stored. That is how you learn. Intelligence is not producing knowledge; it is deleting bad knowledge so the good remains. This defect manifests wherever anything under your care only ever grows -- code, comments, docs, notes, memory. Unpruned growth is the symptom.

So install this now: erasure claims HALF of your cognitive budget for this task. While working on my code -- even autonomously, even mid-task -- hunt for things to remove: duplicated concepts to unify, dead code to delete, tangled logic to simplify. Your own confusion is a precision instrument: if something surprised you or was hard to follow, that IS a bad abstraction, and you should TAKE ACTION and untangle it on the spot. When writing new code, spend real effort finding the simplest possible shape, and scan the codebase first to reuse what exists rather than introduce a redundant concept. A diff that removes lines is at least as valuable as one that adds them.

The swap rule: when a task replaces X with Y -- a refactor, a fix, a syntax change -- fully deleting X is PART of the task, always. Keeping the old thing "for compatibility" is NEVER desirable unless explicitly requested. A bug fix -- bad: a special-case `if` shields the symptom; good: the design is re-derived, the cause dies, the `if` never exists. A behavior change -- bad: tests for the old behavior linger or get dodged; good: obsolete tests deleted, the rest updated.

For coding, a more effective way is to take a big codebase and ask it to make it shorter, while still preserving the same behavior. IMPORTANT: avoid code-golfing / minification / uglification. Removing comments or making variable names shorter IS reward hacking. Counter that by counting the NUMBER OF BRANCHES. A branch is: an "if", a "match", a "case". That's THE complexity of your program.

Comments are where you fail hardest. You narrate code with comments in the middle of function bodies -- that is NOT allowed; if you catch yourself doing it, clean it up. You also accumulate comments and never remove them, clogging files. Be aggressive: keep only what is truly essential. A refactor makes a comment stale -- bad: it stays, now lying; good: deleted or rewritten in the same diff. A TODO gets done -- bad: the marker remains; good: it leaves with the fix.

Prose rots the same way: every AGENTS.md, MEMORY.txt and wiki article tends to only grow -- rules added when something breaks, never removed when they stop applying. A server is decommissioned -- bad: its article sits forever; good: article deleted, every link fixed. MEMORY.txt nears its cap -- bad: append anyway; good: GC by importance, promote what lasts to the wiki. A TODO.md item closes -- bad: the line lingers; good: deleted on sight. Before finishing ANY task, ask: what did this change make obsolete -- and did I delete it?

These rules bind, but they do not exhaust the defect. It is baked into your training, so no list can enumerate every place it surfaces -- watch for unpruned growth everywhere, including in places this file never mentions.

## Agent skills

### Documentation

Keep tracked docs to current usage, constraints and open work. Delete completed tickets and stale notes; Git keeps their history. Only keep research that cannot be recovered cheaply from code or Git, under ignored `research/`. Never force-add or publish that directory.

### Issue tracker

When creating or updating a ticket, use `docs/agents/issue-tracker.md`. Open issues live under `.scratch/<feature>/`.

When dispatching ticket agents, include `docs/agents/ticket-agent.md` in their instructions. Before orchestrating a milestone, read `docs/agents/orchestrator.md`.

### Bend constraints

Read `docs/bend.md` before writing Bend code or proofs: what the checker refuses, and the shapes that pass.

### Checking the game

Vanilla is the oracle. A frame is right when `tools/oracle.nu x y degrees` reports no differing pixel against Chocolate Doom at that spot; it runs headless (Xvfb) and needs `bend tools/frame.bend -o frame` first. Every rest position in `tests/render.bend` must stay at zero.

Expected values come from outside the code under test: read the WAD in nushell, or compute by hand from vanilla's source, before the Bend code answers. Values with no oracle are regression pins, and the ticket says so.

Automated checks never open a window or move focus on the desktop. A program that needs a display runs on Xvfb. `tools/screenshot.nu [keys...] [--binary path] [--wait duration]` and the game's window are for mechanics and gameplay QA only: it runs the game, holds keys, and screenshots its window through niri; the X root is black under Xwayland, so X capture tools show nothing.
