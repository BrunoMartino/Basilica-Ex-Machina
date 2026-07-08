---
name: learn-live-canvas
description: Search, learn, and download LiveCanvas page builder and Picostrap 5 WordPress theme documentation, hooks, and integration patterns from docs.livecanvas.com and livecanvas-team/picostrap5. Use when invoked explicitly, or when working with LiveCanvas, Picostrap, Bootstrap 5 WordPress themes, LC editable regions, child themes, or picostrap5 GitHub source.
disable-model-invocation: true
---

# Learn LiveCanvas & Picostrap

Answer LiveCanvas/Picostrap questions **from cached docs and source, never from memory**. Do not guess LC-specific APIs — verify in cache or fetch the page first.

## Workflow

1. **Sync cache** (skip if fresh, < 7 days): `bash .cursor/skills/learn-live-canvas/scripts/sync-docs.sh` from repo root.
2. **Locate sources** for the topic (table below), search with `rg`.
3. **Fetch gaps** only if the cache lacks the topic.
4. **Answer** with: direct answer → LC attributes/shortcodes/PHP patterns from cache → Picostrap hooks when theme integration is involved → source link (`docs.livecanvas.com/{slug}/` or GitHub path).

Cache layout: LiveCanvas HTML docs in `reference/cache/docs/`, Picostrap source in `reference/cache/picostrap/`, hooks index in `reference/cache/picostrap-hooks.txt`. Full URL list: [reference/doc-index.md](reference/doc-index.md).

## Topic → source

| Topic | Start here |
|-------|------------|
| LC editor, sections, blocks | `docs/the-main-editor-interface.html`, `adding-sections.html`, `the-blocks-directory.html` |
| Editable regions, HTML structure | `creating-editable-regions.html`, `the-livecanvas-html-structure.html` |
| Dynamic content, loops | `post-loops.html`, `dynamic-templating.html`, `tangible.html` |
| Forms | `forms-api.html` |
| Header/footer | `header-builder.html`, `handling-the-footer.html` |
| CSS/JS customization | `the-css-editor.html`, `adding-custom-css-or-js.html` |
| WooCommerce | `woocommerce.html`, `woocommerce-shortcodes.html` |
| Picostrap SASS/customizer | `picostrap/README.md`, `inc/picosass-compiler-integration.php` |
| Picostrap ↔ LC bridge | `picostrap/inc/livecanvas-config.php`, `inc/content-filtering.php` |
| WordPress hooks/filters | `picostrap-hooks.txt`, `reference/picostrap-hooks.md` |

## Fetching gaps

```bash
# LiveCanvas doc page (slug from URL)
curl -sL "https://docs.livecanvas.com/{slug}/" -o ".cursor/skills/learn-live-canvas/reference/cache/docs/{slug}.html"
# Picostrap source file
curl -sL "https://raw.githubusercontent.com/livecanvas-team/picostrap5/master/{path}" -o ".cursor/skills/learn-live-canvas/reference/cache/picostrap/{path}"
```

Doc URL discovery: `https://docs.livecanvas.com/documentation-sitemap.xml`.

## Key integration facts (Picostrap 5)

- `lc_theme_is_livecanvas_friendly()` (empty stub in `inc/theme-settings.php`) signals an LC-friendly theme; `lc_theme_bootstrap_version()` returns `5.3`.
- `lc_define_editor_config()` in `inc/livecanvas-config.php` sets `config_file_slug => bootstrap-5.3`.
- LC plugin-off mode strips LC attributes via `pico_strip_lc_attributes` in `inc/content-filtering.php`.
- Priority files: `inc/livecanvas-config.php`, `inc/content-filtering.php`, `inc/theme-settings.php`, `inc/enqueues.php`, `inc/setup.php`, `functions.php`.
