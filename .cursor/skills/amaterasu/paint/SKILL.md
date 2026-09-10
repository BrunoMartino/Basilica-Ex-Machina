---
name: amaterasu-paint
description: >-
  Paint a full visual universe with amaterasu — brainstorm, theses, design system
  (MASTER.md), implement, audit. Anti-AI-slop. Web Tailwind/Bootstrap, Compose, SwiftUI.
  Use for redesigns, design systems, portfolios from scratch, or /amaterasu-paint.
disable-model-invocation: true
---

# Amaterasu Paint — Master Painter

Brainstorm → theses → design system → implement → audit. Not a quick beautifier.

## Voice

- **During work**: short flair ("Brushing palette.", "Setting spacing tokens.")
- **Reports**: plain. Files. Facts.

## vs Cast

| | cast | paint |
|---|------|-------|
| Goal | Polish / wow existing | Build visual universe |
| Discovery | If vague | Mandatory brainstorm |
| Design system | Optional | Required MASTER.md (except light) |
| Audit | Quick | Full |

## Iron Rules

1. Never skip brainstorm (light: one Q only).
2. One question at a time.
3. Both theses validated before code (light: interaction only).
4. Tokens from MASTER.md (light: existing project tokens only).
5. Animations obey interaction thesis.
6. Never install dep without asking.
7. Page by page; validate page by page.
8. Audit always runs (light: shortened).
9. No anim lib → native first; detected lib → respect.
10. Preview mode once; stick.
11. Web: `web-styling`, framework breakpoints, `max-width: 1920px` centered.
12. Web: design brief (colors/fonts) after SCAN.

## Module base

Read `.cursor/skills/amaterasu/_jutsu/<name>/SKILL.md`

## Light scope

All three: one component; no new visual identity; nothing downstream needs systematizing.

| Phase | Full | Light |
|-------|------|-------|
| Brainstorm | 5 domains | 1 Q |
| Thesis | visual + interaction | interaction only |
| Design system | MASTER.md | skip; use existing tokens |
| Implement | page by page | one component |
| Audit | full | reduced-motion, exit, 60fps |

Announce: "Running paint light. Say so for full pipeline."

## Preview gate

Same as cast: A Canvas/HTML | B live preview | C inline. Ask once. Throwaway.

## Pipeline

### Phase 1 — BRAINSTORM

**SCAN** (same bash as cast). Map stack including Bootstrap vs Tailwind.

**DESIGN BRIEF (web)** — see `web-styling`. Detect or AskQuestion: primary, secondary, tertiary, success, danger, warning, fonts. Self-host fonts by default.

Domains (one Q at a time; skip known from SCAN): product, audience, mood (3–5 adjectives), references, tech stack.

Vague answers → concrete options / "what would feel wrong?" Never treat "yeah" as confirm.

Stop when both theses writable without guessing.

### Phase 2 — THESIS

**Visual** (4): color direction, type spirit, spacing philosophy, component style.
**Interaction** (4): timing range, hover, scroll, forbidden patterns.

Preview → wait explicit OK on both (light: interaction only).

### Phase 3 — DESIGN SYSTEM

```bash
go -C .cursor/skills/amaterasu/_jutsu/ui-ux-pro-max/cli run . design-system "<product> <industry> <mood>"
```

Treat CLI output as proposal; thesis wins on conflict. Fail → derive from thesis by hand.

Stack-aware tokens:

- Web Tailwind: `@theme` / config + CSS vars
- Web Bootstrap: `$theme-colors` + CSS vars
- Compose: Theme/Color/Type/Shapes/Motion.kt
- SwiftUI: Color+/Font+/Animation+/Shape+App.swift
- CMP: commonMain + expect/actual notes

MASTER.md at project root = SoT. Show design system in preview mode; wait OK.

Optional MCPs (Stitch, Nano Banana, 21st.dev): use if present; else skip.

### Phase 4 — IMPLEMENT

Load: always `motion-principles`; web `web-styling`; then same load table as cast.

Rules: tokens only from MASTER.md; thesis for motion; five states; page-by-page validation; 1920px container + framework breakpoints.

### Phase 5 — AUDIT

Read `design-audit`. Run Go audit if available. Evidence vs handoff split (same checklist as cast + design consistency). Order findings Critical > Important > Nice.

## Existing project

Thesis overrides existing look. Replace visual layer; keep structure/function. For polish-only → redirect to cast.

## Decision tree

```
request → SCAN → (web BRIEF) → BRAINSTORM → THESIS → DESIGN SYSTEM → LOAD → IMPLEMENT → AUDIT
```
