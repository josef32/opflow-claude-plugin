---
description: Create or update a sprint-style plan in the orchestrator (name, packages, optional timebox, attached requirements + issues). Status flips happen via dedicated tools; for AI scoping use /scope-plan.
---

Use the `plan` skill: ask the user for plan details (name, affected packages, optional startDate/endDate, optional requirementIds/issueIds), generate the notes block, and call `plan-create`. If updating metadata, use `plan-update` (no status field). For status transitions use `plan-start` / `plan-complete` / `plan-cancel`. For AI scoping of a ready plan use `/scope-plan <id>` instead.
