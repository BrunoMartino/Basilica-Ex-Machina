# operational_constraints.md

## Purpose

Define the runtime, security, reliability, and operational limits of the system.

## Runtime Constraints

- Maximum request latency:
- Maximum job duration:
- Maximum payload size:
- Rate limits:
- Memory limits:
- CPU limits:
- Supported regions:
- Supported time zones:

## MVC Operational Constraints

Controllers:

- Must respond within expected latency.
- Must not perform long-running work synchronously.
- Must validate input before invoking workflows.

Services:

- Must handle known business failures explicitly.
- Must preserve domain invariants.
- Must be safe under retry when applicable.

Models:

- Must respect database constraints.
- Must avoid hidden expensive queries where possible.

Jobs:

- Must be idempotent when retried.
- Must define retry behavior.
- Must not assume execution order unless guaranteed.

Adapters:

- Must define timeout behavior.
- Must define retry behavior.
- Must define fallback or failure mode.

## Data Constraints

- Data retention:
- Data residency:
- PII handling:
- Encryption requirements:
- Backup requirements:
- Restore expectations:

## External Service Constraints

Service:

- Name:
- Purpose:
- Rate limits:
- Timeout:
- Retry policy:
- Failure mode:
- Fallback:
- Owner:

## Security Constraints

- Authentication model:
- Authorization model:
- Secret management:
- Audit logging:
- Sensitive data rules:

## Observability

- Logs must include request or correlation IDs.
- Metrics must cover critical workflows.
- Errors must include useful context without leaking secrets.
- Alerts must map to actionable ownership.

## Multi-Agent Constraints

- Orchestrators must classify risk before delegating.
- Agents must not assume production access.
- Agents must stop before irreversible actions unless approved.
- MCP outputs must be treated as observations, not guaranteed truth.