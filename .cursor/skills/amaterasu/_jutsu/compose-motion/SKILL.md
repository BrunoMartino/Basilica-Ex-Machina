---
name: compose-motion
description: "Jetpack Compose animation — animate*AsState, AnimatedVisibility, Crossfade, updateTransition, SharedTransitionLayout, gestures, recomposition perf."
disable-model-invocation: true
---

# Compose Motion

Baseline: Compose BOM 2026.08.x (Compose 1.12). Modern APIs only — no `swipeable`; use `anchoredDraggable` (1.6+).

## API pick

| Need | API |
|---|---|
| Single value | `animateFloatAsState`, `animateDpAsState`, `animateColorAsState`, `animateValueAsState` |
| Mount/unmount | `AnimatedVisibility(visible) { }` |
| Fade swap | `Crossfade(target) { }` — no size anim |
| Multi-prop sync | `updateTransition(target).animateFloat { }` |
| Interrupt/chain/fling | `Animatable` + `animateTo` / `animateDecay` |
| Loop | `rememberInfiniteTransition().animateFloat(...)` |
| Hero | `SharedTransitionLayout` + `sharedElement` / `sharedBounds` (1.7+) |
| Layout swap | `AnimatedContent(target) { }` |
| Drag/snap | `Modifier.draggable` or `Modifier.anchoredDraggable` |

Climb ladder only when needed. `animate*AsState` = 70%. `Animatable` = interrupt, chain, velocity, decay.

## Springs

| Use | Spec |
|---|---|
| Modal/drawer/tab | `spring(StiffnessMediumLow, DampingRatioNoBouncy)` |
| Button/toggle | `spring(StiffnessMedium, dampingRatio = 0.85f)` |
| Bouncy reveal | `spring(StiffnessLow, DampingRatioMediumBouncy)` |
| Drag follow | `spring(StiffnessHigh, dampingRatio = 1f)` |

Stiffness: VeryLow 50, Low 200, MediumLow 400, Medium 1500 (default), High 10000. Damping: HighBouncy 0.2, MediumBouncy 0.5, LowBouncy 0.75, NoBouncy 1.0. Springs ignore `durationMillis` → use `tween` for fixed duration.

## Recipes

### animate*AsState

Always set `label` (Layout Inspector). Variants: Dp, Color, Offset, Size, Rect, Int, generic via `TwoWayConverter`.

```kotlin
val alpha by animateFloatAsState(targetAlpha, spring(StiffnessMedium), label = "alpha")
Box(Modifier.alpha(alpha))
```

### AnimatedVisibility

Combine enter/exit with `+`. Exit shorter/simpler than enter. Content runs while visible OR animating.

```kotlin
AnimatedVisibility(expanded,
    enter = slideInVertically { -it } + fadeIn(),
    exit = slideOutVertically { -it } + fadeOut(tween(150)),
) { Panel() }
```

### AnimatedContent

`togetherWith` = parallel enter/exit. `using SizeTransform(clip = false)` controls container resize. Identity change on `targetState` required.

```kotlin
AnimatedContent(currentTab, transitionSpec = {
    (slideInHorizontally { it } + fadeIn()) togetherWith (slideOutHorizontally { -it } + fadeOut())
}, label = "tabs") { TabContent(it) }
```

### updateTransition

Shared timeline; per-property `transitionSpec` override.

```kotlin
val t = updateTransition(expanded, label = "expand")
val width by t.animateDp(label = "w") { if (it) 300.dp else 100.dp }
val color by t.animateColor(label = "c") { if (it) Blue else Gray }
```

### Animatable

```kotlin
val offsetX = remember { Animatable(0f) }
LaunchedEffect(trigger) {
    offsetX.animateTo(100f, spring())
    offsetX.animateTo(0f, spring(DampingRatioMediumBouncy))
}
Box(Modifier.offset { IntOffset(offsetX.value.roundToInt(), 0) })
```

### SharedTransitionLayout

Two scopes: `SharedTransitionScope` (modifier extensions) + `AnimatedVisibilityScope` (`AnimatedContent` lambda or Nav `composable` receiver).

```kotlin
SharedTransitionLayout {
    AnimatedContent(currentScreen, label = "nav") { screen ->
        when (screen) {
            Screen.List -> ListScreen(this@SharedTransitionLayout, this@AnimatedContent)
            is Screen.Detail -> DetailScreen(screen.item, this@SharedTransitionLayout, this@AnimatedContent)
        }
    }
}

// List card — sharedBounds for shape/size change, sharedElement for image
with(sts) {
    Card(modifier = Modifier.sharedBounds(rememberSharedContentState("card-${id}"), avs)) {
        Image(painter, null, Modifier.sharedElement(rememberSharedContentState("image-${id}"), avs))
    }
}
```

