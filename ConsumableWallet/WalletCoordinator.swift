//
//  WalletCoordinator.swift
//  ConsumableSampleApp
//
//  Created by Baker Mohammad Anas on 27/1/26.
//
import Foundation
import StoreKit

public class WalletCoordinator {

    private static var _instance: WalletCoordinator?

    public static var shared: WalletCoordinator {
        guard let coordinator = _instance else {
            preconditionFailure(
                "WalletCoordinator.shared accessed before configuration. "
                + "Call WalletCoordinator._shared(config:) once at app launch before using the wallet."
            )
        }
        return coordinator
    }

    private let bootstrapService: WalletBootstrapService
    private let api: WalletAPIType

    private var lastBootstrapAt: Date?
    private var bootstrapTask: Task<BootstrapResponse?, Never>?
    private let minInterval: TimeInterval = 10

    @discardableResult
    public static func _shared(config: WalletConfig) -> WalletCoordinator {
        if let coordinator = _instance {
            return coordinator
        }

        let coordinator = WalletCoordinator(
            api: WalletAPI(with: config)
        )
        _instance = coordinator
        return coordinator
    }

    private init(api: WalletAPIType) {
        self.api = api
        self.bootstrapService = WalletBootstrapService(api: api)
    }

    /// Ensures we have a walletId. If missing, bootstraps once.
    private func ensureWalletId() async -> String? {
        if let wid = await WalletStore.shared.walletId() {
            return wid
        }
        _ = try? await bootstrapService.bootstrap()
        return await WalletStore.shared.walletId()
    }

    
    public func grantAppStoreCredits(
        transaction: Transaction,
        signedTransactionInfo: String
    ) async throws -> AppStoreCreditGrantResponse {
        
        guard let walletId = await ensureWalletId() else {
            throw WalletAPIError.httpError(status: 0, body: "No walletId (bootstrap failed)")
        }
        //TODO: IMPLMENT
        let request = AppStoreCreditGrantRequest(
            walletId: walletId,
            transaction: transaction,
            signedTransactionInfo: signedTransactionInfo
        )
        
        let res = try await api.grantAppstoreVerifiedCredits(request: request)
        
        await WalletStore.shared.updateBalances(
            walletId: res.walletId,
            available: res.availableBalance,
            reserved: res.reservedBalance
        )
        
        return res
    }
    
    /// Call this after a verified auto-renewable subscription purchase to sync weekly allowance.
    public func syncAppstoreSubscriptionAfterPurchase(
        transaction: Transaction,
        signedTransactionInfo: String
    ) async throws {
        guard let walletId = await ensureWalletId() else {
            throw WalletAPIError.httpError(status: 0, body: "No walletId (bootstrap failed)")
        }
        
        let request = SubscriptionSyncRequest(walletId: walletId, transaction: transaction, signedTransactionInfo: signedTransactionInfo)

        let res = try await api.syncAppstoreVerifiedSubscription(request: request)
        
        await WalletStore.shared.updateBalances(
            walletId: res.walletId,
            available: res.availableBalance,
            reserved: res.reservedBalance
        )
    }
    
    
    /// Call this after a verified consumable purchase succeeds.
    private func grantCreditsAfterPurchase(credits: Int,
                                   idempotencyKey: String,
                                   productId: String? = nil) async throws -> SubscriptionSyncResponse {
        guard let walletId = await ensureWalletId() else {
            throw WalletAPIError.httpError(status: 0, body: "No walletId (bootstrap failed)")
        }

        let meta: [String: String]? = productId.map { ["productId": $0] }

        let res = try await api.grantCredits(
            walletId: walletId,
            idempotencyKey: idempotencyKey,
            credits: credits,
            reason: "CONSUMABLE_PURCHASE",
            metadata: meta
        )

        await WalletStore.shared.updateBalances(
            walletId: res.walletId,
            available: res.availableBalance,
            reserved: res.reservedBalance
        )

        return res
    }

    

