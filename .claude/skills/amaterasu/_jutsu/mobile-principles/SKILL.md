---
name: mobile-principles
description: "Mobile UX — touch targets, no-hover doctrine, thumb zones, safe areas, gestures, perf budgets."
disable-model-invocation: true
---

# Mobile Principles

Touch-first context. Load for web mobile, iOS, Android.

## Touch targets

| Platform | Design to | Floor | Spacing |
|---|---|---|---|
| iOS / iPadOS / watchOS | 44×44 pt | 28×28 pt | ~12 pt bezeled, ~24 pt unbezeled |
| Android (M3) | 48×48 dp | 48×48 dp | 8 dp between |
| Web mobile | 44×44 CSS px | 24×24 CSS px (WCAG AA) | 24 px non-overlap for AA exception |

Hit area must reach minimum (padding, `hitSlop`, transparent spacer). Spacing matters as much as size.

## No-hover doctrine

`:hover` is not a primary trigger on touch. Visible-by-default; hover = desktop enhancement only.

```css
/* BAD — action never appears on phone */
.card .actions { opacity: 0; }
.card:hover .actions { opacity: 1; }

/* GOOD */
.card .actions { opacity: 1; }
@media (hover: hover) and (pointer: fine) {
  .card .actions { opacity: 0; transition: opacity 0.15s ease-out; }
  .card:hover .actions { opacity: 1; }
}
```

**SwiftUI:** `onTapGesture` + `contextMenu` — no pseudo-hover.  
**Compose:** `combinedClickable(onClick, onLongClick)`.

## Thumb zones (Hoober)

```
+------+----+------+
| HARD | OK | HARD |  top: stretch / two-hand
+------+----+------+
|  OK  | OK |  OK  |  middle: comfortable
+------+----+------+
| EASY |EASY| EASY |  bottom: natural arc
+------+----+------+
```

- **EASY (bottom third):** primary CTA, FAB, tab bar, send/confirm
- **OK (middle):** content, secondary actions
- **HARD (top):** back, close, search — expected reach, not reflex taps

Never put primary CTA (e.g. Pay) top-right.

## Safe areas

| Platform | API |
|---|---|
| Web | `env(safe-area-inset-*)` + `viewport-fit=cover` |
| SwiftUI | `.safeAreaInset(edge:)`, `safeAreaInsets` |
| Compose | `Modifier.windowInsetsPadding(WindowInsets.safeDrawing)` |

```html
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
```
```css
.fab { bottom: calc(env(safe-area-inset-bottom) + 16px); }
```

## Reduced motion

| Platform | API |
|---|---|
| Web | `prefers-reduced-motion` (CSS/JS) |
| SwiftUI | `@Environment(\.accessibilityReduceMotion)` |
| UIKit | `UIAccessibility.isReduceMotionEnabled` |
| Compose | `!ValueAnimator.areAnimatorsEnabled()` (API 26+); else `ANIMATOR_DURATION_SCALE == 0f` |

```swift
.animation(reduceMotion ? .none : .easeOut(duration: 0.3), value: shown)
```

## Canonical gestures

| Gesture | Rule |
|---|---|
| Swipe-back | iOS edge-swipe — never override. Android 13+: predictive back + `enableOnBackInvokedCallback` |
| Pull-to-refresh | Platform primitive: SwiftUI `.refreshable`, Compose `PullToRefreshBox`, web overscroll sentinel |
| Drag-to-dismiss | Sheets/viewers: threshold ~100–150pt |
| Pinch-to-zoom | Images/maps; respect min/max scale |
| Swipe actions on rows | Leading vs trailing = different actions |

### Conflict resolution

| Conflict | Fix |
|---|---|
| Vertical scroll vs horizontal swipe | First axis past threshold wins — align with platform |
| Long-press vs drag | Sequence: press then drag (`sequenced(before:)` / `detectDragGesturesAfterLongPress`) |
| Back-swipe vs custom pan | Don't bind horizontal pan in iOS leading ~20pt edge |

**Web:** Pointer Events + `touch-action`; `setPointerCapture` for custom drag. Multi-touch: `@use-gesture/react` or Hammer.js.

**Momentum:** SwiftUI `predictedEndTranslation`; Compose `animateDecay(splineBasedDecay())`; web `scroll-snap` or rAF velocity decay.

## Performance budgets

| Metric | Target |
|---|---|
| Cold start | <2s mid-range (Pixel 4a, iPhone SE 2) |
| Frame budget | 16.67ms @60fps; 8.33ms @120fps |
| Binary | <30MB APK, <50MB IPA before heavy media |
| Battery | no continuous background CPU; use `WorkManager` / `BGTaskScheduler` |
| Network | respect metered: `Save-Data`, `NWPathMonitor`, `NetworkCapabilities` |

## Anti-patterns

| # | BAD | GOOD |
|---|---|---|
| Hover-only reveal | `.card:hover .actions { opacity: 1 }` only | visible default + `@media (hover: hover)` |
| Sub-minimum target | `IconButton(Modifier.size(32.dp))` on custom hit area | 48dp touch, 24dp glyph |
| Ignoring safe area | CTA in `VStack` bottom without inset | `.safeAreaInset(edge: .bottom) { CTA }` |

## Accessibility (mobile)

| Check | Requirement |
|---|---|
| Screen readers | label + role on every control; Compose `clearAndSetSemantics`; no unlabeled icon buttons |
| Dynamic type | SwiftUI `.body` / `relativeTo:`; Compose `fontScale`; web `rem` + `clamp()` |
| Contrast | 4.5:1 normal text; 3:1 large text + UI boundaries |
| Color alone | pair with icon/label/pattern (WCAG 1.4.1) |
| Gestures | always offer button/menu/keyboard alternative |
| Motor | AssistiveTouch/Switch Access: no time-limited-only interactions |

## Load sub-skills

| Need | Path |
|---|---|
| Compose motion | `.claude/skills/amaterasu/_jutsu/compose-motion/SKILL.md` |
| SwiftUI motion | `.claude/skills/amaterasu/_jutsu/swiftui-motion/SKILL.md` |
| Motion foundation | `.claude/skills/amaterasu/_jutsu/motion-principles/SKILL.md` |
