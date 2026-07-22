---
name: create-minio-docker
description: Generates a MinIO installation (Dockerfile + docker-compose.yml) and an install.md with step-by-step Coolify deployment instructions, including access methods (API/Console), bucket creation via mc or Console, and the credentials/env vars applications need. Use when the user asks to install MinIO, set up S3-compatible object storage in Docker, or deploy MinIO on Coolify.
disable-model-invocation: true
---

# Create MinIO Docker

Gera uma instalação MinIO single-node (Dockerfile + docker-compose) pronta para deploy no Coolify, com `install.md` documentando deploy, acesso, criação de buckets e credenciais.

## Informações a recolher antes de gerar

Pergunte ao usuário (ou infira do contexto) apenas o que faltar:

1. **Diretório de destino** — default: `minio/` na raiz do projeto.
2. **Domínios no Coolify** — um para a API S3 (porta 9000, ex.: `s3.example.com`) e um para a Console (porta 9001, ex.: `minio.example.com`).
3. **Buckets iniciais** — nomes e se algum precisa de acesso anônimo de download (assets públicos).

## Ficheiros a gerar

Use os templates de [templates.md](templates.md) **verbatim**, substituindo apenas os placeholders `<...>`:

| Ficheiro | Conteúdo |
|----------|----------|
| `<destino>/Dockerfile` | Imagem `quay.io/minio/minio` com `server /data --console-address ":9001"` |
| `<destino>/docker-compose.yml` | Serviço `minio` + serviço one-shot `createbuckets` (mc) que cria os buckets no primeiro deploy |
| `<destino>/install.md` | Passo a passo de deploy no Coolify, acesso, buckets e credenciais |
| `.env.example` (raiz) | Placeholders das variáveis (ver secção Credenciais) |

## Regras de credenciais (obrigatório)

- **Nunca** escrever valores reais de `MINIO_ROOT_USER` / `MINIO_ROOT_PASSWORD` em ficheiros versionados nem no `.env`. Apenas placeholders no `.env.example`; valores reais vão nas Environment Variables do Coolify.
- No `install.md`, instruir o usuário a gerar senha forte (`openssl rand -hex 16`) e a criar uma **access key dedicada** (Console → Access Keys, ou `mc admin accesskey`) para as aplicações — as apps **não** usam as credenciais root.
- Variáveis que as aplicações consomem (documentar no `.env.example` do projeto consumidor):

```bash
S3_ENDPOINT=https://s3.example.com
S3_ACCESS_KEY=changeme
S3_SECRET_KEY=changeme
S3_BUCKET=mybucket
S3_REGION=us-east-1
S3_FORCE_PATH_STYLE=true
```

## Pontos específicos do Coolify (refletir no compose e no install.md)

- Coolify usa Traefik como proxy: **não** publicar portas com `ports:`; declarar apenas `expose: [9000, 9001]` e mapear os dois domínios na UI do Coolify (domínio API → porta 9000, domínio Console → porta 9001).
- Definir `MINIO_SERVER_URL=https://<dominio-api>` e `MINIO_BROWSER_REDIRECT_URL=https://<dominio-console>` — sem isso a Console e URLs pré-assinadas quebram atrás do proxy.
- Volume nomeado para `/data` (Coolify persiste volumes nomeados entre deploys).
- Healthcheck: `mc ready local` (disponível na imagem) ou `curl -f http://localhost:9000/minio/health/live`.

## Estrutura do install.md

Seguir o template em [templates.md](templates.md). Secções obrigatórias:

1. **Pré-requisitos** — Coolify instalado, domínios com DNS apontado.
2. **Deploy no Coolify** — criar resource Docker Compose, apontar para o repo/diretório, definir env vars, mapear domínios, deploy.
3. **Formas de acesso** — Console web (login root), API S3 (endpoint + SDK/mc), exemplo de `mc alias set`.
4. **Criação de buckets** — via serviço `createbuckets` do compose (automático), via Console e via `mc mb`; política anônima com `mc anonymous set download` quando aplicável.
5. **Credenciais para ambientes** — criação de access key dedicada e bloco de variáveis para o `.env.example` das aplicações.

## Verificação final

- `docker compose config` valida sem erros.
- Nenhum segredo real em ficheiro versionado.
- `install.md` referencia os mesmos nomes de serviço, volume e variáveis usados no compose.
