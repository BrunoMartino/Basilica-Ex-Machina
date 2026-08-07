# Examples for legacy explainer

Permission prompts, update strategy, harness skeletons. Adapt section titles to the real project; replace placeholder bullets with evidence-backed content from `graphify-out/` and source files.

---

## User messages that trigger this skill

- "Explain this legacy codebase and fill the harness docs"
- "Update my graph after these changes" / "Refresh graphify-out"
- "Reinstall graphify and rebuild the graph"
- "I refactored auth — update the knowledge graph"
- "Remove ghost duplicate nodes from the graph"
- "Graphify shows skill version mismatch — fix it"

---

## Permission prompts

Ask before any install or graph write. Examples:

- Graphify is not on PATH. **May I install it with `uv tool install graphifyy`?** (Official package: `graphifyy`; CLI: `graphify`.)
- Python 3.10+ is missing. **May I install Python 3 using the OS package manager?**
- `uv` is missing. **May I install `uv` (recommended), or prefer `pipx install graphifyy` instead?**
- `graphify-out/` exists but `check-update` shows 12 changed files. **May I run `graphify update .`?**
- You mentioned a large refactor and duplicate nodes. **May I run `graphify extract . --force` to rebuild the graph?**
- Integration is missing. **May I run `graphify cursor install --project`?**
- Version mismatch detected. **May I run `uv tool upgrade graphifyy` and refresh the Cursor integration?**

If the user declines, stop and offer manual commands:

```bash
graphify update .
# or full rebuild:
graphify extract . --force
```

---

## Incremental vs force — decision table

| Signal | Prefer |
|--------|--------|
| Few files changed; small fixes | `graphify update .` |
| `check-update` shows minor pending changes | Incremental |
| Large refactor; many files moved/deleted | `graphify extract . --force` |
| Ghost duplicates; same entity twice in graph | `graphify extract . --force` |
| Graph has fewer nodes after refactor (old nodes linger) | `graphify update . --force` |
| JSON OK; only communities/clustering stale | `graphify cluster-only .` |
| Semantic extraction fails (no API keys) | Ask, then AST: `graphify update . --no-cluster` + `graphify cluster-only .` |

When unsure, ask once: **"Incremental update or full rebuild with --force?"**

---

## Graphify query examples

Run from the project root when `graphify-out/graph.json` exists:

```bash
graphify query "show the auth flow" --graph graphify-out/graph.json
graphify query "what are the main business rules?" --graph graphify-out/graph.json
graphify query "which modules are central to import, payment, or reporting?" --graph graphify-out/graph.json
```

---

## Evidence-backed bullets

**Weak (no evidence):**

- The system uses event-driven architecture everywhere.

**Better:**

- **Fact:** HTTP handlers in `app/api/` delegate to services in `services/` (see `app/api/orders/route.ts`, `services/order_service.ts`).
- **From graph:** `GRAPH_REPORT.md` clusters "checkout" with `PaymentAdapter` (graphify-out).
- **Unknown:** Whether outbox or idempotency is guaranteed—confirm in `...` or DB migrations.

---

## Sample output summary

```
Graph action: incremental update (`graphify update .`)
graphify-out/: graph.json, GRAPH_REPORT.md, graph.html updated
Graph mode: full semantic extraction
Harness: overwrote architeture_rules_template.md, coding_conventions_template.md,
  domain_invariants_template.md, operational_constraints_template.md
```

After CLI-only fix (graph already current):

```
Graph action: CLI upgrade (`uv tool upgrade graphifyy`) + `graphify cursor install --project`
graphify-out/: unchanged (check-update reported no pending changes)
Harness: refreshed templates from existing graph
```

---

## Skeleton: `docs/harness/architeture_rules_template.md`

```markdown
# Architecture (from legacy analysis)

## Purpose

## System context

- Runtime / framework:
- Main entrypoints:

## Module boundaries

- …

## Request and data flows

- …

## Integrations

- …

## Architectural decisions

- Decision:
  - Rationale (evidence):

## Open questions

- …
```

---

## Skeleton: `docs/harness/coding_conventions_template.md`

```markdown
# Coding conventions (from legacy analysis)

## Purpose

## Repo layout

## Naming

## Layering (e.g. MVC or actual pattern)

## Error handling

## Dependencies and tooling

## Comments and documentation style

## Divergences from ideal (legacy debt)

- …
```

---

## Skeleton: `docs/harness/domain_invariants_template.md`

```markdown
# Domain invariants (from legacy analysis)

## Purpose

## Core entities and relationships

## Business rules

- Rule:
  - Enforcement (code path / DB constraint):

## State machines or lifecycles

## Permissions and roles

## Edge cases and failures

## Open questions

- …
```

---

## Skeleton: `docs/harness/operational_constraints_template.md`

```markdown
# Operational constraints (from legacy analysis)

## Purpose

## Environments and configuration

## External services and quotas

## Jobs, queues, schedules

## Storage and data retention

## Deployment and runtime assumptions

## Observability

## Security and compliance notes (factual only)

## Open questions

- …
```

---

## Optional: `docs/<project-name>_legacy.md` (only if user requests)

```markdown
# <Project> — legacy overview

## Executive summary

## Architecture snapshot

## Primary use cases

## Business rules overview

## Risky or complex areas

## How to navigate the codebase

## Suggested follow-ups

## References

- graphify-out/GRAPH_REPORT.md
- Key source paths: …
```
