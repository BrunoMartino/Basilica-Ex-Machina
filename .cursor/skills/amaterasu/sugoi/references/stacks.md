# Stack integration

Build in a staging folder `<p>/site/` first (static layout), run `verify.py` there, then integrate. Read only the section that matches `stack=`.

## Isolated backend (static front + API) / JS framework

**Assets**: frames and images stay static (`public/`, CDN). Never pass frames through an upload pipeline.

**GSAP**: project has `package.json` → ask, then `npm i gsap`. Expose globals once, before `app.js`:

```js
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";
window.gsap = gsap; window.ScrollTrigger = ScrollTrigger;
import "./app.js";
```

Framework routes (Next/Astro/Vite): drop `index.html` body into the page component; `styles.css` as a global or scoped import; `config.js` → inline `window.SITE = {...}` or env-fed. React: run `app.js` in `useEffect`/`useGSAP` and call `ScrollTrigger.getAll().forEach(t => t.kill())` on cleanup.

**Contact**: `contact.endpoint` = existing route (`/api/contact`, `/contact`, …). Payload is flat JSON `{name, email, phone, message, subject}`; honeypot `_honey` is stripped client-side. If the route expects form-encoded or a CSRF token, set `action` on the `<form>` and let it submit natively (app.js does not intercept forms with `action`).

**Headless WordPress**: same as above; copy comes from REST/WPGraphQL into the template placeholders at build time. Contact → `sugoi/v1/contact` from `template/wp/sugoi-enqueue.php` or any existing form plugin endpoint.

## WordPress + LiveCanvas (Picostrap)

Works as the main theme: LiveCanvas emits the HTML you write, Picostrap adds no wrappers with `overflow`/`transform` and no smooth-scroll runtime. Use the child theme.

1. **Assets** → `wp-content/themes/<child>/sugoi/{styles.css,app.js,vendor/,frames/,img/,logo.*}`. Not the media library.
2. **PHP** → append `template/wp/sugoi-enqueue.php` to the child `functions.php`. Fill `SUGOI_PAGES` (slugs), WhatsApp, contact e-mail, `frames.total`. It enqueues GSAP + app, injects `window.SITE`, adds body class `sugoi`, registers `POST /wp-json/sugoi/v1/contact` (wp_mail). If a form plugin already exists (CF7, WPForms, Fluent) → paste its shortcode in place of `<form class="form">` and drop the REST route.
3. **Markup** → in the LiveCanvas editor paste each `<section>` from `index.html` as a section (header/footer go to the theme header/footer or as first/last sections). Replace `assets/img/x.webp` with `/wp-content/themes/<child>/sugoi/img/x.webp`. Remove the `<script src>` and `<link rel=stylesheet>` lines (enqueued by PHP). Keep the Google Fonts `<link>` or move it to `wp_enqueue_style`.
4. **Bootstrap collisions**: everything is scoped under `body.sugoi`; if a Picostrap utility still wins (headings, `.container` padding), raise specificity with `body.sugoi .x` rather than `!important`.
5. **Cache / optimizer plugins** (WP Rocket, LiteSpeed, Autoptimize, Perfmatters): exclude handles `gsap`, `gsap-st`, `sugoi` from defer/delay/combine; exclude `/sugoi/` from image lazy-load and from "remove unused CSS". Tell the user in HANDOFF.
6. **Ancestor with `overflow:hidden`** (page builder wrapper, theme container): `position: sticky` on `.cine-stage` breaks → switch to ScrollTrigger pin (recipe in `motion.md`).
7. **R3F** does not fit LiveCanvas (needs a separate React build). 3D → vanilla Three.js in `app.js`.

## WordPress without LiveCanvas (Elementor, Divi, block themes)

Ask: **isolated page template** or **headless**.

- **Isolated template**: `page-sugoi.php` in the child theme with a blank `<body class="sugoi">`, `wp_head()` / `wp_footer()` kept, theme + builder styles dequeued on that template (`wp_dequeue_style`/`wp_dequeue_script` at priority 100). Copy from ACF/options into `window.SITE` and placeholders. Same asset layout and PHP snippet as LiveCanvas.
- **Headless**: see Isolated backend.

Builders inject wrappers with `transform`/`overflow` and their own smooth-scroll: do not place the hero inside a builder section.

## Static

Already the default build. `vendor_gsap.sh` downloads pinned GSAP + ScrollTrigger into `assets/vendor/`. Hosting: any static host; frames are ~5–12 MB on mobile, enable Brotli/long cache.
