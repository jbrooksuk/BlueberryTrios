import Foundation
import StoreKit
import Observation

@MainActor
@Observable
final class StoreKitService {
    static let proProductID = "com.altthree.Berroku.pro"
    static let streakRevivalProductID = "com.altthree.Berroku.streakrevival"
    static let themeProductIDs = Set(AppTheme.allCases.compactMap(\.productID))

    private(set) var proProduct: Product?
    private(set) var streakRevivalProduct: Product?
    private(set) var themeProducts: [String: Product] = [:]
    private(set) var isProUnlocked: Bool = false
    private(set) var unlockedThemeIDs: Set<String> = []
    /// Runs once per verified Berry Revival purchase, before the
    /// transaction is finished. Consumables leave the transaction stream
    /// permanently once finished, so a transaction that arrives while no
    /// handler is attached is left unfinished — StoreKit redelivers it on
    /// the next launch and the streak grant runs then.
    var onStreakRevivalPurchased: (() -> Void)?
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
            let productIDs = [Self.proProductID, Self.streakRevivalProductID] + Array(Self.themeProductIDs)
            let products = try await Product.products(for: productIDs)
            proProduct = products.first { $0.id == Self.proProductID }
            streakRevivalProduct = products.first { $0.id == Self.streakRevivalProductID }
            themeProducts = Dictionary(
                uniqueKeysWithValues: products
                    .filter { Self.themeProductIDs.contains($0.id) }
                    .map { ($0.id, $0) }
            )
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

    func product(for theme: AppTheme) -> Product? {
        guard let productID = theme.productID else { return nil }
        return themeProducts[productID]
    }

    func isThemeUnlocked(_ theme: AppTheme) -> Bool {
        guard let productID = theme.productID else { return true }
        return unlockedThemeIDs.contains(productID)
    }

    @discardableResult
    func purchaseTheme(_ theme: AppTheme) async throws -> Bool {
        guard let product = product(for: theme) else { return false }
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await updatePurchaseStatus()
            return true
        case .userCancelled, .pending:
            return false
        @unknown default:
            return false
        }
    }

    /// Purchases the Berry Revival consumable. Returns true when the
    /// purchase completed (the streak grant runs via
    /// `onStreakRevivalPurchased`); false for cancelled or pending.
    @discardableResult
    func purchaseStreakRevival() async throws -> Bool {
        guard let product = streakRevivalProduct else { return false }
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await handle(transaction)
            return true
        case .userCancelled, .pending:
            return false
        @unknown default:
            return false
        }
    }

    func restorePurchases() async {
        try? await AppStore.sync()
        await updatePurchaseStatus()
    }

    private func updatePurchaseStatus() async {
        var proUnlocked = false
        var unlockedThemes: Set<String> = []
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == Self.proProductID {
                    proUnlocked = true
                } else if Self.themeProductIDs.contains(transaction.productID) {
                    unlockedThemes.insert(transaction.productID)
                }
            }
        }
        isProUnlocked = proUnlocked
        unlockedThemeIDs = unlockedThemes
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await handle(transaction)
                }
            }
        }
    }

    /// Routes a verified transaction: Berry Revival grants the streak via
    /// `onStreakRevivalPurchased`, everything else refreshes entitlements.
    /// The revival transaction is only finished after the grant has run —
    /// finishing a consumable is irreversible, so with no handler attached
    /// yet it stays unfinished for redelivery on the next launch.
    private func handle(_ transaction: Transaction) async {
        if transaction.productID == Self.streakRevivalProductID {
            guard transaction.revocationDate == nil else {
                await transaction.finish()
                return
            }
            guard let onStreakRevivalPurchased else { return }
            onStreakRevivalPurchased()
            await transaction.finish()
        } else {
            await transaction.finish()
            await updatePurchaseStatus()
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
