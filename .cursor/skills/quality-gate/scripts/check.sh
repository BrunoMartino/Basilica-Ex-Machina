#!/usr/bin/env bash
# quality-gate RUN: validates Lefthook and runs the repo's Quality Run (check-only).
# Arguments are passed to scripts/quality/run.sh (--stage ..., --path ...).
set -euo pipefail

SETUP_HINT="quality-gate SETUP (scripts/setup.sh in the quality-gate skill)"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

for p_bin in lefthook jq; do
  if ! command -v "$p_bin" >/dev/null 2>&1; then
    echo "${p_bin} not found. Run ${SETUP_HINT}." >&2
    exit 2
  fi
done

if [[ ! -f lefthook.yml && ! -f lefthook.yaml && ! -f .lefthook.yml && ! -f .lefthook.yaml ]]; then
  echo "lefthook.yml not found. Run ${SETUP_HINT}." >&2
  exit 2
fi

if [[ ! -x scripts/quality/run.sh || ! -x scripts/quality/aggregate.sh ]]; then
  echo "scripts/quality/run.sh or aggregate.sh missing. Run ${SETUP_HINT}." >&2
  exit 2
fi

# Quiet on success: only failures reach the caller.
if ! p_out="$(lefthook validate 2>&1)"; then
  echo "$p_out" >&2
  exit 2
fi

exec scripts/quality/run.sh "$@"
