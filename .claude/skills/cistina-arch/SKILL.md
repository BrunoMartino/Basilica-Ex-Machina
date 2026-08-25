---
name: cistina-arch
description: >-
  Graphify companion that renders a truthful interactive HTML mirror of the
  project's constructions and relations (modules, services, flows, dependencies).
  Reads graphify-out first; if the graph is missing, scans the whole workspace
  before drawing. Use when the user explicitly invokes it, asks for a visual
  architecture map, a graphic mirror of what was built, or an HTML diagram of
  the codebase.
disable-model-invocation: true
license: MIT
metadata:
  based_on: tt-a1i/archify (MIT)
---

# Cistina Arch

Produce one self-contained interactive HTML that **mirrors this project's real constructions and relations**. Same intent as `legacy-explainer`, visual instead of harness docs.

Never invent topology. Never draw from README-only or guesswork. Never read `template.html` — inject it with the script.

## When to use

Apply **only when the user explicitly invokes this skill**, unless the same message says otherwise.

Out of scope: drawing fictional systems, generic Mermaid beautify without project evidence, rewriting `docs/harness/`.

## Execution order (mandatory)

```
0. Evidence lock (graph first, else full workspace scan)
1. Choose diagram type (architecture is the default mirror)
2. Author SVG from evidence only
3. check.sh → repair diagnosed subjects only
4. inject.sh → HTML
5. Optional visual open
```

## Step 0 — Evidence lock

**Stop and gather evidence before any SVG.**

1. If `graphify-out/graph.json` **and** `graphify-out/GRAPH_REPORT.md` exist:
   - Read `GRAPH_REPORT.md`.
   - Query gaps: `graphify query "<question>" --graph graphify-out/graph.json`.
   - Open **only** the source files the graph cites, to confirm.
   - Evidence mode = `graph`.
2. Else (`graphify-out/` missing, incomplete, or CLI absent):
   - **Declared fallback**: scan the whole workspace before drawing (tree, entry points, configs, inter-module imports, routes/handlers). Skip `node_modules`, `.git`, `__pycache__`, `.venv`, `dist`, `build`.
   - Evidence mode = `workspace-scan`.
   - Say so in the HTML subtitle/cards and in the chat reply.
3. Never proceed from assumption.

Every node and edge must map to a real module/relation. Cite file paths on cards.

## Step 1 — Type router

| Type | Use for |
|---|---|
| `architecture` | **Default mirror.** Modules, services, storage, boundaries |
| `workflow` | CI/CD, approvals, tool calls, runbooks found in the project |
| `sequence` | One real call chain (API, cache miss, auth) |
| `dataflow` | Pipelines, lineage, consumers found in the project |
| `lifecycle` | State machines, retries, terminal outcomes found in the project |

Read [reference.md](reference.md) for layout recipes of the chosen type. Read [examples.md](examples.md) for SVG shape (field shape, not facts).

## Step 2 — Author the SVG

Write a working file (e.g. `/tmp/cistina-arch.svg`) containing **one** `<svg>...</svg>`. Facts come only from Step 0.

Invariants:

- At most ~12 primary nodes. One obvious main path. Side branches leave the nearest main-path node.
- Detail goes in **cards**, not extra edges.
- Node pattern: mask rect `.c-mask` + typed rect `.c-<kind>` + title 11px `.t-primary` + sublabel 9px `.t-muted`.
- Never inline `fill`/`stroke` colors. CSS classes only (theme toggle depends on it).
- Omit `data-preset` on `<html>` injection (inject default `classic`). Set `signal-flow` / `blueprint` / `editorial` only if the user asks.
- Relationship labels are semantic. Move/reroute/shorten before deleting. Delete only when both endpoints fully imply the relation and it has no protocol/action/direction.
- Boundaries: dashed rects; label headroom ~30px above inner node (`boundary.y = inner.y - 30`, `h = inner.h + 50`).
- viewBox base `0 0 1000 680`; grow height if content needs it. Orthogonal routes; no edge through an unrelated opaque node.
- Language of labels matches the user's request. Keep product names, paths, and identifiers exact.

Viewer contract (required for interactivity):

```svg
<svg viewBox="0 0 1000 680" role="img" aria-label="…" data-animation="trace" data-preset="classic">
  <g id="node-api" data-node-id="api" data-node-kind="backend"
     data-node-label="API" data-node-sublabel="FastAPI"
     tabindex="0" role="button" aria-pressed="false">
    <rect x="510" y="280" width="110" height="50" rx="6" class="c-mask"/>
    <rect x="510" y="280" width="110" height="50" rx="6" class="c-backend"
          data-animate="node" style="--step: 2" stroke-width="1.5"/>
    <text x="565" y="300" class="t-primary" font-size="11" font-weight="600" text-anchor="middle">API</text>
    <text x="565" y="316" class="t-muted" font-size="9" text-anchor="middle">FastAPI</text>
  </g>
  <path data-edge-from="web" data-edge-to="api" data-edge-label="HTTPS"
        data-edge-key="0" data-edge-id="web-to-api"
        data-animate="edge" style="--step: 1"
        d="M 310 305 L 508 305" class="a-emphasis" stroke-width="1.5"
        marker-end="url(#arrowhead-emphasis)"/>
</svg>
```

- Node kinds: `frontend` `backend` `database` `cloud` `security` `messagebus` `external`.
- Edges: `data-edge-from` / `data-edge-to` must equal existing `data-node-id`.
- Trace: `data-animation="trace"` on `<svg>` + `data-animate="edge|node"` + sequential `--step` along the main path. Omit animation attributes if the user wants a static map.
- Include `<defs>` (arrow markers + grid pattern) as in [examples.md](examples.md).

## Step 3 — Validate

```bash
sh .cursor/skills/cistina-arch/scripts/check.sh /tmp/cistina-arch.svg
```

Fix only the named subject. Two focused repair rounds max; then report remaining diagnostics.

## Step 4 — Deliver HTML

Write cards HTML (paths + evidence mode). Optional guided views JSON (max 5 chapters, ids from authored nodes).

```bash
sh .cursor/skills/cistina-arch/scripts/inject.sh \
  --svg /tmp/cistina-arch.svg \
  --title "…" \
  --subtitle "Evidence: graph | workspace-scan" \
  --cards /tmp/cistina-arch-cards.html \
  --views /tmp/cistina-arch-views.json \
  -o docs/architecture-map.html
```

`--views` is optional. `--preset` defaults to `classic`.

Do **not** open or rewrite `template.html`.

## Step 5 — Optional visual check

If Chrome/Chromium exists, screenshot the HTML. Otherwise tell the user the file path to open. Do not claim visual inspection you did not perform.

## Libs

Required: none. The template is plain HTML/CSS/SVG/JS; the scripts run on POSIX `sh` + `awk` (present on any Linux/macOS/WSL/BusyBox — no Python or Node needed).
Optional: Chrome/Chromium for screenshots.

## Output contract

Return: HTML path, diagram type, evidence mode (`graph` | `workspace-scan`), node/edge counts, check.sh summary. List file paths cited. Do not claim success if check.sh failed.
