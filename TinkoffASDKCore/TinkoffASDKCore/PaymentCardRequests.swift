//
//  PaymentCardRequests.swift
//  TinkoffASDKCore
//
//  Copyright (c) 2020 Tinkoff Bank
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation

// MARK: Список карт

public final class CardListRequest: RequestOperation, AcquiringRequestTokenParams {
    // MARK: RequestOperation

    public var name = "GetCardList"

    public var parameters: JSONObject?

    // MARK: AcquiringRequestTokenParams

    ///
    /// отмечаем параметры которые участвуют в вычислении `token`
    public var tokenParamsKey: Set<String> = [GetCardListData.CodingKeys.customerKey.rawValue]

    ///
    /// - Parameter requestData: `GetCardListData`
    public init(data: GetCardListData) {
        if let json = try? data.encode2JSONObject() {
            parameters = json
        }
    }
}

public struct CardListResponse: ResponseOperation {
    public var success: Bool = true
    public var errorCode: Int = 0
    public var errorMessage: String?
    public var errorDetails: String?
    public var terminalKey: String?
    public var cards: [PaymentCard]

    private enum CodingKeys: String, CodingKey {
        case success = "Success"
        case errorCode = "ErrorCode"
        case errorMessage = "Message"
        case errorDetails = "Details"
        case terminalKey = "TerminalKey"
        case cards = "Cards"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decode(Bool.self, forKey: .success)
        errorCode = try container.decode(Int.self, forKey: .errorCode)
        errorMessage = try? container.decode(String.self, forKey: .errorMessage)
        errorDetails = try? container.decode(String.self, forKey: .errorDetails)
        terminalKey = try? container.decode(String.self, forKey: .terminalKey)
        //
        cards = try container.decode([PaymentCard].self, forKey: .cards)
    }

    public init(from decoder: Decoder, cardsList: [PaymentCard]) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decode(Bool.self, forKey: .success)
        errorCode = try container.decode(Int.self, forKey: .errorCode)
        errorMessage = try? container.decode(String.self, forKey: .errorMessage)
        errorDetails = try? container.decode(String.self, forKey: .errorDetails)
        terminalKey = try? container.decode(String.self, forKey: .terminalKey)
        //
        cards = cardsList
    }
}

// MARK: Добавит карту

public final class InitAddCardRequest: RequestOperation, AcquiringRequestTokenParams {
    // MARK: RequestOperation

    public var name = "AddCard"

    public var parameters: JSONObject?

    // MARK: AcquiringRequestTokenParams

    ///
    /// отмечаем параметры которые участвуют в вычислении `token`
    public var tokenParamsKey: Set<String> = [InitAddCardData.CodingKeys.checkType.rawValue,
                                              InitAddCardData.CodingKeys.customerKey.rawValue]

    ///
    /// - Parameter requestData: `InitAddCardData`
    public init(requestData: InitAddCardData) {
        if let json = try? requestData.encode2JSONObject() {
            parameters = json
        }
    }
}

public struct InitAddCardResponse: ResponseOperation {
    public var success: Bool
    public var errorCode: Int
    public var errorMessage: String?
    public var errorDetails: String?
    public var terminalKey: String?
    //
    var requestKey: String

    private enum CodingKeys: String, CodingKey {
        case success = "Success"
        case errorCode = "ErrorCode"
        case errorMessage = "Message"
        case errorDetails = "Details"
        case terminalKey = "TerminalKey"
        //
        case requestKey = "RequestKey"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decode(Bool.self, forKey: .success)
        errorCode = try Int(container.decode(String.self, forKey: .errorCode))!
        errorMessage = try? container.decode(String.self, forKey: .errorMessage)
        errorDetails = try? container.decode(String.self, forKey: .errorDetails)
        terminalKey = try? container.decode(String.self, forKey: .terminalKey)
        //
        requestKey = try container.decode(String.self, forKey: .requestKey)
    }
}


public struct FinishAddCardResponse: ResponseOperation {
    public var success: Bool
    public var errorCode: Int
    public var errorMessage: String?
    public var errorDetails: String?
    public var terminalKey: String?
    public var paymentStatus: PaymentStatus
    public var responseStatus: AttachCardStatus
    //
    var cardId: String?

    private enum CodingKeys: String, CodingKey {
        case success = "Success"
        case errorCode = "ErrorCode"
        case errorMessage = "Message"
        case errorDetails = "Details"
        case terminalKey = "TerminalKey"
        case paymentStatus = "Status"
        //
        case requestKey = "RequestKey"
        case cardId = "CardId"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decode(Bool.self, forKey: .success)
        errorCode = try Int(container.decode(String.self, forKey: .errorCode))!
        errorMessage = try? container.decode(String.self, forKey: .errorMessage)
        errorDetails = try? container.decode(String.self, forKey: .errorDetails)
        terminalKey = try? container.decode(String.self, forKey: .terminalKey)

