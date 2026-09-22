---
name: design-audit
description: "Design audit — motion gaps, accessibility, color consistency, responsive, performance."
disable-model-invocation: true
---

# Design Audit

Final checkpoint. Load at end of creative pipeline.

## Static pass — run CLI, not hand greps

```bash
go -C .claude/skills/amaterasu/_jutsu/ui-ux-pro-max/cli run . audit .
# or: ui-ux-pro-max audit .
```

Add `--json` to post-process. `--only <check-id>` runs one check.

### Result semantics

| Status | Meaning |
|---|---|
| **findings** | check ran; report `file:line` + matched text as evidence |
| **clean** | check ran on real files; nothing matched |
| **not applicable** | no files of that type — report **not checked**, never **passed** |

**Contrast:** not in CLI. Compute from token values: `#831843 on #FDF2F8 = 9.4:1`. Body ≥4.5:1; large text + UI boundaries ≥3:1.

**CLI unavailable:** one-line note; manual partial audit in order: reduced-motion guard → exit animations → layout-property animations → focus visibility → click on non-interactive elements. State which checks could not run.

## Automated checks (evidence checklist)

| ID | Severity | Detects |
|---|---|---|
| `no-reduced-motion` | critical | no `prefers-reduced-motion` anywhere (absence = finding) |
| `animated-layout-property` | critical | `transition` on width/height/top/left/margin/padding |
| `outline-none` | critical | `outline: none/0` without replacement |
| `clickable-non-button` | critical | `onClick` on div/span/li without role/tabIndex |
| `conditional-render-no-exit` | important | `{cond && <` / ternary mount without AnimatePresence/exit |
| `hover-no-transition` | important | `:hover` without transition/animation |
| `js-driven-animation` | important | `setTimeout`/`setInterval` driving visuals (not debounce/fetch) |
| `decorative-motion-not-hidden` | nice | motion/Lottie/Canvas without aria |
| `will-change-broad` | nice | permanent `will-change` |
| `inline-style-object` | nice | `style={{` outside transform/opacity |

**Inventory (judgement, not pass/fail):** duration spread (target 3–5 distinct); easing spread (named handful).

Scans: `src`, `app`, `pages`, `components`, … — skips `node_modules`, `.next`, build output. Covers `.tsx`/`.jsx`/`.vue`/`.svelte`/`.astro`/CSS.

## Stack-specific (profiler/device — not in CLI)

### Compose
- [ ] Layout Inspector: recomposition hotspots
- [ ] Macrobenchmark: <16.67ms/frame @60fps
- [ ] Recomposition counts (API 29+); no vendor `recomposeHighlighter` in prod
- [ ] Baseline Profiles for release
- [ ] `Modifier.semantics` on custom components

### SwiftUI
- [ ] Instruments Time Profiler + Hitches (iOS 14+)
- [ ] GPU Frame Capture for Metal shaders
- [ ] `.accessibilityLabel` / `.accessibilityHint` on interactives
- [ ] Dynamic Type @200%; Reduce Motion ON

### Web
- [ ] Lighthouse + Chrome Performance panel (above CLI scope)

## Output severity buckets

### Critical (ship blocker)
- Missing reduced-motion handling
- Clickable divs without keyboard support
- `outline: none` without `:focus-visible`
- Animating layout properties

### Important (current sprint)
- Conditional render without exit (`AnimatePresence`)
- Hover without transition
- Decorative motion without `aria-hidden`
- Timer-driven animation loops
- >8 unique duration values

### Nice-to-have (backlog)
- Lists without stagger
- Inline styles without transition
- Excessive `will-change`
- Asymmetric enter/exit direction
- Oversized animation library for usage

## Load sub-skills

| Need | Path |
|---|---|
| Motion rules | `.claude/skills/amaterasu/_jutsu/motion-principles/SKILL.md` |
| Mobile rules | `.claude/skills/amaterasu/_jutsu/mobile-principles/SKILL.md` |
| Desktop rules | `.claude/skills/amaterasu/_jutsu/desktop-principles/SKILL.md` |
