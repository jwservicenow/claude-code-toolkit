---
name: newsession
description: Token flush for long conversations — when context is filling up or a topic is wrapping up, invoke /newsession. Two modes: `/newsession` (full — scans for loose ends, writes file, displays handoff block) and `/newsession fast` (silent — writes file only, no scan, no output). Optionally shaped by a runbook or planning file. Strictly user-invoked — never auto-triggers.
---

# /newsession — Session handoff

Look at what actually happened in this conversation (this session only — not memory, not prior sessions).

**Strictly user-invoked.** Only activate when the user types `/newsession`. Never auto-trigger.

## Step 1 — Resolve the optional argument

If `$ARGUMENTS` is the literal word `fast`:
- Skip to Step 3 (Save) immediately — no argument processing, no pre-flight scan, no display.
- Derive `<topic>` from the current directory's name.

Otherwise, if `$ARGUMENTS` is provided, determine how to treat it:
1. If it contains a "/" or ends in a file extension, treat as a file path — read it as a runbook and let its content shape the handoff.
2. If it's a bare filename (no slash, has extension), locate it: `find ~/ClaudeOS -name "<filename>" -type f 2>/dev/null | head -5` — one match → use it; multiple → list and ask; none → ask for full path.
3. If it's a short phrase (no slash, no extension, one or more words), treat as a focus instruction — bias the handoff toward that topic/area without filtering out other important context.

## Step 2 — Loose-ends pre-flight (finish-now vs defer)

Before writing the handoff, scan THIS session for unfinished work and judge each item:
is it cheaper or safer to finish NOW — in this warm session with full context — than to
hand it to a cold one? Surface them so the user decides, then act on their choice.

Better finished now (offer to complete before flushing):
- a change the user wanted committed/pushed but isn't yet;
- a half-applied edit, deploy, or migration left mid-step;
- a quick verification/test whose result would change what the handoff says;
- cleanup or restore of temporary/test state created this session.

Fine to defer (do NOT do now — record in Deferred / Next action instead):
- substantial new work; anything needing a user decision; anything blocked on input.

Show a short two-list summary ("Better done now: …" / "Deferring: …"). If there are
now-items, ask whether to complete them first (honor normal change-control and
destructive-op acks). If there are none, say "clean — nothing better done now" and
continue. Never block on this — it's a gate for the user's benefit, not a chore.

## Step 3 — Save the handoff to disk

Save the generated handoff prompt as a standalone prompt file — this becomes the project's resume point. Mirror `/newplan`'s naming:
- Write to the **current working directory** (the project being worked on) as `<topic>-prompt-YYYY-MM-DD.md` with today's date. Derive `<topic>` from `$ARGUMENTS` if it named a focus, otherwise from the current directory's name.
- If the cwd is a branch root (e.g. `~/ClaudeOS/personal`) rather than a project dir, write the file there as the fallback.
- The newest-dated `*-prompt-*.md` for a project is its resume pointer. Before writing the new prompt, **demote the prior same-project prompt to SUPERSEDED**: prepend the banner `STATUS YYYY-MM-DD — SUPERSEDED by <new-prompt-filename>.` (today's date) as its first line. Do **not** delete it — `/prompt-sweep` archives superseded prompts later, with the user's approval. **Never demote a `keep-loose` REUSABLE prompt** (first line `LIFECYCLE: REUSABLE — keep-loose.`) — skip it entirely when choosing the prior prompt.

Write only the contents of the handoff prompt (no intro line, no fences) to the file with the Write tool. Do **not** create or modify a README or a `.last-newsession.md`.

The prompt lifecycle (states, banner formats, when things get archived) is defined once in `shared/skills/prompt-sweep/prompt-lifecycle.md` — follow that spec; do not restate its rules here.

## Step 4 — Display the handoff prompt

Generate and display a dense, structured handoff prompt the user can paste as the first message of a new Claude Code session.

Output format:
- One line OUTSIDE the code block: `Paste this into a new Claude Code session to resume:`
- A single fenced markdown code block containing the handoff prompt.
- No other commentary.

Inside the code block — strip all fluff, filler words, pronouns, polite transitions. Aggressive shorthand, bullets, high-density keywords. Plain-text section labels (no markdown bold/asterisks), each on its own line ending with a colon. Content follows on the next line(s). Omit any section with nothing real to say. **Cap at 300 words** inside the block.

Sections:

Goal:
One sentence — what this work is trying to accomplish.

State & decisions:
Locked decisions, technical configs, architecture choices. No re-litigation needed.

Constraints:
Active rules or guardrails agreed to this session. One line each.

Previous session:
Bullet list — what was actually done this session, past tense. Skip anything done before this session started.

Next action:
Single most immediate thing to do. Enough context to execute without re-reading history. If a verification or test result is pending, include the pass/fail criteria and what each outcome means — not just the command to run.

Awaiting:
Only if the session ends blocked on user input. One sentence — what's blocked and what input is needed.

Deferred:
Topics discussed but intentionally parked. One line each — prevents the next session from re-litigating resolved decisions.

Key artifacts:
Only what's needed for the next action — file paths, IPs, sys_ids, commands, URLs. Include verbatim any lookup tables, slot maps, or ID-to-name mappings needed to interpret next-session output — do not summarize these into prose.

Resume instruction:
Direct instruction to future Claude: exactly how to pick up, first move, no preamble.

If a runbook was provided, add a footer line: `Read [path] first.` If the runbook describes infrastructure or operational targets (hosts, customer instances, production systems), also add: `Change control: state the action and wait for acknowledgement before proceeding.`
