---
name: css-native
description: "Zero-dependency animations — scroll-driven, View Transitions, @starting-style, anchor positioning."
disable-model-invocation: true
---

# CSS Native

## When to Use

| Situation | Decision |
|---|---|
| < 3 animations | CSS native |
| Scroll reveal/parallax | CSS (`animation-timeline`) inside `@supports` — content visible by default |
| Enter/exit from `display: none` | `@starting-style` + `allow-discrete` |
| Tooltip/popover positioning | Anchor positioning |
| Page transitions | View Transitions API |
| 5+ tween timeline | GSAP |
| Dynamic stagger (unknown count) | `animation-delay: calc(sibling-index() * 60ms)` |
| Spring with interruption | Framer Motion |
| SVG morph | GSAP MorphSVG |

**Rule:** expressible in `@keyframes` + one timeline → CSS. Need imperative control → library.

## Scroll-Driven

```css
.progress-bar {
  animation: grow-width linear both;
  animation-timeline: scroll(root block);
}
@keyframes grow-width { from { transform: scaleX(0); } to { transform: scaleX(1); } }

.reveal {
  animation: fade-in linear both;
  animation-timeline: view();
  animation-range: entry 0% entry 100%;
}
@keyframes fade-in {
  from { opacity: 0; transform: translateY(2rem); }
  to   { opacity: 1; transform: translateY(0); }
}
```

- `scroll(<scroller> <axis>)` — scroller: `nearest` \| `root` \| `self`; axis: `block` \| `inline` \| `x` \| `y`
- `animation-range`: `cover`, `contain`, `entry`, `exit`, `entry-crossing`, `exit-crossing`
- Scroll-driven: use `both`, not `forwards`

## View Transitions

```js
document.startViewTransition(() => updateContent());
```

```css
::view-transition-old(root) { animation: fade-out 200ms ease-out; }
::view-transition-new(root) { animation: fade-in 300ms ease-in; }
.hero-image { view-transition-name: hero; }
::view-transition-group(hero) { animation-duration: 400ms; }

/* MPA cross-document — both pages */
@view-transition { navigation: auto; }
.card { view-transition-name: card-detail; }          /* outgoing */
.detail-hero { view-transition-name: card-detail; }     /* incoming */

/* group styling */
.card { view-transition-class: card; }
::view-transition-group(*.card) { animation-duration: 350ms; }
```

## @starting-style

```css
.dialog {
  opacity: 1; transform: translateY(0);
  transition: opacity 300ms ease, transform 300ms ease, display 300ms allow-discrete;
  @starting-style { opacity: 0; transform: translateY(-1rem); }
}
.dialog[hidden] { opacity: 0; transform: translateY(-1rem); display: none; }
```

Pair with `transition-behavior: allow-discrete` for `display` / `overlay`.

## Anchor Positioning

```css
.trigger { anchor-name: --my-trigger; }
.tooltip {
  position: fixed; position-anchor: --my-trigger; position-area: top center;
  margin-bottom: 0.5rem; position-try-fallbacks: --bottom;
}
@position-try --bottom { position-area: bottom center; margin-top: 0.5rem; }
```

Combine with `@starting-style` on `[popover]:popover-open` for animated tooltips.

## Container Queries

```css
.card-container { container-type: inline-size; container-name: card; }
@container card (min-width: 400px) { .card-content { animation: slide-in-right 400ms ease; } }
@keyframes slide-in-right { from { transform: translateX(10cqw); opacity: 0; } to { transform: translateX(0); opacity: 1; } }
```

## Visual Techniques

```css
/* clip-path reveal */
.reveal { clip-path: inset(0 100% 0 0); transition: clip-path 600ms ease; }
.reveal.visible { clip-path: inset(0 0 0 0); }

/* glass */
.glass { background: oklch(0.98 0.01 250 / 0.6); backdrop-filter: blur(12px) saturate(1.8); }

/* stagger */
@supports (animation-delay: calc(sibling-index() * 1ms)) {
  li { animation: rise 400ms ease both; animation-delay: calc(sibling-index() * 60ms); }
}
```

## Browser Support

