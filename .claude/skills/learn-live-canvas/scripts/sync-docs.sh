#!/usr/bin/env bash
# Sync LiveCanvas docs and Picostrap 5 source into local skill cache.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CACHE_DIR="$SKILL_DIR/reference/cache"
DOCS_DIR="$CACHE_DIR/docs"
PICOSTRAP_DIR="$CACHE_DIR/picostrap"
DOC_URLS="$CACHE_DIR/doc-urls.txt"
HOOKS_INDEX="$CACHE_DIR/picostrap-hooks.txt"

DOCS_SITEMAP="https://docs.livecanvas.com/documentation-sitemap.xml"
GITHUB_RAW="https://raw.githubusercontent.com/livecanvas-team/picostrap5/master"

mkdir -p "$DOCS_DIR" "$PICOSTRAP_DIR/inc" "$PICOSTRAP_DIR/inc/customizer-assets"

echo "==> Fetching LiveCanvas documentation sitemap..."
curl -sL "$DOCS_SITEMAP" \
  | grep -oE '<loc>[^<]+</loc>' \
  | sed 's/<[^>]*>//g' \
  | grep 'docs.livecanvas.com' \
  > "$DOC_URLS" || true

# Also include homepage
echo "https://docs.livecanvas.com/" >> "$DOC_URLS"
sort -u "$DOC_URLS" -o "$DOC_URLS"

DOC_COUNT=$(wc -l < "$DOC_URLS")
echo "==> Downloading $DOC_COUNT LiveCanvas doc pages..."
while IFS= read -r url; do
  slug="$(echo "$url" | sed -E 's|https://docs.livecanvas.com/||; s|/$||; s|/|-|g')"
  [ -z "$slug" ] && slug="index"
  dest="$DOCS_DIR/${slug}.html"
  if [ -f "$dest" ] && [ "$(find "$dest" -mtime -7 2>/dev/null)" ]; then
    continue
  fi
  curl -sL "$url" -o "$dest" || echo "  WARN: failed $url"
done < "$DOC_URLS"

echo "==> Downloading Picostrap 5 key files..."
PICOSTRAP_FILES=(
  "README.md"
  "functions.php"
  "style.css"
  "header.php"
  "footer.php"
  "inc/livecanvas-config.php"
  "inc/content-filtering.php"
  "inc/theme-settings.php"
  "inc/setup.php"
  "inc/enqueues.php"
  "inc/template-tags.php"
  "inc/widgets.php"
  "inc/clean-head.php"
  "inc/woocommerce.php"
  "inc/windpress-support.php"
  "inc/picosass-compiler-integration.php"
  "inc/bootstrap-navwalker.php"
  "inc/custom-comments.php"
  "inc/pagination.php"
  "inc/editor.php"
  "inc/options-page.php"
)

for rel in "${PICOSTRAP_FILES[@]}"; do
  dest="$PICOSTRAP_DIR/$rel"
  mkdir -p "$(dirname "$dest")"
  curl -sL "$GITHUB_RAW/$rel" -o "$dest" || echo "  WARN: failed $rel"
done

echo "==> Indexing Picostrap hooks (add_action, add_filter, apply_filters)..."
{
  echo "# Picostrap 5 hooks index — generated $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "# Source: https://github.com/livecanvas-team/picostrap5"
  echo
  rg -n "(add_action|add_filter|apply_filters|do_action|function lc_|function picostrap_)" \
    "$PICOSTRAP_DIR" --glob '*.php' 2>/dev/null || true
} > "$HOOKS_INDEX"

echo "==> Done."
echo "  Docs:    $DOCS_DIR ($(find "$DOCS_DIR" -name '*.html' 2>/dev/null | wc -l) files)"
echo "  Picostrap: $PICOSTRAP_DIR"
echo "  Hooks:   $HOOKS_INDEX"
