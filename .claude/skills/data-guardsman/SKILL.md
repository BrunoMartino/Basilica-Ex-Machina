---
name: data-guardsman
description: >-
  Applies encryption at rest and in transit, key and secrets management, data
  classification tiers, secure credential/token handling, and injection-safe
  data access for classified data in code and infrastructure. Use when
  designing APIs, databases, storage, secrets, cryptography, TLS, PII/PCI/PHI,
  logging masking, privacy, or tagging DataClassification resources.
disable-model-invocation: true
---

# Data Guardsman

## When to use

When handling **stored or transmitted data**, **secrets**, or **classified information** (code, infra, configs, logs).

## Harness docs first

If the project defines security or coding conventions that conflict, follow project harness docs first.

## Encryption in transit

- **TLS 1.2+ (prefer 1.3)** for all web, API, and service-to-service traffic; HSTS headers; validate certificates (never disable verification, even in "temporary" code).
- **Database connections** over SSL/TLS with server certificate verification.
- Consider **mTLS** for internal service authentication.
- Never put sensitive data (tokens, PII) in **URLs or query strings** — they leak via logs, referrers, and history. Use headers or bodies.

## Encryption at rest

- Enable database encryption at rest (RDS encryption, TDE) **including backups** and volumes.
- Server-side encryption for object storage (S3, Blob) and local caches holding sensitive data.
- Encrypt sensitive fields (PII, financial, tokens, session data, anything restricted/confidential) at the application level when the threat model requires it.

## Secrets management

- Never store secrets in plaintext, code, or version control. Use a secret manager (AWS Secrets Manager, Vault, Key Vault); `.env` files stay local and gitignored.
- **Scan before commit**: run a secrets scanner (gitleaks/trufflehog) or review diffs for keys when touching config. A leaked secret is compromised — rotate it, don't just delete the line.
- Backend-only exposure: secrets never reach frontend bundles, client config, or logs.
- Define rotation (e.g. 90 days) for long-lived keys; prefer short-lived credentials where the platform allows.
- Store only **hashes** of API keys you issue; validate webhooks by signature.

## Keys & algorithms

- Symmetric: AES-256-GCM or ChaCha20-Poly1305. Asymmetric: RSA-2048+ (prefer 4096) or modern EC.
- Passwords: **argon2id** (preferred) or bcrypt (cost ≥ 12) / PBKDF2 — never reversible encryption, never plain hashes.
- Keys live in a KMS/HSM, separated from the data they protect; rotate and document procedures.
- Use proven libraries; never roll your own crypto; ban MD5, SHA-1, DES, 3DES, RC4.

## Injection-safe data access

When code moves classified data in or out of stores:

- **Parameterized queries / prepared statements only** — never string-concatenate user input into SQL/NoSQL/LDAP queries or shell commands.
- Validate and normalize input at trust boundaries; encode output for its destination (HTML, headers, logs).
- Session/auth cookies: `HttpOnly`, `Secure`, `SameSite` set.

## Data classification standard

Classify data the code touches and apply the matching controls:

| Tier | Examples | Controls |
|------|----------|----------|
| **PUBLIC** | product catalogs, marketing content | none required |
| **INTERNAL** | employee directories, internal metrics | authentication required |
| **CONFIDENTIAL** | contracts, financial reports | role-based access + audit logging |
| **PII** | emails, phones, addresses, IPs, device IDs | encrypt at rest+transit; mask in logs (`u***@example.com`); audit access; GDPR/LGPD compliance; deletion path implemented |
| **PCI** | card numbers, CVV, PAN | **never store raw card data**; processor tokens only; PCI-DSS |
| **PHI** | medical records, diagnoses, prescriptions | encrypt everything; audit every access; HIPAA |

### Code requirements for classified data

1. Mark data classification in comments where non-obvious.
2. Encrypt sensitive fields before storage; mask in logs (use IDs, not values).
3. Audit logging for PII/PCI/PHI access (see [`audit-guardsman`](../audit-guardsman/SKILL.md)).
4. Data minimization — collect and retain only what's needed; implement deletion/anonymization for privacy requests.
5. Tag infrastructure resources with `DataClassification`.
6. Anonymize/pseudonymize before sending anything to analytics or third parties.

## Red flags to catch in review

- Logging PII/PCI/PHI values directly, or secrets in error messages/stack traces sent to users
- Storing raw card data or plaintext passwords
- Sensitive data in URLs, query strings, or frontend state
- String-built queries with user input
- Disabled TLS/certificate verification
- Missing encryption for PII/PHI; missing audit logs for sensitive operations
- Secrets committed to version control or baked into images
