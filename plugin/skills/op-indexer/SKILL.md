---
name: op-indexer
description: Re-sync this project's code to the orchestrator so MCP search/context/files reflect the latest source. Use after non-trivial code changes, when the user says "re-index", "sync the code", "refresh the index", or invokes /op-indexer.
---

Part of the opflow-coder workflow.

`op-indexer` is the prebuilt CLI that scans a project's TS/JS source, extracts top-level declarations, and uploads everything to opflow-orchestrator. Once synced, the data is queryable via the MCP tools `search`, `context`, and `files`.

## When to run

- After landing changes that touch declarations another agent might want to find (new endpoints, new components, renamed types).
- When `search` returns stale results referencing files that no longer exist.
- When the user says "re-index" / "sync the code" / "refresh the index" or invokes `/op-indexer`.

Don't re-run after every edit — incremental scans are cheap on the server side, but each run still walks the filesystem. After a focused single-file edit, skip it; after a feature lands, run it.

## How to run

The binary is installed per the project Guide (`Settings → Your Claude Code setup → op-indexer`). It's on PATH after install.

### Standard re-sync

```bash
op-indexer -y
```

`-y` skips prompts and uses values from `orchestration.json` (root, server, token) plus the server-resolved `monorepo` flag.

### First-time setup in a new working directory

```bash
op-indexer
```

Interactive mode. The orchestrator's `project-get` resolves most defaults via the JWT in `orchestration.json`; remaining prompts (root, exclude patterns) accept Enter for defaults.

### Common flags

| Flag | Description |
|------|-------------|
| `-y`, `--yes` | Skip prompts, use defaults |
| `-r <dir>`, `--root <dir>` | Project root (defaults to cwd) |
| `-x <glob>`, `--exclude <glob>` | Add an exclude pattern (repeatable, in addition to .gitignore) |
| `-e <path>`, `--entry <path>` | Restrict scan to entry points (repeatable) |
| `--monorepo` / `--no-monorepo` | Override the project's monorepo flag |
| `--dry-run` | Print JSON without uploading |
| `-s <url>`, `--server <url>` | Override server URL |
| `-t <jwt>`, `--token <jwt>` | Override project token |
| `-h`, `--help` | Show help |

### Dry run

```bash
op-indexer --dry-run
```

Use this to confirm the file set the indexer would upload without touching the server. Output is truncated source bodies + structural JSON.

## MCP tools the index powers

- `search` — find declarations by name / kind / file pattern / package. Filters: `query`, `kind` (function|component|class|const|let|type|interface|enum|hook|default), `file` (regex), `package`.
- `context` — full file source or one declaration's slice. Params: `file` (required, regex), `declaration` (optional name).
- `files` — list indexed files. Filters: `query` (path regex), `package`.

After a re-sync, prefer `search` over `find`/`grep` for declaration-level questions — it returns signatures + JSDoc out of the box.

## Configuration

`orchestration.json` (project root):

```json
{
  "server": "https://orchestrator.opflow.co.uk",
  "token": "<jwt>",
  "root": "/absolute/path/to/project",
  "exclude": ["docs", "build"],
  "dryRun": false
}
```

The `monorepo` field is now read from the orchestrator project (set under Settings → Project info). Local `monorepo` in `orchestration.json` only applies when the server is unreachable. CLI `--monorepo` / `--no-monorepo` always override.

## Notes

- Index is lossless: full file source is stored for every `.ts`/`.tsx`/`.js`/`.jsx`.
- `.gitignore` is respected at root and in nested directories.
- Non-monorepo projects: every file is tagged `package: "root"`; package selectors disappear from the orchestrator UI.
- The MCP endpoint requires the `X-Project-Token` header — already set up if you followed the Guide.
