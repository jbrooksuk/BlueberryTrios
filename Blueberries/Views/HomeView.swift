import SwiftUI
import SwiftData
import StoreKit
import WidgetKit

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
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
    @AppStorage("hasCompletedTutorial") private var hasCompletedTutorial: Bool = false
    @State private var showTutorial: Bool = false
    @State private var currentDay: Date = Calendar.current.startOfDay(for: .now)


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
        let inProgressPuzzle = currentInProgressPuzzle
        return TabView(selection: $selectedTab) {
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
        .inProgressGameAccessory(visible: inProgressPuzzle != nil && !navigateToGame) {
            if let inProgressPuzzle {
                gameAccessoryContent(for: inProgressPuzzle)
            }
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
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                let today = Calendar.current.startOfDay(for: .now)
                if today != currentDay {
                    currentDay = today
                    updateWidgetData()
                }
            }
        }
        .task(id: currentDay) {
            let calendar = Calendar.current
            let now = Date.now
            let nextMidnight = calendar.nextDate(
                after: now,
                matching: DateComponents(hour: 0, minute: 0, second: 0),
                matchingPolicy: .nextTime
            ) ?? now.addingTimeInterval(86400)
            let interval = max(1, nextMidnight.timeIntervalSince(now))
            try? await Task.sleep(for: .seconds(interval))
            if Task.isCancelled { return }
            let today = calendar.startOfDay(for: .now)
            if today != currentDay {
                currentDay = today
                updateWidgetData()
            }
        }
        .task {
            ensureStats()
            gameCenterService.authenticate()
            // Attach the grant handler before any purchase can start, so
            // both direct purchases and transactions redelivered by
            // StoreKit (pending approvals, prior-launch interruptions)
            // land in the same place.
            storeService.onStreakRevivalPurchased = { applyStreakRevival() }
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
                            if last7DaysCompletion.contains(true) {
                                streakBanner
                            }
                            if shouldOfferStreakRevival {
                                streakRevivalCard
                            }
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
                    initialSource: selectedSource,
                    initialDifficulty: selectedDifficulty
                )
            }
        }
    }

    private var achievementsTab: some View {
        ScrollView {
            VStack(spacing: 24) {
                achievementsHero
                achievementsStatsCard
                achievementsBadgeGrid
            }
            .frame(maxWidth: 600)
            .padding(20)
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
                .font(.system(.largeTitle, design: .serif).weight(.bold))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

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

    // MARK: - In-progress Game Accessory (iOS 26+)

    private struct InProgressPuzzleSummary: Equatable {
        let source: PuzzleSource
        let difficulty: Difficulty
        let elapsedTime: TimeInterval
    }

    /// The most recently played unfinished puzzle to surface in the tab
    /// bar accessory. Restricted to today's daily puzzles so a stale
    /// daily from a previous day doesn't dangle in the bar forever; Pro
    /// is excluded for now because GameView's nav doesn't yet take a
    /// `proSetNumber` to disambiguate which set to resume.
    ///
    /// Sorted by `lastPlayedAt` so swapping between puzzles always
    /// surfaces the one the player just left, not the one with the
    /// most accumulated `elapsedTime`. Rows migrated from before V3
    /// have a `nil` timestamp and sort to the bottom (treated as
    /// distantPast) until the player touches them again.
    private var currentInProgressPuzzle: InProgressPuzzleSummary? {
        let today = todayString()
        return savedStates
            .filter { state in
                !state.solved
                    && state.elapsedTime > 0
                    && state.source == PuzzleSource.daily.rawValue
                    && state.dateString == today
            }
            .compactMap { state -> (InProgressPuzzleSummary, Date)? in
                guard let difficulty = Difficulty(rawValue: state.difficulty) else { return nil }
                let summary = InProgressPuzzleSummary(source: .daily, difficulty: difficulty, elapsedTime: state.elapsedTime)
                return (summary, state.lastPlayedAt ?? .distantPast)
            }
            .max { $0.1 < $1.1 }?
            .0
    }

    @ViewBuilder
    private func gameAccessoryContent(for puzzle: InProgressPuzzleSummary) -> some View {
        if #available(iOS 26.0, *) {
            InProgressGameAccessoryView(
                displayIndex: puzzle.difficulty.displayIndex,
                difficultyName: puzzle.difficulty.rawValue,
                elapsedTime: puzzle.elapsedTime
            ) {
                selectedSource = puzzle.source
                selectedDifficulty = puzzle.difficulty
                selectedTab = .home
                navigateToGame = true
            }
        }
    }

    // MARK: - Streak Banner

    /// Whether the player completed any puzzle on each of the last 7 days,
    /// from oldest (index 0, 6 days ago) to newest (index 6, today).
    private var last7DaysCompletion: [Bool] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let completedDays: Set<Date> = Set(
            savedStates.compactMap { state in
                guard state.solved, let date = state.completionDate else { return nil }
                return calendar.startOfDay(for: date)
            }
        )
        return (0..<7).map { offset in
            guard let day = calendar.date(byAdding: .day, value: offset - 6, to: today) else {
                return false
            }
            return completedDays.contains(day)
        }
    }

    private var streakBanner: some View {
        let days = last7DaysCompletion
        let todayFilled = days.last ?? false

        return HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.18))
                    .frame(width: 44, height: 44)
                Image(systemName: "flame.fill")
                    .font(.title3)
                    .foregroundStyle(.orange)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("7-day streak")
                    .font(.headline)
                Text(todayFilled ? "Streak going strong!" : "Solve today to keep it going")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            HStack(spacing: 5) {
                ForEach(0..<7, id: \.self) { i in
                    Circle()
                        .fill(days[6 - i] ? Color.orange : Color.clear)
                        .overlay(Circle().stroke(Color.orange, lineWidth: 1.5))
                        .frame(width: 9, height: 9)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color.orange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.4), lineWidth: 1.5)
        )
        .accessibilityElement(children: .combine)
    }

    // MARK: - Streak Revival Card

    /// Offer Berry Revival only when there is actually a dead streak to
    /// revive: the player has completed a puzzle before, but the streak
    /// has lapsed (no completion today or yesterday). Hidden while the
    /// product hasn't loaded — there's nothing to sell without a price.
    private var shouldOfferStreakRevival: Bool {
        guard let stats, stats.lastPlayedDate != nil else { return false }
        return stats.effectiveCurrentStreak == 0 && storeService.streakRevivalProduct != nil
    }

    @ViewBuilder
    private var streakRevivalCard: some View {
        if let product = storeService.streakRevivalProduct {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.18))
                        .frame(width: 44, height: 44)
                    Image(systemName: "arrow.clockwise.heart.fill")
                        .font(.title3)
                        .foregroundStyle(.orange)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Berry Revival")
                        .font(.headline)
                    Text("Your streak went cold. Revive it at 7 days.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Button {
                    Task { try? await storeService.purchaseStreakRevival() }
                } label: {
                    Text(verbatim: product.displayPrice)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(Color.orange)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Buy Berry Revival for \(product.displayPrice)")
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(Color.orange.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.orange.opacity(0.4), lineWidth: 1.5)
            )
        }
    }

    /// Grants a purchased Berry Revival: bumps the streak back to 7 days,
    /// persists, reports the Game Center achievement, and refreshes the
    /// widget's streak snapshot. Idempotent enough that a double delivery
    /// of the same transaction only re-sets an already-revived streak.
    private func applyStreakRevival() {
        ensureStats()
        var descriptor = FetchDescriptor<PlayerStats>()
        descriptor.fetchLimit = 1
        guard let stats = ((try? modelContext.fetch(descriptor)) ?? []).first else { return }
        stats.restoreStreak()
        do {
            try modelContext.save()
        } catch {
            assertionFailure("Failed to save streak revival: \(error)")
        }
        gameCenterService.reportStreakRevival()
        updateWidgetData()
    }

    // MARK: - Daily Puzzle Card

    private var dailyPuzzleCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Today's puzzles", systemImage: "calendar")
                    .font(.headline)
                    .foregroundStyle(Theme.berryBlue)
                Spacer()
                let solvedCount = Difficulty.allCases.filter { isDailySolved($0) }.count
                Text("\(solvedCount) / 3 solved")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            VStack(spacing: 14) {
                ForEach(Difficulty.allCases) { diff in
                    dailyPuzzleRow(diff)
                }
            }
        }
        .padding(20)
        .adaptiveGlass(in: 16)
    }

    @ViewBuilder
    private func dailyPuzzleRow(_ difficulty: Difficulty) -> some View {
        let solved = isDailySolved(difficulty)
        let inProgress = isDailyInProgress(difficulty)
        let hinted = isDailyHintUsed(difficulty)
        let elapsed = dailyElapsedTime(difficulty)

        let row = HStack(spacing: 14) {
            dailyRowIcon(difficulty: difficulty, solved: solved, inProgress: inProgress, hinted: hinted)

            VStack(alignment: .leading, spacing: 2) {
                Text(difficulty.rawValue)
                    .font(.headline)
                Text(dailyRowSubtitle(difficulty: difficulty, solved: solved, inProgress: inProgress, elapsed: elapsed))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            dailyRowAction(solved: solved, inProgress: inProgress)
        }
        .contentShape(Rectangle())

        Button {
            selectedSource = .daily
            selectedDifficulty = difficulty
            navigateToGame = true
        } label: {
            row
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func dailyRowIcon(difficulty: Difficulty, solved: Bool, inProgress: Bool, hinted: Bool) -> some View {
        let size: CGFloat = 56
        let radius: CGFloat = 14

        if solved && hinted {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(Color.orange)
                .frame(width: size, height: size)
                .overlay {
                    Image(systemName: "lightbulb.fill")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                }
        } else if solved {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(Color.green)
                .frame(width: size, height: size)
                .overlay {
                    Image(systemName: "checkmark.circle")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                }
        } else if inProgress {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(Theme.berryBlue)
                .frame(width: size, height: size)
                .overlay {
                    Text("\(difficulty.displayIndex)")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                }
        } else {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(Theme.berryBlue.opacity(0.1))
                .overlay {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .stroke(Theme.berryBlue.opacity(0.3), lineWidth: 1.5)
                }
                .frame(width: size, height: size)
                .overlay {
                    Text("\(difficulty.displayIndex)")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Theme.berryBlue)
                }
        }
    }

    @ViewBuilder
    private func dailyRowAction(solved: Bool, inProgress: Bool) -> some View {
        if solved {
            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary.opacity(0.5))
                .padding(.trailing, 6)
        } else {
            HStack(spacing: 4) {
                Text(inProgress ? "Continue" : "Play")
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.bold))
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(Theme.berryBlue)
            .clipShape(Capsule())
        }
    }

    private func dailyRowSubtitle(difficulty: Difficulty, solved: Bool, inProgress: Bool, elapsed: TimeInterval?) -> String {
        if solved, let elapsed {
            return "Solved in \(elapsed.formattedAsTimer)"
        } else if solved {
            return "Solved"
        } else if inProgress {
            return "In progress"
        } else {
            switch difficulty {
            case .standard: return "Easy"
            case .advanced: return "Medium"
            case .expert: return "Hard"
            }
        }
    }

    private func dailyElapsedTime(_ difficulty: Difficulty) -> TimeInterval? {
        guard let key = dailyPuzzleKey(difficulty) else { return nil }
        return savedStates.first { isTodaysDailyState($0, key: key) && $0.solved }?.elapsedTime
    }

    // MARK: - Pro Puzzles Card

    @ViewBuilder
    private var proPuzzlesCard: some View {
        if storeService.isProUnlocked {
            unlockedProCard
        } else {
            promotionalProCard
        }
    }

    private var unlockedProCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Pro puzzles", systemImage: "infinity")
                    .font(.headline)
                Spacer()
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.green)
            }

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
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .adaptiveGlass(in: 16)
    }

    private var promotionalProCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Label("Berroku Pro", systemImage: "infinity")
                    .font(.headline)
            }
            .foregroundStyle(.white.opacity(0.92))

            Text("An endless berry patch")
                .font(.system(.largeTitle, design: .serif).weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Text("Unlimited puzzle sets beyond the daily three. One-time purchase.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                if let product = storeService.proProduct {
                    Button {
                        Task { try? await storeService.purchasePro() }
                    } label: {
                        Text("Unlock for \(product.displayPrice)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.berryBlue)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                } else {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.white)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 12)
                }

                Button {
                    Task { await storeService.restorePurchases() }
                } label: {
                    Text("Restore")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 12)
                        .overlay {
                            Capsule()
                                .stroke(Color.white.opacity(0.55), lineWidth: 1.5)
                        }
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 4)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Theme.berryBlue.opacity(0.95), Theme.berryBlue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
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

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(Difficulty.allCases) { diff in
                        statItem(
                            value: "\(completedCount(for: diff))",
                            label: LocalizedStringKey(diff.rawValue),
                            icon: "\(diff.displayIndex).circle.fill"
                        )
                    }
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

    private struct AchievementInfo: Identifiable {
        let id: String
        let icon: String
        let title: LocalizedStringKey
        let subtitle: LocalizedStringKey
        let progress: Int
        let target: Int
        let color: Color
        var earned: Bool { progress >= target }
    }

    private var allAchievements: [AchievementInfo] {
        let totalPuzzles = stats?.totalPuzzlesCompleted ?? 0
        let longestStreak = stats?.longestStreak ?? 0
        let fastest = stats?.fastestCompletionTime ?? .infinity
        let totalHints = stats?.totalHintsUsed ?? 0
        let bestFlawless = stats?.bestFlawlessStreak ?? 0
        let bestSweep = stats?.bestDailySweepStreak ?? 0
        let proCompleted = stats?.proPuzzlesCompleted ?? 0
        let solvedEarly = stats?.hasSolvedEarly ?? false
        let streaksRestored = stats?.streaksRestored ?? 0

        return [
            AchievementInfo(id: "first", icon: "1.circle.fill", title: "First puzzle", subtitle: "Complete your first puzzle", progress: totalPuzzles, target: 1, color: Theme.berryBlue),
            AchievementInfo(id: "dedicated", icon: "10.circle.fill", title: "Dedicated", subtitle: "Complete 10 puzzles", progress: totalPuzzles, target: 10, color: .teal),
            AchievementInfo(id: "centurion", icon: "star.circle.fill", title: "Centurion", subtitle: "Complete 100 puzzles", progress: totalPuzzles, target: 100, color: .indigo),
            AchievementInfo(id: "master", icon: "crown.fill", title: "Master", subtitle: "Complete 500 puzzles", progress: totalPuzzles, target: 500, color: .purple),
            AchievementInfo(id: "roll", icon: "flame.fill", title: "On a roll", subtitle: "3-day streak", progress: longestStreak, target: 3, color: .pink),
            AchievementInfo(id: "week", icon: "flame.fill", title: "Week warrior", subtitle: "7-day streak", progress: longestStreak, target: 7, color: .red),
            AchievementInfo(id: "committed", icon: "flame.fill", title: "Berry committed", subtitle: "30-day streak", progress: longestStreak, target: 30, color: .brown),
            AchievementInfo(id: "revival", icon: "arrow.clockwise.heart.fill", title: "Back from the brink", subtitle: "Revive a lost streak with Berry Revival", progress: streaksRestored, target: 1, color: .orange),
            AchievementInfo(id: "speed", icon: "bolt.fill", title: "Speed demon", subtitle: "Solve a puzzle in under 1 minute", progress: fastest < 60 ? 1 : 0, target: 1, color: .yellow),
            AchievementInfo(id: "lightning", icon: "hare.fill", title: "Lightning", subtitle: "Solve a puzzle in under 30 seconds", progress: fastest < 30 ? 1 : 0, target: 1, color: .orange),
            AchievementInfo(id: "standard", icon: "square.grid.3x3.fill", title: "Standard solver", subtitle: "Complete a Standard puzzle", progress: hasSolvedDifficulty(.standard) ? 1 : 0, target: 1, color: .green),
            AchievementInfo(id: "advanced", icon: "square.grid.3x3.fill", title: "Advanced solver", subtitle: "Complete an Advanced puzzle", progress: hasSolvedDifficulty(.advanced) ? 1 : 0, target: 1, color: .mint),
            AchievementInfo(id: "expert", icon: "square.grid.3x3.fill", title: "Expert solver", subtitle: "Complete an Expert puzzle", progress: hasSolvedDifficulty(.expert) ? 1 : 0, target: 1, color: .cyan),
            AchievementInfo(id: "sweep", icon: "sparkles", title: "Daily sweep", subtitle: "Complete all 3 daily puzzles", progress: hasEverSweptDaily ? 1 : 0, target: 1, color: .pink),
            AchievementInfo(id: "hintHelper", icon: "lightbulb.fill", title: "Hint helper", subtitle: "Use a hint", progress: totalHints, target: 1, color: .yellow),
            AchievementInfo(id: "hintMaster", icon: "lightbulb.max.fill", title: "Hint master", subtitle: "Use 100 hints", progress: totalHints, target: 100, color: .brown),
            AchievementInfo(id: "flawless", icon: "checkmark.seal.fill", title: "Flawless solver", subtitle: "Solve a puzzle with no hints or mistakes", progress: bestFlawless, target: 1, color: .green),
            AchievementInfo(id: "perfectionist", icon: "rosette", title: "Perfectionist", subtitle: "10 flawless solves in a row", progress: bestFlawless, target: 10, color: .indigo),
            AchievementInfo(id: "earlyBird", icon: "sunrise.fill", title: "Early bird", subtitle: "Solve a puzzle before 6 AM", progress: solvedEarly ? 1 : 0, target: 1, color: .yellow),
            AchievementInfo(id: "marathon", icon: "figure.run", title: "Marathon", subtitle: "Sweep the daily puzzles 7 days running", progress: bestSweep, target: 7, color: .red),
            AchievementInfo(id: "proExplorer", icon: "map.fill", title: "Pro explorer", subtitle: "Complete 50 Pro puzzles", progress: proCompleted, target: 50, color: .purple),
        ]
    }

    private var achievementsHero: some View {
        let achievements = allAchievements
        let earned = achievements.filter(\.earned).count
        let total = achievements.count

        return HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(earned)")
                        .font(.system(.largeTitle, design: .serif).weight(.bold))
                    Text("/ \(total)")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                Text("Achievements earned")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Theme.berryBlue)
                .frame(width: 64, height: 64)
                .overlay {
                    Image(systemName: "trophy.fill")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var achievementsStatsCard: some View {
        let solved = stats?.totalPuzzlesCompleted ?? 0
        let streak = stats?.effectiveCurrentStreak ?? 0
        let fastest = stats?.fastestCompletionTime?.formattedAsTimer ?? "—"

        return HStack(spacing: 0) {
            achievementsStatColumn(value: "\(solved)", label: "Solved")
            Divider().frame(height: 36)
            achievementsStatColumn(value: "\(streak)", label: "Day streak")
            Divider().frame(height: 36)
            achievementsStatColumn(value: fastest, label: "Fastest")
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .adaptiveGlass(in: 16)
    }

    private func achievementsStatColumn(value: String, label: LocalizedStringKey) -> some View {
        VStack(spacing: 4) {
            Text(verbatim: value)
                .font(.system(.title2, design: .serif).weight(.bold))
                .monospacedDigit()
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var achievementsBadgeGrid: some View {
        let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
        ]

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("Achievements")
                    .font(.title3.bold())
                Spacer()
                Text("Earn them all")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(allAchievements) { info in
                    achievementBadge(info)
                }
            }
        }
    }

    private func achievementBadge(_ info: AchievementInfo) -> some View {
        let progressFraction = info.target > 0 ? min(1, Double(info.progress) / Double(info.target)) : 0

        return VStack(spacing: 10) {
            ZStack {
                if info.target > 1 {
                    Circle()
                        .stroke(Theme.berryBlue.opacity(0.15), lineWidth: 3)
                    Circle()
                        .trim(from: 0, to: progressFraction)
                        .stroke(Theme.berryBlue, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                Circle()
                    .fill(info.earned ? info.color : Color.secondary.opacity(0.18))
                    .padding(6)
                    .overlay {
                        Image(systemName: info.icon)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                    }
            }
            .frame(width: 60, height: 60)

            VStack(spacing: 2) {
                Text(info.title)
                    .font(.footnote.weight(.bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(info.earned ? .primary : .secondary)
                Text(info.subtitle)
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                if !info.earned && info.target > 1 {
                    Text("\(Int(progressFraction * 100))%")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Theme.berryBlue)
                        .padding(.top, 2)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 6)
        .frame(minHeight: 165, alignment: .top)
        .adaptiveGlass(in: 14)
        .opacity(info.earned ? 1 : 0.7)
    }

    // MARK: - Settings Sheet

    private var settingsTab: some View {
        SettingsFormView(
            storeService: storeService,
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

    /// True if the player has, on any past day, completed all three daily
    /// difficulties hint-free. Mirrors the Game Center `dailySweep` criterion
    /// so the local achievement row stays ticked once earned, instead of
    /// resetting at midnight when today's saved states stop matching.
    private var hasEverSweptDaily: Bool {
        let solved = savedStates.filter {
            $0.source == PuzzleSource.daily.rawValue && $0.solved && $0.hintCount == 0
        }
        let requiredDifficulties = Set(Difficulty.allCases.map(\.rawValue))
        let byDate = Dictionary(grouping: solved, by: \.dateString)
        return byDate.values.contains { dayStates in
            Set(dayStates.map(\.difficulty)).isSuperset(of: requiredDifficulties)
        }
    }

    private func hasSolvedDifficulty(_ difficulty: Difficulty) -> Bool {
        savedStates.contains { $0.difficulty == difficulty.rawValue && $0.solved }
    }

    private func completedCount(for difficulty: Difficulty) -> Int {
        savedStates.reduce(into: 0) { count, state in
            if state.difficulty == difficulty.rawValue && state.solved {
                count += 1
            }
        }
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

    private func todayString() -> String {
        let cal = Calendar.current
        let d = Date.now
        return "\(cal.component(.day, from: d)) \(cal.component(.month, from: d)) \(cal.component(.year, from: d))"
    }

    /// The daily puzzle list has fewer entries than there are days, so two
    /// separate days can legitimately hash to the same `PuzzleDefinition` and
    /// serialise to the same `puzzleJSON`. Match on the (date, source) tuple
    /// too so a past-day solve of an identical puzzle doesn't mark today's
    /// card as completed.
    private func isTodaysDailyState(_ state: GameState, key: String) -> Bool {
        state.puzzleJSON == key
            && state.source == PuzzleSource.daily.rawValue
            && state.dateString == todayString()
    }

    private func isDailySolved(_ difficulty: Difficulty) -> Bool {
        guard let key = dailyPuzzleKey(difficulty) else { return false }
        return savedStates.contains { isTodaysDailyState($0, key: key) && $0.solved }
    }

    private func isDailyInProgress(_ difficulty: Difficulty) -> Bool {
        guard let key = dailyPuzzleKey(difficulty) else { return false }
        return savedStates.contains { isTodaysDailyState($0, key: key) && !$0.solved }
    }

    private func isDailyHintUsed(_ difficulty: Difficulty) -> Bool {
        guard let key = dailyPuzzleKey(difficulty) else { return false }
        return savedStates.contains { isTodaysDailyState($0, key: key) && $0.solved && $0.hintCount > 0 }
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

private extension View {
    /// Attaches a `tabViewBottomAccessory` on iOS 26+ when `visible` is
    /// true. Older OSes fall through and ignore the accessory entirely.
    @ViewBuilder
    func inProgressGameAccessory<Content: View>(visible: Bool, @ViewBuilder content: () -> Content) -> some View {
        if #available(iOS 26.0, *), visible {
            self.tabViewBottomAccessory(content: content)
        } else {
            self
        }
    }
}

/// In-progress puzzle accessory rendered inside `tabViewBottomAccessory`.
///
/// Reads `\.tabViewBottomAccessoryPlacement` so the layout collapses to a
/// pill (badge + timer) when the system minimises the bar (typically on
/// scroll), and expands to the full row otherwise.
@available(iOS 26.0, *)
private struct InProgressGameAccessoryView: View {
    let displayIndex: Int
    let difficultyName: String
    let elapsedTime: TimeInterval
    let onTap: () -> Void

    @Environment(\.tabViewBottomAccessoryPlacement) private var placement

    var body: some View {
        Button(action: onTap) {
            Group {
                if placement == .inline {
                    inlineContent
                } else {
                    expandedContent
                }
            }
            .frame(maxWidth: .infinity)
            // Ensure scrolling content (e.g. the berryBlue Pro card)
            // doesn't bleed through the bar's translucent glass.
            .background(Color(.systemBackground))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var expandedContent: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Theme.berryBlue)
                    .frame(width: 32, height: 32)
                Text("\(displayIndex)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 0) {
                Text("Today's \(difficultyName)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(elapsedTime.formattedAsTimer)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            Spacer(minLength: 8)

            Image(systemName: "play.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.berryBlue)
                .padding(.trailing, 4)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    private var inlineContent: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Theme.berryBlue)
                    .frame(width: 22, height: 22)
                Text("\(displayIndex)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
            }

            Text(elapsedTime.formattedAsTimer)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .monospacedDigit()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}
