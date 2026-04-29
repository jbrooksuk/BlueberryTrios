import Foundation
import UserNotifications
import Observation

@MainActor
@Observable
final class NotificationService {
    private static let reminderIdentifierPrefix = "daily-puzzle-reminder"
    private static let scheduledDayCount = 30
    /// Streak-themed body strings are only included when the player's
    /// effective streak is at least this many days. Below the threshold it
    /// would be misleading (or pressuring) to imply a streak the player
    /// hasn't actually built up yet.
    private static let streakBodyMinimum = 3

    private(set) var isEnabled: Bool = false

    /// Toggles the daily reminder. `currentStreak` should be the player's
    /// effective streak right now (see `PlayerStats.effectiveCurrentStreak`),
    /// so streak-themed body strings only appear when there's a real streak
    /// to talk about.
    func setEnabled(_ enabled: Bool, currentStreak: Int) {
        isEnabled = enabled
        if enabled {
            requestAndSchedule(currentStreak: currentStreak)
        } else {
            cancelAll()
        }
    }

    /// Re-schedules the reminder queue if any are still pending, so the rolling
    /// 30-day window keeps moving forward each time the app is opened. Pass
    /// the current effective streak so streak-themed strings stay aligned
    /// with the player's actual streak status.
    func refreshIfScheduled(currentStreak: Int) {
        Task {
            let center = UNUserNotificationCenter.current()
            let pending = await center.pendingNotificationRequests()
            let hasReminders = pending.contains { $0.identifier.hasPrefix(Self.reminderIdentifierPrefix) }
            if hasReminders {
                isEnabled = true
                scheduleDailyReminders(currentStreak: currentStreak)
            }
        }
    }

    private func requestAndSchedule(currentStreak: Int) {
        Task {
            let center = UNUserNotificationCenter.current()
            let granted = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
            if granted == true {
                scheduleDailyReminders(currentStreak: currentStreak)
            } else {
                isEnabled = false
            }
        }
    }

    private func scheduleDailyReminders(currentStreak: Int) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let calendar = Calendar.current
        let now = Date()
        let bodies = Self.reminderBodies(includeStreak: currentStreak >= Self.streakBodyMinimum)
        var pool: [String] = []
        var lastBody: String?

        for dayOffset in 0..<Self.scheduledDayCount {
            guard
                let target = calendar.date(byAdding: .day, value: dayOffset, to: now),
                let fireDate = calendar.date(
                    bySettingHour: 9,
                    minute: 0,
                    second: 0,
                    of: target
                ),
                fireDate > now
            else { continue }

            if pool.isEmpty {
                pool = bodies.shuffled()
            }
            var body = pool.removeLast()
            // Avoid repeating the same string two days in a row.
            if body == lastBody, let swap = pool.popLast() {
                pool.insert(body, at: 0)
                body = swap
            }
            lastBody = body

            let content = UNMutableNotificationContent()
            content.title = String(localized: "Berroku")
            content.body = body
            content.sound = .default

            let components = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: fireDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: "\(Self.reminderIdentifierPrefix)-\(dayOffset)",
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }

    private func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    private static func reminderBodies(includeStreak: Bool) -> [String] {
        let neutral: [String] = [
            String(localized: "Fresh berries have arrived. Time to sort them out."),
            String(localized: "Your daily puzzles are ripe and waiting."),
            String(localized: "Three berries per row, column, and block. Ready to play?"),
            String(localized: "The grid is set. The berries await."),
            String(localized: "Today's puzzles just dropped. Care to pick them?"),
            String(localized: "Hungry for a puzzle? Today's batch is ready."),
        ]
        guard includeStreak else { return neutral }
        return neutral + [
            String(localized: "Today's puzzles are ready! Can you keep your streak going?"),
            String(localized: "A new day, a new puzzle. Don't break your streak!"),
        ]
    }
}
