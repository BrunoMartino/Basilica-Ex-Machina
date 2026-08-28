---
name: tester
description: >-
  Write failing tests first, then minimal production code (TDD). Covers unit
  and integration tests with AAA structure, four-axis triangulation (happy,
  boundary, negative, adversarial), safe test isolation, mock/spy gates
  (independently derived expectations, exercise the real thing), test run
  documentation, Green-phase handoff docs (faseN.md + faseNTask.md), and
  brownfield post-Green refactor playbooks (refactor-faseN.md). Use before
  implementing new features, in greenfield or brownfield projects, or when
  the user asks for TDD, unit tests, or integration tests.
disable-model-invocation: true
---

# Tester (TDD)

## When to use

Invoke **before** writing production code for a new feature (legacy codebase or blank project): no new behavior without a failing test first—unless the user explicitly opts out.

## Harness docs first

Before planning or writing tests, read project testing expectations:

1. Prefer [`docs/harness/testing_expectation.md`](../../../docs/harness/testing_expectation.md) if present.
2. If missing, read [`docs/harness/testing_expectations_template.md`](../../../docs/harness/testing_expectations_template.md) (note the naming gap versus the `_template` convention) and do not invent stricter rules than that file implies.

Follow always-apply project rules (including harness documentation gates under `.cursor/rules/`) alongside those docs.

## Two principles

A test exists to catch a specific break. Two principles govern everything here:

```
1. Every test names the break it catches
2. Every test exercises the real thing
```

Strict TDD produces both naturally: a test written first and watched failing against real code has already proven it can fail, and only earns a mock when the real dependency proves slow or external.

### Principle 1: Name the Break

Before writing the test body, answer: **what production change should make this test fail — and is that change a bug or a decision?** A test earns its place by catching a wrong branch, missing side effect, wrong argument, boundary case, or broken contract.

**Derive expectations independently.** Use literals and hand-checked fixtures; table-driven tests with literal `want` values are the preferred shape. An expectation computed by the code under test — or its helpers — passes no matter what that code does:

```typescript
// ❌ Mirror assertion: the same builder computes both sides — always true
const expected = buildSearchQuery({ tag: 'urgent' });
expect(buildSearchQuery({ tag: 'urgent' })).toBe(expected);

// ✅ Hand-derived literal
expect(buildSearchQuery({ tag: 'urgent' })).toBe('tag:"urgent"');
```

**No change detectors.** If only intentional decisions can fail a test — a constant's value, exact message wording, private structure — it fires on redesign and sleeps through bugs. Test the behavior that depends on the decision: not `expect(MAX_RETRIES).toBe(5)` but "a failing call is retried 5 times and the 6th attempt never happens."

**Behavior, not text.** Asserting that a script, skill, or config contains an exact line proves only that the source is the source. Run scripts against controlled inputs and assert outputs, side effects, or exit codes. Documents that instruct agents are tested by the consuming agent's behavior (superpowers:writing-skills); prose for humans earns no test at all.

**Your code, not the framework.** Test the contract your code makes at its boundaries — the route you register, the query you emit, the payload you produce. Upstream mechanics are their maintainers' tests to write (the classic: asserting your router invokes a registered handler — that is the framework's test, not yours). When upstream behavior genuinely surprised you, write one narrow characterization test naming the assumption. The same boundary applies inside your code: constructors, getters, constants, and trivial forwarding earn tests only when they validate, normalize, default, derive, enforce, or cause side effects — otherwise assert the first consumer-visible result that depends on them.

#### Gate Function

```
BEFORE writing the test body:
  Name the production change that would make this test fail.

  Cannot name one            → redesign around an observable behavior
  "The source text changed"  → run the artifact and assert its effects
  Only intentional decisions → change detector; test the behavior
                               that depends on the decision

  Confirm the expected value is derived without the code under test.
  IF it reuses the code's logic or helpers:
    Replace it with a literal or hand-checked fixture
```

### Principle 2: Exercise the Real Thing

**The mock earns no assertions.** A mock assertion passes when the mock is present and fails when it is absent — it says nothing about the component. Assert the real component's behavior; if the mock is what you are checking, unmock it or delete the assertion.

```typescript
// ✅ Real behavior
expect(screen.getByRole('navigation')).toBeInTheDocument();

// ❌ Mock existence
expect(screen.getByTestId('sidebar-mock')).toBeInTheDocument();
```

**your human partner's correction:** "Are we testing the behavior of a mock?"

**Mock at the right level.** Learn every side effect of the real method before replacing it; mock the slow or external operation and keep what the test depends on real. When unsure, run the test against the real implementation first and observe what actually needs to happen.

```typescript
// ❌ The mock swallows the config write that duplicate detection reads
vi.mock('ToolCatalog', () => ({
  discoverAndCacheTools: vi.fn().mockResolvedValue(undefined)
}));

// ✅ Mock only the slow server startup; the config write stays real
vi.mock('MCPServerManager');
```

**Make doubles specific.** When arguments, call counts, or ordering are part of the contract, assert them — a fake that accepts anything verifies nothing. Give each branch (success, error, malformed) its own fixture or spy, so the wrong branch cannot satisfy the expectation.

