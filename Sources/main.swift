import AppKit
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    private var title = "Notification"
    private var message = "Task completed"
    private var soundName = "Glass"

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)
        parseArguments()

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

    private func parseArguments() {
        let args = CommandLine.arguments
        var i = 1
        while i < args.count {
            let arg = args[i]
            if (arg == "--sound" || arg == "-s") && i + 1 < args.count {
                soundName = args[i + 1]
                i += 2
                continue
            } else if !arg.hasPrefix("-") {
                if title == "Notification" {
                    title = arg
                } else if message == "Task completed" {
                    message = arg
                }
            }
            i += 1
        }
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
        if let sound = NSSound(named: NSSound.Name(soundName)) {
            sound.play()
        } else {
            NSSound(named: "Glass")?.play()
        }
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
