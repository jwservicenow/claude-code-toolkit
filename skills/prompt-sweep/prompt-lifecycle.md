<!-- CANONICAL:prompt-lifecycle -->
# Prompt Lifecycle — canonical spec

The single source of truth for how `*-prompt-*.md` files are born, superseded, retired,
and archived. **Rules only — no live state, no project backlog.** `/prompt-sweep`,
`/newsession`, and `/newplan` all point here; they must never restate these rules.

A "prompt file" is a `<topic>-prompt-YYYY-MM-DD.md` paste-to-resume handoff written by
`/newsession` or `/newplan`. The newest one for a topic is that topic's live resume pointer —
**newest = highest date, then highest letter suffix** (`…-08-03c.md` beats `…-08-03b.md` beats
`…-08-03.md`).

## The four states

| State | Definition | Swept? |
|---|---|---|
| **ACTIVE** | Newest prompt **for its topic**, carrying **no** banner. The live resume pointer for that topic. | **Never** |
| **SUPERSEDED** | An older prompt for which a newer one now exists. Carries a SUPERSEDED banner. | Yes — after approval |
| **DONE** | Carries a DONE banner (its plan closed, or work finished). | Yes — after approval |
| **REUSABLE** | A utility prompt tagged `keep-loose` — meant to be re-run, kept in place indefinitely. | **Never** |
| **LEGACY** | No banner and no `keep-loose` marker — the tool can't tell a live pointer from a retired-but-unstamped orphan. Predates this system, or was retired without stamping. | Never silently — **always surfaced for a per-file decision** |

Precedence when a file could match more than one: **REUSABLE > ACTIVE > DONE > SUPERSEDED.**
A `keep-loose` file is REUSABLE even if it is also the newest; a banner never overrides
`keep-loose`.

**A project holds one ACTIVE prompt per open topic, not one overall.** A project with three
live workstreams legitimately has three ACTIVE prompts. Never infer that one topic's prompt
retired another topic's just because it is newer — that inference is what silently retires
live work. Only a same-topic successor supersedes.

**LEGACY is not a resting state.** An unbannered prompt is only genuinely ACTIVE when it is
the live resume pointer of an open topic; otherwise `/prompt-sweep` cannot know,
so it must **always ask Jim** what to do rather than assume ACTIVE and skip. Jim's answer
resolves it into ACTIVE (leave), REUSABLE (stamp `keep-loose`), or DONE/SUPERSEDED (stamp +
sweep). This is what stops retired-but-unstamped prompts from hiding as ACTIVE forever.

## Banner & marker formats

Banners go at the **very top** of the prompt file, first line, so any tool sees them without
parsing the body. Date is the day the state changed (US Mountain Time).

- **DONE:**  `STATUS YYYY-MM-DD — DONE.`
- **SUPERSEDED:**  `STATUS YYYY-MM-DD — SUPERSEDED by <newer-prompt-filename>.`
- **REUSABLE:**  `LIFECYCLE: REUSABLE — keep-loose.`  (this is the `keep-loose` tag; presence of this line = never sweep)

A file with none of these lines and that is the newest prompt for its topic = **ACTIVE**.
`STATUS …` mirrors the plan-header banner `/newplan` already stamps at Closure, so the
vocabulary is shared between plans and prompts.

## Division of labor — who changes state, and when

| Tool | Trigger | Action |
|---|---|---|
| **`/newplan`** | Closure of a plan | Stamps its OWN plan+prompt pair `DONE`, moves both to the project's `archive/`. |
| **`/newplan`** | Replan on an existing project | Demotes the prior prompt to `SUPERSEDED` (banner) before writing the new pair. |
| **`/newsession`** | Refresh (new prompt written) | Stamps the prior **same-topic** prompt `SUPERSEDED` before writing the new one. Never touches another topic's prompt, however old. |
| **`/prompt-sweep`** | Jim runs it (~monthly) | Backstop. Finds SUPERSEDED/DONE prompts, proposes moves, and — per Jim's approval — archives them. Catches whatever the other two missed. |

Each tool owns the state changes at its own moment; `/prompt-sweep` is the periodic net
under all of them. No tool ever deletes a prompt — the sweep **moves** files to `archive/`.

## Same-day suffix vs different-day keep

Prompt filenames are keyed to **date + topic**, with a letter suffix for repeat runs on the
same day: `<topic>-prompt-YYYY-MM-DD[b|c|…].md`. **A prompt file is never overwritten.**

- **Different day** (normal case): a new date makes a new filename, so the prior prompt is a
  distinct file. `/newsession` and `/newplan` keep it and stamp it `SUPERSEDED` — history is
  preserved, and `/prompt-sweep` archives it later.
