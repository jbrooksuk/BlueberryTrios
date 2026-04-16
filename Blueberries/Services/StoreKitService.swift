import Foundation
import StoreKit
import Observation

@MainActor
@Observable
final class StoreKitService {
    static let proProductID = "com.altthree.Berroku.pro"
    static let hintPackProductID = "com.altthree.Berroku.hints10"
    static let hintPackSize: Int = 10

    private(set) var proProduct: Product?
    private(set) var hintPackProduct: Product?
    private(set) var isProUnlocked: Bool = false

    /// Closure called when a verified hint-pack transaction arrives, either
    /// from an interactive purchase or from `Transaction.updates` (Ask to
    /// Buy, cross-device delivery). The argument is the number of hints to
    /// credit. The caller should persist the credit before returning —
    /// StoreKit finishes the transaction immediately after this closure
    /// returns, so anything not persisted by then is lost.
    var creditHintPack: ((Int) -> Void)?

    private var transactionListener: Task<Void, Never>?

    init() {
        transactionListener = listenForTransactions()
        Task {
            await loadProducts()
            await updatePurchaseStatus()
        }
    }

    func loadProducts() async {
        do {
            let products = try await Product.products(for: [Self.proProductID, Self.hintPackProductID])
            proProduct = products.first { $0.id == Self.proProductID }
            hintPackProduct = products.first { $0.id == Self.hintPackProductID }
        } catch {
            #if DEBUG
            print("Failed to load products: \(error)")
            #endif
        }
    }

    func purchasePro() async throws {
        guard let product = proProduct else { return }
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            isProUnlocked = true
        case .userCancelled:
            break
        case .pending:
            break
        @unknown default:
            break
        }
    }

    /// Purchases one hint pack. Returns `true` on a verified, credited
    /// success; `false` if the user cancelled, the purchase is pending
    /// (Ask to Buy), or the product isn't loaded. Throws on verification
    /// failure so the caller can surface an error.
    func purchaseHintPack() async throws -> Bool {
        guard let product = hintPackProduct else { return false }
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            creditHintPack?(Self.hintPackSize)
            await transaction.finish()
            return true
        case .userCancelled, .pending:
            return false
        @unknown default:
            return false
        }
    }

    func restorePurchases() async {
        // Only the non-consumable Pro unlock is restorable. Consumable
        // hint packs are spent once credited and are not restored.
        try? await AppStore.sync()
        await updatePurchaseStatus()
    }

    private func updatePurchaseStatus() async {
        var unlocked = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.proProductID {
                unlocked = true
                break
            }
        }
        isProUnlocked = unlocked
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task {
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else { continue }
                switch transaction.productID {
                case Self.proProductID:
                    await transaction.finish()
                    await updatePurchaseStatus()
                case Self.hintPackProductID:
                    creditHintPack?(Self.hintPackSize)
                    await transaction.finish()
                default:
                    await transaction.finish()
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    enum StoreError: Error {
        case failedVerification
    }
}
