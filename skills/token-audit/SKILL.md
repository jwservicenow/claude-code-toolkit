---
name: token-audit
description: Use when the user types /token-audit to check Claude Code accounts for token waste — CLAUDE.md size, MCP server/tool footprint, model/effort config, hooks, subagents, scheduled cron jobs, undocumented settings.json keys, and cache/token usage totals. Auto-discovers every real Claude Code config on the machine (works for one account or several) and skips any that just mirrors another via symlinked session data. Runnable from any account. Strictly user-invoked — never auto-triggers.
---

# /token-audit — Claude Code token-waste audit

Checks every real Claude Code account on this machine for config bloat, undocumented settings,
and actual token/cache usage — whether that's one account or several. Filesystem access isn't
scoped to whichever account is currently running the skill, so it can read every discovered
config dir in one pass regardless of which one invoked it.

**Strictly user-invoked.** Only activate when the user types `/token-audit`. Never auto-trigger.

## Step 0 — Discover accounts

Run `bash <skill_dir>/discover_accounts.sh`, where `<skill_dir>` is the directory this SKILL.md
lives in (resolve it at runtime — it's often a symlink target, so use the actual on-disk path).
It prints one config dir per line — could be just `~/.claude` for a single-account setup, or
several for a multi-profile Mac. It only counts a directory as real if it has a `settings.json`
or `.claude.json` **and** shows genuine usage (at least one session `.jsonl` under `projects/`),
and it collapses any config dir whose `projects/` is a symlink onto another discovered dir's
`projects/` — that's one account's session history shared across two config dirs (a common way to
run two CLI aliases against the same login), not two separate accounts to audit and double-count.

Use exactly the list this script returns for every step below. Don't assume a fixed number of
accounts, and don't hardcode directory names — the whole point of this step is not needing to.

## Step 1 — CLAUDE.md sizes

For each discovered config dir, find every `CLAUDE.md` reachable from it (its own `CLAUDE.md` if
present, plus any project-level ones under that account's known project paths — check
`<config_dir>/.claude.json` key `projects` for the tracked path list). Report byte size and a
rough token estimate (bytes / 4) per file, and a combined total per account. Flag any single file
over ~5k tokens (~20KB) — that's the bar used in prior audits.

## Step 2 — MCP servers

Read `mcpServers` from each account's `settings.json` (and `.mcp.json` / `~/.claude.json`
project-scoped servers if present). Report server count per account and flag anything that looks
like a proxy/gateway server fronting many tools (worth a tool-count check) versus small direct
servers. Note whether tool deferral is active (large tool counts should be deferred, not all
loaded up front).

## Step 3 — Model / effort config

Report `model` and `effortLevel` from each account's `settings.json`.

## Step 4 — Undocumented settings.json keys

Fetch the official schema and diff against it:
1. `WebFetch` on `https://code.claude.com/docs/en/settings` and `https://code.claude.com/docs/en/settings.md`
   (the raw `.md` variant sometimes surfaces keys the rendered page truncates) — ask for the complete
   list of top-level documented key names.
2. List the top-level keys actually present in each discovered account's `settings.json`. Also
   check `~/.claude/settings.json` even if Step 0 didn't count it as an active account — stray
   keys have shown up in the unused default location before (e.g. an undocumented `auto_dream`
   flag), and it's cheap to check regardless of activity.
3. Any key not in the documented list is a finding. For each, report which account(s) have it and
   the value.
4. **Don't recommend removal by default.** The docs page itself warns it lags recent CLI releases, so
   "undocumented" isn't automatically "wrong." Use judgment on presentation:
   - A key with **no local evidence of ever running** (no matching log/session trace anywhere,
     unclear purpose from the name alone) — worth flagging as a real candidate for removal, and
     worth a quick check of unofficial sources (GitHub issues, changelog) for what it is before
     recommending anything.
   - A self-explanatory key with **consistent presence and no sign of being inert** — report it as
     undocumented-but-likely-legitimate, no action recommended.

## Step 5 — Hooks

List configured hooks (`SessionStart`, `PreToolUse`, etc.) per account's `settings.json`, with the
command each one runs. Confirm the command target still exists on disk (a hook pointing at a deleted
script is a real finding).

## Step 6 — Subagents

Check for a custom `agents/` directory under each discovered config dir. Most runs will find none
— that's not a finding, just report it plainly.

## Step 7 — Scheduled jobs (CronList)

Call `CronList`. Note in the output that this tool is session-scoped — it only reports jobs created
via `CronCreate` in the *current* session, not a durable per-account registry. Report what it returns,
but don't treat an empty result as proof no jobs exist anywhere; say so explicitly.

## Step 8 — Cache/token usage totals

Run `python3 <skill_dir>/parse_usage.py <config_dir>` for each discovered config dir (no date
argument — it auto-detects the most recent Mountain-time day with activity, which may differ
between accounts if one wasn't used as recently).

Report per account: the date it covers, file count, input/output/cache_read/cache_creation totals,
grand total, and cache_read percentage.

## Output

One report. If Step 0 found more than one account, lay each step out as a table with one column
per account; for a single-account result, plain sections read better than a one-column table.
Lead with a one-line summary of what's actually wasteful (if anything) — most runs will find
nothing new since the last audit; say that plainly instead of padding the report. Only propose a
fix (editing a settings.json, removing a stray key) after stating the finding and getting
confirmation — this skill reports, it doesn't remediate on its own unless the user asks for that
as a follow-up.
