//
//  ConsumableWalletDataModel.swift
//  ConsumableSampleApp
//
//  Created by Baker Mohammad Anas on 27/1/26.
//

import Foundation
import StoreKit

// MARK: - Enums

public enum IdentityType: String, Codable, Sendable {
    case apple = "APPLE"
    case subOriginal = "SUB_ORIGINAL"
    case device = "DEVICE_LOCAL"
}

public enum BootstrapWarning: Codable, Equatable, Sendable {
    // Device rehoming
    case deviceRehomtedToNewGuestWallet
    case deviceRehomtedToAppleWallet
    case deviceRehomtedToSubWallet
    case deviceRehomtedFromAppleWalletToSubWallet
    // Subscription conflicts
    case subLinkedToAnotherApple
    case subAlreadyClaimed
    case subMergedGuest
    case subAlreadyClaimedAppleSigninRequired
    case subLinkedToAppleSigninRequired
    case subWalletsMergedAfterAppleSignin
    // Apple sign-in prompts
    case appleSigninRequiredForWallet
    case appleSigninRequiredForSubWalletMerge
    // Future-proof fallback
    case unknown(String)

    init(rawValue: String) {
        switch rawValue {
        case "DEVICE_REHOMED_TO_NEW_GUEST_WALLET":              self = .deviceRehomtedToNewGuestWallet
        case "DEVICE_REHOMED_TO_APPLE_WALLET":                  self = .deviceRehomtedToAppleWallet
        case "DEVICE_REHOMED_TO_SUB_WALLET":                    self = .deviceRehomtedToSubWallet
        case "DEVICE_REHOMED_FROM_APPLE_WALLET_TO_SUB_WALLET":  self = .deviceRehomtedFromAppleWalletToSubWallet
        case "SUB_LINKED_TO_ANOTHER_APPLE":                     self = .subLinkedToAnotherApple
        case "SUB_ALREADY_CLAIMED":                             self = .subAlreadyClaimed
        case "SUB_MERGED_GUEST":                                self = .subMergedGuest
        case "SUB_ALREADY_CLAIMED_APPLE_SIGNIN_REQUIRED":       self = .subAlreadyClaimedAppleSigninRequired
        case "SUB_LINKED_TO_APPLE_SIGNIN_REQUIRED":             self = .subLinkedToAppleSigninRequired
        case "SUB_WALLETS_MERGED_AFTER_APPLE_SIGNIN":           self = .subWalletsMergedAfterAppleSignin
        case "APPLE_SIGNIN_REQUIRED_FOR_WALLET":                self = .appleSigninRequiredForWallet
        case "APPLE_SIGNIN_REQUIRED_FOR_SUB_WALLET_MERGE":      self = .appleSigninRequiredForSubWalletMerge
        default:                                                self = .unknown(rawValue)
        }
    }

    var rawValue: String {
        switch self {
        case .deviceRehomtedToNewGuestWallet:               return "DEVICE_REHOMED_TO_NEW_GUEST_WALLET"
        case .deviceRehomtedToAppleWallet:                  return "DEVICE_REHOMED_TO_APPLE_WALLET"
        case .deviceRehomtedToSubWallet:                    return "DEVICE_REHOMED_TO_SUB_WALLET"
        case .deviceRehomtedFromAppleWalletToSubWallet:     return "DEVICE_REHOMED_FROM_APPLE_WALLET_TO_SUB_WALLET"
        case .subLinkedToAnotherApple:                      return "SUB_LINKED_TO_ANOTHER_APPLE"
        case .subAlreadyClaimed:                            return "SUB_ALREADY_CLAIMED"
        case .subMergedGuest:                               return "SUB_MERGED_GUEST"
        case .subAlreadyClaimedAppleSigninRequired:         return "SUB_ALREADY_CLAIMED_APPLE_SIGNIN_REQUIRED"
        case .subLinkedToAppleSigninRequired:               return "SUB_LINKED_TO_APPLE_SIGNIN_REQUIRED"
        case .subWalletsMergedAfterAppleSignin:             return "SUB_WALLETS_MERGED_AFTER_APPLE_SIGNIN"
        case .appleSigninRequiredForWallet:                 return "APPLE_SIGNIN_REQUIRED_FOR_WALLET"
        case .appleSigninRequiredForSubWalletMerge:         return "APPLE_SIGNIN_REQUIRED_FOR_SUB_WALLET_MERGE"
        case .unknown(let s):                               return s
        }
    }

    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self.init(rawValue: raw)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(rawValue)
    }
}

