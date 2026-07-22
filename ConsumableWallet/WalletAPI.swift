//
//  WalletAPI.swift
//  ConsumableSampleApp
//
//  Created by Baker Mohammad Anas on 27/1/26.
//

import Foundation

// MARK: - Protocol

protocol WalletAPIType {
    func bootstrap(request: BootstrapRequest) async throws -> BootstrapResponse
    
    func grantAppstoreVerifiedCredits(request: AppStoreCreditGrantRequest) async throws -> AppStoreCreditGrantResponse
    
    func syncAppstoreVerifiedSubscription(request: SubscriptionSyncRequest) async throws -> SubscriptionSyncResponse

    func reserveCredits(request: ReservationRequest) async throws -> ReservationResponse

    func getReservationStatus(reservationId: String) async throws -> ReservationStatusResponse
    
    func fetchAppConfig() async throws -> AppCreditConfigResponse


    // MARK: Delete later
    func attachReserve(reservationId: String,
                       reservationToken: String,
                       taskId: String,
                       featureId: String,
                       amount: Double) async throws -> AttachResponse

    func settleReserve(reservationId: String,
                       taskId: String,
                       result: String) async throws -> BalanceResponse

    func cancelReserve(reservationId: String,
                       taskId: String?,
                       reason: String?) async throws -> BalanceResponse
}

// MARK: - API Errors

