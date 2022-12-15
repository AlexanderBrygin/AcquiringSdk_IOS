//
//  TerminalInfo.swift
//  TinkoffASDKCore
//
//  Created by r.akhmadeev on 29.11.2022.
//

import Foundation

/// Информация о доступных методах оплаты и настройках терминала
public struct TerminalInfo {
    /// Методы оплаты, доступные для данного терминала
    public let payMethods: [TerminalPayMethod]
}

// MARK: - TerminalInfo + Decodable

extension TerminalInfo: Decodable {
    private enum CodingKeys: String, CodingKey {
        case payMethods = "Paymethods"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Логика парсинга данных учитывает возможное добавление новых методов оплаты в контракт API эквайринга
        payMethods = try container
            .decodeIfPresent([SafeDecodable<TerminalPayMethod>].self, forKey: .payMethods)
            .or([])
            .compactMap(\.successfullyDecoded)
    }
}
