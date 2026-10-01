---
name: statera-quaderno
description: >-
  Installs the Statera-Quaderno WordPress + WooCommerce MCP locally from
  github.com/BrunoMartino/Statera-Quaderno-MCP: clones, tests and builds the Go
  binary, prepares one .env per store, registers one server per store in the
  project .mcp.json for Claude Code, then prints the .env variables the user
  must fill. Use when the user asks to install or configure Statera-Quaderno,
  statera-quaderno-mcp, or the WordPress/WooCommerce content MCP.
disable-model-invocation: true
---

# Statera-Quaderno MCP

Installs [Statera-Quaderno-MCP](https://github.com/BrunoMartino/Statera-Quaderno-MCP) locally and wires it as a Claude Code MCP. One process = one `.env` = one store (`WP_BASE_URL`). **Does not** write store secrets anywhere: the clone's `.env` is created from `.env.example` and filled by the user. Never edit the **project** `.env` (rule `dont-write-env`).

Upstream `README.md` / `README-eng.md` is the source of truth if steps diverge: follow it.

## Step 1 — Clone location

Ask once if unclear. Prefer a tools dir outside app source, e.g. `~/.local/share/mcp/Statera-Quaderno-MCP`.

```bash
git clone https://github.com/BrunoMartino/Statera-Quaderno-MCP.git
cd Statera-Quaderno-MCP
```

On 404/auth failure: ask for access or the corrected URL. **Do not** substitute another WordPress/WooCommerce MCP (including WooCommerce's native `/woocommerce/mcp`) without explicit approval.

## Step 2 — Prerequisites

- Go at the version in `go.mod` (`go version`). If missing or older, tell the user to install it and stop.
- Store on **HTTPS** (Application Passwords do not appear without it).
- A dedicated WordPress user (e.g. `mcp-content`), **not** an administrator, with an Application Password. Minimum capabilities are listed in the upstream README ("Requirements").

## Step 3 — Locate the entrypoint

The README and `statera-quaderno-mcp.sh` may name different `cmd/` paths. Resolve the real one:

```bash
go list -f '{{if eq .Name "main"}}{{.ImportPath}} {{.Dir}}{{end}}' ./...
```

- One result → use it as `<MAIN_PKG>` (e.g. `./cmd/woocommerce-store-mcp`).
- No result → the `main` package is not in the repo (e.g. excluded by `.gitignore`). **Stop** and report it to the user; do not write a `main.go` yourself.

## Step 4 — Test and build

```bash
go test ./...
CGO_ENABLED=0 go build -o bin/statera-quaderno-mcp <MAIN_PKG>
```

If tests fail, report the output and ask before continuing. Resolve **absolute** paths for the binary and the clone.

## Step 5 — Stores and env files (MCP clone only)

Ask in a single AskQuestion (non-secret answers only):

1. **Stores** to register — one MCP server per store, e.g. `loja-staging`, `loja-production`.
2. **Environment** of each store: `local` | `staging` | `production`.
3. **Logs/diagnostics**: will the store install the `store-plugin/` mu-plugin (`get_debug_mode`, `collect_logs`)?

Never ask for passwords, Application Passwords, consumer keys or observability secrets in chat.

Per store, create its env file from the template in the clone:

```bash
cp .env.example .env.<store>   # single store: .env
```

Do **not** fill secret values. Only the user edits these files.

## Step 6 — Register Claude Code MCP

Create or merge into **project root** `.mcp.json` (do not clobber other servers). One entry per store; secrets stay in the clone env file referenced by `DOTENV_PATH`, never inlined here.

```json
{
  "mcpServers": {
    "statera-quaderno": {
      "command": "/ABS/PATH/Statera-Quaderno-MCP/bin/statera-quaderno-mcp",
      "env": {
        "DOTENV_PATH": "/ABS/PATH/Statera-Quaderno-MCP/.env"
      }
    }
  }
}
```

With several stores, name each server `statera-quaderno-<store>` and point `DOTENV_PATH` to `.env.<store>`. Replace `/ABS/PATH` with the real clone path.

Ask the user to restart the Claude Code session (or run `claude mcp list` to confirm). Startup refuses with `AUTH_MISSING` until the env file is filled.

## Step 7 — Final chat output (mandatory)

End the turn with this block (adapt paths and stores). Never print real values.

```markdown
## Statera-Quaderno ready

- Clone: `<ABS>/Statera-Quaderno-MCP`
- Binary: `<ABS>/Statera-Quaderno-MCP/bin/statera-quaderno-mcp`
- MCP servers: `<names>` (in project `.mcp.json`)
- Fill the env file(s) below, restart Claude Code / `claude mcp list`, then try `list_posts`.

### Fill `<ABS>/Statera-Quaderno-MCP/.env[.<store>]`

**Required**

| Variable | What to set |
|----------|-------------|
| `WP_BASE_URL` | HTTPS origin of the store, no trailing slash |
| `WP_APP_USER` | Login of the dedicated user (e.g. `mcp-content`) |
| `WP_APP_PASSWORD` | Application Password (Users → that user → Application Passwords; shown once) — never the login password |
| `WP_STORE_ID` | Store slug (used in logs) |
| `WP_ENVIRONMENT` | `local` \| `staging` \| `production` |

**Optional**

| Variable | Default / notes |
|----------|-----------------|
| `WP_MCP_ALLOWED_STATUSES` | `draft,publish,pending` |
| `WP_MCP_USER_LOGIN` | defaults to `WP_APP_USER` |
| `WC_CONSUMER_KEY` / `WC_CONSUMER_SECRET` | only if there is **no** `WP_APP_PASSWORD` (ignored otherwise) |
| `WP_MCP_OBSERVABILITY_SECRET` | same value as the WordPress service env var; required for `get_debug_mode` / `collect_logs` |

### Logs (only if the store uses `store-plugin/`)

Follow `<ABS>/Statera-Quaderno-MCP/store-plugin/README.md` on the store host: copy the mu-plugin, generate the secret (`openssl rand -hex 32`), set `WP_MCP_OBSERVABILITY_SECRET`, `WP_MCP_OBSERVABILITY_USER` and `WORDPRESS_CONFIG_EXTRA` on the WordPress service, then confirm with `get_debug_mode`.
```

## Guards

- Closed tool set: do not invent tools. No price, stock, SKU, orders writes, customers, users, settings, plugins, themes, SQL, WP-CLI or PHP.
- Coupons with percent > 20 require human confirmation (AskQuestion) before saving.
- New posts/pages default to `draft`; do not publish generated content without the user's confirmation.
- Turning debug on/off belongs to the host (`WORDPRESS_DEBUG`), not to this MCP.
- Never suggest admin consumer keys, never read or print any `.env`, never paste log lines with personal data in chat.
