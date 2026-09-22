---
name: motion-principles
description: "Motion design foundation — timing, easing, enter/exit patterns, accessibility, performance."
disable-model-invocation: true
---

# Motion Principles

Foundation module. Loaded by every creative skill invocation.

## Timing

| Context | Duration |
|---|---|
| Micro (toggle, hover, focus) | 100–150ms |
| UI (modal, drawer, tab) | 200–300ms |
| Page/route | 300–500ms |
| Scroll-driven / 3D | progress-based, no fixed duration |

**Frequency rule:** more often = shorter/subtler. Hover 1000×/day → ~100ms opacity. Onboarding 1× → 600ms+ OK.

**Exit < enter:** enter ~300ms ease-out + choreography; exit ~200ms ease-in, often opacity only.

## Easing

| Action | Easing |
|---|---|
| Enter | `ease-out` / spring |
| Exit | `ease-in` |
| State change | `ease-in-out` |
| Scroll-synced | `linear` / `none` |
| Playful | underdamped spring |
| Snappy UI | `cubic-bezier(0.2, 0, 0, 1)` |

### Native equivalents

| Web | SwiftUI | Compose |
|---|---|---|
| `cubic-bezier(0.2, 0, 0, 1)` | `.spring(response: 0.4, dampingFraction: 0.85)` / `.snappy` | `spring(stiffness = Medium, dampingRatio = 0.85f)` |
| `ease-out` | `.easeOut(duration: 0.3)` | `tween(300, LinearOutSlowInEasing)` |
| `ease-in` | `.easeIn(duration: 0.2)` | `tween(200, FastOutLinearInEasing)` |
| bouncy spring | `.bouncy` (iOS 17+) | `spring(stiffness = Low, dampingRatio = MediumBouncy)` |
| smooth spring | `.smooth` (iOS 17+) | `spring(stiffness = Medium, dampingRatio = NoBouncy)` |

### CSS keywords & recipes

| Keyword / name | Value | Use |
|---|---|---|
| `ease-in` | `(0.42, 0, 1, 1)` | **exits only** |
| `ease-out` | `(0, 0, 0.58, 1)` | **entries** |
| `ease-in-out` | `(0.42, 0, 0.58, 1)` | state change |
| Snappy UI | `(0.2, 0, 0, 1)` | modals, drawers |
| Material | `(0.4, 0, 0.2, 1)` | general |
| Vercel/Geist | `(0.16, 1, 0.3, 1)` | snappy + soft land |
| Overshoot | `(0.34, 1.56, 0.64, 1)` | playful entry |

### GSAP / Framer decision matrix

| Scenario | CSS | GSAP | Framer Motion |
|---|---|---|---|
| Hover/focus | `ease-out` / snappy bezier | `power2.out` | `tween`, `easeOut` |
| Modal enter | Geist bezier | `power3.out` / `back.out(1.4)` | spring 300/25 |
| Modal exit | `ease-in` | `power2.in` | tween 150ms `easeIn` |
| Stagger | `ease-out` | `power2.out` + `stagger: 0.05` | spring + `stagger(0.05)` |
| Scroll | `linear` | `none` | `useScroll` |
| Playful | `linear()` bounce | `bounce.out` / `elastic.out` | spring 600/15 |

### Spring presets (Framer)

| Preset | stiffness | damping | Use |
|---|---|---|---|
| Snappy UI | 400 | 30 | buttons, menus |
| Default | 100 | 10 | general entries |
| Gentle | 120 | 14 | cards, modals |
| Bouncy | 600 | 15 | playful |
| Slow | 50 | 10 | page transitions |

## Reduced motion — MANDATORY

| Platform | API |
|---|---|
| Web CSS | `@media (prefers-reduced-motion: reduce)` |
| Web JS | `matchMedia('(prefers-reduced-motion: reduce)')` |
| SwiftUI | `@Environment(\.accessibilityReduceMotion)` |
| UIKit | `UIAccessibility.isReduceMotionEnabled` |
| Compose | `ValueAnimator.areAnimatorsEnabled()` (API 26+); fallback `ANIMATOR_DURATION_SCALE == 0f` |

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

**Also:** focus never hidden by motion; contrast OK every frame; looping motion needs pause control.

## Iron rules (never break)

