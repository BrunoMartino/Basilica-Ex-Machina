---
name: legacy-explainer
description: >-
  Uses Graphify to map an existing codebase, then overwrites harness template
  docs with evidence-backed architecture, conventions, domain invariants, and
  operational constraints. Use only when the user explicitly invokes this
  skill, when refreshing legacy documentation after changes, or when aligning
  harness templates with a brownfield project; requires user approval before
  installing Python, uv, or graphifyy.
disable-model-invocation: true
---

# Legacy explainer (Graphify + harness templates)

## When to use

- Apply **only when the user explicitly invokes this skill**, unless the same message says otherwise.
- Use for **brownfield** projects: broad understanding, documentation refresh, or keeping harness templates consistent after new features or refactors.
- **Out of scope**: explaining a single small function or file without a project-wide pass.

## Harness docs first

Before rewriting templates, read existing non-template harness docs if they exist (they override guesswork):

1. [`docs/harness/architecture_rules.md`](../../../docs/harness/architecture_rules.md)
2. [`docs/harness/domain_invariantes.md`](../../../docs/harness/domain_invariantes.md)
3. [`docs/harness/coding_convention.md`](../../../docs/harness/coding_convention.md)

If a file is missing, say so and derive content from the repo plus Graphify outputs.

Follow always-apply project rules (including harness gates under `.cursor/rules/`).

## Graphify: availability and install (permission required)

1. Check whether **`graphify` works** (e.g. `graphify --version` or `which graphify`) and whether project integration exists (Cursor/Claude hooks or skills as expected).
2. If Graphify or integration is missing, **stop and ask the user for permission** before:
   - installing **Python** (3.10+),
   - installing **`uv`** or **`pipx`**,
   - running **`uv tool install graphifyy`** (official PyPI name; CLI remains `graphify`) or **`pipx install graphifyy`** only if agreed,
   - running **`graphify cursor install --project`** or **`graphify claude install --project`**.
3. On Linux/WSL prefer `python3` if `python` is unavailable. Do **not** silently install OS packages.

Up-to-date install details: [safishamsi/graphify](https://github.com/safishamsi/graphify).

## Graphify: run and read

After Graphify is available:

1. **Project-scoped register** (typical): `graphify cursor install --project` (Cursor) or `graphify claude install --project` (Claude Code). Use non-`--project` forms only if the user prefers global integration.
2. **Build the graph** for the repo root or a path the user specifies, e.g. `graphify .` or **`/graphify .`** — use the form your environment expects (PowerShell treats a leading `/` as a path; use `graphify .` without a leading slash on Windows shells).
3. Primary artifacts under **`graphify-out/`** (names may vary slightly by version):
   - `GRAPH_REPORT.md`
   - `graph.json` — use `graphify query "..." --graph graphify-out/graph.json` for targeted questions.
   - `graph.html`, `cache/` when present.

## Documentation workflow

1. Read **`graphify-out/GRAPH_REPORT.md`** and **`graphify-out/graph.json`** (and use **`graphify query`** for gaps).
2. Open and verify important **source files**; never trust the graph alone for security, auth, or money paths.
3. **Overwrite** these template files every run with the **current** evidence-backed state (full replace, not append):
   - [`docs/harness/architeture_rules_template.md`](../../../docs/harness/architeture_rules_template.md)
   - [`docs/harness/coding_conventions_template.md`](../../../docs/harness/coding_conventions_template.md)
   - [`docs/harness/domain_invariants_template.md`](../../../docs/harness/domain_invariants_template.md)
   - [`docs/harness/operational_constraints_template.md`](../../../docs/harness/operational_constraints_template.md)
4. Generate **`docs/<project-name>_legacy.md`** only if the user **explicitly** asks for that extra narrative.

Skeletons and examples: [examples.md](examples.md).

## Output contract

- Templates must be **readable by humans and agents**, with clear sections and bullets.
- **Facts vs assumptions**: label uncertainty; list open questions and what to read next.
- **Evidence**: cite paths (e.g. `src/...`, `graphify-out/GRAPH_REPORT.md`) for non-obvious claims.
- **Consistency**: align template content with the real codebase and with existing harness docs when both exist; call out intentional drift only if the user asked for it.
