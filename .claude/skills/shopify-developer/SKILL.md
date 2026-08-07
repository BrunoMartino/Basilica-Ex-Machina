---
name: shopify-developer
description: Complete Shopify development reference covering Liquid templating, OS 2.0 themes, GraphQL APIs, Hydrogen, Functions, and performance optimization (API v2026-01). Use when working with .liquid files, building Shopify themes or apps, writing GraphQL queries for Shopify, debugging Liquid errors, creating app extensions, migrating from Scripts to Functions, or building headless storefronts. Triggers on "Shopify", "Liquid template", "Hydrogen", "Storefront API", "theme development", "Shopify Functions", "Polaris". Do NOT use for non-Shopify e-commerce platforms.
---

# Shopify Developer Reference

API version **2026-01**. Read only the reference file(s) matching the task — do not load all of them.

## Quick reference

| Item | Value |
|------|-------|
| GraphQL Admin | `POST https://{store}.myshopify.com/admin/api/2026-01/graphql.json` (header `X-Shopify-Access-Token`) |
| Storefront API | `POST https://{store}.myshopify.com/api/2026-01/graphql.json` |
| Ajax API (theme) | `/cart.js`, `/cart/add.js`, `/cart/change.js` |
| CLI | `npm install -g @shopify/cli` · `shopify theme dev --store {store}.myshopify.com` · `shopify app dev` / `deploy` |

Always prefer **GraphQL Admin over REST** (REST is in active deprecation).

## Task → reference file

| Task | Read |
|------|------|
| Writing/debugging `.liquid` | [liquid-syntax.md](references/liquid-syntax.md), [liquid-filters.md](references/liquid-filters.md), [liquid-objects.md](references/liquid-objects.md) |
| Theme building (OS 2.0, sections, blocks, JSON templates, settings schema) | [theme-development.md](references/theme-development.md) |
| Admin data (GraphQL, OAuth, webhooks, rate limits) | [api-admin.md](references/api-admin.md) |
| Storefront/cart operations | [api-storefront.md](references/api-storefront.md) |
| App building (CLI, extensions, Polaris Web Components, App Bridge) | [app-development.md](references/app-development.md) |
| Custom business rules (Functions, Scripts migration) | [functions.md](references/functions.md) |
| Headless storefronts (Hydrogen, React Router 7) | [hydrogen.md](references/hydrogen.md) |
| Performance / Core Web Vitals | [performance.md](references/performance.md) |
| Errors: Liquid, API, cart, webhooks | [debugging.md](references/debugging.md) |

## Deprecations

| Deprecated | Replacement |
|------------|-------------|
| Shopify Scripts | Shopify Functions |
| checkout.liquid | Checkout Extensibility (done) |
| REST Admin API | GraphQL Admin API |
| Polaris React | Polaris Web Components |
| Remix (app framework) | React Router 7 (Hydrogen 2025.5.0+) |

## Liquid in 10 lines

```liquid
{{ product.title | upcase }}                    {# output + filter #}
{% if product.available %}In stock{% endif %}   {# logic #}
{% assign sale = product.price | times: 0.8 %}  {# assignment #}
{%- if x -%}stripped whitespace{%- endif -%}
{% for product in collection.products limit: 5 %}
  {% render 'product-card', product: product %}
{% endfor %}
{% paginate collection.products by 12 %}
  ... {{ paginate | default_pagination }}
{% endpaginate %}
```
