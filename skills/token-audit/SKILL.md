---
name: token-audit
description: Use when the user types /token-audit to check Claude Code accounts for token waste — CLAUDE.md size, MCP server/tool footprint, model/effort config, hooks, subagents, scheduled cron jobs, undocumented settings.json keys, and cache/token usage totals. Covers claudep (~/.claude-personal) and claudew (~/.claude-work) — claudec mirrors claudep's commands/output-styles/plugins by symlink and is not audited separately. Runnable from any account. Strictly user-invoked — never auto-triggers.
---

# /token-audit — Claude Code token-waste audit

Checks both real Claude Code accounts on this Mac for config bloat, undocumented settings, and
actual token/cache usage. Filesystem access isn't scoped to the account currently running the
skill — it can read `~/.claude-personal` and `~/.claude-work` regardless of which alias invoked
it (`claudep`, `claudew`, or `claudec`).

**Strictly user-invoked.** Only activate when the user types `/token-audit`. Never auto-trigger.

## Scope

Two config dirs, always both, every run:
- `~/.claude-personal`
- `~/.claude-work`

A third config dir may exist that mirrors the personal one — e.g. via symlinked `commands`,
`output-styles`, `plugins`, and even `projects` subdirectories pointing back at
`~/.claude-personal`. Check for this before treating any extra `~/.claude-*` dir as a separate
account: `ls -la <dir>/projects` — if it resolves to a symlink onto `~/.claude-personal/projects`,
its session transcripts and usage data aren't separate at all, they're the same files. Auditing
it again would just re-report the personal account's own numbers under a different label. Skip
it silently once confirmed; don't re-investigate this each run.

The bare `~/.claude` (no suffix) is not an account — it's the CLI's default install path, and is
typically walled off from direct use by a shell alias. Include it only in the settings-key check
(Step 4), since stray keys have shown up there before (e.g. an undocumented `auto_dream` flag);
skip it for everything else.

## Step 1 — CLAUDE.md sizes

For each of the two config dirs, find every `CLAUDE.md` reachable from it (global `~/.claude/CLAUDE.md`
plus any project-level ones under that account's known project paths — check `<config_dir>/.claude.json`
key `projects` for the tracked path list). Report byte size and a rough token estimate (bytes / 4) per
file, and a combined total per account. Flag any single file over ~5k tokens (~20KB) — that's the bar
used in prior audits.

## Step 2 — MCP servers

Read `mcpServers` from each account's `settings.json` (and `.mcp.json` / `~/.claude.json` project-scoped
servers if present). Report server count per account and flag anything that looks like a proxy/gateway
server fronting many tools (worth a tool-count check) versus small direct servers. Note whether tool
deferral is active (large tool counts should be deferred, not all loaded up front).

## Step 3 — Model / effort config

Report `model` and `effortLevel` from each account's `settings.json`.

## Step 4 — Undocumented settings.json keys

Fetch the official schema and diff against it:
1. `WebFetch` on `https://code.claude.com/docs/en/settings` and `https://code.claude.com/docs/en/settings.md`
   (the raw `.md` variant sometimes surfaces keys the rendered page truncates) — ask for the complete
   list of top-level documented key names.
2. List the top-level keys actually present in each of `~/.claude/settings.json`,
   `~/.claude-personal/settings.json`, and `~/.claude-work/settings.json`.
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

Check for a custom `agents/` directory under each config dir. Most runs will find none — that's not
a finding, just report it plainly.

## Step 7 — Scheduled jobs (CronList)

Call `CronList`. Note in the output that this tool is session-scoped — it only reports jobs created
via `CronCreate` in the *current* session, not a durable per-account registry. Report what it returns,
but don't treat an empty result as proof no jobs exist anywhere; say so explicitly.

## Step 8 — Cache/token usage totals

Run `python3 <skill_dir>/parse_usage.py <config_dir>` for each of `~/.claude-personal` and
`~/.claude-work` (no date argument — it auto-detects the most recent Mountain-time day with
activity, which may differ between the two accounts if one wasn't used as recently). `<skill_dir>`
is the directory this SKILL.md lives in (resolve it at runtime — it's a symlink target, so use the
actual path, e.g. via `dirname` of the invoked skill file or a known-good absolute path if the
symlink resolution is ambiguous).

Report per account: the date it covers, file count, input/output/cache_read/cache_creation totals,
grand total, and cache_read percentage.

## Output

One report, both accounts side by side per item (a table per step reads better than prose). Lead
with a one-line summary of what's actually wasteful (if anything) — most runs will find nothing
new since the last audit; say that plainly instead of padding the report. Only propose a fix
(editing a settings.json, removing a stray key) after stating the finding and getting confirmation —
this skill reports, it doesn't remediate on its own unless the user asks for that as a follow-up.
