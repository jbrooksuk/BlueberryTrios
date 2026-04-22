import SwiftUI

@main
struct BerrokuClipApp: App {
    @State private var invocation = AppClipInvocation()

    var body: some Scene {
        WindowGroup {
            AppClipRootView(invocation: invocation)
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                    invocation.apply(userActivity: activity)
                }
        }
    }
}
