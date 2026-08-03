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
        case lightning = "com.altthree.berroku.lightning"
        case flawless = "com.altthree.berroku.flawless"
        case perfectionist = "com.altthree.berroku.perfectionist"
        case earlyBird = "com.altthree.berroku.early_bird"
        case marathon = "com.altthree.berroku.marathon"
        case proExplorer = "com.altthree.berroku.pro_explorer"
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

    /// Reports just the hint achievements (Hint helper, Hint master) so
    /// they fire the moment the player presses the hint button rather
    /// than waiting for puzzle completion. Game Center accepts repeat
    /// reports idempotently, so the redundant report inside
    /// `reportPuzzleCompleted` is harmless.
    func reportHintUsed(totalHintsUsed: Int) {
        guard isAuthenticated else { return }

        var achievements: [GKAchievement] = []
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

        guard !achievements.isEmpty else { return }

        Task {
            do {
                try await GKAchievement.report(achievements)
            } catch {
                #if DEBUG
                print("Failed to report hint achievements: \(error)")
                #endif
            }
        }
    }

    func reportPuzzleCompleted(
        totalCompleted: Int,
        completionTime: TimeInterval,
        streak: Int,
        difficulty: Difficulty? = nil,
        isDaily: Bool = false,
        allDailySolved: Bool = false,
        hintUsed: Bool = false,
        totalHintsUsed: Int = 0,
        isEarlyBird: Bool = false,
        flawlessStreak: Int = 0,
        dailySweepStreak: Int = 0,
        proPuzzlesCompleted: Int = 0
    ) {
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

            // Lightning — sub 30 seconds
            let lightningAchievement = GKAchievement(identifier: Achievement.lightning.rawValue)
            lightningAchievement.percentComplete = completionTime < 30 ? 100.0 : 0.0
            lightningAchievement.showsCompletionBanner = true
            achievements.append(lightningAchievement)

            // Pro explorer — 50 completed Pro puzzles. Counts all Pro
            // completions (the tally lives in PlayerStats); like the other
            // count achievements it is only *reported* on a hint-free solve.
            if proPuzzlesCompleted > 0 {
                let proAchievement = GKAchievement(identifier: Achievement.proExplorer.rawValue)
                proAchievement.percentComplete = min(100.0, Double(proPuzzlesCompleted) / 50.0 * 100.0)
                proAchievement.showsCompletionBanner = true
                achievements.append(proAchievement)
            }

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

        // Early bird is about *when* you played, not skill, so it is reported
        // regardless of hint usage.
        if isEarlyBird {
            let earlyAchievement = GKAchievement(identifier: Achievement.earlyBird.rawValue)
            earlyAchievement.percentComplete = 100.0
            earlyAchievement.showsCompletionBanner = true
            achievements.append(earlyAchievement)
        }

        // Flawless solver (1) and Perfectionist (10) share the flawless
        // streak, which only advances on hint-free, mistake-free solves — so
        // these are safe to report regardless of the current run's hint usage
        // (a hinted run resets the streak to zero before we get here).
        if flawlessStreak > 0 {
            let flawlessAchievement = GKAchievement(identifier: Achievement.flawless.rawValue)
            flawlessAchievement.percentComplete = 100.0
            flawlessAchievement.showsCompletionBanner = true
            achievements.append(flawlessAchievement)

            let perfectionistAchievement = GKAchievement(identifier: Achievement.perfectionist.rawValue)
            perfectionistAchievement.percentComplete = min(100.0, Double(flawlessStreak) / 10.0 * 100.0)
            perfectionistAchievement.showsCompletionBanner = true
            achievements.append(perfectionistAchievement)
        }

        // Marathon — sweep the dailies 7 days running. The sweep streak only
        // advances on hint-free sweeps, so reporting it here is always valid.
        if dailySweepStreak > 0 {
            let marathonAchievement = GKAchievement(identifier: Achievement.marathon.rawValue)
            marathonAchievement.percentComplete = min(100.0, Double(dailySweepStreak) / 7.0 * 100.0)
            marathonAchievement.showsCompletionBanner = true
            achievements.append(marathonAchievement)
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
