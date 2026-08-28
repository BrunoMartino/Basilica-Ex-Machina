---
name: recon
description: "Perform structured reconnaissance and attack surface enumeration for authorized penetration tests, CTF challenges, and bug bounty programs. Use when the user mentions 'recon,' 'reconnaissance,' 'enumerate,' 'attack surface,' 'subdomain enumeration,' 'port scan,' 'fingerprint,' 'asset discovery,' or needs to map a target's external footprint."
allowed-tools: Bash, Read, Write, WebSearch, WebFetch
---

# Recon — Penetration Testing Reconnaissance

Perform structured reconnaissance against an authorized target, organizing findings into an actionable attack surface map.

Cross-references: `osint-recon` for the deeper open-source-intelligence pass (people, organizations, historical data) — this skill is the active/passive target-mapping side, osint-recon is the broader investigative side; they pair naturally. `web-pentest` for the next stage once recon has produced an attack surface map and an authorized target list. `owasp-audit` for source-code review when you have access to the target's code.

## Authorization Check

Before running any commands, confirm:
1. The user has written authorization for the target (pentest engagement, bug bounty program, CTF/lab environment)
2. The target is within the defined scope

If authorization is unclear, ask before proceeding. Never assume authorization.

## Project grounding — Graphify first, then harness docs

Before working through this skill, orient yourself in the project in scope so findings map to real nodes and documented constraints rather than generic patterns (when you have access to its codebase in this workspace):

- **Graphify first.** If `graphify-out/` exists, read `graphify-out/GRAPH_REPORT.md` and run `graphify query "<question>" --graph graphify-out/graph.json` to learn the project's nodes, entry points, and dependencies, then open only the files the graph points at. If `graphify-out/` or the `graphify` CLI is missing, fall back to reading the workspace directly. (Mirrors the `graphify-first` project rule.)
- **Harness docs next.** If `docs/harness/` exists (created by `harness-create` or `legacy-explainer`), read the relevant docs — `architecture_rules.md`, `domain_invariantes.md`, `forbidden_patterns.md`, `operational_constraints.md`, `testing_expectation.md`, and any `features/feature-*.md` — and treat them as binding context: calibrate severity and remediation against them, rank a finding that breaks a documented invariant or forbidden pattern above a generic one, and never propose a fix that violates the harness. If a doc is absent, use what exists and say so; do not invent project rules. (Mirrors the `all-for-harness` project rule.)

## Methodology

### Phase 1: Passive Recon

Gather information without touching the target directly.

**DNS enumeration:**
- Run `dig any $ARGUMENTS` for A, AAAA, MX, TXT, NS, CNAME records
- Attempt zone transfer: `dig axfr @ns-server $ARGUMENTS`
- Enumerate subdomains via certificate transparency:
  ```
  curl -s "https://crt.sh/?q=%25.$ARGUMENTS&output=json" | jq -r '.[].name_value' | sort -u
  ```

**WHOIS and registration:** Run `whois $ARGUMENTS` for registrant, nameserver, and creation date info.

**Search engine dorking:** Use targeted queries — `site:`, `inurl:`, `filetype:`, `intitle:` — to find exposed pages, documents, and admin panels.

**Technology fingerprinting:** Identify frameworks, CMS, server software, and JavaScript libraries from public-facing pages.

**Public code repositories:** Search GitHub/GitLab for the target's org name, domain, API keys, or internal paths.

**Historical data:** Check the Wayback Machine for old endpoints, removed pages, and configuration files.

### Phase 2: Active Recon (explicit authorization only)

**Port scanning:**
```bash
nmap -sC -sV -oN scan-results.txt $ARGUMENTS
```
Start with top 1000 ports. Expand to full range (`-p-`) if needed. Use `-Pn` if the host appears down but is in scope.

**Service enumeration:** Based on open ports, probe for version info and default configurations.

**Web content discovery:**
- Directory bruting with gobuster, feroxbuster, or dirsearch
- Virtual host enumeration
- API endpoint discovery (check `/api/`, `/v1/`, `/graphql`, `/swagger.json`)

**SSL/TLS analysis:** Run `testssl.sh` or `sslyze` to check for weak ciphers, expired certificates, and misconfigurations.

### Phase 3: Analysis

Correlate all findings. Identify the most promising attack vectors and prioritize by:
1. Severity of potential impact
2. Likelihood of exploitation
3. Exposure level (internet-facing vs. internal)

## Output Format

Produce a structured recon report:

```markdown
# Recon Report
## Target: [target]
## Scope: [confirmed scope]
## Date: [date]

### Passive Findings
| Finding | Details | Relevance |
|---------|---------|-----------|

### Subdomains Discovered
- [list]

### Technologies Detected
- [list with versions where identified]

### Active Findings
| Port | Service | Version | Notes |
|------|---------|---------|-------|

### Attack Surface Summary
[Prioritized list of interesting findings with risk assessment]

### Recommended Next Steps
[Ordered list of what to investigate further]
```

## Boundaries

- Stay within the defined scope — never scan adjacent or out-of-scope systems
- Rate-limit aggressive scans to avoid disruption
- Log all commands run for the engagement record
- If you discover evidence of active compromise by a third party, alert the user immediately
- Refuse requests targeting systems without explicit authorization
- Refuse requests for mass scanning of unrelated targets

## References

- PTES (Penetration Testing Execution Standard)
- OWASP Testing Guide
- Bug Bounty Methodology (jhaddix/tbhm)
