---
name: compose-graphics
description: "Advanced Compose visuals — M3 Expressive MotionScheme, AGSL shaders (API 33+), Canvas/DrawScope, graphicsLayer effects."
disable-model-invocation: true
---

# Compose Graphics

Foundation: `compose-motion`. Escalate: tokens → `graphicsLayer`/`blur` → `Canvas` → AGSL (Android 13+ only).

## API pick

| Need | API |
|---|---|
| Brand spring physics | `MotionScheme.expressive()` on theme |
| Pixel shader | `RuntimeShader` + `graphicsLayer { renderEffect }` (API 33+) |
| Paths/particles/fractals | `Canvas { drawScope → }` |
| GPU blur/shadow/filter | `graphicsLayer { renderEffect }` / `Modifier.blur` |
| Adaptive materials | `MaterialTheme.colorScheme.surfaceContainerHighest` |
| Liquid glass (Android) | AGSL + upstream `blur` — no native iOS-style API |

## M3 Expressive

2025 M3 evolution: springs replace fixed tweens; shape morph via `androidx.graphics.shapes` + material3 `MaterialShapes`.

| Scheme | Use |
|---|---|
| `MotionScheme.standard()` | Chrome, lists, nav — default |
| `MotionScheme.expressive()` | Hero, FAB, primary CTA — 1–3% UI |

Stable in material3 **1.4.0** (`MotionScheme`, theme). `MaterialShapes` + morph helpers = **1.5.0-alpha** + `@OptIn(ExperimentalMaterial3ExpressiveApi)`.

### Tokens (damping/stiffness)

| Token | Spatial standard | Spatial expressive | Effects (both) |
|---|---|---|---|
| fast | 0.9/1400 | 0.6/800 | 1.0/3800 |
| default | 0.9/700 | 0.8/380 | 1.0/1600 |
| slow | 0.9/300 | 0.8/200 | 1.0/800 |

**Spatial** = position/size (may overshoot). **Effects** = alpha/color (critically damped). Only spatial differs between schemes.

```kotlin
MaterialTheme(motionScheme = MotionScheme.expressive()) {
    val t = updateTransition(expanded, label = "expand")
    val height by t.animateDp({ MaterialTheme.motionScheme.slowSpatialSpec() }, label = "h") { if (it) 400.dp else 100.dp }
    val alpha by t.animateFloat({ MaterialTheme.motionScheme.defaultEffectsSpec() }, label = "a") { if (it) 1f else 0f }
    Card(Modifier.fillMaxWidth().height(height).clickable { expanded = !expanded }) {
        Box(Modifier.alpha(alpha)) { Text("Detail", Modifier.padding(24.dp)) }
    }
}
```

### Shape morph

- `graphics-shapes` 1.1.0: `RoundedPolygon`, `CornerRounding`, `Morph` → `android.graphics.Path`
- material3 alpha: `MaterialShapes.*`, `Morph.toPath()` → Compose `Path`, `toShape()` for static

**MaterialShapes normalized 0..1** — must scale to draw size:

```kotlin
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
private class MorphShape(private val morph: Morph, private val progress: Float) : Shape {
    override fun createOutline(size: Size, ld: LayoutDirection, density: Density): Outline {
        val path = morph.toPath(progress)
        path.transform(Matrix().apply { scale(size.width, size.height) })
        path.translate(size.center - path.getBounds().center)
        return Outline.Generic(path)
    }
}

@Composable
fun MorphingBadge(active: Boolean) {
    val morph = remember { Morph(MaterialShapes.Circle, MaterialShapes.Cookie4Sided) }
    val progress by animateFloatAsState(if (active) 1f else 0f, MaterialTheme.motionScheme.slowSpatialSpec(), label = "morph")
    Box(Modifier.size(96.dp).clip(MorphShape(morph, progress)).background(MaterialTheme.colorScheme.primary))
}
```

Static → `MaterialShapes.Cookie4Sided.toShape()`. Never `.asAndroidPath().asComposePath()` round trip.

### Choreography

- **Sequential reveal:** stagger 50ms/item with `produceState` + `delay(index * 50L)` + `AnimatedVisibility`
- **Hero-first:** hero at t=0, supporting +150ms
- **Exit:** uniform `slowEffectsSpec()` — never stagger exit

Override tokens only for brand signature springs or a11y — not ad-hoc per screen.

## AGSL (API 33+)

Gate every use: `if (Build.VERSION.SDK_INT >= TIRAMISU)`.

