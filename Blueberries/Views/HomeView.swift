import SwiftUI
import SwiftData
import StoreKit
import WidgetKit

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var savedStates: [GameState]
    @Query private var statsRecords: [PlayerStats]

    @State private var storeService = StoreKitService()
    @State private var gameCenterService = GameCenterService()
    private let puzzleStore = PuzzleStore()
    @State private var navigateToGame = false
    @State private var selectedSource: PuzzleSource = .daily
    @State private var selectedDifficulty: Difficulty = .standard

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
            ScrollView {
                VStack(spacing: 0) {
                    // Hero header
                    heroHeader
                        .padding(.bottom, 24)

                    GlassEffectContainer(spacing: 20) {
                        VStack(spacing: 20) {
                            dailyPuzzleCard
                            proPuzzlesCard
                            statsCard
                            calendarCard
                            achievementsCard
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
            .background(
                LinearGradient(
                    colors: [Theme.berryBlue.opacity(0.08), Color(.systemGroupedBackground)],
                    startPoint: .top,
                    endPoint: .center
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .task {
                ensureStats()
                gameCenterService.authenticate()
                updateWidgetData()
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

    private static let berryDecorations: [(opacity: Double, size: CGFloat, x: CGFloat, y: CGFloat)] = [
        (0.20, 16, -50, -20),
        (0.30, 20, 60, 10),
        (0.18, 14, -30, 25),
        (0.35, 22, 70, -15),
        (0.25, 18, -60, 20),
    ]

    private var heroHeader: some View {
        VStack(spacing: 12) {
            PhaseAnimator([false, true]) { phase in
                ZStack {
                    ForEach(0..<5, id: \.self) { i in
                        let d = Self.berryDecorations[i]
                        Circle()
                            .fill(Theme.berryBlue.opacity(d.opacity))
                            .frame(width: d.size)
                            .offset(x: d.x, y: d.y + (phase ? 4 : -4))
                    }

                    Circle()
                        .fill(Theme.berryBlue)
                        .frame(width: 72, height: 72)
                        .shadow(color: Theme.berryBlue.opacity(0.4), radius: 12, y: 4)
                        .overlay {
                            Image(systemName: "circle.grid.3x3.fill")
                                .font(.system(size: 30))
                                .foregroundStyle(.white)
                        }
                        .scaleEffect(phase ? 1.02 : 0.98)
                }
            } animation: { _ in
                .easeInOut(duration: 1.2)
            }
            .frame(height: 100)

            Text("Blueberry Trio")
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
                    Button {
                        selectedSource = .daily
                        selectedDifficulty = diff
                        navigateToGame = true
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(solved
                                          ? Color.green.opacity(0.15)
                                          : Theme.berryBlue.opacity(0.1))
                                    .frame(width: 56, height: 56)

                                if solved {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(.green)
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
                                .foregroundStyle(solved ? .green : .primary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(20)
        .glassEffect(in: .rect(cornerRadius: 16))
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
                .buttonStyle(.glassProminent)
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
                        .buttonStyle(.glassProminent)
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
                    .buttonStyle(.glass)
                    .font(.subheadline)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(in: .rect(cornerRadius: 16))
    }

    // MARK: - Stats Card

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Statistics", systemImage: "chart.bar.fill")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                statItem(value: "\(stats?.totalPuzzlesCompleted ?? 0)", label: "Puzzles Solved", icon: "puzzlepiece.fill")
                statItem(value: stats?.fastestCompletionTime?.formattedAsTimer ?? "--:--", label: "Fastest Time", icon: "bolt.fill")
                statItem(value: "\(stats?.currentStreak ?? 0)", label: "Current Streak", icon: "flame.fill")
                statItem(value: "\(stats?.longestStreak ?? 0)", label: "Best Streak", icon: "trophy.fill")
            }
        }
        .padding(20)
        .glassEffect(in: .rect(cornerRadius: 16))
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

    // MARK: - Calendar Card

    private var calendarCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Activity", systemImage: "calendar")
                .font(.headline)

            PuzzleCalendarView(savedStates: savedStates)
        }
        .padding(20)
        .glassEffect(in: .rect(cornerRadius: 16))
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
        }
        .padding(20)
        .glassEffect(in: .rect(cornerRadius: 16))
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

    // MARK: - Helpers

    private var allDailySolved: Bool {
        Difficulty.allCases.allSatisfy { isDailySolved($0) }
    }

    private func isDailySolved(_ difficulty: Difficulty) -> Bool {
        let date = Date.now
        guard let definition = puzzleStore.dailyPuzzle(date: date, difficulty: difficulty) else { return false }
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        guard let data = try? encoder.encode(definition),
              let key = String(data: data, encoding: .utf8) else { return false }
        return savedStates.contains { $0.puzzleJSON == key && $0.solved }
    }

    private func updateWidgetData() {
        let defaults = UserDefaults(suiteName: "group.com.alt-three.Blueberries")
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
