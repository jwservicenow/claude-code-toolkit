# Work Credentials & Auth Methods — Index

Pointer doc only — **no secret values here.** The real content already exists in
`pdi_auth_methods_reference.md` (same folder) — this file is a short map to it plus
the adjacent docs, so "where's the work auth doc" has one answer.

## Primary reference (already the source of truth)

**`pdi_auth_methods_reference.md`** — this folder. Covers every auth path Claude uses
against ServiceNow instances (`empjwells2.service-now.com` PDI):

| # | Method | Identity | Storage |
|---|---|---|---|
| 1 | Basic Auth | `Claude.Code.user1` | macOS Keychain, service `servicenow-pdi-password` |
| 2 | Basic Auth | `admin` | now-sdk's own store (`.now-sdk/`) |
| 3 | OAuth 2.0 + PKCE | Your ServiceNow login (browser consent) | macOS Keychain, `Claude Code-credentials-*` |
| 4 | Org SSO (not yours to manage) | Corporate SSO | ServiceNow-internal |

Read that file for full detail (scopes, read/write coverage, hardening priorities).

## Supporting / deeper detail

| File | What it adds |
|---|---|
| `~/ClaudeOS/work/projects/mcp-server-servicenow-otb/auth_reference.md` | Stack A OAuth client detail — sys_id, client_id, endpoints, PKCE flow, security posture live-verified against `oauth_entity` + `sys_properties` |
| `~/ClaudeOS/work/repos/claude-toolkit/docs/pdi_native_mcp_install_guide.md` | How the native MCP OAuth setup is installed/configured |
| `~/ClaudeOS/work/projects/pdi/pdi-curl.sh` | The actual Basic Auth curl helper (`Claude.Code.user1`) — pulls password from Keychain at runtime |
| `~/ClaudeOS/work/projects/BeyondTrust-KeyVault/README.md` | Separate track: BeyondTrust Password Safe as an *external* credential vault for ServiceNow Discovery (SSH-key resolver spike) — not used for Claude's own auth, but the vault architecture ServiceNow customers use |

## Key things to remember (carried over, still true)

- `Claude.Code.user1` (basic auth) and `admin` (now-sdk) are **different identities** on
  the same PDI — easy to conflate.
- `mcp-server-custom-crew`'s ServiceNow MCP is **explicitly off-limits** per prior direction,
  even though it has broader write coverage.
- Only Basic Auth (`Claude.Code.user1` / `pdi-curl.sh`) supports arbitrary table writes
  outside the curated native MCP tool set.
- now-sdk (`admin`) is read-only in practice — no insert/update CLI command exists.

## Not yet indexed (flag if you need these)

- Any credentials for non-ServiceNow work tools/services outside this PDI scope
- 1Password/vault entries, if any exist for work credentials beyond Keychain
