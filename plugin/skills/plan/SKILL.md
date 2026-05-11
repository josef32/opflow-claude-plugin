---
name: plan
description: Structured workflow for creating and updating sprint-style plans via MCP. Plans contain attached requirements + issues; the lifecycle is draft → ready → scoped → active → completed (with revision_required as a feedback loop). Use after grill-me session, when user says "create a plan", "plan this feature", or invokes /plan. For AI-scoping a ready plan, use /scope-plan instead.
---

Part of the opflow-coder workflow.

A plan in this orchestrator is a **sprint with a lifecycle**:

```
draft ──mark_ready──▶ ready ──plan-set-scoped──▶ scoped ──plan-start──▶ active ──plan-complete──▶ completed
                                                  │
                                            client comment
                                                  ▼
                                         revision_required
                                            (→ rescope via /scope-plan,
                                             or reopen scope back to draft
                                             via the team UI)
```

- `draft` — user is iterating on scope in the orchestrator chat. Attach/detach is free.
- `ready` — user has signalled scope is complete. Scope is locked from this point (attach/detach requires `override: true`). Awaiting AI scoping via `/scope-plan`.
- `scoped` — Claude Code has produced summary + milestones + client brief. Public share URL is live.
- `revision_required` — client posted a comment on the public brief page. Resolve via `/scope-plan` (process feedback in place) or reopen scope from the team UI (drops back to `draft`).
- `active` — work in progress.
- `completed` — done.
- `cancelled` — abandoned (from any state).

## MCP Tools

- `plan-create` — Create a plan in `draft` (default) or `ready`. Accepts `issueIds` / `requirementIds` / `documentRefs` to attach in one shot. AI-generated fields (summary/milestones/clientBrief) cannot be set here — use `plan-set-scoped`.
- `plan-update` — Update plan metadata (dates, notes, packages, name, `documentRefs`). **No status field** — use the dedicated transition tools below. Note: changing `documentRefs` on a non-draft plan is a scope change; this tool does NOT enforce the override audit — use the UI for that.
- `plan-set-scoped` — Atomic write of summary/milestones/clientBrief/language. Flips status to `scoped`. Use via `/scope-plan` skill.
- `plan-start` — `scoped → active`. Blocked from `ready`/`revision_required` (must scope or resolve feedback first).
- `plan-complete` — `active → completed`.
- `plan-cancel` — any → `cancelled`. Frees uploaded image assets to S3 cleanup.
- `plan-active` — Returns plans in `ready`, `scoped`, `revision_required`, or `active`. Includes attached requirement/issue counts, plus summary + milestones + (for revision_required) the new client comments.
- `plan-list` — List by status, package, or name substring.
- `plan-get-for-scoping` — Full payload for scoping a `ready` / `revision_required` plan, including expanded `documents` (full content) and `images` (presigned URLs). See the `plan-scoping` skill.
- `plan-get-for-execution` — Full payload for starting / continuing work on a `scoped` / `active` plan. Returns plan + summary + milestones + reqs + issues + expanded `documents` + presigned `images`. Call this from the opflow-coder session before writing code so you read every attached document.

## Plan context attachments

A plan can carry user-curated reference context that the AI must consume:

- **Images** (`images[]`) — uploaded mockups / screenshots. Max 5. The MCP tools sign each with a 1-hour presigned URL so you can fetch them as images.
- **Document refs** (`documentRefs[]`) — ids into the project's `documentation` collection. The MCP tools expand them to full title + path + content (missing ids are silently dropped).

These are attached by the user via the orchestrator UI's "Context" tab on the plan page. Document refs may also be set by `plan-create` / `plan-update`; images stay UI-only (they require asset upload). Edits follow the existing scope-lock: free in `draft`, override + audit-logged in `scopeChanges[]` once the plan is `scoped` or `active`.

## Workflow: Create Plan

After grill-me, when the user is ready to formalise a sprint:

1. Ask user for plan details:
   - Plan name
   - Affected packages
   - Optional sprint window (`startDate`, `endDate` as epoch ms)
   - Optional `requirementIds` / `issueIds` to attach in one shot

2. Generate notes summary in markdown:
   ```markdown
   ## Summary
   <brief description>

   ## Goals
   <what the sprint is trying to achieve>

   ## Out of scope
   <explicit non-goals>
   ```

3. Call `plan-create({ name, affectedPackages, notes, ... })`. Status defaults to `draft` so the user can keep iterating in the orchestrator chat.

4. Confirm: "Created plan '<name>' (draft) with N requirements + M issues attached. Open the orchestrator chat to refine scope, or run /scope-plan once it's ready."

## Workflow: Transition a plan

Status flips happen via dedicated tools, not `plan-update`:

- `plan-start` when work begins (`scoped → active`).
- `plan-complete` when all attached items are landed (`active → completed`).
- `plan-cancel` to abandon a plan from any state.

Never set `status` via `plan-update` — that field is no longer accepted.

To scope a ready plan (or process feedback on a revision-required one), use `/scope-plan <id>` — that runs the `plan-scoping` skill.

## Workflow: Read active plans

When starting a session (triggered by AGENTS.md):

1. Call `plan-active({ package: "<current-package>" })` — returns ready / scoped / revision_required / active.
2. If a plan is in `ready`, offer to run `/scope-plan` on it.
3. If a plan is in `revision_required`, surface the new client comments and offer to process them.
4. If a plan is in `scoped` / `active` and the user wants to start (or continue) work on it, call `plan-get-for-execution(planid)` to load the full payload — including any attached `documents` (full content) and `images` (presigned URLs). Read each attached document fully before writing code; they often contain constraints not captured in the requirements/issues.

## Workflow: Plan from issues / requirements

When the user asks you to "scope these issues" / "plan these requirements":

1. Call `issue-list` / `requirement-list` to understand the cluster.
2. Group related items.
3. Call `plan-create` with `issueIds` and/or `requirementIds` — the plan starts in `draft` so the user can refine it in the orchestrator chat.
4. Don't try to mark ready / scope / start from this skill — those transitions are user-driven.

See the `issue` skill for full triage workflow.

## Rules

- Always ask user for plan details — don't auto-generate from grill-me output.
- `notes` should contain all provided context so future sessions can pick up the plan without re-asking.
- Never change plan status via `plan-update` — it doesn't accept `status` anymore. Use the dedicated transition tools.
- When attaching to a plan that's no longer `draft`, prompt the user to confirm the override before passing `override: true`. Each override is audit-logged to `plan.scopeChanges[]`.
