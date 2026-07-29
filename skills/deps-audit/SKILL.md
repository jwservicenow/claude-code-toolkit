---
name: deps-audit
description: Use when the user types /deps-audit to run a comprehensive dependency health check on a project — security vulnerabilities, outdated packages, unused dependencies, and license compliance. Detects the package manager (npm/yarn/pnpm, pip/poetry, etc.) and produces a prioritized report. Strictly user-invoked — never auto-triggers.
---

# /deps-audit — Dependency Audit Skill

Comprehensive dependency analysis covering security vulnerabilities, outdated packages, unused dependencies, and license compliance.

**Strictly user-invoked.** Only activate when the user types `/deps-audit`. Never auto-trigger.

## Process

### Step 1 — Detect the package manager

Look in the working directory for manifest files and pick the matching tool:
- `package-lock.json` → npm, `package.json` → npm/yarn/pnpm (check for `yarn.lock` / `pnpm-lock.yaml` to disambiguate)
- `requirements.txt`, `pyproject.toml`, `Pipfile` → pip / poetry / pipenv
- If none found, or multiple ecosystems coexist (e.g. a JS frontend + Python backend), say so and ask which to audit, or audit each separately.

### Step 2 — Run the built-in audit

- npm: `npm audit --json`
- yarn: `yarn audit --json`
- pip: `pip audit` (or `poetry run pip audit` / `pipenv check` if that's the tool in use)

Capture critical/high severity issues, affected package, whether the vulnerability is in a direct or transitive dependency, and known exploit availability if reported.

### Step 3 — Check for outdated packages

- npm: `npm outdated --json`
- yarn: `yarn outdated`
- pip: `pip list --outdated`

Group results by update type (major / minor / patch). Flag major bumps as breaking-change risk and note a migration guide link if one is easy to find (changelog/release notes URL from the registry).

### Step 4 — Detect unused dependencies

- JS/TS: use `depcheck` if available (`npx depcheck`); otherwise grep imports/requires across source files against `package.json` dependencies as a fallback.
- Python: no single standard tool — cross-reference `import` statements against installed top-level packages (e.g. via `pipreqs --print` or a manual grep) and flag likely-unused entries as low-confidence.

Separate findings into: unused `dependencies`, unused `devDependencies`, and any duplicate packages that appear to serve the same purpose (e.g. both `moment` and `dayjs`).

### Step 5 — License compliance

List the license for each direct dependency (`npm ls --json` + registry metadata, or `pip-licenses` for Python). Flag copyleft licenses (GPL, AGPL, LGPL) explicitly — these carry the most compliance risk for closed-source projects. Note any dependency with no detectable license.

## Output

Produce one report with these sections, in this order:

1. **Summary table** — counts of critical/high vulns, outdated majors, unused deps, and any copyleft licenses found; one line each.
2. **Security Vulnerabilities** — critical/high first, each with the affected package, severity, whether it's direct or transitive, and the remediation step (usually a version bump or `npm audit fix`).
3. **Outdated Packages** — grouped by major/minor/patch, breaking-change warnings called out for majors.
4. **Unused Dependencies** — split into dependencies vs devDependencies vs duplicates.
5. **License Compliance** — table of direct deps and license type, copyleft entries flagged.
6. **Priority-ranked action items** — a short ordered list of what to fix first (security first, then breaking-risk majors, then cleanup), with one-command fixes called out where the fix is safe to run directly (e.g. `npm audit fix` for non-breaking patches).

Keep the report concise — tables over prose for each section. Don't apply any fixes automatically; this skill reports, it doesn't remediate on its own unless the user asks for that as a follow-up.
