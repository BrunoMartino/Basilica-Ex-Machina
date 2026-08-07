---
name: node-fastify-project
description: >-
  Scaffolds a Node.js + Fastify + TypeScript development environment via npm
  or bun (asks the user), with Zod validation (fastify-type-provider-zod),
  Prisma or Drizzle ORM (asks the user), response-delivery optimization
  (@fastify/compress, worker threads/cluster), and Jest for automated tests.
  Use when the user asks to create or bootstrap a Fastify project or API.
disable-model-invocation: true
---

# Node Fastify Project

Scaffolds a production-lean Fastify API. Do not reinvent choices the user already stated in the prompt.

## Step 1 — Ask (only what's missing)

Single AskQuestion call:

1. **Package manager**: npm or bun?
2. **ORM**: Prisma or Drizzle? (and target DB: postgres/mysql/sqlite)
3. **Parallelism**: worker threads for CPU-bound work (piscina), cluster mode (Node `cluster` / PM2), or none for now?

## Step 2 — Install

Base (adapt `npm i` ↔ `bun add`):

```bash
npm init -y
npm i fastify zod fastify-type-provider-zod @fastify/helmet @fastify/cors @fastify/compress @fastify/rate-limit
npm i -D typescript tsx @types/node jest ts-jest @types/jest
npx tsc --init --rootDir src --outDir dist --strict true --esModuleInterop true
```

ORM (per answer):

```bash
# Prisma
npm i @prisma/client && npm i -D prisma && npx prisma init --datasource-provider postgresql
# Drizzle
npm i drizzle-orm pg && npm i -D drizzle-kit @types/pg
```

Parallelism (per answer): `npm i piscina`; cluster needs no lib (`node:cluster` / PM2 at deploy).

## Step 3 — Structure

```
src/
├── app.ts            # buildApp(): registers plugins + routes (exported for tests)
├── server.ts         # listen (+ optional cluster bootstrap)
├── routes/
├── services/
├── schemas/          # zod schemas
└── workers/          # piscina tasks, if chosen
tests/
```

`app.ts` core:

```typescript
import Fastify from "fastify";
import { serializerCompiler, validatorCompiler, ZodTypeProvider } from "fastify-type-provider-zod";

export function buildApp() {
  const app = Fastify({ logger: true }).withTypeProvider<ZodTypeProvider>();
  app.setValidatorCompiler(validatorCompiler);
  app.setSerializerCompiler(serializerCompiler);
  app.register(import("@fastify/helmet"));
  app.register(import("@fastify/cors"), { origin: [/* allowlist */] });
  app.register(import("@fastify/compress"));
  app.register(import("@fastify/rate-limit"), { max: 100, timeWindow: "1 minute" });
  // register routes with zod schemas: { schema: { body: myZodSchema } }
  return app;
}
```

Routes declare `schema.body/querystring/params/response` with Zod — Fastify then validates **and** serializes fast. Update `.env.example` (never `.env`) with `PORT` and `DATABASE_URL` placeholders.

Scripts: `"dev": "tsx watch src/server.ts"`, `"build": "tsc"`, `"start": "node dist/server.js"`, `"test": "jest"`.

## Step 4 — Jest

`jest.config.js`: preset `ts-jest`, testEnvironment `node`. Integration tests use `buildApp()` + `app.inject()` (no real port needed). Seed one passing test for `GET /health`; feature work follows the [`tester`](../tester/SKILL.md) skill (Red/Green).

## Step 5 — Verify & report

Run `npm run dev` and `npm test`. Report: manager/ORM chosen, packages installed, structure created, test result.
