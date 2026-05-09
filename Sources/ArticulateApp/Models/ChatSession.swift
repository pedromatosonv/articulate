import Foundation

struct ChatSession: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var mode: PracticeMode
    var proficiency: ProficiencyLevel
    var messages: [TranscriptItem]
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String = "New Chat",
        mode: PracticeMode,
        proficiency: ProficiencyLevel,
        messages: [TranscriptItem] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.mode = mode
        self.proficiency = proficiency
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var hasMessages: Bool {
        !messages.isEmpty
    }
}
