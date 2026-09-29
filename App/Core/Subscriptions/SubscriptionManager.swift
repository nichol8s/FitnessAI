import Foundation
import StoreKit

public enum AppEntitlement: Equatable {
    case unknown
    case free
    case pro
}

public enum SubscriptionError: Error {
    case failedVerification
    case userCancelled
    case pending
    case productNotFound
}

@MainActor
public final class SubscriptionManager: ObservableObject {
    public static let shared = SubscriptionManager()
    
    @Published public private(set) var entitlement: AppEntitlement = .unknown
    @Published public private(set) var products: [Product] = []
    
    // Replace these with actual identifiers configured in App Store Connect
    private let productIDs = [
        "com.fitness.pro.monthly",
        "com.fitness.pro.yearly"
    ]
    
    private var updatesTask: Task<Void, Never>? = nil
    
    private init() {
        updatesTask = listenForTransactions()
    }
    
    deinit {
        updatesTask?.cancel()
    }
    
    public func loadProducts() async {
        do {
            let storeProducts = try await Product.products(for: productIDs)
            self.products = storeProducts.sorted(by: { $0.price < $1.price })
            await updateEntitlementStatus()
        } catch {
            print("Failed to load StoreKit products: \(error)")
        }
    }
    
    public func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try verifyTransaction(verification)
            await transaction.finish()
            await updateEntitlementStatus()
            
        case .userCancelled:
            throw SubscriptionError.userCancelled
            
        case .pending:
            throw SubscriptionError.pending
            
        @unknown default:
            throw SubscriptionError.failedVerification
        }
    }
    
    public func restorePurchases() async throws {
        try await AppStore.sync()
        await updateEntitlementStatus()
    }
    
    private func updateEntitlementStatus() async {
        var hasPro = false
        
        for await result in Transaction.currentEntitlements {
            if let transaction = try? verifyTransaction(result) {
                if productIDs.contains(transaction.productID) {
                    hasPro = true
                }
            }
        }
        
        entitlement = hasPro ? .pro : .free
    }
    
    private func listenForTransactions() -> Task<Void, Never> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.verifyTransaction(result)
                    await transaction.finish()
                    await self.updateEntitlementStatus()
                } catch {
                    print("Transaction failed verification.")
                }
            }
        }
    }
    
    private func verifyTransaction<T>(_ verificationResult: VerificationResult<T>) throws -> T {
        switch verificationResult {
        case .unverified(_, _):
            throw SubscriptionError.failedVerification
        case .verified(let safePayload):
            return safePayload
        }
    }
}
