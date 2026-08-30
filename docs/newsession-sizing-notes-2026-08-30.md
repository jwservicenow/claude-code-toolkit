# /newsession handoff sizing — idea, NOT adopted

STATUS 2026-08-30 — IDEA ONLY. The skill works and is unchanged. Jim wants to think about this
before any edit. Do not "helpfully" apply it. If it does get adopted, the edit is one file:
`~/ClaudeOS/shared/skills/newsession/SKILL.md` (shared → `jwservicenow/claude-toolkit`, public).

## What prompted it

Handoff files have been growing. Measured 2026-08-30:

| Prompt file | Bytes | ~Tokens |
|---|---|---|
| `score-v6-prompt-2026-08-30.md` | 13,306 | 3,326 |
| `lemon-html-ingestion-prompt-2026-08-30e.md` | 11,606 | 2,901 |
| `ram-manuals-consolidation-prompt-2026-08-27h.md` | 9,898 | 2,474 |
| `ram-manuals-consolidation-prompt-2026-08-28i.md` | 5,012 | 1,253 |

Jim's recollection was 2-3k as normal. The drift is real, though not as large as it felt — the
turn cost he noticed (~6k) included loading the skill itself, not just the file.

## Root cause — a rule in the skill, not a one-off

`SKILL.md`, under "Handoff prompt content":

> No fixed word budget — length is set by how much real state there is. Never drop a path, ID,
> command, or lookup table to make it shorter; cut prose instead.

Two problems.

1. **It protects lookup tables from removal.** That is what produced the concrete example: a
   seven-row collection table was pasted into a handoff minutes after being committed to a
   canonical inventory file — and the same handoff also told the next session to go read that
   inventory. Both copies, same session.
2. **"Cut prose instead" trims the wrong half.** Prose is where the reasoning and the traps live.
   The tables and ID lists survive by rule; the thinking gets squeezed.

The fix already exists elsewhere in Jim's setup and was simply never inherited here: the
CLAUDE.md tree's **one fact, one file** rule and its `CANONICAL:<name>` convention — link to the
canonical block, never copy it.

## Candidate rules (Jim leaned toward C)

**A. Cite, don't copy.** If a fact is canonical in a committed artifact, give the path and section
instead of inlining it. Inline only what the next session needs *before* it can read anything —
the host, the ssh line, the first command — or where a lookup would be genuinely ambiguous. Keep
the "never drop a path, ID, or command" protection, but scope it to things the session executes.

**B. A + carried-forward traps must earn their place.** A trap survives into the new handoff only
if it can plausibly fire on the stated Next action. Everything else stays in the superseded
prompt, which is not deleted — so nothing is actually lost. Today traps get copied forward
wholesale, session after session, whether or not the work has moved on.

**C. A + B + a stated target** (~2.5k tokens) as a *check*, not a cap. Real state still wins; the
number just gives the skill something to notice when it is drifting.

## Open questions to settle before editing

- Does "cite, don't copy" risk a handoff that cannot bootstrap if the cited artifact moved or was
  archived? Probably needs a rule that the citation includes enough to re-find the file.
- Are the lookup tables actually the bulk, or does the tone contract plus trap list dominate?
  Worth measuring section-by-section on a real handoff before assuming.
- A target could invite padding *up* toward it as easily as trimming down.
