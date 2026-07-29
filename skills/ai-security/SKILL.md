---
name: ai-security
description: Use when the user types /ai-security to assess the security of AI/ML systems and LLM-based agents — prompt injection (direct and indirect), agent tool abuse, guardrail/blocklist resistance, model inversion and data poisoning exposure, mapped to MITRE ATLAS. This is the model-and-agent layer, NOT general application security (see /security-audit) and not dependency risk (see /deps-audit). Strictly user-invoked — never auto-triggers.
---

# /ai-security — AI & LLM Security Assessment

Security assessment of AI/ML systems and LLM-based agents: prompt injection, jailbreak and guardrail resistance, model inversion risk, data poisoning exposure, and agent tool abuse — mapped to MITRE ATLAS techniques.

**Strictly user-invoked.** Only activate when the user types `/ai-security`. Never auto-trigger.

**Scope boundary.** This covers the *model and agent* layer. Application-layer vulnerabilities (SQLi, XSS, secrets, config) belong to `/security-audit`; dependency CVEs belong to `/deps-audit`. Say so and defer rather than duplicating them here.

## Assessment principle

Assess the system that exists, not the system the checklist assumes. Most AI security checklists are written for a public-facing chatbot with untrusted human users. If the target is an internal agent with one operator, the dominant risk is almost never a human typing jailbreaks — it is **untrusted machine-generated content reaching the model's context**, and what the agent is permitted to *do* with the output. Score the real surface; explicitly mark inapplicable categories N/A with the reason instead of generating a risk number for a threat that does not exist.

## Process

### Step 1 — Map the AI surface

Before assessing anything, inventory what actually exists:
- **Models**: local or hosted, pre-trained / fine-tuned / RLHF'd, who can reach the endpoint
- **Agents**: what tools they hold, what privilege those tools carry, what gates sit in front
- **Context sources**: every string that reaches a prompt — user input, retrieved documents, logs, command output, API responses
- **Guardrails**: system prompts, schema validation, blocklists/allowlists, human approval gates, output filtering

State the map in a few lines before assessing. The trust boundary that matters is: *which of those context sources can an attacker influence?*

### Step 2 — Trace the untrusted-content paths (primary method)

This is the core of the assessment and the step that produces most findings. It is a code-reading procedure, not a scan. Do all five sub-steps; they are mechanical on purpose, so two people running them on the same repo get the same table.

The model is a pass-through with two legs. Trace **inbound** (what reaches its context) and **outbound** (what its answer is allowed to do). Skipping the outbound leg is the most common way a real finding is missed.

#### 2a — Locate every prompt-construction site

Find every place a string is assembled and handed to a model. Do not trust naming; grep for the call, then walk back to the assembly.

```bash
grep -rnE "messages\s*=|\"role\"\s*:|prompt|system_prompt|_build_prompt|\.format\(|f\"\"\"" --include=*.py --include=*.ts --include=*.js .
grep -rnE "chat|completions|generate|invoke|\.create\(" --include=*.py --include=*.ts --include=*.js .
```

Also check: prompt template files (`.txt`, `.jinja`, `.md`), system prompts in config or env vars, few-shot examples loaded from disk, and anything appended to a conversation history that persists across turns.

List each site as `file:line`. If there is exactly one, say so — a single funnel is a finding in your favor and worth stating.

#### 2b — Enumerate what is interpolated at each site

For every site, list every expression that becomes part of the string — every `{}`, every `+`, every `json.dumps(...)`, every dict serialized wholesale. **Serializing a whole object counts as interpolating every field in it**, including fields added later by code you did not read.

#### 2c — Follow each interpolated value back to its origin

Do not stop at the local variable. Follow the call chain until you reach the point where the bytes enter the process: a `subprocess` call, a socket or HTTP read, a file read, a DB row, an env var, or a literal in the source. Record the chain as `origin → … → sink`.

The stopping condition is a syscall or a literal. `ev = finding.get("evidence")` is not an origin; it is a hop.

#### 2d — Classify each origin by who can write to it

Assign exactly one class per origin. This is where the finding actually appears.

| Class | Meaning | Prompt-injection weight |
|---|---|---|
| `static` | Literal in source, or config only committers change | None |
| `operator` | The trusted human running the system | Low — trusted by design |
| `machine-own-state` | Output of our own program describing only our own state (`df`, `uptime`, `zpool status`) | Low |
| `machine-third-party-text` | Machine output that **embeds text someone else chose** | **High — this is the vector** |
| `remote-user` | Anything typed by a non-operator, directly or via an API | High |

