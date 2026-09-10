---
name: swiftui-motion
description: "SwiftUI animation — withAnimation, transitions, matchedGeometryEffect, PhaseAnimator, KeyframeAnimator, springs, gestures."
disable-model-invocation: true
---

# SwiftUI Motion

Pair with `motion-principles` (timing/a11y) and `mobile-principles` (touch UX).

Start `withAnimation`. 3+ ordered states → `PhaseAnimator` (iOS 17+). Parallel time tracks → `KeyframeAnimator`. Custom shape interpolation → `Animatable` / `@Animatable` (Xcode 26+ macro; runtime iOS 13+).

## API pick

| Need | API |
|---|---|
| Single value | `withAnimation { }` or `.animation(_, value:)` |
| Insert/remove | `.transition` inside `if`/`switch`/`ForEach` + animated state change |
| Ordered phases | `.phaseAnimator(phases, trigger:)` |
| Time keyframes | `.keyframeAnimator(initialValue:trigger:)` |
| Hero morph | `matchedGeometryEffect(id:in:)` |
| Gesture-driven | `DragGesture` + `.offset` / `.scaleEffect` |
| Loop | `.animation(.linear.repeatForever(...), value:)` or `keyframeAnimator(repeating:)` |

## Springs (iOS 17+)

Named presets: `.snappy`, `.bouncy`, `.smooth`, `.interactiveSpring()`. Overloads: `.spring(duration:extraBounce:)`. Alt: `.spring(duration:bounce:)` — bounce 0…1.

| Preset | response / damping | Mood |
|---|---|---|
| `.snappy` | 0.5 / 0.85 | UI snap |
| `.bouncy` | 0.5 / 0.7 | playful |
| `.smooth` | 0.5 / 1.0 | calm, no bounce |
| `.interactiveSpring()` | 0.15 / 0.86 | gesture follow |

`response` = oscillation **period**, not settle time. UI band: response 0.2…0.5, damping 0.7…1.0. **Never** `dampingFraction: 0` (perpetual oscillation).

### Recipes by use case

| Use | Spec |
|---|---|
| Tap feedback | `.snappy` or response 0.2, 0.85 |
| Sheet present | response 0.45, 0.85 |
| Sheet dismiss | `.smooth` — no overshoot on exit |
| Drag follow | `.interactiveSpring()` — only during gesture |
| Hero transition | response 0.5, 0.85 |
| Celebrate (sparingly) | `.bouncy` — max 1–2 places/app |
| Looping pulse | `.linear(duration:).repeatForever(autoreverses:)` — not springs |

Centralize as `extension Animation { static let appTap = …; static let appSheet = … }` — 3–5 named springs max.

## Implicit vs explicit

```swift
// Implicit — any value change animates
Circle().scaleEffect(scale).animation(.spring(.snappy), value: scale)

// Explicit — user-triggered
Button("Grow") { withAnimation(.smooth) { scale = 1.5 } }
```

Prefer explicit on user actions. Implicit when value updates from anywhere (progress bar). **Never both on same property** — outer `withAnimation` wins, implicit still fires = unpredictable.

## Transitions

Run when parent animation context fires — wrap mutation in `withAnimation`.

```swift
if visible {
    Card().transition(.asymmetric(
        insertion: .move(edge: .bottom).combined(with: .opacity),
        removal: .opacity.animation(.easeIn(duration: 0.15))
    ))
}
```

Built-ins: `.move`, `.opacity`, `.scale`, `.slide`, `.push`, `.asymmetric`, `.combined(with:)`. iOS 17+ custom via `Transition` protocol.

| BAD | GOOD |
|---|---|
| `.transition(.scale)` — scales to 0, "black hole" | `.scale(scale: 0.95).combined(with: .opacity)` |

## matchedGeometryEffect

Same `id` in `@Namespace`. Interpolates frame/position when source replaced.

```swift
struct Gallery: View {
    @Namespace private var ns
    @State private var expanded = false
    var body: some View {
        ZStack {
            if expanded {
                LargeCard().matchedGeometryEffect(id: "card", in: ns)
                    .onTapGesture { withAnimation(.spring(.smooth)) { expanded = false } }
            } else {
                SmallCard().matchedGeometryEffect(id: "card", in: ns)
                    .onTapGesture { withAnimation(.spring(.smooth)) { expanded = true } }
            }
        }
    }
}
```

Gotchas: stable ids (not indices); both branches in hierarchy during transition; `isSource: true` on source-of-truth view; id collisions across namespaces.

