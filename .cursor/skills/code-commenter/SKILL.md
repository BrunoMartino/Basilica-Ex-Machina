---
name: code-commenter
description: >-
  Documents complex functions and business rules with consistent block
  comments (JSDoc/TSDoc-style when applicable) after implementation. Use when
  the user asks for comments on non-trivial logic, post-refactor docs, or
  documentation readable by humans and agents; omit for trivial or obvious
  code where naming suffices.
disable-model-invocation: true
---

# Code commenter

## When to use

Apply **after** the implementation exists: add or refresh comments once the behavior and structure are stable. Do **not** use this skill while writing new code unless the user explicitly asks for simultaneous comments—default is document **after**.

## Out of scope

- Comments that merely restate obvious code—prefer clearer names instead.
- Low-complexity one-liners unless the user insists.

## Harness docs first

If the project defines comment or doc conventions, follow them:

1. If present, read [`docs/harness/coding_convention.md`](../../../docs/harness/coding_convention.md) before bulk commenting.
2. If missing, rely on this skill and local file conventions only.

Follow always-apply project rules (including harness gates under `.cursor/rules/`) when they touch documentation style.

## What every comment must include

For each documented unit (typically a non-trivial function, class slice, or business-rule block):

1. **Brief description** — what it does at a glance.
2. **Inputs and dependencies** — parameters, key types, collaborators, env/config, side effects.
3. **Where and when** — call sites, routes, server-only vs client, invariants, ordering constraints.

Use the project’s normal doc syntax (JSDoc, TSDoc, Go doc, etc.).

## Block shape (language-agnostic)

Adapt wording to the codebase; keep this structure:

```text
[Name or one-line summary]

[What it does — short paragraph or bullet flow]

[Dependencies / params / external systems]

[Where to use — routes, modules, constraints]
```

Concrete JSDoc patterns and good vs bad length examples: see [examples.md](examples.md).

## Notes

Examples in [examples.md](examples.md) are **guides only**—mirror the same information density and sections for the code at hand, in the correct language and style for the repo.
