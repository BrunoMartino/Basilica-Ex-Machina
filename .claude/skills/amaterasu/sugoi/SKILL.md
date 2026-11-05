---
name: amaterasu-sugoi
description: >-
  Builds visually striking cinematic websites: scroll-driven video hero (canvas
  image sequence on GSAP ScrollTrigger), sections with images fused into the
  background, floating WhatsApp, contact form. Detects the stack (static site,
  static front + isolated backend, WordPress + LiveCanvas/Picostrap) or takes it
  from the user. Reuses existing assets, design tokens and form handlers; only
  generates video/images via OpenRouter or wires FormSubmit/Web3Forms when the
  project has none. Use for "cinematic site", "scroll video landing", "Apple-style
  scroll", "site cinematográfico", "landing page impressionante", or /amaterasu-sugoi.
disable-model-invocation: true
---

# Amaterasu Sugoi — Cinematic Sites

Primary goal: a site that looks like a studio made it. Secondary: respect what already exists (stack, tokens, assets, forms).

`SKILL_DIR=.claude/skills/amaterasu/sugoi`. Modules: `.claude/skills/amaterasu/_jutsu/<name>/SKILL.md` (Read, never slash-invoke).

## Budget rules (token discipline)

1. No preview gate, no variants, no restating the plan. One approval stop (CONCEPT). Then run to the end.
2. Read a `references/*.md` file only at the step that names it. Do not read `_jutsu/gsap` unless writing GSAP outside `template/app.js`.
3. Use the scripts; do not hand-write ffmpeg/API calls. Do not re-read files you just wrote.
4. Ask only what DETECT and the brief cannot answer, one AskQuestion with all open items.
5. Terse voice. Report files, commands, what the user must do. No flair.

## Iron rules

1. Reuse first: existing video/frames/images → skip generation; existing form handler/backend route → wire it; existing tokens → map them. External services (OpenRouter, FormSubmit, Web3Forms) only when the project has nothing.
2. Never commit or print API keys. Never write `.env`.
3. Every section image uses `.art` + a mask variant. No bare `<img>` with corners. All text lives in a `.panel`.
4. One `<h1>`. Copy: concrete nouns of the niche; no invented testimonials, numbers, awards. Banned words list in `references/art-direction.md`.
5. Motion: GSAP + ScrollTrigger from the template. `prefers-reduced-motion` always honoured. Transform/opacity only.
6. Never install a dependency or start a dev server without asking. Never deploy.
7. Existing design system wins over template tokens (see DESIGN below).

## Pipeline

```
DETECT → BRIEF → CONCEPT (stop) → ASSETS → BUILD → INTEGRATE → VERIFY → HANDOFF
```

### 1. DETECT

If the user named the stack, skip the script. Else:

```bash
bash $SKILL_DIR/scripts/detect_stack.sh [project-dir]
```

Output is one line per signal (`stack=`, `css=`, `anim=`, `tokens=`, `forms=`, `assets=`, `tools=`). Decide:

| `stack=` | Mode | Read |
|---|---|---|
| `static` | Static folder, vendored GSAP | — |
| `frontend+backend` / `framework:<next\|astro\|vite…>` | Static front, contact → backend endpoint, GSAP via npm (ask) | `references/stacks.md` §Isolated backend |
| `wordpress+livecanvas` | Child theme assets + LiveCanvas sections | `references/stacks.md` §LiveCanvas |
| `wordpress` (no LiveCanvas) | Ask: isolated page template or headless | `references/stacks.md` |

Missing `ffmpeg`/`python3` in `tools=` → tell the user, stop until present (only needed when generating or slicing).

### 2. BRIEF

Collect in one message (skip what DETECT or the user already gave): brand name, what/for whom, colours (hex) + fonts + 3 mood words, logo path, copy or key claims, references, WhatsApp number + opening message, contact destination (email / endpoint / existing form), sections. Save `brief.json` in the project (shape: `references/brief.example.json`).

### 3. CONCEPT (the only stop)

