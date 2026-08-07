---
description: Creates Technical Design Documents (TDD) with mandatory and optional sections through interactive discovery. Use when user asks to "write a design doc", "create a TDD", "technical spec", "architecture document", "RFC", "design proposal", or needs to document a technical decision before implementation. Do NOT use for README files, API docs, or general documentation (use docs-writer instead).
name: design-doc-creator
---

# Technical Design Doc Creator

Creates Technical Design Documents following industry patterns (Google Design Docs, RFC, ADR, SRE book, OWASP, PCI DSS). Human-readable overview: [README.md](README.md).

## Core principle: architecture, not implementation

TDDs document **decisions and contracts**, not code. The doc must survive a framework swap (NestJS → Express, TypeORM → Prisma).

| Include | Avoid |
|---------|-------|
| API contracts (endpoint, method, request/response schema) | CLI commands, curl examples |
| Data schemas (tables, fields, indexes) | ORM entities, decorators, code snippets |
| Component responsibilities and data flow (Mermaid diagrams) | File paths, framework-specific syntax |
| Strategies ("rollback via feature flag") | Tool-specific rollback commands |
| Technology decisions with rationale | Vendor SDK usage details |

Litmus tests: *"If we change frameworks, does this still apply?"* (yes → include). *"Can someone implement this differently and still meet the requirement?"* (yes → document the requirement, not the implementation).

## Sections

**Mandatory (1–8)** — if missing, ask via AskQuestion; never skip:

1. **Header & Metadata** — tech lead, team, epic/ticket link, status, dates (table).
2. **Technical Solution** — **always the second section, right below the header**, so stakeholders start reading from the decision taken and get the context afterwards. Architecture overview + diagram, data flow steps, API endpoint table with example request/response, database changes + migration strategy.
3. **Context Pillars** — **always the third section; the TDD cannot be written without it.** Reproduces the 4 questions and answers from the feature harness file `docs/harness/features/feature-{name}.md`:
   1. Como descreve a feature?
   2. Qual problema objetivamente ela resolve?
   3. Qual a solução esperada? Quais trade-offs ela envolve?
   4. Qual exemplo ou contexto temos do problema e da solução?

   If the feature file doesn't exist, ask the user the 4 questions via AskQuestion, record the answers verbatim in the TDD, and instruct the user to create `docs/harness/features/feature-{name}.md` before proceeding. The answers always come from the user — the agent never invents or completes them.
4. **Context** — 2–4 paragraphs: current state, business domain, stakeholders.
5. **Problem Statement & Motivation** — specific problems with quantified impact; why now; cost of not solving.
6. **Scope** — explicit ✅ In Scope (V1), ❌ Out of Scope, 🔮 Future (V2+); min 3 items each side.
7. **Risks** — table: risk / impact (H·M·L) / probability (H·M·L) / mitigation; minimum 3.
8. **Implementation Plan** — phased task table (see TDD Red/Green rule below).

**Critical (9–12)** — mandatory by project type (see matrix):

9. **Security Considerations** — authn/authz model, encryption at rest + in transit, PII handling and retention, compliance (GDPR/LGPD, PCI DSS), secrets management, webhook signature validation, input validation / rate limiting / audit logging checklist.
10. **Testing Strategy** — test types table (unit, integration, e2e, contract, load) with scope and approach; critical scenarios; test data management.
11. **Monitoring & Observability** — metrics table with alert thresholds; structured JSON log format; what to log and what NEVER to log (secrets, card data, raw PII); alert severity/channel table.
12. **Rollback Plan** — deployment strategy (flag, phased rollout, canary), rollback trigger table, rollback steps as strategy (flag off → revert deploy → down migration → communicate), post-rollback RCA.

**Suggested (13–21)** — offer, don't force: Success Metrics · Glossary · Alternatives Considered (options table + decision criteria) · Dependencies (+ approvals/blockers) · Performance Requirements (latency percentiles, throughput, availability) · Migration Plan (phases, data migration, backward compatibility) · Open Questions (tracked table with owner/status) · Roadmap/Timeline · Approval & Sign-off.

### Criticality matrix

