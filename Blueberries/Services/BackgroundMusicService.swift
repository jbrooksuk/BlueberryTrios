import AVFoundation
import Observation

@MainActor
@Observable
final class BackgroundMusicService {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var musicBuffer: AVAudioPCMBuffer?

    init() {
        engine.attach(player)
        player.volume = 0.4
    }

    func setEnabled(_ isEnabled: Bool) {
        if isEnabled {
            play()
        } else {
            stop()
        }
    }

    private func play() {
        guard !player.isPlaying else { return }

        do {
            let buffer = try loadMusicBuffer()
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default)
            try session.setActive(true)

            player.scheduleBuffer(buffer, at: nil, options: .loops)
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
        try? AVAudioSession.sharedInstance().setActive(
            false,
            options: .notifyOthersOnDeactivation
        )
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
}
