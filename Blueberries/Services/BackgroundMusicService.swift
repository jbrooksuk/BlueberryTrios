import AVFoundation
import Observation

@MainActor
@Observable
final class BackgroundMusicService {
    nonisolated(unsafe) private static let audioSessionQueue = DispatchQueue(
        label: "com.altthree.Berroku.audio-session"
    )

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var musicBuffer: AVAudioPCMBuffer?
    private var playbackTask: Task<Void, Never>?
    private var isEnabled = false

    init() {
        engine.attach(player)
        player.volume = 0.4
    }

    func setEnabled(_ isEnabled: Bool) {
        guard self.isEnabled != isEnabled else { return }
        self.isEnabled = isEnabled
        playbackTask?.cancel()

        if isEnabled {
            playbackTask = Task { await play() }
        } else {
            stop()
            playbackTask = Task { await deactivateAudioSession() }
        }
    }

    private func play() async {
        guard !player.isPlaying else { return }

        do {
            let buffer = try loadMusicBuffer()
            try await configureAudioSession()
            try await activateAudioSession()
            try Task.checkCancellation()
            guard isEnabled else { return }

            player.scheduleBuffer(
                buffer,
                at: nil,
                options: .loops,
                completionHandler: nil
            )
            if !engine.isRunning {
                try engine.start()
            }
            player.play()
        } catch {
            player.stop()
            engine.stop()
        }
    }

    private func stop() {
        player.stop()
        engine.stop()
    }

    private func configureAudioSession() async throws {
        try await Self.performAudioSessionOperation { session in
            try session.setCategory(.ambient, mode: .default)
        }
    }

    private func activateAudioSession() async throws {
        let session = AVAudioSession.sharedInstance()
        if #available(iOS 27.0, *) {
            guard try await session.activate(options: []) else {
                throw BackgroundMusicError.couldNotActivateSession
            }
        } else {
            try await Self.setAudioSessionActive(true)
        }
    }

    private func deactivateAudioSession() async {
        let session = AVAudioSession.sharedInstance()
        if #available(iOS 27.0, *) {
            _ = try? await session.deactivate(options: [.notifyOthersOnDeactivation])
        } else {
            try? await Self.setAudioSessionActive(false)
        }
    }

    private nonisolated static func setAudioSessionActive(_ active: Bool) async throws {
        try await performAudioSessionOperation { session in
            try session.setActive(
                active,
                options: active ? [] : .notifyOthersOnDeactivation
            )
        }
    }

    private nonisolated static func performAudioSessionOperation(
        _ operation: @escaping @Sendable (AVAudioSession) throws -> Void
    ) async throws {
        try await withCheckedThrowingContinuation { continuation in
            audioSessionQueue.async {
                do {
                    try operation(AVAudioSession.sharedInstance())
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func loadMusicBuffer() throws -> AVAudioPCMBuffer {
        if let musicBuffer {
            return musicBuffer
        }

        guard let url = Bundle.main.url(
            forResource: "Soft-Focus-Groove",
            withExtension: "caf"
        ) else {
            throw BackgroundMusicError.missingResource
        }

        let file = try AVAudioFile(forReading: url)
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: file.processingFormat,
            frameCapacity: AVAudioFrameCount(file.length)
        ) else {
            throw BackgroundMusicError.couldNotCreateBuffer
        }

        try file.read(into: buffer)
        engine.connect(player, to: engine.mainMixerNode, format: buffer.format)
        engine.prepare()
        musicBuffer = buffer
        return buffer
    }
}

private enum BackgroundMusicError: Error {
    case missingResource
    case couldNotCreateBuffer
    case couldNotActivateSession
}
