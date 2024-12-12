//
//  URLSession+Rx.swift
//  CryptoInfoMining
//
//  Created by Samith Aturaliyage on 11/12/24.
//

import RxSwift

//Extension to make UrlSession a Reactive element
extension Reactive where Base: URLSession {
    func data(from url: URL) -> Observable<Data> {
        return Observable.create { observer in
            let task = self.base.dataTask(with: url) { data, response, error in
                if let error = error {
                    observer.onError(error)
                } else if let data = data {
                    observer.onNext(data)
                    observer.onCompleted()
                }
            }
            task.resume()
            return Disposables.create { task.cancel() }
        }
    }
}
