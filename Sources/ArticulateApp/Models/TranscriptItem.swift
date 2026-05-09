import Foundation

enum TranscriptRole: String, Codable {
    case learner
    case coach
    case system
}

struct TranscriptItem: Identifiable, Codable, Equatable {
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

    enum CodingKeys: String, CodingKey {
        case id
        case role
        case text
        case isStreaming
        case createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        role = try container.decode(TranscriptRole.self, forKey: .role)
        text = try container.decode(String.self, forKey: .text)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        isStreaming = false
    }
}
