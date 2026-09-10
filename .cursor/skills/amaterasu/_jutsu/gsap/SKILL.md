---
name: gsap
description: "GSAP animation engine — core tweens, timeline, ScrollTrigger, plugins."
disable-model-invocation: true
---

# GSAP

GSAP 3.15+. All plugins free in `gsap` npm package since 3.13. React: `@gsap/react` + `useGSAP()`.

## When to Use

| Criteria | CSS | Framer Motion | GSAP |
|---|---|---|---|
| Hover / simple toggle | Yes | Yes | Overkill |
| Sequenced timeline | No | Limited | **Yes** |
| Scroll-driven | scroll-timeline | Limited | **ScrollTrigger** |
| Complex stagger | No | Basic | **Distribution** |
| Mobile 60fps | Good | Average | **Excellent** |
| Text split / SVG morph | No | No | **SplitText / MorphSVG** |
| Bundle size | 0kb | ~30kb | ~25kb |

**Rule:** timeline, scroll-link, or distributed stagger → GSAP. Else CSS first.

## Setup

```js
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";
import { SplitText } from "gsap/SplitText";
gsap.registerPlugin(ScrollTrigger, SplitText);
```

```jsx
import { useGSAP } from "@gsap/react";
useGSAP(() => { gsap.to(".box", { x: 200 }); }, { scope: containerRef });
```

## Core API

| Method | Use |
|---|---|
| `gsap.to(t, vars)` | Animate TO values |
| `gsap.from(t, vars)` | Animate FROM values (default `immediateRender: true`) |
| `gsap.fromTo(t, from, to)` | Full control |
| `gsap.set(t, vars)` | Instant apply (`duration: 0`) |

**Key options:** `duration` (default 0.5), `ease` (`"power1.out"`), `delay`, `repeat` (-1 = infinite), `yoyo`, `stagger`, `overwrite` (`true` | `"auto"`), `immediateRender`, `paused`, callbacks.

**Transforms (GPU):** `x`, `y`, `z`, `rotation`, `rotationX/Y`, `scale`, `scaleX/Y`, `skewX/Y`, `xPercent`, `yPercent`, `transformOrigin`.

**Ease:** `"type.direction"` — `none`, `power1`-`power4`, `back`, `elastic`, `bounce`, `circ`, `expo`, `sine`, `steps(n)`. EasePack: `slow()`, `rough()`, `expoScale()`. CustomEase needs plugin.

### Recipes

```js
// defaults
const tl = gsap.timeline({ defaults: { duration: 0.8, ease: "power2.out" } });
tl.to(".a", { y: -20 }).to(".b", { y: -20 }, "<0.1");

// fromTo + stagger
gsap.fromTo(".card", { y: 40, opacity: 0 }, { y: 0, opacity: 1, stagger: 0.15 });

// grid stagger
gsap.to(".grid-item", {
  scale: 0,
  stagger: { each: 0.05, from: "center", grid: "auto", axis: "x" },
});

// quickTo (mouse follow)
const xTo = gsap.quickTo(".cursor", "x", { duration: 0.3, ease: "power3" });

// context cleanup (React: use useGSAP instead)
const ctx = gsap.context(() => { gsap.to(".box", { x: 200 }); }, containerRef);
ctx.revert();
```

## Timeline

Position param = 3rd arg of `.to()` / `.from()` / `.fromTo()`.

| Syntax | Meaning |
|---|---|
| `0`, `1`, `2.5` | Absolute seconds |
| (omit) | Append to end |
| `"+=0.5"` | 0.5s after end |
| `"-=0.3"` | 0.3s before end (overlap) |
| `"<"` | Same start as previous |
| `"<0.2"` | 0.2s after previous start |
| `">"` | At previous end |
| `"myLabel"` | At label |
| `"myLabel+=0.3"` | 0.3s after label |

```js
function heroAnimation() {
  const tl = gsap.timeline();
  tl.from(".hero-title", { y: 50, opacity: 0 })
    .from(".hero-subtitle", { y: 30, opacity: 0 }, "<0.2");
  return tl;
}
const master = gsap.timeline().add(heroAnimation()).add(cardsAnimation(), "-=0.3");
```

