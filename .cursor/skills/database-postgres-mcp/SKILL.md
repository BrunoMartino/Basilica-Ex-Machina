---
name: database-postgres-mcp
description: >-
  Installs the MCP-explorer-for-Postgress MCP server from
  github.com/BrunoMartino/MCP-explorer-for-Postgress: reads the repository,
  follows its install instructions, asks the user for the database connection
  string and exposed query port, and registers the server in .cursor/mcp.json.
  Use when the user asks to install or configure the Postgres explorer MCP.
disable-model-invocation: true
---

# Database Postgres MCP

Installs and configures the Postgres explorer MCP server for the current project.

## Step 1 — Get the repository

```bash
git clone https://github.com/BrunoMartino/MCP-explorer-for-Postgress.git
```

Clone into a tools location outside the project source (e.g. `~/.local/share/mcp/` or a directory the user prefers — ask if unclear).

If the clone fails (404/auth): the repo may be private. Ask the user for access (SSH remote, token) or the corrected URL. **Do not substitute a different Postgres MCP without explicit approval.**

## Step 2 — Read before installing

Read the repo's `README.md` (and any `INSTALL`/`docs/`) and follow **its** instructions — they are the source of truth for runtime (Node/Python), dependency install command, entrypoint, and required environment variables. Typical patterns:

- Node: `npm install` (run [`dependency-guardsman`](../dependency-guardsman/SKILL.md) checks on new lockfiles) and an entry like `node dist/index.js` or `npx`.
- Python: `uv sync` / `pip install -e .` and a module entrypoint.

Identify from the README: the exact env var names for the connection string and the port exposed for queries.

## Step 3 — Ask the user

Single AskQuestion / prompt covering:

1. **Connection string** — `postgresql://user:password@host:5432/dbname` (or its parts).
2. **Exposed port** for querying, if the server binds one beyond stdio.
3. Read-only credentials available? Recommend a read-only role for exploration MCPs.

## Step 4 — Register in `.cursor/mcp.json`

Create or merge (do not clobber existing servers):

```json
{
  "mcpServers": {
    "postgres-explorer": {
      "command": "<entrypoint from README>",
      "args": ["<args from README>"],
      "env": {
        "<CONNECTION_STRING_VAR>": "<value provided by user>",
        "<PORT_VAR>": "<port provided by user>"
      }
    }
  }
}
```

The connection string is a **secret**: warn the user that `.cursor/mcp.json` will contain it and must stay out of version control (check `.gitignore`), or use the env-reference form supported by Cursor if they prefer. Never write it to `.env` (only `.env.example` placeholders, per project rules).

## Step 5 — Verify & report

Ask the user to reload MCP servers in Cursor, then call a cheap tool (e.g. list tables/schemas) to confirm connectivity. Report: repo location, install steps executed, server name registered, env vars set (names only, never the values), verification result.
