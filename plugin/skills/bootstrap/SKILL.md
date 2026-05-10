---
name: bootstrap
description: One-shot project bootstrap. Reads the project, scans the codebase, and fills the project's `technologies` field plus the `bootstrap.md` documentation entry. Use when starting in a fresh opflow-orchestrator project, when the bootstrap doc is empty, when the user says "bootstrap this project", or invokes /bootstrap.
---

Part of the opflow-coder workflow.

One-shot bootstrap for a project: figures out what the project is, writes a Technologies summary on the project, and fills in the `bootstrap.md` doc with conventions a future agent (or human) needs to land changes safely.

## When to run

- First session in a newly-created project (the bootstrap doc still has the placeholder template).
- After a major stack change where Technologies and Pitfalls drifted.
- When the user invokes `/bootstrap` or says "bootstrap this project" / "fill in the project info".

Re-running is safe — both `project-update` and `docs-write` are idempotent upserts. Don't re-run unprompted.

## MCP tools used

- `project-get` — read current project (name, purpose, technologies, monorepo, githubrepo, bootstrapDocId).
- `project-update` — set `technologies` (markdown). Owner-only mutation.
- `docs-write` — replace the body of `bootstrap.md` (path is fixed).
- `search` / `context` / `files` — explore the indexed codebase to ground the writeup.

## Workflow

1. **Read current state.** Call `project-get`. Note `name`, `purpose`, `monorepo`, and whether `technologies` is empty.
2. **Survey the code.** Use `files` to enumerate top-level packages / entry points. Use `search` for distinctive markers (framework imports, build configs, test runners, deployment specs). Don't read every file — sample enough to characterize the stack.
3. **Compose Technologies (markdown).** Cover: language + runtime, framework(s), package manager, key libraries (state mgmt, db, auth, UI), dev tooling (test runner, linter, build), deployment target. Keep under ~30 lines. Don't list versions unless the project pins them somewhere visible.
4. **Compose Bootstrap doc.** Five sections, replacing placeholders inline:
   - **Overview** — 1–3 sentences on what the project does.
   - **Stack** — short pointer to Technologies (don't duplicate).
   - **Conventions** — indent, naming, file layout, any project-specific patterns observed (e.g. "endpoints declared via attachEndpoint", "JSX runtime is custom — not React").
   - **Getting started** — local dev URLs, common bun/npm commands, env vars required.
   - **Pitfalls** — non-obvious gotchas observed during the survey (e.g. monorepo workspace quirks, Vite proxy rules, custom JSX runtime, anything that surprised you).
5. **Write.** Call `project-update` with `{ technologies: <markdown> }`, then `docs-write` with `{ path: 'bootstrap.md', title: 'Bootstrap', package: 'root', tags: ['bootstrap'], content: <markdown> }`.
6. **Confirm.** Echo the two lengths back to the user (e.g. "Wrote 480 chars to technologies, 1.2 KB to bootstrap.md") and stop.

## Constraints

- **Owner only:** `project-update` rejects non-owner callers. If it 403s, surface the error and stop — don't silently retry as a different field.
- **Don't invent project purpose.** If the existing `purpose` field is empty and you can't infer one confidently from the code, leave it untouched — propose an edit to the user instead of writing it via `project-update`.
- **Markdown, not prose.** Both fields render as markdown in the orchestrator UI. Use headings, lists, code fences.
- **Don't touch packages.** Bootstrap is metadata. Don't write code, don't touch the codebase. If the survey turns up bugs or missing setup, surface them as issues separately (`/issue`), not inline edits.
