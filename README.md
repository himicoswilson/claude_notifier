# ClaudeNotifier

A macOS notification agent for Claude Code hooks. Reads JSON from stdin and displays system notifications.

## Build

### Requirements

- macOS 13.0+
- Swift 5.9+
- Xcode Command Line Tools

### Steps

```bash
cd claude_notifier
./build.sh
```

## Install

```bash
cp -r ClaudeNotifier.app /Applications/
sudo ln -sf /Applications/ClaudeNotifier.app/Contents/MacOS/ClaudeNotifier /usr/local/bin/claude-notify
```

## First Run

On first launch, the system will prompt for notification permission. Click "Allow".

If you missed the prompt, go to: **System Settings > Notifications > ClaudeNotifier** and enable notifications.

## Usage

ClaudeNotifier reads JSON from stdin and extracts:

- `message` → notification body
- `notification_type` → notification title (formatted: `permission_prompt` → "Permission Prompt")

```bash
echo '{"message":"Hello","notification_type":"permission_prompt"}' | claude-notify
```

## Claude Code Integration

Add to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "claude-notify"
          }
        ]
      }
    ]
  }
}
```

Claude Code passes JSON to the hook via stdin:

```json
{
  "session_id": "abc123",
  "transcript_path": "/Users/.../.claude/projects/.../00893aaf-19fa-41d2-8238-13269b9b3ca0.jsonl",
  "cwd": "/Users/...",
  "permission_mode": "default",
  "hook_event_name": "Notification",
  "message": "Claude needs your permission to use Bash",
  "notification_type": "permission_prompt"
}
```

## Project Structure

```
claude_notifier/
├── Sources/main.swift
├── Package.swift
├── AppIcon.icns
├── build.sh
└── README.md
```

## Troubleshooting

### No Sound

1. Check **System Settings > Notifications > ClaudeNotifier**, ensure "Sound" is enabled
2. Check system volume is not muted
3. macOS Tahoe has known audio bugs, run `sudo killall coreaudiod` as a workaround

### Permission Denied

Go to **System Settings > Notifications**, find ClaudeNotifier and enable it.

### Icon Not Showing

Re-register the app:

```bash
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f /Applications/ClaudeNotifier.app
```

## Uninstall

To completely remove ClaudeNotifier from your system:

```bash
# Remove the application
rm -rf /Applications/ClaudeNotifier.app

# Remove the symlink
sudo rm -f /usr/local/bin/claude-notify

# Remove Claude Code hook configuration
# Edit ~/.claude/settings.json and remove the "Notification" hook entry

# Remove notification settings (macOS stores these automatically)
# Go to System Settings > Notifications and ClaudeNotifier will disappear after removal

# Remove LaunchServices registration cache (optional, clears app icon cache)
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -u /Applications/ClaudeNotifier.app 2>/dev/null

# Remove Swift Package Manager build cache (if you built from source)
rm -rf ~/Library/Developer/Xcode/DerivedData/ClaudeNotifier-*
rm -rf .build/
```

## License

MIT
