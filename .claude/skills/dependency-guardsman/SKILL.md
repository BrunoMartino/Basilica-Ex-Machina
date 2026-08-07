---
name: dependency-guardsman
description: >-
  Enforces npm dependency security: vulnerability scans (Trivy/npm audit),
  supply-chain checks (typosquatting, install scripts, maintenance signals),
  lockfile integrity, and license verification with open-source-licenses.txt
  updates. Use when adding or changing npm dependencies, updating package.json,
  handling package-lock.json, vulnerability scans, or license compliance.
disable-model-invocation: true
---

# Dependency Guardsman

## When to use

Whenever **adding or changing npm packages** (`package.json` / lockfile flows), run this workflow before merging.

## Harness docs first

If the project overrides dependency or security tooling (harness deployment or operational constraints docs), prefer project docs first.

## 1. Supply-chain vetting (before installing)

For every **new** package, check before it ever touches `node_modules`:

1. **Exact name** — confirm spelling against the intended package (typosquatting: `lodash` vs `1odash`, `cross-env` vs `crossenv`). Verify the npm page links to the expected repository.
2. **Health signals** — `npm view <pkg>`: recent publish activity, weekly downloads, maintainer count, not deprecated. Treat as red flags: brand-new packages with few downloads, a sudden maintainer change, or obfuscated/minified-only source.
3. **Install scripts** — `npm view <pkg> scripts` — packages with `preinstall`/`postinstall` scripts deserve scrutiny; prefer alternatives without them, or review the script source.
4. If the Snyk MCP is available, also run its package/dependency check for a second opinion.

## 2. Vulnerability scanning

After changing dependencies:

1. `npm install --package-lock-only` to update `package-lock.json` without executing installs.
2. Scan (first available tool):
   - `trivy fs --scanners vuln --severity HIGH,CRITICAL --exit-code 1 package-lock.json`
   - fallback: `npm audit --audit-level=high`; or `osv-scanner --lockfile package-lock.json`
3. If HIGH/CRITICAL findings:
   - Upgrade to a fixed version; if none exists, replace with an alternative package.
   - Re-run the scan until clean. Do not merge with known HIGH/CRITICAL vulnerabilities without explicit user acceptance recorded in the PR/commit message.

## 3. Lockfile integrity & pinning

- The lockfile is the security boundary: **always commit `package-lock.json`** and use `npm ci` in CI/builds (fails on lockfile drift).
- Pin exact versions for direct dependencies when the project's convention allows; never use `*` or git URLs to mutable branches.
- Verify registry signatures/provenance when supported: `npm audit signatures`.
- Never edit the lockfile by hand.

## 4. License verification

For every new package:

1. `npm view <package-name> license` (confirm on npmjs.com if ambiguous).
2. **Block**: GPL-2.0/3.0, AGPL-3.0, any "Non-Commercial", proprietary, or missing license.
3. **Allow**: MIT, Apache-2.0, BSD-2-Clause/BSD-3-Clause, ISC.
4. Update `open-source-licenses.txt`: package name, version, license type, license URL/location.

If the license is risky, find a permissive-licensed alternative.

## Report

End with a short summary: packages added/changed, scan tool + result, supply-chain flags found (or none), license entries updated.
