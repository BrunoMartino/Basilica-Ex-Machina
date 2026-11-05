# Art direction + generation prompts

## Looks like AI (forbidden)

**Visual**: purple/blue neon gradient, blurred blob backgrounds, glow everywhere; rectangular image with rounded corners + shadow; emoji or stock icons in every card; three identical cards repeated; everything centred; Inter/Roboto/Poppins as display font; text floating over a photo; title stacks (eyebrow + title + subtitle saying the same thing).

**Copy**: "transform", "revolutionize", "elevate", "unlock", "empower", "journey", "complete solution", "innovative", "cutting-edge", "unique experience", "next level", "not just X, it's Y" (and the pt-BR equivalents: transforme, revolucione, eleve, desbloqueie, potencialize, jornada, solução completa, inovador, de ponta, experiência única, no próximo nível). Excess em-dashes, triads of adjectives, rhetorical question in a title. Invented numbers, awards, clients, testimonials.

Write like the owner talking to a good customer: concrete nouns of the niche (the dish, the technique, the neighbourhood, the material).

## Section structure

Each section: numeric label, one `h2`, one text block or list, one `.art` of its own. Full viewport height on desktop. Alternate: text left / art right → inverse → full-bleed background.

1. Cinematic hero (sequence + 3 moments, CTA on the last)
2. About / manifesto (`.art--right`)
3. What we do (`.art--bg` + cards)
4. Process / menu / portfolio (`.art--left`)
5. Proof (only with real quotes/numbers; else omit)
6. Contact (form + `.art--bg.art--soft`)
7. Footer (panel: name, city, year)

## Palette + fonts

Start from client tokens. Greenfield: 1 background (warm near-black or off-white), 1 text, 1 accent. Dark → `--blend: lighten`; light → `--blend: multiply`.

| Niche | Display + body (Google Fonts) |
|---|---|
| Gastronomy / fashion / premium | Fraunces + Inter Tight |
| Architecture / tech | Instrument Serif + Geist (or Manrope) |
| Health / wellness / beauty | Cormorant Garamond + Figtree |
| Sport / automotive / industry | Archivo (expanded 600) + Archivo 400 |
| Kids / affective | Bricolage Grotesque + Nunito Sans |

Self-host woff2 when the project already self-hosts; otherwise Google Fonts `<link>` is acceptable for a standalone static site.

## Hero rhythm

`--height` of `.cine` between 380vh and 500vh. 3 moments: (1) who + h1, (2) concrete differentiator, (3) invitation + button. Moments follow the shot: text enters when the image reaches what it talks about. Mobile crops to the centre → keep the subject in the central third.

## Logo

File → 34px high in header and footer. Dark logo on dark theme: `filter: invert(1)` only if monochrome; else ask for the light version. No file → `.brand-text`. Never generate a logo with AI.

---

# Generation (OpenRouter) — only when assets are missing

Prompts in English. Same model, same STYLE block, same `--seed` family for every asset of one site.

## Model choice (confirm with `--list`; catalogue drifts)

| Video | Model |
|---|---|
| Default: architecture, interiors, landscape, luxury | `google/veo-3.1` (1080p, 8s) |
| People, fabric, food, liquids | `bytedance/seedance-2.0` |
| Product spin, macro, jewellery | `kwaivgi/kling-v3.0-pro` |
| Cheap test | `google/veo-3.1-fast`, `bytedance/seedance-2.0-fast` |

| Image | Model |
|---|---|
| Default | `google/gemini-3-pro-image` |
| Photoreal product/person | `openai/gpt-image-2` |
| Editorial texture | `black-forest-labs/flux.2-pro` |

## Consistency levers (use all)

- First **and** last keyframe (`--first-frame`, `--last-frame`): the model only fills the path.
- Fixed `--seed`; retry with the same seed and a tighter prompt before changing seed.
- `--reference key-first.png` on every section image → shared DNA.
- Two 4s shots cross-faded (`references/motion.md`) beat one perfect 8s shot.
- Background hex in the prompt **is** `--bg` in CSS. If the model drifts, flatten with ffmpeg: `-vf "colorlevels=rimin=0.02:gimin=0.02:bimin=0.02"` or regenerate; never fix it with a CSS border.

## STYLE block (append to every prompt)

```
STYLE: <3 mood words>, cinematic still, <35mm|50mm|85mm>, <soft window light|golden hour|low-key chiaroscuro>, color palette <bg hex>, <accent hex>, film grain, shallow depth of field, editorial photography, no text, no letters, no logo, no watermark, no frame, no border.
```

## Keyframes

```
Wide establishing shot of <concept scene>, <main subject> in the center third, generous negative space, background falls off into <bg colour in words> (<hex>). <niche details>. STYLE: ...
```
Last frame = the closing image that matches the CTA (same scene, end of the camera path).

## Video (image-to-video)

```
Single continuous shot, no cuts. The camera <slow dolly-in|slow 40° orbit|slow crane up|push through> <path>. First third: <...>. Middle: <reveal>. Final third: <closing image>. Smooth, steady, constant speed, no camera shake, no text, no logos, no people looking at the camera. Lighting stays consistent. STYLE: ...
```
Works both scroll directions: dolly-in, slow orbit, crane up, macro → wide. Avoid: digital zoom, people walking toward camera, particle bursts, transformations.

## Section images (fuse into background)

```
<subject>, isolated, emerging from a seamless <bg colour in words> (<hex>) background, the edges of the frame dissolve into pure <colour>, subject placed <on the right|on the left|in the center>, lots of empty <colour> space around it, <light> rim light, no horizon line, no walls, no floor edge. STYLE: ...
```
`.art--right` → subject right, empty left. `.art--left` → mirror. `.art--bg` → central, "out of focus, atmospheric". Light theme: "fades into a seamless warm off-white (<hex>) haze, high key".

## Visual checklist (look at screenshots)

- No image shows a corner, edge or straight cut.
- No text outside a panel.
- Text legible over the sequence at every moment.
- 390px: nothing overflows; WhatsApp button does not cover Submit.
- Hero scrubs smoothly both ways.
