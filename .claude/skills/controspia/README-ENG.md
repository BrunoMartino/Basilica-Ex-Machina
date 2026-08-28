# Controspia — the harness security block

A closed set of **cybersecurity skills** folded into this toolkit: code and infrastructure auditing, incident response, finding triage, authorized offensive operations, and security communication.

This is not the full catalog of the upstream project — only the skills picked for this harness 

[Português](README.md)

## Structure

```
controspia/
├── owasp-audit/          # OWASP Top 10 (2021) over source code
├── api-audit/            # OWASP API Security Top 10 (2023), per endpoint
├── container-audit/      # Dockerfile, Helm/Kustomize, Kubernetes, runtime
├── incident-triage/      # Incident response (NIST SP 800-61)
├── finding-triage/       # One finding → defensible disposition
├── offensive/            # ⚠️ requires explicit authorization for the target
│   ├── recon/            # Attack surface enumeration
│   ├── osint-recon/      # Open source intelligence
│   ├── web-pentest/      # Black-box / grey-box web pentest
│   └── red-legio/        # Red-team engagement (formerly `red-team-engagement`)
├── report/
│   └── security-comms/   # Translate security work for non-technical audiences
├── LICENSE               # MIT (upstream project)
└── README.md / README-ENG.md
```

Each skill lives in its own folder with a `SKILL.md`, in the harness's normal format. The `offensive/` and `report/` subfolders are organizational: they separate what needs formal authorization from what is a communication deliverable.

> If your agent version doesn't discover skills in subfolders, copy the leaf folder (e.g. `offensive/web-pentest/`) straight into `.claude/skills/` — the `SKILL.md` content is unchanged.

## How to use

1. Copy `controspia/` into the target project's `.claude/skills/` (Claude Code) or `.cursor/skills/` (Cursor). Both copies in this repository are identical.
2. Invoke by name (`/owasp-audit`, `/finding-triage`, …) or just describe the task — each `SKILL.md` carries its activation triggers in `description` ("OWASP", "BOLA", "incident response", "triage this finding", …).
3. Bring stack context and priorities. The skills bring methodology and report format; what counts as critical in your domain comes from you and from `docs/harness/`.
4. The offensive skills stop and ask for proof of authorization before any active step. That is deliberate — do not work around it.

### Relationship with the rest of the harness

- `docs/harness/` stays binding (the `all-for-harness` rule): finding severity and priority must be read against `domain_invariantes.md`, `operational_constraints.md`, and `forbidden_patterns.md`.
- Before inferring architecture or flows during an audit, the `graphify-first` rule applies — query the graph, then open only the files it pointed at.
- Production fixes that need coverage follow `persisted-tester`: new tests, existing ones untouched.
- Already in the toolkit and complementary: the `security-auditor` agent (exploitable backend vulnerabilities), `dependency-guardsman` (npm CVEs and supply chain), `data-guardsman` (crypto, secrets, data access), `audit-guardsman` (audit logging), `wordpress-developer` (WordPress surface).

## Audit and response skills

### `owasp-audit` — OWASP Top 10 (2021) audit

**What it does.** Sweeps source code across the ten categories (A01 access control → A10 SSRF) with concrete per-category grep patterns, runtime verification of fixes, and a second-opinion pass. Every finding lands in **Fixed / Deferred / Accepted Risk** — the convention the other skills reuse.

**When to use.** Security review of a codebase or a large PR; "find vulnerabilities", IDOR, SQL injection, XSS, SSRF, misconfiguration.

**When not to use.** If the surface is API-only, `api-audit` is more direct; containers and Kubernetes belong to `container-audit`; a single known finding goes to `finding-triage`.

### `api-audit` — OWASP API Security Top 10 (2023)

**What it does.** Endpoint-by-endpoint pass over REST, GraphQL, and RPC: BOLA, authentication, BOPLA/BFLA and excessive data exposure, resource consumption, sensitive business flows, SSRF, misconfiguration, version inventory, and unsafe consumption of third-party APIs. Includes GraphQL-specific and REST-specific sections.

**When to use.** There is an API contract (OpenAPI, GraphQL schema, router) and you want per-endpoint coverage, including sister routes that slip past the main guard.

**When not to use.** As a replacement for the codebase sweep — the two skills cross-reference each other and are complementary, not alternatives.

### `container-audit` — containers and orchestration

**What it does.** Audits Dockerfiles (base image and supply chain, build-time secret exposure, runtime posture), Kubernetes manifests (Pod Security Standards and admission via OPA Gatekeeper / Kyverno, network policies, secrets, RBAC, resource limits, image policy), and the runtime layer.

**When to use.** Docker, Helm, Kustomize, or Kubernetes sit in the deploy path; image hardening, rootless, distroless.

**When not to use.** Cloud IAM and managed services, and application package CVEs, are out of scope — the former isn't in this block, the latter belongs to `dependency-guardsman`.

### `incident-triage` — incident response (NIST SP 800-61)

