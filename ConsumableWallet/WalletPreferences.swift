//
//  WalletPreferences.swift
//  ConsumableSampleApp
//
//  Created by Baker Mohammad Anas on 27/1/26.
//

import Foundation

public final class WalletPreferences {
    public static let shared = WalletPreferences()
    private init() {}

    private let defaults = UserDefaults()

    private let kSyncPref = "consumable.wallet.syncPreference"
    private let kCachedOriginalId = "consumable.wallet.cachedSubscriptionOriginalId"
    private let kAppleUserId = "consumable.wallet.appleUserId"
    private let kConfirmedIcloudUUID = "consumable.wallet.confirmedIcloudUUID"

    public var syncPreference: SyncPreference {
        get { SyncPreference(rawValue: defaults.string(forKey: kSyncPref) ?? "") ?? .off }
        set { defaults.set(newValue.rawValue, forKey: kSyncPref) }
    }
    
    public var syncPreferenceStatus: String {
        switch self.syncPreference {
        case .off:
            return "Not Synced"
        case .requested:
            return "Trying to Sync..."
        case .confirmed:
            return "Synced"
        }
    }

    public var cachedSubscriptionOriginalId: String? {
        get { defaults.string(forKey: kCachedOriginalId) }
        set {
            if let v = newValue, !v.isEmpty {
                defaults.set(v, forKey: kCachedOriginalId)
            } else {
                defaults.removeObject(forKey: kCachedOriginalId)
            }
        }
    }

    public var appleUserId: String? {
        get { defaults.string(forKey: kAppleUserId) }
        set {
            if let v = newValue, !v.isEmpty {
                defaults.set(v, forKey: kAppleUserId)
            } else {
                defaults.removeObject(forKey: kAppleUserId)
            }
        }
    }

    /// Anchored iCloud UUID captured when sync is confirmed working.
    /// Used to detect iCloud account switching / keychain replacement.
    public var confirmedIcloudUUID: String? {
        get { defaults.string(forKey: kConfirmedIcloudUUID) }
        set {
            if let v = newValue, !v.isEmpty {
                defaults.set(v, forKey: kConfirmedIcloudUUID)
            } else {
                defaults.removeObject(forKey: kConfirmedIcloudUUID)
            }
        }
    }
}