**Nav 2.8+:**

```kotlin
SharedTransitionLayout {
    NavHost(nav, startDestination = HomeRoute) {
        composable<HomeRoute> {
            HomeScreen(sts = this@SharedTransitionLayout, avs = this, onOpen = { nav.navigate(DetailRoute(it)) })
        }
        composable<DetailRoute> { DetailScreen(sts = this@SharedTransitionLayout, avs = this) }
    }
}
```

**sharedBounds knobs:** `enter`/`exit`, `boundsTransform`, `resizeMode` (`scaleToBounds` vs `RemeasureToBounds`), `clipInOverlayDuringTransition`, `placeholderSize`.

**Keys:** id-based, never index. Namespace: `"image-${id}"`, `"title-${id}"`.

### InfiniteTransition

```kotlin
val inf = rememberInfiniteTransition(label = "loader")
val rot by inf.animateFloat(0f, 360f, infiniteRepeatable(tween(1000, LinearEasing), RepeatMode.Restart), label = "rot")
```

`RepeatMode.Reverse` = ping-pong. One-shot decay → `Animatable.animateDecay`.

## Gestures

| Need | Modifier |
|---|---|
| Tap | `clickable` / `combinedClickable` |
| Axis drag | `draggable(state, orientation, onDragStopped = { velocity → })` |
| Snap/dismiss | `anchoredDraggable(state)` + `AnchoredDraggableDefaults.flingBehavior` |
| Pinch/pan/rotate | `transformable(state)` |
| Custom | `pointerInput(key) { detectDragGestures/onTapGestures/... }` |
| Collapsing header | `nestedScroll(NestedScrollConnection)` |

**AnchoredDraggableState:** `currentValue`, `settledValue`, `offset`, `progress(from, to)`. Thresholds on fling behavior, not deprecated factory.

**pointerInput key:** restart coroutine when deps change. Always `change.consume()` when claiming.

**NestedScrollConnection pattern:**

```kotlin
object : NestedScrollConnection {
    override fun onPreScroll(available: Offset, source: NestedScrollSource): Offset {
        // collapse header before LazyColumn eats scroll
        headerOffset = (headerOffset + available.y).coerceIn(-maxHeader, 0f)
        return Offset(0f, consumedY)
    }
    override fun onPostScroll(consumed: Offset, available: Offset, source: NestedScrollSource): Offset {
        // re-expand when inner at top
    }
}
```

**Fling:** `Animatable` + `splineBasedDecay(density)` on `onDragStopped`. Anchored = auto-snap.

**M3 patterns:** `PullToRefreshBox`, `SwipeToDismissBox` + `LaunchedEffect(state.currentValue)`.

**Pinch-zoom:**

```kotlin
var scale by remember { mutableFloatStateOf(1f) }
val tState = rememberTransformableState { z, p, _ -> scale = (scale * z).coerceIn(1f, 5f); offset += p }
Image(..., Modifier.graphicsLayer { scaleX = scale; scaleY = scale }.transformable(tState))
```

**Conflicts:** LazyColumn in HorizontalPager = OK (orthogonal). Edge horizontal pan → inset 30dp+ or `BackHandler`. Android predictive back vs edge pan.

## Recomposition (animation perf)

Animations change state every frame. Read in **layout/draw**, not composition:

| BAD | GOOD |
|---|---|
| `Modifier.offset(x = animatedX.dp)` | `Modifier.offset { IntOffset(animatedX.roundToInt(), 0) }` |
| `Modifier.scale(animatedScale)` | `Modifier.graphicsLayer { scaleX/Y = animatedScale }` |

`graphicsLayer` = transform-only, GPU, no layout pass.

**derivedStateOf** when boolean flips less often than source:

```kotlin
val isScrolled by remember { derivedStateOf {
    listState.firstVisibleItemIndex > 0 || listState.firstVisibleItemScrollOffset > 0
} }
```

**LazyColumn:** `items(list, key = { it.id })` + `Modifier.animateItem()` (1.7+, replaces `animateItemPlacement`).

**Debug:** Layout Inspector → Show Recomposition Counts. Static nodes on scroll = hoist read. 60/s = switch to lambda modifiers. Reset counts per interaction. API 29+, Compose 1.2+. Compiler reports for unstable params. No shipped `recomposeHighlighter()` — vendor from android/snippets into `debug/`.

