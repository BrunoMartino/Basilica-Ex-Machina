#!/usr/bin/env bash
# amaterasu-sugoi · converts section images to WebP (max 2400px wide), keeps alpha. Skips key-*.png and check_*.jpg.
# Usage: optimize_images.sh <src-dir> <dst-dir>
set -euo pipefail

SRC="${1:?source dir}"
DST="${2:?destination dir}"
mkdir -p "$DST"
source "$(dirname "$0")/_encoder.sh"

shopt -s nullglob nocaseglob
for f in "$SRC"/*.{png,jpg,jpeg,webp}; do
  name=$(basename "${f%.*}")
  case "$name" in key-*|check_*) continue ;; esac
  extract "$f" "scale='min(2400,iw)':-2:flags=lanczos" "$DST" 82 "$name"
  echo "$DST/$name.$EXT  $(du -h "$DST/$name.$EXT" | cut -f1)"
done
