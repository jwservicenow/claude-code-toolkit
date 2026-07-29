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

### Step 2 — Prompt injection (direct and indirect)

**Direct**: adversarial user input overriding system prompt, role, or constraints.

| Signature | Severity | ATLAS | Pattern |
|---|---|---|---|
| direct_role_override | Critical | AML.T0051 | System-prompt override, role-replacement directives |
| indirect_injection | High | AML.T0051.001 | Template token splitting (`<system>`, `[INST]`, `###system###`) |
| jailbreak_persona | High | AML.T0051 | "DAN mode", "developer mode enabled" |
| system_prompt_extraction | High | AML.T0056 | "Repeat your initial instructions" |
| tool_abuse | Critical | AML.T0051.002 | "Call the delete tool", "bypass the approval check" |
| data_poisoning_marker | High | AML.T0020 | "Inject into training data", "poison the corpus" |

**Indirect is usually the higher risk and the more overlooked one.** Trace every path where external or machine-generated content is interpolated into a prompt: retrieved documents, web pages, email bodies, API responses, **log lines, command stdout, and error text**. All of it is untrusted input, not trusted context. For each path, ask: can an attacker (or a compromised/noisy component) get text into it, and is it delimited or sanitized before interpolation?

### Step 3 — Guardrail and gate resistance

Where a deterministic guard (blocklist, allowlist, schema validator) is the backstop, **test it rather than reading it**. A blocklist that looks thorough often fails on trivial mutations — long-form flags, reordered flags, inserted flags, absolute paths, env-var prefixes, quoting.

Use the bundled fuzzer:

```bash
python3 <skill-dir>/scripts/gate_probe.py --module <path/to/gate.py> --function is_forbidden
```

It mutates a corpus of genuinely dangerous commands and reports which variants slip past. Options: `--json` for machine output, `--show-caught` to also list blocked variants, `--quiet` for summary only. Exit codes: `0` no bypasses, `1` bypasses found, `2` a base command was missed entirely (the blocklist does not even catch the canonical form).

Any bypass of a guard that is the *sole* automated backstop in front of privileged execution is Critical, regardless of how hard it is to reach.

### Step 4 — Agent tool abuse

| Attack | ATLAS | Check |
|---|---|---|
| Direct tool injection | AML.T0051.002 | Can a prompt request a destructive tool call directly? |
| Indirect tool hijacking | AML.T0051.001 | Can retrieved/log content trigger a tool call? |
| Approval gate bypass | AML.T0051.002 | Can the confirmation step be skipped or pre-satisfied? |
| Privilege escalation via tools | AML.T0051 | Can tools reach resources outside the intended scope? |

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

Map each finding to a control. Input: injection signature filter, semantic similarity to known templates, length limits, dedicated safety classifier. Output: system-prompt confidentiality checks, PII scanning, URL/code validation. Agent: parameter validation, human-in-the-loop gates, scope allowlists, mid-session instruction-override detection.

Prefer controls at the layer that can actually enforce them. Injection is an input-validation problem at the application layer — a model version bump does not fix it.

## Output

1. **AI surface map** — models, agents, tools, context sources, existing guardrails.
2. **Scorecard** — findings by severity, plus categories marked N/A with reasons.
3. **Findings**, most severe first: file:line, ATLAS ID, what's wrong, realistic exploit path, concrete fix.
4. **Gate resistance results** — if a deterministic guard was fuzzed, the pass/bypass numbers.
5. **Priority-ranked actions**.

Report only what is verifiable in the code and configuration. Do not fabricate a prompt corpus and report scores against it as if it measured the system.

## Anti-patterns

1. **Testing only published jailbreak templates** — DAN/STAN are already blocked by frontier models and irrelevant to internal agents. Test domain-specific injection paths instead.
2. **Treating static signature matching as complete** — signatures catch known patterns only; novel phrasing passes. Complement with adversarial testing and semantic filtering.
3. **Ignoring indirect injection** — for RAG and tool-using agents, poisoned retrieved content and log text outrank direct user input as a vector.
4. **Not testing with the production system prompt** — a payload that fails in isolation may succeed against the real prompt's context.
5. **Deploying without output filtering** — input validation alone fails the moment injection succeeds; output filtering is the required second layer.
6. **Assuming model updates fix injection** — it is an application-layer input-validation problem, independent of model version.
7. **Skipping authorization for gray/white-box testing** — those access levels enable real data extraction. Written authorization first.
8. **Scoring inapplicable categories** — a risk number for a threat the system cannot face is noise that hides the real findings.
