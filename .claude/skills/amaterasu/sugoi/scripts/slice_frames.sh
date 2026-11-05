#!/usr/bin/env bash
# amaterasu-sugoi · slices a video into N frames (desktop 1920w, mobile 960h) + frames.json.
# Usage: slice_frames.sh <video.mp4> <out-dir> [count=160]
set -euo pipefail

VIDEO="${1:?video path}"
OUT="${2:?output dir}"
N_REQ="${3:-160}"

command -v ffmpeg >/dev/null || { echo "ffmpeg not found"; exit 1; }
source "$(dirname "$0")/_encoder.sh"

DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$VIDEO")
FPS=$(python3 -c "print(round($N_REQ / float('$DUR'), 4))")

rm -rf "$OUT/desktop" "$OUT/mobile"
mkdir -p "$OUT/desktop" "$OUT/mobile"

extract "$VIDEO" "fps=$FPS,scale=1920:-2:flags=lanczos" "$OUT/desktop" 78
extract "$VIDEO" "fps=$FPS,scale=-2:960:flags=lanczos"  "$OUT/mobile"  72

N=$(ls "$OUT/desktop" | wc -l | tr -d ' ')
FIRST="$OUT/desktop/f_0001.$EXT"
W=$(ffprobe -v error -select_streams v:0 -show_entries stream=width  -of csv=p=0 "$FIRST")
H=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$FIRST")
REL="${OUT#*/site/}"; [ "$REL" = "$OUT" ] && REL="assets/frames"

cat > "$OUT/frames.json" <<JSON
{ "total": $N, "width": $W, "height": $H,
  "desktop": "$REL/desktop/f_{n}.$EXT", "mobile": "$REL/mobile/f_{n}.$EXT" }
JSON

echo "OK: $N frames .$EXT (${W}x${H}) · desktop $(du -sh "$OUT/desktop" | cut -f1) · mobile $(du -sh "$OUT/mobile" | cut -f1)"
echo "config.js → frames: { total: $N, desktop: \"$REL/desktop/f_{n}.$EXT\", mobile: \"$REL/mobile/f_{n}.$EXT\" }"
[ "$EXT" = jpg ] && echo "Also change og:image and preload in index.html to .jpg"
exit 0
