---
name: get-my-tools
description: >-
  Inventories BrunoMartino/personal_harness_eng on GitHub and installs selected
  skills, rules, and harness docs into the current project. Use when the user
  asks to bring/install harness tools, bootstrap Cursor config in a dev
  container, or names specific skills/rules/docs to copy from personal_harness_eng.
disable-model-invocation: true
---

# Get my tools (harness kit installer)

## When to use

- Apply **only when the user explicitly invokes this skill**, unless the same message says otherwise.
- Use when the user wants to **install or bring** skills, rules, or docs from [personal_harness_eng](https://github.com/BrunoMartino/personal_harness_eng) into the **current project**.
- Use in **dev containers** or environments without access to a local clone or WSL terminal.
- Use when the user names specific items to install (e.g. `tester`, `all-for-harness`, `all rules`) — in that case **skip listing** and install directly.

**Out of scope**: editing harness docs in place, generating project-specific content, or installing into `~/.cursor/skills-cursor/` (Cursor internal).

Follow always-apply project rules (including harness gates under `.cursor/rules/`).

## Execution order (mandatory)

```
1. Parse intent (explicit items vs catalog needed)
2. Inventory remote repo (read-only)
3. Present catalog OR resolve named items
4. STOP → ask permission before overwrite
5. Install selected files into the workspace
6. Report summary
```

Examples: [examples.md](examples.md).

## Step 1 — Parse intent

Determine whether the user already named what to install.

**Skip listing** when the message includes concrete targets, for example:

- Skill names: `tester`, `code-commenter`, `get-that-task`
- Rule stems: `all-for-harness`, `less-talk`, `dont-write-env`
- Doc paths or bundles: `harness templates`, `all rules`, `docs/testsReadme.md`

**Show catalog first** when the user invokes the skill without naming items (e.g. "get my tools", "what can I install from personal_harness_eng?").

Accept aliases: folder names, rule filenames without extension, and bundle keywords (`all skills`, `all rules`, `harness templates`, `full kit`).

## Step 2 — Inventory source repo (read-only)

Source repository:

- **GitHub**: `https://github.com/BrunoMartino/personal_harness_eng`
- **Branch**: `main`

Try these methods **in order** (stop at first that works):

1. **`gh api`** — list contents under each catalog path (see table below).
2. **Raw GitHub** — `https://raw.githubusercontent.com/BrunoMartino/personal_harness_eng/main/<path>`
3. **Sparse clone to `/tmp`** — only if API/raw fail **and** the user approves network + git.

Do **not** write files during inventory.

### Catalog

| Category | Remote path | Local destination |
|----------|-------------|-------------------|
| Skills | `.cursor/skills/<name>/` | `.cursor/skills/<name>/` |
| Rules | `.cursor/rules/*.mdc` | `.cursor/rules/` |
| Harness templates | `docs/harness/*_template.md` | `docs/harness/` |
| Test catalog | `docs/testsReadme.md` | `docs/` |

For each skill folder, read `SKILL.md` frontmatter and include the `description` in the catalog when available.

If inventory finds `.cursor/hooks/` or other dev-toolkit paths, list them under an **Other** category. Do **not** list `drafts/` or repo-only content unrelated to the kit.

## Step 3 — Present catalog or resolve selection

### If listing (user did not name items)

Present a **categorized** markdown list:

1. **Skills** — name + one-line description
2. **Rules** — filename
3. **Harness templates** — filename
4. **Other** — e.g. `docs/testsReadme.md`, hooks if present

Ask which items to install. Support multi-select and bundles.

### If user named items

Map names to remote paths, confirm the resolved set in **one short line**, then proceed to Step 4. Do **not** dump the full catalog.

## Step 4 — Permission gate (before any write)

Check whether any target path **already exists** in the workspace.

**Stop and ask** before writing when conflicts exist. Offer:

- **Skip existing** — install only missing items
- **Overwrite selected** — replace chosen paths
- **Abort** — no changes

If all targets are new, proceed without a separate prompt unless the user asked to confirm first.

While waiting for approval: do **not** create or overwrite files.

If the user **declines**: stop; report what would have been installed and the remote paths for manual copy.

## Step 5 — Install

Copy from the remote repo into the **current project** (default). Use personal paths (`~/.cursor/skills/`) **only** if the user explicitly asks.

Rules:

- Preserve directory structure and relative paths.
- For skills, copy the **entire folder** (`SKILL.md`, `examples.md`, and any sibling files).
- Create parent directories as needed.
- Do **not** copy `drafts/` or unrelated repo root files.
- **Never** create, edit, or overwrite `.env`. If a copied skill documents env vars, update `.env.example` only when the user asks.

### Fetch patterns

**Single file (raw):**

```bash
curl -fsSL "https://raw.githubusercontent.com/BrunoMartino/personal_harness_eng/main/.cursor/rules/all-for-harness.mdc" \
  -o ".cursor/rules/all-for-harness.mdc"
```

**Skill folder (gh api + raw, or sparse clone):**

```bash
mkdir -p ".cursor/skills/tester"
curl -fsSL "https://raw.githubusercontent.com/BrunoMartino/personal_harness_eng/main/.cursor/skills/tester/SKILL.md" \
  -o ".cursor/skills/tester/SKILL.md"
# repeat for examples.md and other files in the folder
```

Prefer `gh api repos/BrunoMartino/personal_harness_eng/contents/.cursor/skills` to discover skill folder contents before fetching each file.

## Step 6 — Output contract

End with a **short summary**:

- **Installed**: item names and local paths
- **Skipped**: already present (if user chose skip)
- **Overwritten**: paths replaced (if any)
- **Failed**: paths that could not be fetched, with error hint
- **Next step** (one line, optional): e.g. materialize harness templates or invoke `legacy-explainer`

Examples: [examples.md](examples.md).

## Guardrails

- **Never** install into `~/.cursor/skills-cursor/`.
- **Never** edit `.env`; only `.env.example` when explicitly requested.
- Default destination is **project** `.cursor/` and `docs/`, not personal skills, unless the user says otherwise.
- If GitHub is unreachable or auth fails, report in **one sentence** and stop.
- Do **not** invent catalog entries — only install paths confirmed by inventory.