The one question that decides `machine-own-state` vs `machine-third-party-text`:

> **Is any substring of this output chosen by someone other than us?**

Apply it literally, per field. Things that fail it constantly and get waved through:

- **Log lines** — `journalctl`, `auth.log`, app logs. Log text contains usernames, User-Agents, request paths, TLS SNI names, and error strings supplied by whoever contacted the service. A failed SSH login writes an attacker-chosen username straight into the journal.
- **Error and exception text** — often quotes the offending input verbatim.
- **Filenames and directory listings** — whoever can create a file names it.
- **HTTP/API response bodies** — including from vendors you trust, and including package names and CVE descriptions.
- **Hostnames, container names, process command lines, git commit messages, ticket bodies, email subjects.**

**Read-only is not the same as trusted.** A probe restricted to read-only verbs is bounded in *side effects*, not in *content*. `journalctl` cannot change the system and can still deliver an attacker's chosen sentence into the model's context. An allowlist of safe verbs does nothing about the bytes those verbs return. State this explicitly whenever a codebase justifies a source as safe because it is read-only.

For every `machine-third-party-text` or `remote-user` origin, then ask:
1. Is it delimited, escaped, or fenced as data before interpolation? (Serializing to JSON is *not* a security boundary — the model reads the string values.)
2. Is it length-capped?
3. Does the system prompt tell the model the block is untrusted data and must not be followed as instructions?
4. Does anything downstream act on the model's answer without a human reading it? (If yes, this inbound finding and the outbound leg compound — say so.)

A "no" to 1–3 on a `machine-third-party-text` origin is an indirect prompt injection finding, **AML.T0051.001**, minimum High. It is Critical when 4 is also true.

#### 2e — Trace the outbound leg: model output to privileged sink

Same procedure, reversed. Take the model's response and follow every field of it to whatever consumes it.

```bash
grep -rnE "json\.loads|parse|response\[|\.content|choices\[0\]" --include=*.py --include=*.ts .
```

For each consumer, record: what privilege it runs with, what it validates, and whether a human sees the content before it acts. Then apply the two questions that find real bugs:

> **Does the code validate the label, or the payload?**

A dispatcher that decides an action is safe from a *type name*, *action name*, or *tool name* the model itself chose is trusting the attacker's classification. The name and the arguments are the same untrusted blob. If `type == "read_only_thing"` grants execution while the arguments attached to it are accepted as an unvalidated dict, the label is a suggestion, not a control — the model (or content that steered it) picks both sides. That is **AML.T0051.002**, Critical when the sink is privileged.

> **What runs before the human is asked?**

Find the approval gate, then look at what executes *above* it in the flow. Anything auto-executed pre-approval is outside the gate no matter what the gate does. Two flags:
- Actions partitioned into "auto" and "needs approval" by a model-supplied field.
- A re-verification or drift check placed *after* the auto-execute branch.

Also check: is the sink argv rebuilt from typed fields, or is a string interpolated into a shell? Are parameters bounded (path prefixes, id ranges, enum values), or accepted as any dict? Is every call audit-logged with the content that triggered it?

#### 2f — Emit the trace tables

Two tables, both required in the report even if a row is clean. They are the artifact that makes the assessment reproducible.

**Inbound — untrusted content to prompt**

| Source (origin) | Class | Path to sink | Prompt site | Delimited? | Attacker-reachable? | Finding |
|---|---|---|---|---|---|---|
| `journalctl` stdout over SSH | machine-third-party-text | `run_probe()` → `gather()` → `finding["evidence"]` → `_build_prompt()` | `hl_llamacpp.py:160` | No — `json.dumps` only | Yes — anyone reaching sshd writes a failed-login username into the journal | SEC-5, High, AML.T0051.001 |

**Outbound — model output to sink**

| Model field | Consumer | Privilege | Validated by | Pre-approval? | Finding |
|---|---|---|---|---|---|
| `actions[].action_type` | `_is_read_only()` → `run_typed()` | root via broker | Name equality only; `fields.args` any dict | Yes — runs before the operator sees anything | SEC-4, Critical, AML.T0051.002 |

