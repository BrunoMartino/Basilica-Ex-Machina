---
name: canvas-generative
description: "Canvas 2D generative art — particles, flow fields, noise, fractals, L-systems."
disable-model-invocation: true
---

# Canvas Generative

Algorithmic art on Canvas 2D. For 3D/shaders → `../threejs-r3f/SKILL.md`. For easing → `../motion-principles/SKILL.md`.

## Setup

```js
function setupCanvas(canvas, width, height) {
  const dpr = window.devicePixelRatio || 1;
  canvas.width = width * dpr; canvas.height = height * dpr;
  canvas.style.width = `${width}px`; canvas.style.height = `${height}px`;
  const ctx = canvas.getContext('2d');
  ctx.scale(dpr, dpr);
  return ctx;
}

// ResizeObserver
const ro = new ResizeObserver(([entry]) => {
  const { width, height } = entry.contentRect;
  const dpr = window.devicePixelRatio || 1;
  canvas.width = width * dpr; canvas.height = height * dpr;
  ctx.scale(dpr, dpr);
  draw();
});
ro.observe(canvas.parentElement);
```

```js
let animId, prevTime = 0;
function loop(time) {
  const dt = Math.min((time - prevTime) / 1000, 0.1);
  prevTime = time;
  update(dt); render(ctx);
  animId = requestAnimationFrame(loop);
}
cancelAnimationFrame(animId); // stop
```

## Noise

| Type | Character | Best For |
|---|---|---|
| Perlin | Smooth, grid bias | Terrain, clouds |
| Simplex | No grid artifacts | Flow fields, organic motion |
| Worley | Cell distance | Voronoi, cracks, caustics |

Scale input coords. Use fBm octaves. Seed for reproducibility.

```js
function fbm(x, y, octaves = 4, lacunarity = 2, gain = 0.5) {
  let value = 0, amplitude = 1, frequency = 1, maxAmp = 0;
  for (let i = 0; i < octaves; i++) {
    value += amplitude * noise2D(x * frequency, y * frequency);
    maxAmp += amplitude; amplitude *= gain; frequency *= lacunarity;
  }
  return value / maxAmp;
}
```

**SimplexNoise:** IIFE with `seed(n)` (Fisher-Yates LCG permutation). Returns `{ noise2D, noise3D, seed }`.

```js
SimplexNoise.seed(42);
const val = SimplexNoise.noise2D(x * 0.01, y * 0.01); // [-1, 1] — scale coords down
SimplexNoise.noise3D(x * 0.01, y * 0.01, z);          // animated fields
```

## Particle Pool

Pre-allocate. Never `new` / `splice` in hot loop. Swap-and-shrink on death.

```js
class ParticleSystem {
  constructor(max = 10000) {
    this.max = max; this.count = 0;
    this.x = new Float32Array(max); this.y = new Float32Array(max);
    this.vx = new Float32Array(max); this.vy = new Float32Array(max);
    this.life = new Float32Array(max); this.maxLife = new Float32Array(max);
    this.alpha = new Float32Array(max);
  }
  spawn(x, y, vx, vy, life) {
    if (this.count >= this.max) return false;
    const i = this.count++;
    this.x[i]=x; this.y[i]=y; this.vx[i]=vx; this.vy[i]=vy;
    this.life[i]=0; this.maxLife[i]=life; this.alpha[i]=1;
    return true;
  }
  update(dt = 1/60, gravity = 0, friction = 1) {
    for (let i = this.count - 1; i >= 0; i--) {
      this.vy[i] += gravity * dt; this.vx[i] *= friction; this.vy[i] *= friction;
      this.x[i] += this.vx[i]; this.y[i] += this.vy[i]; this.life[i]++;
      this.alpha[i] = 1 - this.life[i] / this.maxLife[i];
      if (this.life[i] >= this.maxLife[i]) {
        this.count--;
        if (i < this.count) { /* swap all props with this.count */ }
      }
    }
  }
  render(ctx, color = '255,255,255') {
    for (let i = 0; i < this.count; i++) {
      ctx.beginPath(); ctx.arc(this.x[i], this.y[i], 2, 0, Math.PI * 2);
      ctx.fillStyle = `rgba(${color}, ${this.alpha[i].toFixed(3)})`; ctx.fill();
    }
  }
}
```

## Flow Field

1. Grid of angles from noise
2. Particle lookup by position
3. Steer + damp velocity

```js
const cols = Math.ceil(width / cellSize), rows = Math.ceil(height / cellSize);
const field = new Float32Array(cols * rows);
for (let y = 0; y < rows; y++)
  for (let x = 0; x < cols; x++)
    field[y * cols + x] = noise3D(x * 0.003 * cellSize, y * 0.003 * cellSize, noiseZ) * Math.PI * 2;

function followField(p) {
  const col = Math.floor(p.x / cellSize), row = Math.floor(p.y / cellSize);
  if (col >= 0 && col < cols && row >= 0 && row < rows) {
    const a = field[row * cols + col];
    p.vx += Math.cos(a) * force; p.vy += Math.sin(a) * force;
  }
  p.vx *= 0.96; p.vy *= 0.96;
}
```

