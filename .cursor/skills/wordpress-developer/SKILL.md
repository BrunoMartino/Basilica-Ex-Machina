---
name: wordpress-developer
description: >-
  Scans a local WordPress theme for the most common WordPress attack surfaces
  and hardens them via theme code: XML-RPC, RSS feeds, comments, reviews, user
  enumeration, REST API exposure, CORS for WP/WooCommerce APIs, version
  disclosure, security headers, and template escaping. Use when working on a
  WordPress theme, hardening WordPress, or when the user mentions wp
  vulnerabilities, xmlrpc, wp-json, or WooCommerce API security.
---

# WordPress Developer (theme hardening)

Scan the **local theme** being worked on, report which attack surfaces are open, and mitigate them through theme code (`functions.php` or an `inc/security.php` included by it). Server/`wp-config.php` items are recommendations to report, not silent edits.

## Workflow

1. **Scan** — check the theme (and report site-level gaps) against the checklist below. Search for existing mitigations first (`rg "xmlrpc|rest_authentication|disable_feed" <theme>/`) to avoid duplicates.
2. **Ask scope** — confirm with the user which surfaces to disable (some sites legitimately need comments, feeds, or reviews).
3. **Mitigate** — group all snippets in `inc/security.php`, loaded from `functions.php` with `require_once get_template_directory() . '/inc/security.php';` (child theme: `get_stylesheet_directory()`).
4. **Verify** — list the URLs/behaviors to test (e.g. `curl -i https://site/xmlrpc.php`, `/?feed=rss2`, `/wp-json/wp/v2/users`).
5. **Report** — mitigated, skipped by user choice, and out-of-theme recommendations.

## Attack-surface checklist

| # | Surface | Risk |
|---|---------|------|
| 1 | `xmlrpc.php` | brute-force amplification (`system.multicall`), pingback DDoS |
| 2 | RSS/Atom feeds | content scraping, author/user disclosure |
| 3 | Comments (+ pingbacks/trackbacks) | spam, stored XSS, SEO injection |
| 4 | Product reviews/ratings (WooCommerce) | same as comments |
| 5 | User enumeration (`?author=N`, `/wp-json/wp/v2/users`, oEmbed author data) | login brute-force targeting |
| 6 | REST API over-exposure | data disclosure to anonymous clients |
| 7 | CORS on WP REST / WooCommerce API | cross-origin data theft, CSRF-adjacent abuse |
| 8 | Version disclosure (generator meta, `?ver=` on assets, `readme.html`) | fingerprinting known CVEs |
| 9 | Missing security headers | clickjacking, MIME sniffing, XSS |
| 10 | Login exposure (unlimited attempts, verbose errors, application passwords) | credential stuffing |
| 11 | Theme output escaping/nonces | XSS, CSRF in custom templates and forms |
| 12 | Emojis/embeds/heartbeat excess | surface + performance |
| 13 | File editing in admin, debug display, uploads executing PHP, directory listing | RCE / info leak (out-of-theme) |

## Mitigation snippets (`inc/security.php`)

