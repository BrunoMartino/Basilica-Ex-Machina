---
description: Creates Technical Design Documents (TDD) with mandatory and optional sections through interactive discovery. Use when user asks to "write a design doc", "create a TDD", "technical spec", "architecture document", "RFC", "design proposal", or needs to document a technical decision before implementation. Do NOT use for README files, API docs, or general documentation (use docs-writer instead).
name: technical-design-doc-creator
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

**Mandatory (1–7)** — if missing, ask via AskQuestion; never skip:

1. **Header & Metadata** — tech lead, team, epic/ticket link, status, dates (table).
2. **Context** — 2–4 paragraphs: current state, business domain, stakeholders.
3. **Problem Statement & Motivation** — specific problems with quantified impact; why now; cost of not solving.
4. **Scope** — explicit ✅ In Scope (V1), ❌ Out of Scope, 🔮 Future (V2+); min 3 items each side.
5. **Technical Solution** — architecture overview + diagram, data flow steps, API endpoint table with example request/response, database changes + migration strategy.
6. **Risks** — table: risk / impact (H·M·L) / probability (H·M·L) / mitigation; minimum 3.
7. **Implementation Plan** — phased task table (see TDD Red/Green rule below).

**Critical (8–11)** — mandatory by project type (see matrix):

8. **Security Considerations** — authn/authz model, encryption at rest + in transit, PII handling and retention, compliance (GDPR/LGPD, PCI DSS), secrets management, webhook signature validation, input validation / rate limiting / audit logging checklist.
9. **Testing Strategy** — test types table (unit, integration, e2e, contract, load) with scope and approach; critical scenarios; test data management.
10. **Monitoring & Observability** — metrics table with alert thresholds; structured JSON log format; what to log and what NEVER to log (secrets, card data, raw PII); alert severity/channel table.
11. **Rollback Plan** — deployment strategy (flag, phased rollout, canary), rollback trigger table, rollback steps as strategy (flag off → revert deploy → down migration → communicate), post-rollback RCA.

**Suggested (12–20)** — offer, don't force: Success Metrics · Glossary · Alternatives Considered (options table + decision criteria) · Dependencies (+ approvals/blockers) · Performance Requirements (latency percentiles, throughput, availability) · Migration Plan (phases, data migration, backward compatibility) · Open Questions (tracked table with owner/status) · Roadmap/Timeline · Approval & Sign-off.

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
| Small (< 1 week) | 1–7 + Testing Strategy |
| Medium (1–4 weeks) | 1–11 + Dependencies + Open Questions |
| Large (> 1 month) | All 20 |

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
2. **Validate mandatory info** — ask for anything missing: problem (what/why now/impact if not), scope in/out, high-level approach and components, ≥3 risks, phase breakdown with owners.
3. **Enforce critical sections** by project type (matrix above). For payment/auth: ask authn model, encryption, PII, compliance. For production: metrics, alerts, rollback triggers and steps.
4. **Offer suggested sections** — user can add now or later.
5. **Generate** the Markdown doc; validate with the checklist below; report included/missing sections and next steps.
6. **Offer publication** — Confluence page (via Confluence/Atlassian skill or MCP) if available.

Ask instead of guessing. Vague answers get one targeted follow-up, then an explicit `TBD` in the doc.

## Validation checklist

- [ ] Header: tech lead, team, epic link
- [ ] Problem: ≥2 specific problems with impact
- [ ] Scope: ≥3 in-scope and ≥3 out-of-scope items
- [ ] Solution: diagram or component description + ≥1 API contract
- [ ] Risks: ≥3 with impact/probability/mitigation
- [ ] Plan: phased, estimated, **Red/Green noted per phase**
- [ ] Payment/auth → Security section complete (authn, encryption, PII, compliance)
- [ ] Production → Monitoring (≥3 metrics + alerts) and Rollback (triggers + steps)
- [ ] Testing: ≥2 test types + critical scenarios

## Anti-patterns

- **Vague problem**: "We need to integrate with Stripe" → quantify: "manual payment processing costs 2h/day (~$500/month); current processor blocks international expansion".
- **Undefined scope**: "all features" → explicit V1 list + explicit exclusions.
- **Payment system without a Security section** — never.
- **No rollback plan for production** — always define triggers (e.g. error rate > 5% for 5 min → flag off) and steps.
- **Implementation-level detail** — commands, code, file paths belong in the repo, not the TDD.
