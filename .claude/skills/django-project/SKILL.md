---
name: django-project
description: >-
  Creates a Django installation either as an API (Django REST Framework) or as
  a monolith with a Vue frontend (asks the user), with pytest for automated
  tests, Pydantic for object typing, SQLAlchemy as ORM, and optionally pandas
  + numpy for data manipulation (asks the user). Use when the user asks to
  create or bootstrap a Django project.
disable-model-invocation: true
---

# Django Project

Scaffolds a Django project. Requires Python 3.11+ (verify; ask before installing system packages). Prefer `uv` for env management, fallback `python3 -m venv`.

## Step 1 — Ask (only what's missing)

Single AskQuestion call:

1. **Shape**: API-only (Django REST Framework) or monolith with Vue frontend?
2. **Data tooling**: include pandas + numpy for data manipulation?
3. **Database**: postgres (recommended) or sqlite for now?

## Step 2 — Install

```bash
uv init <name> && cd <name>          # or: python3 -m venv .venv && source .venv/bin/activate
uv add django pydantic sqlalchemy
uv add --dev pytest pytest-django
# API shape:
uv add djangorestframework django-cors-headers
# pandas answer = yes:
uv add pandas numpy
# postgres:
uv add "psycopg[binary]"
django-admin startproject config .
```

Vue shape: scaffold frontend separately (`npm create vue@latest frontend`), served by Vite dev server in dev and built into Django staticfiles (or reverse-proxied) in prod. Django keeps templates only as the app shell.

## Step 3 — Wiring the unusual choices

This stack deliberately replaces two Django defaults — apply consistently:

- **SQLAlchemy as ORM**: create `db/engine.py` (engine + `sessionmaker` from `DATABASE_URL`) and `db/models.py` (Declarative Base). Use Alembic for migrations (`uv add alembic && alembic init migrations`). Django's ORM stays only for `django.contrib` internals (auth/admin/sessions) on the same database.
- **Pydantic for object typing**: request/response and service-layer objects are Pydantic models (`schemas/`). In DRF views, validate payloads with Pydantic schemas and return `.model_dump()`; keep serializers thin or skip them where Pydantic covers the contract.

## Step 4 — Settings baseline

- `SECRET_KEY`, `DEBUG`, `ALLOWED_HOSTS`, `DATABASE_URL` from environment; update `.env.example` (never `.env`).
- API shape: `rest_framework` + `corsheaders` in `INSTALLED_APPS`, CORS **allowlist** (never `CORS_ALLOW_ALL_ORIGINS=True`), DRF throttling defaults.
- Production flags to document: `SECURE_SSL_REDIRECT`, `SESSION_COOKIE_SECURE`, `CSRF_COOKIE_SECURE`, `SECURE_HSTS_SECONDS`.

## Step 5 — pytest

`pyproject.toml`:

```toml
[tool.pytest.ini_options]
DJANGO_SETTINGS_MODULE = "config.settings"
python_files = ["test_*.py"]
```

Seed one passing test (health endpoint via `client`), plus a unit test slot for SQLAlchemy repositories (sqlite in-memory engine). Feature work follows the [`tester`](../tester/SKILL.md) skill (Red/Green).

## Step 6 — Verify & report

Run `python manage.py check`, `pytest`. Report: shape chosen, packages, SQLAlchemy/Alembic wiring, pandas included or not, test result.
