---
name: handover
description: Structured workflow for creating handover records after commits via the `opflow` CLI. Use when AI commits code and user confirms, or user says "create a handover", or invokes /handover.
---

Part of the opflow-coder workflow.

Structured workflow for creating handover records after commits via the `opflow` CLI.

## CLI commands

- `opflow handover create --name <n> --packages <json|csv> --files <json> --tasks <json|csv> --notes <text> --commitid <sha>` — Create a handover.
- `opflow handover latest [--package <p>]` — Get most recent handover.
- `opflow handover list [--query <q>] [--package <p>] [--limit <n>] [--before <iso>]` — Search/list handovers, most-recent-first. `--query` matches name/notes/completedTasks; `--before` is an ISO date cursor for pagination.

**Long-form values from files.** Any string flag accepts `@path` to load from a file: `--notes @notes.md`, `--files @files.json`. Use `@@` for a literal `@`.

**Output.** Add `--json` for machine-readable output (default JSON when stdout is piped).

## Workflow: Search Handovers

When the user asks to find a past handover ("find a handover about X", "what did we do for Y"):

1. Run `opflow handover list --query <topic> --json`. Add `--package <pkg>` if the user scoped it to one.
2. If results are empty, retry with a broader/shorter query (one keyword instead of a phrase).
3. Summarise matches by name + date + commitId; surface the relevant excerpt from notes.
4. For pagination, pass the oldest returned `date` as `--before` on the next call.

Use `opflow handover latest` only when the user explicitly wants the most recent one — `opflow handover list` (with no query) is preferable for browsing because it returns multiple entries.

## Workflow: Create Handover

After the AI completes work and commits:

1. Auto-detect affected files:
   ```bash
   git diff HEAD~1 --stat
   ```
   Parse output to get file paths and addition/removal counts.

2. Auto-detect commit ID:
   ```bash
   git rev-parse HEAD
   ```

3. Auto-detect affected packages from file paths. Pick the heuristic that matches the repo:
   - **Monorepo** (`packages/<name>/...`, `apps/<name>/...`, `services/<name>/...`): use `<name>`.
   - **Single-package repo**: use the project name from `package.json#name` or the repo name from `git remote get-url origin`.
   - **Top-level files** (AGENTS.md, README.md, CLAUDE.md, etc.): include the filename in `affectedPackages` so the change stays searchable.
   If the layout is ambiguous, ask the user once and reuse the choice.

4. Show user the detected information:
   ```
   Commit: abc123
   Files:
     endpoints/users.ts (+12 -0)
     AGENTS.md (+8 -2)
   Packages: opflow-orchestrator
   Should I create a handover?
   ```

5. User confirms or modifies the information.

6. Ask user for:
   - Handover name (e.g., "08 — User Endpoints")
   - Completed tasks (list of what was accomplished) — suggest based on the chat summary.

7. Draft notes in markdown:
   ```markdown
   ## Summary
   <brief description of what was done>

   ## Changes
   <list of key changes>

   ## Learnings
   <any learnings from this session>

   ## Next Steps
   <planned next steps>
   ```
   Write to a temp file (`notes.md`) so quoting doesn't get in the way. Same for the file list:
   ```json
   // files.json
   [
     { "path": "endpoints/users.ts", "additions": 12, "removals": 0 },
     { "path": "AGENTS.md", "additions": 8, "removals": 2 }
   ]
   ```

8. Submit:
   ```bash
   opflow handover create \
       --name "08 — User Endpoints" \
       --packages "opflow-orchestrator" \
       --files @files.json \
       --tasks '["Wire user endpoints","Update AGENTS.md"]' \
       --notes @notes.md \
       --commitid "$(git rev-parse HEAD)"
   ```

9. Confirm to user: "Created handover '<name>'".

## Rules

- Always auto-detect from git first, then ask user to confirm.
- Never create a handover without a commit.
- Notes should be comprehensive but concise.
- Include file:line references in notes when relevant.
- Each handover should be self-contained — someone reading it later should understand what happened.
