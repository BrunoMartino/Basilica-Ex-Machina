# Cistina Arch — SVG shape examples

Use these for **markup shape only**. Replace ids, labels, and coordinates with evidence from the project. Do not copy these facts into a real map.

## Architecture fragment

```svg
<svg viewBox="0 0 1000 680" role="img" aria-label="Runtime architecture" data-animation="trace" data-preset="classic">
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

  <rect x="200" y="40" width="760" height="560" rx="12" class="c-region" stroke-width="1"/>
  <text x="212" y="58" class="t-cloud" font-size="10" font-weight="600">runtime</text>

  <path data-edge-from="users" data-edge-to="web" data-edge-label="HTTPS" data-edge-key="0" data-edge-id="users-to-web"
        data-animate="edge" style="--step:0" d="M 150 305 L 248 305"
        class="a-emphasis" stroke-width="1.8" marker-end="url(#arrowhead-emphasis)"/>
  <text x="199" y="299" class="t-muted" font-size="9" text-anchor="middle">HTTPS</text>

  <path data-edge-from="web" data-edge-to="api" data-edge-key="1" data-edge-id="web-to-api"
        data-animate="edge" style="--step:1" d="M 410 305 L 508 305"
        class="a-emphasis" stroke-width="1.8" marker-end="url(#arrowhead-emphasis)"/>

  <path data-edge-from="api" data-edge-to="db" data-edge-label="SQL" data-edge-key="2" data-edge-id="api-to-db"
        data-animate="edge" style="--step:2" d="M 620 305 L 698 305"
        class="a-default" stroke-width="1.5" marker-end="url(#arrowhead)"/>
  <text x="659" y="299" class="t-muted" font-size="9" text-anchor="middle">SQL</text>

  <path data-edge-from="auth" data-edge-to="api" data-edge-label="verify JWT" data-edge-key="3" data-edge-id="auth-to-api"
        data-animate="edge" style="--step:1" d="M 150 110 L 565 110 L 565 278"
        class="a-security" stroke-width="1.5" marker-end="url(#arrowhead-security)"/>
  <text x="320" y="104" class="t-security" font-size="8">verify JWT</text>

  <g id="node-users" data-node-id="users" data-node-kind="external" data-node-label="Users"
     data-node-sublabel="Browser" tabindex="0" role="button" aria-pressed="false">
    <rect x="30" y="280" width="120" height="50" rx="6" class="c-mask"/>
    <rect x="30" y="280" width="120" height="50" rx="6" class="c-external" data-animate="node" style="--step:0" stroke-width="1.5"/>
    <text x="90" y="300" class="t-primary" font-size="11" font-weight="600" text-anchor="middle">Users</text>
    <text x="90" y="316" class="t-muted" font-size="9" text-anchor="middle">Browser</text>
  </g>

  <g id="node-auth" data-node-id="auth" data-node-kind="security" data-node-label="Auth"
     data-node-sublabel="OAuth 2.0" tabindex="0" role="button" aria-pressed="false">
    <rect x="30" y="80" width="120" height="60" rx="6" class="c-mask"/>
    <rect x="30" y="80" width="120" height="60" rx="6" class="c-security" data-animate="node" style="--step:1" stroke-width="1.5"/>
    <text x="90" y="105" class="t-primary" font-size="11" font-weight="600" text-anchor="middle">Auth</text>
    <text x="90" y="121" class="t-muted" font-size="9" text-anchor="middle">OAuth 2.0</text>
  </g>

  <g id="node-web" data-node-id="web" data-node-kind="frontend" data-node-label="Web App"
     data-node-sublabel="UI" tabindex="0" role="button" aria-pressed="false">
    <rect x="250" y="280" width="160" height="50" rx="6" class="c-mask"/>
    <rect x="250" y="280" width="160" height="50" rx="6" class="c-frontend" data-animate="node" style="--step:1" stroke-width="1.5"/>
    <text x="330" y="300" class="t-primary" font-size="11" font-weight="600" text-anchor="middle">Web App</text>
    <text x="330" y="316" class="t-muted" font-size="9" text-anchor="middle">UI</text>
  </g>

  <g id="node-api" data-node-id="api" data-node-kind="backend" data-node-label="API"
     data-node-sublabel="handlers" tabindex="0" role="button" aria-pressed="false">
    <rect x="510" y="280" width="110" height="50" rx="6" class="c-mask"/>
    <rect x="510" y="280" width="110" height="50" rx="6" class="c-backend" data-animate="node" style="--step:2" stroke-width="1.5"/>
    <text x="565" y="300" class="t-primary" font-size="11" font-weight="600" text-anchor="middle">API</text>
    <text x="565" y="316" class="t-muted" font-size="9" text-anchor="middle">handlers</text>
  </g>

  <g id="node-db" data-node-id="db" data-node-kind="database" data-node-label="Database"
     data-node-sublabel="Postgres" tabindex="0" role="button" aria-pressed="false">
    <rect x="700" y="280" width="120" height="50" rx="6" class="c-mask"/>
    <rect x="700" y="280" width="120" height="50" rx="6" class="c-database" data-animate="node" style="--step:3" stroke-width="1.5"/>
    <text x="760" y="300" class="t-primary" font-size="11" font-weight="600" text-anchor="middle">Database</text>
    <text x="760" y="316" class="t-muted" font-size="9" text-anchor="middle">Postgres</text>
  </g>
</svg>
```

## Sequence fragment

