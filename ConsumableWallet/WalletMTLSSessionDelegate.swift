//
//  WalletMTLSSessionDelegate.swift
//  Pods
//
//  Created by Baker Mohammad Anas on 7/16/26.
//

import Foundation
import Security

final class WalletMTLSSessionDelegate: NSObject, URLSessionDelegate {

    private let identity: SecIdentity
    private let certificateChain: [SecCertificate]

    init(config: MTLSConfig) throws {
        guard let certificateURL = config.bundle.url(
            forResource: config.certificateResourceName,
            withExtension: config.certificateExtension
        ) else {
            throw WalletAPIError.clientCertificateMissing
        }

        let certificateData = try Data(contentsOf: certificateURL)

        let imported = try Self.importPKCS12(
            data: certificateData,
            password: config.certificatePassword
        )

        self.identity = imported.identity
        self.certificateChain = imported.certificates

        super.init()
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge
    ) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        switch challenge.protectionSpace.authenticationMethod {
        case NSURLAuthenticationMethodClientCertificate:
            let credential = URLCredential(
                identity: identity,
                certificates: certificateChain,
                persistence: .forSession
            )
            return (.useCredential, credential)

        case NSURLAuthenticationMethodServerTrust:
            return (.performDefaultHandling, nil)

        default:
            return (.performDefaultHandling, nil)
        }
    }

    private static func importPKCS12(
        data: Data,
        password: String
    ) throws -> (identity: SecIdentity, certificates: [SecCertificate]) {
        let options: [String: Any] = [
            kSecImportExportPassphrase as String: password
        ]

        var rawItems: CFArray?
        let status = SecPKCS12Import(
            data as CFData,
            options as CFDictionary,
            &rawItems
        )

        guard status == errSecSuccess,
              let items = rawItems as? [[String: Any]],
              let firstItem = items.first,
              let identityRef = firstItem[kSecImportItemIdentity as String]
        else {
            throw WalletAPIError.clientCertificateInvalid
        }

        let identity = identityRef as! SecIdentity

        let certs = firstItem[kSecImportItemCertChain as String] as? [SecCertificate] ?? []

        return (identity, certs)
    }
}
