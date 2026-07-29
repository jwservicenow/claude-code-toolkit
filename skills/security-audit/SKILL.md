---
name: security-audit
description: Use when the user types /security-audit to run a comprehensive security scan of the whole project — OWASP Top 10 patterns, dependency CVEs, hardcoded secrets, auth/authorization weaknesses, and risky configuration. Broader than a diff review — it audits the entire codebase, not just pending changes. Strictly user-invoked — never auto-triggers.
---

# /security-audit — Security Audit Skill

Comprehensive security analysis covering common vulnerability patterns, dependency risks, and configuration weaknesses across the whole codebase.

**Strictly user-invoked.** Only activate when the user types `/security-audit`. Never auto-trigger.

**Scope note:** this audits the full project tree as it stands, not just a diff. If the user wants only the pending/uncommitted changes reviewed, that's the separate `security-review` skill — mention it if the ask sounds like it's really about a diff.

## Process

### Step 1 — Map the codebase

Identify the language(s)/framework(s) in play (grep for server frameworks, ORMs, templating engines, auth libraries) so the right checks apply — e.g. Django/Flask/Express-specific CSRF and header conventions differ.

### Step 2 — Injection Risks

Grep/read for:
- SQL built via string concatenation or f-strings instead of parameterized queries/ORM calls
- Shell execution (`subprocess`, `os.system`, `exec`, backticks) fed with unsanitized input — command injection
- Templates rendering user input without escaping (look for `| safe`, `dangerouslySetInnerHTML`, raw string interpolation into HTML) — XSS
- File operations that build paths from user input without normalization/allowlisting — path traversal

### Step 3 — Authentication & Authorization

- Session management: token/cookie flags (`HttpOnly`, `Secure`, `SameSite`), session fixation, weak session ID generation
- CSRF protection present on state-changing routes
- Access control: routes/handlers that check authentication but not authorization (any user can hit another user's resource), missing checks entirely
- Password handling: hashing algorithm (bcrypt/argon2/scrypt vs plain/MD5/SHA1), salting, any passwords logged or stored in plaintext

### Step 4 — Configuration

- Debug mode / verbose error pages enabled in what looks like a production config
- CORS: wildcard origins (`*`) combined with credentials, or overly broad allowed-origin lists
- Missing security headers (CSP, `X-Content-Type-Options`, `X-Frame-Options`, HSTS) in server/middleware config
- Error handlers that leak stack traces, internal paths, or DB errors to the client

### Step 5 — Hardcoded Secrets

Grep for API keys, tokens, connection strings, and credentials committed directly in source — common patterns: `api_key =`, `password =`, `Bearer `, AWS/GCP key formats, private key blocks, `.env` files accidentally tracked in git.

### Step 6 — Dependencies

- Run the ecosystem's audit tool if a manifest exists (`npm audit`, `pip audit`, etc.) for known CVEs in direct and transitive dependencies
- Flag outdated packages that have a security patch available in a newer version
- Note any dependency pinned to a version with a publicly known malicious release, if one is recognized

If there's no dependency manifest in the project, say so plainly instead of forcing this section — don't invent findings.

## Output

Produce one report with these sections, in this order:

1. **Summary scorecard** — counts of findings by severity (Critical/High/Medium/Low), one line.
2. **Findings**, most severe first. Each finding: file path + line reference, category (from the sections above), what's wrong, why it's exploitable, and concrete remediation (the actual fix, not just "sanitize input").
3. **Dependency CVEs** (if applicable) — package, severity, direct vs transitive, fixed version.
4. **Priority-ranked action list** — what to fix first, grouped Critical → Low.

Only report what's actually verifiable in the code — don't speculate about hypothetical frameworks or files that aren't present. This skill reports; it doesn't apply fixes unless the user asks as an explicit follow-up.
