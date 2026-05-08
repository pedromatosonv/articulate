import SwiftUI

struct PracticeDetailView: View {
    @EnvironmentObject private var store: PracticeStore
    @Environment(\.contentScale) private var contentScale
    @FocusState private var promptFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HeaderView()

            Divider()

            TranscriptView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            ComposerView(promptFocused: _promptFocused)
        }
        .navigationTitle(store.selectedMode.title)
        .font(.system(size: AppZoom.scaled(13, by: contentScale)))
    }
}

private struct HeaderView: View {
    @EnvironmentObject private var store: PracticeStore
    @Environment(\.contentScale) private var contentScale

    var body: some View {
        HStack(spacing: 12) {
            Label(store.connectionStatus.title, systemImage: statusImage)
                .font(.system(size: AppZoom.scaled(13, by: contentScale)))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .foregroundStyle(statusColor)

            Text(store.model)
                .font(.system(size: AppZoom.scaled(11, by: contentScale)))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .foregroundStyle(.secondary)
                .padding(.horizontal, AppZoom.scaled(8, by: contentScale))
                .padding(.vertical, AppZoom.scaled(4, by: contentScale))
                .background(.quaternary, in: Capsule())

            Spacer()
        }
        .padding(.horizontal, AppZoom.scaled(18, by: contentScale))
        .padding(.vertical, AppZoom.scaled(12, by: contentScale))
        .background(.bar)
    }

    private var statusImage: String {
        switch store.connectionStatus {
        case .idle:
            return "circle"
        case .connecting:
            return "clock"
        case .connected:
            return "checkmark.circle.fill"
        case .failed:
            return "exclamationmark.triangle.fill"
        }
    }

    private var statusColor: Color {
        switch store.connectionStatus {
        case .idle, .connecting:
            return .secondary
        case .connected:
            return .green
        case .failed:
            return .orange
        }
    }
}

private struct ComposerView: View {
    @EnvironmentObject private var store: PracticeStore
    @Environment(\.contentScale) private var contentScale
    @FocusState var promptFocused: Bool

    var body: some View {
        VStack(spacing: AppZoom.scaled(10, by: contentScale)) {
            if let lastError = store.lastError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                    Text(lastError)
                        .lineLimit(2)
                    Spacer()
                }
                .font(.system(size: AppZoom.scaled(11, by: contentScale)))
                .foregroundStyle(.orange)
            }

            HStack(spacing: AppZoom.scaled(12, by: contentScale)) {
                Button {
                    Task {
                        if store.isRecording {
                            await store.stopSpeaking()
                        } else {
                            await store.startSpeaking()
                        }
                    }
                } label: {
                    Label(store.isRecording ? "Stop" : "Speak", systemImage: store.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .labelStyle(.titleAndIcon)
                        .frame(width: AppZoom.scaled(96, by: contentScale))
                }
                .font(.system(size: AppZoom.scaled(13, by: contentScale)))
                .buttonStyle(.borderedProminent)
                .disabled(!store.connectionStatus.isConnected && store.connectionStatus == .connecting)

                TextField("Type a prompt", text: $store.typedPrompt, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: AppZoom.scaled(13, by: contentScale)))
                    .lineLimit(1...4)
                    .focused($promptFocused)
                    .onSubmit {
                        Task { await store.sendTypedPrompt() }
                    }

                Button {
                    Task { await store.sendTypedPrompt() }
                } label: {
                    Label("Send", systemImage: "paperplane.fill")
                }
                .font(.system(size: AppZoom.scaled(13, by: contentScale)))
                .keyboardShortcut(.return, modifiers: [.command])
                .disabled(store.typedPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(AppZoom.scaled(16, by: contentScale))
        .background(.bar)
    }
}
