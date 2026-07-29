//
//  WalletSubscriptionBridge.swift
//  ConsumableSampleApp
//

import StoreKit

struct WalletSubscriptionBridge {
    static func currentSubscriptionStatus() async -> WalletSubscriptionInfo? {
        for await result in Transaction.currentEntitlements {
            let signedJWS = result.jwsRepresentation
            guard case .verified(let tx) = result,
                  tx.productType == .autoRenewable else { continue }
            let isActive = tx.revocationDate == nil && (tx.expirationDate ?? .distantFuture) > Date()
            return WalletSubscriptionInfo(
                isActive: isActive,
                paidThrough: tx.expirationDate,
                anchorStart: tx.originalPurchaseDate
            )
        }
        return nil
    }
    
    static func getLatestSubTransactionDetails() async -> (Transaction?, String?) {
        // Prefer an active subscription entitlement.
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  transaction.productType == .autoRenewable else {
                continue
            }

            return (transaction, result.jwsRepresentation)
        }

        // No active entitlement found. Fall back to the latest
        // auto-renewable subscription transaction in the history.
        var latestTransaction: Transaction?
        var latestSignedJWS: String?

        for await result in Transaction.all {
            guard case .verified(let transaction) = result,
                  transaction.productType == .autoRenewable else {
                continue
            }

            if latestTransaction == nil ||
                transaction.purchaseDate > latestTransaction!.purchaseDate {
                latestTransaction = transaction
                latestSignedJWS = result.jwsRepresentation
            }
        }

        return (latestTransaction, latestSignedJWS)
    }
}
