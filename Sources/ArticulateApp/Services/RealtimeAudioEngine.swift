import AVFoundation
import Foundation

enum RealtimeAudioError: LocalizedError {
    case microphoneDenied
    case invalidAudioFormat

    var errorDescription: String? {
        switch self {
        case .microphoneDenied:
            return "Microphone access is required to practice by voice."
        case .invalidAudioFormat:
            return "Could not create the required 24 kHz PCM audio format."
        }
    }
}

final class RealtimeAudioEngine {
    private let captureEngine = AVAudioEngine()
    private var converter: AVAudioConverter?
    private var captureFormat: AVAudioFormat?

    private let playbackEngine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let playbackQueue = DispatchQueue(label: "Articulate.playback")
    private let playbackFormat: AVAudioFormat

    init() {
        playbackFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 24000, channels: 1, interleaved: true)!
        playbackEngine.attach(playerNode)
        playbackEngine.connect(playerNode, to: playbackEngine.mainMixerNode, format: playbackFormat)
        playbackEngine.prepare()
    }

    var isCapturing: Bool {
        captureEngine.isRunning
    }

    func startCapture(onChunk: @escaping (Data) -> Void) async throws {
        guard await requestMicrophoneAccess() else {
            throw RealtimeAudioError.microphoneDenied
        }

        stopCapture()

        let inputNode = captureEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        guard let targetFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 24000, channels: 1, interleaved: true),
              let converter = AVAudioConverter(from: inputFormat, to: targetFormat) else {
            throw RealtimeAudioError.invalidAudioFormat
        }

        self.converter = converter
        self.captureFormat = targetFormat

        inputNode.installTap(onBus: 0, bufferSize: 2048, format: inputFormat) { [weak self] buffer, _ in
            guard let self, let data = self.convertToPCM16(buffer) else {
                return
            }
            onChunk(data)
        }

        captureEngine.prepare()
        try captureEngine.start()
    }

    func stopCapture() {
        if captureEngine.inputNode.numberOfInputs > 0 {
            captureEngine.inputNode.removeTap(onBus: 0)
        }
        captureEngine.stop()
        converter = nil
        captureFormat = nil
    }

    func enqueuePlayback(_ data: Data) {
        guard !data.isEmpty else { return }

        playbackQueue.async { [weak self] in
            guard let self else { return }

            do {
                if !self.playbackEngine.isRunning {
                    try self.playbackEngine.start()
                }
                if !self.playerNode.isPlaying {
                    self.playerNode.play()
                }

                let frameCount = AVAudioFrameCount(data.count / MemoryLayout<Int16>.size)
                guard let buffer = AVAudioPCMBuffer(pcmFormat: self.playbackFormat, frameCapacity: frameCount) else {
                    return
                }

                buffer.frameLength = frameCount
                var audioBuffer = buffer.audioBufferList.pointee.mBuffers
                guard let destination = audioBuffer.mData else {
                    return
                }

                data.withUnsafeBytes { rawBuffer in
                    if let source = rawBuffer.baseAddress {
                        memcpy(destination, source, data.count)
                    }
                }

                audioBuffer.mDataByteSize = UInt32(data.count)
                self.playerNode.scheduleBuffer(buffer, completionHandler: nil)
            } catch {
                return
            }
        }
    }

    func stopPlayback() {
        playbackQueue.async { [weak self] in
            self?.playerNode.stop()
            self?.playbackEngine.stop()
            self?.playbackEngine.reset()
        }
    }

    private func convertToPCM16(_ buffer: AVAudioPCMBuffer) -> Data? {
        guard let converter, let targetFormat = captureFormat else {
            return nil
        }

        let ratio = targetFormat.sampleRate / buffer.format.sampleRate
        let outputCapacity = AVAudioFrameCount((Double(buffer.frameLength) * ratio).rounded(.up)) + 8
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: outputCapacity) else {
            return nil
        }

        var didProvideInput = false
        var conversionError: NSError?
        let inputBlock: AVAudioConverterInputBlock = { _, status in
            if didProvideInput {
                status.pointee = .noDataNow
                return nil
            }
            didProvideInput = true
            status.pointee = .haveData
            return buffer
        }

        let outputStatus = converter.convert(to: outputBuffer, error: &conversionError, withInputFrom: inputBlock)
        guard outputStatus != .error, conversionError == nil else {
            return nil
        }

        let audioBuffer = outputBuffer.audioBufferList.pointee.mBuffers
        guard let bytes = audioBuffer.mData, audioBuffer.mDataByteSize > 0 else {
            return nil
        }

        return Data(bytes: bytes, count: Int(audioBuffer.mDataByteSize))
    }

    private func requestMicrophoneAccess() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .audio) { granted in
                    continuation.resume(returning: granted)
                }
            }
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }
}
