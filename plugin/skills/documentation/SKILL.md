---
name: documentation
description: Structured workflows for creating and reading documentation via the `opflow` CLI. Use when user says "document this endpoint", "create docs for", "read the docs for", or invokes /docs or /documentation.
---

Part of the opflow-coder workflow.

Structured workflows for creating and reading documentation via the `opflow` CLI.

## CLI commands

- `opflow docs discover [--file <p>] [--query <q>] [--package <p>] [--category <c>] [--path <p>] [--relatedendpoint <e>] [--tags <csv|json>]` — Find docs (metadata only).
- `opflow docs get (--path <p> | --relatedendpoint <e>)` — Get full content.
- `opflow docs write --title <t> --content <text> --package <p> --tags <csv|json> (--path <p> | --relatedendpoint <e>)` — Create/update a doc.

**Long-form values from files.** Any string flag accepts `@path`: `--content @doc.md`. Use `@@` for a literal `@`.

## Workflow: Create API Reference Doc

When the user asks to document an endpoint:

1. Read the endpoint code using `opflow search` / `opflow context`.
2. Analyse the endpoint:
   - Schema (expects/returns)
   - Handler logic
   - Auth requirements
   - Related endpoints
3. Draft comprehensive API-reference markdown to `doc.md` (path, description, parameters, return type, auth, example req/response).
4. Submit:
   ```bash
   opflow docs write \
       --title "<Endpoint Name>" \
       --content @doc.md \
       --package "<package>" \
       --relatedendpoint "/endpoints/<path>" \
       --tags "api,<relevant-tags>"
   ```
5. Confirm to user: "Created API reference doc for `<endpoint>`".

## Workflow: Create General Doc

When the user asks to write documentation about a topic:

1. Understand the topic.
2. Generate markdown content (write to `doc.md`).
3. Ask user for title / package / path / tags if not clear from context.
4. Submit:
   ```bash
   opflow docs write \
       --title "<title>" \
       --content @doc.md \
       --package "<package>" \
       --path "<doc storage path>" \
       --tags "<csv-tags>"
   ```
   The `path` is a logical storage key in the orchestrator's docs collection — it doesn't have to map to a real file on disk. Use whatever convention the repo follows; ask if unclear.
5. Confirm to user: "Created documentation at `<path>`".

## Workflow: Import Existing Docs

When the user asks to import existing documentation:

1. Scan for documentation files using whatever glob matches the repo's layout. Common patterns:
   - Monorepo: `packages/*/documentation/**/*.md`, `apps/*/docs/**/*.md`
   - Single-package: `docs/**/*.md`, `documentation/**/*.md`
   Ask the user to confirm the glob if unclear.
2. For each file:
   a. Read the content.
   b. Extract frontmatter (tags, title) if present.
   c. Auto-detect package from path: `packages/<name>/...` → `<name>`. For non-monorepo layouts, use `package.json#name` or the repo name as a single bucket.
   d. Auto-detect category from path; default `documentation`.
   e. Run `opflow docs write --content @<file>` with the extracted data.
3. Report summary: "Imported X docs, updated Y, skipped Z".

## Workflow: Read Documentation

When the user asks to read documentation about a topic:

1. Run `opflow docs discover --query "<topic>" --json`.
2. Show the user the list of found docs (title, package, category, tags).
3. Ask which docs to read.
4. For selected docs, run `opflow docs get --path "<doc-path>" --json` (or `--relatedendpoint`).
5. Present the content.

## Rules

- Always use `opflow docs discover` before `opflow docs get` — never read docs without user confirmation.
- Exception: `agent-instructions` category docs can be auto-read (autoRead: true).
- Never create docs proactively — only when the user asks.
- For API reference, always read the endpoint code first.
- Tags should be meaningful, not redundant with path/title.
