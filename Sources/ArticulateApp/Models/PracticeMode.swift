import Foundation

enum PracticeMode: String, CaseIterable, Identifiable, Codable {
    case conversation
    case interview
    case pronunciation
    case smallTalk

    var id: String { rawValue }

    var title: String {
        switch self {
        case .conversation:
            return "Conversation"
        case .interview:
            return "Interview"
        case .pronunciation:
            return "Pronunciation"
        case .smallTalk:
            return "Small Talk"
        }
    }

    var systemImage: String {
        switch self {
        case .conversation:
            return "bubble.left.and.bubble.right"
        case .interview:
            return "person.2.wave.2"
        case .pronunciation:
            return "waveform"
        case .smallTalk:
            return "cup.and.saucer"
        }
    }

    var coachingDirective: String {
        switch self {
        case .conversation:
            return "Run an open-ended English conversation. Ask one natural follow-up question after each answer."
        case .interview:
            return "Run a realistic job interview. Ask one interview question at a time, then give concise feedback on structure and clarity."
        case .pronunciation:
            return "Focus on pronunciation, rhythm, and stress. Ask the learner to repeat short phrases and explain corrections simply."
        case .smallTalk:
            return "Practice casual small talk for work and social situations. Keep it relaxed and idiomatic."
        }
    }
}

enum ProficiencyLevel: String, CaseIterable, Identifiable, Codable {
    case beginner
    case intermediate
    case advanced

    var id: String { rawValue }

    var title: String {
        switch self {
        case .beginner:
            return "Beginner"
        case .intermediate:
            return "Intermediate"
        case .advanced:
            return "Advanced"
        }
    }

    var directive: String {
        switch self {
        case .beginner:
            return "Use short sentences, slower speech, and frequent examples."
        case .intermediate:
            return "Use natural everyday English and correct recurring grammar or word-choice issues."
        case .advanced:
            return "Use native-level phrasing and challenge the learner to be more precise and concise."
        }
    }
}
