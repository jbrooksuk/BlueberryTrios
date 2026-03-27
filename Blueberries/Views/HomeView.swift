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
    @State private var animateBerries = false

    private var stats: PlayerStats {
        if let existing = statsRecords.first { return existing }
        let new = PlayerStats()
        modelContext.insert(new)
        return new
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Hero header
                    heroHeader
                        .padding(.bottom, 24)

                    VStack(spacing: 20) {
                        dailyPuzzleCard
                        proPuzzlesCard
                        statsCard
                        achievementsCard
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
            .onAppear {
                gameCenterService.authenticate()
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    animateBerries = true
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

    private var heroHeader: some View {
        VStack(spacing: 12) {
            // Floating berries decoration
            ZStack {
                // Background berries scattered
                ForEach(0..<5, id: \.self) { i in
                    Circle()
                        .fill(Theme.berryBlue.opacity(Double.random(in: 0.15...0.35)))
                        .frame(width: CGFloat.random(in: 12...24))
                        .offset(
                            x: CGFloat([-50, 60, -30, 70, -60][i]),
                            y: CGFloat([-20, 10, 25, -15, 20][i]) + (animateBerries ? 4 : -4)
                        )
                }

                // Main berry icon
                Circle()
                    .fill(Theme.berryBlue)
                    .frame(width: 72, height: 72)
                    .shadow(color: Theme.berryBlue.opacity(0.4), radius: 12, y: 4)
                    .overlay {
                        Image(systemName: "circle.grid.3x3.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(.white)
                    }
                    .scaleEffect(animateBerries ? 1.02 : 0.98)
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
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
                .buttonStyle(.borderedProminent)
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
                    .font(.subheadline)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Stats Card

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Statistics", systemImage: "chart.bar.fill")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                statItem(value: "\(stats.totalPuzzlesCompleted)", label: "Puzzles Solved", icon: "puzzlepiece.fill")
                statItem(value: stats.fastestCompletionTime.map { formatTime($0) } ?? "--:--", label: "Fastest Time", icon: "bolt.fill")
                statItem(value: "\(stats.currentStreak)", label: "Current Streak", icon: "flame.fill")
                statItem(value: "\(stats.longestStreak)", label: "Best Streak", icon: "trophy.fill")
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func statItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Theme.berryBlue)
            Text(value)
                .font(.title2.bold().monospacedDigit())
            Text(label)
                .font(.caption2)
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
                achievementRow(icon: "1.circle.fill", title: "First Puzzle", subtitle: "Complete your first puzzle", progress: stats.totalPuzzlesCompleted, target: 1)
                Divider().padding(.leading, 44)
                achievementRow(icon: "10.circle.fill", title: "Dedicated", subtitle: "Complete 10 puzzles", progress: stats.totalPuzzlesCompleted, target: 10)
                Divider().padding(.leading, 44)
                achievementRow(icon: "star.circle.fill", title: "Centurion", subtitle: "Complete 100 puzzles", progress: stats.totalPuzzlesCompleted, target: 100)
                Divider().padding(.leading, 44)
                achievementRow(icon: "crown.fill", title: "Master", subtitle: "Complete 500 puzzles", progress: stats.totalPuzzlesCompleted, target: 500)
            }

            VStack(spacing: 0) {
                achievementRow(icon: "flame.fill", title: "On a Roll", subtitle: "3-day streak", progress: stats.longestStreak, target: 3)
                Divider().padding(.leading, 44)
                achievementRow(icon: "flame.fill", title: "Week Warrior", subtitle: "7-day streak", progress: stats.longestStreak, target: 7)
                Divider().padding(.leading, 44)
                achievementRow(icon: "flame.fill", title: "Berry Committed", subtitle: "30-day streak", progress: stats.longestStreak, target: 30)
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
                    .font(.caption2)
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
