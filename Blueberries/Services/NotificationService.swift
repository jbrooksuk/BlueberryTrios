import Foundation
import UserNotifications
import Observation

@MainActor
@Observable
final class NotificationService {
    private static let reminderIdentifierPrefix = "daily-puzzle-reminder"
    private static let scheduledDayCount = 30

    var isEnabled: Bool = false {
        didSet {
            if isEnabled {
                requestAndSchedule()
            } else {
                cancelAll()
            }
        }
    }

    func requestAndSchedule() {
        Task {
            let center = UNUserNotificationCenter.current()
            let granted = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
            if granted == true {
                scheduleDailyReminders()
            } else {
                isEnabled = false
            }
        }
    }

    /// Re-schedules the reminder queue if any are still pending, so the rolling
    /// 30-day window keeps moving forward each time the app is opened.
    func refreshIfScheduled() {
        Task {
            let center = UNUserNotificationCenter.current()
            let pending = await center.pendingNotificationRequests()
            let hasReminders = pending.contains { $0.identifier.hasPrefix(Self.reminderIdentifierPrefix) }
            if hasReminders {
                scheduleDailyReminders()
            }
        }
    }

    private func scheduleDailyReminders() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let calendar = Calendar.current
        let now = Date()
        let bodies = Self.reminderBodies()
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

    private static func reminderBodies() -> [String] {
        [
            String(localized: "Today's puzzles are ready! Can you keep your streak going?"),
            String(localized: "Fresh berries have arrived. Time to sort them out."),
            String(localized: "Your daily puzzles are ripe and waiting."),
            String(localized: "Three berries per row, column, and block. Ready to play?"),
            String(localized: "A new day, a new puzzle. Don't break your streak!"),
            String(localized: "The grid is set. The berries await."),
            String(localized: "Today's puzzles just dropped. Care to pick them?"),
            String(localized: "Hungry for a puzzle? Today's batch is ready."),
        ]
    }
}
