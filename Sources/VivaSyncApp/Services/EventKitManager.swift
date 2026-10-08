import Foundation

public enum SpaggiariClientError: LocalizedError {
    case invalidURL
    case invalidCredentials
    case invalidResponse
    case requestFailed(String)
    case decodingFailed
    case unauthorized

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL Spaggiari non valida."
        case .invalidCredentials:
            return "Credenziali non valide."
        case .invalidResponse:
            return "Risposta non valida." 
        case .requestFailed(let message):
            return message
        case .decodingFailed:
            return "Impossibile decodificare i dati di Spaggiari."
        case .unauthorized:
            return "Autorizzazione non valida."
        }
    }
}

public final class SpaggiariClient {
    public static let apiBase = "https://web.spaggiari.eu/rest/v1"
    public static let apiKey = "Tg1NWEwNGIgIC0K"
    public static let appCode = "SD"
    public static let userAgent = "CVVS/std/4.2.3"

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func login(username: String, password: String) async throws -> String {
        guard let url = URL(string: "\(Self.apiBase)/login") else {
            throw SpaggiariClientError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue(Self.apiKey, forHTTPHeaderField: "x-api-key")

        let payload: [String: String] = [
            "ident": username,
            "pass": password,
            "appCode": Self.appCode
        ]

        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SpaggiariClientError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw SpaggiariClientError.invalidCredentials
            }
            let body = String(data: data, encoding: .utf8) ?? ""
            throw SpaggiariClientError.requestFailed("Login fallito: \(body)")
        }

        do {
            let auth = try JSONDecoder().decode(SpaggiariAuthResponse.self, from: data)
            return auth.token
        } catch {
            throw SpaggiariClientError.decodingFailed
        }
    }

    public func fetchAssignments(token: String, from: Date, to: Date) async throws -> [ClasseVivaTask] {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard var components = URLComponents(string: "\(Self.apiBase)/students/\(Self.appCode)/agenda") else {
            throw SpaggiariClientError.invalidURL
        }

        components.queryItems = [
            URLQueryItem(name: "from", value: formatter.string(from: from)),
            URLQueryItem(name: "to", value: formatter.string(from: to))
        ]

        guard let url = components.url else {
            throw SpaggiariClientError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue(Self.apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SpaggiariClientError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw SpaggiariClientError.unauthorized
            }
            let body = String(data: data, encoding: .utf8) ?? ""
            throw SpaggiariClientError.requestFailed("Recupero agenda fallito: \(body)")
        }

        do {
            let items = try JSONDecoder().decode([SpaggiariAgendaItem].self, from: data)
            return items.filter { $0.eventType == "homework" }.map { $0.toTask() }
        } catch {
            throw SpaggiariClientError.decodingFailed
        }
    }
}

public struct SpaggiariAuthResponse: Decodable {
    public let token: String
    public let id: String?
}

public struct SpaggiariAgendaItem: Decodable {
    public let id: String
    public let eventType: String?
    public let subject: String?
    public let subjectId: String?
    public let description: String?
    public let notes: String?
    public let start: String?
    public let due: String?
    public let dueTime: String?

    public func toTask() -> ClasseVivaTask {
        let dateString = due ?? start ?? Date().ISO8601Format()
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let dueDate = dateFormatter.date(from: dateString) ?? Date()

        let dueTimeDate: Date? = {
            guard let dueTime else { return nil }
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            return timeFormatter.date(from: dueTime)
        }()

        let title = description ?? notes ?? "Compito"
        let subjectText = subject ?? subjectId ?? "Materia"

        return ClasseVivaTask(
            id: id,
            subject: subjectText,
            title: title,
            description: notes ?? "",
            dueDate: dueDate,
            dueTime: dueTimeDate
        )
    }
}
