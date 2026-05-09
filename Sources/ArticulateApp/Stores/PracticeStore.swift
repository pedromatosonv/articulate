import Foundation

@MainActor
final class PracticeStore: ObservableObject {
    let model = "gpt-realtime-2"

    @Published var selectedMode: PracticeMode = .conversation {
        didSet {
            guard !isApplyingSelectedSession else { return }
            updateCurrentSessionSettings()
            Task { await refreshSession() }
        }
    }
    @Published var proficiency: ProficiencyLevel = .intermediate {
        didSet {
            guard !isApplyingSelectedSession else { return }
            updateCurrentSessionSettings()
            Task { await refreshSession() }
        }
    }
    @Published var selectedSessionID: ChatSession.ID? {
        didSet { applySelectedSession() }
    }
    @Published var connectionStatus: ConnectionStatus = .idle
    @Published var isRecording = false
    @Published var sessions: [ChatSession] = []
    @Published var transcript: [TranscriptItem] = []
    @Published var typedPrompt = ""
    @Published var searchText = ""
    @Published private(set) var contentScale: Double
    @Published var lastError: String?

    private let userDefaults: UserDefaults
    private let chatRepository: ChatSessionRepository
    private lazy var audioEngine = RealtimeAudioEngine()
    private var client: RealtimeClient?
    private var currentCoachItemID: UUID?
    private var receivedAudioForCurrentTurn = false
    private var isApplyingSelectedSession = false

    init(userDefaults: UserDefaults = .standard, chatRepository: ChatSessionRepository = ChatSessionRepository()) {
        self.userDefaults = userDefaults
        self.chatRepository = chatRepository

        let storedScale = userDefaults.object(forKey: AppZoom.storageKey) as? Double ?? AppZoom.defaultScale
        contentScale = AppZoom.rounded(AppZoom.clamped(storedScale))

        do {
            sessions = try chatRepository.load().sorted { $0.updatedAt > $1.updatedAt }
        } catch {
            lastError = "Could not load chat history: \(error.localizedDescription)"
            sessions = []
        }

        if sessions.isEmpty {
            createNewSession(saveImmediately: false)
        } else {
            selectedSessionID = sessions.first?.id
            applySelectedSession()
        }
    }

    var canStartSpeaking: Bool {
        connectionStatus.isConnected && !isRecording
    }

    var currentSession: ChatSession? {
        guard let selectedSessionID else { return nil }
        return sessions.first { $0.id == selectedSessionID }
    }

    var currentSessionTitle: String {
        currentSession?.title ?? "New Chat"
    }

    var filteredSessions: [ChatSession] {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let baseSessions = sessions.sorted { $0.updatedAt > $1.updatedAt }

        guard !trimmedSearch.isEmpty else {
            return baseSessions
        }

        return baseSessions.filter { session in
            session.title.localizedCaseInsensitiveContains(trimmedSearch)
                || session.mode.title.localizedCaseInsensitiveContains(trimmedSearch)
                || session.messages.contains { $0.text.localizedCaseInsensitiveContains(trimmedSearch) }
        }
    }

    var canZoomOut: Bool {
        contentScale > AppZoom.minimumScale
    }

    var canZoomIn: Bool {
        contentScale < AppZoom.maximumScale
    }

    var contentScaleLabel: String {
        AppZoom.percentLabel(for: contentScale)
    }

    func zoomIn() {
        setContentScale(AppZoom.adjusted(contentScale, by: 1))
    }

    func zoomOut() {
        setContentScale(AppZoom.adjusted(contentScale, by: -1))
    }

    func resetZoom() {
        setContentScale(AppZoom.defaultScale)
    }

