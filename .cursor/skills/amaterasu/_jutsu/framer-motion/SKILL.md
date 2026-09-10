---
name: framer-motion
description: "Framer Motion / Motion — AnimatePresence, layout, gestures, motion values."
disable-model-invocation: true
---

# Framer Motion / Motion

`motion` and `framer-motion` both v13+. Same API. **Read `package.json` — do not migrate unless asked.**

| In package.json | Import | Install |
|---|---|---|
| `motion` | `"motion/react"` | `npm install motion` |
| `framer-motion` | `"framer-motion"` | `npm install framer-motion` |

Peers: `react` / `react-dom` `^18 || ^19`.

## When to Use

| Criteria | Framer Motion | GSAP | CSS |
|---|---|---|---|
| Layout animations | Excellent (`layoutId`) | Manual | Impossible |
| Exit animations | AnimatePresence | Timeline reverse | Limited |
| Gestures (drag/hover) | Native | Draggable plugin | Basic |
| Scroll-driven | useScroll + useTransform | ScrollTrigger | scroll-timeline |
| Complex orchestration | Variants | Timeline | @keyframes |
| Bundle | ~50kb | ~30kb | 0kb |

**Rule:** React UI (modals, toasts, reorder, shared layout) → Motion. Cinematic scroll / SVG morph → GSAP.

## Recipes

### AnimatePresence

```tsx
<AnimatePresence mode="wait">
  {isVisible && (
    <motion.div key="unique-key" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} />
  )}
</AnimatePresence>
```

Modes: `sync` (default), `wait` (page transitions), `popLayout` (lists). `onExitComplete` when all exits done.

### Layout

```tsx
<motion.div layoutId="highlight" />           // shared layout slide
<motion.div layout>                            // auto position/size
  {expanded && <motion.p layout>Content</motion.p>}
</motion.div>
// layout="position" | "size" | "preserve-aspect"
```

### Variants

```tsx
import { stagger } from "motion/react";
const container = {
  hidden: { opacity: 0 },
  show: { opacity: 1, transition: { delayChildren: stagger(0.08, { startDelay: 0.2 }) } },
};
const item = { hidden: { opacity: 0, y: 20 }, show: { opacity: 1, y: 0 } };
<motion.ul variants={container} initial="hidden" animate="show">
  {items.map(i => <motion.li key={i.id} variants={item} />)}
</motion.ul>
```

`staggerChildren` / `staggerDirection` deprecated since Motion 12.22 — use `stagger()`.

### Gestures

```tsx
<motion.div
  whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.95 }}
  drag dragConstraints={{ left: -100, right: 100 }} dragElastic={0.2}
  onDragEnd={(_, info) => { if (info.offset.x > 100) handleSwipe("right"); }}
/>
```

### Motion Values (no re-render)

```tsx
const x = useMotionValue(0);
const opacity = useTransform(x, [-200, 0, 200], [0, 1, 0]);
const smoothX = useSpring(x, { stiffness: 300, damping: 30 });
const { scrollYProgress } = useScroll({ target: ref, offset: ["start end", "end start"] });
const parallaxY = useTransform(scrollYProgress, [0, 1], [0, -300]);
<motion.div style={{ x, opacity }} />
```

## motion Props

### Animation

| Prop | Type | Notes |
|---|---|---|
| `initial` | Target \| label \| `false` | `false` = skip mount animation |
| `animate` | Target \| label | Change triggers animation |
| `exit` | Target \| label | Needs AnimatePresence parent |
| `transition` | Transition | duration, ease, type, delay |
| `variants` | Variants | Propagate to children |

### Gestures

| Prop | Notes |
|---|---|
| `whileHover` / `whileTap` / `whileFocus` / `whileDrag` / `whileInView` | Animate during state |
| `drag` | `true` \| `"x"` \| `"y"` |
| `dragConstraints` | `{ top, left, right, bottom }` or RefObject |
| `dragElastic` | 0-1 (default 0.35) |
| `dragMomentum` | Inertia after release (default true) |
| `dragSnapToOrigin` | Return to start |
| `onDrag` / `onDragStart` / `onDragEnd` | `(event, PanInfo) => void` |

### Layout

| Prop | Notes |
|---|---|
| `layout` | `true` \| `"position"` \| `"size"` \| `"preserve-aspect"` |
| `layoutId` | Shared layout between components |
| `layoutDependency` | Force recalc on change |
| `layoutScroll` | Compensate scroll offset |

**Style:** accepts MotionValues — `x`, `y`, `z`, `rotateX/Y/Z`, `scale`, `scaleX/Y`, `skewX/Y`.

## AnimatePresence Props

| Prop | Notes |
|---|---|
| `mode` | `sync` \| `wait` \| `popLayout` |
| `initial` | `false` disables first-render child animations |
| `onExitComplete` | All exits done |
| `custom` | Passed to dynamic exit variants |
| `presenceAffectsLayout` | Default true |

## Transition

```tsx
transition={{ type: "spring", stiffness: 300, damping: 30 }}
transition={{ type: "tween", duration: 0.3, ease: "easeInOut" }}
transition={{ x: { type: "spring" }, opacity: { duration: 0.2 } }}
transition={{ delayChildren: stagger(0.08, { from: "last" }), when: "beforeChildren" }}
```

Ease: `linear`, `easeIn/Out/InOut`, `circ*`, `back*`, `anticipate`, or cubic-bezier array.

## Hooks

| Hook | Use |
|---|---|
| `useMotionValue` | Reactive value, no re-render. `.set()` / `.get()` |
| `useTransform` | Map or derive from MotionValue(s) |
| `useSpring` | Spring-smooth a MotionValue or number |
| `useScroll` | `scrollX/Y`, `scrollX/YProgress`. Offset: `"start"`, `"center"`, `"end"`, `%` |
| `useAnimate` | Imperative: `await animate(scope.current, { x: 100 })` |
| `useInView` | IntersectionObserver wrapper. `once`, `amount`, `margin` |
| `useReducedMotion` | **Always use** for non-essential motion |
| `useMotionValueEvent` | Subscribe without re-render. Prefer over deprecated `onChange` |

```tsx
const [scope, animate] = useAnimate();
await animate([ [scope.current, { x: 100 }], ["li", { opacity: 1 }, { delay: stagger(0.1) }] ]);

const prefersReduced = useReducedMotion();
<motion.div animate={prefersReduced ? { opacity: 1 } : { opacity: 1, y: 0 }} />
```

## Standalone Utilities

```tsx
import { animate, stagger, scroll } from "motion/react";
animate(0, 100, { duration: 1, onUpdate: (v) => el.style.opacity = v });
animate(element, { opacity: 1 }, { duration: 0.5 });
scroll((progress) => { el.style.opacity = progress; }, { target: el, offset: ["start end", "end start"] });
```

## DO NOT

| BAD | GOOD | Why |
|---|---|---|
| Motion + styled-components without `isValidProp` | `MotionConfig isValidProp={isPropValid}` or `motion.create(StyledDiv)` | Motion props leak to DOM (v13+) |
| `onUpdate` → setState every frame | `useMotionValueEvent` with guard | Re-render loop |
| `layout` + unstable key | Stable `key={item.id}` | Breaks layout tracking |
| AnimatePresence child without key | `key="modal"` | Exit never fires |
| Nested motion both animating same axis | Single axis per level or variants | Transform conflict |
| Skip `useReducedMotion` | Always check preference | A11y |