```kotlin
@Composable
fun ShaderEffect(content: @Composable () -> Unit) {
    if (Build.VERSION.SDK_INT < 33) { content(); return }
    val shader = remember { RuntimeShader(AGSL_SOURCE) }
    val time by produceState(0f) { while (true) { withFrameMillis { value = it / 1000f } } }
    Box(Modifier.onSizeChanged { shader.setFloatUniform("resolution", it.width.toFloat(), it.height.toFloat()) }
        .graphicsLayer {
            shader.setFloatUniform("time", time)
            renderEffect = RenderEffect.createRuntimeShaderEffect(shader, "image").asComposeRenderEffect()
        }) { content() }
}
```

Syntax: `uniform`, `half4 main(float2 fragCoord)`, `image.eval(coord)`. Use `half` for color, `float` for geometry.

### Touch ripple

```glsl
uniform float2 resolution; uniform float2 origin; uniform float time; uniform shader image;
half4 main(float2 fragCoord) {
    float2 toOrigin = fragCoord - origin;
    float dist = length(toOrigin);
    float wave = sin(dist * 0.05 - time * 8.0) * 0.05;
    float falloff = 1.0 / max(dist * 0.01, 1.0);
    float2 dir = toOrigin / max(dist, 0.0001);
    return image.eval(fragCoord + dir * wave * falloff * 50.0);
}
```

Bind: tap sets `origin`, `startMs` drives `time` via `withFrameMillis`. Duration 1.0–2.0s typical.

### Holographic

Phase-shifted RGB × luma — shimmer over text/icons. `time` or scroll drives phase.

### Glass / glassmorphism

Chromatic aberration (R/G/B offset) + edge tint in AGSL. **Pair with** `Modifier.blur(20.dp, BlurredEdgeTreatment.Unbounded)` upstream — platform blur cheaper than in-shader.

```glsl
uniform float2 resolution; uniform shader image;
half4 main(float2 fragCoord) {
    float2 uv = fragCoord / resolution;
    float2 ca = (uv - 0.5) * 0.004;
    half r = image.eval(fragCoord + ca * resolution).r;
    half g = image.eval(fragCoord).g;
    half b = image.eval(fragCoord - ca * resolution).b;
    float edge = smoothstep(0.45, 0.5, max(abs(uv.x-0.5), abs(uv.y-0.5)));
    return half4(half3(r,g,b) + half3(edge * 0.08), 0.85);
}
```

### Other recipes

| Shader | Idea | Params |
|---|---|---|
| Glow halo | `smoothstep(threshold)` luminance boost | threshold 0.7, strength 2–3 |
| Heat haze | hash noise displacement | intensity 4–12px, animated time |
| Film grain | `hash3(fragCoord, time)` overlay | intensity 0.04–0.1 |
| Tilt foil | anisotropic stripes × tilt vector | accelerometer or drag |

**Combine:** fold always-on effects into one shader (1 pass). Chain max 2 passes if toggled independently.

**Perf:** each `RuntimeShader` = render pass. `image.eval` on complex views = expensive. Cache static subtrees. Benchmark Macrobenchmark. Pre-33: fallback gradient/blur/static — never crash.

## Canvas / DrawScope

```kotlin
Canvas(Modifier.size(200.dp)) {
    drawCircle(Color.Blue, radius = size.minDimension / 2)
    drawPath(path, Color.White, Stroke(4.dp.toPx()))
    drawArc(...); drawLine(...); drawText via TextMeasurer
    drawIntoCanvas { it.nativeCanvas.drawText(...) }  // escape hatch
}
```

| Method | Use |
|---|---|
| `drawCircle/Rect/Path/Arc/Line` | primitives |
| `drawIntoCanvas` | raw `android.graphics.Canvas` |

### Animated sine wave

```kotlin
val phase by rememberInfiniteTransition(label = "wave").animateFloat(
    0f, 2 * PI.toFloat(), infiniteRepeatable(tween(3000, LinearEasing)), label = "phase")
Canvas(Modifier.fillMaxWidth().height(80.dp)) {
    val path = Path(); var x = 0
    while (x <= size.width.toInt()) {
        val y = size.height/2 + sin(x * 0.05f + phase) * 20f
        if (x == 0) path.moveTo(x.toFloat(), y) else path.lineTo(x.toFloat(), y); x += 2
    }
    drawPath(path, Color.Blue, Stroke(2.dp.toPx()))
}
```

### Particles (~50)

`LaunchedEffect` + `withFrameMillis` mutate positions; draw circles. Cap count. 200 draws/frame OK; 2000+ lag.

### Flow field

Hash noise angle field advects particles. See sin-hash for cheap runtime; Perlin for production.

### L-system

