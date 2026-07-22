//
//  SubscriptionOriginalIdProvider.swift
//  ConsumableSampleApp
//
//  Created by Baker Mohammad Anas on 27/1/26.
//

//MARK: LATER THIS CLASS WILL NOT BE USED, PROBABLIY WILL USE

import Foundation
import StoreKit

enum SubscriptionOriginalIdProvider {

    /// Fast path: use cached value.
    static func cached() -> String? {
        return WalletPreferences.shared.cachedSubscriptionOriginalId
    }
    
    // Call this rarely (e.g., on user action "Restore / Sync").
    static func refreshFromHistory() async {
        WalletPreferences.shared.cachedSubscriptionOriginalId = ""
        
        for await result in Transaction.currentEntitlements {
            guard case .verified(let tx) = result else { continue }
            if tx.productType == .autoRenewable {
                WalletPreferences.shared.cachedSubscriptionOriginalId = String(tx.originalID)
                return
            }
        }
        
        for await result in Transaction.all {
            guard case .verified(let tx) = result else { continue }
            if tx.productType == .autoRenewable {
                WalletPreferences.shared.cachedSubscriptionOriginalId = String(tx.originalID)
                return
            }
        }
    }
}
