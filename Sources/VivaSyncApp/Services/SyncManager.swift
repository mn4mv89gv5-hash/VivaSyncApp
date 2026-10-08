import BackgroundTasks
import Foundation

public final class BackgroundScheduler {
    public static let refreshTaskIdentifier = "com.vivasyncapp.refresh"

    public func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.refreshTaskIdentifier, using: nil) { task in
            guard let appRefreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }

            Task {
                do {
                    let syncManager = SyncManager()
                    try await syncManager.runSync()
                    appRefreshTask.setTaskCompleted(success: true)
                } catch {
                    appRefreshTask.setTaskCompleted(success: false)
                }
            }
        }
    }

    public func scheduleDailySync(at hour: Int = 15, minute: Int = 0) {
        let now = Date()
        let calendar = Calendar.current

        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: now)
        components.hour = hour
        components.minute = minute
        components.second = 0

        guard let triggerDate = calendar.date(from: components) else { return }

        let nextDate = triggerDate > now ? triggerDate : calendar.date(byAdding: .day, value: 1, to: triggerDate) ?? triggerDate

        let request = BGAppRefreshTaskRequest(identifier: Self.refreshTaskIdentifier)
        request.earliestBeginDate = nextDate

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Unable to schedule background refresh: \(error)")
        }
    }
}
