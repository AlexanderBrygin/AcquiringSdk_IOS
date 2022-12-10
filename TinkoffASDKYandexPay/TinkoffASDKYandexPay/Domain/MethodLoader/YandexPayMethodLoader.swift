//
//  YandexPayMethodLoader.swift
//  TinkoffASDKYandexPay
//
//  Created by r.akhmadeev on 30.11.2022.
//

import Foundation
import TinkoffASDKCore

enum YandexPayMethodLoaderError: Error {
    case methodUnavailable
    case loadingError(Error)
}

protocol IYandexPayMethodLoader {
    func loadMethod(_ completion: @escaping (_ result: Result<YandexPayMethod, YandexPayMethodLoaderError>) -> Void)
}

final class YandexPayMethodLoader: IYandexPayMethodLoader {
    private let terminalPayMethodsLoader: ITerminalPayMethodsLoader
    private let responseQueue: DispatchQueue

    init(terminalPayMethodsLoader: ITerminalPayMethodsLoader, responseQueue: DispatchQueue = .main) {
        self.terminalPayMethodsLoader = terminalPayMethodsLoader
        self.responseQueue = responseQueue
    }

    func loadMethod(_ completion: @escaping (Result<YandexPayMethod, YandexPayMethodLoaderError>) -> Void) {
        terminalPayMethodsLoader.getTerminalPayMethods { [responseQueue] result in
            let yandexPayResult = result
                .mapError(YandexPayMethodLoaderError.loadingError)
                .flatMap(\.yandexPayMethodResult)

            responseQueue.async {
                completion(yandexPayResult)
            }
        }
    }
}

// MARK: - GetTerminalPayMethodsPayload + Loading Result

private extension GetTerminalPayMethodsPayload {
    var yandexPayMethodResult: Result<YandexPayMethod, YandexPayMethodLoaderError> {
        for method in terminalInfo.payMethods {
            if case let .yandexPay(yandexPayMethod) = method {
                return .success(yandexPayMethod)
            }
        }

        return .failure(.methodUnavailable)
    }
}