---
name: build-a-castle
description: >-
  Installs the Ingeniarius-Castellorum Coolify v4 MCP locally from
  github.com/BrunoMartino/Ingeniarius-Castellorum: clones, builds coolify-mcp,
  registers it in project .mcp.json for Claude Code, then prints the .env
  variables the user must fill to operate Coolify. Use when the user asks to
  install Coolify MCP, build-a-castle, Ingeniarius-Castellorum, or coolify-mcp.
disable-model-invocation: true
---

# Build a Castle

Installs [Ingeniarius-Castellorum](https://github.com/BrunoMartino/Ingeniarius-Castellorum) locally and wires it as a Claude Code MCP. **Does not** write Coolify secrets into any project `.env` — only into the MCP clone’s own `.env` as an empty template from `.env.example`. Secrets are filled by the user.

Upstream README is source of truth if steps diverge: follow it.

## Step 1 — Clone location

Ask once if unclear. Prefer a tools dir outside app source, e.g. `~/.local/share/mcp/Ingeniarius-Castellorum`.

```bash
git clone https://github.com/BrunoMartino/Ingeniarius-Castellorum.git
cd Ingeniarius-Castellorum
```

On 404/auth failure: ask for access or corrected URL. **Do not** substitute another Coolify MCP without explicit approval.

## Step 2 — Prerequisites

- Go **1.22+** (`go version`). If missing, tell the user to install Go and stop.
- Writable audit path (default `~/.coolify-mcp/`); create dir if needed.

## Step 3 — Env template (MCP clone only)

```bash
cp .env.example .env
```

Do **not** invent `COOLIFY_API_TOKEN` or other secrets. Do **not** edit the **project** `.env` (toolkit rule `dont-write-env`). Only the clone’s `.env` / `.env.example`.

## Step 4 — Build

```bash
CGO_ENABLED=0 go build -o bin/coolify-mcp ./cmd/coolify-mcp
```

Alternative entrypoint: `ingeniarius-castellorum.sh` in the clone root (builds on first run). Prefer the binary path once built.

Resolve **absolute** paths for binary and `.env`.

## Step 5 — Register Claude Code MCP

Create or merge into **project root** `.mcp.json` (do not clobber other servers). Ensure `.mcp.json` is gitignored if it will ever hold secrets; with `DOTENV_PATH` only, secrets stay in the clone `.env`.

```json
{
  "mcpServers": {
    "ingeniarius-castellorum": {
      "command": "/ABS/PATH/Ingeniarius-Castellorum/bin/coolify-mcp",
      "env": {
        "DOTENV_PATH": "/ABS/PATH/Ingeniarius-Castellorum/.env"
      }
    }
  }
}
```

Replace `/ABS/PATH` with the real clone path.

Ask the user to restart the Claude Code session (or run `claude mcp list` to confirm).

## Step 6 — Final chat output (mandatory)

End the turn with this block (adapt paths to the install). List what the user must put in the **MCP clone** `.env` — never print real token values.

```markdown
## Castle ready

- Clone: `<ABS>/Ingeniarius-Castellorum`
- Binary: `<ABS>/Ingeniarius-Castellorum/bin/coolify-mcp`
- MCP name: `ingeniarius-castellorum` (in project `.mcp.json`)
- Restart Claude Code / `claude mcp list`, then try `coolify_get_infrastructure_overview`.

### Fill `<ABS>/Ingeniarius-Castellorum/.env`

**Required**

| Variable | What to set |
|----------|-------------|
| `COOLIFY_URL` | Base URL of your Coolify instance (e.g. `https://coolify.example.com`) |
| `COOLIFY_API_TOKEN` | API token with scopes `read`, `read:sensitive`, `write`, `deploy` — **never** `root`. TTL **7 days**. Create under Coolify → Security → API Tokens. |
| `COOLIFY_USER` | Logical identity for the audit log (e.g. your name/handle) |

**Optional**

| Variable | Default / notes |
|----------|-----------------|
| `COOLIFY_MCP_TRANSPORT` | `stdio` (default) or `http` |
| `COOLIFY_MCP_HTTP_ADDR` | e.g. `:8788` (http only) |
| `COOLIFY_MCP_HTTP_TOKEN` | Bearer for http clients (required if transport=http) |
| `COOLIFY_MCP_STRICT_ONAIR` | `true` (default) — unknown status blocks config mutations |
| `COOLIFY_MCP_ALLOW_CLI` | `true` (default) — enables `run_cli` group |
| `COOLIFY_MCP_ALLOW_PRIVATE_KEYS` | `false` (reserved) |
| `COOLIFY_MCP_AUDIT_PATH` | `~/.coolify-mcp/audit.jsonl` |
| `COOLIFY_MCP_TIMEOUT` | `30s` |

If the MCP fails with auth/API errors: mint a new 7-day token, update `COOLIFY_API_TOKEN`, reload MCP.
```

## Guards

- No DELETE tools exist upstream — do not invent them.
- Running resources: config mutations denied (`DENIED_ONAIR`); ask the human to stop — do not stop for them.
- Never print `COOLIFY_API_TOKEN` or HTTP bearer values in chat.
