# Examples for update-my-graph

Permission prompts, update strategy, and sample user triggers. After a successful graph update, **legacy-explainer runs automatically** (no extra confirmation).

---

## User messages that trigger this skill

- "Update my graph after these changes"
- "Refresh graphify-out"
- "Reinstall graphify and rebuild the graph"
- "I refactored auth — update the knowledge graph"
- "Graphify shows skill version mismatch — fix it"
- "Remove ghost duplicate nodes from the graph"

---

## Permission prompts

Ask before any install or graph write. Examples:

- Graphify is not on PATH. **May I reinstall it with `uv tool install graphifyy --force`?** (Official package: `graphifyy`; CLI: `graphify`.)
- `graphify-out/` exists but `check-update` shows 12 changed files. **May I run `graphify update .`?**
- You mentioned a large refactor and duplicate nodes. **May I run `graphify extract . --force` to rebuild the graph?**
- CLI works but project integration is missing. **May I run `graphify cursor install --project`?**
- Graphify version mismatch detected. **May I run `uv tool upgrade graphifyy` and refresh the Cursor integration?**

If the user declines, stop and offer manual commands:

```bash
graphify update .
# or for full rebuild:
graphify extract . --force
```

---

## Incremental vs force — decision table

| Signal | Prefer |
|--------|--------|
| Few files changed; small fixes | `graphify update .` or `graphify . --update` |
| `check-update` shows minor pending changes | Incremental |
| Large refactor; many files moved/deleted | `graphify extract . --force` or `graphify .` |
| Ghost duplicates; same entity twice in graph | `graphify extract . --force` |
| Graph has fewer nodes after refactor (old nodes linger) | `graphify update . --force` or `graphify extract . --force` |
| JSON OK; only communities/clustering stale | `graphify cluster-only .` |
| Semantic extraction fails (no API keys) | Ask, then AST: `graphify update . --no-cluster` + `graphify cluster-only .` |

When unsure, ask once: **"Incremental update or full rebuild with --force?"**

---

## CLI reinstall examples (after approval)

```bash
# uv (preferred)
uv tool upgrade graphifyy
# or clean reinstall:
uv tool install graphifyy --force

# pipx
pipx upgrade graphifyy
# or:
pipx reinstall graphifyy

# pip
pip install --upgrade graphifyy
# or:
pip install --force-reinstall graphifyy

# always refresh project integration
graphify cursor install --project
```

---

## Sample output summary

After a successful run:

```
Graph action: incremental update (`graphify update .`)
graphify-out/: graph.json, GRAPH_REPORT.md, graph.html updated
Graph mode: full semantic extraction
Legacy-explainer: overwrote architeture_rules_template.md, coding_conventions_template.md,
  domain_invariants_template.md, operational_constraints_template.md
```

After CLI-only fix (graph already current):

```
Graph action: CLI upgrade (`uv tool upgrade graphifyy`) + `graphify cursor install --project`
graphify-out/: unchanged (check-update reported no pending changes)
Legacy-explainer: skipped graph rebuild; refreshed harness templates from existing graph
```

(If graph was unchanged, legacy-explainer still runs from Step 3 using existing `graphify-out/`.)

---

## Related skills

| Skill | When |
|-------|------|
| [`update-my-graph`](../update-my-graph/SKILL.md) | Maintain CLI + refresh `graphify-out/` after code changes |
| [`legacy-explainer`](../legacy-explainer/SKILL.md) | Chained automatically after graph update; harness templates only |

Do **not** invoke `graphify uninstall --purge` unless the user explicitly asks to delete `graphify-out/`.