**Macrobenchmark:** `FrameTimingMetric` — 60Hz p50 <16.67ms, p99 <30ms; 120Hz p50 <8.33ms. **Baseline profiles:** `:app:generateBaselineProfile`, commit `baseline-prof.txt` — 20–40% jank reduction cold scroll.

## Anti-patterns

### Layout size vs transform

```kotlin
// BAD — layout pass every frame
val w by animateDpAsState(if (expanded) 300.dp else 100.dp)
Box(Modifier.width(w).height(60.dp))

// GOOD — composite-only
val scale by animateFloatAsState(if (expanded) 3f else 1f, label = "scale")
Box(Modifier.width(100.dp).graphicsLayer { scaleX = scale; transformOrigin = TransformOrigin(0f, 0.5f) })
```

Must change layout → `animateContentSize()` or `AnimatedContent`.

### LaunchedEffect keys

```kotlin
// BAD — stale capture, surprise re-runs
LaunchedEffect(true) { offsetX.animateTo(target) }

// GOOD — key on trigger
LaunchedEffect(triggerKey) { offsetX.animateTo(target) }
```

### LazyColumn without keys

```kotlin
// BAD — wrong slot on reorder
items(list) { AnimatedVisibility(item.expanded) { ItemRow(item) } }

// GOOD
items(list, key = { it.id }) { Row(Modifier.animateItem()) { AnimatedVisibility(...) { ItemRow(it) } } }
```

### AnimatedContent per row

```kotlin
// BAD — jank on scroll
items(list, key = { it.id }) { AnimatedContent(it.state) { Row(it) } }

// GOOD — single prop
items(list, key = { it.id }) {
    val bg by animateColorAsState(if (it.selected) sel else def, label = "rowBg")
    Row(Modifier.background(bg)) { Content(it) }
}
```

Heavy containers (`AnimatedContent`, `SharedTransitionLayout`) at screen scope only.

## Shared transition gotchas

- Mismatched keys = silent no-op. Verify both sides in Layout Inspector.
- Source off-screen in LazyColumn = unmeasurable. Scroll into view or `sharedBounds` on row.
- Max ~2 shared elements (hero + title); rest fade. Each = overlay render pass.
- Z-order: shared in overlay — app bar/FAB outside or accept overlap.
- Reduced motion → `snap()` boundsTransform, `tween(0)` enter/exit.

## Reduced motion

```kotlin
@Composable fun rememberReduceMotion(): Boolean {
    val ctx = LocalContext.current
    return remember {
        Settings.Global.getFloat(ctx.contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE, 1f) == 0f
    }
}
// Cleaner: ValueAnimator.areAnimatorsEnabled() (API 26+)

val alpha by animateFloatAsState(target, if (reduce) snap() else spring(), label = "alpha")
```

Battery Saver, Accessibility "Remove animations", Developer "Animation off" all zero the scale.

## Shared transition recipes

**Card → detail** — outer `sharedBounds`, inner image `sharedElement`:

```kotlin
LazyColumn { items(items, key = { it.id }) { item ->
    with(sts) {
        Card(onClick = { onOpen(item) },
            modifier = Modifier.sharedBounds(rememberSharedContentState("card-${item.id}"), avs)) {
            Image(item.painter, null, Modifier.sharedElement(rememberSharedContentState("image-${item.id}"), avs))
            Text(item.title)
        }
    }
} }

Column(Modifier.sharedBounds(rememberSharedContentState("card-${item.id}"), avs)) {
    Image(..., Modifier.fillMaxWidth().height(360.dp)
        .sharedElement(rememberSharedContentState("image-${item.id}"), avs))
    Text(item.title, style = MaterialTheme.typography.headlineLarge)
}
```

**Image hero** — same key both sides; optional `boundsTransform`:

```kotlin
Modifier.sharedElement(
    rememberSharedContentState("photo-${item.id}"), avs,
    boundsTransform = { _, _ -> spring(StiffnessMediumLow, dampingRatio = 0.85f) },
)
```

**sharedBounds template:**

```kotlin
Modifier.sharedBounds(
    rememberSharedContentState("card-$id"), avs,
    enter = fadeIn(tween(150)), exit = fadeOut(tween(80)),
    resizeMode = SharedTransitionScope.ResizeMode.RemeasureToBounds,
    clipInOverlayDuringTransition = OverlayClip(RoundedCornerShape(24.dp)),
)
```
