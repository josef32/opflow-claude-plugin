#!/usr/bin/env bash
# Opflow plugin: at session start, prompt Claude to load active plans
# and the latest handover so it has the orchestrator's project context
# before the user asks for anything.
set -euo pipefail

cat <<'EOF'
The opflow Claude Code plugin is installed and the orchestrator MCP is registered.

When relevant to the user's first request, call these MCP tools to orient yourself in the project:
- `plan-active` — current active plans (call with no args, or with `package: "<current-package>"` if working in a monorepo).
- `handover-latest` — the most recent handover record, useful for picking up where the previous session left off.

Don't dump these results to the user unprompted. Use them as context for tailoring your responses.
EOF
