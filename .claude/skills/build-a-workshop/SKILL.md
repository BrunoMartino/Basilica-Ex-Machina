---
name: build-a-workshop
description: >-
  Installs a workshop — a Herdr desktop app layout with its mod and theme — on
  this machine by cloning the workshop repo and running its installer into the
  Herdr app home. Registry of workshops; L'Officina (officina-mod) is the only
  entry today. Use when the user invokes build-a-workshop or asks to install
  officina-mod / L'Officina / a workshop layout in Herdr.
disable-model-invocation: true
---

# Build a workshop

Invoking this skill **installs a workshop into the Herdr app** (`herdr-app`): a layout, its mod and its theme. Each agent (Pittore, Scultore, Ingegnere, Inventore, or any other) shows up as a master at a bench; sub-agents show up as garzoni.

Machine-level install. Nothing is written to the current project. Never write `.env`.

## Workshop registry

| id | name | repo | layout | min Herdr app |
|----|------|------|--------|---------------|
| `officina` | L'Officina | `https://github.com/BrunoMartino/officina-mod.git` | `officina` | `0.1.16` |

Adding a workshop later = one row. Do not invent workshops. Do not fetch a repo absent from this table.

## Resolve workshop

1. User named an id or name in the prompt → that row.
2. Registry has **exactly one** row → use it (no question).
3. Registry has **two or more** and the user did not name one → **one** AskQuestion listing id + name.

## Flow

```
1. Resolve workshop
2. Preflight
3. Shallow-clone the repo into a temporary directory
4. sh scripts/install.sh
5. herdr-app check <herdr home>/mods/<layout>
6. One AskQuestion: connect the hook bridge? (multi-select: claude, codex, cursor, none)
7. If any agent was picked: node scripts/install-hooks.mjs <picked agents>
8. herdr-app do layout.switch --name <layout>
9. One-line summary: workshop id, repo, Herdr home, bridge agents connected
```

### 2. Preflight

- Herdr home = `$HERDR_APP_HOME`, else `~/.config/herdr-app`. Missing → stop and report; do not create it.
- `herdr-app --version` must be at or above the row's min version. Missing or older → stop and report; do not install or upgrade Herdr.
- `node` is required only for step 7. Missing → skip step 6 and 7 and say so.

### 4. Install

Run the repo's own `scripts/install.sh` from the clone. It copies only these into the Herdr home and keeps an existing `mods/<layout>/roles.json`:

- `layouts/<layout>.json` (+ `<layout>.png`)
- `mods/<layout>/`
- `themes/<layout>.json`

Do not copy files by hand and do not edit other files in the Herdr home.

### 5. Check

`herdr-app check` must pass. If it fails, stop, show the failure, and do not run steps 6–8.

### 6–7. Hook bridge

The bridge tells the workshop which tool each agent is using and which sub-agents are alive. `install-hooks.mjs` edits **one file per agent**, keeps a dated copy beside it, and touches only its own entries:

| Agent | File | After connecting |
|-------|------|------------------|
| Claude Code | `~/.claude/settings.json` | nothing — applies to new sessions |
| Codex | `~/.codex/hooks.json` | user opens Codex, runs `/hooks`, and trusts the entries |
| Cursor | `~/.cursor/hooks.json` | nothing — applies to new sessions |

These are user-level config files: never run step 7 without the answer from step 6. Offer only the agents whose config folder exists. Never edit those files by hand; use the script. Relay the Codex `/hooks` step to the user when Codex was picked.

### 8. Switch

`herdr-app do layout.switch --name <layout>`. The previous layout stays installed; `ctrl-shift-l` toggles between them.

## Remove

Only when the user asks:

```
1. node scripts/install-hooks.mjs --remove   (from a fresh clone)
2. Delete from the Herdr home: layouts/<layout>.json, layouts/<layout>.png, mods/<layout>/, themes/<layout>.json
```

Confirm with one AskQuestion before deleting.

## Guardrails

- Explicit user invoke only (`disable-model-invocation`).
- Full workshop install through the repo's scripts — not a pick-list of files.
- The clone lives in a temporary directory; never clone into the current project.
- Do not rebuild the art (`tools/art/`) or edit `roles.json` unless the user asks.
