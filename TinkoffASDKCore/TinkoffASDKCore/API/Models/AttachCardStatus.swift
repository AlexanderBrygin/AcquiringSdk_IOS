//
//
//  AttachCardStatus.swift
//
//  Copyright (c) 2021 Tinkoff Bank
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

public enum AttachCardStatus {
    /// Требуется подтверждение 3DS v1.0
    case needConfirmation3DS(Confirmation3DSData)

    /// Требуется подтверждение 3DS v2.0
    case needConfirmation3DSACS(Confirmation3DSDataACS)

    /// Требуется подтвержить оплату указать сумму из смс для `requestKey`
    case needConfirmationRandomAmount(String)

    /// Успешная оплата
    case done

    public func convertToAddCardFinishResponseStatus() -> AddCardFinishResponseStatus {
        switch self {
        case let .needConfirmation3DS(confirmation3DSData):
            return .needConfirmation3DS(confirmation3DSData)
        case let .needConfirmation3DSACS(confirmation3DSDataACS):
            return .needConfirmation3DSACS(confirmation3DSDataACS)
        case let .needConfirmationRandomAmount(string):
            return .needConfirmationRandomAmount(string)
        case .done:
            return .done(AddCardStatusResponse(success: true, errorCode: 0))
        }
    }
}
