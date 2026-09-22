---
name: swiftui-graphics
description: "Advanced SwiftUI visuals — Metal shaders (.colorEffect/.layerEffect/.distortionEffect), .visualEffect, Liquid Glass (iOS 26), Canvas."
disable-model-invocation: true
---

# SwiftUI Graphics

Foundation: `swiftui-motion`. Escalate: built-in modifiers → `.visualEffect` → `Canvas` → Metal (iOS 17+, not watchOS).

## API pick

| Need | API |
|---|---|
| Per-pixel color | `.colorEffect(ShaderLibrary.*)` |
| Displacement | `.distortionEffect(..., maxSampleOffset:)` |
| Layer sample | `.layerEffect(..., maxSampleOffset:)` |
| Geometry context | `.visualEffect { content, proxy in }` |
| Vector draw | `Canvas { context, size in }` |
| iOS 26 glass | `.glassEffect()` in `GlassEffectContainer` |

Default order: built-ins → visualEffect → Canvas → shader (per-pixel + animated).

## Metal shaders (iOS 17+)

Author `.metal` in app target. Mark `[[ stitchable ]]`. SwiftUI generates `ShaderLibrary.<fn>(...)`.

Availability: iOS/iPadOS 17+, macOS 14+, tvOS 17+, visionOS 1+ — **not watchOS**.

| Slot | Receives | Does |
|---|---|---|
| `.colorEffect` | `(position, color)` | transform color, no neighbors |
| `.distortionEffect` | `(position)` | return new sample point |
| `.layerEffect` | `(position, Layer)` | sample anywhere within `maxSampleOffset` — most expensive |

Args from Swift: `.float`, `.float2`, `.color`, `.image`. Use `half` for color math, `float` for geometry.

```metal
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;
```

First two args of layer/distortion shaders injected by SwiftUI; your args start at index 2.

## Metal recipes

### 1. Ripple (layerEffect)

```metal
[[ stitchable ]]
half4 ripple(float2 position, SwiftUI::Layer layer, float2 origin, float time, float amp) {
    float dist = length(position - origin);
    float wavefront = dist - time * 200.0;
    float wave = sin(wavefront * 0.05) * amp * exp(-time * 1.5) * exp(-abs(wavefront) * 0.005);
    float2 dir = normalize(position - origin);
    float2 displaced = position + dir * wave * clamp(50.0 / max(dist, 1.0), 0.0, 50.0);
    return layer.sample(displaced);
}
```

```swift
.layerEffect(ShaderLibrary.ripple(.float2(Float(origin.x), Float(origin.y)), .float(time), .float(0.05)),
    maxSampleOffset: CGSize(width: 50, height: 50))
.onTapGesture { location in origin = location; time = 0; withAnimation(.linear(duration: 1.5)) { time = 1.5 } }
```

`maxSampleOffset` ≥ actual displacement. Underestimate = clip; overestimate = waste.

### 2. Holographic (colorEffect)

```metal
[[ stitchable ]]
half4 holographic(float2 position, half4 color, float scroll) {
    float n = position.x * 0.01 + position.y * 0.005 + scroll * 0.3;
    half3 rainbow = half3(sin(n*2)*0.5+0.5, sin(n*2+2.094)*0.5+0.5, sin(n*2+4.188)*0.5+0.5);
    half lum = dot(color.rgb, half3(0.299, 0.587, 0.114));
    return half4(mix(color.rgb, rainbow * lum * 2.0, 0.5), color.a);
}
```

Drive via `TimelineView(.animation)` or drag gesture on `scroll`. Offsets 2.094/4.188 = 2π/3, 4π/3.

### 3. CRT (layerEffect for true chromatic)

```metal
[[ stitchable ]]
half4 crt(float2 position, SwiftUI::Layer layer, float time) {
    float scanline = sin(position.y * 1.5) * 0.04;
    float flicker = sin(time * 60.0) * 0.02;
    half r = layer.sample(position + float2(1.5, 0)).r;
    half g = layer.sample(position).g;
    half b = layer.sample(position - float2(1.5, 0)).b;
    return half4(half3(r,g,b) * (1.0 - scanline - flicker), layer.sample(position).a);
}
```

Four samples/pixel — profile on iPhone 12 and below at full screen.

### 4. Glow halo (colorEffect)

```metal
[[ stitchable ]]
half4 glow(float2 position, half4 color, float threshold, float strength) {
    half lum = dot(color.rgb, half3(0.299, 0.587, 0.114));
    half mask = smoothstep(threshold, threshold + 0.1, lum);
    return half4(color.rgb + color.rgb * mask * strength, color.a);
}
```

