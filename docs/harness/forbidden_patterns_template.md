# forbidden_patterns.md

## Purpose

List patterns, architectures, and implementation habits that are forbidden by default.

## Forbidden Architectures By Default

The following are forbidden unless explicitly requested by the user or enabled in `architecture_rules.md`:

- Domain-Driven Design / DDD
- Clean Architecture
- Hexagonal Architecture
- Onion Architecture
- Ports and Adapters as a global architecture
- CQRS as a global architecture
- Event Sourcing as a global architecture

These patterns may be valid in other contexts, but they are not default choices for this project.

## Forbidden MVC Violations

- Large controllers containing complex business workflows.
- Views that query databases directly.
- Models that call external APIs directly.
- Jobs that duplicate business logic instead of calling services.
- Services that depend directly on HTTP request/response objects.
- Controllers that contain authorization rules inline instead of using policies/guards.

## Forbidden Abstraction Patterns

- Creating interfaces for every class by default.
- Creating repositories for every model by default.
- Creating factories for simple constructors.
- Creating service layers that only pass through to one method.
- Using “Manager”, “Helper”, or “Util” as vague dumping grounds.
- Adding patterns because they are fashionable rather than needed.

## Forbidden Data Patterns

- Updating critical state without transactions when consistency is required.
- Using nullable fields to encode many unrelated states.
- Persisting derived values without invalidation rules.
- Relying on timestamps alone for critical ordering.
- Mixing tenant/customer data without explicit scoping.

## Forbidden Error Patterns

- Catching errors and returning success.
- Swallowing exceptions without logs or recovery.
- Retrying non-idempotent operations blindly.
- Logging secrets, tokens, passwords, or sensitive PII.
- Throwing generic errors for known business failures.

## Forbidden Agent Patterns

- Introducing DDD/Clean Architecture without permission.
- Expanding task scope beyond the user request.
- Performing broad refactors for small changes.
- Adding dependencies without justification.
- Changing architecture because a generic best practice suggests it.
