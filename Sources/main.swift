import AppKit
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    private var title = "Claude Code"
    private var message = "Awaiting your input"
    private let soundName = "Glass"

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
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) ->
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
