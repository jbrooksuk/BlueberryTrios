import SwiftUI
import StoreKit

struct SettingsFormView: View {
    @AppStorage("autoCheck") private var autoCheck: Bool = true
    @AppStorage("showTimer") private var showTimer: Bool = true
    @AppStorage("fillHints") private var fillHints: Bool = false
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    @AppStorage("soundEnabled") private var soundEnabled: Bool = true
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = BerryTheme.blueberry.rawValue

    @State private var notificationService = NotificationService()
    @State private var showOfferCode: Bool = false

    var storeService: StoreKitService
    var hintService: HintService?
    var onShowWalkthrough: (() -> Void)?
    var onShowTutorial: (() -> Void)?

    private var selectedTheme: BerryTheme {
        BerryTheme(rawValue: selectedThemeRaw) ?? .blueberry
    }

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

            // MARK: - Theme picker

            Section("Theme") {
                ForEach(BerryTheme.allCases) { theme in
                    let isSelected = selectedTheme == theme
                    let isUnlocked = storeService.isThemeUnlocked(theme)

                    Button {
                        if isUnlocked {
                            applyTheme(theme)
                        } else {
                            Task { try? await storeService.purchaseTheme(theme) }
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(theme.primaryColor)
                                .frame(width: 28, height: 28)
                                .overlay {
                                    if isSelected {
                                        Image(systemName: "checkmark")
                                            .font(.caption.bold())
                                            .foregroundStyle(.white)
                                    }
                                }

                            VStack(alignment: .leading, spacing: 1) {
                                Text(theme.displayName)
                                    .font(.body)
                                    .foregroundStyle(.primary)
                                if !isUnlocked, let product = storeService.product(for: theme) {
                                    Text(product.displayPrice)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            if isUnlocked {
                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }
                            } else {
                                Image(systemName: "lock.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            // MARK: - Hints

            if let hintService {
                Section("Hints") {
                    HStack {
                        Label("Daily hints", systemImage: "clock")
                        Spacer()
                        Text("\(hintService.dailyHintsRemaining)/\(HintService.dailyFreeHints)")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    HStack {
                        Label("Bonus hints", systemImage: "plus.circle")
                        Spacer()
                        Text("\(hintService.bonusHints)")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }

                    ForEach(storeService.sortedHintProducts, id: \.id) { product in
                        Button {
                            Task { try? await storeService.purchaseHints(productID: product.id) }
                        } label: {
                            HStack {
                                Text("Buy \(product.displayName)")
                                Spacer()
                                Text(product.displayPrice)
                                    .foregroundStyle(.secondary)
                            }
                        }
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
                Text("Made with berries by James Brooks \u{1FAD0}")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundStyle(.secondary)
                    .font(.footnote)
                    .listRowBackground(Color.clear)
            }
        }
        .offerCodeRedemption(isPresented: $showOfferCode)
    }

    private func applyTheme(_ theme: BerryTheme) {
        selectedThemeRaw = theme.rawValue
        BerryTheme.active = theme

        // Switch the app icon to match the theme.
        // nil resets to the primary icon; a name selects an alternate.
        #if !DEBUG
        let iconName = theme.alternateIconName
        if UIApplication.shared.alternateIconName != iconName {
            UIApplication.shared.setAlternateIconName(iconName)
        }
        #endif
    }
}
