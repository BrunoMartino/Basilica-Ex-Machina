---
name: make-etl-project
description: >-
  Creates a Python ETL project with SQLAlchemy, pandas, and numpy, structured
  around source and target databases for migrations, with pytest suites for
  extract, transform, and load stages. Use when the user asks to create an ETL
  pipeline, data migration project, or database-to-database transfer tooling.
disable-model-invocation: true
---

# Make ETL Project

Scaffolds a Python ETL/migration project expecting a **source** and a **target** database. Requires Python 3.11+; prefer `uv`, fallback venv.

## Step 1 — Ask (only what's missing)

Single AskQuestion call:

1. **Source database**: engine (postgres/mysql/sqlserver/sqlite/other)? Connection details available now?
2. **Target database**: engine? Connection details available now?
3. **Run style**: one-shot migration or repeatable/incremental pipeline?

Connection strings are secrets: put placeholder URLs in `.env.example` (never write `.env`) as `SOURCE_DATABASE_URL` / `TARGET_DATABASE_URL`.

## Step 2 — Install

```bash
uv init <name> && cd <name>
uv add sqlalchemy pandas numpy python-dotenv
uv add --dev pytest
# drivers per engines chosen, e.g.:
uv add "psycopg[binary]"     # postgres
uv add pymysql               # mysql
```

## Step 3 — Structure

```
src/etl/
├── config.py         # reads SOURCE_DATABASE_URL / TARGET_DATABASE_URL from env
├── connections.py    # create_engine() for source and target (pool_pre_ping=True)
├── extract.py        # queries → DataFrame (pd.read_sql, chunksize for big tables)
├── transform.py      # pure functions: DataFrame in → DataFrame out
├── load.py           # DataFrame → target (to_sql / SQLAlchemy Core upserts)
├── pipeline.py       # orchestrates E→T→L per table, logs row counts
└── __main__.py       # python -m etl [--tables ...] [--dry-run]
tests/
├── test_extract.py
├── test_transform.py
└── test_load.py
```

Design rules:

- **Transforms are pure** (no I/O) — trivially testable with numpy/pandas fixtures.
- **Chunked processing** for large tables (`chunksize=`) to bound memory.
- **Idempotent loads**: upsert or truncate-and-load per table, decided explicitly; log source vs loaded row counts and fail on mismatch.
- Never log connection strings or row-level PII.

## Step 4 — pytest per stage

- **Extract**: against a sqlite in-memory engine seeded with fixture rows — asserts query shape/filters.
- **Transform**: pure DataFrame in/out — cover happy, boundary (empty frame, nulls), and bad-data cases.
- **Load**: sqlite in-memory target — asserts row counts, idempotency (run twice → same state), and type mapping.

No test touches real source/target databases. Feature work follows the [`tester`](../tester/SKILL.md) skill (Red/Green).

## Step 5 — Verify & report

Run `pytest` and a `--dry-run` of the pipeline if connections were provided. Report: engines/drivers installed, structure, idempotency strategy, test result.
