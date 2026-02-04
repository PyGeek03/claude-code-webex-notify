#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/.claude/waiting"
SETTINGS_FILE="$HOME/.claude/settings.json"

echo "Claude Code Webhook Notifications Installer"
echo "============================================"
echo

# Check for jq
if ! command -v jq &> /dev/null; then
  echo "Error: jq is required but not installed."
  echo "Install with: brew install jq (macOS) or apt install jq (Linux)"
  exit 1
fi

# Create install directory
echo "Creating $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"

# Copy scripts
echo "Copying scripts..."
cp "$SCRIPT_DIR/scripts/notify-if-away.sh" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/scripts/cleanup-marker.sh" "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR"/*.sh

# Prompt for webhook URL
echo
read -p "Enter your webhook URL: " WEBHOOK_URL

if [ -z "$WEBHOOK_URL" ]; then
  echo "Warning: No webhook URL provided. Edit $INSTALL_DIR/notify-if-away.sh manually."
else
  # Update the webhook URL in the script
  sed -i.bak "s|YOUR_WEBHOOK_URL|$WEBHOOK_URL|g" "$INSTALL_DIR/notify-if-away.sh"
  rm -f "$INSTALL_DIR/notify-if-away.sh.bak"
  echo "Webhook URL configured."
fi

# Prompt for timeout
echo
read -p "Notification timeout in seconds [60]: " TIMEOUT
TIMEOUT=${TIMEOUT:-60}
sed -i.bak "s|TIMEOUT=60|TIMEOUT=$TIMEOUT|g" "$INSTALL_DIR/notify-if-away.sh"
rm -f "$INSTALL_DIR/notify-if-away.sh.bak"

# Configure Claude Code hooks
echo
echo "Configuring Claude Code hooks..."

HOOKS_JSON='{
  "Notification": [
    {
      "matcher": "permission_prompt|elicitation_dialog",
      "hooks": [
        {
          "type": "command",
          "command": "~/.claude/waiting/notify-if-away.sh"
        }
      ]
    }
  ],
  "PostToolUse": [
    {
      "matcher": "",
      "hooks": [
        {
          "type": "command",
          "command": "~/.claude/waiting/cleanup-marker.sh"
        }
      ]
    }
  ],
  "PostToolUseFailure": [
    {
      "matcher": "",
      "hooks": [
        {
          "type": "command",
          "command": "~/.claude/waiting/cleanup-marker.sh"
        }
      ]
    }
  ]
}'

if [ -f "$SETTINGS_FILE" ]; then
  # Check if hooks already exist
  if jq -e '.hooks' "$SETTINGS_FILE" > /dev/null 2>&1; then
    echo "Warning: hooks already exist in $SETTINGS_FILE"
    echo "Please manually merge the following hooks configuration:"
    echo
    echo "$HOOKS_JSON" | jq .
    echo
  else
    # Add hooks to existing settings
    jq --argjson hooks "$HOOKS_JSON" '. + {hooks: $hooks}' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp"
    mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
    echo "Hooks added to $SETTINGS_FILE"
  fi
else
  # Create new settings file
  echo "{\"hooks\": $HOOKS_JSON}" | jq . > "$SETTINGS_FILE"
  echo "Created $SETTINGS_FILE with hooks configuration"
fi

echo
echo "Installation complete!"
echo
echo "Test your webhook with:"
echo "  curl -X POST '$WEBHOOK_URL' -H 'Content-Type: application/json' -d '{\"text\": \"Test\"}'"
echo
echo "To uninstall:"
echo "  rm -rf ~/.claude/waiting"
echo "  # Then remove hooks from ~/.claude/settings.json"
