---
name: compose-multiplatform
description: "Compose Multiplatform / KMP — expect/actual, platform interop, density/fonts/resources, iOS/Android/Desktop/Web quirks."
disable-model-invocation: true
---

# Compose Multiplatform

**KMP** = shared Kotlin compiled to JVM/Native/Wasm. **CMP** = Compose UI on KMP (JetBrains port of Jetpack Compose). Target: **CMP 1.12.0**. ~80–95% in `commonMain`.

## Project layout

```
composeApp/src/
  commonMain/kotlin/     ← shared UI (80–95%)
  androidMain/           ← Activity, Context
  iosMain/               ← UIKit interop
  desktopMain/           ← JVM desktop
  wasmJsMain/            ← Wasm web
iosApp/                  ← Xcode consumes framework
androidApp/              ← optional separate module
```

If `iosMain`/`androidMain` grow past few hundred lines → platform concerns leaking into shared UI.

## expect/actual

Contract once in `commonMain`, `actual` per target. Functions, classes, properties, composables.

```kotlin
// commonMain
expect fun openShareSheet(text: String)

// androidMain
actual fun openShareSheet(text: String) {
    val intent = Intent(Intent.ACTION_SEND).apply { type = "text/plain"; putExtra(Intent.EXTRA_TEXT, text) }
    context.startActivity(Intent.createChooser(intent, null))
}

// iosMain
actual fun openShareSheet(text: String) {
    val vc = UIActivityViewController(listOf(text), null)
    UIApplication.sharedApplication.keyWindow?.rootViewController?.presentViewController(vc, true, null)
}
```

### expect composables (exception)

```kotlin
@Composable expect fun PlatformBlur(modifier: Modifier = Modifier, content: @Composable () -> Unit)
// androidMain: RuntimeShader blur (API 33+)
// iosMain: UIKitView(UIVisualEffectView(UIBlurEffectStyleSystemMaterial))
```

Most platform feel → tune tokens (colors, radii, springs) in `commonMain`, not separate code paths.

## Cross-platform APIs

| Android-only | CMP alternative |
|---|---|
| `LocalConfiguration` | `LocalWindowInfo.current.containerSize`, `BoxWithConstraints`, `LocalDensity`, `LocalLayoutDirection` |
| Hardcoded px | `with(LocalDensity.current) { 16.dp.toPx() }` — cache in hot loops |

Device traits → `expect class PlatformInfo` with typed `actual`.

## Compose Resources

`org.jetbrains.compose.resources` — `commonMain/composeResources/`:

```
font/Inter-Regular.ttf
drawable/logo.xml       ← Android XML vector; SVG everywhere EXCEPT Android
values/strings.xml
values-fr/strings.xml   ← qualifier on directory
files/config.json       ← Res.readBytes("files/config.json") — no generated accessor
```

```kotlin
val InterFamily = FontFamily(Font(Res.font.Inter_Regular, FontWeight.Normal), Font(Res.font.Inter_Bold, FontWeight.Bold))
Text("Hello", fontFamily = InterFamily)
Text(stringResource(Res.string.app_name))
```

## Entry points

**Android:**

```kotlin
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent { AppContent() }
    }
}
```

Pass `Context` → DI or `expect class PlatformContext`.

**iOS → SwiftUI:**

```kotlin
// iosMain/kotlin/main.ios.kt
fun MainViewController(): UIViewController = ComposeUIViewController { AppContent() }
```

```swift
import ComposeApp
struct ComposeContent: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController { Main_iosKt.MainViewController() }
    func updateUIViewController(_: UIViewController, context: Context) {}
}
struct ContentView: View { ComposeContent().ignoresSafeArea() }
```

Symbol mangling: file `main.ios.kt` → `Main_iosKt.MainViewController()`. Check generated headers.

**Compose embeds native (iOS):**

```kotlin
UIKitView(factory = { UISwitch().apply { ... } }, modifier = Modifier.size(48.dp, 32.dp))
UIKitViewController(factory = { ... })
```

Since 1.7: `androidx.compose.ui.viewinterop`. Deprecated: old `androidx.compose.ui.interop.UIKitView` with `interactive:` params. 1.10: `UIKitInteropProperties(placedAsOverlay = true)`, `sizeThatFits` for SwiftUI wrap.

**SwiftUI in Compose** → `UIHostingController` via `@objc` Swift bridge + cinterop:

```swift
@objc public class SwiftUIBridge: NSObject {
    @objc public static func makeMapController(lat: Double, lon: Double) -> UIViewController {
        UIHostingController(rootView: Map(coordinateRegion: .constant(region)))
    }
}
```

```kotlin
// iosMain
UIKitViewController(factory = { SwiftUIBridge.makeMapController(lat, lon) })
```

`build.gradle.kts`: cinterop `swiftBridge.def` → `language = Objective-C`, `headers = SwiftUIBridge.h`.

**Android legacy in Compose:** `AndroidView`, `ComposeView` in Fragment:

```kotlin
ComposeView(requireContext()).apply {
    setViewCompositionStrategy(DisposeOnViewTreeLifecycleDestroyed)
    setContent { AppContent() }
}
```

**Desktop:** `SwingPanel` / `JFXPanel` for WebView, JavaFX.

**Wasm:** `@JsName external fun renderChart(...)`. Compose → single `<canvas>`; adjacent DOM in `index.html` if needed.

## State sharing (Compose ↔ native)

Shared ViewModel in `commonMain`:

```kotlin
class CounterViewModel {
    private val _count = MutableStateFlow(0)
    val count: StateFlow<Int> = _count.asStateFlow()
    fun increment() { _count.value += 1 }
}
```

