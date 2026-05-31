---
name: learn-live-canvas
description: Search, learn, and download LiveCanvas page builder and Picostrap 5 WordPress theme documentation, hooks, and integration patterns from docs.livecanvas.com and livecanvas-team/picostrap5. Use when invoked explicitly, or when working with LiveCanvas, Picostrap, Bootstrap 5 WordPress themes, LC editable regions, child themes, or picostrap5 GitHub source.
disable-model-invocation: true
---

# Learn LiveCanvas & Picostrap

When invoked, search, learn, and download relevant documentation and hooks for the LiveCanvas site builder and Picostrap theme for WordPress, from:

- https://docs.livecanvas.com/
- https://github.com/livecanvas-team/picostrap5

## Invocation workflow

Copy this checklist and track progress:

```
Task Progress:
- [ ] Step 1: Run sync script (or refresh stale cache)
- [ ] Step 2: Identify topic from user request
- [ ] Step 3: Search cached docs + picostrap source
- [ ] Step 4: Fetch any missing live pages
- [ ] Step 5: Answer using downloaded material
```

### Step 1 — Sync local cache

Run from repo root:

```bash
bash .cursor/skills/learn-live-canvas/scripts/sync-docs.sh
```

Cache locations:

| Source | Path |
|--------|------|
| LiveCanvas docs (HTML) | `reference/cache/docs/` |
| Doc URL index | `reference/cache/doc-urls.txt` |
| Picostrap PHP/inc | `reference/cache/picostrap/` |
| Picostrap hooks index | `reference/cache/picostrap-hooks.txt` |

Re-sync when cache is missing, older than 7 days, or the user asks for latest docs.

### Step 2 — Map user topic to sources

| Topic | Start here |
|-------|------------|
| LC editor, sections, blocks | `reference/cache/docs/the-main-editor-interface.html`, `adding-sections.html`, `the-blocks-directory.html` |
| Editable regions, HTML structure | `creating-editable-regions.html`, `the-livecanvas-html-structure.html` |
| Child themes / UI kits | `integrating-ui-kits.html`, `reference/picostrap-integration.md` |
| Dynamic content, loops | `post-loops.html`, `dynamic-templating.html`, `tangible.html` |
| Forms | `forms-api.html` |
| Header/footer control | `header-builder.html`, `handling-the-footer.html`, `remove-header-and-footer.html` |
| CSS/JS customization | `the-css-editor.html`, `adding-custom-css-or-js.html`, `add-js-to-a-livecanvas-page-or-website.html` |
| WooCommerce | `woocommerce.html`, `woocommerce-shortcodes.html` |
| Picostrap SASS/customizer | `reference/cache/picostrap/README.md`, `inc/picosass-compiler-integration.php` |
| Picostrap ↔ LiveCanvas bridge | `reference/cache/picostrap/inc/livecanvas-config.php`, `inc/content-filtering.php` |
| WordPress hooks/filters | `reference/cache/picostrap-hooks.txt`, `reference/picostrap-hooks.md` |

Full URL list: [reference/doc-index.md](reference/doc-index.md)

### Step 3 — Search cached material

```bash
# Search LiveCanvas docs
rg -i "editable region|lc-block" .cursor/skills/learn-live-canvas/reference/cache/docs/

# Search Picostrap hooks
rg -i "add_action|add_filter|apply_filters" .cursor/skills/learn-live-canvas/reference/cache/picostrap/

# Search generated hooks index
rg -i "livecanvas|picostrap" .cursor/skills/learn-live-canvas/reference/cache/picostrap-hooks.txt
```

Prefer cached files over live fetches. Use live fetch only for gaps.

### Step 4 — Fetch missing pages

**LiveCanvas doc page** (slug from URL path):

```bash
curl -sL "https://docs.livecanvas.com/{slug}/" \
  -o ".cursor/skills/learn-live-canvas/reference/cache/docs/{slug}.html"
```

**Picostrap source file**:

```bash
curl -sL "https://raw.githubusercontent.com/livecanvas-team/picostrap5/master/{path}" \
  -o ".cursor/skills/learn-live-canvas/reference/cache/picostrap/{path}"
```

**Discover doc URLs** from sitemap:

```bash
curl -sL "https://docs.livecanvas.com/documentation-sitemap.xml" \
  | grep -oE '<loc>[^<]+</loc>' | sed 's/<[^>]*>//g'
```

**Browse picostrap repo**:

```bash
curl -sL "https://api.github.com/repos/livecanvas-team/picostrap5/contents/inc?ref=master"
```

Raw GitHub base: `https://raw.githubusercontent.com/livecanvas-team/picostrap5/master/`

### Step 5 — Respond from learned material

Summarize findings with:

1. Direct answer to the user's question
2. Relevant LC HTML attributes, shortcodes, or PHP patterns (with examples from cache)
3. Picostrap hooks/filters when theme integration is involved
4. Source links: `docs.livecanvas.com/{slug}/` or GitHub file path

Do not guess LC-specific APIs — verify in cached docs or fetch the page first.

## Key integration facts (Picostrap 5)

Picostrap declares LiveCanvas compatibility in `inc/theme-settings.php`:

- `lc_theme_is_livecanvas_friendly()` — empty stub; presence signals LC-friendly theme
- `lc_theme_bootstrap_version()` — returns `5.3`
- `lc_define_editor_config()` in `inc/livecanvas-config.php` — sets `config_file_slug => bootstrap-5.3`

Content filtering for LC plugin-off mode: `inc/content-filtering.php` strips LC attributes via `pico_strip_lc_attributes`.

Priority picostrap files to read after sync:

```
inc/livecanvas-config.php
inc/content-filtering.php
inc/theme-settings.php
inc/enqueues.php
inc/setup.php
inc/picosass-compiler-integration.php
functions.php
```

## Additional resources

- Curated hooks reference: [reference/picostrap-hooks.md](reference/picostrap-hooks.md)
- Doc URL index: [reference/doc-index.md](reference/doc-index.md)
- Official docs home: https://docs.livecanvas.com/
- Picostrap repo: https://github.com/livecanvas-team/picostrap5