Pair with `.blur(radius:)` duplicate layer for true bloom.

### 5. Heat haze (distortionEffect)

Hash noise displacement — `strength` 4–8px typical. Sample noise texture on older devices if hot.

### 6. Film grain (colorEffect)

```metal
[[ stitchable ]]
half4 grain(float2 position, half4 color, float time, float strength) {
    float n = fract(sin(dot(float3(position * 0.5, time * 10.0), float3(127.1, 311.7, 74.7))) * 43758.5453);
    return half4(color.rgb + half3(n - 0.5) * strength, color.a);
}
```

strength 0.05–0.15 subtle; 0.2+ aggressive.

### Combining

**A. Single shader (best)** — inline all ops in one `[[ stitchable ]]`.

**B. Stacked modifiers** — max 2 if toggled independently. Prototype stacked → collapse for ship.

Pass colors from Swift — no hardcoded tints in MSL:

```metal
// BAD: half3 tint = half3(1.0, 0.4, 0.2);
// GOOD: half4 tinted(float2 pos, half4 color, half4 tint) { return half4(color.rgb * tint.rgb, color.a); }
```

## .visualEffect (iOS 17+)

Read-only geometry — **cannot write @State** inside.

```swift
ScrollView {
    LazyVStack {
        ForEach(items) { item in
            CardView(item: item)
                .visualEffect { content, proxy in
                    let y = proxy.frame(in: .scrollView).minY
                    return content
                        .scaleEffect(0.85 + max(0, min(1, y/600)) * 0.15)
                        .opacity(max(0, min(1, y/600)))
                }
        }
    }
}
```

Parallax, scroll-scale cards, sticky reveal via `.offset(y: max(0, -y))`.

## Liquid Glass (iOS 26+)

System glassmorphism: adaptive depth, refraction, morphing. Metal stack optimized by OS.

| API | Purpose |
|---|---|
| `.glassEffect(.regular/.clear/.identity)` | Frosted (default capsule shape via `in:`) |
| `.glassEffect(.regular.tint(.blue).interactive())` | Refined variant |
| `.glassEffectID(_:in:)` | Morph pair — **only inside container** |
| `GlassEffectContainer(spacing:)` | Merge/split glass shapes by spacing |
| `.glassEffectTransition(.matchedGeometry/.materialize)` | Add/remove transition |
| `.buttonStyle(.glass)` / `.glassProminent` | System glass buttons |
| `.glassBackgroundEffect` | **visionOS only** — not iOS |

### Glass card morph

```swift
@Namespace var glassNS
@State var expanded = false

GlassEffectContainer(spacing: 40) {
    if !expanded {
        Image("hero").resizable().frame(width: 200, height: 280)
            .glassEffect(.regular).glassEffectID("hero", in: glassNS)
            .onTapGesture { withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { expanded = true } }
    } else {
        VStack { Image("hero").resizable(); Text("Details").font(.title) }
            .padding().frame(maxWidth: .infinity, maxHeight: .infinity)
            .glassEffect(.regular).glassEffectID("hero", in: glassNS)
    }
}
```

### Glass tab bar

Floating bar over scroll content — `.glassEffect(.regular, in: .capsule)` at bottom. Cells underneath use solid/material, not glass.

### Pre-iOS 26 fallback

| iOS 26 | Fallback |
|---|---|
| `.glassEffect(.clear)` | `.background(.ultraThinMaterial)` |
| `.glassEffect(.regular)` | `.background(.regularMaterial)` |
| `.glassEffectID` | `matchedGeometryEffect` on material view |
| `GlassEffectContainer` | Manual ZStack + namespace |

No true refraction, adaptive transparency, or edge highlights pre-26.

### Glass gotchas

| BAD | GOOD |
|---|---|
| Glass on glass (nested) | `GlassEffectContainer` — one pass |
| Glass over flat white/black | Glass over photo/gradient — nothing to refract |
| Glass per LazyVStack row | Glass on chrome only; cells opaque/material |

## Canvas

```swift
Canvas { context, size in
    context.fill(Path(ellipseIn: rect), with: .color(.white))
    context.stroke(path, with: .color(.cyan), lineWidth: 2)
    context.draw(image, in: rect)
    context.draw(Text("Hi"), at: point)
    context.blendMode = .plusLighter
    context.addFilter(.blur(radius: 4))
} symbols: {
    Image(systemName: "star.fill").tag("star")
}
```

Animate via `TimelineView(.animation)` — Canvas doesn't self-animate.

