import Foundation
import GameKit
import Observation

@MainActor
@Observable
final class GameCenterService {
    private(set) var isAuthenticated = false

    // Achievement identifiers
    enum Achievement: String, CaseIterable {
        case firstPuzzle = "com.altthree.berroku.first_puzzle"
        case dedicated = "com.altthree.berroku.dedicated"
        case centurion = "com.altthree.berroku.centurion"
        case master = "com.altthree.berroku.master"
        case onARoll = "com.altthree.berroku.streak_3"
        case weekWarrior = "com.altthree.berroku.streak_7"
        case berryCommitted = "com.altthree.berroku.streak_30"
        case speedDemon = "com.altthree.berroku.speed_demon"
        case standardComplete = "com.altthree.berroku.standard_complete"
        case advancedComplete = "com.altthree.berroku.advanced_complete"
        case expertComplete = "com.altthree.berroku.expert_complete"
        case dailySweep = "com.altthree.berroku.daily_sweep"
        case hintHelper = "com.altthree.berroku.hint_helper"
        case hintMaster = "com.altthree.berroku.hint_master"
    }

    // Daily leaderboard identifiers (recurring, one per difficulty)
    static func dailyLeaderboard(for difficulty: Difficulty) -> String {
        switch difficulty {
        case .standard: "com.altthree.berroku.daily_standard"
        case .advanced: "com.altthree.berroku.daily_advanced"
        case .expert: "com.altthree.berroku.daily_expert"
        }
    }

    func authenticate() {
        // Debug builds use a separate bundle ID (`com.altthree.Berroku.debug`)
        // that isn't registered with Game Center in App Store Connect. Trying
        // to authenticate there produces "Invalid gamekit configuration" and
        // cascades into "No AchievementDescription could be found" noise on
        // every report call. Skip GC entirely in debug — `isAuthenticated`
        // stays false, so every other method early-returns cleanly.
        #if DEBUG
        return
        #else
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            if error != nil {
                // User not signed in or cancelled — expected, not an error
                return
            }
            self?.isAuthenticated = GKLocalPlayer.local.isAuthenticated
        }
        #endif
    }

    func reportPuzzleCompleted(totalCompleted: Int, completionTime: TimeInterval, streak: Int, difficulty: Difficulty? = nil, isDaily: Bool = false, allDailySolved: Bool = false, hintUsed: Bool = false, totalHintsUsed: Int = 0) {
        guard isAuthenticated else { return }

        var achievements: [GKAchievement] = []

        // Hint achievements — always reported regardless of hint usage
        let hintMilestones: [(Achievement, Int)] = [
            (.hintHelper, 1),
            (.hintMaster, 100),
        ]
        for (achievement, target) in hintMilestones {
            let percent = min(100.0, Double(totalHintsUsed) / Double(target) * 100.0)
            if percent > 0 {
                let gkAchievement = GKAchievement(identifier: achievement.rawValue)
                gkAchievement.percentComplete = percent
                gkAchievement.showsCompletionBanner = true
                achievements.append(gkAchievement)
            }
        }

        // All other achievements and leaderboards are only for hint-free completions
        if !hintUsed {
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
        }

        Task {
            do {
                try await GKAchievement.report(achievements)
            } catch {
                #if DEBUG
                print("Failed to report achievements: \(error)")
                #endif
            }

            // Only submit to leaderboard for hint-free daily completions
            if !hintUsed, isDaily, let difficulty {
                try? await GKLeaderboard.submitScore(
                    Int(completionTime * 100),
                    context: 0,
                    player: GKLocalPlayer.local,
                    leaderboardIDs: [Self.dailyLeaderboard(for: difficulty)]
                )
            }
        }
    }
}
