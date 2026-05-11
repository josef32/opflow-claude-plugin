---
name: plan-scoping
description: AI-scope a 'ready' plan into a summary + ordered milestones + client-facing markdown brief, or process client feedback on a 'revision_required' plan. Use when invoked via /scope-plan, or when the user says "scope plan N", "process feedback on plan N", or asks Claude to pick up a plan that the chat just marked ready.
---

Part of the opflow-coder workflow.

This skill is the bridge between the orchestrator's chat-driven scoping (which produces a `ready` plan with attached requirements + issues) and the team starting work. It produces three artefacts atomically:

- `summary` — internal, dev-facing
- `milestones[]` — ordered `{ title, description }` chunks
- `clientBrief` — markdown for the client, written in their language

…and flips the plan to `scoped`. On first scope, a `shareToken` is minted so the brief is reachable at `/p/<orgSlug>/<token>` for the client to read and comment on.

## MCP tools

- `plan-get-for-scoping(planid)` — full payload for scoping: plan + attached requirements (title + description) + attached issues + existing summary/milestones/clientBrief + clientComments + expanded `documents` (full content of any attached documentRefs) + `images` (presigned URLs, 1h TTL). Requires status `ready` or `revision_required`.
- `plan-set-scoped(planid, summary, milestones[], clientBrief, language)` — atomic write of all four. Server flips status to `scoped`. Idempotent on re-run.
- `plan-list({ status: "ready" })` / `plan-list({ status: "revision_required" })` — when the user didn't pass an id.

## Workflow

### 1. Resolve the plan id

If invoked as `/scope-plan <id>`, use that. Otherwise:
- If the user mentioned a plan by name, call `plan-list({ nameContains: "<term>" })`.
- Otherwise list `ready` + `revision_required` plans and ask which.

### 2. Load context

Call `plan-get-for-scoping(planid)`. Three relevant cases:

- **status='ready', no existingSummary** — fresh scoping. Ask the user which language the client brief should be in (default to project default if known; otherwise ask). Examples: `en`, `nl`, `de`.
- **status='ready' with existingSummary** — only happens if reopen_scope was called and the user wants you to re-scope. Treat as fresh scoping; the existing fields are stale and will be overwritten.
- **status='revision_required'** — process feedback mode. Read `clientComments` carefully. Existing summary/milestones/clientBrief are the baseline; rewrite them addressing each comment. Reuse the existing `language`.

**Required reading.** If the payload contains `documents[]`, read every entry in full before drafting — they're the user's curated context and often carry constraints not in the requirements/issues. Same goes for `images[]`: fetch each presigned URL and look at the image. The presigned URLs expire in 1 hour, so if scoping takes longer, just re-call `plan-get-for-scoping` to refresh.

### 3. Draft

#### Summary (internal)
1-3 short paragraphs. Goal: a dev opening the plan months later understands what it's about. Reference attached requirement / issue ids where helpful. Skip motherhood (do not say "this plan covers X"); just describe X.

#### Milestones
Order matters — execution order. Each is a meaningful chunk a dev could pick up. Aim for 3-6 milestones. Skip "set up project" / "deploy" boilerplate unless they are genuinely part of the work. For each: `title` (short imperative, e.g. "Wire client brief to public endpoint") and `description` (1-3 sentences of what's done and how it's verified).

#### Client brief
Markdown, in the chosen `language`. Audience: a non-technical stakeholder. The brief should:
- State the goal in their terms (no internal jargon).
- Walk through what will change in the product, grouped sensibly (not necessarily milestone-by-milestone).
- Be honest about scope boundaries (what's *not* included).
- Render cleanly — use `##` / `###` headings, short paragraphs, occasional bullet lists. No code blocks, no GitHub-flavoured markdown ticks for inline emphasis. Avoid placeholders / TODOs.

If processing revision feedback: lead with the changes you made in response to the feedback (one paragraph), then the rest of the brief.

### 4. Submit

Call `plan-set-scoped(planid, summary, milestones, clientBrief, language)`. The server enforces that status is `ready` or `revision_required`; if not, surface the error.

### 5. Confirm

Print the public share URL returned in the response. Example:
```
Scoped plan #42. Status: scoped.
Share link: https://orchestrator.dev.opflow.co.uk/p/oporchestrator/AbCd123…
```

If the user already had a share link out in the wild and you re-ran scoping, mention that the URL is unchanged.

## Rules

- **One atomic write.** Always call `plan-set-scoped` once, with all four fields complete. Don't try to stream/iterate.
- **No scope mutations here.** Attaching/detaching requirements or issues is the chat's job (or done via override on a non-draft plan). Don't call `requirement-attach` from this skill.
- **Honour the language.** When in revision-required mode, re-use the existing language unless the user explicitly asks to switch.
- **Don't invent requirements.** Work from what `plan-get-for-scoping` returns. If a requirement seems missing, ask the user — don't silently add it.