| Schedule | Use |
|---|---|
| `.animation` | 60–120Hz visual |
| `.animation(minimumInterval: 0.1)` | power save |
| `.periodic(from:by:)` | clocks |
| `.explicit([dates])` | manual |

### Recipes

**Sparkle field** — stable per-sparkle phase, sin alpha loop.

**Sine wave** — path built with stride, stroke.

**Particle trail** — `DragGesture(minimumDistance: 0)`, cap trail length (~30).

**Gradient mesh** — moving radial anchors, `.plusLighter` blend.

**Particles (50+)** — Canvas OK iPhone 11+; 500+ → Metal or SpriteKit.

Isolate from parent state: `TimelineView`, `EquatableView`, `.drawingGroup()` (disables hit testing). Cache `resolveSymbol` if static.

## Canvas vs Metal

| Need | Tool |
|---|---|
| Paths, gradients, text, <500 shapes | Canvas |
| Per-pixel color | `.colorEffect` |
| Displacement, ripples | `.distortionEffect` / `.layerEffect` |
| Dense particles, fluids | Metal or SpriteKit |

Vectors → Canvas. Per-pixel → Metal.

## Performance

| Effect | Cost |
|---|---|
| `.colorEffect` | Low |
| `.distortionEffect` | Medium |
| `.layerEffect` | High |
| Canvas + TimelineView | Varies |
| `.glassEffect` | Medium-high |

Rules: max 1 `.layerEffect`/view; precompute static paths; Instruments GPU Frame Capture / Metal System Trace.

## Anti-patterns

### Stacked colorEffects

```swift
// BAD — 5 GPU passes
Image(...).colorEffect(tint).colorEffect(scanlines).colorEffect(grain).colorEffect(vignette)

// GOOD
Image(...).colorEffect(ShaderLibrary.crtCombo(.float(time)))
```

### Canvas on parent state

```swift
// BAD
VStack { Button("tick") { n += 1 }; Canvas { expensiveDraw } }

// GOOD
TimelineView(.animation) { _ in Canvas { expensiveDraw } }
```

### Hardcoded shader colors

Pass via `.color(themeAccent)` from Swift.

### Glass everywhere

```swift
// BAD
LazyVStack { ForEach(items) { Card($0).glassEffect(.regular) } }

// GOOD
ZStack { ScrollView { opaque cards }; TabBar().glassEffect(.regular) }
```

## Metal catalog (folded)

| # | Name | Modifier | Params |
|---|---|---|---|
| 1 | Ripple | layerEffect | origin, time, amp |
| 2 | Holographic | colorEffect | scroll/time |
| 3 | CRT | layerEffect | time; 3–4 samples |
| 4 | Glow | colorEffect | threshold, strength |
| 5 | Heat haze | distortionEffect | time, strength 4–8 |
| 6 | Particles | Canvas+TimelineView | 50 fills OK |
| 7 | Grain | colorEffect | time, strength 0.05–0.15 |

Port GLSL Shadertoy → MSL: `vec*`→`float*`/`half*`, `texture()`→`layer.sample()`, use `fragCoord` param not `gl_FragCoord`.

## Liquid Glass recipes (folded)

**Tab bar over scroll:**

```swift
ZStack(alignment: .bottom) {
    ScrollView { LazyVStack { ForEach(0..<50) { Card(index: $0) } }.padding() }
    HStack(spacing: 32) { /* tab icons */ }
        .padding(.horizontal, 24).padding(.vertical, 12)
        .glassEffect(.regular, in: .capsule).padding(.bottom, 16)
}
```

**Modal stack depth** — `.clear` outer sheet, `.regular` inner = heavier frost signals depth.

**Adaptive helper:**

```swift
@ViewBuilder func adaptiveGlass<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
    if #available(iOS 26.0, *) { content().glassEffect(.regular) }
    else { content().background(.regularMaterial) }
}
```

## Canvas recipes (folded)

**Sparkle field** — 30 sparkles, per-sparkle `phase`, `alpha = (sin(t*2+phase)+1)/2`.

**Gradient mesh** — two moving radial gradient anchors, `.plusLighter`.

**Symbol drawing:**

```swift
Canvas { ctx, size in
    if let star = ctx.resolveSymbol(id: "star") { ctx.draw(star, at: CGPoint(x: 50, y: 50)) }
} symbols: { Image(systemName: "star.fill").tag("star").foregroundStyle(.yellow) }
```

Precompute paths outside closure. `drawingGroup()` for heavy nested hierarchies — loses hit testing.
