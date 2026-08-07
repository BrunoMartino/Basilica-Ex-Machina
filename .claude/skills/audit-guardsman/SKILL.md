---
name: audit-guardsman
description: >-
  Ensures privileged and restricted-data operations emit stdout single-line JSON
  audit logs with canonical fields, event naming, UTC timestamps, log-injection
  protection, and no secrets/PII in log values. Use when adding admin flows,
  RBAC changes, privileged APIs, restricted data access, compliance logging,
  or event_id / event_type instrumentation.
disable-model-invocation: true
---

# Audit Guardsman

## When to use

When adding **privileged functionality** or access to **restricted** data—the "who did what when" audit trail must be adequate and tamper-resistant.

## Harness docs first

If the project defines logging or auditing standards, align with those first.

## What to audit

1. **Authentication & session events** — login success/failure, logout, MFA challenges, password/API-key resets, session revocation.
2. **Privileged operations** — admin adding/removing users, role or permission changes, configuration and security-setting modifications, feature-flag flips affecting access.
3. **Restricted data access** — viewing, downloading, querying, exporting, or modifying data classified as restricted/confidential/PII.
4. **Security-relevant failures** — authorization denials, signature validation failures, rate-limit hits on sensitive endpoints.

Not everything needs auditing—use judgment for routine, non-sensitive operations.

## Standard log format

Single-line JSON on stdout:

```json
{
  "timestamp": "2025-11-13T14:23:45.123Z",
  "event_id": "evt_unique123",
  "event_type": "resource.action",
  "severity": "INFO|WARNING|ERROR|CRITICAL",
  "correlation_id": "req-abc123",
  "actor": {
    "id": "user-123",
    "type": "user|service_account|api_key|system",
    "name": "email or service name",
    "ip_address": "203.0.113.42"
  },
  "action": {
    "type": "CREATE|READ|UPDATE|DELETE|EXECUTE",
    "outcome": "success|failure|denied",
    "reason": "optional explanation"
  },
  "resource": {
    "id": "unique resource id",
    "type": "resource type",
    "name": "human readable name"
  },
  "context": {
    "environment": "dev|staging|production",
    "service": "service name"
  },
  "metadata": {}
}
```

## Event type naming

Dot notation, from a **fixed allowlist defined in code**—never build `event_type` from user input:

- `auth.login.success` / `auth.login.failure` / `auth.mfa.failure`
- `user.create` / `user.delete` / `user.update`
- `permission.grant` / `permission.revoke`
- `resource.read` / `resource.update` / `resource.delete`
- `data.restricted.access` / `data.restricted.export`
- `infrastructure.change.applied`
- `compliance.access.denied`

## Security requirements

- **UTC ISO 8601 timestamps**; unique `event_id` per entry (prefer UUIDv7 for sortability); include `correlation_id` / request ID to link events in a flow.
- **Log injection prevention**: any user-controlled value placed in a log field must be serialized by the JSON encoder (never string-concatenated) and stripped of newlines/control characters. One log record = one line, always.
- **No secrets or raw PII in values**: log identifiers, not contents. Mask where identity is needed (`u***@example.com`); never log passwords, tokens, API keys, card data, or document bodies.
- **Log both successes AND failures/denials** — denied attempts are the most valuable security signal. Repeated `auth.*.failure` or `compliance.access.denied` should map to an alert.
- **Append-only trail**: audit logs go to stdout for the aggregation system; application code must never rewrite, filter, or delete emitted audit events.
- **Fail safe**: if audit emission fails for a privileged operation, surface the error—do not silently continue.
- Add relevant metadata (fields changed, ticket IDs, data classification), keeping the no-secrets rule.

## Review checklist

When touching privileged flows, verify:

- [ ] Every new privileged/restricted operation emits an audit event (success and failure paths)
- [ ] `event_type` comes from the code allowlist
- [ ] No user-controlled string is concatenated into the log line
- [ ] No secret/PII value appears in any field
- [ ] `actor`, `correlation_id`, and `outcome` are always populated
