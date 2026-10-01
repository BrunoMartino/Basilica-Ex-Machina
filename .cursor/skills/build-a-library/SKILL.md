---
name: build-a-library
description: >-
  Installs the Michelangelo-Dev-Inks docs MCP locally from
  github.com/BrunoMartino/Michelangelo-Dev-Inks: clones, builds the Go
  server, registers it as `docs-mcp` in ~/.cursor/mcp.json, and
  smoke-checks it. Use when the user asks to install the library, docs-mcp,
  Michelangelo-Dev-Inks, or the local docs RAG MCP.
disable-model-invocation: true
---

# Library

Installs [Michelangelo-Dev-Inks](https://github.com/BrunoMartino/Michelangelo-Dev-Inks) locally and wires it as the Cursor MCP **`docs-mcp`** — the name every skill and agent of this toolkit uses to query documentation (e.g. `design-patterns-coder` → `search_docs` with `source_id: gof-design-patterns`).

The server is a stdio MCP that indexes cleaned text in SQLite (FTS5). It does **not** crawl or fetch URLs. No secrets involved.

Upstream README is source of truth if steps diverge: follow it.

## Step 1 — Clone location

Ask once if unclear. Prefer a tools dir outside app source, e.g. `~/.local/share/mcp/Michelangelo-Dev-Inks`. If the clone already exists, `git pull` instead of cloning.

```bash
git clone https://github.com/BrunoMartino/Michelangelo-Dev-Inks.git
cd Michelangelo-Dev-Inks
```

On 404/auth failure: ask for access or corrected URL. **Do not** substitute another docs MCP without explicit approval.

## Step 2 — Prerequisites

- Go **1.22+** (`go version`). If missing, tell the user to install Go and stop.

## Step 3 — Build

```bash
cd server
go mod tidy
go build -o docs-mcp ./cmd/docs-mcp
```

Resolve the **absolute** path of `server/docs-mcp`.

## Step 4 — Database path

Default: `~/.local/share/docs-mcp/docs.db` (created on first run). Keep the default unless the user names another path; create the parent dir if needed. Never delete an existing DB — it holds the indexed library.

## Step 5 — Smoke check

```bash
go test ./internal/store/ -run TestUpsertSearchGetDelete -v
```

If it fails: stop, report the output — do not register a broken server.

## Step 6 — Register Cursor MCP as `docs-mcp`

Merge into **user** config `~/.cursor/mcp.json` (do not clobber other servers). If a `docs-mcp` entry already exists, show it and ask before replacing.

```json
{
  "mcpServers": {
    "docs-mcp": {
      "command": "/ABS/PATH/Michelangelo-Dev-Inks/server/docs-mcp",
      "env": {
        "DOCS_DB_PATH": "/ABS/HOME/.local/share/docs-mcp/docs.db"
      }
    }
  }
}
```

Replace `/ABS/PATH` and `/ABS/HOME` with real absolute paths (no `~`).

Ask the user to reload MCP servers in Cursor.

## Step 7 — Final chat output (mandatory)

```markdown
## Library ready

- Clone: `<ABS>/Michelangelo-Dev-Inks`
- Binary: `<ABS>/Michelangelo-Dev-Inks/server/docs-mcp`
- DB: `<DOCS_DB_PATH>`
- MCP name: `docs-mcp` (in `~/.cursor/mcp.json`)
- Reload MCPs in Cursor, then try `list_sources`.
```

## How models use `docs-mcp`

| Tool | Use |
|------|-----|
| `list_sources` | See which libraries are indexed |
| `search_docs` | FTS query → snippets + `chunk_id`s (filter by `source_id` / `tags`; `limit` ≤ 10) |
| `get_chunk` | Read one chunk (optional neighbors) |
| `upsert_doc` | Index cleaned text you extracted (`source_id`, `title`, `content`, `doc_path`) |
| `ingest_path` | Index local `.md` / `.txt` / `.html` files |
| `delete_source` | Remove a source — only on explicit user request |

Lean path: `search_docs` → `get_chunk` on the best hits only. Never dump whole sources into context.

## Guards

- Never delete the DB or call `delete_source` without an explicit user request.
- Do not add URL-fetching to the server; extraction happens outside it.