## PhaseAnimator (iOS 17+)

Sequential phases — `Phase: Equatable` (`CaseIterable` optional for `.allCases`). Never parallel within one animator.

```swift
enum SuccessPhase: CaseIterable { case start, scaleUp, rotate, settle }

Image(systemName: "checkmark.circle.fill")
    .phaseAnimator(SuccessPhase.allCases, trigger: trigger) { view, phase in
        view
            .scaleEffect(phase == .start ? 0 : phase == .settle ? 1 : 1.2)
            .rotationEffect(.degrees(phase == .rotate ? 360 : 0))
            .opacity(phase == .start ? 0 : 1)
    } animation: { phase in
        switch phase {
        case .start: .smooth(duration: 0.05)
        case .scaleUp: .spring(.bouncy, blendDuration: 0.25)
        case .rotate: .spring(response: 0.4, dampingFraction: 0.8)
        case .settle: .smooth(duration: 0.2)
        }
    }
```

- No `trigger:` → walks phases once on appear, stops on last.
- `trigger:` → re-runs from phase[0] on change. **Increment counter**, don't toggle Bool (dedupes rapid taps).
- Enter = choreography (stagger OK). Exit = uniform — never stagger exit.
- Need parallel props on different curves → `KeyframeAnimator`.

## KeyframeAnimator (iOS 17+)

Parallel tracks on independent timelines.

```swift
struct AnimationValues { var scale = 1.0; var rotation = Angle.zero; var opacity = 1.0 }

Image(systemName: "heart.fill")
    .keyframeAnimator(initialValue: AnimationValues(), trigger: counter) { content, v in
        content.scaleEffect(v.scale).rotationEffect(v.rotation).opacity(v.opacity)
    } keyframes: { _ in
        KeyframeTrack(\.scale) {
            SpringKeyframe(1.3, duration: 0.15)
            SpringKeyframe(1.0, duration: 0.3, spring: .bouncy)
        }
        KeyframeTrack(\.rotation) {
            CubicKeyframe(.degrees(15), duration: 0.1)
            CubicKeyframe(.degrees(-15), duration: 0.2)
            CubicKeyframe(.degrees(0), duration: 0.15)
        }
    }
```

| Keyframe type | Curve |
|---|---|
| `LinearKeyframe` | constant velocity |
| `SpringKeyframe` | spring settle (+ optional `spring:`) |
| `CubicKeyframe` | cubic ease |
| `MoveKeyframe` | jump cut, no interpolation |

`keyframeAnimator(initialValue:repeating:)` — ambient loop, no trigger. Equal track durations = clean repeat. Trigger re-runs from `initialValue` — don't read end state synchronously.

### Loader example (repeating)

```swift
.keyframeAnimator(initialValue: LoaderValues(), repeating: true) { c, v in
    c.rotationEffect(v.rotation).scaleEffect(v.scale).opacity(v.opacity)
} keyframes: { _ in
    KeyframeTrack(\.rotation) { LinearKeyframe(.degrees(360), duration: 1.5) }
    KeyframeTrack(\.scale) { CubicKeyframe(1.1, duration: 0.75); CubicKeyframe(1.0, duration: 0.75) }
}
```

Nest `KeyframeAnimator` inside `phaseAnimator` content for exotic compositions.

## Animatable / @Animatable

Custom interpolation for shapes/drawings.

```swift
struct ProgressRing: Shape {
    var progress: Double  // 0...1
    var animatableData: Double { get { progress } set { progress = newValue } }
    func path(in rect: CGRect) -> Path { /* arc to progress */ }
}
ProgressRing(progress: p).stroke(.tint, lineWidth: 6).animation(.spring(.smooth), value: p)
```

Multi-prop: `AnimatablePair<A,B>` or nested pairs. `@Animatable` macro (Xcode 26+) synthesizes from `VectorArithmetic` properties; `@AnimatableIgnored` opts out. Back-deploys to iOS 13+.

## Gestures

| Gesture | Use |
|---|---|
| `TapGesture(count:)` | tap / double-tap |
| `LongPressGesture(minimumDuration:)` | context menu; `maximumDistance` default 10pt |
| `DragGesture(minimumDistance:)` | 0=immediate/steals taps; 10=default; 30+=intentional only |
| `MagnifyGesture` / `RotateGesture` | iOS 17+ (replaces Magnification/Rotation) |
| `SpatialTapGesture` | tap + location (iOS 16+) |

Composition: `.simultaneously(with:)` (pan+zoom), `.sequenced(before:)` (long-press then drag), `.exclusively(before:)` (one wins).