| Feature | Chrome/Edge | Firefox | Safari | Coverage |
|---|---|---|---|---|
| Scroll-driven (`animation-timeline`) | 115+ | **Not shipped** | 26+ | ~84% — guard mandatory |
| View Transitions same-doc | 111+ | 144+ | 18+ | ~90% |
| View Transitions cross-doc | 126+ | Not yet | 18.2+ | ~85% |
| `@starting-style` | 117+ | 129+ | 17.5+ | ~90% |
| `allow-discrete` display transition | 117+ | **No exit** | 18+ | Enter works; exit skipped in FF |
| Anchor positioning | 125+ | 147+ | 26+ | ~84% — guard + fallback |
| Container size queries | 105+ | 110+ | 16+ | ~94% |
| `sibling-index()` stagger | 138+ | 154+ | 26.2+ | ~80% |
| `interpolate-size` / `calc-size()` | 129+ | Not shipped | Not shipped | ~70% — bonus only |

Renames: `inset-area` → `position-area`; `position-try-options` → `position-try-fallbacks`. Auto-naming: `match-element` (not `auto`).

## Popover + @starting-style (Zero JS Modal)

```html
<button popovertarget="menu">Open</button>
<div id="menu" popover><p>Menu content</p></div>
```

```css
[popover] {
  opacity: 1; transform: translateY(0) scale(1);
  transition: opacity 250ms ease, transform 250ms ease, display 250ms allow-discrete, overlay 250ms allow-discrete;
  @starting-style { opacity: 0; transform: translateY(-0.5rem) scale(0.97); }
}
[popover]:not(:popover-open) { opacity: 0; transform: translateY(-0.5rem) scale(0.97); }
```

## Anchor + Popover Tooltip

```css
#tip-trigger { anchor-name: --trigger; }
[popover="hint"] {
  position: fixed; position-anchor: --trigger; position-area: top center;
  position-try-fallbacks: --bottom, --left, --right;
  opacity: 1; transform: translateY(0);
  transition: opacity 150ms ease, transform 150ms ease, display 150ms allow-discrete, overlay 150ms allow-discrete;
  @starting-style { opacity: 0; transform: translateY(4px); }
}
@position-try --bottom { position-area: bottom center; margin-top: 0.5rem; }
@position-try --left   { position-area: left center; margin-right: 0.5rem; }
@position-try --right  { position-area: right center; margin-left: 0.5rem; }
```

HTML `anchor` attribute is experimental — declare `anchor-name` in CSS only.

## Layered Animation Strategy

```css
.section-title { opacity: 1; transition: opacity 400ms ease, transform 400ms ease; }
.section-title.visible { opacity: 1; transform: translateY(0); }
@supports (animation-timeline: scroll()) {
  .section-title {
    animation: reveal linear both; animation-timeline: view(); animation-range: entry 0% entry 80%;
    transition: none;
  }
  @keyframes reveal { from { opacity: 0; transform: translateY(1.5rem); } to { opacity: 1; transform: translateY(0); } }
}
```

## Fallback Patterns

```css
/* scroll-driven — content always visible */
.reveal { opacity: 1; transform: translateY(0); }
@supports (animation-timeline: scroll()) {
  .reveal { animation: reveal-up linear both; animation-timeline: view(); animation-range: entry 10% entry 90%; }
}

/* anchor — absolute fallback */
@supports (anchor-name: --a) { .tooltip { position-anchor: --trigger; } }
@supports not (anchor-name: --a) { .tooltip { position: absolute; bottom: 100%; left: 50%; transform: translateX(-50%); } }
```

```js
function navigate(updateFn) {
  if (!document.startViewTransition) { updateFn(); return; }
  document.startViewTransition(updateFn);
}
```

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after { animation-duration: 0.01ms !important; transition-duration: 0.01ms !important; }
  .reveal { animation: none; opacity: 1; transform: none; }
}
```

## Performance

| Property | Cost | GPU |
|---|---|---|
| `transform`, `opacity` | Low | Yes |
| `filter`, `backdrop-filter`, `clip-path` | Medium | Yes |
| `background` gradients | Medium | No |
| `width`/`height`/`top`/`left`/`box-shadow` | High | No |

## DO NOT

| BAD | GOOD | Why |
|---|---|---|
| `transition: all 300ms` | List specific properties | Unexpected transitions |
| Animate `width`/`height`/`top`/`left` | `transform`, `opacity`, `clip-path` | Reflow every frame |
| Scroll-driven without fallback | `@supports` + visible default | ~1/6 visitors (Firefox) see nothing |
| `@starting-style` without `allow-discrete` | Pair for display/overlay | Exit/enter skipped |
| Anchor without `position-try-fallbacks` | Define fallbacks | Clips out of viewport |
| `animation-fill-mode: forwards` scroll-driven | Use `both` | Locks final state on scroll back |
| `interpolate-size` as only accordion mechanism | `grid-template-rows: 0fr→1fr` fallback | Chromium-only |
| `will-change` on 50 elements | Only on imminent animators | Wastes memory |