public enum WalletAPIError: Error, LocalizedError {
    case httpError(status: Int, body: String)
    case validationError(String)
    case walletNotResolved
    case unknownApp
    case badAppKey
    case badInternalKey
    case walletNotFound
    case invalidWallet
    case deviceLocalRequired
    case invalidAppWeekSeconds
    case unknownFeature
    case featureDisabled
    case featureCostInvalid
    case featureCostExceedsMaxFeatureCost
    case featureCostMismatch
    case featureIdMismatch
    case invalidReservationToken
    case reservationNotFound
    case reservationTaskMismatch
    case reservationAlreadySettled
    case reservationAlreadyCanceled
    case reservationAlreadyExpired
    case reservationExpired
    case invalidStateTransition
    case settlementNotAllowedAfterExpiry
    case taskIdRequiredForAttachedReservation
    case reservationBalanceMismatch
    case maxReservationLifetimeExceeded
    case invalidExtension
    case insufficientCredits
    case appStoreInvalidJWS
    case appStoreInvalidJWSPayload
    case appStoreTransactionPayloadIncomplete
    case appStoreTransactionVerificationFailed
    case appStoreBundleMismatch
    case appStoreEnvironmentMismatch
    case appStoreUnknownProduct
    case appStoreProductNotConsumable
    case appStoreTransactionRevoked
    case appStoreTransactionIdMismatch
    case appStoreOriginalTransactionIdMismatch
    case appStoreProductIdMismatch
    case appStoreAccountTokenMismatch
    case appStoreAccountTokenWalletMismatch
    case appStoreTransactionAlreadyGrantedToAnotherWallet
    case appStoreProductNotSubscription
    case appStoreUnknownSubscriptionProduct
    case appStoreSubscriptionExpiresDateMissing
    case appStoreSubscriptionPurchaseDateMissing
    case appStoreGrantRetryExhausted
    case appStoreBundleIdNotConfigured
    case appStoreEnvironmentNotConfigured
    case appStoreEnvironmentInvalid
    case appStoreCreditProductsInvalid
    case appStoreCreditProductsNotConfigured
    case appStoreSubscriptionProductsInvalid
    case appStoreSubscriptionProductsNotConfigured
    case appStoreAppAppleIdInvalid
    case appStoreAppAppleIdRequiredForProduction
    case appStoreRootCertsDirNotConfigured
    case appStoreRootCertsDirNotFound
    case appStoreRootCertsMissing
    case appStoreServerLibraryNotInstalled
    case noAdjustment
    case negativeBalanceNotAllowed
    case decodingError(String)
    case timeout
    case offline
    case cancelled
    case clientCertificateMissing
    case clientCertificateInvalid
    case tlsHandshakeFailed
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .httpError(let status, let body):
            return "HTTP \(status): \(body)"
        case .validationError(let message):
            return "Validation error: \(message)"
        case .walletNotResolved:
            return "No wallet found. Wallet bootstrap is required."
        case .unknownApp:
            return "Invalid App ID in request."
        case .badAppKey:
            return "Invalid app key in request."
        case .badInternalKey:
            return "Invalid internal API key."
        case .walletNotFound:
            return "Wallet was not found."
        case .invalidWallet:
            return "Wallet is invalid or inactive."
        case .deviceLocalRequired:
            return "A local device identity is required."
        case .invalidAppWeekSeconds:
            return "The app's weekly credit period is invalid."
        case .unknownFeature:
            return "Unknown feature ID in request."
        case .featureDisabled:
            return "This feature is currently disabled."
        case .featureCostInvalid:
            return "The feature credit cost configuration is invalid."
        case .featureCostExceedsMaxFeatureCost:
            return "The feature credit cost exceeds the configured maximum."
        case .featureCostMismatch:
            return "The feature credit cost does not match the server configuration."
        case .featureIdMismatch:
            return "The feature ID does not match the reservation."
        case .invalidReservationToken:
            return "The reservation token is invalid or expired."
        case .reservationNotFound:
            return "Reservation was not found."
        case .reservationTaskMismatch:
            return "The reservation is attached to a different task."
        case .reservationAlreadySettled:
            return "The reservation has already been settled."
        case .reservationAlreadyCanceled:
            return "The reservation has already been canceled."
        case .reservationAlreadyExpired:
            return "The reservation has already expired."
        case .reservationExpired:
            return "The reservation has expired."
        case .invalidStateTransition:
            return "The reservation cannot perform this operation in its current state."
        case .settlementNotAllowedAfterExpiry:
            return "The reservation cannot be settled after expiry."
        case .taskIdRequiredForAttachedReservation:
            return "A task ID is required for an attached reservation."
        case .reservationBalanceMismatch:
            return "The wallet's reserved balance does not match the reservation."
        case .maxReservationLifetimeExceeded:
            return "The reservation has reached its maximum lifetime."
        case .invalidExtension:
            return "The requested reservation extension is invalid."
        case .insufficientCredits:
            return "Insufficient credits."
        case .appStoreInvalidJWS:
            return "The App Store signed transaction is invalid."
        case .appStoreInvalidJWSPayload:
            return "The App Store signed transaction payload is invalid."
        case .appStoreTransactionPayloadIncomplete:
            return "The App Store transaction payload is incomplete."
        case .appStoreTransactionVerificationFailed:
            return "The App Store transaction could not be verified."
        case .appStoreBundleMismatch:
            return "The App Store transaction belongs to a different app."
        case .appStoreEnvironmentMismatch:
            return "The App Store transaction environment does not match the server configuration."
        case .appStoreUnknownProduct:
            return "The App Store product is not configured."
        case .appStoreProductNotConsumable:
            return "The App Store product is not a consumable credit product."
        case .appStoreTransactionRevoked:
            return "The App Store transaction has been revoked."
        case .appStoreTransactionIdMismatch:
            return "The transaction ID does not match the verified App Store transaction."
        case .appStoreOriginalTransactionIdMismatch:
            return "The original transaction ID does not match the verified App Store transaction."
        case .appStoreProductIdMismatch:
            return "The product ID does not match the verified App Store transaction."
        case .appStoreAccountTokenMismatch:
            return "The app account token does not match the verified App Store transaction."
        case .appStoreAccountTokenWalletMismatch:
            return "The App Store transaction does not belong to this wallet."
        case .appStoreTransactionAlreadyGrantedToAnotherWallet:
            return "The App Store transaction was already granted to another wallet."
        case .appStoreProductNotSubscription:
            return "The App Store product is not a subscription."
        case .appStoreUnknownSubscriptionProduct:
            return "The App Store subscription product is not configured."
        case .appStoreSubscriptionExpiresDateMissing:
            return "The App Store subscription transaction has no expiration date."
        case .appStoreSubscriptionPurchaseDateMissing:
            return "The App Store subscription transaction has no purchase date."
        case .appStoreGrantRetryExhausted:
            return "The server could not complete the App Store credit grant."
        case .appStoreBundleIdNotConfigured:
            return "The App Store bundle ID is not configured on the server."
        case .appStoreEnvironmentNotConfigured:
            return "The App Store environment is not configured on the server."
        case .appStoreEnvironmentInvalid:
            return "The configured App Store environment is invalid."
        case .appStoreCreditProductsInvalid:
            return "The App Store credit-product configuration is invalid."
        case .appStoreCreditProductsNotConfigured:
            return "No App Store credit products are configured."
        case .appStoreSubscriptionProductsInvalid:
            return "The App Store subscription-product configuration is invalid."
        case .appStoreSubscriptionProductsNotConfigured:
            return "No App Store subscription products are configured."
        case .appStoreAppAppleIdInvalid:
            return "The configured App Store Apple ID is invalid."
        case .appStoreAppAppleIdRequiredForProduction:
            return "An App Store Apple ID is required for production verification."
        case .appStoreRootCertsDirNotConfigured:
            return "The App Store root-certificate directory is not configured."
        case .appStoreRootCertsDirNotFound:
            return "The App Store root-certificate directory was not found."
        case .appStoreRootCertsMissing:
            return "The App Store root certificates are missing."
        case .appStoreServerLibraryNotInstalled:
            return "The App Store Server Library is not installed on the server."
        case .noAdjustment:
            return "At least one credit adjustment must be non-zero."
        case .negativeBalanceNotAllowed:
            return "The adjustment would make a wallet balance negative."
        case .decodingError(let message):
            return "Decoding error: \(message)"
        case .timeout:
            return "Request timed out."
        case .offline:
            return "No internet connection."
        case .cancelled:
            return "Request cancelled."
        case .clientCertificateMissing:
            return "Client certificate is missing."
        case .clientCertificateInvalid:
            return "Client certificate is invalid."
        case .tlsHandshakeFailed:
            return "Secure connection failed."
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}

