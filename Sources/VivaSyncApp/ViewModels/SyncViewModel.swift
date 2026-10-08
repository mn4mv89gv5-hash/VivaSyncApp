import Foundation

public final class SyncManager {
    private let client: SpaggiariClient
    private let eventKitManager: EventKitManager
    private let remindersManager: RemindersManager
    private let notificationManager: NotificationManager

    public init(
        client: SpaggiariClient = SpaggiariClient(),
        eventKitManager: EventKitManager = EventKitManager(),
        remindersManager: RemindersManager = RemindersManager(),
        notificationManager: NotificationManager = NotificationManager()
    ) {
        self.client = client
        self.eventKitManager = eventKitManager
        self.remindersManager = remindersManager
        self.notificationManager = notificationManager
    }

    public func runSync() async throws {
        guard let credentials = try KeychainManager.read() else {
            return
        }

        let token = try await client.login(username: credentials.username, password: credentials.password)

        let startDate = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date()
        let tasks = try await client.fetchAssignments(token: token, from: startDate, to: endDate)

        try await eventKitManager.upsertTasks(tasks)
        try await remindersManager.upsertTasks(tasks)
        notificationManager.scheduleSyncCompleteNotification()
    }
}
