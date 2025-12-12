import AppKit
import UserNotifications

func printHelp() {
    print("""
    ClaudeNotifier - macOS notification agent for Claude Code hooks

    USAGE:
        echo '{"message":"..."}' | claude-notify [-s SOUND]

    OPTIONS:
        -s, --sound SOUND   Custom sound (default: Glass)
        -h, --help          Show help

    JSON FIELDS:
        message             Notification body
        notification_type   Title (snake_case → Title Case)
        cwd                 Working directory (for window matching)

    BEHAVIOR:
        Click notification → activate matching Terminal window
        No click → auto-exit after 60s
    """)
}

// Check help flag early
if CommandLine.arguments.contains("-h") || CommandLine.arguments.contains("--help") {
    printHelp()
    exit(0)
}

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    var title = "Claude Notifier"
    var message = "Hello!"
    var cwd: String?
    var soundName = "Glass"

    override init() {
        super.init()
        // Parse -s/--sound argument
        let args = CommandLine.arguments
        for i in 0..<args.count {
            if (args[i] == "-s" || args[i] == "--sound") && i + 1 < args.count {
                soundName = args[i + 1]
                break
            }
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let hasData = parseStdin()
        UNUserNotificationCenter.current().delegate = self

        guard hasData else {
            // Launched by notification click, wait for didReceive
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { NSApp.terminate(nil) }
            return
        }

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                if settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional {
                    self.sendNotification()
                } else if settings.authorizationStatus == .notDetermined {
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
                        if granted { DispatchQueue.main.async { self.sendNotification() } }
                        else { NSApp.terminate(nil) }
                    }
                } else {
                    print("Error: Notifications disabled")
                    NSApp.terminate(nil)
                }
            }
        }
    }

    private func parseStdin() -> Bool {
        guard isatty(STDIN_FILENO) == 0 else { return false }
        let data = FileHandle.standardInput.readDataToEndOfFile()
        guard !data.isEmpty,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return false }

        if let m = json["message"] as? String { message = m }
        if let t = json["notification_type"] as? String {
            title = t.split(separator: "_").map { $0.capitalized }.joined(separator: " ")
        }
        if let c = json["cwd"] as? String { cwd = c }
        return true
    }

    private func sendNotification() {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.interruptionLevel = .timeSensitive
        content.userInfo = ["cwd": cwd ?? ""]

        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        ) { _ in
            DispatchQueue.main.async {
                NSSound(named: NSSound.Name(self.soundName))?.play()
                DispatchQueue.main.asyncAfter(deadline: .now() + 60) { NSApp.terminate(nil) }
            }
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent: UNNotification,
                                withCompletionHandler handler: @escaping (UNNotificationPresentationOptions) -> Void) {
        handler([.banner, .list])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                withCompletionHandler handler: @escaping () -> Void) {
        let targetCwd = response.notification.request.content.userInfo["cwd"] as? String
        activateTerminal(cwd: targetCwd)
        handler()
        NSApp.terminate(nil)
    }

    private func activateTerminal(cwd: String?) {
        let dirName = cwd.flatMap { ($0 as NSString).lastPathComponent }

        let script: String
        if let dir = dirName {
            let escaped = dir.replacingOccurrences(of: "\\", with: "\\\\")
                             .replacingOccurrences(of: "\"", with: "\\\"")
            script = """
            tell application "Terminal" to activate
            tell application "System Events"
                tell process "Terminal"
                    set frontmost to true
                    repeat with w in windows
                        if name of w starts with "\(escaped)" then
                            perform action "AXRaise" of w
                            exit repeat
                        end if
                    end repeat
                end tell
            end tell
            """
        } else {
            script = "tell application \"Terminal\" to activate"
        }

        NSAppleScript(source: script)?.executeAndReturnError(nil)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.setActivationPolicy(.accessory)
app.delegate = delegate
app.run()
