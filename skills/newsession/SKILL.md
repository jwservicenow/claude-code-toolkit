---
name: newsession
description: Token flush for long conversations — when context is filling up or a topic is wrapping up, invoke /newsession. Writes a dense handoff prompt file to the current project and prints only its path — no pre-flight check, no loose-ends survey, nothing shown in chat. Takes one optional argument: short free text naming an extra effort to carry into the next session. Strictly user-invoked — never auto-triggers.
---

# /newsession — Session handoff

Look at what actually happened in this conversation (this session only — not memory, not prior sessions).

**Strictly user-invoked.** Only activate when the user types `/newsession`. Never auto-trigger.

## Step 1 — Resolve the optional argument

`$ARGUMENTS` is optional short free text: a description of an effort to **also** be done in the
next session. Record it verbatim in the handoff's `Also next session:` section (see below). Do
not treat it as a file path, a filename, or a focus filter, and do not let it change what else
the handoff includes. If `$ARGUMENTS` is empty, omit that section.

Derive `<topic>` from the current directory's name — the argument never affects the filename.

Then go straight to Step 2. There is no pre-flight check: do not survey loose ends, do not
produce a two-list summary, do not ask what to finish first, do not flag anything before
writing. Unfinished work belongs in the handoff's Next action / Deferred sections, not in a
pre-flight discussion.

## Step 2 — Save the handoff to disk

Save the generated handoff prompt as a standalone prompt file — this becomes the project's resume point. Mirror `/newplan`'s naming:
- Write to the **current working directory** (the project being worked on) as `<topic>-prompt-YYYY-MM-DD.md` with today's date, `<topic>` from the current directory's name.
- If the cwd is a branch root (e.g. `~/ClaudeOS/personal`) rather than a project dir, write the file there as the fallback.
- The newest-dated `*-prompt-*.md` for a project is its resume pointer. Before writing the new prompt, **demote the prior same-project prompt to SUPERSEDED**: prepend the banner `STATUS YYYY-MM-DD — SUPERSEDED by <new-prompt-filename>.` (today's date) as its first line. Do **not** delete it — `/prompt-sweep` archives superseded prompts later, with the user's approval. **Never demote a `keep-loose` REUSABLE prompt** (first line `LIFECYCLE: REUSABLE — keep-loose.`) — skip it entirely when choosing the prior prompt.

Write only the contents of the handoff prompt (no intro line, no fences) to the file with the Write tool. Do **not** create or modify a README or a `.last-newsession.md`.

The handoff prompt's content is specified below.

The prompt lifecycle (states, banner formats, when things get archived) is defined once in `shared/skills/prompt-sweep/prompt-lifecycle.md` — follow that spec; do not restate its rules here.

## Step 3 — Report the filename only

**Never print the handoff prompt in chat.** It is written to disk in Step 2 and nothing more.

Output format — exactly one line, nothing else:
`Handoff written: <full path to the prompt file>`

No preamble, no code block, no summary of the handoff's contents, no next-step commentary.

## Handoff prompt content (written to the file in Step 2)

Generate a dense, structured handoff prompt the user can paste as the first message of a new Claude Code session.

Strip all fluff, filler words, pronouns, polite transitions. Aggressive shorthand, bullets, high-density keywords. Plain-text section labels (no markdown bold/asterisks), each on its own line ending with a colon. Content follows on the next line(s). Omit any section with nothing real to say. **Cap at 300 words.**

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

Also next session:
Only if `$ARGUMENTS` was provided. The user's text, verbatim — an additional effort to take on next session, alongside Next action. Do not reword, expand, or interpret it. Omit this section entirely when no argument was given.

Awaiting:
Only if the session ends blocked on user input. One sentence — what's blocked and what input is needed.

Deferred:
Topics discussed but intentionally parked. One line each — prevents the next session from re-litigating resolved decisions.

Key artifacts:
Only what's needed for the next action — file paths, IPs, sys_ids, commands, URLs. Include verbatim any lookup tables, slot maps, or ID-to-name mappings needed to interpret next-session output — do not summarize these into prose.

Resume instruction:
Direct instruction to future Claude: exactly how to pick up, first move, no preamble.
