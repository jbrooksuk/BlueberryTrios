import Foundation
import GameKit
import Observation

@MainActor
@Observable
final class GameCenterService {
    private(set) var isAuthenticated = false

    // Achievement identifiers
    enum Achievement: String, CaseIterable {
        case firstPuzzle = "com.alt-three.Berroku.first_puzzle"
        case dedicated = "com.alt-three.Berroku.dedicated"
        case centurion = "com.alt-three.Berroku.centurion"
        case master = "com.alt-three.Berroku.master"
        case onARoll = "com.alt-three.Berroku.streak_3"
        case weekWarrior = "com.alt-three.Berroku.streak_7"
        case berryCommitted = "com.alt-three.Berroku.streak_30"
        case speedDemon = "com.alt-three.Berroku.speed_demon"
        case standardComplete = "com.alt-three.Berroku.standard_complete"
        case advancedComplete = "com.alt-three.Berroku.advanced_complete"
        case expertComplete = "com.alt-three.Berroku.expert_complete"
        case dailySweep = "com.alt-three.Berroku.daily_sweep"
    }

    // Leaderboard identifier
    static let fastestTimeLeaderboard = "com.alt-three.Berroku.fastest_time"

    func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            if let error {
                print("Game Center auth error: \(error)")
                return
            }
            self?.isAuthenticated = GKLocalPlayer.local.isAuthenticated
        }
    }

    func reportPuzzleCompleted(totalCompleted: Int, completionTime: TimeInterval, streak: Int, difficulty: Difficulty? = nil, allDailySolved: Bool = false) {
        guard isAuthenticated else { return }

        var achievements: [GKAchievement] = []

        // Puzzle count achievements
        let milestones: [(Achievement, Int)] = [
            (.firstPuzzle, 1),
            (.dedicated, 10),
            (.centurion, 100),
            (.master, 500),
        ]
        for (achievement, target) in milestones {
            let percent = min(100.0, Double(totalCompleted) / Double(target) * 100.0)
            let gkAchievement = GKAchievement(identifier: achievement.rawValue)
            gkAchievement.percentComplete = percent
            gkAchievement.showsCompletionBanner = true
            achievements.append(gkAchievement)
        }

        // Streak achievements
        let streakMilestones: [(Achievement, Int)] = [
            (.onARoll, 3),
            (.weekWarrior, 7),
            (.berryCommitted, 30),
        ]
        for (achievement, target) in streakMilestones {
            let percent = min(100.0, Double(streak) / Double(target) * 100.0)
            let gkAchievement = GKAchievement(identifier: achievement.rawValue)
            gkAchievement.percentComplete = percent
            gkAchievement.showsCompletionBanner = true
            achievements.append(gkAchievement)
        }

        // Speed achievement — sub 1 minute
        let speedAchievement = GKAchievement(identifier: Achievement.speedDemon.rawValue)
        speedAchievement.percentComplete = completionTime < 60 ? 100.0 : 0.0
        speedAchievement.showsCompletionBanner = true
        achievements.append(speedAchievement)

        // Difficulty achievements
        if let difficulty {
            let diffAchievement: Achievement? = switch difficulty {
            case .standard: .standardComplete
            case .advanced: .advancedComplete
            case .expert: .expertComplete
            }
            if let diffAchievement {
                let gkAchievement = GKAchievement(identifier: diffAchievement.rawValue)
                gkAchievement.percentComplete = 100.0
                gkAchievement.showsCompletionBanner = true
                achievements.append(gkAchievement)
            }
        }

        // Daily sweep — all 3 difficulties in one day
        if allDailySolved {
            let sweepAchievement = GKAchievement(identifier: Achievement.dailySweep.rawValue)
            sweepAchievement.percentComplete = 100.0
            sweepAchievement.showsCompletionBanner = true
            achievements.append(sweepAchievement)
        }

        Task {
            do {
                try await GKAchievement.report(achievements)
            } catch {
                print("Failed to report achievements: \(error)")
            }

            try? await GKLeaderboard.submitScore(
                Int(completionTime),
                context: 0,
                player: GKLocalPlayer.local,
                leaderboardIDs: [Self.fastestTimeLeaderboard]
            )
        }
    }
}
