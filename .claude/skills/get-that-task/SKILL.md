---
name: get-that-task
description: >-
  Queries Jira Cloud for the current developer’s open issues and for unassigned
  open issues; returns a minimal two-section markdown view (links, status,
  estimate, age/staleness, labels). Use when the user asks for their Jira cards
  or tasks, backlog/in-progress work assigned to them, or unowned issues to pick
  up; or mentions Jira plus “my tasks”, “unassigned”, or “get that task”.
disable-model-invocation: true
---

# Get that task (Jira)

## When to use

Run when the user wants **their** non-finished Jira work and/or **unassigned** non-finished issues, in a **short** answer (no extra commentary, no third table, no wall of text).

Treat “not done / not concluded / not finished” as Jira issues that are **not** in a terminal state: prefer `statusCategory != Done` and **`resolution is EMPTY`** in JQL.

Interpret “backlog / blocked / working” as **non-done** workflow states: use `statusCategory in ("To Do", "In Progress")` when statuses are standard. If the site uses a **Blocked** status outside those categories, widen with `OR status = Blocked` **only** after a quick check against visible statuses (or ask the user once for the exact blocked status name).

## Atlassian MCP workflow

1. **Resolve `cloudId`**: if the user gave a Jira URL (e.g. `https://acme.atlassian.net/browse/KEY-1`), pass **`acme.atlassian.net`** as `cloudId` first. If calls fail, call `getAccessibleAtlassianResources` and pick the matching site.
2. **Current user** (for “my” issues): call `atlassianUserInfo` only if you need `accountId` / display name for confirmation; for assignment filters prefer JQL `assignee = currentUser()`.
3. **Search** (two passes, same `cloudId`):
   - **Mine**: `searchJiraIssuesUsingJql` with JQL like:
     - `assignee = currentUser() AND statusCategory != Done AND resolution is EMPTY ORDER BY updated DESC`
   - **Unassigned**:  
     - `assignee is EMPTY AND statusCategory != Done AND resolution is EMPTY ORDER BY updated DESC`

4. **`searchJiraIssuesUsingJql` options**:
   - Set `maxResults` as high as allowed (up to **100**); if `nextPageToken` is returned and the user asked for “all”, page until done or cap at what the user agrees.
   - Prefer `responseContentFormat`: `markdown` unless you need ADF.
   - **`fields`**: include at least `summary`, `status`, `issuetype`, `assignee`, `created`, `updated`, `labels`, and time fields you can read: `timeestimate`, `aggregatetimeestimate`, `aggregatetimeoriginalestimate`, `timetracking` (omit if the API rejects; fall back to numeric estimate fields only).

5. **URLs**: each row’s link should be `{base}/browse/{issueKey}` using the same site host as `cloudId`.

## Output (exactly two sections)

Use **two markdown tables** only, plus a **one-line** note if results were truncated (e.g. pagination cap). No other sections.

### Section 1 — `Your Cards/Task`

Columns (in order):

| Link | Step | Estimate | Since began | Tags |
|------|------|----------|-------------|------|

- **Link**: issue key + summary, as a single markdown link to Jira.
- **Step**: current **status** name (Kanban column).
- **Estimate**: human-readable original/remaining estimate when present; if **no** usable estimate (and no story-point field in the payload), show **`MISSING`** in bold.
- **Since began**: primary = time since **`created`** (or since first **In Progress** date if present in payload); human-readable duration.
- **Tags**: `labels` joined comma-separated; `—` if empty.

Highlighting:

- **`MISSING`** for missing estimate (table cell text, not prose).
- **`STALE`** in the **Since began** cell if **either**:
  - `updated` is older than **14** days, or
  - the issue is **In Progress** (`statusCategory`) and **`created`** is older than **10** days.  
  Adjust thresholds only if the user specifies.

### Section 2 — `Cards/Tasks without owner`

Columns (in order):

| Link | Step | Since began | Tags |
|------|------|-------------|------|

Apply the same **`STALE`** rule on **Since began** / **`updated`**.

If a section has zero rows, put a single table row or one line under the heading: **`None found`**—no apology text.

## Guardrails

- Do **not** dump raw JSON, full descriptions, or comment threads.
- Do **not** add recommendations, prioritization narratives, or “next steps” unless the user asks.
- If MCP is unavailable or credentials fail, say so in **one sentence** and stop.
