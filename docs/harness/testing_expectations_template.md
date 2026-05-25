# testing_expectation.md

## Purpose

Define the testing expectations for an MVC project using pragmatic Design Patterns.

## Testing Philosophy

- Test behavior, not implementation details.
- Keep tests close to the level of risk.
- Domain invariants must be tested directly.
- Bug fixes require regression tests.
- Avoid testing framework internals.

## MVC Test Expectations

Controller tests:

- Verify request handling, authorization, response status, redirects, and payload shape.
- Mock or isolate external services when appropriate.
- Avoid testing complex business rules only through controllers.

Model tests:

- Verify validations, relationships, scopes, simple domain behavior, and persistence rules.
- Cover critical constraints.

Service tests:

- Verify business workflows.
- Cover branching rules, failure modes, and side effects.
- Prefer these for non-trivial business logic.

Policy / Guard tests:

- Verify access rules.
- Cover allowed and denied cases.

Adapter tests:

- Verify mapping between project code and external systems.
- Avoid real external calls in regular test suites unless explicitly marked.

Job tests:

- Verify enqueueing, idempotency, retry behavior, and service invocation.

## Design Pattern Test Expectations

Factory:

- Test creation rules and invalid inputs.

Strategy:

- Test each strategy independently.
- Test strategy selection separately.

Adapter:

- Test request/response mapping.
- Test external failure handling.

Command:

- Test success, validation failure, and side effects.

Policy:

- Test permission matrix clearly.

## Minimum Requirements

Every change should include:

- Relevant automated tests.
- Regression coverage for fixed bugs.
- Tests for affected domain invariants.
- Manual verification notes only when automation is insufficient.

## Agent Rules

- Agents must add focused tests for changed behavior.
- Agents must not add broad brittle tests just to increase coverage.
- Reviewer agents must flag missing invariant tests.
- Test agents must report what was run and what was not run.