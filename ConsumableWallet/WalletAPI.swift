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
    
    //REQUEST HEADER RELATED ISSUES.
    case unknownApp
    case badAppKey
    case walletNotResolved
    
    //RESERVATION ERRORS
    case unknownFeature
    case featureDisabled
    case featureCostInvalid
    case featureCostExceedsMaxFeatureCost
    case featureCostMismatch
    case invalidWallet
    case insufficientCredits
    
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
        case .validationError(let msg):
            return "Validation error: \(msg)"
            
        case .walletNotResolved:
            return "No Wallet Found, Wallet Bootstrap required, contact support!"
            
        case .unknownApp:
            return "Invalid App ID in request."
        case .badAppKey:
            return "Invalid APP Key in request."
            
        case .unknownFeature:
            return "Unknown Feature ID in request."
        case .featureDisabled:
            return "This feature is currently disabled."
        case .featureCostInvalid:
            return "Feature credit cost validation failed. Contact Support!"
        case .featureCostExceedsMaxFeatureCost:
            return "Feature credit cost exceeds the maximum allowed. Contact Support!"
        case .featureCostMismatch:
            return "Feature credit cost mismatched. Contact Support"
        case .invalidWallet:
            return "Wallet is invalid or inactive."
        
        case .decodingError(let msg):
            return "Decoding error: \(msg)"
        case .insufficientCredits:
            return "Insufficient credits"
        case .timeout:
            return "Request timed out"
        case .offline:
            return "No internet connection"
        case .cancelled:
            return "Request cancelled"
        case .clientCertificateMissing:
            return "Client certificate is missing."
        case .clientCertificateInvalid:
            return "Client certificate is invalid."
        case .tlsHandshakeFailed:
            return "Secure connection failed."
        case .unknown(let err):
            return "Unknown error: \(err.localizedDescription)"
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
        // Expected FastAPI shape:
        // { "detail": "INSUFFICIENT_CREDITS" }
        if let decoded = try? makeDecoder().decode(ServerErrorResponse.self, from: data),
           let detail = decoded.detail,
           !detail.isEmpty {
            return detail
        }

        // Fallback for unexpected/non-standard responses.
        let knownCodes = [
            "UNKNOWN_APP",
            "BAD_APP_KEY",

            "UNKNOWN_FEATURE",
            "FEATURE_DISABLED",
            "FEATURE_COST_INVALID",
            "FEATURE_COST_EXCEEDS_MAX_FEATURE_COST",
            "FEATURE_COST_MISMATCH",

            "INVALID_WALLET",
            "INSUFFICIENT_CREDITS"
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

        case "INVALID_WALLET":
            return .invalidWallet

        case "INSUFFICIENT_CREDITS":
            return .insufficientCredits

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

        do {
            return try await post(
                path: "/v1/consume/attach",
                body: req,
                responseType: AttachResponse.self
            )
        } catch let WalletAPIError.httpError(status, body) {
            if status == 409, body.contains("INSUFFICIENT_CREDITS") {
                throw WalletAPIError.insufficientCredits
            }
            throw WalletAPIError.httpError(status: status, body: body)
        }
    }

    func settleReserve(reservationId: String,
                       taskId: String,
                       result: String) async throws -> BalanceResponse {

        let req = SettleRequest(reservationId: reservationId, taskId: taskId, result: result)

        do {
            return try await post(
                path: "/v1/consume/settle",
                body: req,
                responseType: BalanceResponse.self
            )
        } catch let WalletAPIError.httpError(status, body) {
            if status == 409, body.contains("INSUFFICIENT_CREDITS") {
                throw WalletAPIError.insufficientCredits
            }
            throw WalletAPIError.httpError(status: status, body: body)
        }
    }

    func cancelReserve(reservationId: String,
                       taskId: String?,
                       reason: String?) async throws -> BalanceResponse {

        let req = ReserveCancelRequest(reservationId: reservationId, taskId: taskId, reason: reason)

        do {
            return try await post(
                path: "/v1/consume/cancel",
                body: req,
                responseType: BalanceResponse.self
            )
        } catch let WalletAPIError.httpError(status, body) {
            if status == 409, body.contains("INSUFFICIENT_CREDITS") {
                throw WalletAPIError.insufficientCredits
            }
            throw WalletAPIError.httpError(status: status, body: body)
        }
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

