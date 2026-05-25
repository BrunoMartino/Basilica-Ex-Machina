# architecture_rules.md

## Purpose

Define the architectural style, module boundaries, allowed abstractions, and agent behavior for this project.

## Default Architecture

This project uses MVC as the preferred architectural style.

The default structure should be simple, explicit, and framework-aligned:

- Model: data structure, persistence mapping, validation close to persisted data when appropriate.
- View: presentation layer, UI templates, response formatting, or client-facing representation.
- Controller: request handling, input parsing, orchestration of application flow, and response coordination.
- Service: business workflows that do not belong directly in controllers or models.
- Repository / DAO: persistence access when direct model access becomes too coupled or repetitive.
- Policy / Guard: authorization and access rules.
- Validator / Form Object / Request Object: input validation at boundaries.
- Job / Worker: asynchronous execution.

## Design Patterns

Design Patterns may be used when they reduce real complexity.

Preferred patterns:

- Factory: for object creation with branching rules.
- Strategy: for interchangeable business behavior.
- Adapter: for external services, SDKs, APIs, or infrastructure boundaries.
- Repository: for complex persistence access.
- Observer / PubSub: for domain or application events.
- Decorator: for behavior composition without changing core classes.
- Command: for explicit user or system actions.
- Policy: for authorization and permission checks.

Avoid pattern usage when it only adds ceremony.

## DDD And Clean Architecture Usage

DDD and Clean Architecture are not default architectures for this project.

They may only be used when:

- The user explicitly requests them.
- This file explicitly enables them for a specific module.
- A documented architectural decision approves their use.

Allowed scopes, if enabled:

- Specific bounded module:
- Specific domain area:
- Specific refactor:
- Specific new subsystem:

DDD/Clean Architecture must not be introduced globally without explicit approval.

## Architectural Principles

- Prefer MVC and local framework conventions.
- Keep controllers thin enough to remain readable.
- Move reusable business workflows into services.
- Keep models focused on data, relationships, validation, and simple domain behavior.
- Use adapters for external systems.
- Avoid unnecessary layering.
- Avoid abstractions that do not serve current complexity.

## Dependency Rules

Allowed:

- Controller -> Service
- Controller -> Model
- Service -> Model
- Service -> Repository / Adapter
- View -> presentation data only
- Job -> Service

Avoid:

- View -> direct persistence logic
- Controller -> external SDK directly
- Model -> controller or view
- Service -> framework request/response objects
- Job -> duplicated business logic

## Multi-Agent Rules

- Agents must prefer MVC unless told otherwise.
- Agents must not introduce DDD or Clean Architecture unless explicitly allowed.
- Agents may suggest Design Patterns, but must justify why the pattern is needed.
- Reviewer agents must flag unnecessary abstraction.
- Orchestrator agents must check this file before delegating architecture changes.

## MCP Rules

- MCPs may provide external state, logs, docs, or operational context.
- MCP output must not override architectural rules.
- Write/destructive MCP actions require explicit user approval.