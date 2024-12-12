//
//  CoinListViewModel.swift
//  CryptoInfoMining
//
//  Created by Samith Aturaliyage on 10/12/24.
//

import RxSwift
import Reachability
import Foundation

struct Coin {
    let id: String
    let symbol: String
    let name: String
    let image: UIImage?
    let imageURL: String
    let currentPrice: Double
    let marketCap: Double
    let marketCapRank: Int
    let high24h: Double
    let low24h: Double
    let priceChange24h: Double
    let priceChangePercentage24h: Double
    let sparkLine7Day : [Double]?
}

protocol CoinListViewModelProtocol {
    var userActionObserver: AnyObserver<Void> { get }
    var startLoadingDataSubject: PublishSubject<String?> { get }
    var finishedLoadingDataSubject: PublishSubject<Void> { get }
    var loadedNextViewDataSubject: PublishSubject<(name: String, description: String, link: String, values: [Double])> { get }
}

class CoinListViewModel: CoinListViewModelProtocol {
    
    
    weak var view: CoinListView?
    
    let reachability = try! Reachability()
    let apiClient = APIClient()
    var marketCapCrypto: [(name: String , marketCapPercentage: Double)] = []
    var coinGeckoKey = "CG-vimQfYgkGiuChnbwkjYEo6SB"
    var coins : [Coin] = []
    
    /// Observer
    // Input: Observer for button tap events
    let userActionObserver : AnyObserver<Void>
    
    // Internal PublishSubject to manage button taps
    private let userActionSubject = PublishSubject<Void>()
    var startLoadingDataSubject = PublishSubject<String?>()
    var finishedLoadingDataSubject = PublishSubject<Void>()
    var loadedNextViewDataSubject = PublishSubject<(name: String, description: String, link: String, values: [Double])>()
    
    var counterSubject = PublishSubject<Void>()
    
    // Observable for any error
    let error: PublishSubject<(String, String)> = PublishSubject()
    
    
    let disposeBag = DisposeBag()
    