Read `references/art-direction.md`. Post, in ≤12 lines: visual metaphor (1 sentence), hero shot script (single continuous shot, 3 thirds = 3 text moments), section list with title + image per section, palette + fonts (existing tokens if any), what will be generated vs reused, estimated OpenRouter cost if generating (`or_video.py --list`, `or_image.py --list`). Wait for OK.

### 4. ASSETS

**Have a video (or frame sequence)?** → go to slicing. **Have section images?** → go to optimize. Else, with `OPENROUTER_API_KEY` resolved (env → project `.env` read-only → `~/.config/sugoi/openrouter.key`):

```bash
# keyframes (first AND last frame: fixes composition at both ends)
python3 $SKILL_DIR/scripts/or_image.py --prompt "<p>" --aspect 16:9 --resolution 2K --out <p>/source/key-first.png
python3 $SKILL_DIR/scripts/or_image.py --prompt "<p>" --aspect 16:9 --resolution 2K --out <p>/source/key-last.png
# video, same seed for retries
python3 $SKILL_DIR/scripts/or_video.py --prompt "<p>" --first-frame <p>/source/key-first.png --last-frame <p>/source/key-last.png --duration 8 --resolution 1080p --seed 7 --out <p>/source/hero.mp4
ffmpeg -i <p>/source/hero.mp4 -vf "select='eq(n\,0)+eq(n\,90)+eq(n\,180)'" -vsync 0 <p>/source/check_%d.jpg   # Read the 3 images; redo once max, then ask
```

Section images: one per section (+1 for contact background), same model, same STYLE block, background = exact `--bg` hex. Read each before use.

```bash
bash $SKILL_DIR/scripts/slice_frames.sh <p>/source/hero.mp4 <p>/site/assets/frames 160     # prints the frames: {...} line for config.js
bash $SKILL_DIR/scripts/optimize_images.sh <p>/source <p>/site/assets/img
```

### 5. BUILD

```bash
cp -R $SKILL_DIR/template/. <p>/site/ && rm -rf <p>/site/wp
bash $SKILL_DIR/scripts/vendor_gsap.sh <p>/site/assets/vendor      # static mode only; npm mode: see stacks.md
```

Edit `site/config.js` (name, whatsapp, contact, frames line), `site/index.html` (copy, sections, fonts `<link>`), tokens at top of `site/styles.css`.

**DESIGN.** `tokens=` found (`:root`, Tailwind theme, Bootstrap SCSS, `MASTER.md`): read `_jutsu/web-styling` and map `--bg --bg-2 --text --text-muted --accent --font-display --font-body` to the existing values; do not introduce a new palette. Greenfield: derive from brief; font pairs in `art-direction.md`. `--bg` must equal the hex used in image prompts.

Logo file → `assets/logo.(svg|png)` in header + footer; none → `.brand-text`. Sections not in brief → remove. Testimonials without real quotes → remove.

Extra motion (second scene crossfade, Three.js hero, Lenis, SplitText): `references/motion.md`. 3D requested → also read `_jutsu/threejs-r3f`.

### 6. INTEGRATE

Static: done. Other modes: follow the matching section of `references/stacks.md` (asset paths, enqueue/import, contact endpoint, cache exclusions).

### 7. VERIFY

```bash
python3 $SKILL_DIR/scripts/verify.py <p>/site        # exit 1 on placeholders, bad config, frame mismatch, bare <img>, missing files
cd <p>/site && python3 -m http.server 4173           # ask before starting; then browser: desktop + 390px, scroll the hero both ways
```

Browser check: video scrubs both directions, moments land on the right thirds, no image shows an edge, nothing overflows at 390px, WhatsApp opens the right number, form submits (or native action works).

### 8. HANDOFF

≤8 lines: output path, how to run, screenshots, cost spent, pending user actions (FormSubmit activation e-mail, DNS, WP cache exclusions). No deployment.

## Load table

| When | Read |
|---|---|
| Always at CONCEPT | `references/art-direction.md` |
| Non-static stack | `references/stacks.md` (only the matching section) |
| Existing tokens | `_jutsu/web-styling` |
| Extra motion / 3D | `references/motion.md`, `_jutsu/threejs-r3f` |
| Custom GSAP beyond template | `_jutsu/gsap` |
| User asks for audit | `_jutsu/design-audit` |