**Mirror real data completely.** Mock the complete structure as it exists in reality — all documented fields — not just the ones your test reads. Partial mocks fail silently when downstream code reads an omitted field: the test passes while integration breaks.

**Production classes carry production methods only.** Cleanup that only tests need lives in test utilities, never as a `destroy()` on the production class. Ask: is this method called only from tests? Does this class own this resource's lifecycle? Wrong answers → test utility.

**Prefer real components over complex mocks.** When mock setup outgrows the test logic, mocks miss methods the real components have, or tests break when the mock changes, switch to an integration test with real components. **your human partner's question:** "Do we need to be using a mock here?"

#### Gate Function

```
BEFORE adding a mock or test helper:
  List the real method's side effects; keep the ones the test
  depends on real — mock the slow/external level below them.

  Mock responses mirror the complete real structure.

  A method only tests call lives in test utilities, not production.

  About to assert on the mock itself?
    Unmock it or delete the assertion.
```

When a double is introduced, **answer both partner questions in the Red report** — not as flavor text.

## TDD workflow

Copy and track progress:

- [ ] Detect project language and test runner/framework; confirm deps. Install or add tooling **only after user approval**.
- [ ] Write **exactly one** new failing unit or integration test (Red); pass both gate functions first.
- [ ] Repeat Red until the triangulation matrix for the phase slice is covered.
- [ ] Run the new test(s); confirm **Red** (failing as expected); report command and outcome.
- [ ] Create Green handoff docs for this phase (see below) — **mandatory before any production code**.
- [ ] Implement the **minimal** production code needed to turn tests green (Green) — own session or follow-up; use `fase{N}Task.md` as checklist.
- [ ] **Brownfield only:** after Green verification, create `docs/tdd/refactor-fase{N}.md` (see below); do **not** apply the legacy swap in Green.
- [ ] Refactor if needed without changing observable behavior (Refactor — cleans the **new** Green code only).
- [ ] Append a row to [`docs/testsReadme.md`](../../../docs/testsReadme.md) (suite/name, purpose, path, isolated run command).

## Green handoff docs (mandatory after Red)

When Red for an **implementation phase** is done, always create **both** files under `docs/tdd/` before writing production code:

| File | Purpose |
|------|---------|
| `docs/tdd/fase{N}.md` | Detailed step-by-step: minimal code for Green |
| `docs/tdd/fase{N}Task.md` | Same plan as checkboxes — execution control |

**Language rule (no exception):** every file written under `docs/tdd/` is **always English** — titles, headings, steps, checkboxes, comments in examples — even when the prompt, plan, or chat is in another language. Product names, paths, identifiers, and quoted user answers stay verbatim. This covers `fase{N}.md`, `fase{N}Task.md`, and `refactor-fase{N}.md`.

**`N`**: implementation phase number where the skill was invoked (TDD/design doc). If no explicit phase, use the next free integer in `docs/tdd/` (e.g. `fase1*` already exist → use `2`).

### `fase{N}.md` — minimum content

1. **Context** — phase, slice, Red tests written (paths).
2. **Red command** — how to run only these tests and confirm expected failure.
3. **Green steps** — numbered order: files to create/change, symbols, minimal logic per step; what **not** to implement yet.
4. **Verification** — command to confirm Green; done criteria.
5. **Brownfield only — post-Green playbook** — after Green verification, create `docs/tdd/refactor-fase{N}.md`; do not execute the legacy swap in Green.

### `fase{N}Task.md` — minimum content

Checkboxes mirroring the steps in `fase{N}.md`, one actionable line each:

```markdown
# Phase {N} — Green

- [ ] …
- [ ] …
- [ ] Phase tests pass: `<command>`
- [ ] Brownfield only: Create docs/tdd/refactor-fase{N}.md (legacy removal playbook; do not apply it in Green)
```

Rules:

- **Never** implement production in the same response that finishes Red **without** creating both files (unless the user explicitly asks for Green in the same message — still create the docs **before** the code).
- When implementing Green (same session or another), mark checkboxes in `fase{N}Task.md` as you progress.
- If Red is only an increment within a larger phase, update the existing phase docs instead of creating duplicates.

## Brownfield refactor playbook (post-Green)

**When it applies:** the Green slice **replaces or coexists with existing production code** that already implements the same behavior. Greenfield slices skip this file.

**Two different "refactors":**

- **Classic TDD Refactor:** clean the **new** Green code without changing observable behavior.
- **Brownfield playbook:** later swap **legacy production** for that Green code. Not the same step.

**Green must not swallow the swap.** In brownfield, Green implements the new tested production (typically new modules/paths the Red tests already import). It does **not** delete legacy, rewire production callers, or "fix" old tests. [`persisted-tester`](../../../.cursor/rules/persisted-tester.mdc) still wins: existing tests are immutable; the playbook only **lists** obsolete tests for the user to remove.

After Green verification passes, create `docs/tdd/refactor-fase{N}.md` (**always English**). Do **not** apply the playbook unless the user explicitly asks in that conversation.

### `refactor-fase{N}.md` — minimum content

