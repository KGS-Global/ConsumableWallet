//
//  WalletConfig.swift
//  ConsumableSampleApp
//
//  Created by Baker Mohammad Anas on 1/2/26.
//

import Foundation


public struct WalletConfig {
    let walletBaseURL: URL?
    let appId: String
    let appKey: String

    public init(walletBaseURL: String, appId: String, appKey: String) {
        self.walletBaseURL = URL(string: walletBaseURL)
        self.appId = appId
        self.appKey = appKey
    }
}
