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
    private let puzzleStore = PuzzleStore()
    @State private var navigateToGame = false
    @State private var selectedSource: PuzzleSource = .daily
    @State private var selectedDifficulty: Difficulty = .standard
    @State private var showCalendar: Bool = false
    @State private var showWalkthrough: Bool = false
    @State private var selectedTab: HomeTab = .home
    @AppStorage("hasSeenWalkthrough") private var hasSeenWalkthrough: Bool = false

    @AppStorage("autoCheck") private var autoCheck: Bool = true
    @AppStorage("showTimer") private var showTimer: Bool = true
    @AppStorage("fillHints") private var fillHints: Bool = false
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    @AppStorage("soundEnabled") private var soundEnabled: Bool = true

    private enum HomeTab: Hashable {
        case home, achievements, settings
    }

    private var stats: PlayerStats? {
        statsRecords.first
    }

    private func ensureStats() {
        if statsRecords.isEmpty {
            modelContext.insert(PlayerStats())
        }
    }

    var body: some View {
        NavigationStack {
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
                    .onDisappear { hasSeenWalkthrough = true }
            }
            .task {
                ensureStats()
                gameCenterService.authenticate()
                updateWidgetData()
                if !hasSeenWalkthrough {
                    showWalkthrough = true
                }
            }
            .navigationDestination(isPresented: $navigateToGame) {
                GameView(
                    storeService: storeService,
                    gameCenterService: gameCenterService,
                    puzzleStore: puzzleStore,
                    initialSource: selectedSource,
                    initialDifficulty: selectedDifficulty
                )
            }
        }
    }

    // MARK: - Hero Header

    // MARK: - Tabs

    private var homeTab: some View {
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
        .background(
            LinearGradient(
                colors: [Theme.berryBlue.opacity(0.08), Color(.systemGroupedBackground)],
                startPoint: .top,
                endPoint: .center
            )
        )
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
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Hero Header

    private var heroHeader: some View {
        VStack(spacing: 12) {
            Group {
                if reduceMotion {
                    ZStack {
                        BlueberryView(size: 48, expression: .smile)
                            .offset(x: -32, y: 0)
                            .rotationEffect(.degrees(-4))
                        BlueberryView(size: 44, expression: .wink)
                            .offset(x: 32, y: 0)
                            .rotationEffect(.degrees(6))
                        BlueberryView(size: 64, expression: .happy)
                            .shadow(color: Theme.berryBlue.opacity(0.3), radius: 8, y: 4)
                    }
                } else {
                    PhaseAnimator([false, true]) { phase in
                        ZStack {
                            BlueberryView(size: 48, expression: .smile)
                                .offset(x: -32, y: phase ? -6 : 2)
                                .rotationEffect(.degrees(phase ? -6 : -3))
                            BlueberryView(size: 44, expression: .wink)
                                .offset(x: 32, y: phase ? -4 : 4)
                                .rotationEffect(.degrees(phase ? 8 : 4))
                            BlueberryView(size: 64, expression: .happy)
                                .offset(x: 0, y: phase ? 4 : -4)
                                .shadow(color: Theme.berryBlue.opacity(0.3), radius: 8, y: 4)
                        }
                    } animation: { _ in .easeInOut(duration: 1.5) }
                }
            }
            .frame(height: 90)

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
                Label("Today's Puzzles", systemImage: "calendar")
                    .font(.headline)
                Spacer()
                let solvedCount = Difficulty.allCases.filter { isDailySolved($0) }.count
                Text("\(solvedCount)/3")
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(solvedCount == 3 ? .green : .secondary)
            }

            HStack(spacing: 0) {
                ForEach(Difficulty.allCases) { diff in
                    let solved = isDailySolved(diff)
                    let inProgress = isDailyInProgress(diff)
                    Button {
                        selectedSource = .daily
                        selectedDifficulty = diff
                        navigateToGame = true
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                if solved {
                                    Circle()
                                        .fill(Color.green.opacity(0.15))
                                        .frame(width: 56, height: 56)
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(.green)
                                } else if inProgress {
                                    Circle()
                                        .fill(Theme.berryBlue.opacity(0.5))
                                        .frame(width: 56, height: 56)
                                        .overlay {
                                            Text("\(diff.displayIndex)")
                                                .font(.title2.bold())
                                                .foregroundStyle(.white.opacity(0.8))
                                        }
                                        .overlay(alignment: .bottomTrailing) {
                                            Image(systemName: "clock.fill")
                                                .font(.system(size: 16))
                                                .foregroundStyle(.white)
                                                .background(
                                                    Circle()
                                                        .fill(Theme.berryBlue)
                                                        .frame(width: 22, height: 22)
                                                )
                                                .offset(x: 2, y: 2)
                                        }
                                } else {
                                    Circle()
                                        .fill(Theme.berryBlue)
                                        .frame(width: 56, height: 56)
                                        .overlay {
                                            Text("\(diff.displayIndex)")
                                                .font(.title2.bold())
                                                .foregroundStyle(.white)
                                        }
                                        .shadow(color: Theme.berryBlue.opacity(0.3), radius: 4, y: 2)
                                }
                            }

                            Text(diff.rawValue)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(solved ? .green : inProgress ? .secondary : .primary)
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
                Label("Pro Puzzles", systemImage: "infinity")
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
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    statItem(value: "\(stats?.totalPuzzlesCompleted ?? 0)", label: "Puzzles Solved", icon: "puzzlepiece.fill")
                    statItem(value: stats?.fastestCompletionTime?.formattedAsTimer ?? "--:--", label: "Fastest Time", icon: "bolt.fill")
                    statItem(value: "\(stats?.currentStreak ?? 0)", label: "Current Streak", icon: "flame.fill")
                    statItem(value: "\(stats?.longestStreak ?? 0)", label: "Best Streak", icon: "trophy.fill")
                }
            }
        }
        .padding(20)
        .adaptiveGlass(in: 16)
    }

    private func statItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Theme.berryBlue)
            Text(value)
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
                achievementRow(icon: "1.circle.fill", title: "First Puzzle", subtitle: "Complete your first puzzle", progress: stats?.totalPuzzlesCompleted ?? 0, target: 1)
                Divider().padding(.leading, 44)
                achievementRow(icon: "10.circle.fill", title: "Dedicated", subtitle: "Complete 10 puzzles", progress: stats?.totalPuzzlesCompleted ?? 0, target: 10)
                Divider().padding(.leading, 44)
                achievementRow(icon: "star.circle.fill", title: "Centurion", subtitle: "Complete 100 puzzles", progress: stats?.totalPuzzlesCompleted ?? 0, target: 100)
                Divider().padding(.leading, 44)
                achievementRow(icon: "crown.fill", title: "Master", subtitle: "Complete 500 puzzles", progress: stats?.totalPuzzlesCompleted ?? 0, target: 500)
            }

            VStack(spacing: 0) {
                achievementRow(icon: "flame.fill", title: "On a Roll", subtitle: "3-day streak", progress: stats?.longestStreak ?? 0, target: 3)
                Divider().padding(.leading, 44)
                achievementRow(icon: "flame.fill", title: "Week Warrior", subtitle: "7-day streak", progress: stats?.longestStreak ?? 0, target: 7)
                Divider().padding(.leading, 44)
                achievementRow(icon: "flame.fill", title: "Berry Committed", subtitle: "30-day streak", progress: stats?.longestStreak ?? 0, target: 30)
            }

            VStack(spacing: 0) {
                achievementRow(icon: "bolt.fill", title: "Speed Demon", subtitle: "Solve a puzzle in under 1 minute", progress: (stats?.fastestCompletionTime ?? .infinity) < 60 ? 1 : 0, target: 1)
            }

            VStack(spacing: 0) {
                achievementRow(icon: "square.grid.3x3.fill", title: "Standard Solver", subtitle: "Complete a Standard puzzle", progress: hasSolvedDifficulty(.standard) ? 1 : 0, target: 1)
                Divider().padding(.leading, 44)
                achievementRow(icon: "square.grid.3x3.fill", title: "Advanced Solver", subtitle: "Complete an Advanced puzzle", progress: hasSolvedDifficulty(.advanced) ? 1 : 0, target: 1)
                Divider().padding(.leading, 44)
                achievementRow(icon: "square.grid.3x3.fill", title: "Expert Solver", subtitle: "Complete an Expert puzzle", progress: hasSolvedDifficulty(.expert) ? 1 : 0, target: 1)
                Divider().padding(.leading, 44)
                achievementRow(icon: "sparkles", title: "Daily Sweep", subtitle: "Complete all 3 daily puzzles", progress: allDailySolved ? 1 : 0, target: 1)
            }
        }
        .padding(20)
        .adaptiveGlass(in: 16)
    }

    private func achievementRow(icon: String, title: String, subtitle: String, progress: Int, target: Int) -> some View {
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
        Form {
            Section("Gameplay") {
                Toggle("Auto Check", isOn: $autoCheck)
                Toggle("Show Timer", isOn: $showTimer)
                Toggle("Fill Hints", isOn: $fillHints)
                Toggle("Haptics", isOn: $hapticsEnabled)
                Toggle("Sound", isOn: $soundEnabled)
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
                    }
                    Button("Restore Purchases") {
                        Task { await storeService.restorePurchases() }
                    }
                }
            }
            Section("Help") {
                Button {
                    showWalkthrough = true
                } label: {
                    Label(String(localized: "Show walkthrough", comment: "Settings button to replay tutorial"), systemImage: "questionmark.circle")
                }
            }
            Section("Rules") {
                Text("Place 3 berries into each row, column, and block. Surround each number with the specified number of berries.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
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

    private func updateWidgetData() {
        let defaults = UserDefaults(suiteName: "group.com.altthree.berroku")
        let solvedCount = Difficulty.allCases.filter { isDailySolved($0) }.count
        defaults?.set(solvedCount, forKey: "widget.solvedCount")
        defaults?.set(stats?.currentStreak ?? 0, forKey: "widget.currentStreak")
        WidgetCenter.shared.reloadAllTimelines()
    }

}

#Preview {
    HomeView()
        .modelContainer(for: [GameState.self, PlayerStats.self], inMemory: true)
}
