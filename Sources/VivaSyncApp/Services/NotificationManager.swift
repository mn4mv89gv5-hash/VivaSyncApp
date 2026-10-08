import EventKit
import Foundation

public enum RemindersManagerError: LocalizedError {
    case accessDenied
    case reminderListNotFound
    case saveFailed(String)

    public var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "L'accesso ai promemoria non è stato autorizzato."
        case .reminderListNotFound:
            return "Lista promemoria non trovata."
        case .saveFailed(let message):
            return message
        }
    }
}

public final class RemindersManager {
    private let store: EKEventStore

    public init(store: EKEventStore = EKEventStore()) {
        self.store = store
    }

    public func requestAuthorization() async throws -> Bool {
        return try await store.requestAccess(to: .reminder)
    }

    public func upsertTasks(_ tasks: [ClasseVivaTask]) async throws {
        let allowed = try await requestAuthorization()
        guard allowed else { throw RemindersManagerError.accessDenied }

        let calendar = try reminderCalendar()

        for task in tasks {
            let reminder = EKReminder(eventStore: store)
            reminder.calendar = calendar
            reminder.title = "\(task.subject): \(task.title)"
            reminder.notes = task.description
            reminder.priority = 2

            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: task.dueDate)
            reminder.dueDateComponents = components
            reminder.isCompleted = false

            do {
                try store.save(reminder, commit: true)
            } catch {
                throw RemindersManagerError.saveFailed("Impossibile salvare il promemoria \(task.title): \(error.localizedDescription)")
            }
        }
    }

    private func reminderCalendar() throws -> EKCalendar {
        if let defaultCalendar = store.defaultCalendarForNewReminders() {
            return defaultCalendar
        }

        if let existing = store.calendars(for: .reminder).first(where: { $0.title == "VivaSyncApp" }) {
            return existing
        }

        throw RemindersManagerError.reminderListNotFound
    }
}
