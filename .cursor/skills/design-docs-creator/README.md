# Technical Design Doc Creator

A Cursor skill that guides agents to create comprehensive **Technical Design Documents (TDDs)** through interactive discovery, following industry standards (Google Design Docs, RFC, ADR, SRE, OWASP, PCI DSS).

**Skill file:** [`SKILL.md`](SKILL.md)

## What It Does

The agent produces well-structured TDDs with up to **20 sections**, adapted to project size and type:

| Category | Sections |
|----------|----------|
| **Mandatory (7)** | Header & Metadata, Context, Problem Statement, Scope, Technical Solution, Risks, Implementation Plan |
| **Critical (4)** | Security Considerations, Testing Strategy, Monitoring & Observability, Rollback Plan |
| **Suggested (9)** | Success Metrics, Glossary, Alternatives Considered, Dependencies, Performance Requirements, Migration Plan, Open Questions, Roadmap / Timeline, Approval & Sign-off |

The skill automatically adapts to:

- **Project size** — Small (< 1 week), Medium (1–4 weeks), Large (> 1 month)
- **Project type** — Integration, Feature, Refactor, Infrastructure, Payment, Auth, Data migration

### Architecture-first, not implementation

TDDs document **decisions and contracts**, not code:

| Include | Avoid |
|---------|-------|
| API contracts, data schemas, architecture diagrams | CLI commands, code snippets |
| High-level service responsibilities | Framework-specific syntax |
| Rollback *strategy* (e.g. feature flag) | Tool-specific rollback commands |

If the implementation stack changes (NestJS → Express, TypeORM → Prisma), the TDD should still be valid.

## When to Use

```
Create a TDD for Stripe payment integration
Write a design doc for the API redesign
Create a tech spec for migrating to microservices
Help me document the payment integration architecture
```

Also use when:

- Starting a new feature or integration
- Planning a migration or system replacement
- Needing stakeholder approval before implementation

### When NOT to Use

- README files or general project documentation
- API reference docs (endpoint catalogs)
- Bug fixes, trivial config changes, or refactors without architectural impact

## Interactive Workflow

The skill runs a **6-step** process:

1. **Initial gathering** — Project name, size, type, context clarity (via `AskQuestion` when useful)
2. **Mandatory information** — Problem statement, scope, technical approach, risks, implementation plan
3. **Critical sections** — Security, monitoring, rollback (enforced by project type)
4. **Suggested sections** — Success metrics, glossary, alternatives, etc. (offered, not forced)
5. **Generate document** — Markdown TDD from section templates in `SKILL.md`
6. **Confluence integration** — Optionally publish if a Confluence Assistant skill is available

Mandatory sections **cannot be skipped**. The agent asks clarifying questions instead of guessing.

### Critical sections by project type

| Project type | Required |
|--------------|----------|
| Payment, Auth | Security Considerations (mandatory) |
| Production | Monitoring & Observability, Rollback Plan (mandatory) |
| Integration | Dependencies, Security (highly recommended) |
| All | Testing Strategy (highly recommended) |

### Sections by project size

| Size | Sections used |
|------|---------------|
| **Small** (< 1 week) | Mandatory + Testing Strategy (sections 1–7, 9) |
| **Medium** (1–4 weeks) | Mandatory + Critical + Dependencies + Open Questions (1–11, 15, 18) |
| **Large** (> 1 month) | All 20 sections, fully detailed |

## Examples

### Payment integration (medium/large)

**Request:**

```
Create a TDD for integrating Stripe payments into our subscription system
```

**What happens:**

1. Agent asks about project size and type
2. Agent collects problem statement, scope, and technical approach
3. Payment type detected → **Security section becomes mandatory**
4. Agent asks for security requirements, monitoring metrics, and rollback plan
5. Agent generates the TDD and summarizes included/missing sections

**Result:** Context, scope, architecture, API contracts, security (PCI DSS), testing, monitoring, rollback, implementation timeline.

### Simple feature (small)

**Request:**

```
Write a design doc for adding user profile pictures
```

**Result:** Streamlined TDD with context, problem statement, scope, technical solution, risks, implementation plan, and testing strategy.

### Migration project (large)

**Request:**

```
Create a TDD for migrating our database from PostgreSQL to MongoDB
```

**What happens:**