```svg
<svg viewBox="0 0 820 520" role="img" aria-label="Request sequence" data-animation="trace" data-preset="classic">
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

  <rect x="48" y="150" width="724" height="140" rx="10" class="c-lane" stroke-width="1"/>
  <rect x="48" y="310" width="724" height="150" rx="10" class="c-lane" stroke-width="1"/>

  <path d="M 100 142 L 100 480" class="a-default" stroke-width="0.8" stroke-dasharray="3,7"/>
  <path d="M 280 142 L 280 480" class="a-default" stroke-width="0.8" stroke-dasharray="3,7"/>
  <path d="M 460 142 L 460 480" class="a-default" stroke-width="0.8" stroke-dasharray="3,7"/>
  <path d="M 640 142 L 640 480" class="a-default" stroke-width="0.8" stroke-dasharray="3,7"/>

  <rect x="275" y="200" width="10" height="250" rx="3" class="c-mask"/>
  <rect x="275" y="200" width="10" height="250" rx="3" class="c-frontend" stroke-width="1"/>
  <rect x="455" y="220" width="10" height="200" rx="3" class="c-mask"/>
  <rect x="455" y="220" width="10" height="200" rx="3" class="c-backend" stroke-width="1"/>

  <g data-edge-from="user" data-edge-to="web" data-edge-label="open page" data-edge-key="0" data-edge-id="open-page">
    <path d="M 105 185 L 275 185" class="a-default" data-animate="edge" style="--step:0"
          stroke-width="1.4" marker-end="url(#arrowhead)"/>
    <rect x="150" y="167" width="70" height="16" rx="3" class="c-mask"/>
    <text x="185" y="178" class="t-muted" font-size="9" text-anchor="middle">open page</text>
  </g>
  <g data-edge-from="web" data-edge-to="api" data-edge-label="GET /x" data-edge-key="1" data-edge-id="get-x">
    <path d="M 285 228 L 455 228" class="a-emphasis" data-animate="edge" style="--step:1"
          stroke-width="1.5" marker-end="url(#arrowhead-emphasis)"/>
    <rect x="330" y="210" width="70" height="16" rx="3" class="c-mask"/>
    <text x="365" y="221" class="t-muted" font-size="9" text-anchor="middle">GET /x</text>
  </g>
  <g data-edge-from="api" data-edge-to="db" data-edge-label="query" data-edge-key="2" data-edge-id="query">
    <path d="M 465 340 L 635 340" class="a-emphasis" data-animate="edge" style="--step:2"
          stroke-width="1.5" marker-end="url(#arrowhead-emphasis)"/>
    <rect x="510" y="322" width="50" height="16" rx="3" class="c-mask"/>
    <text x="535" y="333" class="t-muted" font-size="9" text-anchor="middle">query</text>
  </g>
  <g data-edge-from="api" data-edge-to="web" data-edge-label="200 JSON" data-edge-key="3" data-edge-id="response">
    <path d="M 455 400 L 285 400" class="a-default" data-animate="edge" style="--step:3"
          stroke-width="1.4" marker-end="url(#arrowhead)"/>
    <rect x="330" y="382" width="70" height="16" rx="3" class="c-mask"/>
    <text x="365" y="393" class="t-muted" font-size="9" text-anchor="middle">200 JSON</text>
  </g>

  <g id="node-user" data-node-id="user" data-node-kind="external" data-node-label="User"
     data-node-sublabel="browser" tabindex="0" role="button" aria-pressed="false">
    <rect x="55" y="70" width="90" height="54" rx="6" class="c-mask"/>
    <rect x="55" y="70" width="90" height="54" rx="6" class="c-external" data-animate="node" style="--step:0" stroke-width="1.5"/>
    <text x="100" y="92" class="t-primary" font-size="11" font-weight="600" text-anchor="middle">User</text>
    <text x="100" y="108" class="t-muted" font-size="9" text-anchor="middle">browser</text>
  </g>
  <g id="node-web" data-node-id="web" data-node-kind="frontend" data-node-label="Web"
     data-node-sublabel="UI" tabindex="0" role="button" aria-pressed="false">
    <rect x="235" y="70" width="90" height="54" rx="6" class="c-mask"/>
    <rect x="235" y="70" width="90" height="54" rx="6" class="c-frontend" data-animate="node" style="--step:1" stroke-width="1.5"/>
    <text x="280" y="92" class="t-primary" font-size="11" font-weight="600" text-anchor="middle">Web</text>
    <text x="280" y="108" class="t-muted" font-size="9" text-anchor="middle">UI</text>
  </g>
  <g id="node-api" data-node-id="api" data-node-kind="backend" data-node-label="API"
     data-node-sublabel="handler" tabindex="0" role="button" aria-pressed="false">
    <rect x="415" y="70" width="90" height="54" rx="6" class="c-mask"/>
    <rect x="415" y="70" width="90" height="54" rx="6" class="c-backend" data-animate="node" style="--step:2" stroke-width="1.5"/>
    <text x="460" y="92" class="t-primary" font-size="11" font-weight="600" text-anchor="middle">API</text>
    <text x="460" y="108" class="t-muted" font-size="9" text-anchor="middle">handler</text>
  </g>
  <g id="node-db" data-node-id="db" data-node-kind="database" data-node-label="DB"
     data-node-sublabel="store" tabindex="0" role="button" aria-pressed="false">
    <rect x="595" y="70" width="90" height="54" rx="6" class="c-mask"/>
    <rect x="595" y="70" width="90" height="54" rx="6" class="c-database" data-animate="node" style="--step:3" stroke-width="1.5"/>
    <text x="640" y="92" class="t-primary" font-size="11" font-weight="600" text-anchor="middle">DB</text>
    <text x="640" y="108" class="t-muted" font-size="9" text-anchor="middle">store</text>
  </g>
</svg>
```
