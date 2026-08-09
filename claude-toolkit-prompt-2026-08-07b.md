Goal:
Keep ServiceNow docs-mirror path routing accurate across the Desktop guide (Project Instructions payload) and the /servicenow_rag Claude Code command.

State & decisions:
AI Search paths (platform-administration/ai-search/{overview-ais,explore-ais,configuring-ais,use-ais,...}.md) confirmed live — prior session's "gap" flag was a false alarm from a bad curl test (dropped the ai-search/ subfolder); no gap ever existed.
Desktop guide's CMDB/IRE paths were missing configuration-management-database-cmdb/ subfolder; servicenow_rag.md already had it right — guide brought in line with the command file, not the other way around.
Service Graph Connectors: no consistent per-vendor filename pattern exists; guide's old "cmdb-data-mapping-{vendor}.md" claim was fictional — replaced with accurate guidance (search servicenow-platform/index.md by vendor name, no own index for that folder).
servicenow_rag.md had zero platform-administration routing — added routing-table entry + known-direct-paths block for AI Search.
ITOM items (Metric Intelligence, Event Management, Service Operations Workspace, HLA) already correct in both files — no gap, no change made.
curl inside a while-loop or backgrounded subshell is blocked by this session's sandbox ("command not found: curl"); a single curl call with multiple URL args works fine — use that pattern for any future bulk path verification here.

Constraints:
gh account must be jwservicenow before any push to claude-toolkit — confirmed each time.
Push banner printed before every git push.

Previous session:
Resumed prior session's paused AI Search / platform-administration verification.
Found and reused prior audit ~/ClaudeOS/work/projects/search-routing/audit8-known-locations-paths.txt as ground-truth checklist; HTTP-verified all 84 paths live.
Corrected own earlier false "gap confirmed" verdict on AI Search.
Found 2 real bugs in docs/servicenow-mirror-desktop-guide.html (missing CMDB/IRE subfolder x5 files, fictional SGC filename pattern) and 1 real gap in commands/servicenow_rag.md (no platform-administration routing).
Applied all 4 fixes, committed (e1d59d9), pushed to jwservicenow/claude-toolkit main.

Next action:
None pending — changeset applied and pushed clean. If resuming, spot-check the live guide/command reflect commit e1d59d9 (configuration-management-database-cmdb/ subfolder present in Known Doc Locations; platform-administration routing present in servicenow_rag.md).

Key artifacts:
Repo: ~/ClaudeOS/work/repos/claude-toolkit (github.com/jwservicenow/claude-toolkit, gh account jwservicenow)
Guide: docs/servicenow-mirror-desktop-guide.html — live: https://jwservicenow.github.io/claude-toolkit/docs/servicenow-mirror-desktop-guide.html
Command: commands/servicenow_rag.md
Commit: e1d59d9 (7d64dcb..e1d59d9)
Ground-truth checklist: ~/ClaudeOS/work/projects/search-routing/audit8-known-locations-paths.txt (84 paths, all HTTP-verified live 2026-08-07 except 3 already-known retired files)
Mirror: https://github.com/ServiceNow/ServiceNowDocs (branch: australia)

Resume instruction:
Nothing outstanding on this thread. If new path-accuracy questions come up, reuse audit8-known-locations-paths.txt as a starting checklist and verify with single multi-URL curl calls — loops and backgrounded curl are sandbox-blocked in this environment.
