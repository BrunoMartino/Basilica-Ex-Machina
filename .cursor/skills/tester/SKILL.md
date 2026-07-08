---
name: tester
description: >-
  Write failing tests first, then minimal production code (TDD). Covers unit
  and integration tests with AAA structure, four-axis triangulation (happy,
  boundary, negative, adversarial), safe test isolation, mocks/spies, and
  test run documentation. Use before implementing new features, in greenfield
  projects, or when the user asks for TDD, unit tests, or integration tests.
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

## TDD workflow

Copy and track progress:

- [ ] Detect project language and test runner/framework; confirm deps. Install or add tooling **only after user approval**.
- [ ] Write **exactly one** new failing unit or integration test (Red).
- [ ] Implement the **minimal** production code needed to turn it green (Green).
- [ ] Refactor if needed without changing observable behavior (Refactor).
- [ ] Repeat until the triangulation matrix for the slice is covered.
- [ ] Run the new test(s); report the command and outcome.
- [ ] Append a row to [`docs/testsReadme.md`](../../../docs/testsReadme.md) (suite/name, purpose, path, isolated run command).

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

- **Isolation**: tests never hit production databases, real external APIs, or shared mutable state. Use in-memory/ephemeral stores and mocks/spies for externals (deterministic results).
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
  expect(result.value).toBe(expected);
});
```

## Anti-patterns

- Unit test **without** asserting on the outcome of the exercise (or without exercising the unit at all)—see [`examples.md`](examples.md).
- Integration tests whose success **depends on test order** (later test assumes state from an earlier case)—each test establishes its own data.
- Testing against live external services or real secrets.

Full TypeScript-heavy examples remain **guides only**. Use this repository's languages, runners, and file layout when writing tests. See [`examples.md`](examples.md).

## Scope

- **In scope**: unit tests and integration tests; mocks/spies for externals when appropriate.
- **Out of scope**: end-to-end tests unless the user requests them explicitly.

## Reporting

Always state what automated tests ran and anything **not** run (e.g. full suite omitted for time), plus which triangulation axes were skipped and why. Respect project harness agent rules ("report what ran and did not run").