**Control:** `play()`, `pause()`, `reverse()`, `restart()`, `kill()`, `seek(2)`, `progress(0.5)`, `timeScale(2)`.

**Labels:** `tl.addLabel("reveal", "+=0.5")`, `tl.play("reveal")`, `tl.seek("myLabel")`.

**Nesting:** sub-timeline = one block in parent. Parent `defaults` do NOT propagate into nested timelines.

```js
const tl = gsap.timeline({
  scrollTrigger: { trigger: ".section", start: "top center", scrub: 1 },
});
tl.to(".a", { x: 200 }).to(".b", { rotation: 360 }, "<").to(".c", { scale: 2 }, "+=0.3");
// DO NOT put ScrollTrigger on timeline children
```

## Utils

```js
gsap.defaults({ duration: 0.8, ease: "power2.out" });
gsap.utils.toArray(".items");
gsap.utils.clamp(0, 100, val);
gsap.utils.mapRange(0, 1, 0, 100, 0.5); // → 50
gsap.utils.wrap([1,2,3], 5);           // → 3
gsap.utils.interpolate(0, 100, 0.5);   // → 50
gsap.utils.random(1, 10, 1);
gsap.utils.shuffle(array);
gsap.utils.distribute({ amount: 1, from: "center" });
```

**Tween control:** `tween.play()`, `pause()`, `reverse()`, `restart()`, `kill()`, `progress(0.5)`, `timeScale(2)`, `duration()` / `duration(2)`.

**Other animatable:** `opacity`, `borderRadius`, `backgroundColor`, `color`, `boxShadow`, CSS vars (`"--my-var": 100`), SVG `attr: { cx, r }`.

## ScrollTrigger

```js
gsap.to(".box", {
  x: 200,
  scrollTrigger: { trigger: ".box", start: "top center", end: "bottom center", toggleActions: "play none none none" },
});

const tl = gsap.timeline({
  scrollTrigger: { trigger: ".section", start: "top top", end: "+=1000", pin: true, scrub: 1 },
});
```

| Prop | Notes |
|---|---|
| `start` / `end` | `"triggerPoint viewportPoint"` — `top`, `center`, `bottom`, `%`, `px`, `+=500` |
| `scrub` | `true` (instant), `0.5`-`3` (smooth catch-up) |
| `pin` | Pin trigger or `pin: ".el"`. `pinSpacing: false` for overlay |
| `snap` | `0.25`, array, `"labels"`, or config object |
| `toggleActions` | `onEnter onLeave onEnterBack onLeaveBack` — `play pause resume reverse reset none` |
| `toggleClass` | Toggle class on enter/leave |
| `markers` | Debug only — remove in prod |

### Recipes

```js
// pin + scrub horizontal
gsap.to(".panel", {
  x: "-300%", ease: "none",
  scrollTrigger: { trigger: ".container", pin: true, scrub: 1, end: () => "+=" + el.scrollWidth },
});

// batch reveal
ScrollTrigger.batch(".card", {
  onEnter: (els) => gsap.to(els, { opacity: 1, y: 0, stagger: 0.1 }),
  start: "top 85%",
});
gsap.set(".card", { opacity: 0, y: 30 });

// horizontal scroll + inner animations
const scrollTween = gsap.to(".panels", {
  x: () => -(panels.scrollWidth - innerWidth), ease: "none",
  scrollTrigger: { trigger: ".wrapper", pin: true, scrub: 1 },
});
gsap.to(".panel-content", {
  scale: 1.2,
  scrollTrigger: { trigger: ".panel-content", containerAnimation: scrollTween, start: "left center", scrub: true },
});

// responsive
const mm = gsap.matchMedia();
mm.add("(min-width: 960px)", () => { gsap.to(".box", { x: 500, scrollTrigger: { scrub: true } }); });

// Lenis
lenis.on("scroll", ScrollTrigger.update);
gsap.ticker.add((t) => lenis.raf(t * 1000));
gsap.ticker.lagSmoothing(0);
```

**Callbacks:** `onEnter`, `onLeave`, `onEnterBack`, `onLeaveBack`, `onUpdate` (self.progress, self.direction, self.isActive, self.getVelocity()), `onToggle`, `onRefresh`, `onScrubComplete`.

**Standalone:** `ScrollTrigger.create({ trigger, start, onEnter, toggleClass: "active" })`.

