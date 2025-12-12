import AppKit
import UserNotifications

func printHelp() {
    let help = """
        ClaudeNotifier - macOS notification agent for Claude Code hooks

        USAGE:
            echo '{"message":"...","notification_type":"..."}' | claude-notify [-s SOUND]
            claude-notify -h | --help

        OPTIONS:
            -s, --sound SOUND   Custom sound name (default: Glass)
            -h, --help          Show this help message

        JSON FIELDS:
            message             Notification body text
            notification_type   Notification title (snake_case → Title Case)

        AVAILABLE SOUNDS:
            Glass (default), Basso, Blow, Bottle, Frog, Funk, Hero,
            Morse, Ping, Pop, Purr, Sosumi, Submarine, Tink

        EXAMPLES:
            echo '{"message":"Task done"}' | claude-notify
            echo '{"message":"Hello"}' | claude-notify -s Funk
        """
    print(help)
}

func checkHelpFlag() -> Bool {
    let args = CommandLine.arguments
    return args.contains("-h") || args.contains("--help")
}

func parseSoundArg() -> String? {
    let args = CommandLine.arguments
    for i in 0..<args.count {
        if (args[i] == "-s" || args[i] == "--sound") && i + 1 < args.count {
            return args[i + 1]
        }
    }
    return nil
}

if checkHelpFlag() {
    printHelp()
    exit(0)
}

let customSound = parseSoundArg()

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    private var title = "Claude Notifier"
    private var message = "Hello!"
    private var soundName = customSound ?? "Glass"

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)
        parseStdinJSON()

        let center = UNUserNotificationCenter.current()
        center.delegate = self

        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized, .provisional:
                    self.sendNotification()
                case .notDetermined:
                    self.requestPermission()
                case .denied:
                    print(
                        "Error: Notification permission denied. Enable in System Settings > Notifications."
                    )
                    self.quit()
                @unknown default:
                    self.requestPermission()
                }
            }
        }
    }

    private func parseStdinJSON() {
        guard isatty(STDIN_FILENO) == 0 else { return }

        let data = FileHandle.standardInput.readDataToEndOfFile()
        guard !data.isEmpty else { return }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }

        if let msg = json["message"] as? String {
            message = msg
        }
        if let type = json["notification_type"] as? String {
            title = formatNotificationType(type)
        }
    }

    private func formatNotificationType(_ type: String) -> String {
        type.split(separator: "_").map { $0.capitalized }.joined(separator: " ")
    }

    private func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
            granted, _ in
            DispatchQueue.main.async {
                if granted {
                    self.sendNotification()
                } else {
                    print("Error: Notification permission not granted.")
                    self.quit()
                }
            }
        }
    }

    private func sendNotification() {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        let request = UNNotificationRequest(
            identifier: UUID().uuidString, content: content, trigger: nil)

        UNUserNotificationCenter.current().add(request) { _ in
            DispatchQueue.main.async {
                self.playSound()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { self.quit() }
            }
        }
    }

    private func playSound() {
        NSSound(named: NSSound.Name(soundName))?.play()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter, willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
            @escaping (UNNotificationPresentationOptions) ->
            Void
    ) {
        completionHandler([.banner, .sound, .list])
    }

    private func quit() {
        NSApplication.shared.terminate(nil)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.setActivationPolicy(.accessory)
app.delegate = delegate
app.run()