// MARK: - WalletAPI Implementation

final class WalletAPI: WalletAPIType {

    private let baseURL: URL
    private let session: URLSession
    private let appId: String
    private let appKey: String

    init(with walletConfig: WalletConfig, session: URLSession? = nil) {
        guard let url = walletConfig.walletBaseURL else {
            fatalError("Invalid base URL string: \(String(describing: walletConfig.walletBaseURL?.absoluteString))")
        }
        self.baseURL = url
        self.appId = walletConfig.appId
        self.appKey = walletConfig.appKey
        
        if let session {
            self.session = session
        } else if let mtlsConfig = walletConfig.mtlsConfig {
            do {
                self.session = try WalletURLSessionFactory.makeMTLSSession(
                    config: mtlsConfig
                )
            } catch {
                fatalError("ConsumableWallet:: Failed to create mTLS wallet URLSession: \(error)")
            }
        } else {
            self.session = .shared
        }
    }

    // MARK: - Public API

    func bootstrap(request: BootstrapRequest) async throws -> BootstrapResponse {
        return try await post(
            path: "/v1/session/bootstrap",
            body: request,
            responseType: BootstrapResponse.self
        )
    }
    
    func grantAppstoreVerifiedCredits(request: AppStoreCreditGrantRequest) async throws -> AppStoreCreditGrantResponse {
        return try await post(
            path: "/v1/appstore/credits/grant",
            body: request,
            responseType: AppStoreCreditGrantResponse.self)
    }
    
    func syncAppstoreVerifiedSubscription(request: SubscriptionSyncRequest) async throws -> SubscriptionSyncResponse {
        return try await post(
            path: "/v1/appstore/subscription/sync",
            body: request,
            responseType: SubscriptionSyncResponse.self)
    }

    func reserveCredits(request: ReservationRequest) async throws -> ReservationResponse {
        return try await post(
            path: "/v1/consume/reserve",
            body: request,
            responseType: ReservationResponse.self
        )
    }

    func cancelReservation(reservationId: String,
                           taskId: String? = nil,
                           reason: String? = nil,
                           idempotencyKey: String? = nil,
                           metadata: [String: String]? = nil) async throws -> ConsumeCancelResponse {
        let req = ConsumeCancelRequest(
            reservationId: reservationId,
            taskId: taskId,
            reason: reason,
            idempotencyKey: idempotencyKey,
            metadata: metadata
        )
        return try await post(
            path: "/v1/consume/cancel",
            body: req,
            responseType: ConsumeCancelResponse.self
        )
    }

