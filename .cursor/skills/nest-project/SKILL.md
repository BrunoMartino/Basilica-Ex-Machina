---
name: nest-project
description: >-
  Scaffolds an optimized NestJS installation with npm or bun (asks the user),
  fast build tooling (SWC recommended or Vite via vite-plugin-node), request
  validation, Prisma or Drizzle ORM (asks the user), request-optimization and
  security libs (helmet, throttler, compression, caching), and Jest for
  automated tests. Use when the user asks to create or bootstrap a NestJS
  project or API.
disable-model-invocation: true
---

# Nest Project

Scaffolds an optimized NestJS API. Do not reinvent choices the user already stated in the prompt.

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
# SWC (recommended): builds/tests dramatically faster
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

Jest already comes with the Nest CLI scaffold (unit + e2e). With SWC, switch to `@swc/jest` for fast test runs: `npm i -D @swc/jest` and set `transform: { "^.+\\.(t|j)s$": "@swc/jest" }` in the jest config.

## Step 3 — Baseline configuration

`main.ts`:

```typescript
app.use(helmet());
app.use(compression());
app.enableCors({ origin: [/* allowlist */] });
app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }));
```

`app.module.ts`: register `ThrottlerModule.forRoot([{ ttl: 60000, limit: 100 }])` with the global `ThrottlerGuard`, and `CacheModule.register({ isGlobal: true })` for hot read endpoints (`@UseInterceptors(CacheInterceptor)`).

DTOs use `class-validator` decorators; the global pipe strips and rejects unknown fields. Update `.env.example` (never `.env`) with `PORT` and `DATABASE_URL` placeholders.

## Step 4 — Verify & report

Run dev server (`npm run start:dev`) and `npm test`. Report: manager, build tooling, ORM and adapter chosen; packages installed; validation/security baseline applied; test result. Feature work follows the [`tester`](../tester/SKILL.md) skill (Red/Green).
