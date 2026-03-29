import Foundation
import UserNotifications

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
    }

    func sendOutdatedNotification(count: Int) {
        let content = UNMutableNotificationContent()
        content.title = "BrewDesk"
        content.body = "\(count) package\(count == 1 ? "" : "s") can be upgraded."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "outdated-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}
