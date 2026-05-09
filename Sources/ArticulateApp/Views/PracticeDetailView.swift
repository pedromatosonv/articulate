import SwiftUI

struct PracticeDetailView: View {
    @EnvironmentObject private var store: PracticeStore
    @Environment(\.contentScale) private var contentScale
    @FocusState private var promptFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HeaderView()

            Divider()

            if let lastError = store.lastError {
                ErrorBannerView(message: lastError)
            }

            TranscriptView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            ComposerView(promptFocused: _promptFocused)
        }
        .navigationTitle(store.currentSessionTitle)
        .font(.system(size: AppZoom.scaled(13, by: contentScale)))
    }
}

private struct HeaderView: View {
    @EnvironmentObject private var store: PracticeStore
    @Environment(\.contentScale) private var contentScale
    @State private var isRenaming = false
    @State private var draftTitle = ""
    @FocusState private var titleFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppZoom.scaled(10, by: contentScale)) {
            HStack(spacing: AppZoom.scaled(8, by: contentScale)) {
                if isRenaming {
                    TextField("Chat title", text: $draftTitle)
                        .textFieldStyle(.plain)
                        .font(.system(size: AppZoom.scaled(17, by: contentScale), weight: .semibold))
                        .focused($titleFocused)
                        .onSubmit { commitRename() }
                        .frame(maxWidth: AppZoom.scaled(420, by: contentScale))
                } else {
                    Text(store.currentSessionTitle)
                        .font(.system(size: AppZoom.scaled(17, by: contentScale), weight: .semibold))
                        .lineLimit(1)
                }

                Button {
                    beginRename()
                } label: {
                    Label("Rename", systemImage: "pencil")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.plain)
                .help("Rename Chat")

                Spacer()

                Button {
                    Task {
                        if store.connectionStatus.isConnected {
                            await store.disconnect()
                        } else {
                            await store.connect()
                        }
                    }
                } label: {
                    Label(store.connectionStatus.title, systemImage: statusImage)
                        .labelStyle(.titleAndIcon)
                        .padding(.horizontal, AppZoom.scaled(9, by: contentScale))
                        .padding(.vertical, AppZoom.scaled(5, by: contentScale))
                        .background(statusColor.opacity(0.12), in: Capsule())
                }
                .buttonStyle(.plain)
                .foregroundStyle(statusColor)

                SessionBadge(label: store.model, systemImage: "cpu", color: .secondary)

                Menu {
                    Button("Clear Chat") {
                        store.clearTranscript()
                    }
                    .disabled(store.transcript.isEmpty)

                    Button("Delete Chat", role: .destructive) {
                        store.deleteCurrentSession()
                    }
                } label: {
                    Label("Chat Actions", systemImage: "ellipsis.circle")
                        .labelStyle(.iconOnly)
                }
                .menuStyle(.borderlessButton)
            }

            HStack(spacing: AppZoom.scaled(10, by: contentScale)) {
                Picker("Mode", selection: $store.selectedMode) {
                    ForEach(PracticeMode.allCases) { mode in
                        Label(mode.title, systemImage: mode.systemImage)
                            .tag(mode)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: AppZoom.scaled(180, by: contentScale))

                Picker("Level", selection: $store.proficiency) {
                    ForEach(ProficiencyLevel.allCases) { level in
                        Text(level.title).tag(level)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: AppZoom.scaled(150, by: contentScale))

                Spacer()

                SessionBadge(
                    label: "\(store.selectedMode.title) / \(store.proficiency.title)",
                    systemImage: store.selectedMode.systemImage,
                    color: .secondary
                )
            }
        }
        .padding(.horizontal, AppZoom.scaled(18, by: contentScale))
        .padding(.vertical, AppZoom.scaled(12, by: contentScale))
        .background(.bar)
        .onChange(of: store.currentSessionTitle) { _, title in
            if !isRenaming {
                draftTitle = title
            }
        }
        .onAppear {
            draftTitle = store.currentSessionTitle
        }
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

    private func beginRename() {
        draftTitle = store.currentSessionTitle
        isRenaming = true
        titleFocused = true
    }

    private func commitRename() {
        store.renameCurrentSession(to: draftTitle)
        isRenaming = false
    }
}

private struct SessionBadge: View {
    @Environment(\.contentScale) private var contentScale

    let label: String
    let systemImage: String
    let color: Color

    var body: some View {
        Label(label, systemImage: systemImage)
            .labelStyle(.titleAndIcon)
            .font(.system(size: AppZoom.scaled(11, by: contentScale), weight: .medium))
            .lineLimit(1)
            .truncationMode(.middle)
            .foregroundStyle(color)
            .padding(.horizontal, AppZoom.scaled(8, by: contentScale))
            .padding(.vertical, AppZoom.scaled(4, by: contentScale))
            .background(color.opacity(0.10), in: Capsule())
    }
}

private struct ErrorBannerView: View {
    @EnvironmentObject private var store: PracticeStore
    @Environment(\.contentScale) private var contentScale

    let message: String

    var body: some View {
        HStack(spacing: AppZoom.scaled(8, by: contentScale)) {
            Image(systemName: "exclamationmark.triangle")
            Text(message)
                .lineLimit(2)
            Spacer()
            Button {
                store.clearLastError()
            } label: {
                Label("Dismiss", systemImage: "xmark")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.plain)
        }
        .font(.system(size: AppZoom.scaled(12, by: contentScale)))
        .foregroundStyle(.orange)
        .padding(.horizontal, AppZoom.scaled(18, by: contentScale))
        .padding(.vertical, AppZoom.scaled(8, by: contentScale))
        .background(Color.orange.opacity(0.12))
        .overlay(alignment: .bottom) {
            Divider()
        }
    }
}

private struct ComposerView: View {
    @EnvironmentObject private var store: PracticeStore
    @Environment(\.contentScale) private var contentScale
    @FocusState var promptFocused: Bool

    var body: some View {
        VStack(spacing: AppZoom.scaled(10, by: contentScale)) {
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
