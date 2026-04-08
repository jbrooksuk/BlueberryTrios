import Foundation
import StoreKit
import Observation

@MainActor
@Observable
final class StoreKitService {
    static let proProductID = "com.altthree.Berroku.pro"

    // Hint refill product IDs
    static let hints10ProductID = "com.altthree.Berroku.hints.10"
    static let hints30ProductID = "com.altthree.Berroku.hints.30"
    static let hintProductIDs: Set<String> = [hints10ProductID, hints30ProductID]

    /// All product IDs the app knows about.
    static var allProductIDs: Set<String> {
        var ids: Set<String> = [proProductID, hints10ProductID, hints30ProductID]
        ids.formUnion(BerryTheme.allProductIDs)
        return ids
    }

    // MARK: - Products

    private(set) var proProduct: Product?
    private(set) var themeProducts: [String: Product] = [:]
    private(set) var hintProducts: [String: Product] = [:]

    // MARK: - Entitlements

    private(set) var isProUnlocked: Bool = false
    private(set) var unlockedThemes: Set<BerryTheme> = [.blueberry]

    private var transactionListener: Task<Void, Never>?

    /// Optional reference to the hint service so consumable purchases can
    /// credit bonus hints immediately.
    var hintService: HintService?

    init() {
        transactionListener = listenForTransactions()
        Task {
            await loadProducts()
            await updatePurchaseStatus()
        }
    }

    // MARK: - Load products

    func loadProducts() async {
        do {
            let products = try await Product.products(for: Self.allProductIDs)
            for product in products {
                if product.id == Self.proProductID {
                    proProduct = product
                } else if BerryTheme.allProductIDs.contains(product.id) {
                    themeProducts[product.id] = product
                } else if Self.hintProductIDs.contains(product.id) {
                    hintProducts[product.id] = product
                }
            }
        } catch {
            #if DEBUG
            print("Failed to load products: \(error)")
            #endif
        }
    }

    // MARK: - Purchases

    func purchasePro() async throws {
        guard let product = proProduct else { return }
        try await purchaseNonConsumable(product)
    }

    func purchaseTheme(_ theme: BerryTheme) async throws {
        guard let productID = theme.productID,
              let product = themeProducts[productID] else { return }
        try await purchaseNonConsumable(product)
    }

    func purchaseHints(productID: String) async throws {
        guard let product = hintProducts[productID] else { return }
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            creditHints(for: transaction.productID)
        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }

    func restorePurchases() async {
        try? await AppStore.sync()
        await updatePurchaseStatus()
    }

    // MARK: - Theme helpers

    func isThemeUnlocked(_ theme: BerryTheme) -> Bool {
        unlockedThemes.contains(theme)
    }

    func product(for theme: BerryTheme) -> Product? {
        guard let id = theme.productID else { return nil }
        return themeProducts[id]
    }

    /// Sorted hint products (cheapest first) for display in the store UI.
    var sortedHintProducts: [Product] {
        hintProducts.values.sorted { $0.price < $1.price }
    }

    // MARK: - Private

    private func purchaseNonConsumable(_ product: Product) async throws {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await updatePurchaseStatus()
        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }

    private func updatePurchaseStatus() async {
        var proUnlocked = false
        var themes: Set<BerryTheme> = [.blueberry]

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }

            if transaction.productID == Self.proProductID {
                proUnlocked = true
            }

            // Check theme entitlements
            for theme in BerryTheme.allCases {
                if let pid = theme.productID, transaction.productID == pid {
                    themes.insert(theme)
                }
            }
        }

        isProUnlocked = proUnlocked
        unlockedThemes = themes
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    // Credit hints for consumable purchases
                    if Self.hintProductIDs.contains(transaction.productID) {
                        creditHints(for: transaction.productID)
                    }
                    await transaction.finish()
                    await updatePurchaseStatus()
                }
            }
        }
    }

    private func creditHints(for productID: String) {
        let count: Int
        switch productID {
        case Self.hints10ProductID: count = 10
        case Self.hints30ProductID: count = 30
        default: return
        }
        hintService?.addBonusHints(count)
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
