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
| **ACTIVE** | Newest prompt in a project, carrying **no** banner. The live resume pointer. | **Never** |
| **SUPERSEDED** | An older prompt for which a newer one now exists. Carries a SUPERSEDED banner. | Yes — after approval |
| **DONE** | Carries a DONE banner (its plan closed, or work finished). | Yes — after approval |
| **REUSABLE** | A utility prompt tagged `keep-loose` — meant to be re-run, kept in place indefinitely. | **Never** |
| **LEGACY** | No banner and no `keep-loose` marker — the tool can't tell a live pointer from a retired-but-unstamped orphan. Predates this system, or was retired without stamping. | Never silently — **always surfaced for a per-file decision** |

Precedence when a file could match more than one: **REUSABLE > ACTIVE > DONE > SUPERSEDED.**
A `keep-loose` file is REUSABLE even if it is also the newest; a banner never overrides
`keep-loose`.

**LEGACY is not a resting state.** An unbannered prompt is only genuinely ACTIVE when it is
the live resume pointer of a project with an open plan; otherwise `/prompt-sweep` cannot know,
so it must **always ask Jim** what to do rather than assume ACTIVE and skip. Jim's answer
resolves it into ACTIVE (leave), REUSABLE (stamp `keep-loose`), or DONE/SUPERSEDED (stamp +
sweep). This is what stops retired-but-unstamped prompts from hiding as ACTIVE forever.

## Banner & marker formats

Banners go at the **very top** of the prompt file, first line, so any tool sees them without
parsing the body. Date is the day the state changed (US Mountain Time).

- **DONE:**  `STATUS YYYY-MM-DD — DONE.`
- **SUPERSEDED:**  `STATUS YYYY-MM-DD — SUPERSEDED by <newer-prompt-filename>.`
- **REUSABLE:**  `LIFECYCLE: REUSABLE — keep-loose.`  (this is the `keep-loose` tag; presence of this line = never sweep)

A file with none of these lines and that is the newest prompt in its project = **ACTIVE**.
`STATUS …` mirrors the plan-header banner `/newplan` already stamps at Closure, so the
vocabulary is shared between plans and prompts.

## Division of labor — who changes state, and when

| Tool | Trigger | Action |
|---|---|---|
| **`/newplan`** | Closure of a plan | Stamps its OWN plan+prompt pair `DONE`, moves both to the project's `archive/`. |
| **`/newplan`** | Replan on an existing project | Demotes the prior prompt to `SUPERSEDED` (banner) before writing the new pair. |
| **`/newsession`** | Refresh (new prompt written) | Stamps the prior same-project prompt `SUPERSEDED` before writing the new one. |
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

Net: the newest file — highest date, then highest letter — is the project's resume pointer;
every earlier one survives with a `SUPERSEDED` banner until `/prompt-sweep` archives it.

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
