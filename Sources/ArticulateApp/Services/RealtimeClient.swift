import Foundation

struct RealtimeSessionConfig {
    let instructions: String
    let voice: String
}

enum RealtimeServerEvent {
    case connected
    case sessionUpdated
    case learnerTranscript(String)
    case coachTextDelta(String)
    case coachAudioDelta(Data)
    case responseDone
    case notice(String)
    case error(String)
}

enum RealtimeClientError: LocalizedError {
    case invalidURL
    case notConnected
    case invalidPayload

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The Realtime endpoint URL is invalid."
        case .notConnected:
            return "The Realtime session is not connected."
        case .invalidPayload:
            return "Could not encode a Realtime event."
        }
    }
}

final class RealtimeClient {
    var onEvent: ((RealtimeServerEvent) -> Void)?

    private let apiKey: String
    private let model: String
    private let safetyIdentifier: String
    private var webSocket: URLSessionWebSocketTask?

    init(apiKey: String, model: String, safetyIdentifier: String) {
        self.apiKey = apiKey
        self.model = model
        self.safetyIdentifier = safetyIdentifier
    }

    func connect(config: RealtimeSessionConfig) async throws {
        guard let url = URL(string: "wss://api.openai.com/v1/realtime?model=\(model)") else {
            throw RealtimeClientError.invalidURL
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue(safetyIdentifier, forHTTPHeaderField: "OpenAI-Safety-Identifier")

        let socket = URLSession.shared.webSocketTask(with: request)
        webSocket = socket
        socket.resume()
        receiveNextMessage()
        try await updateSession(config)
        onEvent?(.connected)
    }

    func disconnect() {
        webSocket?.cancel(with: .goingAway, reason: nil)
        webSocket = nil
    }

    func updateSession(_ config: RealtimeSessionConfig) async throws {
        let event: [String: Any] = [
            "type": "session.update",
            "session": [
                "type": "realtime",
                "model": model,
                "instructions": config.instructions,
                "max_output_tokens": 1200,
                "output_modalities": ["audio"],
                "audio": [
                    "input": [
                        "format": [
                            "type": "audio/pcm",
                            "rate": 24000
                        ],
                        "turn_detection": NSNull(),
                        "noise_reduction": [
                            "type": "near_field"
                        ],
                        "transcription": [
                            "model": "gpt-4o-mini-transcribe"
                        ]
                    ],
                    "output": [
                        "format": [
                            "type": "audio/pcm",
                            "rate": 24000
                        ],
                        "voice": config.voice
                    ]
                ]
            ]
        ]

        try await send(event)
    }

    func clearInputAudio() async throws {
        try await send(["type": "input_audio_buffer.clear"])
    }

    func appendAudio(_ data: Data) async throws {
        guard !data.isEmpty else { return }
        try await send([
            "type": "input_audio_buffer.append",
            "audio": data.base64EncodedString()
        ])
    }

    func commitInputAudioAndRespond() async throws {
        try await send(["type": "input_audio_buffer.commit"])
        try await createResponse()
    }

    func sendText(_ text: String) async throws {
        let item: [String: Any] = [
            "type": "message",
            "role": "user",
            "content": [
                [
                    "type": "input_text",
                    "text": text
                ]
            ]
        ]

        try await send([
            "type": "conversation.item.create",
            "item": item
        ])

        try await createResponse()
    }

    func cancelResponse() async throws {
        try await send(["type": "response.cancel"])
    }

    private func createResponse() async throws {
        try await send([
            "type": "response.create",
            "response": [
                "output_modalities": ["audio"]
            ]
        ])
    }

    private func send(_ object: [String: Any]) async throws {
        guard let webSocket else {
            throw RealtimeClientError.notConnected
        }

        guard JSONSerialization.isValidJSONObject(object),
              let data = try? JSONSerialization.data(withJSONObject: object),
              let text = String(data: data, encoding: .utf8) else {
            throw RealtimeClientError.invalidPayload
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            webSocket.send(.string(text)) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private func receiveNextMessage() {
        webSocket?.receive { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let message):
                self.handle(message)
                self.receiveNextMessage()
            case .failure(let error):
                self.onEvent?(.error(error.localizedDescription))
            }
        }
    }

    private func handle(_ message: URLSessionWebSocketTask.Message) {
        let payload: Data?
        switch message {
        case .data(let data):
            payload = data
        case .string(let string):
            payload = string.data(using: .utf8)
        @unknown default:
            payload = nil
        }

        guard let payload,
              let object = try? JSONSerialization.jsonObject(with: payload),
              let event = object as? [String: Any],
              let type = event["type"] as? String else {
            onEvent?(.notice("Received an unreadable Realtime event."))
            return
        }

        switch type {
        case "session.created", "session.updated":
            onEvent?(.sessionUpdated)
        case "conversation.item.input_audio_transcription.completed",
             "conversation.item.input_audio_transcription.done":
            if let transcript = event["transcript"] as? String, !transcript.isEmpty {
                onEvent?(.learnerTranscript(transcript))
            }
        case "response.output_audio.delta", "response.audio.delta":
            if let delta = event["delta"] as? String, let data = Data(base64Encoded: delta) {
                onEvent?(.coachAudioDelta(data))
            }
        case "response.output_audio_transcript.delta",
             "response.audio_transcript.delta",
             "response.output_text.delta",
             "response.text.delta":
            if let delta = event["delta"] as? String, !delta.isEmpty {
                onEvent?(.coachTextDelta(delta))
            }
        case "response.done":
            onEvent?(.responseDone)
        case "error":
            onEvent?(.error(errorMessage(from: event)))
        default:
            break
        }
    }

    private func errorMessage(from event: [String: Any]) -> String {
        if let error = event["error"] as? [String: Any],
           let message = error["message"] as? String {
            return message
        }

        if let message = event["message"] as? String {
            return message
        }

        return "Realtime API returned an error."
    }
}
