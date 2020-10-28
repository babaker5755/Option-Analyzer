//
//  OptionChain.swift
//  OptionAnalyzer
//
//  Created by Brandon Baker on 1/26/20.
//  Copyright © 2020 Brandon Baker. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class OptionChain {
    
    static var symbol : String? = nil
    static var shared : OptionChain = OptionChain()
    
    static var options : [Option] = []
    static var dates : [String] = []
    static var currentPrice : Double? = nil
    static var currentDiv : Double = 0.0

    static var headers : HTTPHeaders {
        get {
            return [
                "Accept": "application/json",
                "Authorization" : "Bearer \(LocalStorage.key ?? "")"
            ]
        }
    }
    
    static func getUnderlyingPrice(symbol: String, completion: ((Bool) -> Void)?) {
        
        Helpers.trackEvent("Searched Symbol", properties: ["symbol":symbol])
        
        AF.request("\(Secrets.domain)/quotes?symbols=\(symbol)", headers: headers).response { response in
            
            guard let data = response.data else {
                Helpers.trackEvent("Unable to serialize data", properties: ["symbol":symbol])
                completion?(false)
                return
            }
            
            do {
                let json = try JSON(data: data)
                let lastPrice = json["quotes"]["quote"]["last"].doubleValue
                OptionChain.currentPrice = lastPrice
                OptionChain.getDividend(symbol) { success in
                    completion?(success)
                }
            } catch {
                LocalStorage.key = nil
                Helpers.trackEvent("Unable to find symbol", properties: ["symbol":symbol])
                completion?(false)
            }
        }
    }
    
    static func getDividend(_ symbol: String, completion: ((Bool) -> Void)?) {
        //skip this until the api has it
        OptionChain.getOptionExpirations(symbol) { success in
            completion?(success)
        }
    }
    
    
    static func getOptionExpirations(_ symbol: String, completion: ((Bool) -> Void)?) {
        
        self.symbol = nil
        let symbol = symbol.trimmed
        self.shared = OptionChain()
        AF.request("\(Secrets.domain)/options/expirations?symbol=\(symbol)",headers: headers).response { response in
            guard let data = response.data else {
                Helpers.trackEvent("Unable to serialize expiration data", properties: ["symbol":symbol])
                completion?(false)
                return
            }
            
            self.symbol = symbol
            do {
                let json = try JSON(data: data)
                guard let dates = json["expirations"]["date"].array else { return }
                self.dates = dates.map { date in date.stringValue }
                guard let firstExp = self.dates.first else { return }
                getOptionChain(expiration: firstExp) { success in
                    completion?(success)
                }
            } catch {
                LocalStorage.key = nil
                Helpers.trackEvent("Unable to get expirations", properties: ["symbol":symbol])
                completion?(false)
            }
        }
    }
    
    static func getOptionChain(expiration: String, completion: ((Bool) -> Void)? = nil) {
        guard let symbol = self.symbol else { return }
        self.symbol = nil
        AF.request("\(Secrets.domain)/options/chains?symbol=\(symbol)&expiration=\(expiration)&greeks=true",headers: headers).response { response in
            guard let data = response.data else {
                Helpers.trackEvent("Unable to serialize option data",
                                   properties: ["symbol":symbol, "expiration": expiration])
                completion?(false)
                return
            }
            self.symbol = symbol
            do {
                self.options = []
                let json = try JSON(data: data)
                let options = json["options"]["option"].arrayValue
                options.forEach { opt in
                    if let price = opt["last"].double {
                        let price = String(price)
                        let strikePrice = opt["strike"].stringValue
                        let type : OptionType = opt["option_type"].stringValue == "call" ? .call : .put
                        let greeks = opt["greeks"]
                        let option = Option(price: price, expiration: expiration, type: type, strikePrice: strikePrice, greeks: greeks)
                        self.options.append(option)
                    }
                }
                completion?(true)
            } catch {
                LocalStorage.key = nil
                completion?(false)
                Helpers.trackEvent("Unable to get option chain", properties: ["symbol":symbol])
            }
        }
    }
    
}
