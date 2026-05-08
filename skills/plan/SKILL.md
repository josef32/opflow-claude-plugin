---
name: plan
description: Structured workflow for creating and updating project plans via MCP. Use after grill-me session, when user says "create a plan", "plan this feature", or invokes /plan.
---

Structured workflow for creating and updating project plans via MCP.

## MCP Tools

- `plan-create` — Create/update plan. Params: name, status, affectedPackages, milestones, dependencies, notes, **issueIds** (optional — issues to attach in one shot; each gets `planid` set + status flipped to `scoped`)
- `plan-update` — Update plan fields. Params: name, status, milestones, notes, dependencies. **When status flips to `completed`, the server auto-cascades attached `scoped` issues to `solved`** and returns `cascadedIssues` in the result.
- `plan-active` — Get active plans. Params: package (optional)
- `plan-list` — List all plans. Params: status, package, nameContains

## Workflow: Create Plan

When starting a new feature or project (typically after grill-me):

1. Ask user for plan details:
   - Plan name (e.g., "Documentation MCP")
   - Affected packages (e.g., ["opflow-orchestrator"])
   - Milestones:
     - Name for each (e.g., "Phase 1: Infrastructure")
     - Description for each (what this milestone covers)
   - Dependencies (other plans this depends on, if any)
   - Initial status (draft or active)

2. Generate notes summary in markdown:
   ```markdown
   ## Summary
   <brief description of the plan>

   ## Problem
   <what problem this solves>

   ## Solution
   <high-level solution>

   ## Phases
   <description of each phase>
   ```

3. Call `plan-create`:
   ```json
   {
     "name": "<plan name>",
     "status": "<draft|active>",
     "affectedPackages": ["<packages>"],
     "milestones": [
       {
         "name": "<milestone name>",
         "status": "pending",
         "description": "<description>"
       }
     ],
     "dependencies": ["<other plan names>"],
     "notes": "<generated markdown>"
   }
   ```

4. Confirm to user: "Created plan '<name>' with <N> milestones"

## Workflow: Update Milestone

When the AI completes work that matches a plan milestone:

1. AI recognizes the work aligns with a milestone in an active plan
2. AI suggests: "This work completes milestone '<name>' in plan '<plan>'. Should I mark it as completed?"
3. User confirms
4. Call `plan-update`:
   ```json
   {
     "name": "<plan name>",
     "milestones": [
       {
         "name": "<milestone name>",
         "status": "completed"
       }
     ]
   }
   ```
5. Confirm to user: "Marked milestone '<name>' as completed"

## Workflow: Update Plan Status

When the user asks to change a plan's status:

1. Ask user for the new status (draft/active/completed/cancelled)
2. Call `plan-update`:
   ```json
   {
     "name": "<plan name>",
     "status": "<new status>"
   }
   ```
3. Confirm to user: "Updated plan '<name>' status to '<status>'"

## Workflow: Read Active Plans

When starting a session (triggered by AGENTS.md, not this skill):

1. Call `plan-active({ package: "<current-package>" })`
2. Review active plans to understand current priorities
3. Use this context to orient yourself before asking user what to work on

## Workflow: Plan from issues

When the user asks you to "scope these issues" or you're triaging in the `issue` skill:

1. Call `issue-list` (or `issue-get` for details) to understand the cluster.
2. Group related issues that share root cause / fix.
3. Call `plan-create` with `issueIds: [...]` — this creates the plan and attaches the issues atomically (each issue's status flips to `scoped`).
4. When the work lands and you mark the plan `completed` via `plan-update`, attached issues auto-cascade to `solved`. The result includes `cascadedIssues: [ids]` — relay this to the user.

See the `issue` skill for full triage workflow.

## Rules

- Always ask user for plan details — don't auto-generate from grill-me output
- Milestone names should be descriptive and numbered (e.g., "Phase 1: Infrastructure")
- Notes should be comprehensive and contain all provided / created context (exploration summaries, identified code changes etc...)
- Suggest milestone updates when work aligns — don't wait for user to ask
- Never change plan status without user confirmation
