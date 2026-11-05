<?php
/**
 * amaterasu-sugoi · append to the child theme functions.php (LiveCanvas/Picostrap or isolated page template).
 * Assets live in <child>/sugoi/{styles.css,app.js,vendor/,frames/,img/}.
 */

const SUGOI_PAGES = ['home'];            // page slugs that get the cinematic layer
const SUGOI_FRAMES_TOTAL = 160;          // value printed by slice_frames.sh
const SUGOI_WHATSAPP = '';               // digits with country code; empty → button removed
const SUGOI_WHATSAPP_MSG = 'Olá!';
const SUGOI_CONTACT_EMAIL = '';          // destination for the REST route below; empty → form hidden

function sugoi_is_page(): bool { return is_page(SUGOI_PAGES); }

add_filter('body_class', function (array $c): array { if (sugoi_is_page()) $c[] = 'sugoi'; return $c; });

add_action('wp_enqueue_scripts', function (): void {
    if (!sugoi_is_page()) return;
    $u = get_stylesheet_directory_uri() . '/sugoi';
    $v = wp_get_theme()->get('Version') ?: '1.0';
    wp_enqueue_style('sugoi', "$u/styles.css", [], $v);
    wp_enqueue_script('gsap', "$u/vendor/gsap.min.js", [], '3', true);
    wp_enqueue_script('gsap-st', "$u/vendor/ScrollTrigger.min.js", ['gsap'], '3', true);
    wp_enqueue_script('sugoi', "$u/app.js", ['gsap-st'], $v, true);
    wp_add_inline_script('sugoi', 'window.SITE=' . wp_json_encode([
        'name'     => get_bloginfo('name'),
        'whatsapp' => ['number' => SUGOI_WHATSAPP, 'message' => SUGOI_WHATSAPP_MSG],
        'contact'  => ['endpoint' => SUGOI_CONTACT_EMAIL ? esc_url_raw(rest_url('sugoi/v1/contact')) : '',
                       'subject'  => 'Novo contato pelo site ' . get_bloginfo('name')],
        'messages' => ['fix' => 'Confira os campos destacados.', 'sending' => 'Enviando…',
                       'sent' => 'Recebemos seu contato. Em breve falamos com você.',
                       'failed' => 'Não foi possível enviar agora. Chame no WhatsApp.'],
        'frames'   => ['total' => SUGOI_FRAMES_TOTAL,
                       'desktop' => "$u/frames/desktop/f_{n}.webp", 'mobile' => "$u/frames/mobile/f_{n}.webp"],
    ]) . ';', 'before');
}, 20);

// Cache/optimizer plugins: exclude handles gsap, gsap-st, sugoi from defer/delay/combine.

// Contact via wp_mail. Remove if a form plugin (CF7, WPForms, Fluent) handles the form instead.
add_action('rest_api_init', function (): void {
    register_rest_route('sugoi/v1', '/contact', [
        'methods'             => 'POST',
        'permission_callback' => '__return_true',
        'callback'            => function (WP_REST_Request $r) {
            if (!SUGOI_CONTACT_EMAIL) return new WP_Error('off', 'disabled', ['status' => 404]);
            $p = $r->get_json_params() ?: [];
            if (!empty($p['_honey'])) return ['success' => true];
            $name = sanitize_text_field($p['name'] ?? ''); $email = sanitize_email($p['email'] ?? '');
            if (!$name || !is_email($email)) return new WP_Error('bad', 'invalid', ['status' => 400]);
            $body = "Nome: $name\nE-mail: $email\nWhatsApp: " . sanitize_text_field($p['phone'] ?? '')
                  . "\n\n" . sanitize_textarea_field($p['message'] ?? '');
            $ok = wp_mail(SUGOI_CONTACT_EMAIL, sanitize_text_field($p['subject'] ?? 'Contato'), $body, ["Reply-To: $email"]);
            return ['success' => (bool) $ok];
        },
    ]);
});
