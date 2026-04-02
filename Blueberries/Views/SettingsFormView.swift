import SwiftUI
import StoreKit

struct SettingsFormView: View {
    @AppStorage("autoCheck") private var autoCheck: Bool = true
    @AppStorage("showTimer") private var showTimer: Bool = true
    @AppStorage("fillHints") private var fillHints: Bool = false
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    @AppStorage("soundEnabled") private var soundEnabled: Bool = true

    @State private var notificationService = NotificationService()
    @State private var showOfferCode: Bool = false

    var storeService: StoreKitService
    var onShowWalkthrough: (() -> Void)?
    var onShowTutorial: (() -> Void)?

    var body: some View {
        Form {
            Section("Gameplay") {
                Toggle("Auto Check", isOn: $autoCheck)
                Toggle("Show Timer", isOn: $showTimer)
                Toggle("Fill Hints", isOn: $fillHints)
                Toggle("Haptics", isOn: $hapticsEnabled)
                Toggle("Sound", isOn: $soundEnabled)
                Toggle("Daily Reminder", isOn: $notificationService.isEnabled)
            }
            Section("Pro Puzzles") {
                if storeService.isProUnlocked {
                    Label("Pro Unlocked", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                } else {
                    if let product = storeService.proProduct {
                        Button {
                            Task { try? await storeService.purchasePro() }
                        } label: {
                            HStack {
                                Text("Unlock Pro Puzzles")
                                Spacer()
                                Text(product.displayPrice)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } else {
                        HStack {
                            ProgressView()
                                .controlSize(.small)
                            Text("Loading products...")
                                .foregroundStyle(.secondary)
                        }
                    }
                    Button("Restore Purchases") {
                        Task { await storeService.restorePurchases() }
                    }
                    Button("Redeem Code") {
                        showOfferCode = true
                    }
                }
            }
            Section("Help") {
                if let onShowWalkthrough {
                    Button {
                        onShowWalkthrough()
                    } label: {
                        Label(String(localized: "Show walkthrough", comment: "Settings button to replay walkthrough"), systemImage: "questionmark.circle")
                    }
                }
                if let onShowTutorial {
                    Button {
                        onShowTutorial()
                    } label: {
                        Label(String(localized: "Show tutorial", comment: "Settings button to replay tutorial"), systemImage: "puzzlepiece")
                    }
                }
                Text("Place 3 berries into each row, column, and block. Surround each number with the specified number of berries.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Section("About") {
                Link(destination: URL(string: "https://berroku.com")!) {
                    HStack {
                        Label("Website", systemImage: "globe")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Link(destination: URL(string: "https://x.com/jbrooksuk")!) {
                    HStack {
                        Label("Follow @jbrooksuk", systemImage: "at")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Section {
                Text("Made with berries 🫐")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundStyle(.secondary)
                    .font(.footnote)
                    .listRowBackground(Color.clear)
            }
        }
        .offerCodeRedemption(isPresented: $showOfferCode)
    }
}
