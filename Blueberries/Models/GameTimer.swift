import Foundation
import Observation

@MainActor
@Observable
final class GameTimer {
    var elapsedTime: TimeInterval = 0
    private(set) var isRunning: Bool = false
    private var timerTask: Task<Void, Never>?

    func start() {
        guard !isRunning else { return }
        isRunning = true
        timerTask = Task {
            while !Task.isCancelled && isRunning {
                try? await Task.sleep(for: .seconds(1))
                if !Task.isCancelled && isRunning {
                    elapsedTime += 1
                }
            }
        }
    }

    func stop() {
        isRunning = false
        timerTask?.cancel()
        timerTask = nil
    }

    func reset() {
        stop()
        elapsedTime = 0
    }
}
