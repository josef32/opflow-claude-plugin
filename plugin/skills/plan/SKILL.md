---
name: plan
description: Structured workflow for creating and updating sprint-style plans via the `opflow` CLI. Plans contain attached requirements + issues; the lifecycle is draft → ready → scoped → active → completed (with revision_required as a feedback loop). Use after grill-me session, when user says "create a plan", "plan this feature", or invokes /plan. For AI-scoping a ready plan, use /scope-plan instead.
---

Part of the opflow-coder workflow.

A plan in this orchestrator is a **sprint with a lifecycle**:

```
draft ──mark_ready──▶ ready ──plan set-scoped──▶ scoped ──plan start──▶ active ──plan complete──▶ completed
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

## CLI commands

All commands are invoked via the `opflow` binary (auto-resolves the project via the `.opflow` file in the cwd and uses the saved credentials from `opflow auth login`).

- `opflow plan create --name <n> --notes <text> [--packages <json>] [--requirementids <json>] [--issueids <json>] [--startdate <iso>] [--enddate <iso>]` — Create a plan in `draft`.
- `opflow plan update <id> [--name <n>] [--notes <text>] [--packages <json>] [--startdate <iso>] [--enddate <iso>]` — Update metadata. **No status flag.** Status transitions go through the dedicated commands below.
- `opflow plan set-scoped <id> --summary <text> --milestones <json> --clientbrief <text> --language <code>` — Atomic write of summary/milestones/clientBrief/language. Flips status to `scoped`. Use via `/scope-plan` skill.
- `opflow plan start <id>` — `scoped → active`. Blocked from `ready`/`revision_required`.
- `opflow plan complete <id>` — `active → completed`.
- `opflow plan cancel <id>` — any → `cancelled`. Frees S3 image assets for cleanup.
- `opflow plan active` — Plans in `ready`, `scoped`, `revision_required`, or `active`. Includes summary + milestones + (for revision_required) the new client comments.
- `opflow plan list [--status <s>] [--package <p>]` — List by status, package, or name substring.
- `opflow plan get-for-scoping <id>` — Full payload for scoping a `ready` / `revision_required` plan, including expanded `documents` (full content) and `images` (presigned URLs). See the `plan-scoping` skill.
- `opflow plan get-for-execution <id>` — Full payload for starting / continuing work on a `scoped` / `active` plan. Returns plan + summary + milestones + reqs + issues + expanded `documents` + presigned `images`. Call this from the opflow-coder session before writing code so you read every attached document.

**Long-form values from files.** Any string flag accepts `@path` to load its value from a file: `--notes @notes.md`, `--clientbrief @brief.md`, `--milestones @milestones.json`. Use `@@` to pass a literal value starting with `@`.

**Output.** Add `--json` for machine-readable output (default JSON when stdout is piped). On TTY you get a pretty table / key-value rendering. `OPFLOW_FORMAT=pretty` forces pretty mode.

## Plan context attachments

A plan can carry user-curated reference context that the AI must consume:

- **Images** (`images[]`) — uploaded mockups / screenshots. Max 5. Each is signed with a 1-hour presigned URL.
- **Document refs** (`documentRefs[]`) — ids into the project's `documentation` collection. Expanded to full title + path + content (missing ids are silently dropped).

These are attached by the user via the orchestrator UI's "Context" tab. Document refs may also be set via `opflow plan create` / `opflow plan update`; images stay UI-only (they require asset upload). Edits follow the existing scope-lock: free in `draft`, override + audit-logged in `scopeChanges[]` once the plan is `scoped` or `active`.

## Workflow: Create Plan

After grill-me, when the user is ready to formalise a sprint:

1. Ask user for plan details:
   - Plan name
   - Affected packages
   - Optional sprint window (`startDate`, `endDate` as epoch ms)
   - Optional `requirementIds` / `issueIds` to attach in one shot

2. Draft notes in markdown:
   ```markdown
   ## Summary
   <brief description>

   ## Goals
   <what the sprint is trying to achieve>

   ## Out of scope
   <explicit non-goals>
   ```
   Write to a temp file and pass `--notes @file.md` so quoting doesn't get in the way.

3. Run `opflow plan create --name "<name>" --notes @notes.md --packages '["pkg-a","pkg-b"]'` (and `--requirementids` / `--issueids` if any). Status defaults to `draft`.

4. Confirm: "Created plan '<name>' (draft) with N requirements + M issues attached. Open the orchestrator chat to refine scope, or run /scope-plan once it's ready."

## Workflow: Transition a plan

Status flips happen via dedicated commands, not `opflow plan update`:

- `opflow plan start <id>` when work begins (`scoped → active`).
- `opflow plan complete <id>` when all attached items are landed (`active → completed`).
- `opflow plan cancel <id>` to abandon a plan from any state.

Never pass a `status` flag — it isn't accepted.

To scope a ready plan (or process feedback on a revision-required one), use `/scope-plan <id>` — that runs the `plan-scoping` skill.

## Workflow: Read active plans

When starting a session (triggered by AGENTS.md):

1. Run `opflow plan active --json` (optionally `--package <current-package>`).
2. If a plan is in `ready`, offer to run `/scope-plan` on it.
3. If a plan is in `revision_required`, surface the new client comments and offer to process them.
4. If a plan is in `scoped` / `active` and the user wants to start (or continue) work on it, run `opflow plan get-for-execution <id> --json` to load the full payload — including any attached `documents` (full content) and `images` (presigned URLs). Read each attached document fully before writing code; they often contain constraints not captured in the requirements/issues.

## Workflow: Plan from issues / requirements

When the user asks you to "scope these issues" / "plan these requirements":

1. Run `opflow issue list --json` / `opflow requirement list --json`.
2. Group related items.
3. Run `opflow plan create --issueids '[1,2,3]'` and/or `--requirementids '[...]'` — plan starts in `draft` so the user can refine it in the orchestrator chat.
4. Don't try to mark ready / scope / start from this skill — those transitions are user-driven.

See the `issue` skill for full triage workflow.

## Rules

- Always ask user for plan details — don't auto-generate from grill-me output.
- `notes` should contain all provided context so future sessions can pick up the plan without re-asking.
- Never change plan status via `opflow plan update`.
- When attaching to a plan that's no longer `draft`, prompt the user to confirm the override before proceeding.
