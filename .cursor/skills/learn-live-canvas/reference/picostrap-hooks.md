# Picostrap 5 — LiveCanvas integration & hooks

Source: https://github.com/livecanvas-team/picostrap5 (run sync for latest)

## LiveCanvas-specific

| Symbol | File | Purpose |
|--------|------|---------|
| `lc_theme_is_livecanvas_friendly()` | `inc/theme-settings.php` | Declares theme as LC-compatible |
| `lc_theme_bootstrap_version()` | `inc/theme-settings.php` | Returns Bootstrap version `5.3` |
| `lc_define_editor_config($key)` | `inc/livecanvas-config.php` | LC editor config; `config_file_slug => bootstrap-5.3` |
| `pico_strip_lc_attributes` | `inc/content-filtering.php` | Strips LC attributes when plugin disabled |
| `pico_alter_content_filters` | `inc/content-filtering.php` | Toggles content filters on `wp` hook |

## Theme setup & filters

| Hook / filter | File | Notes |
|---------------|------|-------|
| `after_setup_theme` → `picostrap_setup` | `inc/setup.php` | Menus, HTML5, thumbnails, post formats |
| `excerpt_length` | `inc/setup.php` | 22 words |
| `excerpt_more` → `picostrap_custom_excerpt_more` | `inc/setup.php` | Bootstrap-styled read-more link |
| `wp_trim_excerpt` → `picostrap_all_excerpts_get_more_link` | `inc/setup.php` | Appends read-more to auto excerpts |
| `get_the_archive_title` | `inc/setup.php` | Cleans archive titles |
| `embed_oembed_html` → `bootstrap_wrap_oembed` | `inc/setup.php` | Responsive embed wrapper |
| `wp_video_shortcode` → `picostrap_bs_ratio_for_wp_video` | `inc/setup.php` | Bootstrap ratio classes on video |
| `picostrap_enable_sourcemap_in_css` | `inc/setup.php` | Source maps in compiled CSS |
| `picostrap_theme_default_settings` | `inc/theme-settings.php` | Filter theme default customizer values |

## Assets & enqueue

| Hook | File | Notes |
|------|------|-------|
| `wp_enqueue_scripts` | `inc/enqueues.php` | Loads `css-output/bundle.css` |
| `wp_head` | `inc/enqueues.php` | Header code, chrome color, preload hints |
| `wp_footer` | `inc/enqueues.php` | Footer custom code from customizer |
| `clean_url` → `picostrap_add_css_error_handling` | `inc/enqueues.php` | CSS load error fallback |
| `send_headers` → `picostrap_hints` | `inc/enqueues.php` | Resource hints (optional) |
| `template_redirect` | `inc/enqueues.php` | Dequeue conflicting Bootstrap |

Helper functions: `picostrap_get_css_url()`, `picostrap_get_css_version()`, `picostrap_get_complete_css_filename()`.

## WooCommerce

| Hook | File |
|------|------|
| `after_setup_theme` → `picostrap_woocommerce_support` | `inc/woocommerce.php` |
| `woocommerce_before_main_content` / `after_main_content` | `inc/woocommerce.php` |
| `woocommerce_form_field_args` | `inc/woocommerce.php` |
| `woocommerce_quantity_input_classes` | `inc/woocommerce.php` |

## SASS compilation

| Action | File | Notes |
|--------|------|-------|
| `picostrap_save_css_bundle` | `inc/picosass-compiler-integration.php` | AJAX save of compiled CSS to `css-output/bundle.css` |

## Template helpers

| Function | File |
|----------|------|
| `picostrap_site_info()` | `inc/template-tags.php` |
| `picostrap_the_sharing_buttons()` | `inc/template-tags.php` |

## Opt-in features (loaded from `functions.php`)

Enabled via customizer theme mods:

- `disable-comments.php`, `back-to-top.php`, `open-menu-on-hover.php`
- `lightbox.php`, `initialize-tooltips.php`, `detect-page-scroll.php`
- `disable-gutenberg.php`, `disable-widgets-block-editor.php`, `disable-xml-rpc.php`

## Child theme extension points

- Override Bootstrap variables in child `sass/_custom.scss`
- Filter `picostrap_theme_default_settings` for customizer defaults
- Override `picostrap_get_css_optional_subfolder_name()` / `picostrap_get_base_css_filename()` in child theme
- Implement custom `lc_define_editor_config()` in child theme for different UI kit slug
