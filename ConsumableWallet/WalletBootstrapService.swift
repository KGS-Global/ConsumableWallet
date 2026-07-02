//
//  WalletBootstrapService.swift
//  ConsumableSampleApp
//
//  Created by Baker Mohammad Anas on 27/1/26.
//

import Foundation

final class WalletBootstrapService {

    private let api: WalletAPIType
    private let prefs = WalletPreferences.shared
    private let idm = WalletIdentityManager.shared

    init(api: WalletAPIType) {
        self.api = api
    }

    func bootstrap() async throws -> BootstrapResponse {
        let appleId = AppleAuthStore.shared.appleUserId
        let _ = await SubscriptionOriginalIdProvider.refreshFromHistory()
        let originalTransactionId = SubscriptionOriginalIdProvider.cached()

        let identities = idm.buildIdentities(
            appleUserId: appleId,
            originalTransactionId: originalTransactionId
        )

        let subscription: WalletSubscriptionInfo? = await WalletSubscriptionBridge.currentSubscriptionStatus()

        let req = BootstrapRequest(
            identities: identities,
            subscription: subscription
        )

        let res = try await api.bootstrap(request: req)
        await WalletStore.shared.setFromBootstrap(res)

        return res
    }

    func userRestoreAndSync() async throws -> BootstrapResponse {
        await SubscriptionOriginalIdProvider.refreshFromHistory()
        return try await bootstrap()
    }
}
