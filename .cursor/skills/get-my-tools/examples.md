# Examples for get-my-tools

Invocation patterns, permission prompts, and sample output. Source repo: [BrunoMartino/personal_harness_eng](https://github.com/BrunoMartino/personal_harness_eng) (`main`).

---

## User messages that trigger this skill

- "Get my tools"
- "Install harness skills from personal_harness_eng"
- "Bring tester and code-commenter into this project"
- "Install all rules from personal_harness_eng"
- "Bootstrap Cursor config in this dev container"
- "Copy harness templates and harness-docs rule from GitHub"

---

## Skip listing (user named items)

User: **"Install tester, code-commenter, and the harness-docs rule."**

Agent:

1. Resolve: `tester/`, `code-commenter/`, `.cursor/rules/harness-docs.mdc`
2. Check for existing paths → permission if conflicts
3. Fetch and write — **no full catalog**

---

## Show catalog first (bare invocation)

User: **"Get my tools"**

Agent presents:

```markdown
### Skills
| Name | Description |
|------|-------------|
| `tester` | TDD: failing tests first, then minimal code |
| `code-commenter` | Block comments for non-trivial logic after implementation |
| … | … |

### Rules
- `harness-docs.mdc`
- `less-talk.mdc`
- `dont-write-env.mdc`

### Harness templates
- `architeture_rules_template.md`
- `coding_conventions_template.md`
- …

### Other
- `docs/testsReadme.md`
```

Then ask: **Which items should I install?** (multi-select or bundle OK)

---

## Permission prompts (overwrite conflicts)

Ask before writing when targets already exist:

- `.cursor/skills/tester/` already exists. **Skip, overwrite, or abort?**
- `harness-docs.mdc` and `less-talk.mdc` would overwrite local rules. **Overwrite both, skip existing, or abort?**
- Installing **full kit** would touch 12 paths; 3 already exist. **Skip existing only, overwrite all, or abort?**

If the user declines, stop and offer manual raw URLs or:

```bash
gh api repos/BrunoMartino/personal_harness_eng/contents/.cursor/skills/tester \
  --jq '.[].name'
```

---

## Bundle aliases

| User says | Resolves to |
|-----------|-------------|
| `all skills` | Every folder under `.cursor/skills/` |
| `all rules` | Every `.mdc` under `.cursor/rules/` |
| `harness templates` | `docs/harness/*_template.md` |
| `full kit` | All skills + rules + harness templates + `docs/testsReadme.md` |

---

## Example summary (after successful install)

```markdown
**Installed**
- `tester` → `.cursor/skills/tester/` (SKILL.md, examples.md)
- `code-commenter` → `.cursor/skills/code-commenter/`
- `harness-docs.mdc` → `.cursor/rules/harness-docs.mdc`

**Skipped**
- `less-talk.mdc` (already present; user chose skip)

**Next**
- Rename and fill harness templates under `docs/harness/` when ready.
```

---

## Dev container note

When shell access to a local clone is unavailable, prefer **`gh api`** or **raw.githubusercontent.com** over asking the user to copy from WSL. Sparse clone to `/tmp` is a last resort after user approval.
