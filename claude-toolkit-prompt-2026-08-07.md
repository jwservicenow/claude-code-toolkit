STATUS 2026-08-07 — SUPERSEDED by claude-toolkit-prompt-2026-08-07b.md.
Goal:
Condense the ServiceNow Claude Desktop RAG setup guide for busy peers, push it live, then check whether its Project Instructions payload has anything worth porting into the more advanced /servicenow_rag Claude Code command.

State & decisions:
Chose the "Brief" tier (4 numbered steps, one-line rationale, collapsible full Instructions payload) over very-brief/extremely-brief.
Instructions payload (Core Rules, Known Doc Locations, etc.) kept byte-identical across all tiers — only surrounding prose/chrome condensed, never the paste-in payload.
Live file docs/servicenow-mirror-desktop-guide.html rebuilt as a standalone full HTML doc (doctype/head/body), not an Artifact fragment.
"GitHub docs mirror" linked to https://github.com/ServiceNow/ServiceNowDocs#servicenowdocs everywhere the exact phrase appears (README.md x3, commands/servicenow_rag.md x1). Near-miss phrasing ("GitHub mirror" without "docs") left untouched.

Constraints:
gh account must be jwservicenow before any push to this repo — confirmed each time.
Push banner printed before every git push.

Previous session:
- Fetched live guide, built/published 3 condensed HTML tiers as artifacts for review.
- Added missing Copy button to Brief's Instructions block (toolbar pattern, stays visible while scrolling).
- Committed+pushed Brief as live guide (cb5c8a1), eyebrow text change (de1693e), README links (0e3e8de), command-file link (7d64dcb).
- Read commands/servicenow_rag.md in full — it's far more advanced/battle-tested (live-verified fixes dated 2026-07-30: routing corrections, offset-jump logic, retry-on-timeout, curated community KB boards, trust signals) than the Desktop Instructions.
- Found one untested candidate gap: Desktop Instructions reference a "platform-administration" publication (AI Search: overview-ais.md, configuring-ais.md, use-ais.md) absent from servicenow_rag.md's routing table entirely. Also flagged, untested: Service Operations Workspace for ITOM paths, and direct-path shortcuts for Metric Intelligence/Event Management.
- User interrupted the verification curl batch (rejected tool call) and asked to pause — nothing confirmed live or dead yet.

Next action:
Ask before re-running the verification batch (see Awaiting). Once cleared: curl/fetch llms.txt for "platform-administration"/"ai-search"/"service-operations-workspace" entries, and HTTP-status-check platform-administration/ai-search/{overview-ais,configuring-ais,use-ais}.md plus the SOW/Metric Intelligence/Event Management paths. 200 = live, worth porting into servicenow_rag.md; 404 = stale, drop it. If llms.txt has no platform-administration entry, check where AI Search actually lives before concluding it's a real gap.

Awaiting:
User paused with no stated reason after rejecting the curl verification batch — confirm OK to run read-only fetches against public raw.githubusercontent.com URLs before resuming.

Key artifacts:
Repo: ~/ClaudeOS/work/repos/claude-toolkit (github.com/jwservicenow/claude-toolkit, gh account jwservicenow)
Live guide: https://jwservicenow.github.io/claude-toolkit/docs/servicenow-mirror-desktop-guide.html
Command file: commands/servicenow_rag.md
Mirror: https://github.com/ServiceNow/ServiceNowDocs (branch: australia)
Recent commits: cb5c8a1, de1693e, 0e3e8de, 7d64dcb

Resume instruction:
Ask Jim whether to proceed with the read-only verification fetches he interrupted, before doing anything else.
