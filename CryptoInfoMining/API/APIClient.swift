//
//  APIClient.swift
//  CryptoInfoMining
//
//  Created by Samith Aturaliyage on 11/12/24.
//

import Foundation
import RxSwift

struct APIClient {
    /// Execute generic HTTP request.
    func request<T: Decodable>(
        url: URL,
        method: String = "GET",
        headers: [String: String]? = nil,
        queryParams: [String: String]? = nil,
        bodyParams: [String: Any]? = nil
    ) -> Observable<T> {
        return Observable.create { observer in
            var requestURL = url

            /// Add parameters to GET requests.
            if method == "GET", let queryParams = queryParams {
                var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
                urlComponents?.queryItems = queryParams.map { URLQueryItem(name: $0.key, value: $0.value) }
                if let finalURL = urlComponents?.url {
                    requestURL = finalURL
                }
            }

            /// Request creation.
            var request = URLRequest(url: requestURL)
            request.httpMethod = method
            
            /// Adding header to the request.
            headers?.forEach { key, value in
                request.setValue(value, forHTTPHeaderField: key)
            }

            /// Add parameters to POST/PUT/DELETE requests.
            if method != "GET", let bodyParams = bodyParams {
                do {
                    let bodyData = try JSONSerialization.data(withJSONObject: bodyParams, options: [])
                    request.httpBody = bodyData
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                } catch {
                    observer.onError(error)
                }
            }

            /// Request execution.
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    observer.onError(error)
                    return
                }

                guard let data = data else {
                    observer.onError(NSError(domain: "No Data", code: -1, userInfo: nil))
                    return
                }

                /// Decoding response through JSONDecoder.
                do {
                    /// If the requested type is Data, the response is NOT decoded.
                    if T.self == Data.self {
                        observer.onNext(data as! T)
                    } else {
                        let result = try JSONDecoder().decode(T.self, from: data)
                        observer.onNext(result)
                    }
                    observer.onCompleted()
                } catch {
                    observer.onError(error)
                }
            }
            
            task.resume()

            /// Give back the disposable for the request deletion.
            return Disposables.create {
                task.cancel()
            }
        }
    }
}
