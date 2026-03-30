import AudioToolbox
import Observation

@MainActor
@Observable
final class SoundService {
    var isEnabled: Bool = true

    func playTap() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1104)
    }

    func playClear() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1105)
    }

    func playSolved() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1025)
    }
}