```php
<?php
defined('ABSPATH') || exit;

// 1. XML-RPC off (methods, pingback header, X-Pingback)
add_filter('xmlrpc_enabled', '__return_false');
add_filter('xmlrpc_methods', '__return_empty_array');
add_filter('wp_headers', function ($headers) { unset($headers['X-Pingback']); return $headers; });

// 2. Feeds off → redirect home
foreach (['do_feed', 'do_feed_rdf', 'do_feed_rss', 'do_feed_rss2', 'do_feed_atom'] as $feed) {
    add_action($feed, function () { wp_redirect(home_url(), 301); exit; }, 1);
}
remove_action('wp_head', 'feed_links', 2);
remove_action('wp_head', 'feed_links_extra', 3);

// 3. Comments + pingbacks off
add_filter('comments_open', '__return_false', 20);
add_filter('pings_open', '__return_false', 20);
add_filter('comments_array', '__return_empty_array', 10);
add_action('admin_menu', function () { remove_menu_page('edit-comments.php'); });

// 4. WooCommerce reviews off
add_filter('woocommerce_product_tabs', function ($tabs) { unset($tabs['reviews']); return $tabs; }, 98);
add_filter('comments_open', fn($open, $post_id) => get_post_type($post_id) === 'product' ? false : $open, 20, 2);

// 5. User enumeration blocked
add_action('template_redirect', function () {
    if (is_author() || (isset($_GET['author']) && !is_admin())) { wp_redirect(home_url(), 301); exit; }
});
add_filter('rest_endpoints', function ($endpoints) {
    if (!is_user_logged_in()) {
        unset($endpoints['/wp/v2/users'], $endpoints['/wp/v2/users/(?P<id>[\d]+)']);
    }
    return $endpoints;
});
add_filter('oembed_response_data', function ($data) { unset($data['author_name'], $data['author_url']); return $data; });

// 6. REST API: require auth except allowlisted public namespaces
add_filter('rest_authentication_errors', function ($result) {
    if (!empty($result) || is_user_logged_in()) return $result;
    $route = $_SERVER['REQUEST_URI'] ?? '';
    $public = ['/wp-json/wc/store', '/wp-json/contact-form-7']; // adjust per site
    foreach ($public as $prefix) { if (str_contains($route, $prefix)) return $result; }
    return new WP_Error('rest_forbidden', 'Authentication required.', ['status' => 401]);
});

// 7. CORS: replace permissive defaults with explicit origin allowlist
add_action('rest_api_init', function () {
    remove_filter('rest_pre_serve_request', 'rest_send_cors_headers');
    add_filter('rest_pre_serve_request', function ($value) {
        $allowed = ['https://app.example.com']; // adjust per site
        $origin  = get_http_origin();
        if ($origin && in_array($origin, $allowed, true)) {
            header('Access-Control-Allow-Origin: ' . esc_url_raw($origin));
            header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
            header('Access-Control-Allow-Credentials: true');
            header('Vary: Origin');
        }
        return $value;
    });
}, 15);

// 8. Version disclosure
remove_action('wp_head', 'wp_generator');
add_filter('the_generator', '__return_empty_string');
$strip_ver = fn($src) => $src ? remove_query_arg('ver', $src) : $src;
add_filter('style_loader_src', $strip_ver, 9999);
add_filter('script_loader_src', $strip_ver, 9999);

// 9. Security headers (if not set at the web server)
add_action('send_headers', function () {
    header('X-Frame-Options: SAMEORIGIN');
    header('X-Content-Type-Options: nosniff');
    header('Referrer-Policy: strict-origin-when-cross-origin');
    header('Permissions-Policy: camera=(), microphone=(), geolocation=()');
});

// 10. Login hardening: generic error, no application passwords
add_filter('login_errors', fn() => 'Credenciais inválidas.');
add_filter('wp_is_application_passwords_available', '__return_false');

// 12. Emojis, embeds, RSD/WLW links off
remove_action('wp_head', 'print_emoji_detection_script', 7);
remove_action('wp_print_styles', 'print_emoji_styles');
remove_action('wp_head', 'wp_oembed_add_discovery_links');
remove_action('wp_head', 'wp_oembed_add_host_js');
remove_action('wp_head', 'rsd_link');
remove_action('wp_head', 'wlwmanifest_link');
```

## Theme code review (item 11)

When touching template/theme PHP, enforce:

- **Escape all output**: `esc_html()`, `esc_attr()`, `esc_url()`, `wp_kses_post()` — never echo raw `$_GET`/`$_POST`/meta.
- **Sanitize all input**: `sanitize_text_field()`, `absint()`, etc., at the point of entry.
- **Nonces** on every custom form/AJAX action (`wp_nonce_field()` + `check_admin_referer()` / `check_ajax_referer()`), plus capability checks (`current_user_can()`).
- **Prepared queries**: `$wpdb->prepare()` for any custom SQL.

## Out-of-theme recommendations (report, don't edit silently)

- `wp-config.php`: `define('DISALLOW_FILE_EDIT', true);`, `WP_DEBUG_DISPLAY` false in production, fresh salts, non-default table prefix.
- Web server: block `xmlrpc.php` and `readme.html`/`license.txt`, deny PHP execution in `wp-content/uploads/`, disable directory listing, rate-limit `wp-login.php`.
- Replace `wp-cron.php` with a real cron job on busy sites (`DISABLE_WP_CRON` + system cron).
- Keep core/plugins/themes updated; remove unused plugins and themes.
