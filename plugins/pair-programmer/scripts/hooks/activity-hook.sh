#!/bin/bash
# Unified hook script for the overlay activity feed.
# Handles: PreToolUse, PostToolUse, PostToolUseFailure, Stop, Notification, SubagentStart, SubagentStop.
# Checks session_id, extracts relevant fields, and POSTs to the recorder.
INPUT=$(cat)
LOG="/tmp/videodb-hooks.log"
CONFIG_FILE="${HOME}/.config/videodb/config.json"
PORT=$(jq -r '.recorder_port // 8899' "$CONFIG_FILE" 2>/dev/null)

EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // "unknown"')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""')

# Quick exit if recorder isn't running
if ! lsof -i :"$PORT" >/dev/null 2>&1; then
  exit 0
fi

# Check if this is the pair-programmer session
PAIR_SESSION=$(curl -s --max-time 2 "http://127.0.0.1:${PORT}/api/claude-session" 2>/dev/null | jq -r '.claudeSessionId // ""' 2>/dev/null)

if [ -z "$PAIR_SESSION" ] || [ "$SESSION_ID" != "$PAIR_SESSION" ]; then
  exit 0
fi

# Build the payload based on event type
case "$EVENT" in
  PreToolUse|PostToolUse|PostToolUseFailure)
    TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
    TOOL_INPUT=$(echo "$INPUT" | jq -c '.tool_input // {}' 2>/dev/null | head -c 300)
    TOOL_OUTPUT=""
    if [ "$EVENT" = "PostToolUse" ] || [ "$EVENT" = "PostToolUseFailure" ]; then
      TOOL_OUTPUT=$(echo "$INPUT" | jq -c '.tool_output // ""' 2>/dev/null | head -c 300)
    fi
    PAYLOAD=$(jq -n \
      --arg event "$EVENT" \
      --arg tool_name "$TOOL_NAME" \
      --arg tool_input "$TOOL_INPUT" \
      --arg tool_output "$TOOL_OUTPUT" \
      '{event: $event, tool_name: $tool_name, tool_input: $tool_input, tool_output: $tool_output}')
    ;;
  Stop)
    STOP_REASON=$(echo "$INPUT" | jq -r '.stop_reason // "end_turn"')
    PAYLOAD=$(jq -n --arg event "$EVENT" --arg reason "$STOP_REASON" '{event: $event, stop_reason: $reason}')
    ;;
  SubagentStart)
    AGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // "unknown"')
    PAYLOAD=$(jq -n --arg event "$EVENT" --arg agent "$AGENT_TYPE" '{event: $event, agent_type: $agent}')
    ;;
  SubagentStop)
    AGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // "unknown"')
    PAYLOAD=$(jq -n --arg event "$EVENT" --arg agent "$AGENT_TYPE" '{event: $event, agent_type: $agent}')
    ;;
  Notification)
    NOTIF_TYPE=$(echo "$INPUT" | jq -r '.notification_type // ""')
    NOTIF_MSG=$(echo "$INPUT" | jq -r '.message // ""' | head -c 300)
    PAYLOAD=$(jq -n --arg event "$EVENT" --arg type "$NOTIF_TYPE" --arg msg "$NOTIF_MSG" \
      '{event: $event, notification_type: $type, message: $msg}')
    ;;
  *)
    exit 0
    ;;
esac

echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) [ActivityHook] $EVENT session=${SESSION_ID:0:8}" >> "$LOG"

# Fire-and-forget POST to the recorder
curl -s --max-time 2 -X POST "http://127.0.0.1:${PORT}/api/hook-event" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" >/dev/null 2>&1 &

exit 0
