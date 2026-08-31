# Handoff template

The handoff file is the labels below, in this order, and **no others**. Omit a label with
nothing real to say. Never invent one. Plain-text labels, each alone on its line ending in a
colon; content on the following lines.

## Fixed header — copied, not composed

Two blocks open every handoff, in this order, before `Goal:`. Copy them; do not gloss,
summarize, or write your own preamble around them.

1. The lifecycle banner, if this supersedes a prior prompt. Format and rules are canonical in
   `shared/skills/prompt-sweep/prompt-lifecycle.md`.
2. The tone contract, verbatim:

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

Nothing else goes above `Goal:`. No "READ THIS FIRST", no restatement of the tone contract in
your own words, no editorial about what went wrong this session.

## Labels

| Label | Cap | What it holds |
|---|---|---|
| `Goal:` | **2 sentences** | What this work is trying to accomplish. |
| `State & decisions:` | — | Locked decisions, configs, current status. Present tense, not a diary. |
| `Constraints:` | — | Active rules agreed this session. One line each. |
| `Next action:` | — | The immediate thing to do, executable without re-reading history. If a verification is pending, give the pass/fail criteria and what each outcome means. |
| `Traps the next action can still trip on:` | — | Hard-won corrections that can still bite. The label is the filter: if it can only bite work already finished, it fails the live-target gate below. |
| `Awaiting:` | **1 entry per item, ≤3 sentences** | Only if the session ends blocked on Jim. One entry per blocked item — what's blocked and what input is needed. |
| `Deferred:` | — | Parked topics, one line each, so they aren't re-litigated. |
| `Key artifacts:` | — | Paths, IPs, sys_ids, commands, URLs the next action needs. Real path for anything in `run/`. Lookup tables and ID-to-name maps go in verbatim — never summarized into prose. |
| `Resume instruction:` | **2 sentences** | The file to read first, and the first move. Nothing else. |

Caps are counted in sentences and entries, never in physical lines — a cap must not change
with the wrap width. Capped labels are capped because they can only ever hold restatement. **The uncapped labels have
no line limit** — they scale with how much real work happened, and a dense session yields a long
handoff. That is correct, not a failure. There is no whole-file ceiling.

## Two gates — apply to every block in an uncapped label

**Live-target gate.** A block earns its place by naming the live thing the Next action will
touch — a file, host, port, command, build, criterion. A block that names nothing live is
history: compress it to one line saying the thread is closed, that it must not be reopened, and
which artifact holds the detail (findings doc, inventory entry, commit hash). A closed thread
never carries its mechanics forward.

**Overflow gate.** Nothing is ever cut to make the handoff shorter. A block that does not belong
here is written down *first*, then cited from the handoff (`plan §Phase 1 step 7`). Three places
to put it, in order of preference:
1. The plan or the findings file, if the block belongs to that work.
2. A `<topic>-reference-YYYY-MM-DD.md`, for material that is reusable but attached to no live
   thread — recipes, retired commands kept as a record, raw measurement tables. Same naming and
   the same durable/ephemeral placement test as *Working artifacts* in `shared/skills/newplan/SKILL.md`.
3. Nowhere yet — in which case the block STAYS in the handoff and an `Awaiting:` entry offers to
   write it. Never cut a block whose only copy is this file.

Cut-then-lost is the one outcome this template exists to prevent.

Corollary: when the handoff names a plan, that plan is the durable copy. Cite its sections
instead of reproducing its tables, port maps, or measurements. The exception is anything needed
to act *before* the plan has been read.

## Do not use the prior prompt as a shape

Read it to learn what is superseded, not what to write. Every block is re-derived from this
session against the two gates above. A block does not earn its place by having been there last
time.
