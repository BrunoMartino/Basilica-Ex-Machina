#!/usr/bin/env bash
# amaterasu-sugoi · downloads pinned GSAP core + ScrollTrigger (+ optional plugins) for static sites.
# Usage: vendor_gsap.sh <dest-dir> [extra plugin names, e.g. SplitText Flip]
set -euo pipefail

DEST="${1:?destination dir, e.g. site/assets/vendor}"; shift || true
VER="${GSAP_VERSION:-3.13.0}"
BASE="https://cdn.jsdelivr.net/npm/gsap@$VER/dist"
mkdir -p "$DEST"

fetch() { curl -fsSL "$BASE/$1" -o "$DEST/$1" && echo "$DEST/$1"; }
fetch gsap.min.js
fetch ScrollTrigger.min.js
for p in "$@"; do fetch "$p.min.js"; done
