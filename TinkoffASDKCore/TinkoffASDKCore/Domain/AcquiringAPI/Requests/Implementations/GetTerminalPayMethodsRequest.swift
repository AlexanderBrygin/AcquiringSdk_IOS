//
//  GetTerminalPayMethodsRequest.swift
//  TinkoffASDKCore
//
//  Created by r.akhmadeev on 28.11.2022.
//

import Foundation

struct GetTerminalPayMethods: AcquiringRequest {
    let baseURL: URL
    let path: String
    let httpMethod: HTTPMethod = .get
    let tokenFormationStrategy: TokenFormationStrategy = .none

    init(baseURL: URL, terminalKey: String) {
        self.baseURL = baseURL
        path = .pathWithQueries(terminalKey: terminalKey)
    }
}

// MARK: - String + Helpers

private extension String {
    static let paySourceKey = "Paysource"
    static let paySourceValue = "SDK"

    static func pathWithQueries(terminalKey: String) -> String {
        "v2/GetTerminalPayMethods?\(Constants.Keys.terminalKey)=\(terminalKey)&\(paySourceKey)=\(paySourceValue)"
    }
}