    func setContentScale(_ value: Double) {
        let nextScale = AppZoom.rounded(AppZoom.clamped(value))
        guard nextScale != contentScale else {
            return
        }

        contentScale = nextScale
        userDefaults.set(nextScale, forKey: AppZoom.storageKey)
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
        } catch {
            connectionStatus = .failed(error.localizedDescription)
            lastError = error.localizedDescription
        }
    }

    func disconnect() async {
        audioEngine.stopCapture()
        audioEngine.stopPlayback()
        isRecording = false
        client?.disconnect()
        client = nil
        connectionStatus = .idle
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
        }
    }

    func clearTranscript() {
        transcript.removeAll()
        currentCoachItemID = nil
        syncTranscriptToCurrentSession()
    }

    func clearLastError() {
        lastError = nil
    }

    func createNewSession() {
        createNewSession(saveImmediately: true)
    }

    func selectSession(_ id: ChatSession.ID) {
        selectedSessionID = id
    }

    func renameCurrentSession(to title: String) {
        let normalized = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty, let index = currentSessionIndex else {
            return
        }

        sessions[index].title = String(normalized.prefix(60))
        sessions[index].updatedAt = Date()
        sortSessionsKeepingSelection()
        saveSessions()
    }

    func deleteCurrentSession() {
        guard let selectedSessionID else { return }
        sessions.removeAll { $0.id == selectedSessionID }

        if sessions.isEmpty {
            createNewSession(saveImmediately: true)
        } else {
            self.selectedSessionID = sessions.sorted { $0.updatedAt > $1.updatedAt }.first?.id
            saveSessions()
        }
    }

    private func refreshSession() async {
        guard let client, connectionStatus.isConnected else {
            return
        }

        do {
            try await client.updateSession(sessionConfig())
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func sessionConfig() -> RealtimeSessionConfig {
        RealtimeSessionConfig(
            instructions: instructions(),
            voice: "marin"
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
            lastError = message
        case .error(let message):
            lastError = message
        }
    }

    private func appendLearnerMessage(_ text: String) {
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return }
        ensureSelectedSession()
        transcript.append(TranscriptItem(role: .learner, text: normalized))
        syncTranscriptToCurrentSession(shouldRetitle: true)
    }

    private func appendCoachDelta(_ delta: String) {
        ensureSelectedSession()
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
        syncTranscriptToCurrentSession()
    }

    private var currentSessionIndex: Int? {
        guard let selectedSessionID else { return nil }
        return sessions.firstIndex { $0.id == selectedSessionID }
    }

    private func createNewSession(saveImmediately: Bool) {
        let now = Date()
        let session = ChatSession(
            mode: selectedMode,
            proficiency: proficiency,
            createdAt: now,
            updatedAt: now
        )

        sessions.insert(session, at: 0)
        selectedSessionID = session.id
        transcript = []
        currentCoachItemID = nil
        receivedAudioForCurrentTurn = false
        lastError = nil

        if saveImmediately {
            saveSessions()
        }
    }

    private func applySelectedSession() {
        guard !isApplyingSelectedSession,
              let selectedSessionID,
              let session = sessions.first(where: { $0.id == selectedSessionID }) else {
            return
        }

        isApplyingSelectedSession = true
        selectedMode = session.mode
        proficiency = session.proficiency
        transcript = session.messages
        currentCoachItemID = nil
        receivedAudioForCurrentTurn = false
        lastError = nil
        isApplyingSelectedSession = false

        Task { await refreshSession() }
    }

    private func ensureSelectedSession() {
        if selectedSessionID == nil || currentSessionIndex == nil {
            createNewSession(saveImmediately: false)
        }
    }

    private func updateCurrentSessionSettings() {
        ensureSelectedSession()
        guard let index = currentSessionIndex else { return }

        sessions[index].mode = selectedMode
        sessions[index].proficiency = proficiency
        sessions[index].updatedAt = Date()
        sortSessionsKeepingSelection()
        saveSessions()
    }

    private func syncTranscriptToCurrentSession(shouldRetitle: Bool = false) {
        ensureSelectedSession()
        guard let index = currentSessionIndex else { return }

        sessions[index].messages = transcript.map { item in
            var savedItem = item
            savedItem.isStreaming = false
            return savedItem
        }
        sessions[index].updatedAt = Date()

        if shouldRetitle && sessions[index].title == "New Chat",
           let learnerMessage = transcript.first(where: { $0.role == .learner }) {
            sessions[index].title = Self.title(from: learnerMessage.text)
        }

        sortSessionsKeepingSelection()
        saveSessions()
    }

    private func sortSessionsKeepingSelection() {
        let selection = selectedSessionID
        sessions.sort { $0.updatedAt > $1.updatedAt }
        selectedSessionID = selection
    }

    private func saveSessions() {
        do {
            try chatRepository.save(sessions)
        } catch {
            lastError = "Could not save chat history: \(error.localizedDescription)"
        }
    }

    private static func title(from text: String) -> String {
        let words = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(whereSeparator: { $0.isWhitespace || $0.isNewline })
            .prefix(6)
            .joined(separator: " ")

        let trimmed = words.trimmingCharacters(in: CharacterSet(charactersIn: ".,!?;:"))
        guard !trimmed.isEmpty else {
            return "New Chat"
        }

        return String(trimmed.prefix(60))
    }
}
