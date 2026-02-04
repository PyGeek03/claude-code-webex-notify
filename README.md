# Claude Code WebEx Notifications

Get notified on WebEx (or Slack, Discord, etc.) when Claude Code needs your input and you haven't responded within a configurable timeout.
Very useful when you let Claude do its thing while you switched your attention to something else or stepped away from your laptop.

## How It Works

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              Permission Prompt                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  1. Claude Code shows permission prompt                                     │
│                     │                                                       │
│                     ▼                                                       │
│  2. Notification hook fires ──► Creates marker file + starts 60s timer      │
│                    │                                                        │
│          ┌─────────┴─────────┐                                              │
│          │                   │                                              │
│          ▼                   ▼                                              │
│   User responds         User doesn't respond                                │
│          │                   │                                              │
│          ▼                   ▼                                              │
│   PostToolUse hook      Timer expires                                       │
│   deletes marker             │                                              │
│          │                   ▼                                              │
│          ▼              Marker still exists?                                │
│   No notification            │                                              │
│                    ┌─────────┴───────┐                                      │
│                    │                 │                                      │
│                   Yes                No                                     │
│                    │                 │                                      │
│                    ▼                 ▼                                      │
│            Send WebEx         No notification                               │
│            notification                                                     │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Quick Start

```bash
# Clone the repo
git clone https://github.com/user/claude-code-webex-notify.git
cd claude-code-webex-notify

# Run the installer
./install.sh
```

The installer will:
1. Copy scripts to `~/.claude/waiting/`
2. Prompt for your webhook URL
3. Add hooks to your Claude Code settings

## Prerequisites

- macOS or Linux
- `jq` installed (`brew install jq` or `apt install jq`)
- Claude Code CLI
- Webhook URL from WebEx, Slack, Discord, or similar service

## Getting a WebEx Webhook URL

1. Go to [WebEx Incoming Webhooks App](https://apphub.webex.com/applications/incoming-webhooks-cisco-systems-38054-23307-75252)
2. Click **Connect** (sign in if prompted)
3. Enter a name (e.g., "Claude Code Alerts")
4. Select the Space where you want notifications (tip: create a dedicated space for this)
5. Click **Add**
6. Copy the generated Webhook URL

## Manual Installation

If you prefer not to use the installer:

### 1. Create scripts directory

```bash
mkdir -p ~/.claude/waiting
```

### 2. Copy scripts

```bash
cp scripts/notify-if-away.sh ~/.claude/waiting/
cp scripts/cleanup-marker.sh ~/.claude/waiting/
chmod +x ~/.claude/waiting/*.sh
```

### 3. Configure webhook URL

Edit `~/.claude/waiting/notify-if-away.sh` and set your webhook URL:

```bash
WEBHOOK_URL="https://webexapis.com/v1/webhooks/incoming/YOUR_WEBHOOK_ID"
```

### 4. Add hooks to Claude Code settings

Add to your `~/.claude/settings.json`:

```json
{
  "hooks": {
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
  }
}
```

## Configuration

| Setting      | Location              | Default                                       | Description                                 |
|--------------|-----------------------|-----------------------------------------------|---------------------------------------------|
| TIMEOUT      | notify-if-away.sh     | 60                                            | Seconds to wait before sending notification |
| WEBHOOK_URL  | notify-if-away.sh     | -                                             | Your webhook URL                            |
| Message text | notify-if-away.sh     | "Claude Code needs your input to proceed"    | Notification message                        |

## Testing

### Test webhook manually

```bash
curl -X POST "YOUR_WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{"text": "Test notification from Claude Code"}'
```

### Test notification is NOT sent when you respond quickly

1. Trigger a Claude Code command that requires permission
2. Approve it immediately
3. Wait 60+ seconds
4. Verify no notification received

### Test notification IS sent when you don't respond

1. Trigger a Claude Code command that requires permission
2. Do NOT respond
3. Wait 60+ seconds
4. Verify notification received

## Alternative Notification Services

The webhook approach works with any service that accepts HTTP POST requests. Modify `notify-if-away.sh` for your service:

### Slack

```bash
WEBHOOK_URL="https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK"
# curl command stays the same
```

### Discord

```bash
WEBHOOK_URL="https://discord.com/api/webhooks/YOUR_WEBHOOK_ID"
curl -s -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{"content": "Claude Code needs your input to proceed"}'
```

### ntfy.sh (free, no account needed)

```bash
curl -d "Claude Code needs your input to proceed" ntfy.sh/your-topic
```

### Pushover

```bash
curl -s -F "token=YOUR_APP_TOKEN" \
  -F "user=YOUR_USER_KEY" \
  -F "message=Claude Code needs your input to proceed" \
  https://api.pushover.net/1/messages.json
```

## Troubleshooting

| Issue                                    | Solution                                                         |
|------------------------------------------|------------------------------------------------------------------|
| No notification received                 | Check webhook URL is correct; test manually with curl            |
| Notification sent even after responding  | Verify cleanup-marker.sh is executable and hooks are configured  |
| `command not found: jq`                  | Install jq: `brew install jq` or `apt install jq`                |
| Permission denied on scripts             | Run `chmod +x ~/.claude/waiting/*.sh`                            |

## Uninstall

```bash
rm -rf ~/.claude/waiting
# Then manually remove the hooks section from ~/.claude/settings.json
```

## License

MIT
