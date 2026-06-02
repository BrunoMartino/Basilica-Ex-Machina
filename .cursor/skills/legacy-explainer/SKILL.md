---
name: legacy-explainer
description: >-
  Uses Graphify to map an existing codebase, then overwrites harness template
  docs with evidence-backed architecture, conventions, domain invariants, and
  operational constraints. Use only when the user explicitly invokes this
  skill. Requires Graphify and graphify-out/ before writing harness docs;
  asks user approval before installing Python, uv, or graphifyy.
disable-model-invocation: true
---

# Legacy explainer (Graphify + harness templates)

## When to use

- Apply **only when the user explicitly invokes this skill**, unless the same message says otherwise.
- Use for **brownfield** projects: broad understanding, documentation refresh, or keeping harness templates consistent after new features or refactors.
- **Out of scope**: explaining a single small function or file without a project-wide pass.

## Execution order (mandatory)

Follow this sequence **strictly**. Do **not** skip ahead.

```
1. Check Graphify + graphify-out/
2. If missing → STOP → ask permission to install / build
3. Only after graphify-out/ exists → read graph + verify source → overwrite harness templates
```

### Gate: no harness output without Graphify

**Before `graphify-out/` exists with at least `graph.json` and `GRAPH_REPORT.md`:**

- Do **not** read the codebase to draft or rewrite harness templates.
- Do **not** overwrite files under `docs/harness/`.
- Do **not** fall back to “source inspection only” as a substitute for the graph.

If Graphify is unavailable or the user has not approved install/build, **stop** and report what is missing. Wait for approval or for the user to run the commands themselves.

Harness template generation happens **only** in step 3, after a successful graph build.

Follow always-apply project rules (including harness gates under `.cursor/rules/`).

## Step 1 — Check Graphify and graphify-out/

1. Check whether **`graphify` works** (e.g. `graphify --version` or `which graphify`).
2. Check whether **`graphify-out/graph.json`** and **`graphify-out/GRAPH_REPORT.md`** exist and are usable for this repo.
3. Check whether project integration exists if relevant (e.g. `.cursor/rules/graphify.mdc` after `graphify cursor install --project`).

If **any** of the above is missing, go to **Step 2** — do not proceed to harness docs.

## Step 2 — Install / build (permission required)

If Graphify or `graphify-out/` is missing, **stop immediately** and **ask the user for permission** before:

- installing **Python** (3.10+),
- installing **`uv`** or **`pipx`**,
- running **`uv tool install graphifyy`** (official PyPI name; CLI remains `graphify`) or **`pipx install graphifyy`** only if agreed,
- running **`graphify cursor install --project`** or **`graphify claude install --project`**,
- running **`graphify .`** (or `graphify update .` + `graphify cluster-only .` if semantic backends are unavailable).

On Linux/WSL prefer `python3` if `python` is unavailable. Do **not** silently install OS packages.

**While waiting for approval:** do not explore the repo for harness content and do not write `docs/harness/*`.

If the user **declines** install: stop; explain that harness templates cannot be generated without Graphify; offer the exact commands they can run later.

If the user **approves**: run install/build, then continue to Step 3.

Up-to-date install details: [safishamsi/graphify](https://github.com/safishamsi/graphify).

Recommended install (when approved):

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
source "$HOME/.local/bin/env"
uv tool install graphifyy
graphify cursor install --project
graphify .
```

If full semantic extraction fails (e.g. missing API keys), ask before continuing with AST-only:

```bash
graphify update . --no-cluster
graphify cluster-only .
```

## Step 3 — Graphify: read and query

**Only after Step 1 passes or Step 2 completes successfully.**

1. Read **`graphify-out/GRAPH_REPORT.md`** and use **`graphify-out/graph.json`**.
2. Use **`graphify query "..." --graph graphify-out/graph.json`** for gaps (auth flow, business rules, central modules).
3. Read existing **non-template** harness docs if they exist (they override guesswork when reconciling with the graph):
   - [`docs/harness/architecture_rules.md`](../../../docs/harness/architecture_rules.md)
   - [`docs/harness/domain_invariantes.md`](../../../docs/harness/domain_invariantes.md)
   - [`docs/harness/coding_convention.md`](../../../docs/harness/coding_convention.md)
   If a file is missing, say so; derive content from **Graphify outputs plus targeted source verification** — not from a broad codebase pass alone.
4. Open and verify important **source files** for security, auth, and money paths; never trust the graph alone for those.

## Step 4 — Overwrite harness templates

**Only after Step 3.** Full replace (not append) every run:

- [`docs/harness/architeture_rules_template.md`](../../../docs/harness/architeture_rules.md)
- [`docs/harness/coding_conventions_template.md`](../../../docs/harness/coding_conventions.md)
- [`docs/harness/domain_invariants_template.md`](../../../docs/harness/domain_invariants.md)
- [`docs/harness/operational_constraints_template.md`](../../../docs/harness/operational_constraints.md)

Generate **`docs/<project-name>_legacy.md`** only if the user **explicitly** asks for that extra narrative.

Skeletons and examples: [examples.md](examples.md).

## Output contract

- Templates must be **readable by humans and agents**, with clear sections and bullets.
- **Facts vs assumptions**: label uncertainty; list open questions and what to read next.
- **Evidence**: cite `graphify-out/GRAPH_REPORT.md`, `graphify-out/graph.json`, and source paths (e.g. `src/...`) for non-obvious claims.
- **Graph mode**: state whether the run used full semantic extraction or AST-only, and commit/hash from `GRAPH_REPORT.md` if present.
- **Consistency**: align template content with the graph, verified source, and existing harness docs when both exist; call out intentional drift only if the user asked for it.