| Project type | Required beyond mandatory |
|--------------|---------------------------|
| Payment, Auth, PII | Security Considerations |
| Any production system | Monitoring & Observability, Rollback Plan |
| External integration | Dependencies, Security |
| All | Testing Strategy (highly recommended) |

### Size adaptation

| Size | Sections |
|------|----------|
| Small (< 1 week) | 1–8 + Testing Strategy |
| Medium (1–4 weeks) | 1–12 + Dependencies + Open Questions |
| Large (> 1 month) | All 21 |

## Implementation Plan uses TDD Red/Green

**Every implementation phase must state that it is executed with test-driven development**: each task starts with a failing test (**Red**), then the minimal code to pass (**Green**), then refactor. Make this explicit in the plan, e.g.:

```markdown
| Phase | Task | TDD cycle | Owner | Estimate |
|-------|------|-----------|-------|----------|
| 2 – Core | SubscriptionService | Red: failing unit tests for create/cancel → Green: minimal service | @Dev2 | 4d |
| 3 – APIs | POST /subscriptions | Red: failing integration test → Green: controller + DTO | @Dev3 | 2d |
```

Do not add a separate trailing "write tests" phase — tests lead each phase, they don't follow it. Execution follows the [`tester`](../tester/SKILL.md) skill.

## Interactive workflow

1. **Gather** — AskQuestion: project name, size (S/M/L), type (integration, feature, refactor, infra, payment, auth, data), whether context/problem is already clear.
2. **Collect Context Pillars** — locate `docs/harness/features/feature-{name}.md` and copy its 4 questions/answers verbatim. If the file is missing, ask the user the 4 questions via AskQuestion (never answer or complete them yourself), record the answers verbatim, and instruct the user to create the feature file before proceeding.
3. **Choose design pattern (mandatory AskQuestion)** — present as options the design patterns listed in the feature file's "Design Patterns (Gang of Four) Sugerido" section and ask which one the user wants for this implementation. Record the choice in the Technical Solution section. Never pick for the user.
4. **Validate mandatory info** — ask for anything missing: problem (what/why now/impact if not), scope in/out, high-level approach and components, ≥3 risks, phase breakdown with owners.
5. **Enforce critical sections** by project type (matrix above). For payment/auth: ask authn model, encryption, PII, compliance. For production: metrics, alerts, rollback triggers and steps.
6. **Offer suggested sections** — user can add now or later.
7. **Generate** the Markdown doc; validate with the checklist below; report included/missing sections and next steps.
8. **Offer publication** — Confluence page (via Confluence/Atlassian skill or MCP) if available.

Ask instead of guessing. Vague answers get one targeted follow-up, then an explicit `TBD` in the doc.

## Validation checklist

- [ ] Header: tech lead, team, epic link
- [ ] Context Pillars: 4 answers present, sourced from `feature-{name}.md` or answered by the user
- [ ] Design pattern: chosen by the user via AskQuestion among the patterns suggested in the feature file, recorded in Technical Solution
- [ ] Problem: ≥2 specific problems with impact
- [ ] Scope: ≥3 in-scope and ≥3 out-of-scope items
- [ ] Solution: diagram or component description + ≥1 API contract
- [ ] Risks: ≥3 with impact/probability/mitigation
- [ ] Plan: phased, estimated, **Red/Green noted per phase**
- [ ] Payment/auth → Security section complete (authn, encryption, PII, compliance)
- [ ] Production → Monitoring (≥3 metrics + alerts) and Rollback (triggers + steps)
- [ ] Testing: ≥2 test types + critical scenarios

## Anti-patterns

- **TDD without Context Pillars, or with answers invented/completed by the agent** — never; the 4 answers come from `feature-{name}.md` or directly from the user.
- **Vague problem**: "We need to integrate with Stripe" → quantify: "manual payment processing costs 2h/day (~$500/month); current processor blocks international expansion".
- **Undefined scope**: "all features" → explicit V1 list + explicit exclusions.
- **Payment system without a Security section** — never.
- **No rollback plan for production** — always define triggers (e.g. error rate > 5% for 5 min → flag off) and steps.
- **Implementation-level detail** — commands, code, file paths belong in the repo, not the TDD.
