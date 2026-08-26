# Cistina Arch — reference

Read this after choosing a diagram type. Do not inline colors; classes come from `template.html`.

## Semantic classes

### Nodes (`c-*`)

| Class | Kind | Use |
|---|---|---|
| `c-frontend` | `frontend` | UI, clients, SDKs |
| `c-backend` | `backend` | APIs, workers, jobs |
| `c-database` | `database` | SQL, cache, warehouse |
| `c-cloud` | `cloud` | CDN, object storage, managed infra |
| `c-security` | `security` | Auth, policy, vaults |
| `c-messagebus` | `messagebus` | Queues, streams, events |
| `c-external` | `external` | Users, third parties |
| `c-mask` | — | Opaque underlay so arrows hide under the node |
| `c-region` | boundary | Cloud/region dashed box |
| `c-security-group` | boundary | Trust/SG dashed box |
| `c-lane` | boundary | Workflow/sequence/lifecycle lane |

Every node: mask rect, then typed rect (`stroke-width="1.5"`, `rx="6"`).

### Status (`data-node-status`) — not a kind

Keep `data-node-kind` semantic. Mark anomalies on the node:

| Value | Use |
|---|---|
| *(omit)* or `live` | Reachable from an entry |
| `orphan` | No edges, or on disk and missing from the graph |
| `dead` | Exists but no entry reaches it |
| `edge-case` | Error / flag / exception / test-only branch |

Child excerpts and extra-depth symbols set `data-parent-id` to the parent file's `data-node-id`.

Default map: files and **complex excerpts are visible** (no `data-detail`). Optional extra-depth symbols may use `data-detail="fine"`.

### Text (`t-*`)

`t-primary` title · `t-muted` sublabel · `t-dim` faint · `t-frontend|backend|database|cloud|security|messagebus|external` accent (tags, boundary labels).

### Edges (`a-*`) + markers (`m-*`)

| Class | Marker | Meaning |
|---|---|---|
| `a-default` | `#arrowhead` | Ordinary relation |
| `a-emphasis` | `#arrowhead-emphasis` | Main path |
| `a-security` | `#arrowhead-security` | Auth/policy (dashed 5,5) |
| `a-dashed` | `#arrowhead-dashed` | Async / optional (dashed 4,4) |

Stroke 1.5 (1.8 on the main path). Prefer `<path>` over `<line>`.

## Presets

Injected on `<html data-preset>` by `inject.sh`. Geometry stays identical; only chrome changes.

| Preset | When |
|---|---|
| `classic` | **Default.** Technical map |
| `signal-flow` | Presentation / demo (user asked) |
| `blueprint` | Infra / deployment review (user asked) |
| `editorial` | Design notes / launch write-up (user asked) |

Never write hex on SVG elements.

## Animation

Keyframes already live in the template. Enable with:

- `<svg data-animation="trace">`
- `data-animate="node"` on the typed rect
- `data-animate="edge"` on the path
- `style="--step: n"` sequential along the **main** path (`0, 1, 2…`)

Side branches may share a nearby step or omit `data-animate`. Respect that `prefers-reduced-motion` is handled by the template. Omit all of the above for a static diagram.

## Layout recipes

### Architecture (default mirror)

**Do not** draw a 4-box LTR stack (`Users → Web → API → DB`) unless those are the only artefacts in the workspace.

- One **boundary** (`c-region` / `c-lane`) per real directory or package. Label = folder path.
- Inside each band: a **grid of file nodes** (one node per source file). Typical size `110×44`. Gap between neighbors ≥ 16px (clear gap, not center distance).
- **Complex excerpts** (branching handlers, high-degree functions, state machines, atypical links): child nodes `90×32` beside or below the parent file, `data-parent-id` set, **no** `data-detail`. Always visible.
- Grow viewBox with the grid: minimum `0 0 1000 680`; width ≈ `max(1000, 40 + cols × 126)`, height ≈ `max(680, 40 + rows × 60)` plus island and excerpt rows.
- External actors and imported third-party packages (exact names) sit outside directory bands.
- **Unreferenced / dead island**: a separate `c-region` to the right or below, not wired to the main path. Put `orphan` and `dead` nodes there. `edge-case` nodes stay near their parent file with `a-dashed` or `a-security` edges.
- Main reachable path uses `a-emphasis`. Do not drop edges to tidy the drawing.

