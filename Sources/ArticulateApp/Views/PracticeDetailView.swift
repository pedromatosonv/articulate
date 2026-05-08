import SwiftUI

struct PracticeDetailView: View {
    @EnvironmentObject private var store: PracticeStore
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
    }
}

private struct HeaderView: View {
    @EnvironmentObject private var store: PracticeStore

    var body: some View {
        HStack(spacing: 12) {
            Label(store.connectionStatus.title, systemImage: statusImage)
                .foregroundStyle(statusColor)

            Text(store.model)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.quaternary, in: Capsule())

            Spacer()

            HStack(spacing: 8) {
                Text("Speed")
                    .foregroundStyle(.secondary)
                Slider(value: $store.speed, in: 0.75...1.25, step: 0.05)
                    .frame(width: 150)
                Text(store.speed.formatted(.number.precision(.fractionLength(2))))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(width: 38, alignment: .trailing)
            }
            .font(.caption)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
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
    @FocusState var promptFocused: Bool

    var body: some View {
        VStack(spacing: 10) {
            if let lastError = store.lastError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                    Text(lastError)
                        .lineLimit(2)
                    Spacer()
                }
                .font(.caption)
                .foregroundStyle(.orange)
            }

            HStack(spacing: 12) {
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
                        .frame(width: 96)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!store.connectionStatus.isConnected && store.connectionStatus == .connecting)

                TextField("Type a prompt", text: $store.typedPrompt, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
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
                .keyboardShortcut(.return, modifiers: [.command])
                .disabled(store.typedPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(16)
        .background(.bar)
    }
}