**containerAnimation rules:** parent `ease: "none"`. Child start/end use horizontal axes (`left`, `right`). No `pin` or `snap` on children.

**Static:** `ScrollTrigger.getAll()`, `getById()`, `killAll()`, `refresh()`, `refresh(true)`, `sort()`, `saveStyles()`, `scrollerProxy()`, `normalizeScroll(true)`, `config({ limitCallbacks: true })`.

## Plugins

| Plugin | Use |
|---|---|
| ScrollTrigger | Scroll-driven |
| SplitText | Text split (chars/words/lines) |
| Flip | Layout transitions (FLIP) |
| MorphSVG | SVG path morph |
| DrawSVG | SVG stroke draw |
| MotionPath | Follow SVG path |
| Observer | Gestures without ScrollTrigger |
| CustomEase | Custom curves |

```js
// SplitText
const split = SplitText.create(".headline", { type: "chars, words, lines", mask: "lines", autoSplit: true,
  onSplit(self) { return gsap.from(self.words, { y: "100%", opacity: 0, stagger: 0.04 }); } });

// Flip
const state = Flip.getState(".items"); // BEFORE DOM change
container.appendChild(movedElement);
Flip.from(state, {
  duration: 0.8, absolute: true, stagger: 0.05,
  onEnter: (els) => gsap.fromTo(els, { opacity: 0, scale: 0 }, { opacity: 1, scale: 1 }),
  onLeave: (els) => gsap.to(els, { opacity: 0, scale: 0 }),
});
Flip.fit(".box", ".target", { scale: true, duration: 0.5 });

// MorphSVG / DrawSVG / MotionPath
gsap.to("#shape", { morphSVG: { shape: "#complex", shapeIndex: 2 }, duration: 1.5 });
MorphSVGPlugin.convertToPath("circle, rect, ellipse"); // dev: findShapeIndex("#a","#b")
gsap.from(".path", { drawSVG: 0, duration: 2 }); // stroke required in CSS
gsap.fromTo(".path", { drawSVG: "0% 0%" }, { drawSVG: "0% 100%", duration: 2 });
gsap.to(".rocket", { motionPath: { path: "#path", align: "#path", alignOrigin: [0.5, 0.5], autoRotate: true } });
gsap.to(".ball", { motionPath: { path: [{x:100,y:0},{x:200,y:-100}], curviness: 1.5, autoRotate: true } });

// Observer — full-page sections
let currentIndex = 0, animating = false;
const sections = gsap.utils.toArray(".section");
function goToSection(dir) {
  if (animating) return;
  const next = gsap.utils.clamp(0, sections.length - 1, currentIndex + dir);
  if (next === currentIndex) return;
  animating = true;
  gsap.to(sections[currentIndex], { yPercent: -100 * dir, duration: 0.8 });
  gsap.fromTo(sections[next], { yPercent: 100 * dir }, { yPercent: 0, duration: 0.8, onComplete: () => (animating = false) });
  currentIndex = next;
}
Observer.create({ type: "wheel, touch", onUp: () => goToSection(-1), onDown: () => goToSection(1), tolerance: 80, preventDefault: true });
```

## DO NOT

| BAD | GOOD | Why |
|---|---|---|
| `containerAnimation` with ease | Parent tween `ease: "none"` | Ease breaks scroll mapping |
| ScrollTrigger on timeline child | One ST per timeline OR standalone tweens | Child ST ignored |
| `setState` in `onUpdate` | Ref / `quickSetter` / DOM direct | 60 re-renders/s |
| `from()` in timeline without flag | `immediateRender: false` | Visual jump |
| Animate `width`/`height`/`top`/`left` | `scale`/`transform` or Flip | Layout reflow |
| `Flip.getState()` after DOM change | getState BEFORE change | No reference |
| MorphSVG mismatched point counts | Similar complexity or `shapeIndex` | Chaotic morph |
| DrawSVG on unstoked path | Define `stroke` + `fill: none` | Nothing draws |
| MotionPath + autoRotate, no alignOrigin | `align` + `alignOrigin: [0.5,0.5]` | Rotates around corner |
| SplitText never reverted | `onComplete: () => split.revert()` | DOM litter |
| Observer without lock | `animating` guard | Stacked animations |