### Workflow

Horizontal **lanes** (`c-lane`) stacked top-to-bottom (participants). Happy path left-to-right across lanes. Exception lane below. Orthogonal connectors; approval/block as `c-security`.

### Sequence

Participants as header nodes in a row. Vertical dashed lifelines. Activation bars (`10px` wide typed rects) on the lifeline. Messages are horizontal paths at increasing `y`. Group each message:

```svg
<g data-edge-from="web" data-edge-to="api" data-edge-label="GET /x" data-edge-key="0" data-edge-id="get-x">
  <path d="M 170 228 L 268 228" class="a-emphasis" data-animate="edge" style="--step:1"
        stroke-width="1.5" marker-end="url(#arrowhead-emphasis)"/>
  <rect x="190" y="210" width="58" height="16" rx="3" class="c-mask"/>
  <text x="219" y="221" class="t-muted" font-size="9" text-anchor="middle">GET /x</text>
</g>
```

Return messages use `a-default` (quieter) or `a-dashed`. Time bands: `c-lane` rects behind messages.

### Data flow

Vertical **stage** columns (Sources → Ingest → Process → Store → Consume). PII/consent as `c-security`. Main lineage `a-emphasis`; restricted `a-security`.

### Lifecycle

Main rail = phases columns `0..4`. Waiting/retry/terminal in rows below. Recoverable failure: `c-security` state **plus** a real transition back to the active state. Terminal states have no outgoing recovery edge.

## Guided views JSON

Required for `architecture`. Optional for other types. Replaces `<!-- ARCHIFY:GUIDED_VIEWS_DATA -->` with:

```html
<script id="archify-guided-views-data" type="application/json">[...]</script>
```

Shape (max 16). Architecture must include at least:

1. path from entry points
2. orphans & dead
3. edge cases

Extra chapters per dense directory are allowed.

```json
[
  {
    "id": "entry-path",
    "label": "Entry path",
    "focus": ["cli", "app-py", "create-order"],
    "note": "Reachable path from the authored entry to durable work."
  },
  {
    "id": "orphans-dead",
    "label": "Orphans and dead code",
    "focus": ["unused-mod"],
    "note": "Artefacts on disk with no inbound reach from an entry."
  },
  {
    "id": "edge-cases",
    "label": "Edge cases",
    "focus": ["retry-handler"],
    "note": "Exception, flag, or recovery branches found in source."
  }
]
```

`focus` ids must exist as `data-node-id`. Do not invent chapters that the SVG cannot play.

## Cards

Put supporting detail and **source paths** here. Dot classes: `cyan` `emerald` `rose` `amber` `violet` `orange`.

```html
<div class="cards">
  <div class="card">
    <div class="card-header">
      <div class="card-dot emerald"></div>
      <h3>Application</h3>
    </div>
    <ul>
      <li>&bull; API — <code>src/api/app.py</code></li>
      <li>&bull; Worker — <code>src/worker/jobs.py</code></li>
    </ul>
  </div>
</div>
```

Always include:

- one card stating evidence mode: `graph` (`graphify-out/`) or `workspace-scan`
- one **census** card with counts: live / orphan / dead / edge-case, plus paths for anomalies

Cards do not replace nodes or edges.

## SVG defs (required in every fragment)

```svg
<defs>
  <marker id="arrowhead" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto">
    <polygon points="0 0, 10 3.5, 0 7" class="m-default" />
  </marker>
  <marker id="arrowhead-emphasis" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto">
    <polygon points="0 0, 10 3.5, 0 7" class="m-emphasis" />
  </marker>
  <marker id="arrowhead-security" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto">
    <polygon points="0 0, 10 3.5, 0 7" class="m-security" />
  </marker>
  <marker id="arrowhead-dashed" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto">
    <polygon points="0 0, 10 3.5, 0 7" class="m-dashed" />
  </marker>
  <pattern id="grid" width="40" height="40" patternUnits="userSpaceOnUse">
    <path d="M 40 0 L 0 0 0 40" class="c-grid" stroke-width="0.5"/>
  </pattern>
</defs>
<rect width="100%" height="100%" fill="url(#grid)" />
```

Draw order: grid → boundaries → edges → nodes (nodes last so masks cover arrows).
