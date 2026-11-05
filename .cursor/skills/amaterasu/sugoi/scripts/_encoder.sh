# amaterasu-sugoi · picks the image encoder. Defines EXT and extract().
# extract <input> <ffmpeg-filter> <out-dir> <quality> [name-pattern=f_%04d]

if ffmpeg -hide_banner -encoders 2>/dev/null | grep -q libwebp; then
  MODE=ffmpeg-webp; EXT=webp
elif command -v cwebp >/dev/null; then
  MODE=cwebp; EXT=webp
else
  MODE=jpg; EXT=jpg
  echo "Warning: no WebP encoder (ffmpeg libwebp or cwebp). Falling back to JPG." >&2
fi

extract() {
  local in="$1" filter="$2" dir="$3" q="$4" name="${5:-f_%04d}"
  case "$MODE" in
    ffmpeg-webp)
      ffmpeg -v error -y -i "$in" -vf "$filter" -c:v libwebp -quality "$q" -compression_level 6 "$dir/$name.webp" ;;
    cwebp)
      local tmp; tmp=$(mktemp -d)
      ffmpeg -v error -y -i "$in" -vf "$filter" "$tmp/$name.png"
      find "$tmp" -name '*.png' -print0 | xargs -0 -P 8 -I{} sh -c \
        'cwebp -quiet -q '"$q"' -alpha_q 90 "$1" -o "'"$dir"'/$(basename "${1%.png}").webp"' _ {}
      rm -rf "$tmp" ;;
    jpg)
      ffmpeg -v error -y -i "$in" -vf "$filter" -q:v 3 "$dir/$name.jpg" ;;
  esac
}
