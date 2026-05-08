import SwiftUI

struct TranscriptView: View {
    @EnvironmentObject private var store: PracticeStore

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if store.transcript.isEmpty {
                        EmptyTranscriptView()
                            .frame(maxWidth: .infinity, minHeight: 360)
                    } else {
                        ForEach(store.transcript) { item in
                            TranscriptRow(item: item)
                                .id(item.id)
                        }
                    }
                }
                .padding(18)
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
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "bubble.left.and.text.bubble.right")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text("Ready")
                .font(.title2)
            Text("Connect, speak, or type a prompt.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct TranscriptRow: View {
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
                        .scaleEffect(0.7)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Text(item.text)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: 560, alignment: .leading)
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
