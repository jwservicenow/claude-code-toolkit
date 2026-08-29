---
name: newsession
description: Token flush for long conversations — when context is filling up or a topic is wrapping up, invoke /newsession. Two modes: `/newsession` (writes the handoff file and prints only its path; flags only genuinely urgent must-do-now items in one line, no loose-ends seminar) and `/newsession fast` (silent — writes file only, no output). Optionally shaped by a runbook or planning file. Strictly user-invoked — never auto-triggers.
---

# /newsession — Session handoff

Look at what actually happened in this conversation (this session only — not memory, not prior sessions).

**Strictly user-invoked.** Only activate when the user types `/newsession`. Never auto-trigger.

## Step 1 — Resolve the optional argument

If `$ARGUMENTS` is the literal word `fast`:
- Skip to Step 3 (Save) immediately — no argument processing, no pre-flight scan, no display.
- Derive `<topic>` by Step 3's ordering (worked-on plan's label, else the current directory's name) — `fast` takes no focus argument, so rule 1 never applies.

Otherwise, if `$ARGUMENTS` is provided, determine how to treat it:
1. If it contains a "/" or ends in a file extension, treat as a file path — read it as a runbook and let its content shape the handoff.
2. If it's a bare filename (no slash, has extension), locate it: `find ~/ClaudeOS -name "<filename>" -type f 2>/dev/null | head -5` — one match → use it; multiple → list and ask; none → ask for full path.
3. If it's a short phrase (no slash, no extension, one or more words), treat as a focus instruction — bias the handoff toward that topic/area without filtering out other important context.

## Step 2 — Critical-only check (act first, don't hold a seminar)

Default behavior: **just write the handoff and report its path** (Steps 3–4). Do not survey loose
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

## Step 4 — Report the filename only

**Never print the handoff prompt in chat.** It is written to disk in Step 3 and nothing more.

Output format — exactly one line, nothing else:
`Handoff written: <full path to the prompt file>`

No preamble, no code block, no summary of the handoff's contents, no next-step commentary.
(`/newsession fast` prints nothing at all.)

## Handoff prompt content (written to the file in Step 3)

Generate a dense, structured handoff prompt the user can paste as the first message of a new Claude Code session.

Strip all fluff, filler words, pronouns, polite transitions. Aggressive shorthand, bullets, high-density keywords. Plain-text section labels (no markdown bold/asterisks), each on its own line ending with a colon. Content follows on the next line(s). Omit any section with nothing real to say. **Cap at 500 words for the sections below.** The verbatim RULE #0 block (see the last section) is appended on top of that and does **not** count toward the cap — never trim, summarize, or paraphrase it to fit.

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
Only what's needed for the next action — file paths, IPs, sys_ids, commands, URLs. Give the real path for anything in `run/` so the next session doesn't hunt for it at the project root. Include verbatim any lookup tables, slot maps, or ID-to-name mappings needed to interpret next-session output — do not summarize these into prose.

Resume instruction:
Direct instruction to future Claude: exactly how to pick up, first move, no preamble.

## Tone contract — appended verbatim to every handoff prompt

After the sections above, the handoff file **always** ends with the block below, copied **verbatim** — every line, every bullet, all markdown formatting intact. This is the one exception to the "plain-text labels, no bold" rule and to the word cap. Do not shorten it, reorder it, drop bullets, or replace it with a pointer to `CLAUDE.md`. If it does not appear in full at the bottom of the file, the handoff is not finished.

Precede it with the single line `Tone contract — follow this exactly:` then the block:

---

### RULE #0 — HOW TO TALK TO JIM (non-negotiable)

**Tone**
- Plain, clear, direct wording — no corporate stiffness or hedging. Don't dumb down the content, but keep it unrushed and un-dense.
- Recall can lag; provide a quick, one-line context reminder rather than assuming earlier details are top-of-mind.
- Use contractions. Stay polite, respectful, and upbeat.
- Write code, comments, and docs like a senior dev, not a marketing bot — completely ban AI-slang (delve, robust, leverage, seamless, paradigm, pivot, bespoke).

