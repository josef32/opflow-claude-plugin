---
name: opflow-coder
description: The opflow workflow for AI-driven software engineering. Use at the start of any coding session in an opflow-orchestrator project — load context (handover, plan, project, bootstrap) and follow the intent→skill routing table for the rest of the session. Also invoke manually via /opflow-coder to re-orient mid-session.
---

You are coding inside a project wired to opflow-orchestrator. The orchestrator stores plans, handovers, requirements, issues, documentation, and a code index. This skill is the connective tissue — it tells you what to load, when to invoke each spoke skill, and what *not* to do.

This is a meta-skill. It delegates. The actual procedures for handovers, plans, issues, docs, etc. live in their own skills.

## Session-start ritual

The moment you enter a session in this project, before doing anything else, fire these four MCP calls in parallel and read the results:

1. **`handover-latest`** — what was the last session about? What's the current commit? Are there open follow-ups?
2. **`plan-active`** — is there an active sprint? If yes, treat its scope as locked: new work goes through the plan, not around it.
3. **`project-get`** — read project metadata. Crucially: `monorepo` (true → use package selectors; false → never pass a `package` field, the server will overwrite it to `'root'` anyway) and `technologies` (the stack you're working in).
4. **`docs-get` with `path: 'bootstrap.md'`** — project conventions. Indent, naming, footguns. Read this *before* writing code, not after.

If any of these return empty / placeholder content, that's a signal:
- Empty `bootstrap.md` (still has the 5-section template) → suggest `/bootstrap` to the user.
- No active plan → suggest `/grill-me` then `/plan` once they describe the next chunk of work.
- No prior handover → fine, just skip step 1.

Don't dump the raw results to the user unprompted — use them as context for the rest of the conversation.

## Intent → skill routing

Listen to the user's phrasing and route to the right skill. Don't re-implement these flows here.

| User intent / phrasing | Skill / command |
|------------------------|-----------------|
| "I want to do X" / "can we add Y" / "we should…" (idle capture) | Capture into the requirement backlog. Mention `/issue` for triage later. |
| "let's plan X" / "design Y" / "what's the approach for Z" | `/grill-me` first to stress-test the design, then `/plan` to lock scope. |
| "triage open issues" / "what's outstanding" | `/issue` |
| "commit this" / after work lands and gets committed | `/handover` |
| "document X" / "how does Y work" / "write up the Z endpoint" | `/documentation` |
| "set up this project" / first session in an empty project / `bootstrap.md` is placeholder | `/bootstrap` |
| "re-index" / "sync the code" / `search` returns stale results | `/op-indexer` |

A few rules of thumb the routing relies on:

- **Plan first, code second.** When the user proposes new work, push toward `/plan` rather than starting to type. Scope-lock keeps everyone aligned.
- **Capture, don't queue.** Casual asks ("we could also…") go into requirements as backlog. Don't grow the active plan mid-flight.
- **Handover after every commit.** When you (or the user) lands a commit, run `/handover` before context evaporates. Future sessions start with `handover-latest`.

## Working inside an active plan

When `plan-active` returns a plan:

- **Don't introduce work outside its scope.** If the user asks for something off-plan, surface it: "this is outside the active plan's scope — capture as a requirement, or update the plan?". Let them choose.
- **Attach issues you uncover via `issue-attach`** so they're traceable to the plan.
- **Update the plan when you decide to expand or trim scope** — the audit trail matters more than the final state.

## Coding hygiene

- Use `search` / `context` / `files` (the code-index MCP tools) before grep — they return signatures + JSDoc and respect monorepo packaging.
- Re-run `/op-indexer` after non-trivial changes so the next agent sees them.
- Read the project's `bootstrap.md` for indent / naming / framework quirks before writing code in an unfamiliar package.

## Anti-patterns

- **Skipping the session-start ritual** because "the user just asked a quick question". Quick questions become hour-long sessions; the ritual costs four parallel MCP calls.
- **Dumping handover/plan/bootstrap content at the user.** Read it; use it. Surface only what's relevant to the current ask.
- **Re-implementing handover/plan/issue/docs/bootstrap procedures inline.** Each lives in its own skill — invoke it.
- **Writing to `bootstrap.md` ad-hoc.** Use `/bootstrap` (it surveys the codebase first) or `/documentation` for general docs.
- **Sending `package` fields when the project is non-monorepo.** Harmless (server overwrites to `'root'`) but noisy. Read `project-get`'s `monorepo` once and skip it.
