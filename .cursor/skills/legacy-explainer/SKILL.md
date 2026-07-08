---
name: legacy-explainer
description: >-
  Graphify companion: explains an existing codebase AND regenerates or updates
  its knowledge graph. Maintains the CLI and graphify-out/ (install,
  incremental --update, --force rebuild for refactors and ghost duplicates),
  then overwrites harness template docs with evidence-backed architecture,
  conventions, domain invariants, and operational constraints. Use when the
  user explicitly invokes it, asks to explain a legacy codebase, update or
  rebuild the graph, or refresh graphify-out/ and harness docs.
disable-model-invocation: true
---

# Legacy Explainer (Graphify: explain + update graph + harness docs)

## When to use

- Apply **only when the user explicitly invokes this skill**, unless the same message says otherwise.
- **Explain mode**: brownfield understanding, documentation refresh, keeping harness templates consistent.
- **Update mode**: after code changes that stale `graphify-out/` (features, fixes, refactors), ghost duplicates, CLI reinstall/upgrade, or skill version mismatch.
- Most invocations do both: update the graph, then re-explain (overwrite harness templates).
- **Out of scope**: explaining a single small function without a project-wide pass; deleting `graphify-out/` (`graphify uninstall --purge` only on explicit request).

Follow always-apply project rules (including harness gates under `.cursor/rules/`).

## Execution order (mandatory)

```
1. Diagnose: CLI, graphify-out/, integration, pending changes
2. If install or graph write needed → STOP → ask permission
3. Fix CLI if needed → refresh project integration
4. Build/update graph (initial | incremental | force | cluster-only | AST fallback)
5. Verify outputs (graph.json + GRAPH_REPORT.md)
6. Explain: read + query graph, verify source → overwrite harness templates
```

### Gate: no harness output without Graphify

Before `graphify-out/` exists with `graph.json` and `GRAPH_REPORT.md`:

- Do **not** read the codebase to draft or rewrite harness templates.
- Do **not** overwrite files under `docs/harness/`.
- Do **not** fall back to "source inspection only" as a substitute for the graph.

If Graphify is unavailable and the user declines install, **stop**: explain what's missing and offer the exact commands they can run later.

## Step 1 — Diagnose (read-only)

1. `graphify --version` / `which graphify` — CLI on PATH?
2. `graphify-out/graph.json` + `graphify-out/GRAPH_REPORT.md` — graph exists and matches this repo?
3. Project integration — e.g. `.cursor/rules/graphify.mdc` (from `graphify cursor install --project`).
4. If the graph exists: `graphify check-update .` — pending file changes?

Record findings for the permission prompt. Do not install or write yet.

## Step 2 — Permission gate (always)

**Stop and ask** before:

- installing Python (3.10+), `uv`, `pipx`, or `graphifyy` (official PyPI name; CLI is `graphify`),
- any command that **writes** to `graphify-out/` (extract, update, cluster-only, rebuild),
- refreshing project integration (`graphify cursor install --project`).

While waiting: no repo exploration for harness content, no writes to `docs/harness/*`. On Linux/WSL prefer `python3`; never silently install OS packages. Prompts and examples: [examples.md](examples.md).

## Step 3 — CLI install / reinstall / upgrade (when needed)

Only if diagnosis shows missing/broken CLI, version mismatch, or the user asked for an upgrade:

| Manager | Install/Reinstall | Upgrade |
|---------|-------------------|---------|
| **uv** (preferred) | `uv tool install graphifyy` (`--force` to reinstall) | `uv tool upgrade graphifyy` |
| **pipx** | `pipx install graphifyy` / `pipx reinstall graphifyy` | `pipx upgrade graphifyy` |
| **pip** | `pip install --force-reinstall graphifyy` | `pip install --upgrade graphifyy` |

After any CLI fix, refresh integration: `graphify cursor install --project`. Details: [safishamsi/graphify](https://github.com/safishamsi/graphify).

## Step 4 — Build or update the graph

Pick **one** strategy; ask once if unclear (incremental vs full rebuild):

| Scenario | Command |
|----------|---------|
| No `graphify-out/` yet (initial build) | `graphify .` |
| Few changes / small fixes | `graphify update .` |
| Large refactor, ghost duplicates, stale nodes after deletions | `graphify extract . --force` (or `graphify update . --force`) |
| JSON OK, only clustering stale | `graphify cluster-only .` |
| No LLM backend (ask first) | `graphify update . --no-cluster` then `graphify cluster-only .` |

Prefer **incremental** when `check-update` shows minor changes; prefer **`--force`** on ghost duplicates or broad refactors.

## Step 5 — Verify

1. `graphify-out/graph.json` and `GRAPH_REPORT.md` exist and were updated (mtime/content).
2. Note mode (full semantic vs AST-only) and commit/hash from `GRAPH_REPORT.md`.

If verification fails: stop, report errors and manual recovery commands — do **not** proceed to harness docs.

## Step 6 — Explain: read graph, overwrite harness templates

1. Read `graphify-out/GRAPH_REPORT.md`; query gaps: `graphify query "..." --graph graphify-out/graph.json` (auth flow, business rules, central modules).
2. Read existing non-template harness docs if present (`docs/harness/architecture_rules.md`, `domain_invariantes.md`, `coding_convention.md`) — they override guesswork when reconciling.
3. Open and verify important **source files** for security, auth, and money paths; never trust the graph alone there.
4. **Full replace** (not append) each run:
   - `docs/harness/architeture_rules_template.md`
   - `docs/harness/coding_conventions_template.md`
   - `docs/harness/domain_invariants_template.md`
   - `docs/harness/operational_constraints_template.md`
5. Generate `docs/<project-name>_legacy.md` **only** if the user explicitly asked for that narrative.

Skeletons: [examples.md](examples.md).

## Guardrails

- Never run `graphify uninstall --purge` unless explicitly requested.
- Never install tooling or write to `graphify-out/` / `docs/harness/` before the permission gate.
- If the user only wants a graph refresh without docs, skip Step 6 and say so; if they only want docs and the graph is current, start at Step 6.

## Output contract

- Templates readable by humans and agents; clear sections and bullets.
- **Facts vs assumptions** labeled; open questions listed with what to read next.
- **Evidence** cited: `graphify-out/GRAPH_REPORT.md`, `graph.json`, and source paths for non-obvious claims.
- End with a short summary: graph action taken (install/incremental/force/cluster-only/AST-only), `graphify-out/` files touched, graph mode + commit/hash, harness templates overwritten, manual commands for anything skipped or failed.
