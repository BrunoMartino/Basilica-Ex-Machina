---
name: update-my-graph
description: >-
  Updates or rebuilds Graphify (CLI + graphify-out/) after code changes:
  reinstall binary, incremental --update, or --force re-extract for refactors
  and ghost duplicates. Always asks permission before install or graph writes.
  Chains to legacy-explainer to refresh harness docs. Use when the user asks
  to update the graph, refresh graphify-out, reinstall graphify, or after
  refactors/features that may stale the knowledge graph.
disable-model-invocation: true
---

# Update my graph (Graphify maintenance + harness refresh)

## When to use

- Apply **only when the user explicitly invokes this skill**, unless the same message says otherwise.
- Use after **code changes** that may stale `graphify-out/` (features, fixes, refactors).
- Use when the user asks to **update the graph**, **refresh graphify-out**, or **reinstall graphify**.
- Use when **ghost duplicates** or stale nodes appear after a large refactor.
- Use when Graphify reports a **skill version mismatch** (CLI vs project integration).
- **Out of scope**: writing harness docs without updating the graph first (that is [`legacy-explainer`](../legacy-explainer/SKILL.md) alone); deleting `graphify-out/` (`graphify uninstall --purge`).

Follow always-apply project rules (including harness gates under `.cursor/rules/`).

## Execution order (mandatory)

Follow this sequence **strictly**. Do **not** skip ahead.

```
1. Diagnose (graphify --version, graphify-out/, graphify check-update .)
2. STOP → ask permission (always, before install or graph writes)
3. Fix CLI if needed → refresh project integration
4. Update graph (incremental | force | cluster-only | AST fallback)
5. Verify outputs (graph.json + GRAPH_REPORT.md)
6. Chain → invoke legacy-explainer (automatic, no extra confirmation)
```

### Separation of concerns

| Skill | Responsibility |
|-------|----------------|
| **update-my-graph** (this skill) | CLI health, `graphify-out/` extract/update/cluster |
| **legacy-explainer** | Read graph + overwrite `docs/harness/*_template.md` |

## Step 1 — Diagnose (read-only)

Run **read-only** checks from the project root:

1. **`graphify --version`** or **`which graphify`** — is the CLI on PATH?
2. **`graphify-out/graph.json`** and **`graphify-out/GRAPH_REPORT.md`** — does the graph exist?
3. **Project integration** — e.g. `.cursor/rules/graphify.mdc` after `graphify cursor install --project`.
4. If `graphify-out/` exists: **`graphify check-update .`** — are there pending file changes?

Record findings for the permission prompt in Step 2. Do **not** install or write to `graphify-out/` yet.

## Step 2 — Permission gate (always)

**Stop and ask the user for permission** before:

- installing or reinstalling **Python** (3.10+), **`uv`**, **`pipx`**, or **`graphifyy`**,
- running any command that **writes** to `graphify-out/` (update, extract, cluster-only, full rebuild),
- refreshing project integration (`graphify cursor install --project`).

Permission prompts and examples: [examples.md](examples.md).

**While waiting for approval:** do not run install or graph-update commands.

If the user **declines**: stop; report what is missing or stale; offer the exact commands they can run manually (see examples).

If the user **approves**: continue to Step 3 (if CLI fix needed) and Step 4.

## Step 3 — CLI reinstall / upgrade (when needed)

Run **only** if Step 1 shows a missing/broken CLI, version mismatch, or the user asked to upgrade Graphify.

Official PyPI package: **`graphifyy`** (double-y). CLI command: **`graphify`**.

| Manager | Reinstall | Upgrade |
|---------|-----------|---------|
| **uv** (preferred) | `uv tool install graphifyy --force` | `uv tool upgrade graphifyy` |
| **pipx** | `pipx reinstall graphifyy` | `pipx upgrade graphifyy` |
| **pip** | `pip install --force-reinstall graphifyy` | `pip install --upgrade graphifyy` |

On Linux/WSL prefer `python3` if `python` is unavailable. Do **not** silently install OS packages.

After CLI fix, **always** refresh project integration in the current repo:

```bash
graphify cursor install --project
# equivalent:
graphify install --project --platform cursor
```

Up-to-date install details: [safishamsi/graphify](https://github.com/safishamsi/graphify).

If the CLI was already healthy, skip to Step 4.

## Step 4 — Choose update strategy

Pick **one** path based on diagnosis and user intent. Ask if unclear (incremental vs full rebuild).

| Scenario | Command |
|----------|---------|
| Few changes / small fixes | `graphify update .` or `graphify . --update` |
| Large refactor, ghost duplicates, fewer nodes after deletions | `graphify extract . --force` or `graphify update . --force` or `graphify .` |
| Re-cluster only (JSON OK, clustering stale) | `graphify cluster-only .` |
| No LLM backend (AST fallback) | `graphify update . --no-cluster` then `graphify cluster-only .` |

**Heuristics:**

- Prefer **incremental** when `graphify check-update .` shows minor pending changes and the user did not mention duplicates or a large refactor.
- Prefer **`--force`** when the user mentions ghost duplicates, a broad refactor, or a full rebuild.
- If full semantic extraction fails (e.g. missing API keys), **ask** before AST-only fallback.

If `graphify-out/` does **not** exist yet, treat as initial build: `graphify .` (after permission).

## Step 5 — Verify

Confirm a successful graph update:

1. **`graphify-out/graph.json`** and **`graphify-out/GRAPH_REPORT.md`** exist and were updated (mtime or content change).
2. Report **mode**: full semantic extraction vs AST-only.
3. Note commit/hash from `GRAPH_REPORT.md` if present.

If verification fails, stop; do **not** chain legacy-explainer. Report error output and manual recovery commands.

## Step 6 — Chain legacy-explainer (automatic)

**After Step 5 succeeds**, invoke [`legacy-explainer`](../legacy-explainer/SKILL.md) **without asking again**:

1. Start at **legacy-explainer Step 3** (graph already exists; skip install/build unless Step 4 failed partially).
2. Read and query the graph; verify critical source paths.
3. **Full replace** harness templates per legacy-explainer Step 4:
   - `docs/harness/architeture_rules_template.md`
   - `docs/harness/coding_conventions_template.md`
   - `docs/harness/domain_invariants_template.md`
   - `docs/harness/operational_constraints_template.md`
4. Generate `docs/<project-name>_legacy.md` **only** if the user explicitly asked for it in the same invocation.

Do **not** duplicate legacy-explainer logic here — follow that skill for harness content rules and output contract.

## Guardrails

- **Never** run `graphify uninstall --purge` unless the user explicitly requests deletion of `graphify-out/`.
- **Never** install Python, `uv`, `pipx`, or `graphifyy` without user approval.
- **Never** write to `graphify-out/` or `docs/harness/` before permission (Step 2) and successful graph update (Step 5).
- **Never** skip legacy-explainer after a successful graph update (Step 6 is mandatory for this skill).
- Do **not** use this skill as a substitute for [`legacy-explainer`](../legacy-explainer/SKILL.md) when the user only wants harness docs and the graph is already current — invoke legacy-explainer directly instead.

## Output contract

End with a **short summary**:

- **Graph action**: CLI reinstall / upgrade / incremental / force / cluster-only / AST-only
- **`graphify-out/` files touched**: e.g. `graph.json`, `GRAPH_REPORT.md`, `graph.html`
- **Graph mode**: full semantic vs AST-only; commit/hash if available
- **Legacy-explainer**: which harness templates were overwritten
- **Manual commands**: if anything failed or was skipped

Examples: [examples.md](examples.md).
