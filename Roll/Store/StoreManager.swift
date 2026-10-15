import StoreKit

/// StoreKit 2 wrapper. Entitlement is derived only from verified transactions.
@MainActor
final class StoreManager: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var isPlus = false
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var isWorking = false
    @Published var message: String?

    private var updatesTask: Task<Void, Never>?

    init() {
        // Open source build: no StoreKit, no paywall, everything unlocked.
        guard AppConfig.storeEnabled else {
            isPlus = true
            return
        }
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                await self?.handle(result)
            }
        }
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    var monthly: Product? { products.first { $0.id == ProductID.monthly } }
    var lifetime: Product? { products.first { $0.id == ProductID.lifetime } }

    func loadProducts() async {
        guard AppConfig.storeEnabled else { return }
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            products = try await Product.products(for: ProductID.all)
        } catch {
            message = "Couldn't load prices. Check your connection and try again."
        }
    }

    func purchase(_ product: Product) async {
        guard AppConfig.storeEnabled else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            switch try await product.purchase() {
            case .success(let result):
                await handle(result)
            case .pending:
                message = "Your purchase is pending approval."
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            message = "Purchase failed. You have not been charged."
        }
    }

    func restore() async {
        guard AppConfig.storeEnabled else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            message = isPlus ? "Purchases restored." : "No purchases found to restore."
        } catch {
            message = "Couldn't restore purchases. Try again."
        }
    }

    private func handle(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else { return }
        await transaction.finish()
        await refreshEntitlements()
    }

    func refreshEntitlements() async {
        guard AppConfig.storeEnabled else { return }
        var active = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let t) = result else { continue }
            if ProductID.all.contains(t.productID), t.revocationDate == nil {
                active = true
            }
        }
        isPlus = active
    }
}
