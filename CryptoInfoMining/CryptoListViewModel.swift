//
//  CryptoListViewModel.swift
//  CryptoInfoMining
//
//  Created by Samith Aturaliyage on 10/12/24.
//

import RxSwift
import Alamofire
import Reachability
import Foundation

class CryptoListViewModel {
    
    weak var view: CryptoView?
    
    let reachability = try! Reachability()
    var cryptoInfo: Observable<[CryptoInfo]>?
    var coinGeckoKey = "CG-vimQfYgkGiuChnbwkjYEo6SB"
    
    let apiCall = 
    
    let disposeBag = DisposeBag()
    
    init(view: CryptoView) {
        self.view = view
        view.dataLoading()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(note:)), name: .reachabilityChanged, object: reachability)
        do{
            try reachability.startNotifier()
        } catch {
            print("could not start reachability notifier")
        }
        
    }
    
    func testButton() {
        let urlString = APIString.ping
        guard let url = URL(string: urlString + coinGeckoKey) else { return }
        var urlRequest = URLRequest(url: url)
        
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.setValue("x-cg-demo-api-key", forHTTPHeaderField: coinGeckoKey)
        
        cryptoInfo = URLSession.shared.rx
            .data(request: urlRequest)
            .map { data -> Data in
                let decoder = JSONDecoder()
                return try decoder.decode([CryptoInfo].self, from: data)
            }
            .catch({ error in
                
            })
            .dispose(by: disposeBag)
    }
    
    func checkReachability() {
        
        reachability.whenReachable = { reachability in
            if reachability.connection == .wifi {
                print("Reachable via WiFi")
            } else {
                print("Reachable via Cellular")
            }
        }
        reachability.whenUnreachable = { _ in
            print("Not reachable")
        }
        
        do {
            try reachability.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
    }
    
//    func downloadFileCompletionHandler(urlstring: String, filename : String?, completion: @escaping (URL?, Error?) -> Void) -> URLSessionDownloadTask? {
//        
//        guard let url = URL(string: urlstring) else { return nil }
//        let documentsUrl =  try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
//        
//        var destinationUrl = documentsUrl.appendingPathComponent(url.lastPathComponent)
//        
//        if let f = filename {
//            destinationUrl = documentsUrl.appendingPathComponent(f)
//        }
//        print(destinationUrl)
//    }
    
    @objc func reachabilityChanged(note: Notification) {
        
        let reachability = note.object as! Reachability
        
        switch reachability.connection {
        case .wifi:
            print("Reachable via WiFi")
        case .cellular:
            print("Reachable via Cellular")
        case .unavailable:
            print("Network not reachable")
        }
        
        func getTodos() -> Observable<Any> {
            
            return Observable.create { (observer) -> Disposable in
                
                AF.request("https://jsonplaceholder.typicode.com/todos", method: .get, parameters: nil, encoding: JSONEncoding.default, headers: ["Content-Type": "application/json"])
                    .responseData { response in
                        switch response.result {
                        case let .success(data):
                            do {
                                observer.onNext(data)
                                observer.onCompleted()
                            } catch {
                                observer.onError(error)
                            }
                        case let .failure(error):
                            observer.onError(error)
                        }
                    }
                
                return Disposables.create()
            }
        }
        
        
    }
}