Rows above are worked examples from a real assessment. Replace them; keep the columns.

#### 2g — Prove the traced path with the scanner

Once a path is traced, use the bundled scanner as evidence that content on that path is actually classifiable as an injection attempt — not as the discovery method. Pipe **real** content from the traced source.

```bash
# real untrusted content from a traced source
ssh host 'journalctl -u sshd -n 500' | python3 <skill-dir>/scripts/ai_threat_scanner.py --stdin

# a corpus file (JSON array of strings, or of {"text": ...} objects)
python3 <skill-dir>/scripts/ai_threat_scanner.py --prompts corpus.json

# signature quality, no target involved
python3 <skill-dir>/scripts/ai_threat_scanner.py --self-test
```

Model-level scoring flags: `--target-type {llm,classifier,embedding}`, `--access-level {black-box,gray-box,white-box}`, `--training-scope {fine-tuning,rlhf,retrieval-augmented,pre-trained-only,inference-only}`. Categories that do not apply to the target come back **N/A with a reason**, not as a low score. Add `--no-score` for scan-only, `--json` for machine output, `--list-signatures` to print the signature set.

**Exit codes reflect the scan only**, not the risk scores: `0` clean (or no corpus given), `1` high-severity matches, `2` critical matches, `3` refused — `--access-level gray-box|white-box` requires `--authorized` attesting written authorization exists.

Signature reference: see **Reference — injection signatures** below.

**A clean scan is not a clean path.** The scanner measures a corpus; the trace measures the system. If 2d found an undelimited `machine-third-party-text` origin, the finding stands whether or not today's log sample happens to contain an attack string. Report it as traced-and-reachable, with the scan as supporting evidence.

#### Direct injection

Direct injection — adversarial user input overriding system prompt, role, or constraints — is the `remote-user` row of the same inbound table. On a single-operator internal system there is often no such row. If so, mark it N/A with the reason rather than scoring it.

### Step 3 — Guardrail and gate resistance

Where a deterministic guard (blocklist, allowlist, schema validator) is the backstop, **test it rather than reading it**. A blocklist that looks thorough often fails on trivial mutations — long-form flags, reordered flags, inserted flags, absolute paths, env-var prefixes, quoting.

Use the bundled fuzzer:

```bash
python3 <skill-dir>/scripts/gate_probe.py --module <path/to/gate.py> --function is_forbidden
```

It mutates a corpus of genuinely dangerous commands and reports which variants slip past. Options: `--json` for machine output, `--show-caught` to also list blocked variants, `--quiet` for summary only. Exit codes: `0` no bypasses, `1` bypasses found, `2` a base command was missed entirely (the blocklist does not even catch the canonical form).

Any bypass of a guard that is the *sole* automated backstop in front of privileged execution is Critical, regardless of how hard it is to reach.

### Step 4 — Agent tool abuse

Step 2e already produced the outbound table; this step reads it against the standard techniques and checks the mitigations.

| Attack | ATLAS | Check |
|---|---|---|
| Direct tool injection | AML.T0051.002 | Can a prompt request a destructive tool call directly? |
| Indirect tool hijacking | AML.T0051.001 | Can retrieved/log content trigger a tool call? (Join an inbound row to an outbound row — if a `machine-third-party-text` source feeds a prompt whose output reaches a privileged sink, the chain is complete.) |
| Approval gate bypass | AML.T0051.002 | Can the confirmation step be skipped or pre-satisfied? What executes above the gate? |
| Privilege escalation via tools | AML.T0051 | Can tools reach resources outside the intended scope? Are parameters bounded? |

Mitigations to check for: human approval gates on destructive/exfiltrating calls; minimal tool scope; **parameter validation before invocation** (not just action-name validation); audit logging of every call with its triggering context; output filtering before results re-enter agent context.

### Step 5 — Model inversion and data poisoning

Score by access level and training scope — but only if they apply.

| Access | Inversion risk | Mechanism | Mitigation |
|---|---|---|---|
| white-box | Critical (0.9) | Gradient inversion, membership inference via logits | No gradient access in prod; differential privacy |
| gray-box | High (0.6) | Confidence-based membership inference | Disable logit outputs; rate limit |
| black-box | Low (0.3) | Label-only, high query volume | Monitor systematic querying |

