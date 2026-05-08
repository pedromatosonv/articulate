import SwiftUI

struct TranscriptView: View {
    @EnvironmentObject private var store: PracticeStore
    @Environment(\.contentScale) private var contentScale

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: AppZoom.scaled(12, by: contentScale)) {
                    if store.transcript.isEmpty {
                        EmptyTranscriptView()
                            .frame(maxWidth: .infinity, minHeight: AppZoom.scaled(360, by: contentScale))
                    } else {
                        ForEach(store.transcript) { item in
                            TranscriptRow(item: item)
                                .id(item.id)
                        }
                    }
                }
                .padding(AppZoom.scaled(18, by: contentScale))
            }
            .onChange(of: store.transcript) { _, items in
                if let last = items.last {
                    withAnimation(.easeOut(duration: 0.18)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
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
            if item.role == .coach || item.role == .system {
                rowBody
                Spacer(minLength: 80)
            } else {
                Spacer(minLength: 80)
                rowBody
            }
        }
    }

    private var rowBody: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
                if item.isStreaming {
                    ProgressView()
                        .controlSize(.small)
                        .scaleEffect(AppZoom.scaled(0.7, by: contentScale))
                }
            }
            .font(.system(size: AppZoom.scaled(11, by: contentScale)))
            .foregroundStyle(.secondary)

            Text(item.text)
                .font(.system(size: AppZoom.scaled(14, by: contentScale)))
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppZoom.scaled(12, by: contentScale))
        .frame(maxWidth: min(AppZoom.scaled(560, by: contentScale), 760), alignment: .leading)
        .background(background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(.quaternary)
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

    private var background: Color {
        switch item.role {
        case .learner:
            return Color.accentColor.opacity(0.14)
        case .coach:
            return Color(nsColor: .controlBackgroundColor)
        case .system:
            return Color.orange.opacity(0.12)
        }
    }
}
