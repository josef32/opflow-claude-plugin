---
name: plan
description: Structured workflow for creating and updating sprint-style plans via MCP. Plans contain attached requirements + issues; activating a plan locks its scope. Use after grill-me session, when user says "create a plan", "plan this feature", or invokes /plan.
---

Part of the opflow-coder workflow.

Structured workflow for creating and updating sprint-style plans via MCP.

A plan in this orchestrator is essentially a **sprint**: it has an optional timebox (`startDate`, `endDate` epoch ms), a set of attached requirements + issues, and a status that flows `draft → active → completed | cancelled`. Activating a plan **locks its scope** — attach/detach mutations on contained items require an explicit `override: true` from then on, and each override appends to `plan.scopeChanges[]`.

## MCP Tools

- `plan-create` — Create/update plan. Params: `name`, `status`, `affectedPackages`, `startDate?`, `endDate?`, `notes`, `issueIds?` (attach in one shot, each gets `planid` + `status='scoped'`), `requirementIds?` (same, requirements must be in `created` or `scoped` state).
- `plan-update` — Update plan fields. Params: `name`, `status`, `startDate`, `endDate`, `notes`, `affectedPackages`. **No automatic cascade on plan completion** — mark each requirement/issue `solved` or `rejected` explicitly via `requirement-attach`/`issue-attach` or the `setStatus` endpoints.
- `plan-active` — Get active plans + per-status counts for attached requirements/issues. Params: `package?`.
- `plan-list` — List all plans. Params: `status?`, `package?`, `nameContains?`.

## Workflow: Create Plan

When starting a new feature or sprint (typically after grill-me):

1. Ask user for plan details:
   - Plan name (e.g., "Sprint 12: search overhaul")
   - Affected packages
   - Optional sprint window (`startDate`, `endDate` as epoch ms)
   - Initial status (`draft` or `active`)
   - Optional `requirementIds` / `issueIds` to attach in one shot

2. Generate notes summary in markdown:
   ```markdown
   ## Summary
   <brief description>

   ## Goals
   <what the sprint is trying to achieve>

   ## Out of scope
   <explicit non-goals so the locked scope is unambiguous>
   ```

3. Call `plan-create`. If you're activating immediately and attaching items, do it in one call.

4. Confirm to user: "Created plan '<name>' (status: <status>) with N requirements + M issues attached"

## Workflow: Activating a plan (locking scope)

1. User confirms the plan is ready to start
2. Call `plan-update({ name, status: 'active' })`
3. From this point, attach/detach against this plan needs `override: true`. Status changes on contained items remain free.

## Workflow: Update Plan Status

1. Ask user for the new status (`draft`/`active`/`completed`/`cancelled`)
2. Call `plan-update({ name, status })`
3. Confirm: "Updated plan '<name>' status to '<status>'"

## Workflow: Read Active Plans

When starting a session (triggered by AGENTS.md, not this skill):

1. Call `plan-active({ package: "<current-package>" })`
2. Review active plans + their requirement/issue status counts to understand current priorities
3. Use this context to orient yourself before asking user what to work on

## Workflow: Plan from issues / requirements

When the user asks you to "scope these issues" / "plan these requirements", or you're triaging in the `issue` skill:

1. Call `issue-list` / `requirement-list` (or `*-get` for details) to understand the cluster.
2. Group related items that share root cause / theme.
3. Call `plan-create` with `issueIds` and/or `requirementIds` — this creates the plan and attaches the items atomically.
4. When work lands, flip individual item status with `setStatus` or via the UI; **no auto-cascade on plan completion** (intentional — sprints can close with carry-over).

See the `issue` skill for full triage workflow.

## Rules

- Always ask user for plan details — don't auto-generate from grill-me output.
- `notes` should contain all provided context (exploration summaries, identified code changes, etc.) so future sessions can pick up the plan without re-asking.
- Suggest status updates when work aligns — don't silently flip status.
- Never change plan status without user confirmation.
- When attaching to a plan that's already `active`, prompt the user to confirm the override before passing `override: true`.
