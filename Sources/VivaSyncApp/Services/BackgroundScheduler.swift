import Foundation
import UserNotifications

public final class NotificationManager {
    public init() {}

    public func requestAuthorization() async throws {
        let center = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        try await center.requestAuthorization(options: options)
    }

    public func scheduleSyncCompleteNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Compiti sincronizzati"
        content.body = "I compiti sono stati aggiunti sul calendario e sui promemoria per Classe Viva."
        content.sound = .default
        content.badge = 1

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "vivaSyncComplete",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }
}
