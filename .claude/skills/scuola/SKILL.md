---
name: scuola
description: >-
  Ideation method that turns a raw concept into a researched, stress-tested
  Schizzo (`<projectName>Schizzo.md`): open-ended clarification, web research (community evidence
  mainly from Reddit, Substack and Medium), adversarial review through 7 lenses in fresh
  contexts, iterative refinement until the idea survives, and a Mermaid
  drawing of the resulting project. Operated by the
  `inventore` agent, upstream of the feature harness and the design docs. Use
  when the user wants to brainstorm, validate or mature an idea before
  writing `docs/harness/features/feature-{name}.md` or a design doc.
disable-model-invocation: true
---

# Scuola: research-backed, adversarial ideation

Scuola decides **whether** and **what** is worth building. It ends in one artifact — the Schizzo, the compiled record of everything asked, researched, debated and decided, plus the Mermaid drawing of the project — that the user then uses to answer the feature harness questions or to start a design doc. It never writes specs, code or `docs/`.

Operator: the `inventore` agent, running as the main agent. If you are not Inventore, stop and tell the user to start it. If the harness has no sub-agent tool, stop too: a review in the same context is not an adversarial review.

## Economy rules (binding for the operator and every sub-agent)

1. **A finding earns its place only if it changes a decision** — scope, tool choice, design, or go / no-go. Everything else is dropped, however interesting.
2. **No edge-case hunting.** Only `blocker` and `major` issues exist. Minor issues, style remarks and hypothetical corner cases are not reported.
3. **No padding.** No background explanations, no restating the hypothesis, no summaries of what was just done, no "it depends" without the deciding factor.
4. **Hard caps** (never exceeded, may be undershot): 3 questions per chat turn; 3 Astrolabi; 5 searches and 3 page fetches per Astrolabio; 5 findings per Astrolabio; 3 objections per Avversario; Schizzo of 200 lines.
5. **"Nothing found" and "no objection" are valid results.** Never manufacture findings to fill a quota.
6. **Sub-agent reports are fields only**, in the formats below. They are never pasted into the chat.
7. **Re-runs are partial**: on iteration, re-spawn only the research angles and lenses the change affects.

## Conduct

- Stress-test by default. Lead with what is wrong, missing or risky; state merits after. Agree only with what survived scrutiny.
- Never echo the user's framing back as validation. For each proposed approach, state the strongest counter-argument and whether it holds.
- No flattery ("great", "smart", "correct", "spot-on") and no apologies. When corrected, state the corrected logic or trade-off directly.
- Plain, direct language. No promotional adjectives or decorative adverbs.
- Chat in the user's language. The Schizzo is always written in English (quoted user answers stay verbatim).
- Proposals, digests, diagrams and compiled content go to the Schizzo file, never to the chat. The chat carries questions, the file path and the top objections.
- Every gate is exactly one question, is the only tool call of its turn, and carries no recommended option.

## Artifact

`especs/scuola/<projectName>Schizzo.md` — always this name, and the only file Scuola writes. `<projectName>` is the project's name in camelCase (`checkoutFlowSchizzo.md`); take it from the user's concept, and ask only if it has no usable name. Sub-agents receive its path, not its content, and return their reports to the operator; only the operator writes it.

```markdown
# <Project name> — Schizzo

- Author: <git config user.name, else GIT_AUTHOR_NAME, else ask>
- Date: <YYYY-MM-DD>
- Status: clarified | researched | reviewed | final

## Hypothesis
<2-3 sentences: what is built, for whom, and the outcome it produces.>

## Problem and success measure
<The pain today, how it is handled now and why that fails, and the measure that proves success.>

## Scope
- Goals: <...>
- Non-goals: <...>
- Hard constraints: <...>

## Context
<Brownfield only, max 10 lines: constraints taken from `docs/harness/` and `graphify-out/GRAPH_REPORT.md`.>

## Questions and answers
| Question asked | User's answer |
|----------------|---------------|
<Every question of Steps 1 and 4 with the user's answer: verbatim when short, otherwise condensed to one line without changing its meaning.>

## Research
| Finding | Kind | Source | Signal | Impact on the decision |
|---------|------|--------|--------|------------------------|

## Debate
| Lens | Verdict | Objection | Severity | Resolution |
|------|---------|-----------|----------|------------|

## Alternatives weighed
<Each option rejected, with the reason and who rejected it (author, research finding, or lens).>

## Decisions
<Decisions settled during ideation, to carry forward.>

## Open risks
<Unresolved blocker/major objections, if the user chose to accept them.>

## Design
<One Mermaid `flowchart` of the project as decided: actors, components, data stores, external services and the tools chosen in `Decisions`, with the main flows between them. Max 25 nodes; it shows what was decided, never options still open.>
```

## Workflow

### Step 1 — Clarify

1. If the user gave no concept, ask for it. Resolve `Author`.
2. Ask open-ended questions in plain chat, across as many turns as needed, until these six points are answered. No structured question tool and no pre-written answer options in this step. Do not ask what the user already answered.
   - Which problem, bottleneck or pain does this solve?
   - Who or what consumes it, and under which guarantees?
   - Which constraints are non-negotiable?
   - What is out of scope?
   - How is it handled today, and why does that fail?
   - How is success measured?
3. Brownfield: read only the harness docs and the Graphify report the concept touches; record the constraints for `Context`. No source sweeps.
4. **Readiness gate** (AskQuestion; `AskUserQuestion` in Claude Code; plain chat if the harness has neither), one question:
   - Question: `Hypothesis: <2-3 sentence summary>. How do you want to proceed?`
   - Options: `Research and review` · `Clarify more in chat`
