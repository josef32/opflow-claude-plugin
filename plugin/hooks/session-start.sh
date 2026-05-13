#!/usr/bin/env bash
# Opflow plugin: at session start, prompt Claude to load active plans
# and the latest handover so it has the orchestrator's project context
# before the user asks for anything.
set -euo pipefail

cat <<'EOF'
The opflow Claude Code plugin is installed and the `opflow` CLI is authenticated against this project.

When relevant to the user's first request, run these CLI commands to orient yourself in the project:
- `opflow plan active --json` — current active plans (add `--package <current-package>` if working in a monorepo).
- `opflow handover latest --json` — the most recent handover record, useful for picking up where the previous session left off.

Don't dump these results to the user unprompted. Use them as context for tailoring your responses.
EOF
