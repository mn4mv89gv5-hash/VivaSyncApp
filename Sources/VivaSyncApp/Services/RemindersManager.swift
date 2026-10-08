import EventKit
import Foundation

public enum EventKitManagerError: LocalizedError {
    case accessDenied
    case saveFailed(String)
    case calendarNotFound

    public var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "L'accesso al calendario non è stato autorizzato."
        case .saveFailed(let message):
            return message
        case .calendarNotFound:
            return "Calendario VivaSync non trovato."
        }
    }
}

public final class EventKitManager {
    private let store: EKEventStore

    public init(store: EKEventStore = EKEventStore()) {
        self.store = store
    }

    public func requestAuthorization() async throws -> Bool {
        if #available(iOS 17.0, *) {
            return try await store.requestFullAccessToEvents()
        } else {
            return try await store.requestAccess(to: .event)
        }
    }

    public func upsertTasks(_ tasks: [ClasseVivaTask]) async throws {
        let allowed = try await requestAuthorization()
        guard allowed else { throw EventKitManagerError.accessDenied }

        let calendar = try eventCalendar()

        for task in tasks {
            let event = EKEvent(eventStore: store)
            event.calendar = calendar
            event.title = "\(task.subject): \(task.title)"
            event.notes = task.description
            event.startDate = task.dueDate
            event.endDate = task.dueDate.addingTimeInterval(60 * 60)
            event.isAllDay = false
            event.timeZone = TimeZone.current

            do {
                try store.save(event, span: .thisEvent)
            } catch {
                throw EventKitManagerError.saveFailed("Impossibile aggiungere l'evento \(task.title): \(error.localizedDescription)")
            }
        }
    }

    private func eventCalendar() throws -> EKCalendar {
        let calendars = store.calendars(for: .event)
        if let existing = calendars.first(where: { $0.title == "VivaSyncApp" }) {
            return existing
        }

        let calendar = EKCalendar(for: .event, eventStore: store)
        calendar.title = "VivaSyncApp"
        calendar.cgColor = UIColor.systemBlue.cgColor

        if let source = store.defaultCalendarForNewEvents?.source {
            calendar.source = source
        } else if let source = store.sources.first {
            calendar.source = source
        }

        do {
            try store.saveCalendar(calendar, commit: true)
            return calendar
        } catch {
            throw EventKitManagerError.calendarNotFound
        }
    }
}