- **Same day, same topic** (re-running in the same project without changing the focus): the
  base filename is already taken, so append the next unused letter — first re-run of the day
  writes `…-2026-08-03b.md`, the next `…c.md`, and so on. Stamp the prior prompt `SUPERSEDED
  by <new filename>` as usual, so the day's runs form a readable chain. Never write over an
  existing prompt to reuse its name: a same-day handoff holds real work, and the later prompt
  is a continuation of it, not a correction. Letters, not numbers, so the suffix can never be
  mistaken for part of the date.
- **Same day, different topic** (a different `$ARGUMENTS` focus, a different cwd, or a
  different plan worked): different `<topic>` → different filename → both coexist, no suffix
  needed.

Net: within a topic, the newest file — highest date, then highest letter — is that topic's
resume pointer; every earlier one survives with a `SUPERSEDED` banner until `/prompt-sweep`
archives it. Across topics, nothing is compared.

## A hold note only binds the file that states it

A SUPERSEDED file is swept on its own `SUPERSEDED by <file>` banner alone — a "not yet
archived" / "stays in root for now" note found in a *different* file (the plan, or a later
same-topic prompt) never transfers backward onto that topic's already-superseded predecessors.
`/prompt-sweep` always collapses a same-topic chain to its single most-recent file, independent
of the plan's closure/archive status. Only the file that itself carries the hold text — plan or
terminal prompt — may be deferred; every earlier chain link stays a Table A candidate on its
banner alone.

## Dormant topics (ACTIVE is not immortal)

Topic-scoped ACTIVE has one failure mode: an abandoned topic's last prompt is never superseded,
because no successor is ever written. Without a rule it stays ACTIVE forever and quietly pads
the project's "what am I working on" list.

So: an ACTIVE prompt whose date is **more than 60 days old** is **dormant**. `/prompt-sweep`
**surfaces** it for a per-file decision — exactly the LEGACY treatment, in the same "needs your
call" section — with the options **keep ACTIVE** (work is genuinely still open), **mark DONE**
(stamp the banner, then sweep it), or **mark REUSABLE**. Dormancy is a prompt to ask, never a
licence to act: **this does not make ACTIVE sweepable**, and the non-negotiable below stands
unchanged.

60 days, not 30, because `/prompt-sweep` runs about monthly — a topic must sit untouched across
two consecutive sweeps before it is raised, so genuinely slow-burning work is never nagged.

## Scope guardrail (hard rule)

- `/prompt-sweep` operates on **exactly one branch** — the one whose tree contains the cwd
  (work **or** personal). It **never crosses the work/personal line** in a single run.
- In-scope locations: that branch's `projects/*/` (each project archives into its **own**
  `projects/<name>/archive/`) **plus** the flat `shared/` root (archives into `shared/archive/`).
- A file only ever moves into **its own** project's (or `shared/`'s) `archive/` — never another
  project's, never across the branch line.

## Archive naming (prefix on move — hard rule)

Archives are flat, but source files come from a project root **and** its subfolders (e.g.
`homelab/`, `homelab/dimm/`, `homelab/hl-agents/`), all landing in the same `archive/`. To keep
origin legible, on move **every** file gets its **immediate parent folder name** prepended —
prompts and plans alike:

- **Always prefix; no exceptions, no dedup.** Even project-root files get the project-folder name;
  even a file whose name already starts with its folder gets it again. Doubling is expected, not a bug.
- **Immediate parent only**, not the full path: `homelab/dimm/x` → `dimm-x`, never `homelab-dimm-x`.

Examples (all → `homelab/archive/`):
- `homelab/dimm/doc-update-procedure-prompt-2026-06-28.md` → `dimm-doc-update-procedure-prompt-2026-06-28.md`
- `homelab/hl-agents/hl-agents-prompt-2026-06-16.md` → `hl-agents-hl-agents-prompt-2026-06-16.md` *(doubled — correct)*
- `homelab/cu130-130-prompt-2026-06-16.md` *(project root)* → `homelab-cu130-130-prompt-2026-06-16.md`
- `llm/llm-layer8-prompt-2026-06-28.md` *(project root)* → `llm-llm-layer8-prompt-2026-06-28.md` *(doubled — correct)*

The archive-folder **location** may consolidate later (subfolders don't yet own their own
`archive/`); this naming rule keeps names consistent regardless of where the folders land.

## Non-negotiables

- **Nothing moves without Jim's approval** — per-file or approve-all.
- **ACTIVE and REUSABLE are never swept**, ever.
- **Move, never delete** — recovery is always `archive/ → back`.
- **Link, never restate** — other skills reference this file; they do not copy these rules.
