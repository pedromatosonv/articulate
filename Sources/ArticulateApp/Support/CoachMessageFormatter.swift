import Foundation

struct CoachMessageSegment: Identifiable, Equatable {
    let id: Int
    let label: String?
    let text: String
}

enum CoachMessageFormatter {
    private static let labels = [
        "Try this:",
        "Why:",
        "Question:"
    ]

    static func segments(from text: String) -> [CoachMessageSegment] {
        let trimmedText = trimmed(text)
        guard !trimmedText.isEmpty else {
            return []
        }

        let markers = labels.flatMap { label in
            ranges(of: label, in: trimmedText).map { range in
                (label: canonicalLabel(for: label), range: range)
            }
        }
        .sorted { first, second in
            first.range.lowerBound < second.range.lowerBound
        }

        guard !markers.isEmpty else {
            return [CoachMessageSegment(id: 0, label: nil, text: trimmedText)]
        }

        var segments: [CoachMessageSegment] = []
        var nextID = 0

        let leadingText = trimmed(String(trimmedText[..<markers[0].range.lowerBound]))
        if !leadingText.isEmpty {
            segments.append(CoachMessageSegment(id: nextID, label: nil, text: leadingText))
            nextID += 1
        }

        for index in markers.indices {
            let marker = markers[index]
            let contentStart = marker.range.upperBound
            let contentEnd = index + 1 < markers.count ? markers[index + 1].range.lowerBound : trimmedText.endIndex
            let content = trimmed(String(trimmedText[contentStart..<contentEnd]))

            if !content.isEmpty {
                segments.append(CoachMessageSegment(id: nextID, label: marker.label, text: content))
                nextID += 1
            }
        }

        return segments.isEmpty ? [CoachMessageSegment(id: 0, label: nil, text: trimmedText)] : segments
    }

    private static func ranges(of label: String, in text: String) -> [Range<String.Index>] {
        var ranges: [Range<String.Index>] = []
        var searchStart = text.startIndex

        while searchStart < text.endIndex,
              let range = text.range(of: label, options: [.caseInsensitive], range: searchStart..<text.endIndex) {
            ranges.append(range)
            searchStart = range.upperBound
        }

        return ranges
    }

    private static func canonicalLabel(for label: String) -> String {
        switch label.lowercased() {
        case "try this:":
            return "Try this"
        case "why:":
            return "Why"
        case "question:":
            return "Question"
        default:
            return label.trimmingCharacters(in: CharacterSet(charactersIn: ":"))
        }
    }

    private static func trimmed(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
