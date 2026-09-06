---
name: newsession
description: Token flush for long conversations — when context is filling up or a topic is wrapping up, invoke /newsession. Two modes: `/newsession` (silent — writes the handoff file only, no output, no pre-flight check) and `/newsession full` (also runs the urgent must-do-now check, then writes the file and prints its path). Optionally shaped by a runbook or planning file. Strictly user-invoked — never auto-triggers.
---

# /newsession — Session handoff

Look at what actually happened in this conversation (this session only — not memory, not prior sessions).

**Strictly user-invoked.** Only activate when the user types `/newsession`. Never auto-trigger.

## Step 1 — Resolve the optional argument

If `$ARGUMENTS` is empty:
- Skip to Step 3 (Save) immediately — no pre-flight scan, no display. Skip Step 4 as well: write the file, then end the turn with the literal text `<!-- no output -->` and nothing else. It renders as nothing, so the user sees no output, and the harness gets a non-empty reply so it never asks for one.
- Derive `<topic>` by Step 3's ordering (worked-on plan's label, else the current directory's name).

If `$ARGUMENTS` is the literal word `full`:
- Run Step 2, then Step 3, then Step 4.
- Derive `<topic>` by Step 3's ordering — `full` takes no focus argument, so rule 1 never applies.

Otherwise, if `$ARGUMENTS` is provided, determine how to treat it (Step 2 still does **not** run — only `full` turns it on; finish with Step 4):
1. If it contains a "/" or ends in a file extension, treat as a file path — read it as a runbook and let its content shape the handoff.
2. If it's a bare filename (no slash, has extension), locate it: `find ~/ClaudeOS -name "<filename>" -type f 2>/dev/null | head -5` — one match → use it; multiple → list and ask; none → ask for full path.
3. If it's a short phrase (no slash, no extension, one or more words), treat as a focus instruction — bias the handoff toward that topic/area without filtering out other important context.

## Step 2 — Critical-only check (`full` only — never runs by default)

This step runs **only** when `$ARGUMENTS` is the literal word `full`. Otherwise skip it entirely.

Even under `full`: **just write the handoff and report its path** (Steps 3–4). Do not survey loose
ends, do not produce a two-list summary, do not ask what to finish first. Unfinished work
belongs in the handoff's Next action / Deferred sections, not in a pre-flight discussion.

The **only** exception: a single high-bar scan for anything genuinely urgent that must be
done NOW or real harm follows if the session flushes without it — e.g. an uncommitted
change the user explicitly asked to push, a half-applied edit that leaves things broken, or
live/temporary state that must be restored. If — and only if — such an item exists, flag it
in **one line** before writing and let the user decide (honor normal change-control and
destructive-op acks). If nothing clears that bar (the usual case), say nothing and proceed
straight to Step 3.

## Step 3 — Save the handoff to disk

Save the generated handoff prompt as a standalone prompt file — this becomes the project's resume point. Mirror `/newplan`'s naming:
- Write to the **current working directory** (the project being worked on) as `<topic>-prompt-YYYY-MM-DD.md` with today's date. Derive `<topic>` in this order, first match wins:
  1. `$ARGUMENTS`, if it named a focus.
  2. The label of the `*-plan-*.md` in the cwd that **this session actually worked on** — strip the `-plan-YYYY-MM-DD.md` suffix and reuse the label verbatim, so the pair matches (`vuln-mitigation-plan-2026-08-03.md` → `vuln-mitigation-prompt-2026-08-03.md`). If none was worked on this session, skip to 3 — do not adopt a plan's label just because the file is present. If several were worked, break the tie **deterministically, in this order**: (a) highest date in the filename; (b) still tied → most recently modified on disk (`ls -t`); (c) still tied → skip to 3 and use the directory name. Never pick between same-date plans by judgment — an arbitrary pick is what mis-files a handoff.
  3. The current directory's name.
