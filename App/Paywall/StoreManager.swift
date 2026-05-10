import StoreKit
import SwiftUI

@MainActor
final class StoreManager: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    @AppStorage("isPremium") var isPremium = false
    @AppStorage("isTrial") var isTrial = false

    var canExpandGroups: Bool { isPremium && !isTrial }

    static let freeGroupLimit = 3
    static let freeGroupMemberLimit = 3
    static let premiumGroupMemberLimit = 40

    func canAccess(_ feature: PremiumFeature) -> Bool {
        switch feature {
        case .unlimitedGroups, .largeGroups:
            return canExpandGroups
        default:
            return isPremium
        }
    }

    var groupMemberLimit: Int {
        canExpandGroups ? Self.premiumGroupMemberLimit : Self.freeGroupMemberLimit
    }

    var groupLimit: Int {
        canExpandGroups ? .max : Self.freeGroupLimit
    }

    private var updateTask: Task<Void, Never>?

    static let productIDs: Set<String> = [
        Tier.lifetime.productID,
        Tier.annual.productID,
        Tier.monthly.productID
    ]

    init() {
        updateTask = Task { [weak self] in
            await self?.listenForTransactions()
        }
        Task { [weak self] in
            await self?.loadProducts()
            await self?.refreshEntitlements()
        }
    }

    deinit {
        updateTask?.cancel()
    }

    func loadProducts() async {
        do {
            let fetched = try await Product.products(for: Self.productIDs)
            products = fetched.sorted { $0.price > $1.price }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func purchase(_ product: Product) async -> Bool {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await refreshEntitlements()
                return true
            case .userCancelled:
                return false
            case .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        try? await AppStore.sync()
        await refreshEntitlements()
    }

    func product(for tier: Tier) -> Product? {
        products.first { $0.id == tier.productID }
    }

    private func refreshEntitlements() async {
        var ids = Set<String>()
        var onTrial = false
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                if transaction.revocationDate != nil { continue }
                ids.insert(transaction.productID)
                if transaction.offerType == .introductory {
                    onTrial = true
                }
            }
        }
        purchasedProductIDs = ids
        isPremium = !ids.isEmpty
        isTrial = isPremium && onTrial && ids.allSatisfy { id in
            Tier.from(productID: id)?.productID != Tier.lifetime.productID
        }
    }

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if let transaction = try? checkVerified(result) {
                if transaction.revocationDate != nil {
                    purchasedProductIDs.remove(transaction.productID)
                } else {
                    await transaction.finish()
                    purchasedProductIDs.insert(transaction.productID)
                }
                await refreshEntitlements()
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }
}
