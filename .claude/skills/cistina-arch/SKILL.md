---
name: cistina-arch
description: >-
  Graphify companion that renders a truthful interactive HTML mirror of the
  workspace: file-level nodes plus visible complex excerpts (handlers, hubs,
  branches), including orphans and dead code. Asks via AskQuestion whether
  more symbol-level depth is needed. Reads graphify-out first, always
  censuses the filesystem. Use when the user explicitly invokes it, asks for
  a visual architecture map, a graphic mirror of what was built, or an HTML
  diagram of the codebase.
disable-model-invocation: true
license: MIT
metadata:
  based_on: tt-a1i/archify (MIT)
---

# Cistina Arch

Produce one self-contained interactive HTML that **mirrors this project's real constructions and relations**. Same intent as `legacy-explainer`, visual instead of harness docs.

Never invent topology. Never draw from README-only or guesswork. Never read `template.html` — inject it with the script.

Default deliverable is **not** a stack cartoon. It is always **every source file** plus **visible complex excerpts** (branching handlers, high-degree functions, state machines, atypical links). Folders are boundaries, not nodes. Orphans, dead code, and edge cases stay on the canvas.

## Language

All text and documents this skill creates must be written in **English**, even when the prompt, plan, or source document is in another language. Product names, paths, identifiers, and quoted user answers stay verbatim.

## When to use

Apply **only when the user explicitly invokes this skill**, unless the same message says otherwise.

Out of scope: drawing fictional systems, generic Mermaid beautify without project evidence, rewriting `docs/harness/`.

## Execution order (mandatory)

```
0.  Evidence lock (graph + filesystem census — always)
0b. Inventory: nodes, edges, live|orphan|dead|edge-case, complex excerpts
0c. AskQuestion: default vs more depth (skip only if the invoke already fixes depth)
1.  Choose diagram type (architecture is the default mirror)
2.  Layout: directory bands, viewBox grows with counts
3.  Author SVG (files + visible complex excerpts + islands; extra symbols if asked)
4.  check.sh → repair diagnosed subjects only (4 rounds max)
5.  inject.sh → HTML (guided views required for architecture)
6.  Optional visual open
```

## Step 0 — Evidence lock

**Stop and gather evidence before any SVG.**

1. If `graphify-out/graph.json` **and** `graphify-out/GRAPH_REPORT.md` exist:
   - Read `GRAPH_REPORT.md`.
   - Query gaps: `graphify query "<question>" --graph graphify-out/graph.json`.
   - Open source files the graph cites, to confirm.
   - Evidence mode = `graph`.
2. Else (`graphify-out/` missing, incomplete, or CLI absent):
   - Evidence mode = `workspace-scan`.
   - Say so in the HTML subtitle/cards and in the chat reply.
3. **Always** census the workspace (even in `graph` mode): tree, entry points, configs, inter-module imports, routes/handlers, and source files **absent from the graph**. Skip `node_modules`, `.git`, `__pycache__`, `.venv`, `dist`, `build`.
4. Never proceed from assumption.

Every node and edge must map to a real artefact/relation. Cite file paths on cards.

## Step 0b — Inventory

Build a census before asking or drawing. Classify every source artefact:

| Status | Meaning |
|---|---|
| `live` | Reachable from an entry point (omit `data-node-status` or set `live`) |
| `orphan` | No edges, or on disk and missing from the graph |
| `dead` | Exists but no entry point reaches it (import/call) |
| `edge-case` | Error branches, flags, test-only or exception paths |

**Complex excerpts (required on the default map):** non-trivial recortes — branching handlers/routes, high-degree functions, state machines, atypical links. List them with parent file path. These become child nodes with `data-parent-id`.

Do **not** collapse files into a stack/module/language box (`Frontend`, `Python`, `npm`, `Services`). One node = one real artefact (source file, package folder with an entry, compose service, imported dependency by exact name).

## Step 0c — Depth AskQuestion

After inventory, **before** authoring SVG, one AskQuestion:

- **Default (Recommended):** files + complex excerpts visible on the canvas
- **More depth:** remaining public symbols (classes/functions/routes) and internal call/import edges

Rules:

- Do not offer a shallower option (no “stacks only”, no ~12-node cap).
- Skip the question only if the invoking message already asks for extra depth — then go straight to that level.
- Wait for the answer before drawing. Default choice = files + visible complex excerpts.
- Complex excerpts are **never** hidden behind `data-detail="fine"`. Only the optional extra-depth symbols may use `data-detail="fine"`.
- Extra depth extends the same map; do not restart as a cartoon.

## Step 1 — Type router

| Type | Use for |
|---|---|
| `architecture` | **Default mirror.** File-level graph + complex excerpts, directory boundaries, anomaly islands |
| `workflow` | CI/CD, approvals, tool calls, runbooks found in the project |
| `sequence` | One real call chain (API, cache miss, auth) |
| `dataflow` | Pipelines, lineage, consumers found in the project |
| `lifecycle` | State machines, retries, terminal outcomes found in the project |

Read [reference.md](reference.md) for layout recipes of the chosen type. Read [examples.md](examples.md) for SVG shape (field shape, not facts).

## Step 2 — Layout then author the SVG

Write a working file (e.g. `/tmp/cistina-arch.svg`) containing **one** `<svg>...</svg>`. Facts come only from Steps 0–0b.

Invariants:

- No low node cap. Grow the canvas: viewBox minimum `0 0 1000 680`; increase width/height with the grid.
- One node per real artefact. Directories are `c-region` / `c-lane` boundaries, not nodes.
- Default map draws **files + complex excerpts visible** (no `data-detail` on them). Place excerpts beside/below the parent; `data-parent-id` = parent `data-node-id`.
- Optional extra-depth symbols: `data-detail="fine"` + `data-parent-id`.
- Edges on the SVG are the source of truth. Cards cite paths, evidence mode, and census counts — they do not replace nodes or edges.
- Relationship labels are semantic. Move/reroute/shorten before deleting. Delete only when both endpoints fully imply the relation and it has no protocol/action/direction. Do not drop edges to “clean up” the drawing.
- Anomalies stay on the canvas: a `c-region` island (“unreferenced / dead”) plus `data-node-status="orphan|dead|edge-case"`. Kind stays semantic (`backend`, …).
- Node pattern: mask rect `.c-mask` + typed rect `.c-<kind>` + title 11px `.t-primary` + sublabel 9px `.t-muted`. File nodes typical `110×44`; excerpts `90×32`. Gap between neighbors ≥ 16px.
- Never inline `fill`/`stroke` colors. CSS classes only (theme toggle depends on it).
- Omit `data-preset` on `<html>` injection (inject default `classic`). Set `signal-flow` / `blueprint` / `editorial` only if the user asks.
- Boundaries: dashed rects; label headroom ~30px above inner node (`boundary.y = inner.y - 30`, `h = inner.h + 50`).
- Orthogonal routes; no edge through an unrelated opaque node.
- Language of labels matches the user's request. Keep product names, paths, and identifiers exact.

Viewer contract (required for interactivity):

```svg
<svg viewBox="0 0 1000 680" role="img" aria-label="…" data-animation="trace" data-preset="classic">
  <g id="node-api" data-node-id="api" data-node-kind="backend"
     data-node-label="API" data-node-sublabel="app.py"
     tabindex="0" role="button" aria-pressed="false">
    <rect x="510" y="280" width="110" height="44" rx="6" class="c-mask"/>
    <rect x="510" y="280" width="110" height="44" rx="6" class="c-backend"
          data-animate="node" style="--step: 2" stroke-width="1.5"/>
    <text x="565" y="297" class="t-primary" font-size="11" font-weight="600" text-anchor="middle">app.py</text>
    <text x="565" y="313" class="t-muted" font-size="9" text-anchor="middle">src/api</text>
  </g>
  <g id="node-create-order" data-node-id="create-order" data-node-kind="backend"
     data-node-label="create_order" data-node-sublabel="handler"
     data-parent-id="api"
     tabindex="0" role="button" aria-pressed="false">
    <rect x="510" y="340" width="110" height="32" rx="6" class="c-mask"/>
    <rect x="510" y="340" width="110" height="32" rx="6" class="c-backend" stroke-width="1.5"/>
    <text x="565" y="360" class="t-primary" font-size="11" font-weight="600" text-anchor="middle">create_order</text>
  </g>
  <path data-edge-from="web" data-edge-to="api" data-edge-label="HTTPS"
        data-edge-key="0" data-edge-id="web-to-api"
        data-animate="edge" style="--step: 1"
        d="M 310 302 L 508 302" class="a-emphasis" stroke-width="1.5"
        marker-end="url(#arrowhead-emphasis)"/>
</svg>
```

- Node kinds: `frontend` `backend` `database` `cloud` `security` `messagebus` `external`.
- Optional `data-node-status`: `live` (omissible) | `orphan` | `dead` | `edge-case`.
- Optional `data-parent-id`: must equal an existing `data-node-id`.
- Edges: `data-edge-from` / `data-edge-to` must equal existing `data-node-id`.
- Trace: `data-animation="trace"` on `<svg>` + `data-animate="edge|node"` + sequential `--step` along the main path. Omit animation attributes if the user wants a static map.
- Include `<defs>` (arrow markers + grid pattern) as in [examples.md](examples.md).

## Step 3 — Validate

```bash
sh .claude/skills/cistina-arch/scripts/check.sh /tmp/cistina-arch.svg
```

Fix only the named subject. Four focused repair rounds max; then report remaining diagnostics.

## Step 4 — Deliver HTML

Write cards HTML (paths, evidence mode, census counts). For `architecture`, guided views JSON is **required** (ids from authored nodes; at most 16 chapters). Required chapters: (1) path from entry points, (2) orphans & dead, (3) edge cases. Extra chapters per dense directory are allowed.

```bash
sh .claude/skills/cistina-arch/scripts/inject.sh \
  --svg /tmp/cistina-arch.svg \
  --title "…" \
  --subtitle "Evidence: graph | workspace-scan" \
  --cards /tmp/cistina-arch-cards.html \
  --views /tmp/cistina-arch-views.json \
  -o docs/architecture-map.html
```

`--preset` defaults to `classic`. `--views` is required for architecture; optional for other types.

Do **not** open or rewrite `template.html`.

## Step 5 — Optional visual check

If Chrome/Chromium exists, screenshot the HTML. Otherwise tell the user the file path to open. Do not claim visual inspection you did not perform.

## Libs

Required: none. The template is plain HTML/CSS/SVG/JS; the scripts run on POSIX `sh` + `awk` (present on any Linux/macOS/WSL/BusyBox — no Python or Node needed).
Optional: Chrome/Chromium for screenshots.

## Output contract

Return: HTML path, diagram type, evidence mode (`graph` | `workspace-scan`), depth (`default` | `more`), node/edge counts, census counts (live/orphan/dead/edge-case), check.sh summary. List file paths cited. Do not claim success if check.sh failed.