**What it does.** Drives triage: classification and severity, initial containment, evidence preservation (order of volatility), initial analysis, IOC extraction, and an incident report with state (Triage → Contained → Analyzing → Resolved).

**When to use.** Right now, with something happening: suspicious access, malware, exposed credentials, "we've been breached".

**When not to use.** Steady-state findings (scanner, audit, advisory) — that's `finding-triage`. The customer and stakeholder communication the incident generates is `report/security-comms`.

### `finding-triage` — one finding, one disposition

**What it does.** Five steps: restate the finding in your own words, check whether it is actually true (false positive, reachability), assign contextual severity instead of the scanner's score, pick the disposition, and write the text that defends it — with ticket fields, owner, and target date.

**When to use.** "Is this real?", "should we fix this?", mitigation plan, accepted-risk justification, compensating controls, contextual CVSS.

**When not to use.** To sweep a whole codebase (use the audit skills) or for an active fire (use `incident-triage`).

## `offensive/` — explicit authorization only

These four skills open with an authorization check and refuse ambiguous targets. Use them on contracted pentests, bug bounty programs with published scope, CTFs, and your own labs. Have scope, window, and written authorization on file before you start.

### `offensive/recon` — attack surface enumeration

**What it does.** Passive recon (DNS, certificates, subdomains, technology fingerprinting) and, with explicit authorization only, the active phase; ends in a prioritized attack surface map.

**When to use.** First phase of an authorized pentest or bug bounty, mapping an external footprint.

**When not to use.** Against targets that are neither yours nor in a published scope.

### `offensive/osint-recon` — open source intelligence

**What it does.** Collects and correlates public sources: domain and infrastructure, organization, emails and usernames, document metadata, threat intel. Opens with an ethics check before collection.

**When to use.** Digital footprint assessment, investigating a domain, threat intelligence, context for authorized social engineering.

**When not to use.** Profiling people without a legitimate, documented purpose. It's the investigative counterpart to `recon`, not a substitute.

### `offensive/web-pentest` — web application pentest

**What it does.** Nine phases against a live target: configuration and deployment, identity management, authentication, **authorization** (the highest-yield phase), session management, input validation, error handling, business logic, and client-side. Burp Suite and OWASP ZAP workflows, plus a report format with reproduction steps.

**When to use.** You already have a target list, credentials (or guest access), and authorization — ideally after `recon`.

**When not to use.** To read code (that's `owasp-audit`) or to test detection and response (that's `red-legio`).

### `offensive/red-legio` — red-team engagement

**What it does.** Plans and runs an authorized, multi-week, objective-based engagement: three models (external, assumed breach, purple), pre-engagement with an executive sponsor and rules of engagement, an ATT&CK emulation plan, blue-team deconfliction, execution, and a debrief that tracks recommendations to closure.

**When to use.** The goal is to test whether detection and response actually work, not to find vulnerabilities.

**When not to use.** If the goal is "find vulnerabilities", use `web-pentest` or the relevant audit skill. This carries the strongest refusal posture in the block.

> Renamed from upstream `red-team-engagement`: both the folder and the `SKILL.md` `name` field are `red-legio`. Invoke it by that name.

## `report/` — communication

### `report/security-comms` — translating security for decision-makers

**What it does.** Drafts (or reviews) deliverables for seven audiences — board, executive leadership, engineering leadership, the individual engineer, customer success / sales engineering, customers under public disclosure, and procurement / legal / compliance — with what each one needs and what makes them stop reading. Two modes: draft from technical input, or review a draft. Ships templates (board incident update, executive summary, customer disclosure, risk and spend justification).

**When to use.** The technical work is done and has to land outside security: incident communication, post-mortem narrative, audit findings for stakeholders, spend justification.

**When not to use.** As a source of technical remediation detail — that comes from the audit skills and `finding-triage`.

## References to skills that were not included

The `SKILL.md` files keep their original text and cite upstream skills that were **not** brought over — among others: `dependency-audit`, `cloud-audit`, `iam-audit`, `siem-detection`, `disk-forensics`, `breach-patterns`, `soc-operations`, `threat-hunting`, `vuln-research`, `threat-modeling`, `secrets-audit`, `prompt-injection`, `privacy-engineering`, `pci-audit`, `hipaa-audit`, `ai-risk-management`, `csf-mapping`.

Treat any of those as a reading suggestion, not an invocable skill. Some have a local equivalent: `dependency-audit` → `dependency-guardsman`; `secrets-audit` / crypto → `data-guardsman`; A09 (logging) → `audit-guardsman`.

## Origin and license

Skills adapted from [briiirussell/cybersecurity-skills](https://github.com/briiirussell/cybersecurity-skills) — MIT License, © 2026 Bri Russell (see [LICENSE](LICENSE)). Changes in this harness: partial selection of the catalog, reorganization into `offensive/` and `report/`, and the `red-team-engagement` → `red-legio` rename.
