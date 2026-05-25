# coding_convention.md

## Purpose

Define coding style and implementation preferences for an MVC-based project.

## General Style

- Prefer clear, framework-native MVC code.
- Keep code readable before clever.
- Avoid premature abstraction.
- Follow existing project conventions.
- Use explicit names for business concepts.
- Keep functions and methods focused.

## MVC Conventions

Controllers:

- Parse inputs.
- Call services or models.
- Return responses.
- Avoid complex business logic.

Models:

- Represent persisted data and relationships.
- Contain simple domain behavior when natural.
- Avoid external API calls.
- Avoid large workflow orchestration.

Services:

- Hold business workflows.
- Coordinate models, repositories, adapters, and jobs.
- Should be named after use cases or business actions.

Views / Presenters / Serializers:

- Format output.
- Avoid persistence and business decisions.
- Avoid hidden data fetching when possible.

Repositories / DAOs:

- Use when queries become complex or repeated.
- Avoid wrapping every model by default.

## Design Pattern Conventions

Use Design Patterns only when they clarify intent.

Acceptable examples:

- `PaymentStrategy`
- `NotificationAdapter`
- `InvoiceFactory`
- `AccessPolicy`
- `CreateOrderCommand`

Avoid generic names like:

- `Manager`
- `Processor`
- `Handler`
- `Helper`
- `Util`

Unless the responsibility is very clear.

## Naming

- Controllers should describe resources or actions.
- Services should describe business workflows.
- Policies should describe permissions.
- Adapters should name the external system.
- Factories should name what they create.
- Strategies should name the interchangeable behavior.

## Error Handling

- Expected business failures should be explicit.
- Unexpected errors should preserve context.
- Do not leak secrets or internal traces to users.
- Do not silently ignore failures.

## Agent Rules

- Agents must keep edits aligned with MVC.
- Agents must avoid introducing DDD/Clean terminology unless enabled.
- Agents must use existing framework conventions first.
- Agents must not refactor into layers without explicit need.