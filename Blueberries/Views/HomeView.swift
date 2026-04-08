import SwiftUI
import SwiftData
import StoreKit
import WidgetKit

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query private var savedStates: [GameState]
    @Query private var statsRecords: [PlayerStats]

    @State private var storeService = StoreKitService()
    @State private var gameCenterService = GameCenterService()
    @State private var hintService = HintService()
    private let puzzleStore = PuzzleStore()
    @State private var navigateToGame = false
    @State private var selectedSource: PuzzleSource = .daily
    @State private var selectedDifficulty: Difficulty = .standard
    @State private var showCalendar: Bool = false
    @State private var showWalkthrough: Bool = false
    @State private var selectedTab: HomeTab = .home
    @AppStorage("hasSeenWalkthrough") private var hasSeenWalkthrough: Bool = false
    @AppStorage("hasCompletedTutorial") private var hasCompletedTutorial: Bool = false
    @State private var showTutorial: Bool = false


    private enum HomeTab: Hashable {
        case home, achievements, settings
    }

    private var stats: PlayerStats? {
        statsRecords.first
    }

    private func ensureStats() {
        var descriptor = FetchDescriptor<PlayerStats>()
        descriptor.fetchLimit = 1
        let existing = (try? modelContext.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }
        modelContext.insert(PlayerStats())
        do {
            try modelContext.save()
        } catch {
            assertionFailure("Failed to save initial PlayerStats: \(error)")
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            homeTab
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(HomeTab.home)
            achievementsTab
                .tabItem { Label("Achievements", systemImage: "trophy.fill") }
                .tag(HomeTab.achievements)
            settingsTab
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(HomeTab.settings)
        }
        .fullScreenCover(isPresented: $showWalkthrough) {
            WalkthroughView(isPresented: $showWalkthrough)
        }
        .fullScreenCover(isPresented: $showTutorial) {
            TutorialView(isPresented: $showTutorial, gameCenterService: gameCenterService, dismissable: hasCompletedTutorial)
                .onDisappear { hasCompletedTutorial = true }
        }
        .onChange(of: showWalkthrough) {
            if !showWalkthrough && !hasSeenWalkthrough {
                hasSeenWalkthrough = true
                if !hasCompletedTutorial {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showTutorial = true
                    }
                }
            }
        }
        .task {
            ensureStats()
            storeService.hintService = hintService
            gameCenterService.authenticate()
            updateWidgetData()

            // Existing users who already saw the walkthrough skip the tutorial
            if hasSeenWalkthrough && !hasCompletedTutorial {
                hasCompletedTutorial = true
            }

            if !hasSeenWalkthrough {
                showWalkthrough = true
            }
        }
    }

    // MARK: - Hero Header

    // MARK: - Tabs

    private var homeTab: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    heroHeader
                        .padding(.bottom, 24)

                    AdaptiveGlassContainer(spacing: 20) {
                        VStack(spacing: 20) {
                            dailyPuzzleCard
                            proPuzzlesCard
                            statsAndCalendarCard
                        }
                    }
                    .frame(maxWidth: 600)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
                .frame(maxWidth: .infinity)
            }
            .background(Theme.backgroundGradient)
            .navigationDestination(isPresented: $navigateToGame) {
                GameView(
                    storeService: storeService,
                    gameCenterService: gameCenterService,
                    puzzleStore: puzzleStore,
                    hintService: hintService,
                    initialSource: selectedSource,
                    initialDifficulty: selectedDifficulty
                )
            }
        }
    }

    private var achievementsTab: some View {
        ScrollView {
            VStack(spacing: 0) {
                achievementsCard
                    .frame(maxWidth: 600)
                    .padding(16)
            }
            .frame(maxWidth: .infinity)
        }
        .background(Theme.backgroundGradient)
    }

    // MARK: - Hero Header

    private var heroHeader: some View {
        VStack(spacing: 12) {
            IllustratedBerryClusterView(animated: !reduceMotion)
                .frame(width: 220, height: 140)

            Text("Berroku")
                .font(.largeTitle.bold())

            if allDailySolved {
                Label("All daily puzzles complete!", systemImage: "sparkles")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.orange)
                    .transition(.scale.combined(with: .opacity))
            } else {
                Text("Place 3 berries in every row, column & block")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 16)
    }

    // MARK: - Daily Puzzle Card

    private var dailyPuzzleCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Today's puzzles", systemImage: "calendar")
                    .font(.headline)
                Spacer()
                let solvedCount = Difficulty.allCases.filter { isDailySolved($0) }.count
                let anyHinted = Difficulty.allCases.contains { isDailyHintUsed($0) }
                Text("\(solvedCount)/3")
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(solvedCount == 3 ? (anyHinted ? .orange : .green) : .secondary)
            }

            HStack(spacing: 0) {
                ForEach(Difficulty.allCases) { diff in
                    let solved = isDailySolved(diff)
                    let hinted = isDailyHintUsed(diff)
                    let inProgress = isDailyInProgress(diff)
                    Button {
                        selectedSource = .daily
                        selectedDifficulty = diff
                        navigateToGame = true
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                if solved && hinted {
                                    Circle()
                                        .fill(Color.orange)
                                        .frame(width: 56, height: 56)
                                        .overlay {
                                            Image(systemName: "lightbulb.fill")
                                                .font(.title3.bold())
                                                .foregroundStyle(.white)
                                        }
                                } else if solved {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 56, height: 56)
                                        .overlay {
                                            Image(systemName: "checkmark")
                                                .font(.title3.bold())
                                                .foregroundStyle(.white)
                                        }
                                } else if inProgress {
                                    Circle()
                                        .fill(Theme.berryBlue)
                                        .frame(width: 56, height: 56)
                                        .overlay {
                                            Text("\(diff.displayIndex)")
                                                .font(.title2.bold())
                                                .foregroundStyle(.white)
                                        }
                                        .shadow(color: Theme.berryBlue.opacity(0.3), radius: 4, y: 2)
                                } else {
                                    Circle()
                                        .strokeBorder(Theme.berryBlue.opacity(0.4), lineWidth: 2)
                                        .frame(width: 56, height: 56)
                                        .overlay {
                                            Text("\(diff.displayIndex)")
                                                .font(.title2.bold())
                                                .foregroundStyle(Theme.berryBlue.opacity(0.6))
                                        }
                                }
                            }

                            Text(diff.rawValue)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(solved ? (hinted ? .orange : .green) : inProgress ? .primary : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(20)
        .adaptiveGlass(in: 16)
    }

    // MARK: - Pro Puzzles Card

    private var proPuzzlesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Pro puzzles", systemImage: "infinity")
                    .font(.headline)
                Spacer()
                if storeService.isProUnlocked {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                }
            }

            if storeService.isProUnlocked {
                Text("Unlimited puzzle sets unlocked.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button {
                    selectedSource = .pro
                    selectedDifficulty = .standard
                    navigateToGame = true
                } label: {
                    Label("Play Pro", systemImage: "play.fill")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .adaptiveProminentButton()
                .controlSize(.large)
            } else {
                Text("Unlock unlimited additional puzzle sets beyond the daily puzzles.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack {
                    if let product = storeService.proProduct {
                        Button {
                            Task { try? await storeService.purchasePro() }
                        } label: {
                            Text("Unlock Pro \(product.displayPrice)")
                                .font(.subheadline.weight(.semibold))
                        }
                        .adaptiveProminentButton()
                    } else {
                        ProgressView()
                            .controlSize(.small)
                        Text("Loading...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Button("Restore") {
                        Task { await storeService.restorePurchases() }
                    }
                    .adaptiveSecondaryButton()
                    .font(.subheadline)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .adaptiveGlass(in: 16)
    }

    // MARK: - Stats Card

    private var statsAndCalendarCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label(showCalendar ? "Activity" : "Statistics",
                      systemImage: showCalendar ? "calendar" : "chart.bar.fill")
                    .font(.headline)

                Spacer()

                Button {
                    if reduceMotion {
                        showCalendar.toggle()
                    } else {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showCalendar.toggle()
                        }
                    }
                } label: {
                    Image(systemName: showCalendar ? "number.square" : "calendar")
                        .font(.body)
                        .foregroundStyle(Theme.berryBlue)
                }
            }

            if showCalendar {
                PuzzleCalendarView(savedStates: savedStates)
            } else {
                let totalPuzzles = stats?.totalPuzzlesCompleted ?? 0
                let totalHints = stats?.totalHintsUsed ?? 0
                let avgHintsText: String = {
                    guard totalPuzzles > 0 else { return "—" }
                    return String(format: "%.1f", Double(totalHints) / Double(totalPuzzles))
                }()
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    statItem(value: "\(totalPuzzles)", label: "Puzzles solved", icon: "puzzlepiece.fill")
                    statItem(value: stats?.fastestCompletionTime?.formattedAsTimer ?? "--:--", label: "Fastest time", icon: "bolt.fill")
                    statItem(value: "\(stats?.currentStreak ?? 0)", label: "Current streak", icon: "flame.fill")
                    statItem(value: "\(stats?.longestStreak ?? 0)", label: "Best streak", icon: "trophy.fill")
                    statItem(value: "\(totalHints)", label: "Hints used", icon: "lightbulb.fill")
                    statItem(value: avgHintsText, label: "Avg hints / puzzle", icon: "chart.bar.xaxis")
                }
            }
        }
        .padding(20)
        .adaptiveGlass(in: 16)
    }

    private func statItem(value: String, label: LocalizedStringKey, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Theme.berryBlue)
            Text(verbatim: value)
                .font(.title2.bold().monospacedDigit())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Theme.berryBlue.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Achievements Card

    private var achievementsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Achievements", systemImage: "trophy.fill")
                .font(.headline)

            VStack(spacing: 0) {
                achievementRow(icon: "1.circle.fill", title: "First puzzle", subtitle: "Complete your first puzzle", progress: stats?.totalPuzzlesCompleted ?? 0, target: 1)
                Divider().padding(.leading, 44)
                achievementRow(icon: "10.circle.fill", title: "Dedicated", subtitle: "Complete 10 puzzles", progress: stats?.totalPuzzlesCompleted ?? 0, target: 10)
                Divider().padding(.leading, 44)
                achievementRow(icon: "star.circle.fill", title: "Centurion", subtitle: "Complete 100 puzzles", progress: stats?.totalPuzzlesCompleted ?? 0, target: 100)
                Divider().padding(.leading, 44)
                achievementRow(icon: "crown.fill", title: "Master", subtitle: "Complete 500 puzzles", progress: stats?.totalPuzzlesCompleted ?? 0, target: 500)
            }

            VStack(spacing: 0) {
                achievementRow(icon: "flame.fill", title: "On a roll", subtitle: "3-day streak", progress: stats?.longestStreak ?? 0, target: 3)
                Divider().padding(.leading, 44)
                achievementRow(icon: "flame.fill", title: "Week warrior", subtitle: "7-day streak", progress: stats?.longestStreak ?? 0, target: 7)
                Divider().padding(.leading, 44)
                achievementRow(icon: "flame.fill", title: "Berry committed", subtitle: "30-day streak", progress: stats?.longestStreak ?? 0, target: 30)
            }

            VStack(spacing: 0) {
                achievementRow(icon: "bolt.fill", title: "Speed demon", subtitle: "Solve a puzzle in under 1 minute", progress: (stats?.fastestCompletionTime ?? .infinity) < 60 ? 1 : 0, target: 1)
            }

            VStack(spacing: 0) {
                achievementRow(icon: "square.grid.3x3.fill", title: "Standard solver", subtitle: "Complete a Standard puzzle", progress: hasSolvedDifficulty(.standard) ? 1 : 0, target: 1)
                Divider().padding(.leading, 44)
                achievementRow(icon: "square.grid.3x3.fill", title: "Advanced solver", subtitle: "Complete an Advanced puzzle", progress: hasSolvedDifficulty(.advanced) ? 1 : 0, target: 1)
                Divider().padding(.leading, 44)
                achievementRow(icon: "square.grid.3x3.fill", title: "Expert solver", subtitle: "Complete an Expert puzzle", progress: hasSolvedDifficulty(.expert) ? 1 : 0, target: 1)
                Divider().padding(.leading, 44)
                achievementRow(icon: "sparkles", title: "Daily sweep", subtitle: "Complete all 3 daily puzzles", progress: allDailySolved ? 1 : 0, target: 1)
            }

            if (stats?.totalHintsUsed ?? 0) >= 1 {
                VStack(spacing: 0) {
                    achievementRow(icon: "lightbulb.fill", title: "Hint helper", subtitle: "Use a hint", progress: stats?.totalHintsUsed ?? 0, target: 1)
                    if (stats?.totalHintsUsed ?? 0) >= 100 {
                        Divider().padding(.leading, 44)
                        achievementRow(icon: "lightbulb.max.fill", title: "Hint master", subtitle: "Use 100 hints", progress: stats?.totalHintsUsed ?? 0, target: 100)
                    }
                }
            }
        }
        .padding(20)
        .adaptiveGlass(in: 16)
    }

    private func achievementRow(icon: String, title: LocalizedStringKey, subtitle: LocalizedStringKey, progress: Int, target: Int) -> some View {
        let completed = progress >= target

        return HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(completed ? Color.orange : Color.gray.opacity(0.3))
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(completed ? .semibold : .regular))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if completed {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
            } else {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                    Circle()
                        .trim(from: 0, to: min(1, Double(progress) / Double(target)))
                        .stroke(Theme.berryBlue, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 28, height: 28)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Settings Sheet

    private var settingsTab: some View {
        SettingsFormView(
            storeService: storeService,
            hintService: hintService,
            onShowWalkthrough: { showWalkthrough = true },
            onShowTutorial: { showTutorial = true }
        )
        .scrollContentBackground(.hidden)
        .background(Theme.backgroundGradient)
    }

    // MARK: - Helpers

    private var allDailySolved: Bool {
        Difficulty.allCases.allSatisfy { isDailySolved($0) }
    }

    private func hasSolvedDifficulty(_ difficulty: Difficulty) -> Bool {
        savedStates.contains { $0.difficulty == difficulty.rawValue && $0.solved }
    }

    private func dailyPuzzleKey(_ difficulty: Difficulty) -> String? {
        let date = Date.now
        guard let definition = puzzleStore.dailyPuzzle(date: date, difficulty: difficulty) else { return nil }
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        guard let data = try? encoder.encode(definition),
              let key = String(data: data, encoding: .utf8) else { return nil }
        return key
    }

    private func isDailySolved(_ difficulty: Difficulty) -> Bool {
        guard let key = dailyPuzzleKey(difficulty) else { return false }
        return savedStates.contains { $0.puzzleJSON == key && $0.solved }
    }

    private func isDailyInProgress(_ difficulty: Difficulty) -> Bool {
        guard let key = dailyPuzzleKey(difficulty) else { return false }
        return savedStates.contains { $0.puzzleJSON == key && !$0.solved }
    }

    private func isDailyHintUsed(_ difficulty: Difficulty) -> Bool {
        guard let key = dailyPuzzleKey(difficulty) else { return false }
        return savedStates.contains { $0.puzzleJSON == key && $0.solved && $0.hintCount > 0 }
    }

    private func updateWidgetData() {
        let defaults = UserDefaults(suiteName: "group.com.altthree.berroku")
        let solvedCount = Difficulty.allCases.filter { isDailySolved($0) }.count
        let hintFlags = Difficulty.allCases.map { isDailyHintUsed($0) ? "1" : "0" }.joined()
        defaults?.set(solvedCount, forKey: "widget.solvedCount")
        defaults?.set(stats?.currentStreak ?? 0, forKey: "widget.currentStreak")
        defaults?.set(hintFlags, forKey: "widget.hintFlags")
        WidgetCenter.shared.reloadAllTimelines()
    }

}

#Preview {
    HomeView()
        .modelContainer(for: [GameState.self, PlayerStats.self], inMemory: true)
}
