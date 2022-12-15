//
//
//  UIAssembly.swift
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

import TinkoffASDKCore

struct UIAssembly {
    func paymentController(
        acquiringSDK: AcquiringSdk,
        acquiringUISDK: AcquiringUISDK,
        ipProvider: IIPAddressProvider
    ) -> PaymentController {
        return PaymentController(
            threeDsService: acquiringSDK,
            paymentFactory: paymentFactory(
                acquiringSDK: acquiringSDK,
                ipProvider: ipProvider
            ),
            threeDSHandler: acquiringSDK.payment3DSHandler(),
            threeDSDeviceInfoProvider: acquiringSDK.threeDSDeviceInfoProvider(),
            tdsController: acquiringUISDK.tdsController,
            acquiringUISDK: acquiringUISDK
        )
    }
}

private extension UIAssembly {
    func paymentFactory(acquiringSDK: AcquiringSdk, ipProvider: IIPAddressProvider) -> PaymentFactory {
        return PaymentFactory(
            paymentsService: acquiringSDK,
            threeDsService: acquiringSDK,
            threeDSDeviceInfoProvider: acquiringSDK.threeDSDeviceInfoProvider(),
            ipProvider: ipProvider
        )
    }
}
