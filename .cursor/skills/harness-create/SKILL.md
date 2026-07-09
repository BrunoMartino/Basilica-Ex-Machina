---
name: harness-create
description: >-
  Interactively creates the project harness docs (architecture rules, coding
  conventions, forbidden patterns, testing expectations, deployment rules,
  domain invariants, operational constraints) from the personal_harness_eng
  templates, asking the user only for what the prompt context does not
  provide, and installs the all-for-harness rule alongside them. Use when
  starting a new project, bootstrapping docs/harness/, or when the user asks
  to create or fill harness docs.
disable-model-invocation: true
---

# Harness Create

Builds the `docs/harness/` documents for a project **step by step**, one doc at a time, and finishes by installing the `all-for-harness` rule so the project is bound to them.

For **brownfield** projects with existing code, prefer [`legacy-explainer`](../legacy-explainer/SKILL.md) (evidence from Graphify). This skill is for **greenfield** or docs-first setups.

## Source templates

| Template (this kit) | Target document |
|---------------------|-----------------|
| `docs/harness/architeture_rules_template.md` | `docs/harness/architecture_rules.md` |
| `docs/harness/coding_conventions_template.md` | `docs/harness/coding_convention.md` |
| `docs/harness/forbidden_patterns_template.md` | `docs/harness/forbidden_patterns.md` |
| `docs/harness/testing_expectations_template.md` | `docs/harness/testing_expectation.md` |
| `docs/harness/deployment_rules_template.md` | `docs/harness/deployment_rules.md` |
| `docs/harness/domain_invariants_template.md` | `docs/harness/domain_invariantes.md` |
| `docs/harness/operational_constraints_template.md` | `docs/harness/operational_constraints.md` |

If the templates are not in the current repo, fetch them from `personal_harness_eng` (see `get-my-tools`) or ask the user where they live.

## Workflow

Copy and track progress:

```
- [ ] Step 1: Extract known context from the prompt/conversation
- [ ] Step 2: Ask ONLY for missing information (AskQuestion)
- [ ] Step 3: Generate each harness doc, one at a time, confirming with the user
- [ ] Step 4: Install .cursor/rules/all-for-harness.mdc in the project
- [ ] Step 5: Summary — docs written, open placeholders left for the user
```

### Step 1 — Extract known context

Before asking anything, mine the prompt, conversation, and repo (README, manifests, existing code) for:

- Language, framework, runtime, package manager
- Architectural style (default is simple MVC per the templates)
- Business domain and core entities
- Test runner and testing culture
- Deploy target (VPS, k8s, serverless, shared hosting…)
- Compliance/data sensitivity (PII, payments, health)

**Never ask for something the context already answers.**

### Step 2 — Ask only the gaps

Use the AskQuestion tool with the unanswered items. Question bank (pick only what is missing):

| Doc | Questions to fill gaps |
|-----|------------------------|
| architecture_rules | Architectural style? (MVC default / other) Modules or bounded areas? Any DDD/Clean exception explicitly enabled? |
| coding_convention | Language + framework conventions? Naming preferences? Lint/format tooling? |
| forbidden_patterns | Anything forbidden beyond the defaults (DDD/Clean/CQRS global, vague Manager/Helper, etc.)? |
| testing_expectation | Test runner? Coverage focus (behavior vs implementation)? E2E in scope? |
| deployment_rules | Deploy target and pipeline? Feature flags available? Migration policy? |
| domain_invariantes | Core business rules that must never break? (ask for 2–3 concrete examples) |
| operational_constraints | Latency/SLA targets? External services + rate limits? Data retention/PII rules? |

Batch questions into a single AskQuestion call when possible. If the user answers "don't know yet", keep the template placeholder and mark it as an open item for the summary.

### Step 3 — Generate docs one at a time

For each document, in the table order:

1. Copy the template structure (do **not** invent new sections).
2. Fill it with context + answers; keep it concrete and short — these docs are read by agents on every relevant change, so avoid filler prose.
3. Replace only what is known; leave unanswered fields as explicit placeholders (`TBD:` + what is needed).
4. Show the doc (or a diff) and confirm before moving to the next one. If the user says "generate all without confirming", proceed straight through.

### Step 4 — Install the all-for-harness rule

Write `.cursor/rules/all-for-harness.mdc` into the target project (copy from this kit's `.cursor/rules/all-for-harness.mdc`). This rule makes the docs **binding**: agents must read and follow them before architectural, testing, deployment, or domain changes.

The rule and the docs are a unit — never leave the docs without the rule.

### Step 5 — Summary

Report:

- Docs written (paths)
- Placeholders / open questions left (`TBD:` items per doc)
- Rule installed at `.cursor/rules/all-for-harness.mdc`

## Guardrails

- Do not fabricate business rules, SLAs, or compliance requirements — ask or leave `TBD:`.
- Do not enable DDD/Clean/Hexagonal in `architecture_rules.md` unless the user explicitly requested it.
- Do not overwrite an existing filled harness doc without confirmation; offer a diff first.
- Keep each generated doc at or below the template's size — the value is in precision, not volume.
