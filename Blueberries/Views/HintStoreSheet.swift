import SwiftUI
import StoreKit

/// Sheet presented when the player taps Hint but has no hints remaining.
/// Shows remaining daily hints, bonus balance, and purchasable refill packs.
struct HintStoreSheet: View {
    @Environment(\.dismiss) private var dismiss
    var storeService: StoreKitService
    var hintService: HintService

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Current balance
                VStack(spacing: 8) {
                    Image(systemName: "lightbulb.slash")
                        .font(.system(size: 48))
                        .foregroundStyle(Theme.berryBlue)

                    Text("Out of hints")
                        .font(.title2.bold())

                    Text("You get \(HintService.dailyFreeHints) free hints each day. Buy extra hints to keep going.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 8)

                // Balance summary
                HStack(spacing: 24) {
                    VStack(spacing: 4) {
                        Text("\(hintService.dailyHintsRemaining)")
                            .font(.title.bold().monospacedDigit())
                        Text("Daily")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Divider().frame(height: 40)
                    VStack(spacing: 4) {
                        Text("\(hintService.bonusHints)")
                            .font(.title.bold().monospacedDigit())
                        Text("Bonus")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Theme.berryBlue.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Purchase options
                VStack(spacing: 12) {
                    ForEach(storeService.sortedHintProducts, id: \.id) { product in
                        Button {
                            Task {
                                try? await storeService.purchaseHints(productID: product.id)
                                if hintService.canUseHint {
                                    dismiss()
                                }
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(product.displayName)
                                        .font(.headline)
                                    Text(product.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(product.displayPrice)
                                    .font(.subheadline.bold())
                            }
                            .padding()
                            .background(Theme.berryBlue.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }

                    if storeService.sortedHintProducts.isEmpty {
                        HStack {
                            ProgressView()
                                .controlSize(.small)
                            Text("Loading...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()
            }
            .padding(20)
            .navigationTitle("Get Hints")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