        paymentStatus = .unknown
        if let statusValue = try? container.decode(String.self, forKey: .paymentStatus) {
            paymentStatus = PaymentStatus(rawValue: statusValue)
        }

        responseStatus = .done
        switch paymentStatus {
        case .checking3ds, .hold3ds:
            if let confirmation3DS = try? Confirmation3DSData(from: decoder) {
                responseStatus = .needConfirmation3DS(confirmation3DS)
            } else if let confirmation3DSACS = try? Confirmation3DSDataACS(from: decoder) {
                responseStatus = .needConfirmation3DSACS(confirmation3DSACS)
            }

        case .loop:
            let requestKey = try container.decode(String.self, forKey: .requestKey)
            responseStatus = .needConfirmationRandomAmount(requestKey)

        case .authorized, .confirmed, .checked3ds:
            if let _ = try? AddCardStatusResponse(from: decoder) {
                responseStatus = .done
            }

        default:
            if let _ = try? AddCardStatusResponse(from: decoder) {
                responseStatus = .done
            }
        }

        //
        cardId = try? container.decode(String.self, forKey: .cardId)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(success, forKey: .success)
        try container.encode(errorCode, forKey: .errorCode)
        try? container.encode(errorMessage, forKey: .errorMessage)
        try? container.encode(errorDetails, forKey: .errorDetails)
        try? container.encode(terminalKey, forKey: .terminalKey)

        switch responseStatus {
        case let .needConfirmation3DS(confirm3DSData):
            try confirm3DSData.encode(to: encoder)
        case let .needConfirmationRandomAmount(confirmRandomAmountData):
            try confirmRandomAmountData.encode(to: encoder)
        default:
            break
        }
        //
        try? container.encode(cardId, forKey: .cardId)
    } // encode
} // FinishAddCardResponse

public struct AddCardStatusResponse: ResponseOperation {
    public var success: Bool
    public var errorCode: Int
    public var errorMessage: String?
    public var errorDetails: String?
    public var terminalKey: String?
    //
    public var requestKey: String?
    public var cardId: String?

    private enum CodingKeys: String, CodingKey {
        case success = "Success"
        case errorCode = "ErrorCode"
        case errorMessage = "Message"
        case errorDetails = "Details"
        case terminalKey = "TerminalKey"
        //
        case requestKey = "RequestKey"
        case cardId = "CardId"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decode(Bool.self, forKey: .success)
        errorCode = try Int(container.decode(String.self, forKey: .errorCode))!
        errorMessage = try? container.decode(String.self, forKey: .errorMessage)
        errorDetails = try? container.decode(String.self, forKey: .errorDetails)
        terminalKey = try? container.decode(String.self, forKey: .terminalKey)
        //
        requestKey? = try container.decode(String.self, forKey: .requestKey)
        cardId = try? container.decode(String.self, forKey: .cardId)
    }

    public init(success: Bool, errorCode: Int, requestKey: String? = nil, cardId: String? = nil) {
        self.success = success
        self.errorCode = errorCode
        self.requestKey = requestKey
        self.cardId = cardId
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(success, forKey: .success)
        try container.encode(errorCode, forKey: .errorCode)
        try? container.encode(errorMessage, forKey: .errorMessage)
        try? container.encode(errorDetails, forKey: .errorDetails)
        //
        try? container.encode(terminalKey, forKey: .terminalKey)
        try? container.encode(cardId, forKey: .cardId)
    }
} // AddCardStatusResponse

// MARK: Удалить карту

public final class InitDeactivateCardRequest: RequestOperation, AcquiringRequestTokenParams {
    // MARK: RequestOperation

    public var name = "RemoveCard"

    public var parameters: JSONObject?

    // MARK: AcquiringRequestTokenParams

    ///
    /// отмечаем параметры которые участвуют в вычислении `token`
    public var tokenParamsKey: Set<String> = [InitDeactivateCardData.CodingKeys.cardId.rawValue,
                                              InitDeactivateCardData.CodingKeys.customerKey.rawValue]

    ///
    /// - Parameter requestData: `InitDeactivateCardData`
    public init(requestData: InitDeactivateCardData) {
        if let json = try? requestData.encode2JSONObject() {
            parameters = json
        }
    }
}
