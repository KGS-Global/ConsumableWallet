//
//  AppleAuthStore.swift
//  ConsumableSampleApp
//
//  Created by Baker Mohammad Anas on 27/1/26.
//

import Foundation

public final class AppleAuthStore {
    public static let shared = AppleAuthStore()
    private init() {}

    public var appleUserId: String? {
        get { WalletPreferences.shared.appleUserId }
        set { WalletPreferences.shared.appleUserId = newValue }
    }

    public func logoutLocal() {
        appleUserId = nil
    }
}

