---
name: node-express-project
description: >-
  Scaffolds a Node.js + Express + TypeScript development environment via npm
  or bun (asks the user), with Zod validation, Prisma or Drizzle ORM (asks the
  user), response-delivery optimization (compression, clustering/worker
  threads), and Jest for automated tests. Use when the user asks to create or
  bootstrap an Express project or API.
disable-model-invocation: true
---

# Node Express Project

Scaffolds a production-lean Express API. Do not reinvent choices the user already stated in the prompt.

## Step 1 — Ask (only what's missing)

Single AskQuestion call:

1. **Package manager**: npm or bun?
2. **ORM**: Prisma or Drizzle? (and target DB: postgres/mysql/sqlite)
3. **Parallelism**: worker threads for CPU-bound work (piscina), cluster mode for multi-core (Node `cluster` / PM2), or none for now?

## Step 2 — Install

Base (adapt `npm i` ↔ `bun add`, `npm i -D` ↔ `bun add -d`):

```bash
npm init -y
npm i express zod helmet cors compression
npm i -D typescript tsx @types/node @types/express @types/cors @types/compression \
  jest ts-jest @types/jest supertest @types/supertest
npx tsc --init --rootDir src --outDir dist --strict true --esModuleInterop true
```

ORM (per answer):

```bash
# Prisma
npm i @prisma/client && npm i -D prisma && npx prisma init --datasource-provider postgresql
# Drizzle
npm i drizzle-orm pg && npm i -D drizzle-kit @types/pg
```

Parallelism (per answer): `npm i piscina` (worker pool) — cluster mode needs no lib (`node:cluster`) or use PM2 in deploy.

## Step 3 — Structure

```
src/
├── app.ts            # express app: helmet, cors, compression, json, routes
├── server.ts         # listen (+ optional cluster bootstrap)
├── routes/
├── controllers/
├── services/
├── middlewares/validate.ts   # zod middleware
└── workers/          # piscina tasks, if chosen
tests/
```

Key files — `middlewares/validate.ts`:

```typescript
import { AnyZodObject } from "zod";
import { Request, Response, NextFunction } from "express";

export const validate = (schema: AnyZodObject) =>
  (req: Request, res: Response, next: NextFunction) => {
    const result = schema.safeParse({ body: req.body, query: req.query, params: req.params });
    if (!result.success) return res.status(400).json({ errors: result.error.flatten() });
    next();
  };
```

`app.ts` order: `helmet()` → `cors({ origin: [...] })` → `compression()` → `express.json({ limit: "1mb" })` → routes → error handler. Update `.env.example` (never `.env`) with `PORT` and `DATABASE_URL` placeholders.

`package.json` scripts: `"dev": "tsx watch src/server.ts"`, `"build": "tsc"`, `"start": "node dist/server.js"`, `"test": "jest"`.

## Step 4 — Jest

`jest.config.js`: preset `ts-jest`, testEnvironment `node`, roots `["<rootDir>/tests"]`. Seed one passing integration test (supertest against `GET /health`) and follow the [`tester`](../tester/SKILL.md) skill for feature work (Red/Green).

## Step 5 — Verify & report

Run `npm run dev` (health check responds) and `npm test`. Report: manager/ORM chosen, packages installed, structure created, test result.
