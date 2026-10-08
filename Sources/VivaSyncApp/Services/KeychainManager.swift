import Foundation

public struct ClasseVivaTask: Identifiable, Equatable, Codable {
    public let id: String
    public let subject: String
    public let title: String
    public let description: String
    public let dueDate: Date
    public let dueTime: Date?

    public init(
        id: String,
        subject: String,
        title: String,
        description: String,
        dueDate: Date,
        dueTime: Date? = nil
    ) {
        self.id = id
        self.subject = subject
        self.title = title
        self.description = description
        self.dueDate = dueDate
        self.dueTime = dueTime
    }
}
