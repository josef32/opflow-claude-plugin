#!/usr/bin/env bash
# Opflow plugin: after a successful `git commit`, nudge Claude to ask
# whether the user wants a handover record. Only fires on the parent
# `git commit` invocation, not unrelated Bash usage.
set -euo pipefail

input=$(cat)

# jq is widely available; if missing, just exit silently.
if ! command -v jq >/dev/null 2>&1; then
    exit 0
fi

cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)
exit_code=$(printf '%s' "$input" | jq -r '.tool_response.exit_code // .tool_response.exitCode // 0' 2>/dev/null || echo 0)

# Match `git commit` at the start of the command (allow for `git -c ... commit`).
case "$cmd" in
    *"git commit"*|*"git -c"*"commit"*)
        if [ "$exit_code" = "0" ]; then
            jq -nc --arg ctx "A git commit just landed. Ask the user whether they'd like a handover record created via the handover skill — it's a low-friction way to capture what changed and why for future sessions. Don't create one without confirmation." \
                '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: $ctx}}'
        fi
        ;;
esac

exit 0
