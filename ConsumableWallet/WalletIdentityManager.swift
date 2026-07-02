//
//  WalletIdentityManager.swift
//  ConsumableSampleApp
//
//  Created by Baker Mohammad Anas on 27/1/26.
//

import Foundation

public final class WalletIdentityManager {

    public static let shared = WalletIdentityManager()
    private init() {}

    private let service = Bundle.main.bundleIdentifier ?? "wallet.service"
    private let deviceKey = "wallet.deviceUUID"
    private let icloudKey = "wallet.icloudUUID"

    // MARK: DeviceUUID (always create/read, non-sync)
    func deviceUUID() -> String {
        if let existing = try? KeychainUUIDStore.readUUID(service: service, account: deviceKey, synchronizable: false) {
            return existing.uuidString
        }
        let new = UUID()
        try? KeychainUUIDStore.saveUUID(new, service: service, account: deviceKey, synchronizable: false)
        return new.uuidString
    }

    // MARK: iCloudUUID (read-only unless user action)
    func readIcloudUUID() -> String? {
        (try? KeychainUUIDStore.readUUID(service: service, account: icloudKey, synchronizable: true))?.uuidString
    }

    /// Call ONLY on user action.
    func enableIcloudSyncUUID() -> String {
        if let existing = readIcloudUUID() { return existing }
        let new = UUID()
        try? KeychainUUIDStore.saveUUID(new, service: service, account: icloudKey, synchronizable: true)
        return new.uuidString
    }

    // MARK: Build identities (priority order)
    func buildIdentities(
        appleUserId: String?,
        originalTransactionId: String?
    ) -> [IdentityPayload] {

        var ids: [IdentityPayload] = []

        if let appleUserId, !appleUserId.isEmpty {
            ids.append(.init(type: .apple, value: appleUserId))
        }
        
        if let originalTransactionId, !originalTransactionId.isEmpty {
            ids.append(.init(type: .subOriginal, value: originalTransactionId))
        }

        // Always include device UUID
        ids.append(.init(type: .device, value: deviceUUID()))
        return ids
    }
    
    
    
    /// Deletes the iCloud sync UUID from synchronizable keychain.
    public func resetAllIdentity() {
        try? KeychainUUIDStore.deleteAnyUUID(service: service, account: deviceKey)
        WalletPreferences.shared.syncPreference = .off
        WalletPreferences.shared.confirmedIcloudUUID = nil
        AppleAuthStore.shared.logoutLocal()
    }
}
