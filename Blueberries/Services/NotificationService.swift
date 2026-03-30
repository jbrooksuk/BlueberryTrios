import Foundation
import UserNotifications
import Observation

@MainActor
@Observable
final class NotificationService {
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
                scheduleDailyReminder()
            } else {
                isEnabled = false
            }
        }
    }

    private func scheduleDailyReminder() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let content = UNMutableNotificationContent()
        content.title = "Berroku"
        content.body = "Today's puzzles are ready! Can you keep your streak going?"
        content.sound = .default

        // Schedule for 9:00 AM daily
        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: "daily-puzzle-reminder",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    private func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
