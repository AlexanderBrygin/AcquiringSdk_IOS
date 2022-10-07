//
//
//  AcquiringAPIClient.swift
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

protocol IAcquiringAPIClient {
    func performRequest<Payload: Decodable>(
        _ request: AcquiringRequest,
        completion: @escaping (Result<Payload, Error>) -> Void
    ) -> Cancellable

    @available(*, deprecated, message: "Use performRequest(_:completion:) instead")
    func performDeprecatedRequest<Response: ResponseOperation>(
        _ request: AcquiringRequest,
        delegate: NetworkTransportResponseDelegate?,
        completion: @escaping (Result<Response, Error>) -> Void
    ) -> Cancellable
}

final class AcquiringAPIClient: IAcquiringAPIClient {
    private let requestAdapter: IAcquiringRequestAdapter
    private let networkClient: INetworkClient
    private let apiDecoder: IAPIDecoder
    @available(*, deprecated, message: "Use apiDecoder instead")
    private let deprecatedDecoder = DeprecatedDecoder()

    init(
        requestAdapter: IAcquiringRequestAdapter,
        networkClient: INetworkClient,
        apiDecoder: IAPIDecoder
    ) {
        self.requestAdapter = requestAdapter
        self.networkClient = networkClient
        self.apiDecoder = apiDecoder
    }

    // MARK: API

    func performRequest<Payload: Decodable>(
        _ request: AcquiringRequest,
        completion: @escaping (Swift.Result<Payload, Error>) -> Void
    ) -> Cancellable {
        let cancellable = CancellableWrapper()

        requestAdapter.adapt(request: request) { [networkClient, apiDecoder] adaptingResult in
            guard !cancellable.isCancelled else { return }

            switch adaptingResult {
            case let .success(request):
                cancellable.addCancellationHandler(cancellable.cancel)

                networkClient.performRequest(request) { response in
                    guard !cancellable.isCancelled else { return }

                    let result = response
                        .result
                        .tryMap { data in
                            try apiDecoder.decode(Payload.self, from: data, with: request.decodingStrategy)
                        }
                        .mapError { error -> Error in
                            switch error {
                            case let error as APIFailureError:
                                return APIError.failure(error)
                            default:
                                return APIError.invalidResponse
                            }
                        }

                    completion(result)
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }

        return cancellable
    }

    @available(*, deprecated, message: "Use performRequest(_:completion:) instead")
    func performDeprecatedRequest<Response: ResponseOperation>(
        _ request: AcquiringRequest,
        delegate: NetworkTransportResponseDelegate?,
        completion: @escaping (Result<Response, Error>) -> Void
    ) -> Cancellable {

        networkClient.performRequest(request) { [deprecatedDecoder] response in
            let result: Result<Response, Error> = response.result.tryMap { data in
                if let delegate = delegate,
                   let urlRequest = response.request,
                   let httpResponse = response.response {

                    guard let delegatedResponse = try? delegate.networkTransport(
                        didCompleteRawTaskForRequest: urlRequest,
                        withData: data,
                        response: httpResponse,
                        error: response.error
                    ) else {
                        throw HTTPResponseError(body: data, response: httpResponse, kind: .invalidResponse)
                    }
                    // swiftlint:disable:next force_cast
                    return delegatedResponse as! Response
                }

                return try deprecatedDecoder.decode(data: data, with: response.response)
            }

            completion(result)
        }
    }
}

private final class DeprecatedDecoder {
    private let decoder = JSONDecoder()

    func decode<Response: ResponseOperation>(data: Data, with response: HTTPURLResponse?) throws -> Response {
        let response = try response.orThrow(NSError(domain: "Response must exist", code: 1))

        // decode as a default `AcquiringResponse`
        guard let acquiringResponse = try? decoder.decode(AcquiringResponse.self, from: data) else {
            throw HTTPResponseError(body: data, response: response, kind: .invalidResponse)
        }

        // data  in `AcquiringResponse` format but `Success = 0;` ( `false` )
        guard acquiringResponse.success else {
            var errorMessage: String = Loc.TinkoffAcquiring.Response.Error.statusFalse

            if let message = acquiringResponse.errorMessage {
                errorMessage = message
            }

            if let details = acquiringResponse.errorDetails, details.isEmpty == false {
                errorMessage.append(contentsOf: " ")
                errorMessage.append(contentsOf: details)
            }

            let error = NSError(
                domain: errorMessage,
                code: acquiringResponse.errorCode,
                userInfo: try? acquiringResponse.encode2JSONObject()
            )

            throw error
        }

        // decode to `Response`
        if let responseObject: Response = try? decoder.decode(Response.self, from: data) {
            return responseObject
        } else {
            throw HTTPResponseError(body: data, response: response, kind: .invalidResponse)
        }
    }
}