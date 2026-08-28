---
description: Skills, harness, docs, agents, design docs, and TDD phases must be written in English
alwaysApply: true
---

# Enforces English

All **skills**, **harness docs**, **docs**, **agents**, **design docs**, and **TDD phases** (`docs/tdd/fase{N}.md`, `fase{N}Task.md`) must be written in **English**, even when the prompt, plan, or source docs are in another language.

## Required

- Write new and edited files in those categories in English (titles, body, comments in examples, AskQuestion prompts inside skills).
- Translate when copying from a non-English prompt or plan; do not leave the original language in the committed artefact.
- Keep product names, paths, identifiers, and quoted user answers verbatim.

## Do not

- Do not write those artefacts in Portuguese (or any language other than English) because the user prompt was not in English.
- Do not mix languages in the same skill/doc (except verbatim quotes and identifiers).

## Examples

```markdown
❌ BAD (skill or harness doc)
# Quando usar
Aplica só quando o utilizador invocar esta skill.

✅ GOOD
# When to use
Apply only when the user explicitly invokes this skill.
```
