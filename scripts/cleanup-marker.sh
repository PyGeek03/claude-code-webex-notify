#!/bin/bash
# Remove the marker file when user responds to permission prompt

# Capture session_id from hook input via stdin
HOOK_INPUT=$(cat)
SESSION_ID=$(echo "$HOOK_INPUT" | jq -r '.session_id')

MARKER_DIR="$HOME/.claude/waiting"
MARKER_FILE="$MARKER_DIR/session_$SESSION_ID"
rm -f "$MARKER_FILE"
