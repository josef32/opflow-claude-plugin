---
name: issue
description: Workflow for triaging and scoping issues stored in the orchestrator. Use when the user says "triage issues", "scope this issue", "look at open issues", or invokes /issue.
---

Workflow for triaging issues in the orchestrator and attaching them to plans.

## MCP Tools

- `issue-list` — List issues. Filters: `status` (created/scoped/solved/rejected), `planid` (pass `null` for unattached), `severity`, `includeArchived`, `includeRejected`. By default excludes archived + rejected.
- `issue-get` — Full issue details including description, AI analysis, and **presigned URLs for screenshots** so you can fetch and analyze them.
- `issue-attach` — Attach one or more issues to an existing plan. Sets `planid` + flips `status` to `scoped`. Optionally records `aiAnalysis` (markdown) and adjusts `severity`.

`plan-create` (in the `plan` skill) also accepts an `issueIds` array — use it to create a plan and attach issues in one shot when starting fresh on an issue cluster.

## Lifecycle

```
created → scoped → solved
   │         │
   └─────────┴────────► rejected
```

- `created → scoped`: happens when you call `issue-attach` or `plan-create` with `issueIds`.
- `scoped → solved`: **automatic** when the linked plan transitions to `completed`. You don't flip this manually — finishing the plan does it.
- `rejected`: manual via UI; not your concern from the AI side.

## Workflow: Triage open issues

When the user says "let's triage issues" or "what issues are open":

1. Call `issue-list` with `status: 'created'` to get all unscoped issues, sorted by severity desc, then date desc.
2. For each (or the highest-priority cluster), call `issue-get` to read the full description and fetch screenshots from the presigned URLs.
3. Decide grouping: do these issues belong to one plan or multiple? Issues sharing root cause / affected area / fix → one plan.
4. Either:
   - **New plan**: call `plan-create` with `issueIds: [...]` to create the plan and attach in one call.
   - **Existing plan**: call `issue-attach` with `planName` to attach to a plan that already covers the work.
5. Pass `aiAnalysis` (markdown) summarizing what you understood about each issue and how the plan addresses it. The user reads this in the UI to verify your scoping.

## Workflow: Resolve scoped issues

When you complete a plan with `plan-update` setting `status: 'completed'`, the server **automatically** flips all attached `scoped` issues to `solved` and emits realtime updates. The tool result includes `cascadedIssues: [ids]` so you can confirm what was resolved.

Don't reopen issues manually — if a regression appears, the user files a new issue.

## Severity guidance

When attaching, you can adjust severity if your analysis reveals it differs from the reporter's assessment. Prefer leaving it alone unless clearly wrong (e.g. reporter marked `low` but it's a data-loss bug → bump to `critical`).

| Severity | When |
|---|---|
| critical | Data loss, auth bypass, prod down |
| high | Broken core feature, no workaround |
| medium | Default; broken non-core feature or workaround exists |
| low | Cosmetic, polish, nice-to-have |
