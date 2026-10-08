import Foundation
import SwiftUI

public struct AlertItem: Identifiable {
    public let id = UUID()
    public let title: String
    public let message: String
}

@MainActor
public final class SyncViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var isLoading = false
    @Published var isAuthenticated = false
    @Published var loginErrorMessage: String?
    @Published var syncStatusText = "Non ancora sincronizzato"
    @Published var lastSyncDate: Date?
    @Published var alertItem: AlertItem?

    private let client = SpaggiariClient()
    private let scheduler = BackgroundScheduler()
    private let notificationManager = NotificationManager()
    private let eventKitManager = EventKitManager()
    private let remindersManager = RemindersManager()

    public init() {
        // Nothing else.
    }

    public func onAppear() async {
        do {
            if let credentials = try KeychainManager.read() {
                username = credentials.username
                password = credentials.password
                isAuthenticated = true
                scheduler.register()
                scheduler.scheduleDailySync(at: 15, minute: 0)
            }
        } catch {
            print("Keychain unavailable: \(error.localizedDescription)")
        }
    }

    public func login() async {
        isLoading = true
        loginErrorMessage = nil

        do {
            _ = try await client.login(username: username, password: password)
            try KeychainManager.save(username: username, password: password)
            isAuthenticated = true
            syncStatusText = "Accesso completato"
            scheduler.register()
            scheduler.scheduleDailySync(at: 15, minute: 0)
            alertItem = AlertItem(title: "Accesso riuscito", message: "Credenziali salvate in modo sicuro.")
        } catch {
            loginErrorMessage = error.localizedDescription
            alertItem = AlertItem(title: "Errore di accesso", message: error.localizedDescription)
        }

        isLoading = false
    }

    public func logout() async {
        do {
            try KeychainManager.delete()
            username = ""
            password = ""
            isAuthenticated = false
            syncStatusText = "Logout eseguito"
        } catch {
            alertItem = AlertItem(title: "Errore", message: error.localizedDescription)
        }
    }

    public func syncNow() async {
        guard isAuthenticated else { return }

        isLoading = true

        do {
            try await notificationManager.requestAuthorization()
            let token = try await client.login(username: username, password: password)
            let fromDate = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
            let toDate = Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date()
            let tasks = try await client.fetchAssignments(token: token, from: fromDate, to: toDate)

            try await eventKitManager.upsertTasks(tasks)
            try await remindersManager.upsertTasks(tasks)

            lastSyncDate = Date()
            syncStatusText = "Compiti sincronizzati"
            notificationManager.scheduleSyncCompleteNotification()
            alertItem = AlertItem(title: "Sincronizzazione completata", message: "I compiti sono stati aggiunti sul calendario e sui promemoria per Classe Viva.")
        } catch {
            syncStatusText = "Sincronizzazione fallita"
            alertItem = AlertItem(title: "Errore", message: error.localizedDescription)
        }

        isLoading = false
    }
}