    init(view: CoinListView) {
        self.view = view
        
        // Expose the PublishSubject as an observer
        userActionObserver = userActionSubject.asObserver()
        
        // React to button tap events
        userActionSubject
            .subscribe(onNext: {
                self.downloadCoinsBasicInfo()
            })
            .disposed(by: disposeBag)
        
        view.viewIsReadySubject
            .subscribe(onNext: {
                self.downloadCoinsBasicInfo()
            })
            .disposed(by: disposeBag)
        
        view.userSelectionSubject
            .subscribe(onNext: { coinName in
                self.downloadSelectedCoinInfo(coinName: coinName)
            })
            .disposed(by: disposeBag)
        
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(note:)), name: .reachabilityChanged, object: reachability)
        do{
            try reachability.startNotifier()
        } catch {
            print("Could not start reachability notifier")
        }
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
            self.error.onNext(("Network Error", "Not reachable"))
        }
        
        do {
            try reachability.startNotifier()
        } catch {
            self.error.onNext(("Network Error", "Unable to start notifier"))
        }
    }
    
    
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
    }
    
    func downloadCoinsBasicInfo() {
        self.startLoadingDataSubject.onNext(("Downloading"))
        guard let url = URL(string: APIString.coinsListWithMarketData) else { return }
        self.performAPICall(url: url, queryParams: ["vs_currency" : "eur",
                                                    "order" : "market_cap_desc",
                                                    "per_page" : "10",
                                                    "sparkline" : "true"])
            .observe(on: MainScheduler.instance) // UI update sul main thread
            .subscribe(
                onNext: { data in
                    self.view?.viewObjects = []
                    self.coins = []
                    let coinsData = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]]
                    for coin in coinsData ?? [] {
                        let imageUrl = coin["image"] as? String ?? ""
                        
                        self.downloadImage(from: imageUrl)
                            .observe(on: MainScheduler.instance) // Aggiorna la UI nel main thread
                            .subscribe(onNext: { image in

                                let id = coin[CoinDictionaryKey.id] as? String ?? ""
                                let symbol = coin[CoinDictionaryKey.symbol] as? String ?? ""
                                let name = coin[CoinDictionaryKey.name] as? String ?? ""
                                let imageURL = coin[CoinDictionaryKey.imageURL] as? String ?? ""
                                let currentPrice = coin[CoinDictionaryKey.currentPrice] as? Double ?? 0
                                let marketCap = coin[CoinDictionaryKey.marketCap] as? Double ?? 0
                                let marketCapRank = coin[CoinDictionaryKey.marketCapRank] as? Int ?? 0
                                let high24h = coin[CoinDictionaryKey.high24h] as? Double ?? 0
                                let low24h = coin[CoinDictionaryKey.low24h] as? Double ?? 0
                                let priceChange24h = coin[CoinDictionaryKey.priceChange24h] as? Double ?? 0
                                let priceChangePercentage24h = coin[CoinDictionaryKey.priceChangePercentage24h] as? Double ?? 0
                                let sparkLine7Day = ((coin[CoinDictionaryKey.sparkLine7Day] as? [String : Any])?[CoinDictionaryKey.price] as? [Double])
                                
                                self.coins.append(Coin(id: id, symbol: symbol, name: name, image: image, imageURL: imageURL, currentPrice: currentPrice, marketCap: marketCap, marketCapRank: marketCapRank, high24h: high24h, low24h: low24h, priceChange24h: priceChange24h, priceChangePercentage24h: priceChangePercentage24h, sparkLine7Day: sparkLine7Day))

                                self.view?.viewObjects.append((rank: "\(marketCapRank)", image: image, name: name, price: currentPrice))
                                if self.view?.viewObjects.count == coinsData?.count {
                                    self.finishedLoadingDataSubject.onNext(())
                                }
                            }, onError: { error in
                                self.error.onNext((error.localizedDescription, ""))
                            })
                            .disposed(by: self.disposeBag)
                    }
                },
                onError: { error in
                    self.finishedLoadingDataSubject.onNext(())
                    self.error.onNext(("API Error", error.localizedDescription))
                },
                onCompleted: {
                    print("Download completed")
                })
            .disposed(by: self.disposeBag)
    }
    
    
    /// Method for downloading a specific coin information.
    /// - Parameter coinName: The selected coin name.
    func downloadSelectedCoinInfo(coinName: String) {
        self.startLoadingDataSubject.onNext(("Downloading"))
        let coinID = self.coins.first(where: { $0.name == coinName })?.id ?? ""
        guard let url = URL(string: APIString.getCoinDataURL(coinID: coinID)) else { return }
        self.performAPICall(url: url, queryParams: ["sparkline" : "true"])
            .observe(on: MainScheduler.instance) 
            .subscribe(
                onNext: { data in
                    
                    let coinsData = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    let name = coinsData?[CoinDictionaryKey.name] as? String ?? ""
                    let sparkLine7Day = (((coinsData?[CoinDictionaryKey.marketData] as? [String : Any])?[CoinDictionaryKey.sparkLine7Day_2] as? [String : Any])?[CoinDictionaryKey.price] as? [Double])
                    let homepageLink = ((coinsData?[CoinDictionaryKey.links] as? [String : Any])?[CoinDictionaryKey.homepage] as? [String])?.first
                    let description = ((coinsData?[CoinDictionaryKey.description] as? [String : Any])?[CoinDictionaryKey.english] as? String)
                    
                    ///After finished downloading and decoding the coin object and all the needed property, UX is notified that the viewmodel has finished.
                    self.finishedLoadingDataSubject.onNext(())
                    self.loadedNextViewDataSubject.onNext((name, description ?? "", homepageLink ?? "", sparkLine7Day ?? []))
                    
                },
                onError: { error in
                    self.finishedLoadingDataSubject.onNext(())
                    self.error.onNext(("API Error", error.localizedDescription))
                },
                onCompleted: {
                    print("Download completed")
                })
            .disposed(by: self.disposeBag)
    }
    
    /// Method that allows to perform a request to an URL withe GET method, with additional headers and optional query parameters.
    /// - Parameters:
    ///   - url: The URL to be called.
    ///   - additionalHeaders: Additional headers for the request.
    ///   - queryParams: Query parameters to be added at the end of the URL.
    /// - Returns: Observable object that contains the request with all the parameters.
    func performAPICall(url: URL,
                        additionalHeaders: [String: Any]? = nil,
                        queryParams: [String: String]? = nil) -> Observable<Data> {
        
        var headers : [String : String] = [
            "accept": "application/json",
            "x-cg-demo-api-key": self.coinGeckoKey
        ]
        
        if let additionals = additionalHeaders as? [String: String] {
            for header in additionals {
                headers[header.key] = header.value
            }
        }
        
        return apiClient.request(url: url, method: "GET", headers: headers, queryParams: queryParams)
    }
    
    
    /// Permits to download an image with an observable.
    /// - Parameter urlString: The URL string where the image is located.
    /// - Returns: Observable object that contains the request with all the parameters.
    func downloadImage(from urlString: String) -> Observable<UIImage?> {
        guard let url = URL(string: urlString) else {
            return Observable.just(nil)
        }
        
        return URLSession.shared.rx.data(from: url)
            .map { data in
                return UIImage(data: data) // Converte i dati in UIImage
            }
            .catchAndReturn(nil) // Gestisce eventuali errori restituendo nil
    }
}


