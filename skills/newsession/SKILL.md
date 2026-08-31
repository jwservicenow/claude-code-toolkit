---
name: newsession
description: Token flush for long conversations — when context is filling up or a topic is wrapping up, invoke /newsession. Two modes: `/newsession` (silent — writes the handoff file only, no output, no pre-flight check) and `/newsession full` (also runs the urgent must-do-now check, then writes the file and prints its path). Optionally shaped by a runbook or planning file. Strictly user-invoked — never auto-triggers.
---

# /newsession — Session handoff

Look at what actually happened in this conversation (this session only — not memory, not prior sessions).

**Strictly user-invoked.** Only activate when the user types `/newsession`. Never auto-trigger.

## Step 1 — Resolve the optional argument

If `$ARGUMENTS` is empty:
- Skip to Step 3 (Save) immediately — no pre-flight scan, no display. Skip Step 4 as well: write the file, then end the turn with the literal text `<!-- no output -->` and nothing else. It renders as nothing, so Jim sees no output, and the harness gets a non-empty reply so it never asks for one.
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

The prompt lifecycle (states, banner formats, when things get archived) is defined once in `shared/skills/prompt-sweep/prompt-lifecycle.md` — follow that spec; do not restate its rules here.

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

Strip all fluff, filler words, pronouns, polite transitions. Aggressive shorthand, bullets, high-density keywords. Plain-text section labels (no markdown bold/asterisks), each on its own line ending with a colon. Content follows on the next line(s). Omit any section with nothing real to say (the Tone contract is never omitted). No fixed word budget — length is set by how much real state there is. Never drop a path, ID, command, or lookup table to make it shorter; cut prose instead.

**Scope to the live thread — "cut prose, not data" applies only to work the Next action can touch.** That rule assumes the paths are still live. It is not a licence to carry forward every command and lookup table the session ever used, and applying it to retired work is what turns a handoff into an archive of its own history.

A thread **closed during this session** — decided, executed, verified, and written into a durable artifact — does not carry its mechanics forward. It compresses to **one line**: that it is closed, that it must not be reopened, and where the detail permanently lives (a findings doc, an inventory entry, a commit hash). Its hosts, ports, tokens, endpoint quirks, and trap lists stay in that artifact. Promoting them into the handoff duplicates the artifact and buries the one thing the next session actually needs.

Test each block before keeping it: **could the Next action plausibly touch this?** If the answer is no because the thing was just shut down, deleted, rejected, or superseded, it is not state — it is history, and history belongs in the artifact the closure step already wrote.

Traps and hard-won corrections are the one judgement call: keep a trap only if it can still bite the *next* action. A trap about infrastructure the session just retired goes with the rest of that thread.

Sections:

Tone contract:
Every handoff opens with the block below, copied verbatim as the first thing in the file — above Goal:, before any project content. It is the one exception to the plain-text-labels rule and to "cut prose, not data": never trim, summarize, reorder, or replace it with a pointer to CLAUDE.md. If it is not at the top in full, the handoff is not finished.

```
Tone contract — follow this exactly (full version: RULE #0 in ~/.claude/CLAUDE.md):
- First sentence contains the answer. Nothing before it. Then tables/lists/code.
- Last line is the last fact. No closing paragraph, no recap.
- ~4 lines normal. 25 vertical lines is a hard ceiling.
- Answer only what was asked. One extra is allowed only if it would change the decision Jim
  is making right now — not because it's interesting or adjacent. Everything else waits.
- Depth unlocks only when Jim literally asks — "please explain," "give me a review,"
  "what are the decisions/requirements." A topic that merely involves a decision does
  not unlock it. When it fires, the ceiling rises to 25 lines; it never disappears.
- Decisions and actions for Jim get a standalone bold heading with the options or steps
  laid out — never buried in prose. Anything Jim runs: exact copy-paste command, one
  line on what it does, one step at a time.
- Flag confidence: verified → say it straight; unsure → "I believe, but haven't
  verified —"; guess → "Honest guess —" with the basis. Verify live, not from memory.
- Batch questions; ask only for real decisions. Recommendations only when Jim is deciding
  something significant, not on every reply. Plain senior-dev voice, contractions,
  no AI-slang (delve, robust, leverage, seamless, paradigm, pivot, bespoke).

Hard gates: name files and wait before writing any of them. Ask "OK to commit + push?"
and wait before any commit or push. Never publish a Claude Artifact without an explicit yes.
```

Goal:
One sentence — what this work is trying to accomplish.

State & decisions:
Locked decisions, technical configs, architecture choices, and current status of work done. Present tense — where things stand now, not a diary of how they got there. No re-litigation needed.

Constraints:
Active rules or guardrails agreed to this session. One line each.

Next action:
Single most immediate thing to do. Enough context to execute without re-reading history. If a verification or test result is pending, include the pass/fail criteria and what each outcome means — not just the command to run.

Awaiting:
Only if the session ends blocked on user input. One sentence — what's blocked and what input is needed.

Deferred:
Topics discussed but intentionally parked. One line each — prevents the next session from re-litigating resolved decisions.

Key artifacts:
Only what's needed for the next action — file paths, IPs, sys_ids, commands, URLs. Give the real path for anything in `run/` so the next session doesn't hunt for it at the project root. Include verbatim any lookup tables, slot maps, or ID-to-name mappings needed to interpret next-session output — do not summarize these into prose.

Resume instruction:
Max 2 lines: the file to read first, and the first move. Nothing else — do not restate State & decisions, do not list what not to re-derive, do not re-flag Deferred items. Those sections already carry themselves.

If a runbook was provided, add a footer line: `Read [path] first.` If the runbook describes infrastructure or operational targets (hosts, customer instances, production systems), also add: `Change control: state the action and wait for acknowledgement before proceeding.`
