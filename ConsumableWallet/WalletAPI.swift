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

    func grantCredits(walletId: String,
                      idempotencyKey: String,
                      credits: Int,
                      reason: String,
                      metadata: [String: String]?) async throws -> SubscriptionSyncResponse
    
    func grantAppstoreVerifiedCredits(request: AppStoreCreditGrantRequest) async throws -> AppStoreCreditGrantResponse
    
    func syncAppstoreVerifiedSubscription(request: SubscriptionSyncRequest) async throws -> SubscriptionSyncResponse

    func reserveCredits(walletId: String,
                        featureId: String,
                        amount: Int,
                        clientRequestId: String,
                        reason: String?,
                        metadata: [String: String]?) async throws -> ReservationResponse

    func cancelReservation(reservationId: String,
                           taskId: String?,
                           reason: String?,
                           idempotencyKey: String?,
                           metadata: [String: String]?) async throws -> ConsumeCancelResponse

    func getReservationStatus(reservationId: String) async throws -> ReservationStatusResponse

    


    // MARK: Delete later
    func attachReserve(reservationId: String,
                       reservationToken: String,
                       taskId: String,
                       featureId: String,
                       amount: Double) async throws -> AttachResponse

    func settleReserve(reservationId: String,
                       taskId: String,
                       result: String) async throws -> SettleResponse

    func cancelReserve(reservationId: String,
                       taskId: String,
                       reason: String) async throws -> SettleResponse
}

// MARK: - API Errors

public enum WalletAPIError: Error, LocalizedError {
    case invalidBaseURL(String)
    case httpError(status: Int, body: String)
    case decodingError(String)
    case insufficientCredits
    case timeout
    case offline
    case cancelled
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidBaseURL(let s):
            return "Invalid base URL: \(s)"
        case .httpError(let status, let body):
            return "HTTP \(status): \(body)"
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

    init(with walletConfig: WalletConfig, session: URLSession = .shared) {
        guard let url = walletConfig.walletBaseURL else {
            fatalError("Invalid base URL string: \(walletConfig.walletBaseURL?.absoluteString)")
        }
        self.baseURL = url
        self.appId = walletConfig.appId
        self.appKey = walletConfig.appKey
        self.session = session
    }

    // MARK: - Public API

    func bootstrap(request: BootstrapRequest) async throws -> BootstrapResponse {
        return try await post(
            path: "/v1/session/bootstrap",
            body: request,
            responseType: BootstrapResponse.self
        )
    }

    func grantCredits(walletId: String,
                      idempotencyKey: String,
                      credits: Int,
                      reason: String,
                      metadata: [String: String]? = nil) async throws -> SubscriptionSyncResponse {
        let req = GrantRequest(
            walletId: walletId,
            idempotencyKey: idempotencyKey,
            credits: credits,
            reason: reason,
            metadata: metadata
        )
        return try await post(
            path: "/v1/credits/grant",
            body: req,
            responseType: SubscriptionSyncResponse.self
        )
    }
    
    func grantAppstoreVerifiedCredits(request: AppStoreCreditGrantRequest) async throws -> AppStoreCreditGrantResponse {
        return try await post(
            path: "/v1/appstore/credits/grant",
            body: request,
            responseType: AppStoreCreditGrantResponse.self)
    }
    
//    func syncSubscription(walletId: String,
//                          isActive: Bool,
//                          paidThrough: Date?,
//                          anchorStart: Date?) async throws -> SubscriptionSyncResponse {
//        let req = SubscriptionSyncRequest(
//            walletId: walletId,
//            isActive: isActive,
//            paidThrough: paidThrough,
//            anchorStart: anchorStart
//        )
//        return try await post(
//            path: "/v1/subscription/sync",
//            body: req,
//            responseType: SubscriptionSyncResponse.self
//        )
//    }
    
    func syncAppstoreVerifiedSubscription(request: SubscriptionSyncRequest) async throws -> SubscriptionSyncResponse {
        return try await post(
            path: "/v1/appstore/subscription/sync",
            body: request,
            responseType: SubscriptionSyncResponse.self)
    }

    func reserveCredits(walletId: String,
                        featureId: String,
                        amount: Int,
                        clientRequestId: String,
                        reason: String? = nil,
                        metadata: [String: String]? = nil) async throws -> ReservationResponse {
        let req = ConsumeReserveRequest(
            walletId: walletId,
            featureId: featureId,
            amount: amount,
            clientRequestId: clientRequestId,
            reason: reason,
            metadata: metadata
        )
        do {
            return try await post(
                path: "/v1/consume/reserve",
                body: req,
                responseType: ReservationResponse.self
            )
        } catch let WalletAPIError.httpError(status, body) {
            if status == 409, body.contains("INSUFFICIENT_CREDITS") {
                throw WalletAPIError.insufficientCredits
            }
            throw WalletAPIError.httpError(status: status, body: body)
        }
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
            
            print("BAKER TEST: Request:", request.url)
            print("BAKER TEST: statusCode: ", http.statusCode)
            
            guard (200..<300).contains(http.statusCode) else {
                let bodyStr = String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
                throw WalletAPIError.httpError(status: http.statusCode, body: bodyStr)
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
                       result: String) async throws -> SettleResponse {

        let req = SettleRequest(reservationId: reservationId, taskId: taskId, result: result)

        do {
            return try await post(
                path: "/v1/consume/settle",
                body: req,
                responseType: SettleResponse.self
            )
        } catch let WalletAPIError.httpError(status, body) {
            if status == 409, body.contains("INSUFFICIENT_CREDITS") {
                throw WalletAPIError.insufficientCredits
            }
            throw WalletAPIError.httpError(status: status, body: body)
        }
    }

    func cancelReserve(reservationId: String,
                       taskId: String,
                       reason: String) async throws -> SettleResponse {

        let req = ReserveCancelRequest(reservationId: reservationId, taskId: taskId, reason: reason)

        do {
            return try await post(
                path: "/v1/consume/cancel",
                body: req,
                responseType: SettleResponse.self
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
