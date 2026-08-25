#!/bin/sh
# Copy cistina-arch template.html and inject SVG, title, cards, views.
# POSIX sh + awk only (no Python/Node required).
#
# Usage:
#   inject.sh --svg diagram.svg --title "..." [--subtitle "..."] \
#     [--cards cards.html] [--views views.json] [--preset classic] \
#     [--template path/to/template.html] -o out.html

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
TEMPLATE="$SCRIPT_DIR/../template.html"
SVG="" TITLE="" SUBTITLE="" CARDS="" VIEWS="" PRESET="classic" OUT=""

usage() {
  sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'
  exit 2
}

while [ $# -gt 0 ]; do
  case "$1" in
    --template) TEMPLATE=$2; shift 2 ;;
    --svg)      SVG=$2; shift 2 ;;
    --title)    TITLE=$2; shift 2 ;;
    --subtitle) SUBTITLE=$2; shift 2 ;;
    --cards)    CARDS=$2; shift 2 ;;
    --views)    VIEWS=$2; shift 2 ;;
    --preset)   PRESET=$2; shift 2 ;;
    -o|--output) OUT=$2; shift 2 ;;
    -h|--help)  usage ;;
    *) echo "unknown argument: $1" >&2; usage ;;
  esac
done

[ -n "$SVG" ]   || { echo "error: --svg is required" >&2; exit 2; }
[ -n "$TITLE" ] || { echo "error: --title is required" >&2; exit 2; }
[ -n "$OUT" ]   || { echo "error: -o/--output is required" >&2; exit 2; }
[ -f "$TEMPLATE" ] || { echo "error: template not found: $TEMPLATE" >&2; exit 1; }
[ -f "$SVG" ]      || { echo "error: svg not found: $SVG" >&2; exit 1; }
case "$PRESET" in
  classic|signal-flow|blueprint|editorial) ;;
  *) echo "error: --preset must be classic|signal-flow|blueprint|editorial" >&2; exit 2 ;;
esac

TMPDIR_W=$(mktemp -d) || exit 1
trap 'rm -rf "$TMPDIR_W"' EXIT INT TERM

# Extract exactly one <svg>...</svg> block from the working file.
awk 'BEGIN{f=0} /<svg[ \t>]/{f=1} f{print} f&&/<\/svg>/{exit}' "$SVG" > "$TMPDIR_W/frag.svg"
grep -q '</svg>' "$TMPDIR_W/frag.svg" || { echo "error: SVG file has no <svg>...</svg> element" >&2; exit 1; }

# Cards: default to an empty container; must contain HTML when provided.
if [ -n "$CARDS" ]; then
  [ -f "$CARDS" ] || { echo "error: cards file not found: $CARDS" >&2; exit 1; }
  grep -q '<div' "$CARDS" || { echo "error: cards file must contain HTML (a .cards root)" >&2; exit 1; }
  CARDS_FILE=$CARDS
else
  printf '<div class="cards"></div>\n' > "$TMPDIR_W/cards.html"
  CARDS_FILE=$TMPDIR_W/cards.html
fi

# Views: optional JSON array with at most 5 chapters.
if [ -n "$VIEWS" ]; then
  [ -f "$VIEWS" ] || { echo "error: views file not found: $VIEWS" >&2; exit 1; }
  first=$(sed -n 's/^[[:space:]]*//;/./{p;q;}' "$VIEWS" | cut -c1)
  [ "$first" = "[" ] || { echo "error: views JSON must be an array" >&2; exit 1; }
  ids=$(tr -d ' \t\n' < "$VIEWS" | awk '{n=gsub(/"id":/,""); print n}')
  [ "${ids:-0}" -le 5 ] || { echo "error: at most 5 guided views (found $ids)" >&2; exit 1; }
fi

OUT_DIR=$(dirname -- "$OUT")
[ -d "$OUT_DIR" ] || mkdir -p "$OUT_DIR"

TITLE="$TITLE" SUBTITLE="$SUBTITLE" PRESET="$PRESET" \
awk -v svgf="$TMPDIR_W/frag.svg" -v cardsf="$CARDS_FILE" -v viewsf="${VIEWS:-}" '
function repl(str, find, rep,   i, out) {
  out = ""
  while ((i = index(str, find)) > 0) {
    out = out substr(str, 1, i - 1) rep
    str = substr(str, i + length(find))
  }
  return out str
}
function dump(file,   line) {
  while ((getline line < file) > 0) print line
  close(file)
}
BEGIN {
  title = ENVIRON["TITLE"]; subtitle = ENVIRON["SUBTITLE"]; preset = ENVIRON["PRESET"]
  skip = 0
}
{
  line = $0
  if (skip) {
    if (index(line, "ARCHIFY:SVG_SLOT_END") || index(line, "ARCHIFY:CARDS_SLOT_END")) {
      skip = 0
      print line
    }
    next
  }
  if (index(line, "ARCHIFY:SVG_SLOT_START")) { print line; dump(svgf); skip = 1; next }
  if (index(line, "ARCHIFY:CARDS_SLOT_START")) { print line; dump(cardsf); skip = 1; next }
  if (index(line, "ARCHIFY:GUIDED_VIEWS_DATA") && viewsf != "") {
    print "    <script id=\"archify-guided-views-data\" type=\"application/json\">"
    dump(viewsf)
    print "    </script>"
    next
  }
  line = repl(line, "[PROJECT NAME]", title)
  line = repl(line, "[Subtitle description]", subtitle)
  line = repl(line, "[VISUAL PRESET]", preset)
  line = repl(line, "content=\"archify 2.15.0\"", "content=\"cistina-arch (archify viewer)\"")
  print line
}
' "$TEMPLATE" > "$OUT"

grep -q '\[PROJECT NAME\]' "$OUT" && { echo "error: placeholder survived injection" >&2; exit 1; }

size=$(wc -c < "$OUT" | tr -d ' ')
echo "wrote $OUT ($size bytes)"
