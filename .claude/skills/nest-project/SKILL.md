---
name: nest-project
description: >-
  Scaffolds a NestJS API that stays idiomatically Nest (DI, modules, decorators)
  while making the dependency graph statically explicit (AI-First / Token-Friendly):
  feature-first modules, Import First, constructor injection, nest-conventions
  rule, and CONTEXT.md. npm or bun, SWC or Vite, Prisma or Drizzle, Express or
  Fastify, validation and security baseline, Jest. Use when the user asks to
  create or bootstrap a NestJS project or API.
disable-model-invocation: true
---

# Nest Project

Scaffolds a NestJS API with **Explicit Dependency Architecture**. Do not reinvent choices the user already stated. Do not fork, bypass, or replace Nest DI.

Canonical spec: [CONTEXT.md](CONTEXT.md). Binding rule: `nest-conventions` (kit `.claude/rules/nest-conventions.md` + `.cursor/rules/nest-conventions.mdc`).

## Step 1 — Ask (only what's missing)

Single AskQuestion call:

1. **Package manager**: npm or bun?
2. **Build/dev tooling**: SWC (official Nest fast builder, recommended) or Vite (`vite-plugin-node`)?
3. **ORM**: Prisma or Drizzle? (and target DB)
4. **HTTP adapter**: Express (default) or Fastify (`@nestjs/platform-fastify`, faster)?

## Step 2 — Scaffold & install

```bash
npx @nestjs/cli new <name> --package-manager npm   # or --package-manager bun (strict mode: accept TS strict)
cd <name>
```

Fast tooling (per answer):

```bash
# SWC (recommended)
npm i -D @swc/cli @swc/core
# nest-cli.json → "compilerOptions": { "builder": "swc", "typeCheck": true }

# Vite alternative
npm i -D vite vite-plugin-node
# create vite.config.ts with VitePluginNode({ adapter: 'nest', appPath: './src/main.ts' })
```

Validation + security + request optimization:

```bash
npm i class-validator class-transformer helmet @nestjs/throttler compression @nestjs/cache-manager cache-manager
```

ORM (per answer):

```bash
# Prisma
npm i @prisma/client && npm i -D prisma && npx prisma init
# Drizzle
npm i drizzle-orm pg && npm i -D drizzle-kit @types/pg
```

Jest ships with the Nest CLI scaffold. With SWC: `npm i -D @swc/jest` and `transform: { "^.+\\.(t|j)s$": "@swc/jest" }`.

## Step 3 — Explicit architecture baseline

Apply [CONTEXT.md](CONTEXT.md). Copy it to the **project root** as `CONTEXT.md`.

Layout (feature-first; `AppModule` is composition root only):

```text
src/
  main.ts
  app.module.ts
  health/
    health.module.ts
    health.controller.ts
```

- Move CLI `AppController` / `AppService` into `health/` (or equivalent). Do not grow `AppModule` with feature providers.
- Never use `src/controllers|services|repositories|entities|modules` as the primary layout.
- Constructor injection; class-as-provider; no `ModuleRef.get()`; no `@Global()`.
- `CacheModule`: import in the feature that needs it — **not** `isGlobal: true`.
- Allowed cross-cutting: `ConfigModule.forRoot()`, `ThrottlerModule.forRoot()` + `APP_GUARD`.
- No barrels that re-export a whole feature.

Install **nest-conventions** into the new project with `alwaysApply: true`:

- kit `.claude/rules/nest-conventions.md` → `.claude/rules/nest-conventions.md`
- kit `.cursor/rules/nest-conventions.mdc` → `.cursor/rules/nest-conventions.mdc`

If the kit is not in this repo, fetch via `get-my-tools` / raw GitHub `main`.

## Step 4 — HTTP baseline

`main.ts`: `helmet()`, `compression()`, CORS **allowlist**, `ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true })`.

`app.module.ts`: import `HealthModule`; register `ThrottlerModule.forRoot([{ ttl: 60000, limit: 100 }])` + global `ThrottlerGuard`. Do **not** register global `CacheModule`.

DTOs use `class-validator`. Update `.env.example` (never `.env`) with `PORT` and `DATABASE_URL`.

## Step 5 — Verify & report

Run `start:dev` and tests. Report: manager, build tooling, ORM, adapter; packages; conventions/rule/`CONTEXT.md` installed; test result.

Greenfield harness next: [`harness-create`](../harness-create/SKILL.md) (must follow nest-conventions — not MVC). Feature work: [`tester`](../tester/SKILL.md).
