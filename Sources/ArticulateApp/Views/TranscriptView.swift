import SwiftUI

struct TranscriptView: View {
    @EnvironmentObject private var store: PracticeStore
    @Environment(\.contentScale) private var contentScale

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: AppZoom.scaled(12, by: contentScale)) {
                    if displayedTranscript.isEmpty {
                        EmptyTranscriptView()
                            .frame(maxWidth: .infinity, minHeight: AppZoom.scaled(360, by: contentScale))
                    } else {
                        ForEach(displayedTranscript) { item in
                            TranscriptRow(item: item)
                                .id(item.id)
                        }
                    }
                }
                .padding(.horizontal, AppZoom.scaled(18, by: contentScale))
                .padding(.vertical, AppZoom.scaled(20, by: contentScale))
                .frame(maxWidth: AppZoom.scaled(940, by: contentScale), alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .onChange(of: store.transcript) { _, items in
                if let last = items.last(where: { $0.role != .system }) {
                    withAnimation(.easeOut(duration: 0.18)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var displayedTranscript: [TranscriptItem] {
        store.transcript.filter { $0.role != .system }
    }
}

private struct EmptyTranscriptView: View {
    @Environment(\.contentScale) private var contentScale

    var body: some View {
        VStack(spacing: AppZoom.scaled(14, by: contentScale)) {
            Image(systemName: "bubble.left.and.text.bubble.right")
                .font(.system(size: AppZoom.scaled(44, by: contentScale)))
                .foregroundStyle(.secondary)
            Text("Ready")
                .font(.system(size: AppZoom.scaled(20, by: contentScale), weight: .semibold))
            Text("Connect, speak, or type a prompt.")
                .font(.system(size: AppZoom.scaled(13, by: contentScale)))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct TranscriptRow: View {
    @Environment(\.contentScale) private var contentScale
    let item: TranscriptItem

    var body: some View {
        HStack(alignment: .top) {
            if item.role == .coach {
                rowBody
                Spacer(minLength: AppZoom.scaled(96, by: contentScale))
            } else {
                Spacer(minLength: AppZoom.scaled(96, by: contentScale))
                rowBody
            }
        }
    }

    private var rowBody: some View {
        HStack(alignment: .top, spacing: AppZoom.scaled(9, by: contentScale)) {
            if item.role == .coach {
                RoleAvatar(icon: icon, color: .green)
            }

            VStack(alignment: .leading, spacing: AppZoom.scaled(8, by: contentScale)) {
                HStack(spacing: AppZoom.scaled(6, by: contentScale)) {
                    Text(title)
                        .font(.system(size: AppZoom.scaled(11, by: contentScale), weight: .semibold))
                    if item.isStreaming {
                        ProgressView()
                            .controlSize(.small)
                            .scaleEffect(AppZoom.scaled(0.7, by: contentScale))
                    }
                }
                .foregroundStyle(.secondary)

                if item.role == .coach {
                    CoachMessageContent(text: item.text)
                } else {
                    Text(item.text)
                        .font(.system(size: AppZoom.scaled(14, by: contentScale)))
                        .lineSpacing(AppZoom.scaled(2, by: contentScale))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .textSelection(.enabled)
            .padding(.horizontal, AppZoom.scaled(14, by: contentScale))
            .padding(.vertical, AppZoom.scaled(12, by: contentScale))
            .frame(maxWidth: maxWidth, alignment: .leading)
            .background(background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(alignment: .leading) {
                if item.role == .coach {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(Color.green.opacity(0.65))
                        .frame(width: AppZoom.scaled(3, by: contentScale))
                        .padding(.vertical, AppZoom.scaled(10, by: contentScale))
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(borderColor)
            }

            if item.role == .learner {
                RoleAvatar(icon: icon, color: .accentColor)
            }
        }
    }

    private var title: String {
        switch item.role {
        case .learner:
            return "You"
        case .coach:
            return "Coach"
        case .system:
            return "System"
        }
    }

    private var icon: String {
        switch item.role {
        case .learner:
            return "person.fill"
        case .coach:
            return "sparkles"
        case .system:
            return "info.circle"
        }
    }

    private var maxWidth: CGFloat {
        switch item.role {
        case .learner:
            return AppZoom.scaled(500, by: contentScale)
        case .coach:
            return AppZoom.scaled(640, by: contentScale)
        case .system:
            return AppZoom.scaled(560, by: contentScale)
        }
    }

    private var background: Color {
        switch item.role {
        case .learner:
            return Color.accentColor.opacity(0.16)
        case .coach:
            return Color(nsColor: .controlBackgroundColor).opacity(0.86)
        case .system:
            return Color.orange.opacity(0.12)
        }
    }

    private var borderColor: Color {
        switch item.role {
        case .learner:
            return Color.accentColor.opacity(0.28)
        case .coach:
            return Color.green.opacity(0.24)
        case .system:
            return Color.orange.opacity(0.22)
        }
    }
}

private struct RoleAvatar: View {
    @Environment(\.contentScale) private var contentScale

    let icon: String
    let color: Color

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: AppZoom.scaled(11, by: contentScale), weight: .semibold))
            .foregroundStyle(color)
            .frame(width: AppZoom.scaled(24, by: contentScale), height: AppZoom.scaled(24, by: contentScale))
            .background(color.opacity(0.13), in: Circle())
            .overlay {
                Circle()
                    .strokeBorder(color.opacity(0.22))
            }
            .accessibilityHidden(true)
    }
}

private struct CoachMessageContent: View {
    @Environment(\.contentScale) private var contentScale

    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppZoom.scaled(8, by: contentScale)) {
            ForEach(CoachMessageFormatter.segments(from: text)) { segment in
                if let label = segment.label {
                    CoachMessageSection(label: label, text: segment.text)
                } else {
                    Text(segment.text)
                        .font(.system(size: AppZoom.scaled(14, by: contentScale)))
                        .lineSpacing(AppZoom.scaled(2, by: contentScale))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

private struct CoachMessageSection: View {
    @Environment(\.contentScale) private var contentScale

    let label: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppZoom.scaled(4, by: contentScale)) {
            Text(label)
                .font(.system(size: AppZoom.scaled(10, by: contentScale), weight: .semibold))
                .foregroundStyle(labelColor)

            Text(text)
                .font(.system(size: AppZoom.scaled(14, by: contentScale)))
                .lineSpacing(AppZoom.scaled(2, by: contentScale))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, sectionPadding.horizontal)
        .padding(.vertical, sectionPadding.vertical)
        .background(sectionBackground, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
    }

    private var labelColor: Color {
        switch label {
        case "Try this":
            return .green
        case "Why":
            return .secondary
        case "Question":
            return .accentColor
        default:
            return .secondary
        }
    }

    private var sectionBackground: Color {
        switch label {
        case "Try this":
            return Color.green.opacity(0.10)
        case "Question":
            return Color.accentColor.opacity(0.09)
        default:
            return Color.clear
        }
    }

    private var sectionPadding: (horizontal: CGFloat, vertical: CGFloat) {
        switch label {
        case "Try this", "Question":
            return (AppZoom.scaled(9, by: contentScale), AppZoom.scaled(7, by: contentScale))
        default:
            return (0, 0)
        }
    }
}