`.simultaneousGesture(_, including:)` masks: `.gesture`, `.subviews`, `.all`, `.none`.

### Conflict resolution

**Scroll vs horizontal swipe:**

```swift
DragGesture(minimumDistance: 10).onChanged { value in
    guard abs(value.translation.width) > abs(value.translation.height) * 1.5 else { return }
    offset = value.translation.width
}
```

**iOS back swipe:** ignore `startLocation.x < 30`.

### Velocity / fling

`predictedEndTranslation`, `predictedEndLocation`, `velocity` (iOS 17+, pt/s).

```swift
.onEnded { value in
    if value.predictedEndTranslation.width > 100 {
        withAnimation(.spring(.smooth)) { offset.width = 1000; dismiss() }
    } else { withAnimation(.interactiveSpring()) { offset = .zero } }
}
```

### Common patterns

**Swipe-dismiss sheet** — drag down only, threshold via `predictedEndTranslation.height`.

**Pull-to-refresh** — `.refreshable { await reload() }` (iOS 15+). Don't reinvent with DragGesture.

**Pinch-zoom** — `MagnifyGesture`, clamp 1…4, track `lastScale` on end.

**Double-tap zoom** — `TapGesture(count: 2)` + `.simultaneously(with: magnify)`.

## Anti-patterns

### Deprecated implicit animation

```swift
// BAD — deprecated iOS 15+
Circle().scaleEffect(scale).animation(.easeInOut)

// GOOD
Circle().scaleEffect(scale).animation(.easeInOut, value: scale)
// or withAnimation { scale = 1.5 }
```

### Frame animation

```swift
// BAD — layout every frame
Card().frame(height: expanded ? 400 : 100).animation(.spring(), value: expanded)

// GOOD
Card().frame(height: 400).scaleEffect(expanded ? 1 : 0.4, anchor: .top).animation(.spring(), value: expanded)
// or matchedGeometryEffect for real layout morph
```

### Scale to 0 transition

```swift
// BAD
Card().transition(.scale)

// GOOD
Card().transition(.scale(scale: 0.95).combined(with: .opacity))
```

### withAnimation in body

```swift
// BAD
var body: some View {
    let _ = withAnimation(.spring()) { scale = 1.2 }
    Circle().scaleEffect(scale)
}

// GOOD — .onTapGesture / .onChange
```

### Spatial spring on color

```swift
// BAD — bouncy alpha
.animateColor(..., animationSpec: .defaultSpatialSpec())  // Compose analogue; in SwiftUI use effects-style damping 1.0
```

## Reduced motion

```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

Text("Welcome")
    .opacity(shown ? 1 : 0)
    .offset(y: shown ? 0 : (reduceMotion ? 0 : 20))
    .animation(reduceMotion ? .none : .spring(.smooth), value: shown)
```

Allow opacity/crossfade. Kill large translation, scale-from-zero, parallax, loops.

## Gesture recipes (folded)

**Swipe-dismiss modal:**

```swift
@State private var dragOffset: CGFloat = 0
VStack { /* sheet */ }
    .offset(y: dragOffset)
    .gesture(DragGesture(minimumDistance: 10)
        .onChanged { dragOffset = max(0, $0.translation.height) }
        .onEnded { value in
            if value.predictedEndTranslation.height > 150 {
                withAnimation(.spring(.smooth)) { dragOffset = 800 }; onDismiss()
            } else { withAnimation(.spring(.snappy)) { dragOffset = 0 } }
        })
```

**Press-then-drag (reorder pattern):**

```swift
LongPressGesture(minimumDuration: 0.3).sequenced(before: DragGesture())
    .onChanged { value in
        if case .second(_, let drag?) = value { offset = drag.translation }
    }
```

**Pinch + rotate canvas:**

```swift
.gesture(drag.simultaneously(with: magnify.simultaneously(with: rotate)))
```

Track `lastScale` / `lastRotation` on `.onEnded` for composed successive gestures.

## Phase vs Keyframe pick

| Need | Pick |
|---|---|
| 3+ ordered states, spring between each | PhaseAnimator |
| Parallel tracks, precise durations | KeyframeAnimator |
| Loop on appear | PhaseAnimator (no trigger) or KeyframeAnimator(repeating:) |
| Re-fire on action | both via `trigger:` counter increment |
| Custom Shape value | Animatable protocol |

CustomAnimation protocol (iOS 17+) — brand-specific velocity curves; 99% of work = built-in springs + keyframes.
