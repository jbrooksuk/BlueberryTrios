import SwiftUI
import SwiftData
import StoreKit

struct SettingsFormView: View {
    @AppStorage("autoCheck") private var autoCheck: Bool = true
    @AppStorage("showTimer") private var showTimer: Bool = true
    @AppStorage("fillHints") private var fillHints: Bool = false
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    @AppStorage("soundEnabled") private var soundEnabled: Bool = true

    @Query private var statsRecords: [PlayerStats]
    @State private var notificationService = NotificationService()
    @State private var showOfferCode: Bool = false
    @State private var isPurchasingHints: Bool = false

    var storeService: StoreKitService
    var onShowWalkthrough: (() -> Void)?
    var onShowTutorial: (() -> Void)?

    private var stats: PlayerStats? { statsRecords.first }

    var body: some View {
        Form {
            Section("Gameplay") {
                Toggle("Auto check", isOn: $autoCheck)
                Toggle("Show timer", isOn: $showTimer)
                Toggle("Fill hints", isOn: $fillHints)
                Toggle("Haptics", isOn: $hapticsEnabled)
                Toggle("Sound", isOn: $soundEnabled)
                Toggle("Daily reminder", isOn: $notificationService.isEnabled)
            }
            Section("Hints") {
                LabeledContent("Free today") {
                    Text("\(stats?.availableFreeHints ?? PlayerStats.freeHintsPerDay) / \(PlayerStats.freeHintsPerDay)")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Saved pack") {
                    Text("\(stats?.purchasedHintsRemaining ?? 0)")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                if let product = storeService.hintPackProduct {
                    Button {
                        Task {
                            isPurchasingHints = true
                            _ = try? await storeService.purchaseHintPack()
                            isPurchasingHints = false
                        }
                    } label: {
                        HStack {
                            if isPurchasingHints {
                                ProgressView().controlSize(.small)
                                Text("Purchasing…")
                            } else {
                                Text("Buy 10 hints")
                            }
                            Spacer()
                            Text(verbatim: product.displayPrice)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .disabled(isPurchasingHints)
                } else {
                    HStack {
                        ProgressView().controlSize(.small)
                        Text("Loading products…")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Section("Pro puzzles") {
                if storeService.isProUnlocked {
                    Label("Pro unlocked", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                } else {
                    if let product = storeService.proProduct {
                        Button {
                            Task { try? await storeService.purchasePro() }
                        } label: {
                            HStack {
                                Text("Unlock Pro puzzles")
                                Spacer()
                                Text(verbatim: product.displayPrice)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } else {
                        HStack {
                            ProgressView()
                                .controlSize(.small)
                            Text("Loading products…")
                                .foregroundStyle(.secondary)
                        }
                    }
                    Button("Restore purchases") {
                        Task { await storeService.restorePurchases() }
                    }
                    Button("Redeem code") {
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
                Text("Made with berries by James Brooks 🫐")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundStyle(.secondary)
                    .font(.footnote)
                    .listRowBackground(Color.clear)
            }
        }
        .offerCodeRedemption(isPresented: $showOfferCode)
    }
}