1. Agent identifies a migration/refactor project
2. Agent requests migration strategy, data mapping, and rollback plan
3. Agent offers Migration Plan and related optional sections

**Result:** Full TDD including Migration Plan, Rollback Plan, Testing Strategy, and phased implementation.

## What to Expect

The agent will ask targeted questions, for example:

- **Problem:** What problem are we solving? Why now? Impact if we don't?
- **Scope:** What is in V1? What is explicitly out of scope?
- **Technical approach:** Main components, data flow, APIs affected?
- **Payment/Auth:** Authentication, encryption, PII, compliance (GDPR, PCI DSS)?
- **Production:** Metrics to monitor, rollback triggers and steps?

After generation, expect a summary like:

```
✅ TDD Created: "[Project Name]"

**Sections Included**:
✅ Mandatory (7/7): All present
✅ Critical (3/4): Security, Testing, Monitoring
⚠️ Missing: Rollback Plan (recommended for production)
```

## Tips for Best Results

**Provide context early:**

```
Create a TDD for integrating Stripe payments. We need subscriptions,
webhooks, and PCI DSS compliance. This is for our SaaS product.
```

**Be explicit about scope:**

```
Create a TDD for user authentication. In scope: email/password, JWT, password reset.
Out of scope: OAuth, 2FA, social login (V2).
```

**Mention project size:**

```
Create a TDD for the database migration. Large project, expected ~2 months.
```

**State security requirements upfront (payment/auth):**

```
Create a TDD for Stripe integration with PCI DSS compliance, webhook
signature validation, and encrypted payment method token storage.
```

## Related Skills in This Repo

Use alongside other harness skills depending on the TDD topic:

| Skill | When it complements a TDD |
|-------|---------------------------|
| [`coupling-analizer`](../coupling-analizer/SKILLL.md) | Evaluating module coupling before or during architecture design |
| [`data-guardsman`](../data-guardsman/SKILL.md) | Encryption, data classification, secrets — feeds Security Considerations |
| [`audit-guardsman`](../audit-guardsman/SKILL.md) | Audit logging for privileged operations |
| [`tester`](../tester/SKILL.md) | TDD implementation after the design is approved |
| [`legacy-explainer`](../legacy-explainer/SKILL.md) | Brownfield context before writing a migration/refactor TDD |
| [`get-that-task`](../get-that-task/SKILL.md) | Linking Epic/Ticket metadata to Jira issues |

The harness docs gate (`.cursor/rules/all-for-harness.mdc`) applies: for architecture or domain changes documented in a TDD, align with `docs/harness/` when those files exist in the project.

## Integration with External Tools

### Confluence

After generating a TDD, the agent may offer:

```
Would you like me to publish this TDD to Confluence?
- I can create a new page in your space
- Or update an existing page
```

Requires a Confluence Assistant skill or MCP integration.

### Jira / Linear

The Header & Metadata section includes an Epic/Ticket field. Link manually or use [`get-that-task`](../get-that-task/SKILL.md) / Atlassian MCP to create or reference issues.

## Example Output Structure

```markdown
# TDD - [Project Name]

| Field     | Value   |
|-----------|---------|
| Tech Lead | @Name   |
| Status    | Draft   |

## Context
## Problem Statement & Motivation
## Scope
### ✅ In Scope (V1)
### ❌ Out of Scope (V1)
## Technical Solution
## Risks
## Implementation Plan
## Security Considerations
## Testing Strategy
## Monitoring & Observability
## Rollback Plan
```

## Troubleshooting

**The agent keeps asking questions** — Expected. Mandatory sections require explicit input.

**Skip a section** — Mandatory sections cannot be skipped. For optional sections:

```
Skip the Alternatives Considered section for now
```

**TDD too detailed** — Specify size:

```
This is a small project (< 1 week), keep it simple
```

**Missing content** — Request additions:

```
Add a section on performance requirements
```

## After Creating a TDD

1. Review all sections against the validation checklists in `SKILL.md`
2. Share with the team for feedback
3. Get stakeholder sign-off (Approval section for large projects)
4. Implement using the TDD as the guide
5. Update the document as decisions evolve

## References

Industry patterns followed: [Google Engineering Practices](https://google.github.io/eng-practices/), [Google SRE Book](https://sre.google/sre-book/table-of-contents/), [OWASP Top 10](https://owasp.org/www-project-top-ten/), [Architecture Decision Records](https://adr.github.io/).
