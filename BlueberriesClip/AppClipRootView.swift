import SwiftUI
import StoreKit

struct AppClipRootView: View {
    @Bindable var invocation: AppClipInvocation
    @State private var model: PuzzleModel?
    @State private var timer = GameTimer()
    @State private var store: PuzzleStore?
    @State private var showAppStoreOverlay = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient.ignoresSafeArea()

                if let model {
                    puzzleContent(model: model)
                } else {
                    ProgressView("Loading puzzle…")
                }
            }
            .navigationTitle("Berroku")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Text(timer.elapsedTime.formattedAsTimer)
                        .font(.body.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .task {
            await loadPuzzle()
        }
        .onChange(of: invocation.difficulty) {
            Task { await loadPuzzle() }
        }
        .onChange(of: model?.isSolved) { _, isSolved in
            if isSolved == true {
                timer.stop()
                showAppStoreOverlay = true
            }
        }
        .appStoreOverlay(isPresented: $showAppStoreOverlay) {
            SKOverlay.AppClipConfiguration(position: .bottom)
        }
    }

    @ViewBuilder
    private func puzzleContent(model: PuzzleModel) -> some View {
        VStack(spacing: 16) {
            PuzzleGridView(
                model: model,
                autoCheck: true,
                hapticsEnabled: true
            )
            .padding(.horizontal, 16)

            if model.isSolved {
                solvedFooter
            } else {
                hintFooter
            }
        }
        .padding(.vertical, 16)
    }

    private var hintFooter: some View {
        VStack(spacing: 4) {
            Text("Place 3 berries in every row, column & block")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text("Numbers count berries in the 8 surrounding cells")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
    }

    private var solvedFooter: some View {
        VStack(spacing: 12) {
            Label("Solved!", systemImage: "checkmark.seal.fill")
                .font(.title2.bold())
                .foregroundStyle(.green)

            Button {
                showAppStoreOverlay = true
            } label: {
                Label("Get Berroku", systemImage: "arrow.down.app.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.berryBlue)
            .padding(.horizontal, 24)
        }
    }

    private func loadPuzzle() async {
        let store = store ?? PuzzleStore()
        self.store = store
        let definition = store.dailyPuzzle(date: .now, difficulty: invocation.difficulty)
        guard let definition else { return }
        let newModel = PuzzleModel(definition: definition)
        self.model = newModel
        timer.reset()
        timer.start()
    }
}
