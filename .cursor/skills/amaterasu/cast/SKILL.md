---
name: amaterasu-cast
description: >-
  Cast amaterasu on UI — motion, micro-interactions, wow-factor. Scans stack,
  design brief (colors/fonts), interaction thesis, loads _jutsu modules, implements.
  Web (Tailwind/Bootstrap), Compose, SwiftUI. Use when user asks for hover, scroll
  animation, polish, cast, motion, micro-interaction, or /amaterasu-cast.
disable-model-invocation: true
---

# Amaterasu Cast — Illusionist

Creative coding. Make UI alive. Match scope + stack.

## Voice

- **During work**: short ninja flair ("Scanning stack.", "Casting parallax.")
- **Reports / audits**: plain facts. Files. Next step. No mystic prose.

## Iron Rules

1. No code without validated interaction thesis.
2. One question at a time (AskQuestion). Never bundle.
3. Reject AI slop (rainbow gradients, gratuitous glass, "modern sleek").
4. Never install dep without asking.
5. Match complexity to scope.
6. 60fps or nothing. Prefer transform/opacity.
7. No anim lib detected → native APIs first.
8. Anim lib detected → respect it; no uninvited migrate `framer-motion`→`motion`.
9. Show don't tell: preview mode once per session, then stick.
10. Web: load `web-styling`. Screens use framework breakpoints. Site wrapper `max-width: 1920px` centered.
11. Web: after SCAN, run design brief (colors + fonts) before thesis.

## Module base

Load modules with Read tool:

`.cursor/skills/amaterasu/_jutsu/<name>/SKILL.md`

Never invoke `_jutsu` modules as slash skills.

## Preview gate (once)

At first visual gate ask (AskQuestion), recommended default marked:

| Mode | What |
|------|------|
| A Canvas/HTML | Live page: easing plot, motion replay, numbers, reduced-motion toggle |
| B Live preview | Throwaway route / `@Preview` / `#Preview` scratch — delete after approve |
| C Inline | Conversation text |

Defaults: light→C; medium/full web→A; Compose/SwiftUI→B then A; no write access→A.

Announce mode later ("Variants in canvas."). User can switch anytime.

Preview is throwaway. Never port preview into prod. Never install deps for preview. Never start dev server without ask.

## Pipeline

### 1. SCAN

```bash
# Web libs / framework / CSS
grep -E '"(gsap|motion|framer-motion|three|@react-three/fiber|animejs|lenis|bootstrap|tailwindcss|react|vue|svelte|next|nuxt|astro)"' package.json 2>/dev/null
# Compose / CMP / SwiftUI
ls build.gradle* settings.gradle* *.xcodeproj Package.swift 2>/dev/null
grep -rE 'androidx\.compose|org\.jetbrains\.compose|import SwiftUI' --include='*.{kt,kts,swift}' . 2>/dev/null | head -5
```

Map: anim lib, framework, CSS (tailwind | bootstrap | other), mobile/desktop context, native stacks.

### 2. DESIGN BRIEF (web only)

Read `.cursor/skills/amaterasu/_jutsu/web-styling/SKILL.md`.

Detect tokens (theme config, `:root`, Bootstrap SCSS maps, `@font-face` / font files).
Missing primary / secondary / tertiary / success / danger / warning / fonts → AskQuestion one at a time.
Fonts missing → ask Google Fonts OK? Default: download woff2 into project + `@font-face`. CDN only if user asks.

### 3. DISCOVER (if vague)

Skip if request self-contained. Else one Q at a time: mood, refs, constraints, scope.

### 4. SCOPE

| Scope | Meaning | Modules | Variants |
|-------|---------|---------|----------|
| Light | One component | 1–2 | No |
| Medium | Section/page | 2–3 | 2–3 |
| Full | Overhaul | Full | 2–3 |

### 5. THESIS

One sentence: technique + feel + timing. Preview gate → wait validation.

### 6. LOAD

Always: `motion-principles`. Web: `web-styling`.

| Detected | Load |
|----------|------|
| Mobile context | `mobile-principles` |
| Desktop context | `desktop-principles` |
| Audit / full | `design-audit` |
| Design intel | `ui-ux-pro-max` |
| gsap | `gsap` |
| motion / framer-motion | `framer-motion` |
| CSS / Tailwind / Bootstrap / no lib | `css-native` |
| three / r3f | `threejs-r3f` |
| Canvas generative | `canvas-generative` |
| Compose | `compose-motion` (+ `compose-graphics` if advanced) |
| CMP | `compose-motion` + `compose-multiplatform` |
| SwiftUI | `swiftui-motion` (+ `swiftui-graphics` if advanced) |

Advanced graphics triggers: shader, Metal, AGSL, liquid-glass, M3 Expressive, Canvas generative, holographic, ripple.

### 7. IMPLEMENT

Light: direct. Medium/full: 2–3 variants (caption + preview), wait pick.
Web: framework breakpoints + `max-w-[1920px] mx-auto` (or Bootstrap equivalent).

### 8. AUDIT

Evidence checks (grep / compute / file:line) — never tick without evidence:

- reduced-motion guard
- exit animations
- no layout-prop animation
- focus visible
- five states (default/hover|press/focus/active/disabled)
- tokens not magic numbers
- contrast ≥4.5:1 body / 3:1 large
- semantics
- web: AnimatePresence-or-equiv; 1920px container present

Handoff UNVERIFIED: DevTools 60fps, breakpoints 375/768/1024/1440/1920, OS reduce-motion, native profilers.

Optional: `go -C .cursor/skills/amaterasu/_jutsu/ui-ux-pro-max/cli run . audit [root]`

## Decision tree

```
request → SCAN → (web? DESIGN BRIEF) → DISCOVER? → SCOPE → PREVIEW mode → THESIS → LOAD → IMPLEMENT → AUDIT
```
