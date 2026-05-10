---
name: documentation
description: Structured workflows for creating and reading documentation via MCP tools. Use when user says "document this endpoint", "create docs for", "read the docs for", or invokes /docs or /documentation.
---

Part of the opflow-coder workflow.

Structured workflows for creating and reading documentation via MCP tools.

## MCP Tools

- `docs-discover` — Find docs (metadata only). Filters: file, query, package, tags, category, path, relatedEndpoint
- `docs-get` — Get full content. Params: path OR relatedEndpoint
- `docs-write` — Create/update doc. Params: title, content, package, tags, path (optional if relatedEndpoint), relatedEndpoint (optional)

## Workflow: Create API Reference Doc

When the user asks to document an endpoint:

1. Read the endpoint code using `search` and `context` MCP tools
2. Analyze the endpoint:
   - Schema (expects/returns)
   - Handler logic
   - Auth requirements
   - Related endpoints
3. Generate comprehensive API reference markdown with:
   - Endpoint path and method
   - Description
   - Parameters (schema)
   - Return type
   - Auth requirements
   - Example request/response
4. Call `docs-write`:
   ```json
   {
     "title": "<Endpoint Name>",
     "content": "<generated markdown>",
     "package": "<package name>",
     "relatedEndpoint": "/endpoints/<path>",
     "tags": ["api", "<relevant-tags>"]
   }
   ```
5. Confirm to user: "Created API reference doc for `<endpoint>`"

## Workflow: Create General Doc

When the user asks to write documentation about a topic:

1. Understand the topic from the user's request
2. Generate markdown content
3. Ask user for:
   - Title (if not clear)
   - Package (if not clear from context)
   - Path (if not clear from context)
   - Tags (optional)
4. Call `docs-write`:
   ```json
   {
     "title": "<title>",
     "content": "<generated markdown>",
     "package": "<package>",
     "path": "<doc storage path, e.g. packages/<pkg>/documentation/<filename>.md or docs/<filename>.md depending on the repo's convention>",
     "tags": ["<tags>"]
   }
   ```
   The `path` is a logical storage key in the orchestrator's docs collection — it doesn't have to map to a real file on disk. Use whatever convention the user's repo follows; ask if unclear.
5. Confirm to user: "Created documentation at `<path>`"

## Workflow: Import Existing Docs

When the user asks to import existing documentation:

1. Scan for documentation files using whatever glob matches the repo's layout. Common patterns:
   - Monorepo: `packages/*/documentation/**/*.md`, `apps/*/docs/**/*.md`
   - Single-package: `docs/**/*.md`, `documentation/**/*.md`
   Ask the user to confirm the glob if the layout isn't obvious.
2. For each file:
   a. Read the content
   b. Extract frontmatter (tags, title) if present using gray-matter or manual parsing
   c. Auto-detect package from path: `packages/<name>/...` → `<name>`. For non-monorepo layouts, use `package.json#name` or the repo name as a single bucket.
   d. Auto-detect category:
      - Path contains `agent-instructions` → `"agent-instructions"`
      - Path contains `api-reference` → `"api-reference"`
      - Otherwise → `"documentation"`
   e. Call `docs-write` with extracted data
3. Report summary: "Imported X docs, updated Y, skipped Z"

## Workflow: Read Documentation

When the user asks to read documentation about a topic:

1. Call `docs-discover({ query: "<topic>" })`
2. Show user the list of found docs (title, package, category, tags)
3. Ask user which docs to read
4. For selected docs, call `docs-get({ path: "<doc-path>" })`
5. Present the content

## Rules

- Always use `docs-discover` before `docs-get` — never read docs without user confirmation
- Exception: `agent-instructions` category docs can be auto-read (autoRead: true)
- Never create docs proactively — only when user asks
- For API reference, always read the endpoint code first
- Tags should be meaningful, not redundant with path/title
