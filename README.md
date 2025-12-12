# ClaudeNotifier

A macOS notification agent for sending system notifications with sound and icon from the command line.

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
```

## First Run

On first launch, the system will prompt for notification permission. Click "Allow".

If you missed the prompt, go to: **System Settings > Notifications > ClaudeNotifier** and enable notifications.

## Usage

### Basic

```bash
open -a ClaudeNotifier --args "Title" "Message"
```

### Custom Sound

```bash
open -a ClaudeNotifier --args "Title" "Message" --sound Hero
open -a ClaudeNotifier --args "Title" "Message" -s Funk
```

### Available Sounds

**Glass** (default), Basso, Blow, Bottle, Frog, Funk, Hero, Morse, Ping, Pop, Purr, Sosumi, Submarine, Tink

## Custom Icon

Place `AppIcon.icns` in the project root. It will be copied to the app bundle during build.

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
            "command": "open -a ClaudeNotifier --args 'Claude Code' 'Awaiting your input' -s Funk"
          }
        ]
      }
    ]
  }
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
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f ClaudeNotifier.app
```

## License

MIT
