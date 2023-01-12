//
//  IYandexPayPaymentActivityOutput.swift
//  TinkoffASDKUI
//
//  Created by r.akhmadeev on 18.12.2022.
//

import Foundation

protocol IYandexPayPaymentActivityOutput: AnyObject {
    func yandexPayPaymentActivity(completedWith result: YandexPayPaymentResult)
}