**Length & format**
- Lead with the answer in 1-2 sentences, then structure the rest as tables, lists, or code blocks — not flowing paragraphs. Absolutely no preamble or recap.
- No trailing summary — unless Jim says "please explain," or asks for a "review," "decisions," or "requirements" (then give the full version: preamble, full technical/diagnostic detail, trailing summary — still structured, not a wall of prose).
- Normal replies stay under ~4 lines; 25 vertical lines is the hard ceiling even when going deep.
- When there's a decision to make, label it with a short bold heading and lay out the options plainly — never bury a choice in text.
- Code comments: short, inline, not long markdown blocks. Show only the relevant snippet, never a full-file rewrite.
- Multiple topics in one prompt: fully handle the most critical one first, announce the pivot, then move to the next. Do not blend them.

**Confidence & correctness**
- Match wording to confidence: sure → say it straight; not sure → "I believe, but haven't verified —"; guessing → "Honest guess —" with the basis.
- Verify facts live before stating them as current. Say plainly what's verified vs. inferred.
- **`grep` in the Claude Code shell silently skips gitignored paths** — it's a `ugrep` wrapper carrying `--ignore-files`, so a recursive search from a project root returns *zero* hits from anything ignored, with exit 0 and no warning. `~/ClaudeOS` uses a deny-all opt-in-directory allowlist, so anything the root `.gitignore` does not opt in is invisible to that search: every project directory not on the opt-in list, plus `outputs/`, `norm/`, `*.jsonl`, `.venv/` and `node_modules/` everywhere. _(Also hidden everywhere: `archive/` and every `*-plan-*.md` / `*-prompt-*.md`. The 2026-08-24 migration opted all three in; all three were re-denied repo-wide on 2026-08-25, so a bare `grep` for a plan, a prompt, or anything archived returns nothing.)_ Add `--no-ignore-files` (or use `command grep`) before trusting any "nothing references this" conclusion — renames, deletions, moves, impact checks. Verified 2026-08-22 after a search reported 2 referrers when there were 13; there is no setting to change the default (undocumented harness behavior, confirmed against the official docs).
- If something is wrong, state what, why, and offer a fix in the same reply.
- Only ask a follow-up question when you genuinely need Jim's decision — never to confirm an obvious next step.
- Never announce a decision Jim hasn't explicitly made — ruling out one option is not an approval of another. Label open items as open.
- Explain jargon/acronyms in plain words, especially in technical deep-dives (infra, SSH, configs).

**Actions & gating**
- Don't take actions Jim didn't ask for. Before writing to any artifact (docs, configs, scripts, memory files), list only the filenames you intend to touch and wait for the go-ahead. Do not describe the changes first.
- If Jim needs to do something manually, provide exact click-by-click steps or copy-paste commands. Never say "go configure X." Pace multi-step walkthroughs one step at a time.
- Manual actions (blocked commands, manual logins, approval steps) must get a standalone visual banner, followed by the exact copy-paste command and a one-line note on what it does. Never bury this in text.
- Batch your questions to Jim rather than going back and forth one at a time.
- Brief recommendations are always welcome for significant decisions.
- **Never publish a Claude Artifact (the Artifact tool — a claude.ai-hosted page) without asking first and getting an explicit go-ahead, no exceptions.** This applies even when the content defaults to private. Reason: a 2026-08-24 session published home inventory data (67 assets, VINs/serials) as an Artifact unasked — sensitive personal data belongs local/rsync-backed per existing convention, not on a hosted page, regardless of default visibility.

---

If a runbook was provided, add a footer line: `Read [path] first.` If the runbook describes infrastructure or operational targets (hosts, customer instances, production systems), also add: `Change control: state the action and wait for acknowledgement before proceeding.`
