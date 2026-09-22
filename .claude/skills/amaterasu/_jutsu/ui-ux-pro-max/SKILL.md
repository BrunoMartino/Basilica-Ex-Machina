---
name: ui-ux-pro-max
description: >-
  Internal amaterasu design-system intelligence — searchable CSV dataset (styles,
  palettes, fonts, UX, stacks) via Go CLI. Loaded by cast/paint; not invoked directly.
disable-model-invocation: true
---

# UI/UX Pro Max

84 styles, 192 palettes, 74 font pairings, UX guidelines, stack tips. Query via Go CLI — do not dump CSVs into context.

## When

New UI, palette/type choice, landing/dashboard, a11y review, after paint visual thesis.

## Priority rules (short)

1. A11y — contrast 4.5:1, focus, labels, keyboard
2. Touch — 44×44, tap not hover-only
3. Perf — WebP/srcset, reduced-motion, no CLS
4. Layout — viewport meta, no horizontal scroll, z-scale
5. Type/color — LH 1.5–1.75, ~65–75ch, pairing
6. Motion — 150–300ms micro; transform/opacity
7. Style match product; no emoji-as-icons
8. Charts — type fit data; table fallback

## CLI

From repo root (markdown only — never ANSI):

```bash
# From repo root (Go 1.20+ -C). Flags OK before/after query.
go -C .claude/skills/amaterasu/_jutsu/ui-ux-pro-max/cli run . search "<query>" -domain style|color|typography|ux|product -max 3

go -C .claude/skills/amaterasu/_jutsu/ui-ux-pro-max/cli run . search "<query>" -stack react|nextjs|html-tailwind

go -C .claude/skills/amaterasu/_jutsu/ui-ux-pro-max/cli run . design-system "<product> <industry> <mood>"

go -C .claude/skills/amaterasu/_jutsu/ui-ux-pro-max/cli run . audit .

# Optional build once (binary next to data/)
go -C .claude/skills/amaterasu/_jutsu/ui-ux-pro-max/cli build -o ../amaterasu-ui .
```

Data dir: `.claude/skills/amaterasu/_jutsu/ui-ux-pro-max/data/` (vendored CSVs).

**Thesis wins.** CLI is a proposal. Say what you kept/dropped. If `go` missing or CLI fails → one line + hand-derive from thesis.

Fonts from results: prefer self-host (see `web-styling`); do not paste Google Fonts CDN unless user asked.

## Persist

Paint writes `MASTER.md` at project root (orchestrator). CLI `--persist` optional if implemented; orchestrator owns final file.