public enum SyncPreference: String, Codable {
    case off
    case requested
    case confirmed
}

// MARK: - Identity

struct IdentityPayload: Codable, Hashable {
    let type: IdentityType
    let value: String
}

// MARK: - Subscription

struct WalletSubscriptionInfo: Codable {
    let isActive: Bool
    let paidThrough: Date?
    let anchorStart: Date?
}

// MARK: - Weekly State

public struct WeeklyState: Codable {
    let entitled: Int
    let remaining: Int
    let reserved: Int
    let periodSeconds: Int
    let grantedWeekIndex: Int?
    let anchorStart: Date?
    let periodStart: Date?
    let periodEnd: Date?
    let paidThrough: Date?
}

// MARK: - Bootstrap

struct BootstrapRequest: Codable {
    let identities: [IdentityPayload]
    let subscription: WalletSubscriptionInfo?
}

public struct BootstrapResponse: Codable {
    let walletId: String
    let mode: IdentityType
    let availableBalance: Int
    let reservedBalance: Int
    let bankedBalance: Int
    let bankedReservedBalance: Int
    let weekly: WeeklyState?
    let warnings: [BootstrapWarning]

    private enum CodingKeys: String, CodingKey {
        case walletId, mode, availableBalance, reservedBalance
        case bankedBalance, bankedReservedBalance, weekly, warning
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        walletId             = try c.decode(String.self, forKey: .walletId)
        mode                 = try c.decode(IdentityType.self, forKey: .mode)
        availableBalance     = try c.decode(Int.self, forKey: .availableBalance)
        reservedBalance      = try c.decode(Int.self, forKey: .reservedBalance)
        bankedBalance        = try c.decode(Int.self, forKey: .bankedBalance)
        bankedReservedBalance = try c.decode(Int.self, forKey: .bankedReservedBalance)
        weekly               = try c.decodeIfPresent(WeeklyState.self, forKey: .weekly)
        let warningStr       = try c.decodeIfPresent(String.self, forKey: .warning)
        warnings = warningStr?
            .split(separator: "|")
            .map { BootstrapWarning(rawValue: String($0)) }
            ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(walletId, forKey: .walletId)
        try c.encode(mode, forKey: .mode)
        try c.encode(availableBalance, forKey: .availableBalance)
        try c.encode(reservedBalance, forKey: .reservedBalance)
        try c.encode(bankedBalance, forKey: .bankedBalance)
        try c.encode(bankedReservedBalance, forKey: .bankedReservedBalance)
        try c.encodeIfPresent(weekly, forKey: .weekly)
        let warningStr = warnings.isEmpty ? nil : warnings.map(\.rawValue).joined(separator: "|")
        try c.encodeIfPresent(warningStr, forKey: .warning)
    }
}

// MARK: - Grant

struct GrantRequest: Codable {
    let walletId: String
    let idempotencyKey: String
    let credits: Int
    let reason: String
    let metadata: [String: String]?
}

struct GrantResponse: Codable {
    let status: String
    let walletId: String
    let availableBalance: Int
    let reservedBalance: Int
    let ledgerId: String
}

// MARK: - Subscription Sync

public struct SubscriptionSyncRequest: Codable {
    public let walletId: String
    public let signedTransactionInfo: String

    public let originalTransactionId: String?
    public let productId: String?
    public let appAccountToken: String?
    
    public init(walletId: String, transaction: Transaction,signedTransactionInfo: String) {
        self.walletId = walletId
        self.signedTransactionInfo = signedTransactionInfo
        self.originalTransactionId = String(transaction.originalID)
        self.productId = transaction.productID
        self.appAccountToken = transaction.appAccountToken?.uuidString
    }
}

