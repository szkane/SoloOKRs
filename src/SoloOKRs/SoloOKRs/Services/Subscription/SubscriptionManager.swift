// SubscriptionManager.swift
// SoloOKRs
//
// StoreKit 2 integration for IAP

import Foundation
import SwiftUI
import StoreKit

@Observable
@MainActor
class SubscriptionManager {
    static let shared = SubscriptionManager()

    // Product identifiers
    static let proLifetimeID = "com.szkane.SoloOKRs.pro.lifetime"
    static let proMonthlyID = "com.szkane.SoloOKRs.pro.monthly"
    
    // State
    var subscriptionStatus: SubscriptionStatus = .trial
    var objectivesCreated: Int = 0
    var products: [Product] = []
    var isLoading = false
    var errorMessage: String?
    
    // Trial limits
    private let maxTrialObjectives = 3
    
    // Transaction listener task
    private var transactionListener: Task<Void, Error>?

    private init() {
        // Load saved state
        objectivesCreated = UserDefaults.standard.integer(forKey: "objectivesCreated")
        
        // Check if user previously purchased
        if UserDefaults.standard.bool(forKey: "isPurchased") {
            subscriptionStatus = .subscribed
        }
        
        // Start listening for transactions
        transactionListener = listenForTransactions()
        
        // Load products on init
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }
    
    deinit {
        // Note: transactionListener will be cancelled when task goes out of scope
    }

    // MARK: - Public API
    
    var canCreateObjective: Bool {
        subscriptionStatus == .subscribed || objectivesCreated < maxTrialObjectives
    }

    var remainingTrialObjectives: Int {
        max(0, maxTrialObjectives - objectivesCreated)
    }
    
    var lifetimeProduct: Product? {
        products.first { $0.id == Self.proLifetimeID }
    }
    
    var monthlyProduct: Product? {
        products.first { $0.id == Self.proMonthlyID }
    }

    func incrementObjectiveCount() {
        objectivesCreated += 1
        UserDefaults.standard.set(objectivesCreated, forKey: "objectivesCreated")
    }

    func decrementObjectiveCount() {
        objectivesCreated = max(0, objectivesCreated - 1)
        UserDefaults.standard.set(objectivesCreated, forKey: "objectivesCreated")
    }

    // MARK: - StoreKit 2
    
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let productIDs = [Self.proLifetimeID, Self.proMonthlyID]
            products = try await Product.products(for: productIDs)
            products.sort { $0.price > $1.price } // Lifetime first
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
            print("StoreKit: Failed to load products: \(error)")
        }
        
        isLoading = false
    }
    
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await handleTransaction(transaction)
            await transaction.finish()
            
        case .userCancelled:
            print("StoreKit: User cancelled purchase")
            
        case .pending:
            print("StoreKit: Purchase pending (Ask to Buy)")
            
        @unknown default:
            break
        }
    }
    
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
        } catch {
            errorMessage = "Failed to restore: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Private
    
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in StoreKit.Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await self.handleTransaction(transaction)
                    await transaction.finish()
                } catch {
                    print("StoreKit: Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified(_, let error):
            throw error
        }
    }
    
    private func handleTransaction(_ transaction: StoreKit.Transaction) async {
        // Check if this is one of our products
        if transaction.productID == Self.proLifetimeID || 
           transaction.productID == Self.proMonthlyID {
            
            // Check if revoked
            if transaction.revocationDate != nil {
                subscriptionStatus = .expired
                UserDefaults.standard.set(false, forKey: "isPurchased")
            } else if let expirationDate = transaction.expirationDate {
                // Subscription - check if expired
                if expirationDate > Date() {
                    subscriptionStatus = .subscribed
                    UserDefaults.standard.set(true, forKey: "isPurchased")
                } else {
                    subscriptionStatus = .expired
                    UserDefaults.standard.set(false, forKey: "isPurchased")
                }
            } else {
                // Non-consumable (lifetime)
                subscriptionStatus = .subscribed
                UserDefaults.standard.set(true, forKey: "isPurchased")
            }
        }
    }
    
    private func updateSubscriptionStatus() async {
        // Check current entitlements
        for await result in StoreKit.Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                await handleTransaction(transaction)
            } catch {
                print("StoreKit: Entitlement verification failed: \(error)")
            }
        }
    }
}
