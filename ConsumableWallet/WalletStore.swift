//
//  WalletStore.swift
//  ConsumableSampleApp
//
//  Created by Baker Mohammad Anas on 1/2/26.
//

import Foundation

extension Notification.Name {
    public static let walletDidUpdate = Notification.Name("walletDidUpdate")
}

public struct WalletSnapshot: Codable {
    public let walletId: String
    public let availableBalance: Int
    public let reservedBalance: Int
    public let mode: IdentityType?
    public let warnings: [BootstrapWarning]
    public let updatedAt: Date
}

public actor WalletStore {

    public static let shared = WalletStore()

    private let defaults = UserDefaults.standard
    private let key = "wallet.snapshot.v2"

    private var cached: WalletSnapshot?

    private init() {}

    // MARK: - Read

    public func currentSnapshot() -> WalletSnapshot? {
        if let cached { return cached }
        if let data = defaults.data(forKey: key),
           let snap = try? JSONDecoder().decode(WalletSnapshot.self, from: data) {
            cached = snap
            return snap
        }
        return nil
    }

    func walletId() -> String? {
        return currentSnapshot()?.walletId
    }

    func availableBalance() -> Int? {
        return currentSnapshot()?.availableBalance
    }

    func reservedBalance() -> Int? {
        return currentSnapshot()?.reservedBalance
    }

    // MARK: - Write

    func setFromBootstrap(_ res: BootstrapResponse) {
        let snap = WalletSnapshot(
            walletId: res.walletId,
            availableBalance: res.availableBalance,
            reservedBalance: res.reservedBalance,
            mode: res.mode,
            warnings: res.warnings,
            updatedAt: Date()
        )
        persistAndNotify(snap)
    }

    func updateBalances(walletId: String, available: Int, reserved: Int, mode: IdentityType? = nil) {
        let existing = currentSnapshot()
        let snap = WalletSnapshot(
            walletId: walletId,
            availableBalance: available,
            reservedBalance: reserved,
            mode: mode ?? existing?.mode,
            warnings: existing?.warnings ?? [],
            updatedAt: Date()
        )
        persistAndNotify(snap)
    }

    func clear() {
        cached = nil
        defaults.removeObject(forKey: key)
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .walletDidUpdate, object: nil)
        }
    }

    private func persistAndNotify(_ snap: WalletSnapshot) {
        cached = snap
        if let data = try? JSONEncoder().encode(snap) {
            defaults.set(data, forKey: key)
        }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .walletDidUpdate, object: snap)
        }
    }
}