String rewrite + turtle graphics in DrawScope. Iterations 4–5 max (exponential string growth).

**Animate:** `withFrameMillis` not `delay(16)` (drifts). Precompute static paths in `remember`; animate transforms only.

## Anti-patterns

### Expressive everywhere

```kotlin
// BAD — bouncy castle
MaterialTheme(motionScheme = MotionScheme.expressive()) { AppRoot() }

// GOOD — local hero override
MaterialTheme(motionScheme = MotionScheme.standard()) {
    NavigationScaffold {
        MaterialTheme(motionScheme = MotionScheme.expressive()) { HeroDetail() }
    }
}
```

### RuntimeShader without gate

```kotlin
// BAD — crash API <33
val shader = remember { RuntimeShader(AGSL) }

// GOOD
if (Build.VERSION.SDK_INT >= TIRAMISU) ShaderEffect { content() }
else Box(Modifier.background(fallbackGradient)) { content() }
```

### Spatial spec on effects

```kotlin
// BAD — bouncy alpha breaks
animateFloatAsState(target, MaterialTheme.motionScheme.defaultSpatialSpec())

// GOOD
animateFloatAsState(target, MaterialTheme.motionScheme.defaultEffectsSpec())
```

### Canvas state / allocation

```kotlin
// BAD — parent state triggers recompose; new Path every frame
Canvas(Modifier.fillMaxSize()) { drawCircle(if (vm.active) Red else Blue, 50f) }
Canvas { val path = Path(); points.forEach { path.lineTo(it.x, it.y) }; drawPath(path) }

// GOOD
val color by remember { derivedStateOf { if (vm.active) Red else Blue } }
val path = remember { Path() }
Canvas { path.rewind(); points.forEach { path.lineTo(it.x, it.y) }; drawPath(path, color) }
```

### Chained AGSL

```kotlin
// BAD — 4 GPU passes
.graphicsLayer { blur }.graphicsLayer { chromatic }.graphicsLayer { grain }

// GOOD — one combined shader
.graphicsLayer { combinedGlassEffect }
```

## AGSL shader catalog (folded)

All gate API 33+. Bind via `RuntimeShader` + `graphicsLayer { renderEffect = createRuntimeShaderEffect(shader, "image").asComposeRenderEffect() }`.

**Glow halo** — single-pass bloom substitute:

```glsl
uniform float threshold; uniform float strength; uniform shader image;
half4 main(float2 fragCoord) {
    half4 c = image.eval(fragCoord);
    half lum = dot(c.rgb, half3(0.299, 0.587, 0.114));
    half excess = max(lum - threshold, 0.0);
    return half4(c.rgb + c.rgb * excess * strength, c.a);
}
```

**Heat haze** — hash noise displacement:

```glsl
float hash(float2 p) { return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453); }
half4 main(float2 fragCoord) {
    float2 uv = fragCoord / resolution;
    float dx = noise(uv * 8.0 + float2(0, time * 0.6)) - 0.5;
    float dy = noise(uv * 8.0 + float2(time * 0.6, 0)) - 0.5;
    return image.eval(fragCoord + float2(dx, dy) * intensity);
}
```

**Film grain** — `hash3(float3(fragCoord, time))`, intensity 0.04–0.1.

**Tilt foil** — anisotropic stripes × `tilt` float2 from accelerometer/drag.

**Combined glass+grain** — one pass when always shipped together; inline aberration + edge tint + grain math.

## Canvas recipes (folded)

**Particle field (~50):**

```kotlin
data class Particle(var x: Float, var y: Float, var vx: Float, var vy: Float, var life: Float)
LaunchedEffect(Unit) {
    while (true) {
        withFrameMillis {
            particles.forEach { p ->
                p.x += p.vx; p.y += p.vy; p.life -= 0.01f
                if (p.life <= 0f) { p.x = Random.nextFloat() * 1000f; p.y = Random.nextFloat() * 1000f; p.life = 1f }
            }
        }
    }
}
Canvas(Modifier.fillMaxSize()) { particles.forEach { drawCircle(White.copy(p.life), 2.dp.toPx(), Offset(it.x, it.y)) } }
```

**Flow field** — 150 particles, sin-hash noise angle, wrap edges. Production → Perlin/Simplex.

**L-system plant** — `F → FF+[+F-F-F]-[-F+F+F]`, iterations ≤5, turtle in DrawScope.

**Pointer trail** — spawn on move, cap 200 particles, gravity on vy.

Perf table: 200 draws/frame OK; 1000 lag mid-range; 2000+ → half rate, batch Path, or AGSL.