- If the cwd is a branch root (e.g. `~/ClaudeOS/personal`) rather than a project dir, write the file there as the fallback.
- The newest `*-prompt-*.md` for a topic is its resume pointer — **newest = highest date, then highest letter suffix** (`…-08-03c.md` beats `…-08-03b.md` beats `…-08-03.md`). Before writing the new prompt, **demote the prior prompt for the same `<topic>` to SUPERSEDED**: prepend the banner `STATUS YYYY-MM-DD — SUPERSEDED by <new-prompt-filename>.` (today's date) as its first line. Do **not** delete it — `/prompt-sweep` archives superseded prompts later, with the user's approval. **Never demote a `keep-loose` REUSABLE prompt** (first line `LIFECYCLE: REUSABLE — keep-loose.`) — skip it entirely when choosing the prior prompt.

Write only the contents of the handoff prompt (no intro line, no fences) to the file with the Write tool. Do **not** create or modify a README or a `.last-newsession.md`.

The handoff prompt is the one exception to the working-artifacts rule — like the plan it points at, it stays flat in the project directory because it is the resume pointer. **Any other file this session created goes by `/newplan`'s *Working artifacts* section** (`shared/skills/newplan/SKILL.md`): `<topic>-<kind>-YYYY-MM-DD.md`, durable at the project root, ephemeral in `<project>/run/`. Do not restate that rule in the handoff — cite the artifacts by path and let the convention do the rest.

The prompt lifecycle (states, banner formats, when things get archived) is defined once in `shared/skills/prompt-sweep/prmpt-lifecycle.md` — follow that spec; do not restate its rules here.

## Step 4 — Report the filename only (skipped when there was no argument)

**Never print the handoff prompt in chat.** It is written to disk in Step 3 and nothing more.

Output format — exactly one line, nothing else:
`Handoff written: <full path to the prompt file>`

No preamble, no code block, no summary of the handoff's contents, no next-step commentary.
(A bare `/newsession` never prints this line. Its entire visible reply is `<!-- no output -->`
per Step 1 — never the path, never `Done.`, never a summary, even if something asks for
visible output.)

## Handoff prompt content (written to the file in Step 3)

Generate a dense, structured handoff prompt the user can paste as the first message of a new Claude Code session.

Strip all fluff, filler words, pronouns, polite transitions. Aggressive shorthand, bullets, high-density keywords. Plain-text section labels (no markdown bold/asterisks), each on its own line ending with a colon. Content follows on the next line(s). Omit any section with nothing real to say. Length is set by how much real state there is, up to the hard ceiling below. Never drop a path, ID, command, or lookup table to make it shorter; cut prose and duplication instead.

**Scope to the live thread — "cut prose, not data" applies only to work the Next action can touch.** That rule assumes the paths are still live. It is not a licence to carry forward every command and lookup table the session ever used, and applying it to retired work is what turns a handoff into an archive of its own history.

A thread **closed during this session** — decided, executed, verified, and written into a durable artifact — does not carry its mechanics forward. It compresses to **one line**: that it is closed, that it must not be reopened, and where the detail permanently lives (a findings doc, an inventory entry, a commit hash). Its hosts, ports, tokens, endpoint quirks, and trap lists stay in that artifact. Promoting them into the handoff duplicates the artifact and buries the one thing the next session actually needs.

Test each block before keeping it: **could the Next action plausibly touch this?** If the answer is no because the thing was just shut down, deleted, rejected, or superseded, it is not state — it is history, and history belongs in the artifact the closure step already wrote.

Traps and hard-won corrections are the one judgement call: keep a trap only if it can still bite the *next* action. A trap about infrastructure the session just retired goes with the rest of that thread.

**Do not duplicate the artifacts this handoff points at.** The rules above catch *retired* work. This one catches the opposite failure: an artifact that is fully live, whose contents therefore pass the Next-action test, and which the handoff restates anyway. A project may own several durable artifacts, not just a plan — a defect log, a runbook, a findings doc, acceptance criteria. **Each one owns its content; the handoff cites it and never reproduces it.** Cite the section (`plan §Phase 1 step 7`, `runbook §1`, `defects D4`) instead of copying source tables, port maps, pipeline descriptions, measurements, or per-file statistics.

**Section ownership — where a block belongs when the project has these artifacts:**

| Handoff section | Owned by | Handoff carries |
|---|---|---|
| Deferred | the defect/backlog log | a pointer, plus anything the Next action must not re-litigate |
| Traps | the runbook | only traps the Next action can actually trip on |
| State & decisions | the plan and findings doc | current position, not the reasoning that produced it |
| Key artifacts | — | paths only |

If the owning artifact does not exist, the content stays in the handoff and **that is the signal to create the artifact**, not to let the section grow. Two copies of a block mean the next session reads it twice and the copies drift the first time one is edited. Narrow exception: anything needed to act *before* the plan has been read.

**The prior prompt is not a template.** Re-derive every block from this session's actual state. A block earns its place by passing the Next-action test on its own — having appeared in the previous prompt is not a reason to keep it, and copying its shape forward is how a handoff grows monotonically: nothing is ever removed because nothing is ever re-examined. Read the prior prompt to know what is superseded, not to know what to write.

**Hard ceiling — 120 lines, and never more than half the plan's line count.** Whichever is smaller. **If the session worked no plan, the ceiling is a flat 120 lines** — the half-the-plan clause simply does not apply, and it never prunes below 120 on its own. This is a hard limit, not a target: prune to fit *before* writing, rather than writing long and trimming after. If real state genuinely will not fit, that is a signal the plan is missing something the handoff is compensating for — put it in the plan and cite it. Traps are capped at those the Next action can actually trip on; **any trap cut for the cap must be written into the runbook first** — or the plan, if the project has no runbook — so the cap never loses one.

**Sessions with no plan are a normal case, not a degraded one.** A long exploratory session — questions, reading, decisions, no plan file — still deserves a good handoff. It just carries different content: what was learned and what is still open, rather than progress against steps. Two sections flex accordingly (see below), and `Open threads:` usually becomes the most valuable block in the file. Do not invent a plan-shaped Goal or a Next action that the session never actually produced.

Sections:

Goal:
One sentence — what this work is trying to accomplish. **With no plan, this is what the session was *about*, not an objective** — "understand how X works and decide whether to adopt it" is a valid Goal.

State & decisions:
Locked decisions, technical configs, architecture choices, and current status of work done. Present tense — where things stand now, not a diary of how they got there. No re-litigation needed.

Constraints:
Active rules or guardrails agreed to this session. One line each.

Next action:
Single most immediate thing to do. **May legitimately be absent** when the session was exploratory and produced no committed next step — omit it rather than inventing one. An invented next action sends the following session off on work nobody asked for. Enough context to execute without re-reading history. If a verification or test result is pending, include the pass/fail criteria and what each outcome means — not just the command to run.

Awaiting:
Only if the session ends blocked on user input. One sentence — what's blocked and what input is needed.

Open threads:
Optional, and usually the most valuable section in a session with no plan. Questions raised and **not resolved** — one line each, stated as the question, not as a topic. Distinct from `Deferred:`: an open thread is live and unanswered, a deferred item is a decision already taken to park something. Include enough context to re-ask the question cold. Where a partial answer exists, say what is known and what is missing.

Deferred:
Topics discussed but intentionally parked. One line each — prevents the next session from re-litigating resolved decisions. **If the project has a defect/backlog log, that log owns these** — carry a pointer and only what the Next action must not reopen. A Deferred block that keeps growing across prompts means the log is missing.

Traps:
Optional. Only hard-won gotchas that **the Next action itself can trip on** — a false-failure signal, a command that silently returns nothing, a flag that means the opposite of what it looks like. **If the project has a runbook, the runbook owns these**; carry at most the two or three live ones and cite the rest. Never carry a trap forward because the previous prompt had it — re-derive it from this session or drop it. This section is capped at 10 lines; anything longer belongs in the runbook.

Key artifacts:
Only what's needed for the next action — file paths, IPs, sys_ids, commands, URLs. Give the real path for anything in `run/` so the next session doesn't hunt for it at the project root. Include verbatim any lookup tables, slot maps, or ID-to-name mappings needed to interpret next-session output — do not summarize these into prose.

Resume instruction:
Max 2 lines: the file to read first, and the first move. Nothing else — do not restate State & decisions, do not list what not to re-derive, do not re-flag Deferred items. Those sections already carry themselves.

If a runbook was provided, add a footer line: `Read [path] first.` If the runbook describes infrastructure or operational targets (hosts, customer instances, production systems), also add: `Change control: state the action and wait for acknowledgement before proceeding.`
