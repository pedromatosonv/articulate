import Foundation

enum TranscriptRole: String {
    case learner
    case coach
    case system
}

struct TranscriptItem: Identifiable, Equatable {
    let id: UUID
    var role: TranscriptRole
    var text: String
    var isStreaming: Bool
    let createdAt: Date

    init(id: UUID = UUID(), role: TranscriptRole, text: String, isStreaming: Bool = false, createdAt: Date = Date()) {
        self.id = id
        self.role = role
        self.text = text
        self.isStreaming = isStreaming
        self.createdAt = createdAt
    }
}

