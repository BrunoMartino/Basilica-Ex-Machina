---
name: quality-gate
description: >-
  Sets up the machine-level static-analysis toolchain and Lefthook, and runs the
  deterministic check-only Quality Run for Go, Python, TypeScript/JavaScript and PHP
  (format, static analysis, security, dead code, cyclomatic/cognitive complexity,
  duplication, tests) with a failures-only SARIF/JSON report. Use when bootstrapping
  the gate, installing lefthook, gitleaks, semgrep, jscpd, ruff, mypy, bandit, vulture,
  radon, complexipy, staticcheck, gosec, gocyclo, gocognit, deadcode, biome, knip,
  oxlint, eslint-plugin-sonarjs, php-cs-fixer, phpstan, phan or phpmd, or when running / reviewing the gate.
  Used by the `ingegnere` agent. SETUP installs to PATH (never project deps); RUN is
  scripts/check.sh — check-only, never fixes, never installs.
---

# Quality gate

Adapted from [newsand/LeonardoDev-Toolkit](https://github.com/newsand/LeonardoDev-Toolkit) (`quality-gate`), expanded to Go, Python, JS/TS and PHP with the Ingegnere toolchain.

Two modes. Never add these CLIs to `pyproject.toml` / `package.json` / `go.mod` / `composer.json`.

| Mode | When | What |
|------|------|------|
| **SETUP** | User asked to set up the gate, or `ingegnere` step "Toolchain" (after user approval) | Install missing CLIs on the user PATH; write thin repo configs, `scripts/quality/*` and `lefthook.yml`; `lefthook install` **only** with `--git-hooks` |
| **RUN** | Agent audit / repair loop, "run the gate", end of a wave | `scripts/check.sh` — `lefthook validate` + `scripts/quality/run.sh`. Check-only |

## Non-negotiables

- **RUN never runs `lefthook install` and never fixes** (no `--fix`, `--write`, `format` without check). RUN never installs anything: a missing CLI or a missing `lefthook.yml` / `scripts/quality/*` → stop and point to SETUP.
- **Human commit/push only goes through Lefthook after SETUP `--git-hooks`.** Git hooks are installed by SETUP and nothing else.
- **Agents always go through `check.sh`.** Agents never call `lefthook run`, never rely on git hooks to validate their work, and never commit with `--no-verify`.
- Install on the machine PATH, never as project dependencies. Never install language runtimes (Go, Python via uv, Node, PHP); a missing runtime is reported and that stack is skipped.
- Coverage and test runners stay in the project env (pytest, go test, the JS test script, PHPUnit/Pest). SETUP does not install them.

## SETUP

Run from the **target repo** root:

```bash
.cursor/skills/quality-gate/scripts/setup.sh --plan        # print the install plan, change nothing
.cursor/skills/quality-gate/scripts/setup.sh               # apply
.cursor/skills/quality-gate/scripts/setup.sh --git-hooks   # apply + lefthook install
```

| Flag | Effect |
|------|--------|
| `--plan` | Dry run: lists CLIs to install and files to write. Show it to the user and wait for approval |
| `--git-hooks` | `lefthook install` (pre-commit + pre-push in this repo). Only when the user wants git hooks |
| `--force` | Overwrite existing gate configs/scripts (default: skip files that exist) |
| `--dir PATH` | Target another directory |

Env: `QUALITY_GATE_BIN_DIR` (default `~/.local/bin`), `QUALITY_GATE_TOOLS_DIR` (default `~/.local/share/quality-gate`, isolated composer projects for the PHP tools). Linux/macOS; on Windows run it from WSL or Git Bash.

Versions are pinned at the top of `setup.sh`. A CLI already on PATH is skipped; every installed CLI is smoke-tested (`--version`) and a CLI that does not run is reported as an error.

### Stack detection → CLIs

Always: Lefthook, Gitleaks, jq (release binaries), Semgrep (`uv tool`), jscpd (`npm -g`).

| Stage | Go (`go install`) | Python (`uv tool`) | JS/TS | PHP (isolated composer) |
|-------|-------------------|--------------------|-------|-------------------------|
| Format | `gofmt` (toolchain) | Ruff (`ruff format`) | Biome (`biome format`) | PHP-CS-Fixer |
| Static analysis | staticcheck | mypy + `ruff check` | Biome (`biome lint`) | PHPStan, Phan ¹ |
| Security | gosec | Bandit | Biome `security` group | — |
| Dead code | `deadcode` (x/tools) + staticcheck `U1000` | Vulture | Knip (`npm -g`) | PHPMD `unusedcode` + PHPStan `*.unused` |
| Cyclomatic complexity | gocyclo | Radon (`radon cc`) | Oxlint `eslint/complexity` ² | PHPMD `CyclomaticComplexity` |
| Cognitive complexity | gocognit | complexipy | Oxlint + `eslint-plugin-sonarjs` (`sonarjs/cognitive-complexity`) ² | PHPStan + `tomasvotruba/cognitive-complexity` |

Cross-language: Gitleaks (secrets), Semgrep (security), jscpd (duplication).

¹ Phan 6 runs on PHP ≥ 8.1; SETUP falls back to Phan 5 on PHP 8.0. Without the `ast` extension, `run.sh` passes `--allow-polyfill-parser`. The analysed PHP version is inferred from `composer.json` (`require.php`).

² Oxlint owns JS/TS complexity and runs **together with Biome**: Biome keeps format, lint and security; Oxlint runs only the two complexity rules (every other category is off in `.oxlintrc.json`). Oxlint and `eslint-plugin-sonarjs` live in one isolated npm project under `QUALITY_GATE_TOOLS_DIR/js/oxlint`; the `oxlint` on PATH is a wrapper that sets `NODE_PATH` so the `sonarjs` JS plugin resolves. An `oxlint` already on PATH is kept and must resolve `eslint-plugin-sonarjs` itself, otherwise the complexity stage reports a `tool-error`.

Signals: `go.mod` / `*.go`; `pyproject.toml` / `uv.lock` / `*.py`; `package.json` / `*.ts|tsx|js|jsx`; `composer.json` / `*.php`. Biome is a standalone binary and Oxlint an isolated npm project (no `devDependency`); ESLint/Prettier are not used.

### Repo files (skipped if present unless `--force`)

| File | Purpose |
|------|---------|
| `lefthook.yml` | Git lifecycle (see below) |
| `scripts/quality/run.sh`, `scripts/quality/aggregate.sh` | The Quality Run and its jq aggregator |
| `quality-baseline.json` | Thresholds, Semgrep rulesets, test commands |
| `.gitleaks.toml` | Shared by pre-commit and the Quality Run |
| `.jscpd.json` | Duplication scope |
| `ruff.toml`, `mypy.ini` | Python (skipped when `pyproject.toml` has `[tool.ruff]` / `[tool.mypy]`) |
| `biome.json` | JS/TS format + lint + security |
| `.oxlintrc.json` | JS/TS cyclomatic + cognitive complexity (skipped when `.oxlintrc.jsonc` / `oxlint.config.ts` exists) |
| `.php-cs-fixer.dist.php`, `phpstan.neon`, `.phan/config.php`, `phpmd.xml` | PHP (PHP paths: `src/`, `app/`, `lib/` when present, else `.`) |
| `.gitignore` | Adds `.quality/` |

`quality-baseline.json` (harness wins — copy thresholds from `docs/harness/*` when they exist):

```json
{
  "cyclomatic_max": 10,
  "cognitive_max": 15,
  "duplication_max_percent": 3,
  "security_fail_severity": "medium",
  "semgrep_configs": ["p/default"],
  "test_commands": {}
}
```

`test_commands` overrides the defaults per stack (`go`, `python`, `js`, `php`), e.g. `{"python": "uv run pytest -q tests/unit"}`. `.oxlintrc.json`, `phpstan.neon` and `phpmd.xml` get the thresholds written in at SETUP; when a threshold changes, update the baseline and re-run SETUP with `--force` (or edit those three files) so tool configs stay in parity.

### Generated `lefthook.yml`

```yaml
pre-commit:           # parallel; each job scoped by glob to {staged_files}
  - gitleaks git --pre-commit --staged --redact --no-banner --config .gitleaks.toml
  - gofmt -w / ruff format / biome format --write / php-cs-fixer fix   (stage_fixed: true)
pre-push:
  - scripts/quality/run.sh --stage all
```

The pre-commit formatters are the only place anything is auto-fixed, and only for human commits after `--git-hooks`. The agent's RUN stays check-only.

## RUN

```bash
.cursor/skills/quality-gate/scripts/check.sh                                  # all stages
.cursor/skills/quality-gate/scripts/check.sh --stage static,deadcode          # only these stages
.cursor/skills/quality-gate/scripts/check.sh --stage all --path src/billing   # scope the report
```

`check.sh` checks that `lefthook`, `jq`, `lefthook.yml` and `scripts/quality/*` exist, runs `lefthook validate` (silent unless it fails), then `scripts/quality/run.sh` with the same arguments. On the console it prints one summary line (`PASS`, or `FAIL — N failure(s)` per stage); tool output never reaches the console. It never runs `lefthook install`, never runs `lefthook run`, and never fixes.

### Quality Run (`scripts/quality/run.sh`)

- Stages, in order: `format` → `static` → `security` → `deadcode` → `complexity` → `duplication` → `tests` (`all` = every stage).
- Every tool writes its machine output to `.quality/<tool>.sarif` (or `.json` / `.jsonl`; tools with text output are normalized to `.quality/<tool>.norm.jsonl`). Logs go to `.quality/<tool>.log`. `.quality/` is wiped at the start of every run.
- `--path` filters the report; the tools still scan the repository.
- A CLI missing from PATH is a `tool-missing` failure; a tool that exits non-zero without a usable report is a `tool-error` failure. The gate never passes silently.

### Report (`.quality/report.json`)

`aggregate.sh` merges every report with jq and keeps **failures only** (SARIF `error`/`warning`, results above threshold, failed tests):

```json
{
  "stages": ["static", "deadcode"],
  "scope": ["src/billing"],
  "count": 2,
  "by_stage": { "static": 1, "deadcode": 1 },
  "failures": [
    { "tool": "mypy", "stage": "static", "rule": "return-value", "severity": "error",
      "file": "src/billing/invoice.py", "line": 42, "message": "Incompatible return value type ..." }
  ]
}
```

Exit code 0 only when `count` is 0. `report.json` is the only file to read: successful checks, info notes and tool logs never enter it. Open a tool's raw report or `.log` only when one failure needs more context than its `message`.

Pass rules: any Gitleaks finding fails; Semgrep/gosec/Bandit/Biome security findings of severity medium or higher fail; complexity above `cyclomatic_max` / `cognitive_max` per function fails; total duplication above `duplication_max_percent` fails (every clone is then listed).

## Do not

- Do not silence findings (inline disables, ignore files, baselines, raised thresholds) without the user's approval.
- Do not edit `scripts/quality/*` to skip a stage or a tool; fix the code or ask the user.
- No extra Cursor/Claude hook and no extra Lefthook skill.
