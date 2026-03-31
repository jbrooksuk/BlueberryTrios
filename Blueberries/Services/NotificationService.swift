import Foundation
import UserNotifications
import Observation

@MainActor
@Observable
final class NotificationService {
    private static let enabledKey = "dailyReminderEnabled"
    private static let morningIdentifier = "daily-puzzle-morning"
    private static let eveningIdentifier = "daily-puzzle-evening"

    var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: Self.enabledKey)
            if isEnabled {
                requestAndSchedule()
            } else {
                cancelAll()
            }
        }
    }

    init() {
        self.isEnabled = UserDefaults.standard.bool(forKey: Self.enabledKey)
    }

    /// Re-evaluate notifications based on current solve state.
    /// Call this when a puzzle is solved to cancel reminders if all dailies are done.
    func refreshIfNeeded(allDailySolved: Bool) {
        guard isEnabled else { return }

        if allDailySolved {
            cancelAll()
        } else {
            scheduleReminders()
        }
    }

    func requestAndSchedule() {
        Task {
            let center = UNUserNotificationCenter.current()
            let granted = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
            if granted == true {
                scheduleReminders()
            } else {
                isEnabled = false
            }
        }
    }

    private func scheduleReminders() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        // Morning reminder at 9:00 AM
        let morningContent = UNMutableNotificationContent()
        morningContent.title = String(localized: "Berroku")
        morningContent.body = String(localized: "Today's puzzles are ready! Can you keep your streak going?")
        morningContent.sound = .default

        var morningComponents = DateComponents()
        morningComponents.hour = 9
        morningComponents.minute = 0
        let morningTrigger = UNCalendarNotificationTrigger(dateMatching: morningComponents, repeats: true)

        center.add(UNNotificationRequest(
            identifier: Self.morningIdentifier,
            content: morningContent,
            trigger: morningTrigger
        ))

        // Evening reminder at 8:00 PM
        let eveningContent = UNMutableNotificationContent()
        eveningContent.title = String(localized: "Berroku")
        eveningContent.body = String(localized: "You still have unsolved puzzles today. Don't lose your streak!")
        eveningContent.sound = .default

        var eveningComponents = DateComponents()
        eveningComponents.hour = 20
        eveningComponents.minute = 0
        let eveningTrigger = UNCalendarNotificationTrigger(dateMatching: eveningComponents, repeats: true)

        center.add(UNNotificationRequest(
            identifier: Self.eveningIdentifier,
            content: eveningContent,
            trigger: eveningTrigger
        ))
    }

    private func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
