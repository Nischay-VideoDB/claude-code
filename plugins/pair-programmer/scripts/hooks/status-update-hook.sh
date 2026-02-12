#!/bin/bash
# Status update hook — fires on PreToolUse, reads transcript tail every N calls,
# and resumes the status-updater session to push a summary to the overlay.

INPUT=$(cat)
LOG="/tmp/videodb-hooks.log"
CONFIG_FILE="${HOME}/.config/videodb/config.json"
PORT=$(jq -r '.recorder_port // 8899' "$CONFIG_FILE" 2>/dev/null)
INTERVAL=$(jq -r '.status_update_interval // 3' "$CONFIG_FILE" 2>/dev/null)
COUNTER_FILE="/tmp/videodb-status-counter"
TRANSCRIPT_LINES=30

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""')
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // ""')

# Quick exit if recorder isn't running
if ! lsof -i :"$PORT" >/dev/null 2>&1; then
  exit 0
fi

# Only act on the pair-programmer session
PAIR_SESSION=$(curl -s --max-time 2 "http://127.0.0.1:${PORT}/api/claude-session" 2>/dev/null | jq -r '.claudeSessionId // ""' 2>/dev/null)
if [ -z "$PAIR_SESSION" ] || [ "$SESSION_ID" != "$PAIR_SESSION" ]; then
  exit 0
fi

# Counter-based throttling — only proceed every N tool calls
COUNT=0
if [ -f "$COUNTER_FILE" ]; then
  COUNT=$(cat "$COUNTER_FILE" 2>/dev/null || echo 0)
fi
COUNT=$((COUNT + 1))
echo "$COUNT" > "$COUNTER_FILE"

if [ $((COUNT % INTERVAL)) -ne 0 ]; then
  exit 0
fi

# Need a transcript to read
if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) [StatusUpdate] No transcript at $TRANSCRIPT_PATH" >> "$LOG"
  exit 0
fi

# Get the status session ID
STATUS_SESSION=$(curl -s --max-time 2 "http://127.0.0.1:${PORT}/api/status-session" 2>/dev/null | jq -r '.statusSessionId // ""' 2>/dev/null)
if [ -z "$STATUS_SESSION" ]; then
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) [StatusUpdate] No status session available" >> "$LOG"
  exit 0
fi

# Read last N lines from transcript
LINES=$(tail -n "$TRANSCRIPT_LINES" "$TRANSCRIPT_PATH" 2>/dev/null)
if [ -z "$LINES" ]; then
  exit 0
fi

echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) [StatusUpdate] Pushing transcript tail to status session (count=$COUNT)" >> "$LOG"

# Build the prompt with escaped content
PROMPT=$(echo "$LINES" | jq -Rs '.')

# Fire-and-forget: resume the status session with the transcript excerpt
PLUGIN_ARGS=""
if [ -n "$PLUGIN_PATH" ]; then
  PLUGIN_ARGS="--plugin-dir $PLUGIN_PATH"
fi

(claude $PLUGIN_ARGS --allowedTools Bash --dangerously-skip-permissions \
  -r "$STATUS_SESSION" \
  -p "Summarize what's happening and update the overlay. Transcript excerpt: $LINES" \
  --output-format json \
  >/dev/null 2>&1) &

exit 0
