# Templates — create-minio-docker

Substituir apenas os placeholders `<...>`. Manter o resto verbatim.

## Dockerfile

```dockerfile
FROM quay.io/minio/minio:latest

VOLUME ["/data"]
EXPOSE 9000 9001

CMD ["server", "/data", "--console-address", ":9001"]
```

## docker-compose.yml

```yaml
services:
  minio:
    build: .
    restart: unless-stopped
    expose:
      - "9000"
      - "9001"
    environment:
      MINIO_ROOT_USER: ${MINIO_ROOT_USER}
      MINIO_ROOT_PASSWORD: ${MINIO_ROOT_PASSWORD}
      MINIO_SERVER_URL: https://<dominio-api>
      MINIO_BROWSER_REDIRECT_URL: https://<dominio-console>
    volumes:
      - minio-data:/data
    healthcheck:
      test: ["CMD", "mc", "ready", "local"]
      interval: 10s
      timeout: 5s
      retries: 5

  createbuckets:
    image: quay.io/minio/mc:latest
    depends_on:
      minio:
        condition: service_healthy
    restart: "no"
    entrypoint: >
      /bin/sh -c "
      mc alias set local http://minio:9000 $${MINIO_ROOT_USER} $${MINIO_ROOT_PASSWORD} &&
      mc mb --ignore-existing local/<bucket-1> &&
      exit 0
      "
    environment:
      MINIO_ROOT_USER: ${MINIO_ROOT_USER}
      MINIO_ROOT_PASSWORD: ${MINIO_ROOT_PASSWORD}

volumes:
  minio-data:
```

Notas para o agente:

- Um `mc mb --ignore-existing local/<bucket>` por bucket pedido.
- Bucket público de download: acrescentar `mc anonymous set download local/<bucket>` após o `mc mb`.
- Se o usuário não quiser Dockerfile próprio, trocar `build: .` por `image: quay.io/minio/minio:latest` e acrescentar `command: server /data --console-address ":9001"`.

## .env.example (acréscimo)

```bash
# MinIO (valores reais só nas Environment Variables do Coolify)
MINIO_ROOT_USER=changeme
MINIO_ROOT_PASSWORD=changeme
```

## install.md

```markdown
# MinIO — Deploy no Coolify

## 1. Pré-requisitos

- Coolify instalado e acessível.
- DNS apontado para o servidor do Coolify:
  - `<dominio-api>` → API S3
  - `<dominio-console>` → Console web

## 2. Deploy no Coolify

1. **Projects → Add Resource → Docker Compose** e aponte para este repositório/diretório (`<destino>/docker-compose.yml`).
2. Em **Environment Variables**, defina:
   - `MINIO_ROOT_USER` — ex.: `admin`
   - `MINIO_ROOT_PASSWORD` — gere com `openssl rand -hex 16`
3. Em **Domains** do serviço `minio`, mapeie:
   - `https://<dominio-api>` → porta **9000**
   - `https://<dominio-console>` → porta **9001**
4. Clique em **Deploy**. O serviço `createbuckets` roda uma vez e cria os buckets iniciais.

## 3. Formas de acesso

### Console web

- URL: `https://<dominio-console>`
- Login: `MINIO_ROOT_USER` / `MINIO_ROOT_PASSWORD`

### API S3 (aplicações e mc)

- Endpoint: `https://<dominio-api>` (path-style, região `us-east-1`)

```bash
mc alias set myminio https://<dominio-api> <ACCESS_KEY> <SECRET_KEY>
mc ls myminio
```

## 4. Buckets

Criados automaticamente no primeiro deploy: `<lista-de-buckets>`.

Para criar mais:

- **Console**: Buckets → Create Bucket.
- **mc**: `mc mb myminio/<novo-bucket>`
- Download público: `mc anonymous set download myminio/<bucket>`

## 5. Credenciais para as aplicações

Não use as credenciais root nas aplicações. Crie uma access key dedicada:

1. Console → **Access Keys → Create Access Key** (ou `mc admin accesskey create myminio/`).
2. Guarde o par gerado no secret manager / Environment Variables do Coolify da aplicação.

Variáveis de ambiente para o `.env.example` da aplicação consumidora:

```bash
S3_ENDPOINT=https://<dominio-api>
S3_ACCESS_KEY=changeme
S3_SECRET_KEY=changeme
S3_BUCKET=<bucket-1>
S3_REGION=us-east-1
S3_FORCE_PATH_STYLE=true
```
```
