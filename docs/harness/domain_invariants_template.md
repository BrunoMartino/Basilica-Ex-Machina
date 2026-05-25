# domain_invariantes.md

## Purpose

Define the business truths that must always remain valid.

## What Is A Domain Invariant?

A domain invariant is a rule that must always be true for the business, regardless of which controller, service, job, command, import, migration, or agent changed the system.

It is stronger than a simple validation.

A validation usually checks whether one input is acceptable.  
An invariant protects the consistency of the business state over time.

Example:

- Validation: “email must have a valid format.”
- Invariant: “a user cannot belong to two tenants with conflicting access scopes.”
- Validation: “order quantity must be greater than zero.”
- Invariant: “a paid order cannot be changed in a way that alters the charged amount without issuing an adjustment.”

## Invariant Template

### INV-001: [Invariant Name]

Description:

- 

Business reason:

- 

Must always be true when:

- 

Applies to:

- Controllers:
- Models:
- Services:
- Jobs:
- Events:
- Database tables:

Enforced by:

- Model validation:
- Service rule:
- Database constraint:
- Transaction:
- Policy / Guard:
- Test coverage:

Failure impact:

- 

## Common MVC Enforcement Points

Model:

- Use for simple validations, relationships, and local consistency.

Service:

- Use for multi-step business workflows.

Policy / Guard:

- Use for authorization invariants.

Database:

- Use for uniqueness, foreign keys, non-null constraints, and critical consistency.

Job:

- Use cautiously; jobs should preserve invariants, not redefine them.

Controller:

- Should not be the only place enforcing important invariants.

## Concurrency Rules

- Define which invariants require transactions.
- Define which invariants require locking.
- Define which invariants require idempotency keys.
- Define which invariants can be eventually consistent.

## Agent Rules

- Agents must check this file before changing business behavior.
- Agents must not weaken invariants without explicit approval.
- Any change affecting an invariant must include tests.
- Reviewer agents must identify touched invariants.