| Training scope | Poisoning risk | Surface | Mitigation |
|---|---|---|---|
| fine-tuning | High (0.85) | Direct training data submission | Audit examples; provenance tracking |
| rlhf | High (0.70) | Feedback manipulation | Vet feedback contributors |
| retrieval-augmented | Medium (0.60) | Document poisoning in the index | Validate content before indexing |
| pre-trained-only | Low (0.20) | Upstream supply chain | Verify model provenance |
| inference-only | Low (0.10) | None | Standard input validation |

Inversion risk is about *what is in the training data*. For stock pre-trained models serving their own operator, there is no proprietary training corpus to reconstruct — mark it N/A and say why, rather than reporting a score.

### Step 6 — Guardrail recommendations

Map each finding to a control. Input: injection signature filter, semantic similarity to known templates, length limits, dedicated safety classifier, explicit untrusted-data fencing in the system prompt. Output: system-prompt confidentiality checks, PII scanning, URL/code validation. Agent: parameter validation, human-in-the-loop gates, scope allowlists, mid-session instruction-override detection.

Prefer controls at the layer that can actually enforce them. Injection is an input-validation problem at the application layer — a model version bump does not fix it.

## Output

1. **AI surface map** — models, agents, tools, context sources, existing guardrails.
2. **Trace tables** — the inbound and outbound tables from Step 2f, complete, including clean rows. These are required; a report without them is not a completed assessment.
3. **Scorecard** — findings by severity, plus categories marked N/A with reasons.
4. **Findings**, most severe first: file:line, ATLAS ID, what's wrong, realistic exploit path, concrete fix.
5. **Gate resistance results** — if a deterministic guard was fuzzed, the pass/bypass numbers.
6. **Scanner evidence** — what was piped, what matched, exit code. Note explicitly when a path is traced-and-reachable but the sample was clean.
7. **Priority-ranked actions**.

Report only what is verifiable in the code and configuration. Do not fabricate a prompt corpus and report scores against it as if it measured the system.

## Reference — injection signatures

Used by `ai_threat_scanner.py` (Step 2g) to classify content already known to be on a traced path. These describe *what an attack looks like*, not *where the system is exposed* — the trace does that. `--list-signatures` prints the live set.

| Signature | Severity | ATLAS | Pattern |
|---|---|---|---|
| direct_role_override | Critical | AML.T0051 | System-prompt override, role-replacement directives |
| indirect_injection | High | AML.T0051.001 | Template token splitting (`<system>`, `[INST]`, `###system###`) |
| jailbreak_persona | High | AML.T0051 | "DAN mode", "developer mode enabled" |
| system_prompt_extraction | High | AML.T0056 | "Repeat your initial instructions" |
| tool_abuse | Critical | AML.T0051.002 | "Call the delete tool", "bypass the approval check" |
| data_poisoning_marker | High | AML.T0020 | "Inject into training data", "poison the corpus" |

## Anti-patterns

1. **Leading with the scanner instead of the trace** — a corpus scan measures the corpus. It cannot tell you that `journalctl` output reaches your prompt undelimited. Trace first; scan to prove.
2. **Testing only published jailbreak templates** — DAN/STAN are already blocked by frontier models and irrelevant to internal agents. Test domain-specific injection paths instead.
3. **Treating "read-only" as "trusted"** — read-only bounds side effects, not content. An allowlisted read-only probe still returns attacker-authored text.
4. **Stopping the trace at a local variable** — `x = get_evidence()` is a hop, not an origin. Follow it to the syscall or the literal.
5. **Validating the label instead of the payload** — accepting a model-chosen action name as proof of safety while its arguments go unvalidated.
6. **Tracing inbound only** — half the trace finds half the findings; the privileged-sink leg is where the Criticals are.
7. **Treating static signature matching as complete** — signatures catch known patterns only; novel phrasing passes. Complement with adversarial testing and semantic filtering.
8. **Not testing with the production system prompt** — a payload that fails in isolation may succeed against the real prompt's context.
9. **Deploying without output filtering** — input validation alone fails the moment injection succeeds; output filtering is the required second layer.
10. **Assuming model updates fix injection** — it is an application-layer input-validation problem, independent of model version.
11. **Skipping authorization for gray/white-box testing** — those access levels enable real data extraction. Written authorization first.
12. **Scoring inapplicable categories** — a risk number for a threat the system cannot face is noise that hides the real findings.
