---
description: AI-scope a ready plan — produces an internal summary, ordered milestones, and a client-facing markdown brief, then flips the plan to 'scoped'. Also used to process client feedback on a plan in 'revision_required'.
---

Use the `plan-scoping` skill. Argument: the numeric plan id.

The skill:
1. Loads the plan via the `plan-get-for-scoping` MCP tool (must be in `ready` or `revision_required` state).
2. Determines the mode:
   - `ready` → fresh scoping. Asks the user for the client-facing language (e.g. `en`, `nl`) if the plan doesn't already have one.
   - `revision_required` → process feedback. Reads existing summary/milestones/clientBrief and the new client comments; refines in place.
3. Drafts:
   - `summary` — internal, dev-facing (1-3 short paragraphs).
   - `milestones[]` — ordered `{ title, description }`. Each milestone is a chunk of meaningful work.
   - `clientBrief` — markdown, in the chosen language. Render-ready (clean headings, no boilerplate).
4. Calls `plan-set-scoped(planid, summary, milestones, clientBrief, language)` atomically. The server flips status to `scoped` and mints a shareToken if one doesn't exist.
5. Prints the public share URL: `<orchestrator>/p/<orgSlug>/<token>`.
