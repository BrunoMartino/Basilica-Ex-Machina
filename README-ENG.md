<p align="center">
  <img src="assets/basilica-ex-machina.png" alt="Basilica Ex Machina" width="480" />
</p>

# Basilica Ex Machina

> *“Code is the residual product of the theory of the project’s construction.”*  
> — adapted from Peter Naur

A collection of **skills**, **rules**, **agents**, and **boilerplates** to start a project with **Claude Code** or **Cursor** already guided by conventions, guardrails, and repeatable workflows.

This is not a runnable application: it is the core of a build driven by the project itself — human-written docs, AI-derived especs, and code derived from both.

| IDE / CLI | Kit folder | Rule extension |
|-----------|------------|----------------|
| **Claude Code** | `.claude/` | `.md` |
| **Cursor** | `.cursor/` | `.mdc` |

Skills, agents, and rules are the same on both sides; only the path and rule file extension differ.

**Repository:** [BrunoMartino/Basilica-Ex-Machina](https://github.com/BrunoMartino/Basilica-Ex-Machina)

[Português](README.md)

## What’s included

The toolkit organizes the build **around the project as its core**: humans write the project's theory in `docs/` (with the harness in `docs/harness/`), Graphify keeps the code graph in `graphify-out/`, the AI derives the specifications in `especs/` (design docs, waves, Red/Green phases, handoffs, reports) from that theory, and only then generates code, DB, APIs and tests from `docs/harness/` + `especs/`. Skills, rules and agents are the tools; the core is always the project.

### Agents (`.claude/agents/` or `.cursor/agents/`)

The build triad — invoked **only by the user**, as the main thread (`claude --agent <name>`), so each can spawn parallel sub-agents:

| Agent | Role |
|-------|------|
| `scultore` | Wave orchestrator: reads `especs/design-docs/implementation.md` and runs each wave — Red with `tester`, Green with `design-patterns-coder` — for the **DB and Backend** layers, with parallel "cinzel" sub-agents per lane. Never writes frontend: hands that layer to Pittore through a manual handoff (`especs/tdd/wave{N}/`) |
| `pittore` | Frontend and finishing: `/cast` (existing design system) or `/paint` (new design system) with "brush" sub-agents built on the `amaterasu` skill; keeps Graphify up to date, draws the flowchart with `sistina-arch`, checks performance and browser compatibility (Chrome/Safari/Firefox) and audits the code against the harness, flagging backend fixes to Scultore |
| `ingegnere` | Quality and security: detects the stack, installs the static-analysis toolchain (format, static, dead code, cyclomatic/cognitive complexity, security, duplication) with Lefthook running the same Quality Run, reads only the failures from the SARIF/JSON report and fixes in a loop until the gate passes — without breaking the architecture or the design patterns. Spawns "squadra" sub-agents for the `controspia` audits and `coupling-analizer` |

### Using the triad on long projects

**Setup (once):**

1. Generate the harness with `harness-create` (greenfield) or `legacy-explainer` (brownfield), including one `docs/harness/features/feature-{name}.md` per feature.
2. Generate the graph with `legacy-explainer` (`graphify-out/`).
3. Invoke `design-docs-creator` for **every listed feature** — one TDD per feature in `especs/design-docs/`. With more than one feature, the skill also writes `especs/design-docs/implementation.md` with the **waves**.

**How waves are built:** a wave is a set of features that independent agents can implement **in parallel** — no writes to the same files, modules or tables, and no dependency on an artifact of another feature in the same wave. Any dependency (schema, API contract, shared module, migration) pushes the feature to a later wave. Each feature is a **lane** with the paths it may touch; waves are sequential (N+1 starts only once N is merged and green).

**Recommended flow — whole project:**

1. `scultore` in `backend-first` mode — all DB/Backend of every wave, without stopping between them.
2. `pittore` — all the frontend and finishing from the handoffs; backend signals go back to Scultore, which fixes them and closes the final gate.
3. `ingegnere` — security and code quality over the whole repository.

**Per-wave flow:** in `per-wave` mode (default), each wave goes Scultore (DB/Backend) → Pittore (Frontend) → Scultore (exit gate) before the next one; `ingegnere` can run at the end of each wave scoped to `especs/tdd/wave{N}/`.

**Standalone tasks:** each agent can also be called on its own, outside `implementation.md` — Pittore for a redesign (`/cast`, `/paint`), a flowchart or an audit; Ingegnere for a set of paths or the whole repository; Scultore for a specific wave the user names.


### Skills (`.claude/skills/` or `.cursor/skills/`)

Specialized instructions the agent can invoke for concrete tasks:

| Skill | Role |
|-------|------|
| `harness-create` | Creates harness docs interactively (asks only for what’s missing) and installs the `all-for-harness` rule |
| `tester` | TDD: failing tests first, then minimal code; triangulation on 4 axes (happy, boundary, negative, adversarial); Green handoff in `especs/tdd/fase{N}.md` + `fase{N}Task.md` |
| `design-patterns-coder` | GoF patterns only from the developer’s documentation (docs-mcp `gof-design-patterns`; GitHub fallback); composition over inheritance |
| `code-commenter` | Block comments and documentation for non-trivial logic |
| `design-docs-creator` | Technical design docs: specs, RFCs, and architecture proposals via interactive discovery; Red/Green implementation phases |
| `coupling-analizer` | Module coupling analysis (strength, distance, volatility) |
| `quality-gate` | Machine-level static-analysis toolchain (PATH, never a project dependency) + Lefthook for Go, Python, TS/JS and PHP; check-only Quality Run (`check.sh`) with a failures-only `.quality/report.json`. Used by `ingegnere` |
| `legacy-explainer` | Graphify: explains a legacy codebase AND regenerates/updates the graph (`graphify-out/`); fills harness docs |
| `sistina-arch` | Graphify companion: interactive HTML at file level with visible complex excerpts; AskQuestion for extra depth; orphans and dead code on the canvas |
| `get-that-task` | Jira lookup: open issues assigned to the user and unassigned |
| `get-my-tools` | Inventories and installs skills, rules, and docs from this toolkit into the current project (useful in dev containers) |
| `wordpress-developer` | Scan and mitigate common WordPress vulnerabilities via the local theme (xmlrpc, feeds, comments, CORS, …) |
| `shopify-developer` | Full Shopify development reference (Liquid, OS 2.0 themes, GraphQL, Hydrogen, Functions) |
| `learn-live-canvas` | LiveCanvas + Picostrap 5 docs and hooks from a synced local cache |
| `node-express-project` | Node+Express+TS scaffold (npm/bun, Zod, Prisma/Drizzle, parallelism, Jest) |
| `node-fastify-project` | Node+Fastify+TS scaffold (npm/bun, Zod, Prisma/Drizzle, parallelism, Jest) |
| `nest-project` | Optimized NestJS scaffold (SWC/Vite, validators, Prisma/Drizzle, security, Jest) |
| `laravel-project` | Optimized Laravel install with API (Sanctum), Eloquent, FormRequests, PHPUnit, and strict types (Larastan) |
| `django-project` | Django API (DRF) or Vue monolith; pytest, Pydantic, SQLAlchemy, optional pandas/numpy |
| `django-fastapi-project` | Django + FastAPI mounted on the same ASGI; pytest, Pydantic, SQLAlchemy |
| `make-etl-project` | Python ETL project (SQLAlchemy, pandas, numpy) with source/target DBs and pytest per E/T/L stage |
| `create-minio-docker` | Generates MinIO (Dockerfile + docker-compose) and `install.md` for Coolify deploy (API/Console, buckets, credentials) |
| `database-postgres-mcp` | Installs MCP-explorer-for-Postgress and registers it in the agent’s MCP config |
| `build-a-castle` | Installs the Coolify MCP [Ingeniarius-Castellorum](https://github.com/BrunoMartino/Ingeniarius-Castellorum) locally; ends by listing the `.env` vars to fill |
| `build-a-library` | Installs the [Michelangelo-Dev-Inks](https://github.com/BrunoMartino/Michelangelo-Dev-Inks) MCP locally (docs RAG on SQLite/FTS5) and registers it as `docs-mcp` for the models |
| `statera-quaderno` | Installs the [Statera-Quaderno-MCP](https://github.com/BrunoMartino/Statera-Quaderno-MCP) locally (WordPress + WooCommerce content and coupons), one server per store; ends by listing the `.env` vars to fill |

Each skill lives in a folder with `SKILL.md` (and `examples.md` when applicable).

### Amaterasu — creative UI (Cursor: `.cursor/skills/amaterasu/`)

Caveman (minimal-token) Cursor port of the genjutsu plugin. Explicit invocation; internal modules under `_jutsu/` (not slash skills).

| Skill | Role |
|-------|------|
| `amaterasu-cast` | Motion / micro-interactions: stack scan, design brief (colors/fonts), interaction thesis, implement, quick audit |
| `amaterasu-paint` | Full visual universe: brainstorm, theses, `MASTER.md`, page-by-page implement, full audit |

Extras vs upstream: Tailwind **and** Bootstrap; brief for primary/secondary/tertiary/success/danger/warning + fonts (self-host woff2 by default, CDN only if asked); framework breakpoints + centered `max-width: 1920px` container; Go CLI under `_jutsu/ui-ux-pro-max/cli` (`search`, `design-system`, `audit`). Cursor kit only for now (no `.claude/skills/` mirror yet).

### Controspia — security block (`.claude/skills/controspia/` or `.cursor/skills/controspia/`)

Cybersecurity skills grouped into their own block, with a **dedicated README** ([PT](.claude/skills/controspia/README.md) · [EN](.claude/skills/controspia/README-ENG.md)) covering each skill, when to use it and when not to:

| Skill | Purpose |
|-------|---------|
| `owasp-audit` | Source-code audit against the OWASP Top 10 (2021), A01–A10, with runtime verification of fixes |
| `api-audit` | OWASP API Security Top 10 (2023) endpoint by endpoint (REST, GraphQL, RPC): BOLA, BFLA, mass assignment, SSRF |
| `container-audit` | Dockerfiles, Helm/Kustomize, Kubernetes manifests and runtime: privileges, secrets, PSS, network policies, RBAC |
| `incident-triage` | Incident response (NIST SP 800-61): classification, containment, evidence preservation, IOCs |
| `finding-triage` | One finding → defensible disposition (Fixed / Deferred / Accepted Risk) with mitigation plan or accepted risk |
| `offensive/recon` | Attack surface enumeration (passive and active) against authorized targets |
| `offensive/osint-recon` | Open source intelligence: infrastructure, organization, emails, documents, threat intel |
| `offensive/web-pentest` | Black-box / grey-box web pentest in 9 phases (Burp Suite / OWASP ZAP) |
| `offensive/red-legio` | Authorized red-team engagement: RoE, assumed breach, ATT&CK emulation, deconfliction, debrief |
| `report/security-comms` | Translates security work for the board, executives, engineering, customers, legal |

The `offensive/` skills **require explicit authorization for the target** — they open with an authorization check and refuse ambiguous targets. Upstream: [briiirussell/cybersecurity-skills](https://github.com/briiirussell/cybersecurity-skills) (MIT), partially selected, with `red-team-engagement` renamed to `red-legio`.

### Rules

Always-on rules that steer agent behavior:

| Claude Code | Cursor |
|-------------|--------|
| `.claude/rules/*.md` | `.cursor/rules/*.mdc` |

- **`all-for-harness`** — docs under `docs/harness/` are binding: the agent reads them before architecture, test, deploy, domain, or feature changes; they win over generic “best practices”; mandatory flow docs → code → graphify. Feature gate: no new feature without `docs/harness/features/feature-{name}.md` with the user’s 4 answers. Installed with the docs by `harness-create`.
- **`graphify-first`** — before inferring architecture/flows/dependencies, consult Graphify (`graphify-out/`) first; if unavailable, ask the user.
- **`persisted-tester`** — existing tests must not be removed or changed by the agent; cover changes with new tests and flag obsolete ones.
- **`less-talk`** — no unsolicited explanations, scope extras, or token waste in Agent/Ask mode; Plan mode keeps depth.
- **`dont-write-env`** — never edit `.env`; only `.env.example`.
- **`python-uv-package-manager`** — in Python projects, always use `uv` (`uv add` / `uv run` / `uv sync`); no pip/poetry/conda.
- **`api-pydantic-schemas`** — API endpoints use explicit Pydantic request/response schemas; no raw `dict`/`Any`.
- **`enforces-english`** — skills, harness docs, docs, agents, design docs, and TDD phases (`especs/tdd/…`) must be written in **English**, even when the prompt is not (except verbatim quotes/identifiers).
- **`llm-payloads-toon`** — all data passed to LLMs must be TOON; no exceptions. *(Cursor kit today; mirror under `.claude/rules/` if needed for Claude Code)*
- **`nest-conventions`** — Nest AI-First architecture (explicit DI, feature-first, Import First); binds on Nest targets; wins over generic MVC on Nest. Used by `nest-project` / `harness-create` / `legacy-explainer`.

### Harness docs — boilerplate (`docs/harness/`)

Templates for project rules. Copy each `*_template.md`, drop the `_template` suffix, and fill in for your context:

| Template | Final document | Content |
|----------|----------------|---------|
| `architeture_rules_template.md` | `architecture_rules.md` | Architectural style (MVC by default), modules, allowed patterns |
| `coding_conventions_template.md` | `coding_convention.md` | Code style and MVC conventions |
| `forbidden_patterns_template.md` | `forbidden_patterns.md` | Anti-patterns and architectures forbidden by default |
| `testing_expectations_template.md` | `testing_expectation.md` | Testing expectations and coverage |
| `deployment_rules_template.md` | `deployment_rules.md` | Deploy rules and environments |
| `domain_invariants_template.md` | `domain_invariantes.md` | Invariants and business rules |
| `operational_constraints_template.md` | `operational_constraints.md` | Operational limits (SLA, quotas, etc.) |
| `features_template.md` | `features/feature-{name}.md` | One file per feature: description, problem, solution + trade-offs, example/context (user’s 4 answers); feature relations |

These documents are the **source of truth** that skills such as `tester` and `design-patterns-coder` consult before implementing. All AI-generated documentation (design docs, `implementation.md`, TDD, waves, Red/Green phases, handoffs, reports) lives in `especs/` and always derives from `docs/`; `docs/` holds only what humans write. Code, DB, tests and every other artifact derive from `docs/harness/` + `especs/`; the rest of `docs/` is read only when the especs fall short or the user asks.

### Other boilerplates

- **`especs/testsReadme.md`** — test catalog (table to register suites, files, and how to run them in isolation).
- **`especs/tdd/`** — created by `tester` during Red: `fase{N}.md` (Green plan) and `fase{N}Task.md` (checklist).

## How to use (Claude Code)

1. **Copy** into the target repository:
   - `.claude/skills/`
   - `.claude/rules/`
   - `.claude/agents/` (optional)
   - `docs/harness/*_template.md`
   - `especs/testsReadme.md` (optional)

   **Alternative (dev container / no local clone):** invoke `get-my-tools` in Claude Code to list and install items from GitHub.

2. **Materialize harness docs**: invoke `harness-create` (greenfield — asks questions and generates each doc from templates, including `features/`, installing `all-for-harness`), or rename and fill the templates manually.

3. **Tune** skills and rules to the project stack (Jira, npm, Graphify, uv/Python, etc.) — many skills assume MCP integrations (Atlassian, Snyk, docs-mcp, etc.).

4. **Optional — legacy project**: invoke `legacy-explainer` to generate initial documentation from existing code.

5. **Optional — architecture decisions**: invoke `design-docs-creator` before significant features; use `coupling-analizer` for coupling; use `design-patterns-coder` in Green when GoF patterns apply.

6. **TDD**: explicitly ask for **Red** or **Green** (or both); `scultore` runs them per wave — Red with `tester`, Green with `design-patterns-coder`.

7. **Keep** `docs/harness/` and the graph up to date when code, architecture, or domain rules change — invoke `legacy-explainer` after relevant changes; `all-for-harness` and `graphify-first` depend on that.

## How to use (Cursor)

Same steps, swapping `.claude/` for `.cursor/` and rule `.md` for `.mdc`. Cursor’s `get-my-tools` installs under `.cursor/`.

## Repository structure

```
.
├── .claude/                 # Claude Code kit
│   ├── agents/
│   ├── rules/               # *.md
│   └── skills/
│       └── controspia/      # Security block (+ offensive/, report/)
├── .cursor/                 # Cursor kit (mirror)
│   ├── agents/
│   ├── rules/               # *.mdc
│   └── skills/              # mirror + controspia/ + amaterasu/ (Cursor)
├── docs/                    # Human-written
│   └── harness/             # Templates (incl. features)
├── especs/                  # AI-generated (design docs, waves, phases, handoffs, reports)
│   └── testsReadme.md
├── README.md                # Portuguese
└── README-ENG.md            # English
```

The `drafts/` folder holds work-in-progress drafts and is **not** part of the stable kit (it is in `.gitignore`).

## Principles

- **Simple MVC by default** — no global DDD, Clean/Hexagonal, or CQRS unless explicitly requested (see `forbidden_patterns`).
- **Documentation before structural changes** — the agent reads harness docs; it does not invent rules; features require the user’s 4 answers.
- **GoF patterns only from project docs** — via `design-patterns-coder` / docs-mcp, never from model memory.
- **Closed-scope skills** — each covers one flow (TDD, patterns, audit, dependencies, Jira, …).
- **Editable boilerplate** — generic templates; the concrete project fills in the details.
- **Claude / Cursor parity** — the same kit on both agents; keep the folders aligned when changing skills or rules.

## License

Set an appropriate license when you copy this kit into your repositories.
