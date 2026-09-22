---
name: desktop-principles
description: "Desktop UX — hover, pointer precision, keyboard shortcuts, multi-window, focus management."
disable-model-invocation: true
---

# Desktop Principles

Desktop context. Load for macOS, Windows, Linux, web desktop.

## Hover — mandatory

Every clickable surface needs distinct hover feedback (~100–200ms transition).

```css
.button { transition: background 120ms ease-out, transform 120ms ease-out; }
.button:hover { background: var(--surface-hover); transform: translateY(-1px); }
.button:active { transform: translateY(0); }
```

| SwiftUI modifier | macOS? | Notes |
|---|---|---|
| `.onHover { }` | yes | portable hover signal |
| `.onContinuousHover` | yes (macOS 14+) | position, not just in/out |
| `.hoverEffect` | **no** | iOS/iPadOS only — `#if os(macOS)` gate |
| `.pointerStyle` | macOS 15+ | cursor shape |

**Compose Desktop:** `hoverable(interactionSource)` + `collectIsHoveredAsState()`.

## Pointer precision

- Targets: 24–32px icons; 28–36px toolbar — smaller than mobile OK
- WCAG AA floor: **24×24 CSS px** (spacing exception: 24px circles must not intersect)
- macOS HIG: 28×28 pt default; 20×20 pt absolute min
- **Fitts's Law:** high-frequency controls at screen edges/corners (menubar, taskbar, dock)

## Keyboard shortcuts — first-class

| Action | macOS | Windows / Linux |
|---|---|---|
| New | ⌘N | Ctrl+N |
| Open | ⌘O | Ctrl+O |
| Save | ⌘S | Ctrl+S |
| Close window | ⌘W | Ctrl+W |
| Quit | ⌘Q | Alt+F4 |
| Find | ⌘F | Ctrl+F |
| Settings | ⌘, | Ctrl+, |
| Command palette | ⌘K / ⌘⇧P | Ctrl+K / Ctrl+⇧P |
| Undo / Redo | ⌘Z / ⌘⇧Z | Ctrl+Z / Ctrl+Y |
| New tab | ⌘T | Ctrl+T |

**Web mod key:**
```js
const isMac = /Mac|iPhone|iPad/.test(navigator.userAgentData?.platform ?? navigator.platform ?? "");
const mod = isMac ? e.metaKey : e.ctrlKey;
```

**SwiftUI:** `.keyboardShortcut("n", modifiers: .command)`  
**Compose Desktop:** `KeyShortcut(Key.N, meta = true)` in `MenuBar`; `onKeyEvent` for global binds

### Chords & conflicts

- Chord pattern: leader (e.g. ⌘K) arms 300ms buffer, then second key
- **Never override OS:** ⌘Q, ⌘Tab, ⌘Space, Alt+Tab, Win+L
- **Never override browser** globally: ⌘L, ⌘T, ⌘W
- No bare-letter shortcuts without modifier (breaks text input)

### Discoverability

Menu shows shortcut | tooltip after ~1s delay `Action (⌘N)` | ⌘? / ⌘/ overlay, searchable

## Multi-window

**Use window when:** long-running secondary task; comparing two contexts; document-based (one doc = one window).  
**Don't use for:** confirmations, brief settings, sheet/popover candidates.

| Platform | Pattern |
|---|---|
| SwiftUI | `WindowGroup` (docs) + `Window(id:)` (inspector) + `Settings`; `@Environment(\.openWindow)` |
| Compose Desktop | multiple `Window { }` in `application { }`; `rememberWindowState` for size/position |
| Web | prefer panel/modal/tab; `window.open` only on user gesture |

**State:** one source of truth — singleton, DI, or `@Observable` via `.environment`. Secondary windows observe; never own canonical state. Persist size/position/open-at-quit; clamp to visible screens on restore.

**Lifecycle:** SwiftUI `scenePhase` for focus-loss save (not just `onDisappear`); Compose Desktop has no Android `LifecycleEventObserver`.

## Focus management

- Sane tab order; visible focus rings — never `outline: none` without replacement
- SwiftUI: `@FocusState` + `.focused()` + `.onSubmit` chain
- Compose: `FocusRequester` + `ImeAction.Next` / `onNext`
- Web: `:focus-visible` + `tabindex="0"` on custom controls

```css
button:focus { outline: none; }
button:focus-visible { outline: 2px solid var(--ring); outline-offset: 2px; }
```

## Information density

8px grid; persistent sidebars not bottom tabs; command palette (⌘K); dense tables when data warrants it.

## Subtle animations

Desktop = hours of stare time. Routine UI: opacity/small translate <200ms, no bounce on hover.

```css
/* BAD */ .card:hover { transform: scale(1.05); transition: 600ms bounce; }
/* GOOD */ .card { opacity: 0.92; transition: opacity 100ms ease-out; }
.card:hover { opacity: 1; }
```

## Anti-patterns

| # | BAD | GOOD |
|---|---|---|
| Hamburger nav @1440px | collapsed nav on wide viewport | persistent sidebar + optional collapse |
| No shortcuts for primary actions | New buried in menu only | ⌘N in menu + toolbar tooltip + `useShortcut` |
| Focus ring removed | `button:focus { outline: none; }` only | `:focus-visible` replacement |

## Load sub-skills

| Need | Path |
|---|---|
| Motion foundation | `.claude/skills/amaterasu/_jutsu/motion-principles/SKILL.md` |
| SwiftUI motion | `.claude/skills/amaterasu/_jutsu/swiftui-motion/SKILL.md` |
| Compose Desktop | `.claude/skills/amaterasu/_jutsu/compose-multiplatform/SKILL.md` |
| Design audit | `.claude/skills/amaterasu/_jutsu/design-audit/SKILL.md` |
