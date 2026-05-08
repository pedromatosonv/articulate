import Foundation

@MainActor
final class PracticeStore: ObservableObject {
    let model = "gpt-realtime-2"

    @Published var selectedMode: PracticeMode = .conversation {
        didSet { Task { await refreshSession() } }
    }
    @Published var proficiency: ProficiencyLevel = .intermediate {
        didSet { Task { await refreshSession() } }
    }
    @Published var connectionStatus: ConnectionStatus = .idle
    @Published var isRecording = false
    @Published var transcript: [TranscriptItem] = []
    @Published var typedPrompt = ""
    @Published var speed = 1.0 {
        didSet { Task { await refreshSession() } }
    }
    @Published var lastError: String?

    private let audioEngine = RealtimeAudioEngine()
    private var client: RealtimeClient?
    private var currentCoachItemID: UUID?
    private var receivedAudioForCurrentTurn = false

    var canStartSpeaking: Bool {
        connectionStatus.isConnected && !isRecording
    }

    func connect() async {
        if connectionStatus.isConnected {
            return
        }

        connectionStatus = .connecting
        lastError = nil

        do {
            let apiKey = try EnvLoader.openAIAPIKey()
            let realtimeClient = RealtimeClient(
                apiKey: apiKey,
                model: model,
                safetyIdentifier: "articulate-local"
            )

            realtimeClient.onEvent = { [weak self] event in
                Task { @MainActor in
                    self?.handle(event)
                }
            }

            client = realtimeClient
            try await realtimeClient.connect(config: sessionConfig())
            connectionStatus = .connected
            appendSystemMessage("Connected to \(model).")
        } catch {
            connectionStatus = .failed(error.localizedDescription)
            lastError = error.localizedDescription
            appendSystemMessage(error.localizedDescription)
        }
    }

    func disconnect() async {
        audioEngine.stopCapture()
        audioEngine.stopPlayback()
        isRecording = false
        client?.disconnect()
        client = nil
        connectionStatus = .idle
        appendSystemMessage("Disconnected.")
    }

    func startSpeaking() async {
        if !connectionStatus.isConnected {
            await connect()
        }

        guard let client, connectionStatus.isConnected else {
            return
        }

        do {
            receivedAudioForCurrentTurn = false
            currentCoachItemID = nil
            try? await client.cancelResponse()
            try await client.clearInputAudio()
            try await audioEngine.startCapture { chunk in
                Task {
                    try? await client.appendAudio(chunk)
                }
            }
            isRecording = true
        } catch {
            isRecording = false
            lastError = error.localizedDescription
            appendSystemMessage(error.localizedDescription)
        }
    }

    func stopSpeaking() async {
        guard isRecording, let client else {
            return
        }

        audioEngine.stopCapture()
        isRecording = false

        do {
            try await client.commitInputAudioAndRespond()
        } catch {
            lastError = error.localizedDescription
            appendSystemMessage(error.localizedDescription)
        }
    }

    func sendTypedPrompt() async {
        let text = typedPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            return
        }

        typedPrompt = ""

        if !connectionStatus.isConnected {
            await connect()
        }

        guard let client, connectionStatus.isConnected else {
            typedPrompt = text
            return
        }

        appendLearnerMessage(text)
        currentCoachItemID = nil
        receivedAudioForCurrentTurn = false

        do {
            try await client.sendText(text)
        } catch {
            lastError = error.localizedDescription
            appendSystemMessage(error.localizedDescription)
        }
    }

    func clearTranscript() {
        transcript.removeAll()
        currentCoachItemID = nil
    }

    private func refreshSession() async {
        guard let client, connectionStatus.isConnected else {
            return
        }

        do {
            try await client.updateSession(sessionConfig())
        } catch {
            lastError = error.localizedDescription
            appendSystemMessage(error.localizedDescription)
        }
    }

    private func sessionConfig() -> RealtimeSessionConfig {
        RealtimeSessionConfig(
            instructions: instructions(),
            voice: "marin",
            speed: speed
        )
    }

    private func instructions() -> String {
        """
        You are an English practice coach in a native macOS app.
        Speak only in English unless the learner explicitly asks for Portuguese.
        Keep spoken answers concise: one correction, one short explanation, and one follow-up question.
        Do not overpraise. Be direct, warm, and practical.
        \(selectedMode.coachingDirective)
        Learner level: \(proficiency.title). \(proficiency.directive)
        If the learner makes a grammar, pronunciation, or vocabulary mistake, briefly say "Try this:" and give a better version before continuing.
        """
    }

    private func handle(_ event: RealtimeServerEvent) {
        switch event {
        case .connected:
            connectionStatus = .connected
        case .sessionUpdated:
            break
        case .learnerTranscript(let text):
            appendLearnerMessage(text)
        case .coachTextDelta(let delta):
            appendCoachDelta(delta)
        case .coachAudioDelta(let data):
            receivedAudioForCurrentTurn = true
            audioEngine.enqueuePlayback(data)
        case .responseDone:
            finishCoachMessage()
        case .notice(let message):
            appendSystemMessage(message)
        case .error(let message):
            lastError = message
            appendSystemMessage(message)
        }
    }

    private func appendLearnerMessage(_ text: String) {
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return }
        transcript.append(TranscriptItem(role: .learner, text: normalized))
    }

    private func appendCoachDelta(_ delta: String) {
        if let id = currentCoachItemID,
           let index = transcript.firstIndex(where: { $0.id == id }) {
            transcript[index].text += delta
            transcript[index].isStreaming = true
            return
        }

        let item = TranscriptItem(role: .coach, text: delta, isStreaming: true)
        currentCoachItemID = item.id
        transcript.append(item)
    }

    private func finishCoachMessage() {
        if let id = currentCoachItemID,
           let index = transcript.firstIndex(where: { $0.id == id }) {
            transcript[index].isStreaming = false
        } else if receivedAudioForCurrentTurn {
            transcript.append(TranscriptItem(role: .coach, text: "Audio response completed."))
        }
        currentCoachItemID = nil
        receivedAudioForCurrentTurn = false
    }

    private func appendSystemMessage(_ text: String) {
        transcript.append(TranscriptItem(role: .system, text: text))
    }
}
