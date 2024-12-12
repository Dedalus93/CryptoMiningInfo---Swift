//
//  APIEnum.swift
//  CryptoInfoMining
//
//  Created by Samith Aturaliyage on 10/12/24.
//


/// This enum contains the URL string for all the needed API call for this app.
enum APIString {
    // MARK: CoinGecko
    /// This endpoint allows you to check the API server status.
    static let ping = "https://api.coingecko.com/api/v3/ping"
    /// This endpoint allows you to query all the supported currencies on CoinGecko.
    static let supportedCurrenciesList = "https://api.coingecko.com/api/v3/simple/supported_vs_currencies"
    /// This endpoint allows you to query all the supported coins with price, market cap, volume and market related data.
    static let coinsListWithMarketData = "https://api.coingecko.com/api/v3/coins/markets"
    /// This endpoint allows you query cryptocurrency global data including active cryptocurrencies, markets, total crypto market cap and etc.
    static let cryptoGlobalMarkedData = "https://api.coingecko.com/api/v3/global"
    /// This endpoint allows you to query all the coin metadata of a coin
    /// (name, price, market cap, logo images, official websites, social media links, project description, public notice information, contract addresses, categories, exchange tickers, and more)
    /// on CoinGecko coin page based on a particular coin id.
    private static let coinData = "https://api.coingecko.com/api/v3/coins/%@"
    
    static func getCoinDataURL(coinID: String) -> String {
        return String(format: self.coinData, coinID)
    }

}

