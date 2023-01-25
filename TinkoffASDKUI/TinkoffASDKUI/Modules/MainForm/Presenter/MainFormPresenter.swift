//
//  MainFormPresenter.swift
//  TinkoffASDKUI
//
//  Created by r.akhmadeev on 19.01.2023.
//

import Foundation

final class MainFormPresenter {
    // MARK: Dependencies

    weak var view: IMainFormViewController?
    private let router: IMainFormRouter
    private let stub: MainFormStub

    // MARK: Init

    init(router: IMainFormRouter, stub: MainFormStub) {
        self.router = router
        self.stub = stub
    }
}

// MARK: - IMainFormPresenter

extension MainFormPresenter: IMainFormPresenter {
    func viewDidLoad() {
        let orderDetails = MainFormOrderDetailsViewModel(
            amountDescription: "К оплате",
            amount: "10 500 ₽",
            orderDescription: "Заказ №123456"
        )

        let paymentControls = MainFormPaymentControlsViewModel(
            buttonType: .primary(title: "Оплатить картой")
        )

        let header = MainFormHeaderViewModel(
            orderDetails: orderDetails,
            paymentControls: paymentControls
        )

        view?.updateHeader(with: header)
    }

    func viewWasClosed() {}

    func viewDidTapPayButton() {
        router.openCardPaymentForm()
    }
}