5. `Clarify more in chat` keeps you in Step 1. Only `Research and review` allows any sub-agent to be spawned. Then write the Schizzo (`Hypothesis` to `Questions and answers`, `Status: clarified`).

### Step 2 — Research (Astrolabi)

Spawn up to 3 Astrolabi in parallel, one per angle. Skip an angle the hypothesis makes pointless and say which.

| Angle | Brings back |
|-------|-------------|
| `prior-art` | Solutions already built for the same or a close problem: what they did, what worked, what was abandoned and why |
| `building-blocks` | Tools, frameworks, libraries and services that would assemble this, with the community's verdict on each |
| `community-practice` | Practices, tips and pitfalls reported by people who built or operated something similar |

Research rules:
- **Sources follow the question.** Use whatever source answers the angle best — a tool's official documentation or repository, a benchmark, an engineering write-up. Forums are not mandatory in every search.
- **When the evidence sought is community experience** (opinions, tips, pitfalls, "what people actually use"), search mainly Reddit, Substack and Medium, using the tool's domain filter or `site:` operators (`reddit.com`, `substack.com`, `medium.com`). Another forum is used only when those three return nothing useful, and the `gaps` line says so.
- Prefer posts from the last 24 months; always record the post date.
- Search-result snippets count as evidence when sufficient. If a page fetch fails, do not retry it: move on.
- First-hand experience outweighs opinion. Mark `signal: consensus` only when several independent authors or a clearly supported thread agree; otherwise `single-author`.
- Drop tutorials, listicles and promotional posts that carry no experience report.

Astrolabio report:

```
angle: <prior-art | building-blocks | community-practice>
findings (max 5, strongest first):
- claim: <one concrete sentence>
  kind: solution | tool | practice | pitfall
  source: <url> (<platform>, <YYYY-MM>)
  signal: consensus | single-author
  impact: <the decision in the hypothesis it changes, and how>
gaps: <one line: what was searched and not found>
```

Deduplicate the reports, drop findings whose `impact` is empty or generic, and write the `Research` table (`Status: researched`).

### Step 3 — Adversarial review (Avversari)

Spawn one Avversario per lens, all in a single message so they run in parallel and cannot bias each other. Each runs in a fresh context: it knows only the Schizzo (`Hypothesis` to `Research`) and its lens. Skip a lens that plainly does not apply (for example, Migration on a greenfield with no existing clients or data) and record the skip in `Debate`.

| Lens | Attacks | Core question |
|------|---------|---------------|
| Contrarian / YAGNI | Need and complexity | Why must this exist? Does something in `Research` or already in use solve most of it without new code? |
| Cost and quota | Infrastructure and budget at scale | What are the peak load, storage, query and token costs, and which ceiling is hit first? |
| UX and developer ergonomics | Usability and cognitive load | Is the interface (UI, API, CLI) obvious, conventional for its ecosystem, and clear when it fails? |
| Migration and compatibility | Rollout safety | How do existing clients and data move over, what breaks, and how is a half-done rollout reverted? |
| Observability and operability | Production visibility | How does whoever is on call see that it failed, find the cause and fix it? |
| Tech debt and maintenance | Long-term cost of ownership | Which coupling, state or dependency introduced here becomes expensive to change in two years? |
| Inventive catalyst | Accepted trade-offs | Which trade-off does the design treat as inevitable, and which known transform removes the conflict instead of balancing it? |

Avversario report:

```
lens: <name>
verdict: holds | holds-with-changes | fails
objections (max 3, blocker and major only):
- objection: <one sentence>
  severity: blocker | major
  basis: <the fact in the Schizzo or the research finding it rests on>
  change: <the concrete change that resolves it>
```

An objection with no `basis` in the Schizzo is speculation: discard it. Deduplicate across lenses, order by severity, and write `Debate`, `Alternatives weighed` and the first `Design` drawing (`Status: reviewed`).

### Step 4 — Iterate

1. In chat: the Schizzo path and the 2-3 strongest objections, one line each. Nothing else.
2. Ask one open question: how the user wants to address them (pivot, narrow the scope, add a constraint, accept the risk).
3. Apply the answer to the Schizzo: the question and answer go to `Questions and answers`, resolved objections get their `Resolution`, accepted ones move to `Open risks`, choices go to `Decisions`, and `Design` is redrawn to match `Decisions`.
4. If the hypothesis changed, re-run only the affected research angles and lenses (new readiness gate first if the problem statement itself changed).
5. Repeat until no `blocker` is unresolved and the user is satisfied.

### Step 5 — Hand off

Check that `Design` matches `Decisions` and that every section is filled or marked `none`, set `Status: final`, ask the user to confirm the Schizzo, then present one gate:

- Question: `Schizzo finalized at <path>. Select the next step:`
- Options:
  - `Feature harness` — tell the user to create `docs/harness/features/feature-{name}.md` (skill `harness-create`) with the Schizzo as reference. The 4 mandatory answers are the user's; Scuola never writes or pre-fills them, and never writes under `docs/`.
  - `Design doc for a fix` — when the concept corrects existing behaviour instead of adding a feature: tell the user to run `design-docs-creator` in fix mode, pointing it at the Schizzo.
  - `Keep refining` — return to Step 4.
  - `Conclude` — end the session; the Schizzo stays in `especs/scuola/`.
