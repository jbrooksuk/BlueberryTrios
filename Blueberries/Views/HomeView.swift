import SwiftUI
import SwiftData
import StoreKit

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var savedStates: [GameState]
    @Query private var statsRecords: [PlayerStats]

    @State private var storeService = StoreKitService()
    @State private var gameCenterService = GameCenterService()
    @State private var puzzleStore = PuzzleStore()
    @State private var navigateToGame = false
    @State private var selectedSource: PuzzleSource = .daily
    @State private var selectedDifficulty: Difficulty = .standard

    private var stats: PlayerStats {
        if let existing = statsRecords.first { return existing }
        let new = PlayerStats()
        modelContext.insert(new)
        return new
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Daily puzzle card
                    dailyPuzzleCard

                    // Pro puzzles card
                    proPuzzlesCard

                    // Stats card
                    statsCard

                    // Achievements card
                    achievementsCard
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Blueberry Trio")
            .onAppear {
                gameCenterService.authenticate()
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

    // MARK: - Daily Puzzle Card

    private var dailyPuzzleCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Today's Puzzles", systemImage: "calendar")
                .font(.headline)

            HStack(spacing: 12) {
                ForEach(Difficulty.allCases) { diff in
                    let solved = isDailySolved(diff)
                    Button {
                        selectedSource = .daily
                        selectedDifficulty = diff
                        navigateToGame = true
                    } label: {
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(solved ? Color.green.opacity(0.15) : Theme.berryBlue.opacity(0.15))
                                    .frame(width: 48, height: 48)
                                if solved {
                                    Image(systemName: "checkmark")
                                        .font(.title3.bold())
                                        .foregroundStyle(.green)
                                } else {
                                    Text("\(diff.displayIndex)")
                                        .font(.title3.bold())
                                        .foregroundStyle(Theme.berryBlue)
                                }
                            }
                            Text(diff.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }

            if allDailySolved {
                Label("All daily puzzles complete!", systemImage: "star.fill")
                    .font(.subheadline)
                    .foregroundStyle(.orange)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Pro Puzzles Card

    private var proPuzzlesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Pro Puzzles", systemImage: "infinity")
                .font(.headline)

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
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
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
                        }
                        .buttonStyle(.borderedProminent)
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
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Stats Card

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Statistics", systemImage: "chart.bar.fill")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                statItem(value: "\(stats.totalPuzzlesCompleted)", label: "Puzzles Solved")
                statItem(value: stats.fastestCompletionTime.map { formatTime($0) } ?? "--:--", label: "Fastest Time")
                statItem(value: "\(stats.currentStreak)", label: "Current Streak")
                statItem(value: "\(stats.longestStreak)", label: "Best Streak")
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold().monospacedDigit())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Achievements Card

    private var achievementsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Achievements", systemImage: "trophy.fill")
                .font(.headline)

            VStack(spacing: 8) {
                achievementRow(
                    icon: "1.circle.fill",
                    title: "First Puzzle",
                    progress: stats.totalPuzzlesCompleted,
                    target: 1
                )
                achievementRow(
                    icon: "10.circle.fill",
                    title: "Dedicated",
                    progress: stats.totalPuzzlesCompleted,
                    target: 10
                )
                achievementRow(
                    icon: "star.circle.fill",
                    title: "Centurion",
                    progress: stats.totalPuzzlesCompleted,
                    target: 100
                )
                achievementRow(
                    icon: "crown.fill",
                    title: "Master",
                    progress: stats.totalPuzzlesCompleted,
                    target: 500
                )

                Divider()

                achievementRow(
                    icon: "flame.fill",
                    title: "On a Roll",
                    progress: stats.longestStreak,
                    target: 3
                )
                achievementRow(
                    icon: "flame.fill",
                    title: "Week Warrior",
                    progress: stats.longestStreak,
                    target: 7
                )
                achievementRow(
                    icon: "flame.fill",
                    title: "Berry Committed",
                    progress: stats.longestStreak,
                    target: 30
                )
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func achievementRow(icon: String, title: String, progress: Int, target: Int) -> some View {
        let completed = progress >= target

        return HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(completed ? Color.orange : Color.gray.opacity(0.4))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(completed ? .semibold : .regular))
                Text("\(min(progress, target))/\(target)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if completed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                ProgressView(value: Double(progress), total: Double(target))
                    .frame(width: 60)
            }
        }
    }

    // MARK: - Helpers

    private var allDailySolved: Bool {
        Difficulty.allCases.allSatisfy { isDailySolved($0) }
    }

    private func isDailySolved(_ difficulty: Difficulty) -> Bool {
        let date = Date()
        guard let definition = puzzleStore.dailyPuzzle(date: date, difficulty: difficulty) else { return false }
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        guard let data = try? encoder.encode(definition),
              let key = String(data: data, encoding: .utf8) else { return false }
        return savedStates.contains { $0.puzzleJSON == key && $0.solved }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [GameState.self, PlayerStats.self], inMemory: true)
}
