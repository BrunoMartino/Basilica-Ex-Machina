---
name: web-styling
description: >-
  Internal amaterasu module. Tailwind vs Bootstrap detection, token wiring,
  font self-hosting, framework breakpoints, max-width 1920px centered container.
disable-model-invocation: true
---

# Web Styling

Loaded by cast/paint on web stacks. Not a slash skill.

## Detect

| Signal | Mode |
|--------|------|
| `tailwindcss` in package.json / `@tailwind` / `@theme` | Tailwind |
| `bootstrap` in package.json / `bootstrap` SCSS/CSS import | Bootstrap |
| Both | Ask once which to write for this task |
| Neither | Prefer Tailwind if greenfield; else vanilla CSS vars |

Also detect: CSS `:root` tokens, existing `@font-face`, files under `public/fonts` / `assets/fonts` / `src/fonts`.

## Design brief (orchestrator runs this)

Missing any of: primary, secondary, tertiary, success, danger, warning, fonts → AskQuestion one field at a time.

Fonts absent:

1. Ask: OK to use Google Fonts family?
2. Default path: download woff2 into project (`public/fonts/` or stack-equivalent), `@font-face`, preload. **No CDN** unless user explicitly asks CDN.
3. Wire font-family into Tailwind theme or Bootstrap `$font-family-sans-serif` / CSS vars.

Map brief → tokens:

| Role | Tailwind | Bootstrap |
|------|----------|-----------|
| primary | `--color-primary` / theme.colors.primary | `$primary` / `--bs-primary` |
| secondary | `--color-secondary` | `$secondary` / `--bs-secondary` |
| tertiary | `--color-tertiary` (custom) | custom `$tertiary` + CSS var |
| success | `--color-success` | `$success` |
| danger | `--color-danger` | `$danger` |
| warning | `--color-warning` | `$warning` |

## Iron: breakpoints + 1920 container

Always build responsive layouts with the active framework breakpoints. Always wrap site chrome:

```html
<!-- Tailwind -->
<div class="mx-auto w-full max-w-[1920px]">...</div>

<!-- Bootstrap -->
<div class="mx-auto w-100" style="max-width:1920px">...</div>
<!-- or utility class .container-amaterasu { max-width:1920px; margin-inline:auto; width:100%; } -->
```

Ideal for 4K / >21" ultrawide: content centered, not stretched edge-to-edge.

### Breakpoints

| Name | Tailwind (default) | Bootstrap 5 |
|------|--------------------|-------------|
| sm | 640px | 576px |
| md | 768px | 768px |
| lg | 992px (TW 1024) | 992px |
| xl | 1280px | 1200px |
| 2xl / xxl | 1536px | 1400px |

Use prefix utilities of the active framework (`md:flex`, `md-flex`, etc.). Do not invent custom breakpoint names unless project already has them.

## Tailwind ↔ Bootstrap 5 parity (dense)

| Intent | Tailwind | Bootstrap 5 |
|--------|----------|-------------|
| Flex row | `flex` | `d-flex` |
| Flex col | `flex-col` | `flex-column` |
| Grow | `grow` | `flex-grow-1` |
| Gap | `gap-4` | `gap-4` |
| Grid | `grid grid-cols-3` | `row` + `col-*` |
| Hidden | `hidden` | `d-none` |
| Block | `block` | `d-block` |
| Show md+ | `hidden md:block` | `d-none d-md-block` |
| p/m | `p-4` `m-2` | `p-4` `m-2` |
| Text center | `text-center` | `text-center` |
| Rounded | `rounded-lg` | `rounded-3` |
| Shadow | `shadow-md` | `shadow` |
| Bg primary | `bg-primary` (token) | `bg-primary` |
| Text primary | `text-primary` | `text-primary` |
| Button | custom / ui lib | `btn btn-primary` |
| Container | `max-w-[1920px] mx-auto` | see above |
| W full | `w-full` | `w-100` |
| H full | `h-full` | `h-100` |
| Absolute | `absolute inset-0` | `position-absolute top-0 start-0 end-0 bottom-0` |
| Z | `z-10` | `z-1` … |

Spacing: both ~0.25rem steps. Prefer tokens over magic px.

## Token wiring recipes

**Tailwind v4 `@theme`:**

```css
@theme {
  --color-primary: #...;
  --color-secondary: #...;
  --color-tertiary: #...;
  --color-success: #...;
  --color-danger: #...;
  --color-warning: #...;
  --font-sans: "Family", ui-sans-serif, system-ui, sans-serif;
  --breakpoint-*: /* keep framework defaults */;
}
```

**Bootstrap SCSS:**

```scss
$primary: #...;
$secondary: #...;
$success: #...;
$danger: #...;
$warning: #...;
$tertiary: #...; // custom — also set --bs-tertiary
$font-family-sans-serif: "Family", system-ui, sans-serif;
@import "bootstrap/scss/bootstrap";
```

## Font self-host

1. Pick family (from brief / ui-ux-pro-max / user).
2. Download woff2 weights needed (400/500/700 typical).
3. Place under `public/fonts/<family>/`.
4. CSS:

```css
@font-face {
  font-family: "Family";
  src: url("/fonts/Family/family-400.woff2") format("woff2");
  font-weight: 400;
  font-style: normal;
  font-display: swap;
}
```

5. Optional `<link rel="preload" as="font" href="..." type="font/woff2" crossorigin>`.
6. CDN (`fonts.googleapis.com`) only if user asked.

## BAD / GOOD

| BAD | GOOD |
|-----|------|
| Stretch layout full 4K width | `max-width:1920px` centered |
| CDN fonts by default | Self-host woff2 |
| Hardcode hex in components | Theme tokens |
| Mix TW + BS utilities randomly | One framework per surface |
| Custom breakpoints ignoring framework | Use sm/md/lg/xl/(2xl\|xxl) |
