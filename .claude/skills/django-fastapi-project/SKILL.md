---
name: django-fastapi-project
description: >-
  Creates a Django installation with the API served by FastAPI (mounted
  alongside Django), with pytest for automated tests, Pydantic for object
  typing, SQLAlchemy as ORM, and optionally pandas + numpy for data
  manipulation (asks the user). Use when the user asks for a Django + FastAPI
  hybrid project.
disable-model-invocation: true
---

# Django + FastAPI Project

Hybrid: Django provides admin/auth/apps; **FastAPI serves the API** on the same ASGI process. Requires Python 3.11+. Prefer `uv`, fallback venv.

## Step 1 — Ask (only what's missing)

Single AskQuestion call:

1. **Data tooling**: include pandas + numpy for data manipulation?
2. **Database**: postgres (recommended) or sqlite for now?

## Step 2 — Install

```bash
uv init <name> && cd <name>
uv add django fastapi "uvicorn[standard]" pydantic sqlalchemy alembic
uv add --dev pytest pytest-django httpx
# pandas answer = yes:
uv add pandas numpy
# postgres:
uv add "psycopg[binary]"
django-admin startproject config .
```

## Step 3 — Mount FastAPI beside Django (ASGI)

`config/asgi.py`:

```python
import os
from django.core.asgi import get_asgi_application

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")
django_app = get_asgi_application()   # must come before importing api code

from api.main import api               # FastAPI instance

from starlette.applications import Starlette
from starlette.routing import Mount

application = Starlette(routes=[
    Mount("/api", app=api),           # FastAPI: /api/... + /api/docs
    Mount("/", app=django_app),       # Django: admin, auth, everything else
])
```

`api/main.py`: `api = FastAPI(title="<name>")`; add CORS middleware with an explicit **allowlist**; routers under `api/routers/`.

Run with `uvicorn config.asgi:application --reload`.

## Step 4 — Data layer

- **SQLAlchemy** is the API's ORM: `db/engine.py` (engine + `sessionmaker` from `DATABASE_URL`), `db/models.py` (Declarative Base), **Alembic** for migrations. Django's ORM remains only for `django.contrib` (auth/admin/sessions).
- **Pydantic** models in `api/schemas/` define every request/response contract — FastAPI validates and documents them automatically.
- pandas/numpy (if chosen) live in service modules, never in routers.

## Step 5 — pytest

`pyproject.toml`: `DJANGO_SETTINGS_MODULE = "config.settings"`. Test both worlds:

- FastAPI: `httpx.ASGITransport`/`TestClient` against the mounted app (`/api/health`).
- SQLAlchemy repositories: sqlite in-memory engine per test.

Seed one passing health test; feature work follows the [`tester`](../tester/SKILL.md) skill (Red/Green).

## Step 6 — Verify & report

Run `python manage.py check`, `pytest`, and boot uvicorn once (docs reachable at `/api/docs`). Update `.env.example` (never `.env`) with `SECRET_KEY`, `DEBUG`, `DATABASE_URL`. Report: packages, mount layout, pandas included or not, test result.
