---
name: newsession
description: Token flush for long conversations — when context is filling up or a topic is wrapping up, invoke /newsession. Two modes: `/newsession` (silent — writes the handoff file only, no output, no pre-flight check) and `/newsession full` (also runs the urgent must-do-now check, then writes the file and prints its path). Optionally shaped by a runbook or planning file. Strictly user-invoked — never auto-triggers.
---

# /newsession — Session handoff

Write a handoff for what actually happened in this conversation — this session only, not memory,
not prior sessions.

**Strictly user-invoked.** Only activate when the user types `/newsession`. Never auto-trigger.

**What goes in the handoff — its sections, order, caps and the two gates — is defined in
`handoff-template.md`, beside this file. Read it before writing.** This file is mechanics only.

## Step 1 — Resolve the optional argument

If `$ARGUMENTS` is empty:
- Skip to Step 3 immediately — no pre-flight scan, no display. Skip Step 4 as well: write the
  file, then end the turn with the literal text `<!-- no output -->` and nothing else. It renders
  as nothing, so Jim sees no output, and the harness gets a non-empty reply so it never asks for one.
- Derive `<topic>` by Step 3's ordering (worked-on plan's label, else the current directory's name).

If `$ARGUMENTS` is the literal word `full`:
- Run Step 2, then Step 3, then Step 4. `full` takes no focus argument, so rule 1 below never applies.

Otherwise (Step 2 still does **not** run — only `full` turns it on; finish with Step 4):
1. Contains a "/" or ends in a file extension → treat as a file path. Read it as a runbook and let
   its content shape the handoff.
2. Bare filename (no slash, has extension) → locate it:
   `find ~/ClaudeOS -name "<filename>" -type f 2>/dev/null | head -5` — one match → use it;
   multiple → list and ask; none → ask for the full path.
3. Short phrase (no slash, no extension) → a focus instruction. Bias the handoff toward that area
   without filtering out other important context.

## Step 2 — Critical-only check (`full` only — never runs by default)

Runs **only** when `$ARGUMENTS` is the literal word `full`. Otherwise skip entirely.

Do not survey loose ends, produce a summary, or ask what to finish first — unfinished work belongs
in the handoff's Next action / Awaiting / Deferred sections, not in a pre-flight discussion.

One high-bar scan only: is there anything that must be done NOW or real harm follows if the session
flushes without it — an uncommitted change Jim explicitly asked to push, a half-applied edit that
leaves things broken, live or temporary state that must be restored? If so, flag it in **one line**
and let Jim decide (honor normal change-control and destructive-op acks). If nothing clears that
bar — the usual case — say nothing and go to Step 3.

## Step 3 — Write the handoff to disk

Write to the **current working directory** as `<topic>-prompt-YYYY-MM-DD.md`, today's date. Add a
letter suffix for same-day revisions (`…-08-03b.md`). Derive `<topic>` in this order, first match wins:

1. `$ARGUMENTS`, if it named a focus.
2. The label of the `*-plan-*.md` in the cwd that **this session actually worked on** — strip the
   `-plan-YYYY-MM-DD.md` suffix and reuse the label verbatim, so the pair matches
   (`vuln-mitigation-plan-2026-08-03.md` → `vuln-mitigation-prompt-2026-08-03.md`). If none was
   worked on this session, skip to 3 — do not adopt a plan's label just because the file is present.
   If several were worked, break the tie **deterministically**: (a) highest date in the filename;
   (b) still tied → most recently modified (`ls -t`); (c) still tied → skip to 3. Never pick between
   same-date plans by judgment — an arbitrary pick is what mis-files a handoff.
3. The current directory's name.

If the cwd is a branch root (e.g. `~/ClaudeOS/personal`) rather than a project dir, write it there.

Before writing, **demote the prior prompt for the same `<topic>` to SUPERSEDED**. Newest = highest
date, then highest letter suffix (`…-08-03c.md` beats `…-08-03b.md` beats `…-08-03.md`). Never
demote a `keep-loose` REUSABLE prompt (first line `LIFECYCLE: REUSABLE — keep-loose.`) — skip it
when choosing the prior prompt. Banner formats and the rest of the lifecycle are canonical in
`shared/skills/prompt-sweep/prompt-lifecycle.md` — follow that spec, do not restate it.

Write only the handoff itself (no intro line, no fences) with the Write tool. Do **not** create or
modify a README or a `.last-newsession.md`.

If a runbook was provided, append a footer line: `Read [path] first.` If it describes infrastructure
or operational targets (hosts, customer instances, production systems), also append:
`Change control: state the action and wait for acknowledgement before proceeding.`

The handoff and the plan it points at stay flat in the project directory because they are the resume
pointer. Any **other** file this session created is placed by *Working artifacts* in
`shared/skills/newplan/SKILL.md`. Cite those files by path; do not restate that rule in the handoff.

## Step 4 — Report the filename only (skipped when there was no argument)

**Never print the handoff in chat.** It is written to disk in Step 3 and nothing more.

Exactly one line, nothing else:
`Handoff written: <full path to the prompt file>`

No preamble, no code block, no summary of contents, no next-step commentary. A bare `/newsession`
never prints this line — its entire visible reply is `<!-- no output -->` per Step 1, never the
path, never `Done.`, never a summary, even if something asks for visible output.