| # | Rule | BAD | GOOD |
|---|---|---|---|
| 1 | No width/height/top/left animation | `transition: height 0.3s` | `transform: translateY()` |
| 2 | No scale to 0 | `scale(0)` | `scale(0.95)` + `opacity: 0` |
| 3 | No ease-in on entry | `animation: … ease-in` | `ease-out` or spring |
| 4 | UI interaction ≤500ms | `duration: 0.8` | `0.25` + `power2.out` |
| 5 | Never skip reduced motion | unconditional `gsap.from(...)` | guard with `prefersReduced` |

## Performance

- Animate **only** `transform` + `opacity`
- `will-change` sparingly; remove after animation
- JS: `requestAnimationFrame`, not timers for visuals
- Scroll: `animation-timeline` > `IntersectionObserver` > scroll listeners
- Test throttled CPU (4×) on low-end devices

## Enter/exit recipes

Always implement **enter + exit**. Exit shorter/subtler than enter.

| Style | Enter | Exit | Stagger | Best for |
|---|---|---|---|---|
| **Kowalski** (minimal) | opacity + `translateY(4px)`, 200ms ease-out / spring 400/30 | opacity + `translateY(2px)`, 150ms ease-in | 30–50ms | SaaS, dashboards, frequent UI |
| **Krehel** (material) | opacity + `translateY(8px)` + `blur(4px)`, 450ms `(0.16,1,0.3,1)` / spring 200/20 | opacity + `translateY(4px)` + `blur(2px)`, 250ms ease-in | 60–100ms | portfolios, landing heroes |
| **Jhey** (playful) | opacity + `scale(0.8)` + `rotate(-4deg)`, 600ms overshoot / spring 600/15 | opacity + `scale(0.9)` + `rotate(2deg)`, 300ms ease-in | 60–80ms | kids, games, playful brands |
| **Snappy** | opacity + `translateY(-8px)`, 150ms ease-out | opacity + `translateY(-4px)`, 100ms ease-in | 30–50ms | dev tools, tooltips |
| **Cinematic** | `clip-path: inset(0 100% 0 0)` → full, 800ms | reverse wipe + opacity, 500ms ease-in | 80–120ms | hero, editorial |

### Project → recipe

| Project | Primary | Stagger | Timing |
|---|---|---|---|
| SaaS / dashboard | Kowalski or Snappy | 40–60ms | 150–250ms |
| Portfolio | Krehel or Cinematic | 60–100ms | 300–600ms |
| E-commerce | Kowalski + Snappy filters | 50ms | 150–300ms |
| Landing | Krehel hero + Cinematic sections | 80–120ms | 400–800ms |
| Kids / game | Jhey | 60–80ms | 300–600ms |
| Dev tools | Snappy | 30–50ms | 100–200ms |

### Designer weighting

| Project | Primary (70–80%) | Secondary (15–25%) | Selective (5–10%) |
|---|---|---|---|
| SaaS | Kowalski | Krehel | Jhey (onboarding) |
| Portfolio | Krehel | Jhey | Kowalski (nav, forms) |
| E-commerce | Kowalski | Krehel (PDP) | Jhey (promos) |
| Dashboard | Kowalski | — | Krehel (data viz) |

**Mixing:** one philosophy per element; section boundaries OK; interactive = Kowalski; celebratory = Jhey; when in doubt → Kowalski.

## Load sub-skills

| Need | Path |
|---|---|
| Mobile UX | `.claude/skills/amaterasu/_jutsu/mobile-principles/SKILL.md` |
| Desktop UX | `.claude/skills/amaterasu/_jutsu/desktop-principles/SKILL.md` |
| Design audit | `.claude/skills/amaterasu/_jutsu/design-audit/SKILL.md` |
| GSAP | `.claude/skills/amaterasu/_jutsu/gsap/SKILL.md` |
| Framer Motion | `.claude/skills/amaterasu/_jutsu/framer-motion/SKILL.md` |
| CSS native | `.claude/skills/amaterasu/_jutsu/css-native/SKILL.md` |
| Three.js / R3F | `.claude/skills/amaterasu/_jutsu/threejs-r3f/SKILL.md` |
| Compose motion | `.claude/skills/amaterasu/_jutsu/compose-motion/SKILL.md` |
| SwiftUI motion | `.claude/skills/amaterasu/_jutsu/swiftui-motion/SKILL.md` |
| UI/UX intelligence | `.claude/skills/amaterasu/_jutsu/ui-ux-pro-max/SKILL.md` |