    func getReservationStatus(reservationId: String) async throws -> ReservationStatusResponse {
        return try await get(
            path: "/v1/consume/reservations/\(reservationId)",
            responseType: ReservationStatusResponse.self
        )
    }
    
    public func fetchAppConfig() async throws -> AppCreditConfigResponse {
        return try await get(
            path: "/v1/app/config",
            responseType: AppCreditConfigResponse.self
        )
    }

    
    
    

    // MARK: - Core HTTP

    private func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { dec in
            let raw = try dec.singleValueContainer().decode(String.self)
            // Try with timezone first, then bare datetime (server omits timezone offset)
            if let date = Self.iso8601WithTZ.date(from: raw) { return date }
            if let date = Self.iso8601NoTZ.date(from: raw) { return date }
            throw DecodingError.dataCorrupted(.init(
                codingPath: dec.codingPath,
                debugDescription: "Cannot parse date: \(raw)"
            ))
        }
        return decoder
    }

    private static let iso8601WithTZ: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private static let iso8601NoTZ: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime, .withDashSeparatorInDate]
        return f
    }()

    private func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private func post<T: Encodable, R: Decodable>(path: String,
                                                   body: T,
                                                   responseType: R.Type) async throws -> R {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(appId, forHTTPHeaderField: "X-App-Id")
        request.setValue(appKey, forHTTPHeaderField: "X-App-Key")
        request.timeoutInterval = 20
        request.httpBody = try makeEncoder().encode(AnyEncodable(body))
        return try await execute(request: request, responseType: responseType)
    }

    private func get<R: Decodable>(path: String, responseType: R.Type) async throws -> R {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(appId, forHTTPHeaderField: "X-App-Id")
        request.setValue(appKey, forHTTPHeaderField: "X-App-Key")
        request.timeoutInterval = 20
        return try await execute(request: request, responseType: responseType)
    }

    private func execute<R: Decodable>(request: URLRequest, responseType: R.Type) async throws -> R {
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw WalletAPIError.httpError(status: -1, body: "Non-HTTP response")
            }
            
            print("ConsumableWallet:: Request url: ", request.url ?? "--")
            print("ConsumableWallet:: statusCode: ", http.statusCode)
            
            guard (200..<300).contains(http.statusCode) else {
                let bodyStr = String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
//                throw WalletAPIError.httpError(status: http.statusCode, body: bodyStr)
                throw mapServerError(status: http.statusCode, body: bodyStr, data: data)
            }
            do {
                return try makeDecoder().decode(R.self, from: data)
            } catch {
                let raw = String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
                throw WalletAPIError.decodingError("Failed to decode \(R.self). Raw: \(raw)")
            }
        } catch let apiErr as WalletAPIError {
            throw apiErr
        } catch let err as URLError {
            switch err.code {
            case .timedOut:
                throw WalletAPIError.timeout
            case .notConnectedToInternet, .networkConnectionLost, .cannotFindHost, .cannotConnectToHost:
                throw WalletAPIError.offline
            case .cancelled:
                throw WalletAPIError.cancelled
            default:
                throw WalletAPIError.unknown(err)
            }
        } catch is CancellationError {
            throw WalletAPIError.cancelled
        } catch {
            throw WalletAPIError.unknown(error)
        }
    }
    private struct ServerErrorResponse: Decodable {
    
        let detail: String?
    }

    private func extractServerErrorCode(from data: Data, fallbackBody: String) -> String? {
        // Standard FastAPI application-error shape:
        // { "detail": "ERROR_CODE" }
        if let decoded = try? makeDecoder().decode(ServerErrorResponse.self, from: data),
           let detail = decoded.detail,
           !detail.isEmpty {
            return detail
        }

        // Fallback for proxies or non-standard error bodies that still include
        // one of the server's stable application error codes.
        let knownCodes = [
            "UNKNOWN_APP",
            "BAD_APP_KEY",
            "BAD_INTERNAL_KEY",
            "WALLET_NOT_FOUND",
            "INVALID_WALLET",
            "DEVICE_LOCAL_REQUIRED",
            "INVALID_APP_WEEK_SECONDS",
            "UNKNOWN_FEATURE",
            "FEATURE_DISABLED",
            "FEATURE_COST_INVALID",
            "FEATURE_COST_EXCEEDS_MAX_FEATURE_COST",
            "FEATURE_COST_MISMATCH",
            "FEATURE_ID_MISMATCH",
            "INVALID_RESERVATION_TOKEN",
            "RESERVATION_NOT_FOUND",
            "RESERVATION_TASK_MISMATCH",
            "RESERVATION_ALREADY_SETTLED",
            "RESERVATION_ALREADY_CANCELED",
            "RESERVATION_ALREADY_EXPIRED",
            "RESERVATION_EXPIRED",
            "INVALID_STATE_TRANSITION",
            "SETTLEMENT_NOT_ALLOWED_AFTER_EXPIRY",
            "TASK_ID_REQUIRED_FOR_ATTACHED_RESERVATION",
            "RESERVATION_BALANCE_MISMATCH",
            "MAX_RESERVATION_LIFETIME_EXCEEDED",
            "INVALID_EXTENSION",
            "INSUFFICIENT_CREDITS",
            "APPSTORE_INVALID_JWS",
            "APPSTORE_INVALID_JWS_PAYLOAD",
            "APPSTORE_TRANSACTION_PAYLOAD_INCOMPLETE",
            "APPSTORE_TRANSACTION_VERIFICATION_FAILED",
            "APPSTORE_BUNDLE_MISMATCH",
            "APPSTORE_ENVIRONMENT_MISMATCH",
            "APPSTORE_UNKNOWN_PRODUCT",
            "APPSTORE_PRODUCT_NOT_CONSUMABLE",
            "APPSTORE_TRANSACTION_REVOKED",
            "APPSTORE_TRANSACTION_ID_MISMATCH",
            "APPSTORE_ORIGINAL_TRANSACTION_ID_MISMATCH",
            "APPSTORE_PRODUCT_ID_MISMATCH",
            "APPSTORE_ACCOUNT_TOKEN_MISMATCH",
            "APPSTORE_ACCOUNT_TOKEN_WALLET_MISMATCH",
            "APPSTORE_TRANSACTION_ALREADY_GRANTED_TO_ANOTHER_WALLET",
            "APPSTORE_PRODUCT_NOT_SUBSCRIPTION",
            "APPSTORE_UNKNOWN_SUBSCRIPTION_PRODUCT",
            "APPSTORE_SUBSCRIPTION_EXPIRES_DATE_MISSING",
            "APPSTORE_SUBSCRIPTION_PURCHASE_DATE_MISSING",
            "APPSTORE_GRANT_RETRY_EXHAUSTED",
            "APPSTORE_BUNDLE_ID_NOT_CONFIGURED",
            "APPSTORE_ENVIRONMENT_NOT_CONFIGURED",
            "APPSTORE_ENVIRONMENT_INVALID",
            "APPSTORE_CREDIT_PRODUCTS_INVALID",
            "APPSTORE_CREDIT_PRODUCTS_NOT_CONFIGURED",
            "APPSTORE_SUBSCRIPTION_PRODUCTS_INVALID",
            "APPSTORE_SUBSCRIPTION_PRODUCTS_NOT_CONFIGURED",
            "APPSTORE_APP_APPLE_ID_INVALID",
            "APPSTORE_APP_APPLE_ID_REQUIRED_FOR_PRODUCTION",
            "APPSTORE_ROOT_CERTS_DIR_NOT_CONFIGURED",
            "APPSTORE_ROOT_CERTS_DIR_NOT_FOUND",
            "APPSTORE_ROOT_CERTS_MISSING",
            "APPSTORE_SERVER_LIBRARY_NOT_INSTALLED",
            "NO_ADJUSTMENT",
            "NEGATIVE_BALANCE_NOT_ALLOWED"
        ]

        return knownCodes.first { fallbackBody.contains($0) }
    }

    private func mapServerError(status: Int, body: String, data: Data) -> WalletAPIError {
        guard let code = extractServerErrorCode(from: data, fallbackBody: body) else {
            if status == 422 {
                return .validationError(body)
            }

            return .httpError(status: status, body: body)
        }

        switch code {
        case "UNKNOWN_APP":
            return .unknownApp
        case "BAD_APP_KEY":
            return .badAppKey
        case "BAD_INTERNAL_KEY":
            return .badInternalKey
        case "WALLET_NOT_FOUND":
            return .walletNotFound
        case "INVALID_WALLET":
            return .invalidWallet
        case "DEVICE_LOCAL_REQUIRED":
            return .deviceLocalRequired
        case "INVALID_APP_WEEK_SECONDS":
            return .invalidAppWeekSeconds
        case "UNKNOWN_FEATURE":
            return .unknownFeature
        case "FEATURE_DISABLED":
            return .featureDisabled
        case "FEATURE_COST_INVALID":
            return .featureCostInvalid
        case "FEATURE_COST_EXCEEDS_MAX_FEATURE_COST":
            return .featureCostExceedsMaxFeatureCost
        case "FEATURE_COST_MISMATCH":
            return .featureCostMismatch
        case "FEATURE_ID_MISMATCH":
            return .featureIdMismatch
        case "INVALID_RESERVATION_TOKEN":
            return .invalidReservationToken
        case "RESERVATION_NOT_FOUND":
            return .reservationNotFound
        case "RESERVATION_TASK_MISMATCH":
            return .reservationTaskMismatch
        case "RESERVATION_ALREADY_SETTLED":
            return .reservationAlreadySettled
        case "RESERVATION_ALREADY_CANCELED":
            return .reservationAlreadyCanceled
        case "RESERVATION_ALREADY_EXPIRED":
            return .reservationAlreadyExpired
        case "RESERVATION_EXPIRED":
            return .reservationExpired
        case "INVALID_STATE_TRANSITION":
            return .invalidStateTransition
        case "SETTLEMENT_NOT_ALLOWED_AFTER_EXPIRY":
            return .settlementNotAllowedAfterExpiry
        case "TASK_ID_REQUIRED_FOR_ATTACHED_RESERVATION":
            return .taskIdRequiredForAttachedReservation
        case "RESERVATION_BALANCE_MISMATCH":
            return .reservationBalanceMismatch
        case "MAX_RESERVATION_LIFETIME_EXCEEDED":
            return .maxReservationLifetimeExceeded
        case "INVALID_EXTENSION":
            return .invalidExtension
        case "INSUFFICIENT_CREDITS":
            return .insufficientCredits
        case "APPSTORE_INVALID_JWS":
            return .appStoreInvalidJWS
        case "APPSTORE_INVALID_JWS_PAYLOAD":
            return .appStoreInvalidJWSPayload
        case "APPSTORE_TRANSACTION_PAYLOAD_INCOMPLETE":
            return .appStoreTransactionPayloadIncomplete
        case "APPSTORE_TRANSACTION_VERIFICATION_FAILED":
            return .appStoreTransactionVerificationFailed
        case "APPSTORE_BUNDLE_MISMATCH":
            return .appStoreBundleMismatch
        case "APPSTORE_ENVIRONMENT_MISMATCH":
            return .appStoreEnvironmentMismatch
        case "APPSTORE_UNKNOWN_PRODUCT":
            return .appStoreUnknownProduct
        case "APPSTORE_PRODUCT_NOT_CONSUMABLE":
            return .appStoreProductNotConsumable
        case "APPSTORE_TRANSACTION_REVOKED":
            return .appStoreTransactionRevoked
        case "APPSTORE_TRANSACTION_ID_MISMATCH":
            return .appStoreTransactionIdMismatch
        case "APPSTORE_ORIGINAL_TRANSACTION_ID_MISMATCH":
            return .appStoreOriginalTransactionIdMismatch
        case "APPSTORE_PRODUCT_ID_MISMATCH":
            return .appStoreProductIdMismatch
        case "APPSTORE_ACCOUNT_TOKEN_MISMATCH":
            return .appStoreAccountTokenMismatch
        case "APPSTORE_ACCOUNT_TOKEN_WALLET_MISMATCH":
            return .appStoreAccountTokenWalletMismatch
        case "APPSTORE_TRANSACTION_ALREADY_GRANTED_TO_ANOTHER_WALLET":
            return .appStoreTransactionAlreadyGrantedToAnotherWallet
        case "APPSTORE_PRODUCT_NOT_SUBSCRIPTION":
            return .appStoreProductNotSubscription
        case "APPSTORE_UNKNOWN_SUBSCRIPTION_PRODUCT":
            return .appStoreUnknownSubscriptionProduct
        case "APPSTORE_SUBSCRIPTION_EXPIRES_DATE_MISSING":
            return .appStoreSubscriptionExpiresDateMissing
        case "APPSTORE_SUBSCRIPTION_PURCHASE_DATE_MISSING":
            return .appStoreSubscriptionPurchaseDateMissing
        case "APPSTORE_GRANT_RETRY_EXHAUSTED":
            return .appStoreGrantRetryExhausted
        case "APPSTORE_BUNDLE_ID_NOT_CONFIGURED":
            return .appStoreBundleIdNotConfigured
        case "APPSTORE_ENVIRONMENT_NOT_CONFIGURED":
            return .appStoreEnvironmentNotConfigured
        case "APPSTORE_ENVIRONMENT_INVALID":
            return .appStoreEnvironmentInvalid
        case "APPSTORE_CREDIT_PRODUCTS_INVALID":
            return .appStoreCreditProductsInvalid
        case "APPSTORE_CREDIT_PRODUCTS_NOT_CONFIGURED":
            return .appStoreCreditProductsNotConfigured
        case "APPSTORE_SUBSCRIPTION_PRODUCTS_INVALID":
            return .appStoreSubscriptionProductsInvalid
        case "APPSTORE_SUBSCRIPTION_PRODUCTS_NOT_CONFIGURED":
            return .appStoreSubscriptionProductsNotConfigured
        case "APPSTORE_APP_APPLE_ID_INVALID":
            return .appStoreAppAppleIdInvalid
        case "APPSTORE_APP_APPLE_ID_REQUIRED_FOR_PRODUCTION":
            return .appStoreAppAppleIdRequiredForProduction
        case "APPSTORE_ROOT_CERTS_DIR_NOT_CONFIGURED":
            return .appStoreRootCertsDirNotConfigured
        case "APPSTORE_ROOT_CERTS_DIR_NOT_FOUND":
            return .appStoreRootCertsDirNotFound
        case "APPSTORE_ROOT_CERTS_MISSING":
            return .appStoreRootCertsMissing
        case "APPSTORE_SERVER_LIBRARY_NOT_INSTALLED":
            return .appStoreServerLibraryNotInstalled
        case "NO_ADJUSTMENT":
            return .noAdjustment
        case "NEGATIVE_BALANCE_NOT_ALLOWED":
            return .negativeBalanceNotAllowed
        default:
            return .httpError(status: status, body: body)
        }
    }
}

