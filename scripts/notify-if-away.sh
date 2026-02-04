#!/bin/bash
# Notify via webhook if user hasn't responded to permission prompt within timeout

# Capture session_id from hook input via stdin (must be done before backgrounding)
HOOK_INPUT=$(cat)
SESSION_ID=$(echo "$HOOK_INPUT" | jq -r '.session_id')

# ============================================================================
# CONFIGURATION - Edit these values
# ============================================================================
WEBHOOK_URL="YOUR_WEBHOOK_URL"  # Replace with your webhook URL
TIMEOUT=60                       # Seconds to wait before sending notification
MESSAGE="Claude Code needs your input to proceed"
# ============================================================================

MARKER_DIR="$HOME/.claude/waiting"
MARKER_FILE="$MARKER_DIR/session_$SESSION_ID"

# Create marker directory if needed
mkdir -p "$MARKER_DIR"

# Create marker file before sleeping
touch "$MARKER_FILE"

# Background the sleep + notify part
(
  sleep $TIMEOUT

  # After timeout, check if marker file still exists
  # If it exists, user hasn't responded - send notification
  if [ -f "$MARKER_FILE" ]; then
    curl -s -X POST "$WEBHOOK_URL" \
      -H "Content-Type: application/json" \
      -d "{\"text\": \"$MESSAGE\"}"
    # Clean up marker file after sending
    rm -f "$MARKER_FILE"
  fi
) &