1. **Context** — phase, Green artifacts (paths/symbols), tests that lock the new behavior.
2. **Legacy inventory** — current production files/symbols that implement the same behavior.
3. **Replacement map** — old → new (callers to rewire).
4. **Removal steps** — ordered, numbered; what to delete only after callers point at Green code.
5. **Do not touch** — persisted tests; secrets; unrelated modules.
6. **Obsolete tests** — paths + one-line reason; **user removes them manually**.
7. **Verification** — commands (new tests still green; smoke of rewired entrypoints).

## Three laws (TDD)

1. Production code exists only **after** a failing test exposes the need for it.
2. Only **one** new failing unit test before new production changes (fine-grained increments).
3. Production code stays **minimal**—just enough for the latest test(s) to pass.

## Triangulation matrix

For each feature slice, cover the four axes below with **one focused test each** (skip an axis only when it genuinely does not apply, and say so):

| Axis | What it exercises | Example |
|------|-------------------|---------|
| **Happy path** | The main behavior users care about | valid order → total computed |
| **Boundary** | Limits, off-by-one, empty/max values | 0 items, max guests, date edges |
| **Negative** | Invalid input, expected business failures | missing field → explicit error |
| **Adversarial** | Abuse of the contract when the unit touches auth, money, user input, or persistence | other user's ID → denied; injection-shaped string treated as data |

Rules:

- Different inputs/branches/assertions—**not** duplicate-looking tests that only tighten names.
- The adversarial axis is **mandatory** for code handling authorization, payments, file paths, queries, or any user-controlled input; optional for pure internal helpers.
- 4 meaningful tests per slice is the target; more only when a real branch demands it. Do not pad the suite—extra vacuous tests waste tokens and CI time.

## Test safety

- **Isolation**: tests never hit production databases, real external APIs, or shared mutable state. Use in-memory/ephemeral stores for databases. A mock or spy earns its place only after the real dependency proves slow or external — mock at the level below the side effect the test depends on, never as the thing being asserted.
- **Secrets**: never place real credentials, tokens, or PII in tests or fixtures—use obvious fakes (`test-key-123`).
- **Determinism**: control clock, randomness, and ordering; each test creates its own data (no order dependence).
- **Destructive ops**: never let a test (or its setup/teardown) delete or truncate anything outside its own sandboxed resources.

## Token economy

- During Red/Green, run **only the affected test file** (or single test via the runner's filter), not the whole suite.
- Run the broader suite **once** at the end of the slice; report pass/fail counts, not full output.
- Use the runner's quiet/minimal reporter when available; never paste full verbose logs into chat.
- Reuse Arrange helpers/factories instead of repeating long setup blocks in every test.

## Patterns

- Structure tests with **AAA**: Arrange → Act → Assert.
- Prefer tests that observe **behavior**, not flaky implementation trivia.
- Derive expected values independently — table-driven tests with literal `want` values are preferred.
- Start with the **public behavior** users care about before filling every internal helper unless the harness doc says otherwise.
- **One unit under test per unit test** (don't accidentally turn a focused test into a multi-module integration disguised as a unit test unless that is deliberate).
- Avoid **obvious or vacuous tests** that always pass without exercising the behavior.

Minimal AAA shape (adapt to project language/framework):

```typescript
it("should calculate total with discount", () => {
  // Arrange
  const foo = setupFoo(/* ... */);
  // Act
  const result = subject.doThing(foo);
  // Assert
  expect(result.value).toBe(1800); // hand-derived literal, not subject.doThing(foo)
});
```

## Anti-patterns

- Unit test **without** asserting on the outcome of the exercise (or without exercising the unit at all)—see [`examples.md`](examples.md).
- Integration tests whose success **depends on test order** (later test assumes state from an earlier case)—each test establishes its own data.
- Testing against live external services or real secrets.
- **Mirror assertions** — expected value computed by the same code or helpers as the subject.
- **Change detectors** — tests that fail only on intentional decisions (constants, exact wording, private structure).
- **Source-text tests** — asserting a file contains a line instead of running it and checking output or side effects.
- **Mock-existence assertions** — asserting a mock is present instead of the real component's behavior.
- **Partial doubles** — mock responses missing fields the real structure carries.
- **`destroy()` on production** — test-only lifecycle methods on production classes; use test utilities instead.

Full TypeScript-heavy examples remain **guides only**. Use this repository's languages, runners, and file layout when writing tests. See [`examples.md`](examples.md).

## Scope

- **In scope**: unit tests and integration tests; mocks/spies only when the Principle 2 gate passes.
- **Out of scope**: end-to-end tests unless the user requests them explicitly; applying `refactor-fase{N}.md` unless the user explicitly asks.

## Reporting

Always state what automated tests ran and anything **not** run (e.g. full suite omitted for time), which triangulation axes were skipped and why, the paths `docs/tdd/fase{N}.md` + `docs/tdd/fase{N}Task.md` when Red handoff was produced, and `docs/tdd/refactor-fase{N}.md` when the brownfield playbook was written. When a double is introduced, report answers to both partner questions. Respect project harness agent rules ("report what ran and did not run").
