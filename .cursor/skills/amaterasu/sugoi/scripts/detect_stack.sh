#!/usr/bin/env bash
# amaterasu-sugoi · one-shot stack detection. Prints key=value lines; nothing else.
# Usage: detect_stack.sh [project-dir]
set -uo pipefail
d="${1:-.}"
cd "$d" 2>/dev/null || { echo "stack=unknown dir-missing"; exit 0; }

rg_() { rg -l --max-depth 6 -g '!node_modules' -g '!vendor' -g '!.git' -g '!dist' -g '!build' -g '!.claude' -g '!.cursor' "$@" 2>/dev/null | head -3; }
has() { [ -n "$(rg_ "$@")" ]; }
csv() { local IFS=,; echo "$*"; }

# ── package.json libs ──────────────────────────────────────────────────────
libs=(); fw=""
if [ -f package.json ]; then
  for p in gsap three @react-three/fiber lenis tailwindcss bootstrap react vue svelte next nuxt astro vite; do
    grep -q "\"$p\"" package.json && libs+=("$p")
  done
  for f in next nuxt astro svelte vue vite react; do
    grep -q "\"$f\"" package.json && { fw="$f"; break; }
  done
fi

# ── WordPress / LiveCanvas / Picostrap ─────────────────────────────────────
wp=""; lc=""; child=""
if [ -f wp-config.php ] || [ -d wp-content ]; then
  wp=1
  [ -d wp-content/plugins/livecanvas ] || ls -d wp-content/plugins/livecanvas* >/dev/null 2>&1 && lc=1
  ls -d wp-content/themes/picostrap5* >/dev/null 2>&1 && lc="${lc:-picostrap}"
  for t in wp-content/themes/*/style.css; do
    grep -qi '^Template:' "$t" 2>/dev/null && child="$(dirname "$t")"
  done
elif has -e 'livecanvas|picostrap' -g 'functions.php' -g 'style.css'; then
  wp=1; lc=1; child="$d"
fi

# ── Backend markers (static front + API) ───────────────────────────────────
be=()
[ -f artisan ] && be+=(laravel); [ -f manage.py ] && be+=(django)
[ -f composer.json ] && [ -z "$wp" ] && be+=(php)
[ -f go.mod ] && be+=(go); [ -f Cargo.toml ] && be+=(rust)
[ -f requirements.txt ] || [ -f pyproject.toml ] && be+=(python)
for dir in api server backend; do [ -d "$dir" ] && be+=("$dir/"); done
has_html=$(ls *.html index.htm* public/index.html src/index.html 2>/dev/null | head -1)

# ── Stack verdict ──────────────────────────────────────────────────────────
if [ -n "$wp" ] && [ -n "$lc" ]; then stack="wordpress+livecanvas"
elif [ -n "$wp" ]; then stack="wordpress"
elif [ -n "$fw" ]; then stack="framework:$fw"
elif [ ${#be[@]} -gt 0 ]; then stack="frontend+backend"
else stack="static"; fi
echo "stack=$stack"
[ -n "$child" ] && echo "wp_child=$child"
[ ${#be[@]} -gt 0 ] && echo "backend=$(csv "${be[@]}")"
[ ${#libs[@]} -gt 0 ] && echo "npm=$(csv "${libs[@]}")"

# ── CSS framework / existing tokens ────────────────────────────────────────
css=()
has -e '@tailwind|@theme|tailwind.config' -g '*.{css,js,ts,mjs}' && css+=(tailwind)
has -e 'bootstrap' -g '*.{scss,css,html,php}' && css+=(bootstrap)
echo "css=$([ ${#css[@]} -gt 0 ] && csv "${css[@]}" || echo none)"
tok=()
[ -f MASTER.md ] && tok+=(MASTER.md)
t=$(rg_ -e ':root\s*\{' -g '*.{css,scss}'); [ -n "$t" ] && tok+=("$(echo "$t" | tr '\n' ',' | sed 's/,$//')")
t=$(rg_ -e '^\$(primary|theme-colors)' -g '*.scss'); [ -n "$t" ] && tok+=("$(echo "$t" | tr '\n' ',' | sed 's/,$//')")
echo "tokens=$([ ${#tok[@]} -gt 0 ] && csv "${tok[@]}" || echo none)"

# ── Animation libs already present ─────────────────────────────────────────
anim=()
for l in gsap lenis three; do printf '%s\n' "${libs[@]:-}" | grep -qx "$l" && anim+=("$l"); done
has -e 'gsap\.min\.js|cdn\.jsdelivr\.net/npm/gsap|unpkg\.com/gsap' -g '*.{html,php}' && anim+=(gsap-script)
has -e 'wp_enqueue_script\(.*gsap' -g '*.php' && anim+=(gsap-enqueued)
echo "anim=$([ ${#anim[@]} -gt 0 ] && csv "${anim[@]}" || echo none)"

# ── Existing form handling ─────────────────────────────────────────────────
forms=()
has -e '<form[^>]*action=' -g '*.{html,php,jsx,tsx,vue,svelte,astro}' && forms+=(form-action)
has -e 'formsubmit\.co|web3forms' -g '*.{html,js,ts,php}' && forms+=(formsubmit/web3forms)
has -e 'wp_mail\(|contact-form-7|wpforms|fluentform' -g '*.php' && forms+=(wp-mail/plugin)
[ -d wp-content/plugins/contact-form-7 ] && forms+=(cf7); [ -d wp-content/plugins/wpforms-lite ] || [ -d wp-content/plugins/wpforms ] && forms+=(wpforms)
has -e '/api/contact|nodemailer|resend|sendgrid|@sendgrid/mail|smtplib' -g '*.{js,ts,py,php,go}' && forms+=(backend-mailer)
echo "forms=$([ ${#forms[@]} -gt 0 ] && csv "${forms[@]}" || echo none)"

# ── Existing assets ────────────────────────────────────────────────────────
assets=()
v=$(find . -maxdepth 5 -type f \( -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mov' \) -not -path '*/node_modules/*' 2>/dev/null | head -3 | tr '\n' ',' | sed 's/,$//'); [ -n "$v" ] && assets+=("video:$v")
f=$(find . -maxdepth 6 -type d -iname 'frames' -not -path '*/node_modules/*' 2>/dev/null | head -2 | tr '\n' ',' | sed 's/,$//'); [ -n "$f" ] && assets+=("frames:$f")
n=$(find . -maxdepth 5 -type f \( -iname '*.webp' -o -iname '*.jpg' -o -iname '*.png' \) -not -path '*/node_modules/*' -not -path '*/frames/*' 2>/dev/null | wc -l | tr -d ' '); [ "$n" -gt 0 ] && assets+=("images:$n")
l=$(find . -maxdepth 5 -type f -iname 'logo*' -not -path '*/node_modules/*' 2>/dev/null | head -1); [ -n "$l" ] && assets+=("logo:$l")
echo "assets=$([ ${#assets[@]} -gt 0 ] && csv "${assets[@]}" || echo none)"

# ── Tooling ────────────────────────────────────────────────────────────────
tools=()
for t in ffmpeg ffprobe python3 cwebp node npm; do command -v "$t" >/dev/null && tools+=("$t"); done
ffmpeg -hide_banner -encoders 2>/dev/null | grep -q libwebp && tools+=(libwebp)
k=none; [ -n "${OPENROUTER_API_KEY:-}" ] && k=env
[ "$k" = none ] && [ -f .env ] && grep -q '^OPENROUTER_API_KEY=' .env && k=.env
[ "$k" = none ] && [ -f "$HOME/.config/sugoi/openrouter.key" ] && k=config
echo "tools=$(csv "${tools[@]}")"
echo "openrouter_key=$k"