Compose: `collectAsState()`. Swift: **Skie** (Touchlab) → idiomatic `AsyncSequence`; without Skie → manual Flow bridge. One-shot → `SharedFlow(replay=0)` or `Channel`.

## Animation cross-platform

Same APIs as Jetpack Compose in `commonMain` (1.7+ including `SharedTransitionLayout`). Spring tuning identical on Android/iOS.

Deltas:
- iOS first frame slower (Skia bootstrap ~150–300ms) — keep splash or pre-warm transparent root.
- Wasm first-frame JIT stutter — lazy-load heavy graphs.

## Platform quirks

### Layout

| Issue | Fix |
|---|---|
| iOS safe area / Dynamic Island | `Modifier.windowInsetsPadding(WindowInsets.safeDrawing)` — verify on physical notched device |
| Desktop window resize stutter | `derivedStateOf { windowInfo.containerSize.width.dp }` — throttle ~60 resize events/s |
| Wasm browser zoom | Test 100/125/150% — `devicePixelRatio` affects physical pixels |
| iOS blank root | Explicit `fillMaxSize()` — iOS doesn't infer size like Android edge cases |

### Inputs

| Issue | Fix |
|---|---|
| iOS keyboard double-adjust | Default `OnFocusBehavior.FocusableAboveKeyboard` pans whole view. If using `imePadding()` → `DoNothing`: `ComposeUIViewController(configure = { onFocusBehavior = DoNothing }) { App() }`. Same if SwiftUI parent adjusts keyboard. |
| iOS edge back vs horizontal pan | Drag area inset 30dp+ from leading edge |
| Desktop keyboard | `onKeyEvent` / `onPreviewKeyEvent`, `Key.Tab`, `isCtrlPressed`/`isMetaPressed` |
| Wasm input | `pointerInput` for mouse+touch; wheel via `scrollable` |

### Rendering

- Skia (Android OS) vs Skiko (iOS/Desktop/Wasm) — subtle AA/text differences; visual diff, not pixel-exact.
- **AGSL Android 13+ only.** iOS → Metal `MTKView` via `UIKitView`; Desktop → Skiko low-level; Wasm → WebGL interop. Feature-flag shaders per platform.
- SharedTransitionLayout works cross-platform; iOS slightly slower — shallow scopes, benchmark iPhone 12 baseline.

### Material 3 per platform

| Component | Android | iOS | Desktop | Web |
|---|---|---|---|---|
| Switch | Material | iOS-style auto | Material | Material |
| Slider/DatePicker | Material | Material (not native UIDatePicker) | Material | Material |
| BottomAppBar/NavBar | Material | Foreign on iOS — consider UIKit TabView | OK/adapts | OK |

Native iOS pickers/tabs → `UIKitView`.

### Lifecycle (1.7+ all targets)

`LocalLifecycleOwner.current`, `LifecycleEventEffect(ON_RESUME) { }`. Desktop: `Window(onCloseRequest)` — macOS may hide vs quit.

## What does NOT work

- Drawer swipe from leading edge on iOS → conflicts back gesture; button trigger or inset 30dp+.
- RTL: iOS Compose bugs improved 1.7+ — verify Arabic/Hebrew.
- `Color.parseHex` — use `Color(0xFFRRGGBB)`.
- iOS system fonts: `FontFamily.SansSerif` ≠ SF Pro. Bundle via Resources or `UILabel` via `UIKitView`.
- JVM APIs in commonMain: `java.util.UUID`, `java.io.File` → `kotlinx-uuid`, `okio`, `expect`/`actual`.

## Performance

| Target | Note |
|---|---|
| iOS | Cold Skia boot ~150–300ms; splash until first frame |
| Wasm | Bundle <2MB compressed; tree-shake; lazy screens |
| Desktop | JVM cold start fast; Kotlin/Native AOT optional |
| Android | Same Jetpack profiling — compiler stability, Layout Inspector |

## Anti-patterns

| BAD | GOOD |
|---|---|
| Reflection / `System.getProperty("os.name")` in commonMain | `expect val platform: Platform` |
| `Context` in commonMain | `expect class PlatformContext` or DI |
| Material colors jarring on iOS | Shared design system; tweak 2–3 tokens via actual |
| `LaunchedEffect { while(true) { delay(16) } }` | `rememberInfiniteTransition()` or lifecycle scope |

## Build

| Target | Command | Output |
|---|---|---|
| Android APK/AAB | `assembleRelease` / `bundleRelease` | `outputs/apk|bundle/release/` |
| iOS framework | `linkReleaseFrameworkIosArm64` | `build/bin/iosArm64/releaseFramework/` |
| Desktop installer | `packageDistributionForCurrentOS` | .dmg / .msi / .deb |
| Wasm dev/prod | `wasmJsBrowserDevelopmentRun` / `wasmJsBrowserDistribution` | dev server / `dist/wasmJs/productionExecutable/` |

## Common errors

| Symptom | Fix |
|---|---|
| iOS runtime symbol missing | JVM API in commonMain → multiplatform lib or expect/actual |
| iOS stack overflow | LaunchedEffect recursion / tight state loop — Instruments |
| Slow Wasm | Tree-shake, lazy-load, profile `.wasm` size |
| iOS link Undefined symbol | Cinterop / Swift header missing — rerun `cinteropProcess`, check `.def` |
| Blank iOS Compose | Root `fillMaxSize()` |
| Fonts iOS missing | `composeResources/font/`, verify `Res.font.*` name |

Pair with `compose-motion` (animation), `compose-graphics` (AGSL Android-only advanced).
