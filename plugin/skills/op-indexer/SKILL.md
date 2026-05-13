---
name: op-indexer
description: Re-sync this project's code to the orchestrator so `opflow search`/`context`/`files` reflect the latest source. Use after non-trivial code changes, when the user says "re-index", "sync the code", "refresh the index", or invokes /op-indexer.
---

Part of the opflow-coder workflow.

`opflow index` scans a project's TS/JS source, extracts top-level declarations, and uploads everything to opflow-orchestrator. Once synced, the data is queryable via `opflow search`, `opflow context`, and `opflow files`.

## When to run

- After landing changes that touch declarations another agent might want to find (new endpoints, new components, renamed types).
- When `opflow search` returns stale results referencing files that no longer exist.
- When the user says "re-index" / "sync the code" / "refresh the index" or invokes `/op-indexer`.

Don't re-run after every edit — incremental scans are cheap on the server side, but each run still walks the filesystem. After a focused single-file edit, skip it; after a feature lands, run it.

## How to run

The `opflow` CLI is installed per the project Guide (`Settings → Your Claude Code setup`). It's on PATH after install.

### Standard re-sync

```bash
opflow index
```

Reads the active project + auth from `.opflow` + `~/.config/opflow/projects.json`, then walks the project root and pushes the declaration map.

### Common flags

| Flag | Description |
|------|-------------|
| `--root <dir>` | Project root (defaults to cwd) |
| `--exclude <glob>` | Add an exclude pattern (repeatable, in addition to .gitignore) |
| `--entry <path>` | Restrict scan to entry points (repeatable) |
| `--monorepo` / `--no-monorepo` | Override the project's monorepo flag |
| `--dry-run` | Print JSON without uploading |
| `--project <slug>` | Override the active `.opflow` project |
| `--json` | Machine-readable output |

### Dry run

```bash
opflow index --dry-run
```

Use this to confirm the file set the indexer would upload without touching the server.

## CLI commands the index powers

- `opflow search` — find declarations by name / kind / file pattern / package. Filters: `--query`, `--kind` (function|component|class|const|let|type|interface|enum|hook|default), `--file` (regex), `--package`.
- `opflow context` — full file source or one declaration's slice. Params: `--file` (required, regex), `--declaration` (optional name).
- `opflow files` — list indexed files. Filters: `--query` (path regex), `--package`.

After a re-sync, prefer `opflow search` over `find` / `grep` for declaration-level questions — it returns signatures + JSDoc out of the box.

## Notes

- Index is lossless: full file source is stored for every `.ts`/`.tsx`/`.js`/`.jsx`.
- `.gitignore` is respected at root and in nested directories.
- Non-monorepo projects: every file is tagged `package: "root"`; package selectors disappear from the orchestrator UI.
- The CLI authenticates with the project-scoped JWT written by `opflow auth login` — already set up if you followed the Guide.
