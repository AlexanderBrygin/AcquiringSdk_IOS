//
//
//  MockCardsLoader.swift
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


@testable import TinkoffASDKCore

final class MockCardsLoader: CardsLoader {
    var result: Result<[PaymentCard], Error> = .success([])
    var timeout: TimeInterval = 1.0
    var loadCardsTimesCalled = 0
    
    
    func loadCards(customerKey: String,
                   completion: @escaping (Result<[PaymentCard], Error>) -> Void) {
        loadCardsTimesCalled += 1
        DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
            completion(self.result)
        }
    }
}