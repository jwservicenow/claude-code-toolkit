---
name: prompt-sweep
description: On-demand monthly backstop that finds retired prompt files (`*-prompt-*.md`) and, with per-file or approve-all consent, archives the SUPERSEDED and DONE ones into each project's own `archive/`. Never touches ACTIVE or REUSABLE prompts, never crosses the work/personal line, never deletes. Strictly user-invoked — never auto-triggers.
---

# /prompt-sweep — Prompt lifecycle backstop

The periodic net under `/newsession` and `/newplan`. Jim runs this ~monthly to clear
retired prompt files out of project roots. It **proposes**, Jim **approves**, then it
**moves** — nothing else.

**Strictly user-invoked.** Only activate when the user types `/prompt-sweep`. Never auto-trigger.

The lifecycle states, banner formats, division of labor, and scope guardrail are defined
once in the canonical spec: **`shared/skills/prompt-sweep/prompt-lifecycle.md`**. Read it
before running. This skill does not restate those rules — it applies them.

## Step 1 — Resolve the branch (hard scope)

Determine which branch the cwd sits in — `~/ClaudeOS/work` **or** `~/ClaudeOS/personal`
— and operate on that branch only. If the cwd is inside `~/ClaudeOS/shared`, the branch
is **shared** (the flat root, its own `archive/`). **Never cross the work/personal line
in one run.** If the branch can't be determined, stop and ask.

## Step 2 — Scan for prompt files

Within the resolved branch, find every `*-prompt-*.md`:
- Each `projects/*/` directory (recursively — projects may nest subfolders like `homelab/tv/`).
- The flat branch root and, for shared, the `shared/` root itself.
- Skip anything already inside an `archive/` folder.

## Step 3 — Classify each file (per the spec)

For each prompt file, assign a state using `prompt-lifecycle.md` precedence
(**REUSABLE > ACTIVE > DONE > SUPERSEDED**):
- **REUSABLE** — first line is the `LIFECYCLE: REUSABLE — keep-loose.` marker. Never swept.
- **DONE** — first line is a `STATUS … — DONE.` banner. Sweep candidate.
- **SUPERSEDED** — first line is a `STATUS … — SUPERSEDED by …` banner, OR it is an older
  prompt for a project that has a newer prompt (even if someone forgot to stamp it). Sweep candidate.
- **ACTIVE** — no banner AND the live resume pointer of a project with an open plan. Never swept.
- **LEGACY** — no banner and no `keep-loose` marker, and **not** confidently ACTIVE per the
  line above (predates the system, retired without stamping, or a lone prompt in a flat root
  with no open plan). **Do not assume ACTIVE and skip it** — surface it for a decision (Step 4).

Only **DONE** and **SUPERSEDED** are direct sweep candidates. **LEGACY is always asked about.**

## Step 4 — Propose (never move yet)

Show **two** tables.

**A. Sweep candidates** (DONE / SUPERSEDED):

| # | File (path) | State | → Destination archive/ |
|---|---|---|---|

**B. Legacy — needs your call** (unbannered, not confidently ACTIVE):

| # | File (path) | Recommended | Why |
|---|---|---|---|

Recommended is one of: **keep ACTIVE** (leave in place) · **mark REUSABLE** (`keep-loose`) ·
**archive DONE** / **archive SUPERSEDED by <file>**.

**Read each Table B file in full before assigning its Recommended — always. Never infer a
disposition from the filename, the absence of a banner, or the memory index; those are what
produce wrong first-pass calls.** Base it on what the file actually says, checking:
- **Live task or finished one-shot?** The filename can lie — a `…-procedure-…` may be a single
  completed test, not a reusable procedure. Trust the body's goal + next-action over the name.
- **Is it a keep-around reference?** "Verify-don't-reapply" notes, or a file whose *current path*
  other prompts/docs/the runbook point at, should be **REUSABLE in place** — archiving relocates
  it and breaks those links.
- **Is the work truly done?** Confirm against the file's own status/next-action and any open plan
  for the topic — not just a memory summary, which can lag.

(Table A candidates are banner-driven and self-stamped — no full read needed. This mandatory
read is only for Table B, whose ambiguity is exactly what the read resolves.)

Below both, list what is being **left in place** with no question and why (confirmed ACTIVE with
an open plan; REUSABLE = keep-loose). If both tables are empty, say
"Nothing to sweep — all prompts are ACTIVE or REUSABLE." and stop.

## Step 5 — Get approval, then act

Ask Jim to approve — **per-file** (list the numbers) or **all**. For Table B he confirms or
overrides each recommendation. Then, per file:
- **archive** → stamp the DONE/SUPERSEDED banner as its first line, then move it to `archive/`,
  prefixing the filename per the spec's **Archive naming** rule (immediate parent folder, always, every file, no dedup).
- **mark REUSABLE** → stamp the `LIFECYCLE: REUSABLE — keep-loose.` marker; leave in place.
- **keep ACTIVE** → leave untouched.

For every move: ensure the destination `archive/` exists (the project's own, or `shared/archive/`);
create if missing. **Move** (not copy, not delete). If a plan file (`<same-topic>-plan-*.md`) sits
beside a swept prompt and is itself DONE, offer to move it too — same approval.

Never move or stamp a file Jim didn't approve. Report what moved/stamped and where, one line each.

## Step 6 — Done

State the final tally (moved N, left M active/reusable). No handoff, no README, no next steps.

## Rules

- User-invoked only. Never auto-trigger.
- One branch per run — never cross the work/personal line.
- ACTIVE and REUSABLE are never candidates.
- Move, never delete. Every move is approval-gated.
- Rules live in `prompt-lifecycle.md` — link to it, never restate it.