```js
class FlowField {
  constructor(w, h, cellSize = 20, { noiseScale=0.003, noiseSpeed=0.002, particles=1000, maxSpeed=2, force=0.3 } = {}) {
    this.cols = Math.ceil(w/cellSize); this.rows = Math.ceil(h/cellSize);
    this.field = new Float32Array(this.cols * this.rows);
    this.particles = Array.from({length: particles}, () => ({ x: Math.random()*w, y: Math.random()*h, vx:0, vy:0, px:0, py:0, age:0, maxAge:200, hue:0 }));
  }
  updateField() { /* fill field from noise3D, increment noiseZ */ }
  lookup(x,y) { /* col/row → angle */ }
  updateParticles() { /* follow field, clamp speed, friction 0.96, respawn on age/bounds */ }
  render(ctx) { /* line trails: moveTo(px,py) lineTo(x,y), hsla by angle */ }
}
```

Trail fade: `ctx.fillStyle = 'rgba(10,10,15,0.03)'; ctx.fillRect(...)`.

## L-Systems

| Component | Role |
|---|---|
| Axiom | Start string |
| Rules | `{ 'F': 'F[+F]F[-F]F' }` |
| Angle | Turn per `+`/`-` |
| Iterations | Rewrites (4-7 max — exponential growth) |

```js
class LSystem {
  constructor(axiom, rules, angleDeg) {
    this.axiom = axiom; this.rules = rules; this.angle = angleDeg * Math.PI / 180;
  }
  generate(n) {
    let s = this.axiom;
    for (let i = 0; i < n; i++) s = [...s].map(c => this.rules[c] || c).join('');
    return s;
  }
  render(ctx, x, y, heading, step, style = {}) {
    const stack = []; let a = heading;
    for (const c of this.commands) {
      switch (c) {
        case 'F': { const nx = x + Math.cos(a)*step, ny = y + Math.sin(a)*step;
          ctx.beginPath(); ctx.moveTo(x,y); ctx.lineTo(nx,ny); ctx.stroke(); x=nx; y=ny; break; }
        case '+': a += this.angle; break; case '-': a -= this.angle; break;
        case '[': stack.push({x,y,a}); break;
        case ']': { const s = stack.pop(); x=s.x; y=s.y; a=s.a; ctx.moveTo(x,y); break; }
      }
    }
  }
}
```

**Presets:**

| Name | Axiom | Key Rule | Angle | Iter |
|---|---|---|---|---|
| plant | `X` | `X→F+[[X]-X]-F[-FX]+X`, `F→FF` | 25° | 6 |
| koch | `F--F--F` | `F→F+F--F+F` | 60° | 4 |
| tree | `F` | `F→FF+[+F-F-F]-[-F+F+F]` | 22.5° | 4 |
| dragon | `FX` | `X→X+YF+`, `Y→-FX-Y` | 90° | 12 |

## Lorenz Attractor

Chaotic 3D ODE. Use RK4 (not Euler). Ring-buffer trail. Project x→screen.x, z→screen.y.

```js
class LorenzAttractor {
  constructor({ sigma=10, rho=28, beta=8/3, dt=0.005, trailLength=5000 } = {}) { /* ... */ }
  step() { /* RK4: dx=σ(y-x), dy=x(ρ-z)-y, dz=xy-βz */ }
  render(ctx, cx, cy, scale=8) { /* walk ring buffer, hsla fade */ }
}
// Classic: σ=10, ρ=28, β=8/3. stepN(10) per frame.
// Tighter: ρ=99.96. Wider: σ=14.
```

## Full Loop Example

```js
const canvas = document.getElementById('canvas');
const ctx = setupCanvas(canvas, innerWidth, innerHeight);
SimplexNoise.seed(42);
const ps = new ParticleSystem(5000);
const ff = new FlowField(canvas.clientWidth, canvas.clientHeight, 20, { particles: 2000, force: 0.2 });

function loop() {
  ctx.fillStyle = 'rgba(10,10,15,0.03)'; ctx.fillRect(0, 0, canvas.clientWidth, canvas.clientHeight);
  for (let i = 0; i < 5; i++) ps.spawn(innerWidth/2, innerHeight/2, (Math.random()-0.5)*4, (Math.random()-0.5)*4, 80);
  ps.update(1/60, 0.1, 0.99); ps.render(ctx);
  // OR: ff.updateField(); ff.updateParticles(); ff.render(ctx);
  requestAnimationFrame(loop);
}
requestAnimationFrame(loop);
```

## Double Buffer

```js
const offscreen = document.createElement('canvas');
const offCtx = offscreen.getContext('2d');
function render() {
  offCtx.fillStyle = 'rgba(0,0,0,0.05)'; offCtx.fillRect(0,0,w,h);
  drawParticles(offCtx);
  ctx.drawImage(offscreen, 0, 0);
}
```

## DO NOT

| BAD | GOOD | Why |
|---|---|---|
| `clearRect` every frame for trails | Semi-transparent `fillRect` | Kills trails |
| `getImageData` in animation loop | Sample once, cache | GPU readback blocks pipeline |
| Canvas without DPR scaling | `width * dpr` + `ctx.scale(dpr)` | Blurry on Retina |
| `new` objects in `update()`/`render()` | Pre-allocate, reuse vars | GC spikes |
| L-system iterations > 7 | Cap at 4-7 | Exponential string blowup |
| Euler integration for Lorenz | RK4 | Diverges fast |
| Particle pool with `splice` | Swap-and-shrink | O(n) array churn |
