---
name: laravel-project
description: >-
  Creates an optimized Laravel installation with API already enabled (Sanctum),
  Eloquent as ORM, FormRequest validators, security libraries and headers,
  PHPUnit for automated tests, and strict PHP type hints enforced by static
  analysis (Larastan). Use when the user asks to create or bootstrap a Laravel
  project or API.
disable-model-invocation: true
---

# Laravel Project

Scaffolds an optimized, API-ready Laravel app. Requires PHP 8.2+ and Composer (verify first; ask before installing system packages).

## Step 1 — Create & enable API

```bash
composer create-project laravel/laravel <name>
cd <name>
php artisan install:api        # routes/api.php + Laravel Sanctum (token auth)
```

Confirm with the user: API-only or API + Blade web routes.

## Step 2 — Data layer (Eloquent)

Eloquent is the ORM — no alternative package. Conventions to enforce in generated code:

- Migrations for every schema change; FKs and indexes declared in migrations.
- Models with `$fillable` (never `$guarded = []`), casts declared, relationships typed.
- Query scopes for reused filters; eager loading (`with()`) to avoid N+1 (add `Model::preventLazyLoading(!app()->isProduction())` in `AppServiceProvider`).

## Step 3 — Validation

All input goes through **FormRequests** (`php artisan make:request StoreOrderRequest`) — `authorize()` + `rules()`; controllers receive validated data only (`$request->validated()`). No inline `$request->all()` writes.

## Step 4 — Security

- **Sanctum** for API token/SPA auth (installed by `install:api`).
- **Rate limiting**: `throttle:api` middleware already on API routes; tune in `bootstrap/app.php` / `RateLimiter::for()`.
- **Security headers**: `composer require spatie/laravel-csp` for CSP; add X-Frame-Options / nosniff / Referrer-Policy via a small middleware if not set at the web server.
- **Authorization**: Policies for every model exposed via API (`php artisan make:policy`); optional `spatie/laravel-permission` for roles (ask before adding).
- Confirm `APP_DEBUG=false` expectation for production and update `.env.example` (never `.env`) with any new variables.

## Step 5 — Type hints & static analysis

- `declare(strict_types=1);` at the top of app PHP files.
- Typed properties, parameters, and return types everywhere (including closures where practical); PHPDoc generics for collections (`Collection<int, Order>`).
- Enforce with Larastan: `composer require --dev larastan/larastan`, `phpstan.neon` with `level: 6`+ and the Larastan extension; run `vendor/bin/phpstan analyse`.

## Step 6 — PHPUnit

Laravel ships PHPUnit configured (`phpunit.xml`, sqlite in-memory available):

- Feature tests for API endpoints (`php artisan make:test OrderApiTest`), unit tests for services/actions.
- Use `RefreshDatabase` and model factories; never hit external services (use `Http::fake()`, `Queue::fake()`).
- Seed one passing feature test (health/root endpoint) and follow the [`tester`](../tester/SKILL.md) skill (Red/Green) for features.

## Step 7 — Verify & report

Run `php artisan test` and `vendor/bin/phpstan analyse`. Report: packages installed, API enabled, security baseline, static analysis level, test result.
