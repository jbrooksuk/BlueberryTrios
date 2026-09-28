import SwiftUI
import SwiftData
import StoreKit
import UIKit

struct SettingsFormView: View {
    @Environment(\.appTheme) private var theme
    @AppStorage("autoCheck") private var autoCheck: Bool = true
    @AppStorage("showTimer") private var showTimer: Bool = true
    @AppStorage("fillHints") private var fillHints: Bool = false
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    @AppStorage("soundEnabled") private var soundEnabled: Bool = true
    @AppStorage(ThemeSelection.storageKey) private var selectedThemeID: String = ""

    @Query private var statsRecords: [PlayerStats]

    @State private var notificationService = NotificationService()
    @State private var showOfferCode: Bool = false
    @State private var selectedIconName = UIApplication.shared.alternateIconName
    @State private var showIconChangeError = false

    var storeService: StoreKitService
    var onShowWalkthrough: (() -> Void)?
    var onShowTutorial: (() -> Void)?

    private var displayedThemes: [AppTheme] {
        ThemeSelection.themesForCurrentBuild()
    }

    private var displayedIconThemes: [AppTheme] {
        displayedThemes
    }

    var body: some View {
        Form {
            Section("Gameplay") {
                Toggle("Auto check", isOn: $autoCheck)
                Toggle("Show timer", isOn: $showTimer)
                Toggle("Fill hints", isOn: $fillHints)
                Toggle("Haptics", isOn: $hapticsEnabled)
                Toggle("Sound", isOn: $soundEnabled)
                Toggle("Daily reminder", isOn: Binding(
                    get: { notificationService.isEnabled },
                    set: { newValue in
                        notificationService.setEnabled(
                            newValue,
                            currentStreak: statsRecords.first?.effectiveCurrentStreak ?? 0
                        )
                    }
                ))
            }
            Section {
                themeRow(
                    name: String(localized: "Automatic"),
                    subtitle: String(localized: "Uses the theme chosen for this release"),
                    symbolName: "wand.and.stars",
                    palette: ThemeSelection.automaticTheme().palette,
                    isSelected: selectedThemeID.isEmpty
                ) {
                    selectedThemeID = ""
                }

                ForEach(displayedThemes) { theme in
                    appThemeRow(theme)
                }
            } header: {
                Text("Theme")
            } footer: {
                Text("Choosing a theme saves it as your preference, even when a later update has a new seasonal look.")
            }
            if displayedIconThemes.count > 1 {
                Section {
                    ForEach(displayedIconThemes) { appTheme in
                        appIconRow(appTheme)
                    }
                } header: {
                    Text("App icon")
                } footer: {
                    Text("Seasonal icons are available during their matching theme.")
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
                }
                Button("Restore purchases") {
                    Task { await storeService.restorePurchases() }
                }
                Button("Redeem code") {
                    showOfferCode = true
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
                Text("Place 3 \(theme.markerNamePlural) into each row, column, and block. Surround each number with the specified number of \(theme.markerNamePlural).")
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
                Text(theme.attribution)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundStyle(.secondary)
                    .font(.footnote)
                    .listRowBackground(Color.clear)
            }
        }
        .offerCodeRedemption(isPresented: $showOfferCode)
        .alert("Couldn't change app icon", isPresented: $showIconChangeError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please try again.")
        }
    }

    @ViewBuilder
    private func appThemeRow(_ appTheme: AppTheme) -> some View {
        let isUnlocked = storeService.isThemeUnlocked(appTheme)
        let product = storeService.product(for: appTheme)
        themeRow(
            name: String(localized: appTheme.name),
            subtitle: isUnlocked ? nil : product?.displayPrice ?? String(localized: "Coming soon"),
            symbolName: appTheme.symbolName,
            palette: appTheme.palette,
            isSelected: selectedThemeID == appTheme.rawValue,
            isLocked: !isUnlocked
        ) {
            if isUnlocked {
                selectedThemeID = appTheme.rawValue
            } else if product != nil {
                Task {
                    if (try? await storeService.purchaseTheme(appTheme)) == true {
                        selectedThemeID = appTheme.rawValue
                    }
                }
            }
        }
        .disabled(!isUnlocked && product == nil)
    }

    @ViewBuilder
    private func appIconRow(_ appTheme: AppTheme) -> some View {
        let isUnlocked = storeService.isThemeUnlocked(appTheme)
        let isSelected = selectedIconName == appTheme.alternateIconName

        Button {
            guard isUnlocked, UIApplication.shared.supportsAlternateIcons else { return }
            let iconName = appTheme.alternateIconName
            UIApplication.shared.setAlternateIconName(iconName) { error in
                Task { @MainActor in
                    if error == nil {
                        selectedIconName = iconName
                    } else {
                        showIconChangeError = true
                    }
                }
            }
        } label: {
            HStack(spacing: 12) {
                appIconPreview(appTheme)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(.rect(cornerRadius: 10))
                    .accessibilityHidden(true)

                Text(appTheme.name)
                    .foregroundStyle(.primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .fontWeight(.semibold)
                        .accessibilityLabel("Selected")
                } else if !isUnlocked {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Locked")
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked || !UIApplication.shared.supportsAlternateIcons)
    }

    private func appIconPreview(_ appTheme: AppTheme) -> Image {
        switch appTheme {
        case .blueberry:
            #if DEBUG
            return Image("ThemeIconDebugPreview")
            #else
            return Image("ThemeIconBlueberryPreview")
            #endif
        case .halloween:
            return Image("ThemeIconHalloweenPreview")
        case .christmas:
            return Image("ThemeIconChristmasPreview")
        case .raspberry:
            return Image("ThemeIconRaspberryPreview")
        }
    }

    private func themeRow(
        name: String,
        subtitle: String?,
        symbolName: String,
        palette: Theme,
        isSelected: Bool,
        isLocked: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(palette.backgroundAccent.opacity(0.18))
                    if let berrySymbol = palette.berrySymbol {
                        Text(berrySymbol)
                            .font(.system(size: 18))
                    } else {
                        Image(systemName: symbolName)
                            .foregroundStyle(palette.berry)
                    }
                }
                .frame(width: 32, height: 32)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .foregroundStyle(.primary)
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .fontWeight(.semibold)
                        .accessibilityLabel("Selected")
                } else if isLocked {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Locked")
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
