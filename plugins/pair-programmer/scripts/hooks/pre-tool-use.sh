#!/bin/bash
INPUT=$(cat)
LOG="/tmp/videodb-hooks.log"

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
TOOL_INPUT=$(echo "$INPUT" | jq -c '.tool_input // {}' 2>/dev/null | head -c 500)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
CWD=$(echo "$INPUT" | jq -r '.cwd // "unknown"')
PERM_MODE=$(echo "$INPUT" | jq -r '.permission_mode // "unknown"')

echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) [PreToolUse] tool=$TOOL_NAME mode=$PERM_MODE session=${SESSION_ID:0:8} cwd=$CWD input=$TOOL_INPUT" >> "$LOG"

exit 0
