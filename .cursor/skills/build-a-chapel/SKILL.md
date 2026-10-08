---
name: build-a-chapel
description: >-
  Switches the current project from Basilica's generalist kit to a chapel's
  files and working mode by copying that chapel's .claude/ and .cursor/ trees.
  Registry of chapels; Caporalli is the only entry today. Use when the user
  invokes build-a-chapel or asks to install Caporalli-Chapel / a Buskar chapel.
disable-model-invocation: true
---

# Build a chapel

Invoking this skill **replaces Basilica's generalist pattern** in the current project with the chapel's agents, skills, rules, and Stage 1 ritual.

Not a catalog installer. No subset picker. Never write `.env`.

## Chapel registry

| id | name | repo | retire stems |
|----|------|------|----------------|
| `caporalli` | Caporalli-Chapel | `https://github.com/buskar-solucoes/Caporalli-Chapel.git` | `all-for-harness`, `babylon-gate`, `babylon-gardens`, `harness-create`, `dont-write-env`, `api-pydantic-schemas`, `nest-conventions`, `python-uv-package-manager`, `enforces-english` |

Adding a chapel later = one row. Do not invent chapels. Do not fetch a repo absent from this table.

## Resolve chapel

1. User named an id or name in the prompt → that row.
2. Registry has **exactly one** row → use it (no question).
3. Registry has **two or more** and the user did not name one → **one** AskQuestion listing id + name.

## Flow

```
1. Resolve chapel
2. Optional: one AskQuestion to confirm overwrite of project .claude/ and .cursor/
3. Fetch that repo's .claude/ and .cursor/ (gh / sparse clone / raw)
4. Copy into the current project (overwrite matching paths)
5. Delete retire stems under .claude/ and .cursor/ (skills folders and rules files) if still present
6. One-line summary: chapel id, repo, trees copied, files retired
```

Default destination: project `.claude/` + `.cursor/`. Never `~/.cursor/skills-cursor/`.

## Guardrails

- Explicit user invoke only (`disable-model-invocation`).
- Full chapel install — not a pick-list of skills.
- Retire list is per-row; Caporalli must not leave both `all-for-harness` and `all-for-specs` active.