public struct SubscriptionSyncResponse: Codable {
    public let walletId: String
    public let availableBalance: Int
    public let reservedBalance: Int
    public let bankedBalance: Int
    public let bankedReservedBalance: Int
    public let weekly: WeeklyState

    public let status: String
    public let isActive: Bool
    public let originalTransactionId: String
    public let productId: String
    public let paidThrough: Date?
    public let anchorStart: Date?
}

//MARK: AppStore Verified Credit Grant Request
public struct AppStoreCreditGrantRequest: Codable {
    public let walletId: String
    public let signedTransactionInfo: String
    public let transactionId: String?
    public let productId: String?
    public let appAccountToken: String?

    public init(walletId: String, transaction: Transaction, signedTransactionInfo: String) {
        self.walletId = walletId
        self.signedTransactionInfo = signedTransactionInfo
        self.transactionId = String(transaction.id)
        self.productId = transaction.productID
        self.appAccountToken = transaction.appAccountToken?.uuidString
    }
}

public struct AppStoreCreditGrantResponse: Codable {
    public let walletId: String
    public let availableBalance: Int
    public let reservedBalance: Int
    public let bankedBalance: Int
    public let bankedReservedBalance: Int
    public let weekly: WeeklyState

    public let status: String
    public let alreadyGranted: Bool
    public let transactionId: String
    public let productId: String
    public let creditsGranted: Int
}



// MARK: - Balance

public struct BalanceResponse: Codable {
    let walletId: String
    let availableBalance: Int
    let reservedBalance: Int
}

// MARK: - Reserve

public struct ConsumeReserveRequest: Codable {
    let walletId: String
    let featureId: String
    let amount: Int
    let clientRequestId: String
    let reason: String?
    let metadata: [String: String]?
}

public struct ReservationResponse: Codable {
    public let status: String
    public let reservationId: String
    public let reservationToken: String
    public let walletId: String
    public let featureId: String
    public let amount: Int
    public let weeklyAmount: Int
    public let bankedAmount: Int
    public let taskId: String?
    public let expiresAt: Date
    public let maxExpiresAt: Date
    public let availableBalance: Int
    public let reservedBalance: Int
}

// MARK: - Cancel

struct ConsumeCancelRequest: Codable {
    let reservationId: String
    let taskId: String?
    let reason: String?
    let idempotencyKey: String?
    let metadata: [String: String]?
}

public struct ConsumeCancelResponse: Codable {
    public let status: String
    public let reservationId: String
    public let availableBalance: Int
    public let reservedBalance: Int
}

// MARK: - Reservation Status

struct ReservationStatusResponse: Codable {
    let reservationId: String
    let walletId: String
    let featureId: String
    let amount: Int
    let weeklyAmount: Int
    let bankedAmount: Int
    let status: String
    let taskId: String?
    let expiresAt: Date?
    let maxExpiresAt: Date?
    let createdAt: Date?
    let updatedAt: Date?
    let settledAt: Date?
    let canceledAt: Date?
    let expiredAt: Date?
    let cancelReason: String?
}


struct AttachRequest: Codable {
    let reservationId: String
    let reservationToken: String
    let taskId: String
    let featureId: String
    let amount: Double
}

public struct AttachResponse: Codable {
    public let status: String
    public let reservationId: String
    public let taskId: String?
    public let expiresAt: Date
}

struct SettleRequest: Codable {
    let reservationId: String
    let taskId: String
    let result: String
}

public struct SettleResponse: Codable {
    public let walletId: String
    public let availableBalance: Int
    public let reservedBalance: Int
    public let bankedBalance: Int
    public let bankedReservedBalance: Int
    public let weekly: WeeklyBalance
}

public struct WeeklyBalance: Codable {
    public let entitled: Int
    public let remaining: Int
    public let reserved: Int
    public let periodSeconds: Int
    public let anchorStart: Date
    public let grantedWeekIndex: Int
    public let periodStart: Date
    public let periodEnd: Date
    public let paidThrough: Date
}

struct ReserveCancelRequest: Codable {
    let reservationId: String
    let taskId: String
    let reason: String
}
