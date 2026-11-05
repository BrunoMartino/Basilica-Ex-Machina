# Motion recipes beyond the template

`template/app.js` already does: canvas sequence on `scrub: 0.6`, moments as timeline tweens at progress positions, art parallax, batch reveal, reduced-motion via `gsap.matchMedia`. Add only what the concept needs.

## Two-scene crossfade (two short shots instead of one long one)

`config.js`:
```js
frames: [
  { total: 80, desktop: "assets/frames/a/desktop/f_{n}.webp", mobile: "assets/frames/a/mobile/f_{n}.webp" },
  { total: 80, desktop: "assets/frames/b/desktop/f_{n}.webp", mobile: "assets/frames/b/mobile/f_{n}.webp" },
],
```
Slice each shot into its own folder. In `app.js`, build one `Sequence` per entry (second `<canvas class="cine-canvas">` in the stage, `opacity: 0`), then on the same timeline:

```js
tl.to(seqA.pos, { i: seqA.total - 1, ease: "none", duration: 0.5, onUpdate: seqA.render }, 0)
  .to(seqB.pos, { i: seqB.total - 1, ease: "none", duration: 0.5, onUpdate: seqB.render }, 0.5)
  .to(seqB.canvas, { autoAlpha: 1, duration: 0.08, ease: "none" }, 0.46);
```
Shoot B's first keyframe = A's last keyframe for a seamless cut; crossfade width 0.06–0.1.

## Pin instead of sticky (ancestor has `overflow:hidden`)

```css
.cine { height: auto; } .cine-stage { position: relative; height: 100svh; }
```
```js
scrollTrigger: { trigger: cine, start: "top top", end: "+=" + innerHeight * 3.2, pin: ".cine-stage", scrub: 0.6, anticipatePin: 1 }
```

## Scene transition by mask

```js
tl.fromTo(".section-about .art", { clipPath: "inset(0 0 100% 0)" }, { clipPath: "inset(0 0 0% 0)", ease: "none", duration: 0.2 }, 0.9);
```
Use `clipPath`/`maskImage` tweens, not `height`.

## Opening title split

Plugins are in the GSAP core package (`gsap/SplitText`). Static mode: also vendor `SplitText.min.js`.
```js
const split = SplitText.create(".hero-title", { type: "words", mask: "words" });
tl.from(split.words, { yPercent: 110, stagger: 0.01, duration: 0.06, ease: "power3.out" }, 0.02);
```

## Smooth scroll (Lenis) — only if the user asks

```js
const lenis = new Lenis(); lenis.on("scroll", ScrollTrigger.update);
gsap.ticker.add((t) => lenis.raf(t * 1000)); gsap.ticker.lagSmoothing(0);
```
Lower `scrub` to `0.3` when Lenis is on. Not for LiveCanvas unless the theme has no own scroll handling.

## Three.js hero (replaces the image sequence)

Read `_jutsu/threejs-r3f` (vanilla section). Keep the same `.cine` / `.cine-stage` shell; swap `<canvas class="cine-canvas">` for the WebGL canvas. Camera path from the timeline:

```js
const cam = { t: 0 };
tl.to(cam, { t: 1, ease: "none", duration: 1, onUpdate: () => { camera.position.lerpVectors(P0, P1, cam.t); camera.lookAt(target); } }, 0);
```
`renderer.setPixelRatio(Math.min(devicePixelRatio, 2))`; render on `gsap.ticker`, not a second rAF. Fallback: if `!WebGLRenderingContext` or `matchMedia("(prefers-reduced-motion: reduce)")`, show `assets/frames/desktop/f_0001.webp` as a static poster. GLB ≤ 3 MB, Draco/Meshopt compressed, textures ≤ 2048.

## Performance guardrails

- Mobile frames ≤ 12 MB total (verify.py warns). 120–180 frames.
- `decoding="async"`, progressive preload passes (template does 8→4→2→1).
- DPR capped at 2. One rAF/ticker. No `setInterval` visuals.
- `will-change` only on `.art` during scroll (already in CSS via `transform: translateZ(0)`).