extension WalletAPI {
    func attachReserve(reservationId: String,
                       reservationToken: String,
                       taskId: String,
                       featureId: String,
                       amount: Double) async throws -> AttachResponse {
        let req = AttachRequest(reservationId: reservationId,
                                reservationToken: reservationToken,
                                taskId: taskId,
                                featureId: featureId,
                                amount: amount)

        return try await post(
            path: "/v1/consume/attach",
            body: req,
            responseType: AttachResponse.self
        )
    }

    func settleReserve(reservationId: String,
                       taskId: String,
                       result: String) async throws -> BalanceResponse {

        let req = SettleRequest(reservationId: reservationId, taskId: taskId, result: result)

        return try await post(
            path: "/v1/consume/settle",
            body: req,
            responseType: BalanceResponse.self
        )
    }

    func cancelReserve(reservationId: String,
                       taskId: String?,
                       reason: String?) async throws -> BalanceResponse {

        let req = ReserveCancelRequest(reservationId: reservationId, taskId: taskId, reason: reason)

        return try await post(
            path: "/v1/consume/cancel",
            body: req,
            responseType: BalanceResponse.self
        )
    }
}

// MARK: - AnyEncodable

private struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void

    init<T: Encodable>(_ value: T) {
        _encode = value.encode
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}


