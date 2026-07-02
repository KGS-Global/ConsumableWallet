//
//  WalletSubscriptionBridge.swift
//  ConsumableSampleApp
//

import StoreKit

struct WalletSubscriptionBridge {
    static func currentSubscriptionStatus() async -> WalletSubscriptionInfo? {
        for await result in Transaction.currentEntitlements {
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
}
