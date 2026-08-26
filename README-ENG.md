<p align="center">
  <img src="assets/michelangelo-dev-toolkit.png" alt="Michelangelo-Dev-Toolkit" width="480" />
</p>

# Michelangelo-Dev-Toolkit

> *“Code is the residual product of the theory of the project’s construction.”*  
> — adapted from Peter Naur

A collection of **skills**, **rules**, **agents**, and **boilerplates** to start a project with **Claude Code** or **Cursor** already guided by conventions, guardrails, and repeatable workflows.

This is not a runnable application: it is a **starter kit** you copy or adapt into a new repository so the agent has consistent context from the first commit.

| IDE / CLI | Kit folder | Rule extension |
|-----------|------------|----------------|
| **Claude Code** | `.claude/` | `.md` |
| **Cursor** | `.cursor/` | `.mdc` |

Skills, agents, and rules are the same on both sides; only the path and rule file extension differ.

**Repository:** [BrunoMartino/Michelangelo-Dev-Toolkit](https://github.com/BrunoMartino/Michelangelo-Dev-Toolkit)

[Português](README.md)

## What’s included

### Skills (`.claude/skills/` or `.cursor/skills/`)

Specialized instructions the agent can invoke for concrete tasks:

| Skill | Role |
|-------|------|
| `harness-create` | Creates harness docs interactively (asks only for what’s missing) and installs the `all-for-harness` rule |
| `tester` | TDD: failing tests first, then minimal code; triangulation on 4 axes (happy, boundary, negative, adversarial); Green handoff in `docs/tdd/fase{N}.md` + `fase{N}Task.md` |
| `design-patterns-coder` | GoF patterns only from the developer’s documentation (docs-mcp `gof-design-patterns`; GitHub fallback); composition over inheritance |
| `code-commenter` | Block comments and documentation for non-trivial logic |
| `design-docs-creator` | Technical design docs: specs, RFCs, and architecture proposals via interactive discovery; Red/Green implementation phases |
| `coupling-analizer` | Module coupling analysis (strength, distance, volatility) |
| `legacy-explainer` | Graphify: explains a legacy codebase AND regenerates/updates the graph (`graphify-out/`); fills harness docs |
| `cistina-arch` | Graphify companion: interactive HTML at file level with visible complex excerpts; AskQuestion for extra depth; orphans and dead code on the canvas |
| `get-that-task` | Jira lookup: open issues assigned to the user and unassigned |
| `get-my-tools` | Inventories and installs skills, rules, and docs from this toolkit into the current project (useful in dev containers) |
| `dependency-guardsman` | npm dependency security: vulnerability scan, supply-chain (typosquatting, install scripts), and licenses |
| `data-guardsman` | Encryption, data classification, secrets management, and injection-safe data access |
| `audit-guardsman` | JSON audit logs for privileged operations, with log-injection protection and no PII |
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

Each skill lives in a folder with `SKILL.md` (and `examples.md` when applicable).

### Agents (`.claude/agents/` or `.cursor/agents/`)

Specialized subagents (spawned by the main agent from their `description`):

| Agent | Role |
|-------|------|
| `test-writer` | TDD Red/Green: only on explicit Red, Green, or (rarely) both; always uses `tester` and `design-patterns-coder`; coverage >50% overall and 80–90% on critical code |
| `security-auditor` | Exploitable vulnerability analysis in backends (APIs, auth, DB, integrations); real impact over theoretical false positives |

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

These documents are the **source of truth** that skills such as `tester`, `design-patterns-coder`, `audit-guardsman`, and `data-guardsman` consult before implementing. Project design docs derive from the features harness.

### Other boilerplates

- **`docs/testsReadme.md`** — test catalog (table to register suites, files, and how to run them in isolation).
- **`docs/tdd/`** — created by `tester` / `test-writer` during Red: `fase{N}.md` (Green plan) and `fase{N}Task.md` (checklist).

## How to use (Claude Code)

1. **Copy** into the target repository:
   - `.claude/skills/`
   - `.claude/rules/`
   - `.claude/agents/` (optional)
   - `docs/harness/*_template.md`
   - `docs/testsReadme.md` (optional)

   **Alternative (dev container / no local clone):** invoke `get-my-tools` in Claude Code to list and install items from GitHub.

2. **Materialize harness docs**: invoke `harness-create` (greenfield — asks questions and generates each doc from templates, including `features/`, installing `all-for-harness`), or rename and fill the templates manually.

3. **Tune** skills and rules to the project stack (Jira, npm, Graphify, uv/Python, etc.) — many skills assume MCP integrations (Atlassian, Snyk, docs-mcp, etc.).

4. **Optional — legacy project**: invoke `legacy-explainer` to generate initial documentation from existing code.

5. **Optional — architecture decisions**: invoke `design-docs-creator` before significant features; use `coupling-analizer` for coupling; use `design-patterns-coder` in Green when GoF patterns apply.

6. **TDD**: explicitly ask for **Red** or **Green** (or both) via the `test-writer` agent, which follows `tester` + `design-patterns-coder`.

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
├── .cursor/                 # Cursor kit (mirror)
│   ├── agents/
│   ├── rules/               # *.mdc
│   └── skills/
├── docs/
│   ├── harness/             # Templates (incl. features)
│   └── testsReadme.md
├── README.md                # Portuguese
└── README.en.md             # English
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
