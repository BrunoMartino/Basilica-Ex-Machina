# Examples for get-my-tools

Invocation patterns, permission prompts, and sample output. Source repo: [BrunoMartino/Michelangelo-Dev-Toolkit](https://github.com/BrunoMartino/Michelangelo-Dev-Toolkit) (`main`).

---

## User messages that trigger this skill

- "Get my tools"
- "Install harness skills from Michelangelo-Dev-Toolkit"
- "Bring tester and code-commenter into this project"
- "Install all rules from Michelangelo-Dev-Toolkit"
- "Bootstrap Claude Code config in this dev container"
- "Copy harness templates and all-for-harness rule from GitHub"

---

## Skip listing (user named items)

User: **"Install tester, code-commenter, and the all-for-harness rule."**

Agent:

1. Resolve: `tester/`, `code-commenter/`, `.claude/rules/all-for-harness.md`
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
- `all-for-harness.md`
- `less-talk.md`
- `dont-write-env.md`

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

- `.claude/skills/tester/` already exists. **Skip, overwrite, or abort?**
- `all-for-harness.md` and `less-talk.md` would overwrite local rules. **Overwrite both, skip existing, or abort?**
- Installing **full kit** would touch 12 paths; 3 already exist. **Skip existing only, overwrite all, or abort?**

If the user declines, stop and offer manual raw URLs or:

```bash
gh api repos/BrunoMartino/Michelangelo-Dev-Toolkit/contents/.claude/skills/tester \
  --jq '.[].name'
```

---

## Bundle aliases

| User says | Resolves to |
|-----------|-------------|
| `all skills` | Every folder under `.claude/skills/` |
| `all rules` | Every `.md` under `.claude/rules/` |
| `harness templates` | `docs/harness/*_template.md` |
| `full kit` | All skills + rules + harness templates + `docs/testsReadme.md` |

---

## Example summary (after successful install)

```markdown
**Installed**
- `tester` → `.claude/skills/tester/` (SKILL.md, examples.md)
- `code-commenter` → `.claude/skills/code-commenter/`
- `all-for-harness.md` → `.claude/rules/all-for-harness.md`

**Skipped**
- `less-talk.md` (already present; user chose skip)

**Next**
- Rename and fill harness templates under `docs/harness/` when ready.
```

---

## Dev container note

When shell access to a local clone is unavailable, prefer **`gh api`** or **raw.githubusercontent.com** over asking the user to copy from WSL. Sparse clone to `/tmp` is a last resort after user approval.