    /// Reserve credits for an ML job. Returns the reservation so the caller
    /// can pass reservationId + reservationToken to the Queue Server.
    public func reserveCreditsForJob(featureId: String,
                              amount: Int,
                              clientRequestId: String,
                              metadata: [String: String]? = nil) async throws -> ReservationResponse {
        guard let walletId = await ensureWalletId() else {
            throw WalletAPIError.httpError(status: 0, body: "No walletId (bootstrap failed)")
        }

        let res = try await api.reserveCredits(
            walletId: walletId,
            featureId: featureId,
            amount: amount,
            clientRequestId: clientRequestId,
            reason: "ML_JOB_RESERVE",
            metadata: metadata
        )

        await WalletStore.shared.updateBalances(
            walletId: res.walletId,
            available: res.availableBalance,
            reserved: res.reservedBalance
        )

        return res
    }

    /// Cancel a reservation (iOS-callable for pre-Queue-acceptance failures).
    public func cancelReservation(reservationId: String,
                           taskId: String? = nil,
                           reason: String? = nil) async throws -> ConsumeCancelResponse {
        let res = try await api.cancelReservation(
            reservationId: reservationId,
            taskId: taskId,
            reason: reason,
            idempotencyKey: "cancel:\(reservationId)",
            metadata: nil
        )

        if let walletId = await WalletStore.shared.walletId() {
            await WalletStore.shared.updateBalances(
                walletId: walletId,
                available: res.availableBalance,
                reserved: res.reservedBalance
            )
        }

        return res
    }

    /// Safe: coalesces concurrent calls + debounces
    public func onAppStartOrForeground() async -> BootstrapResponse? {
        if let task = bootstrapTask {
            return await task.value
        }

        if let last = lastBootstrapAt, Date().timeIntervalSince(last) < minInterval {
            return nil
        }
        lastBootstrapAt = Date()

        let task = Task<BootstrapResponse?, Never> { [bootstrapService] in
            defer { Task { @MainActor in self.bootstrapTask = nil } }
            return try? await bootstrapService.bootstrap()
        }

        bootstrapTask = task
        return await task.value
    }

//    func onUserTappedEnableIcloud() async -> BootstrapResponse? {
//        return nil
//    }
//
//    func onUserTappedResetiCloud() async -> BootstrapResponse? {
//        return nil
//    }

    public func onUserTappedRestore() async -> BootstrapResponse? {
        lastBootstrapAt = nil
        return await onAppStartOrForeground()
    }

    public func onUserTappedSignedIn() async -> BootstrapResponse? {
        lastBootstrapAt = nil
        return await onAppStartOrForeground()
    }

    public func onUserTappedSignedOut() async -> BootstrapResponse? {
        lastBootstrapAt = nil
        return await onAppStartOrForeground()
    }
}


// MARK: the functions that are inside this extension will be called from Queue server. it is temporary here
extension WalletCoordinator {
    public func attachReservation(reservationId: String,
                           reservationToken: String,
                           taskId: String,
                           featureId: String,
                           amount: Double) async throws -> AttachResponse {
        let res = try await api.attachReserve(reservationId: reservationId,
                                              reservationToken: reservationToken,
                                              taskId: taskId,
                                              featureId: featureId,
                                              amount: amount)

        return res
    }

    public func settleReservation(reservationId: String,
                           taskId: String,
                           result: String = "SUCCESS") async throws -> SettleResponse {
        let res = try await api.settleReserve(reservationId: reservationId, taskId: taskId, result: result)

        return res
    }

    public func cancelReservation2(reservationId: String,
                           taskId: String,
                           reason: String = "TEST_FROM_DEVICE") async throws -> SettleResponse {
        let res = try await api.cancelReserve(reservationId: reservationId, taskId: taskId, reason: reason)
        
        if let walletId = await WalletStore.shared.walletId() {
            await WalletStore.shared.updateBalances(
                walletId: walletId,
                available: res.availableBalance,
                reserved: res.reservedBalance
            )
        }

        return res
    }
}


