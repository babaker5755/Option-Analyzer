//
//  OptionLeg.swift
//  OptionAnalyzer
//
//  Created by Brandon Baker on 1/24/20.
//  Copyright © 2020 Brandon Baker. All rights reserved.
//

import UIKit

struct OptionStrategy : Codable {
    var strategyName : String? = nil
    var symbol : String
    var legs : [OptionLeg]
    var min : Double?
    var max : Double?
}

enum OptionType : String, Codable {
    case call = "Call"
    case put = "Put"
}

enum OptionDirection : String, Codable {
    case long = "Buy"
    case short = "Write"
}

class OptionLeg : Equatable, Codable {
    
    static func == (lhs: OptionLeg, rhs: OptionLeg) -> Bool {
        lhs.price == rhs.price &&
        lhs.strikePrice == rhs.strikePrice &&
        lhs.expiration == rhs.expiration &&
        lhs.type == rhs.type &&
        lhs.direction == rhs.direction
    }
    
    var price : Double!
    var strikePrice : Double!
    var expiration : Date!
    var type : OptionType!
    var direction : OptionDirection!
    var greeks : Greeks? = nil
    
    init(strikePrice: Double, price: Double, expiration: Date, type: OptionType, direction: OptionDirection, greeks: Greeks?) {
        self.price = price
        self.expiration = expiration
        self.direction = direction
        self.type = type
        self.strikePrice = strikePrice
        self.greeks = greeks
        
    }
    
    func setExpiration(expiration: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy'-'MM'-'dd"
        let date = dateFormatter.date(from: expiration) ?? Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .day, .year], from: date)
        let finalDate = calendar.date(from:components)!
        self.expiration = finalDate
    }
    
    func setPrice(price: String) {
        if let price = Double(price) {
            self.price = price
        }
    }
    
    func setStrikePrice(strikePrice: String) {
        if let strikePrice = Double(strikePrice) {
            self.strikePrice = strikePrice
        }
    }
    
    func getOptionInfo(forButton : Bool = false) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM'/'dd'/'yyyy"
        let dateString = dateFormatter.string(from: self.expiration)
        let expiration = "\(dateString)"
        let direction = self.direction == OptionDirection.long ? "Buy" : "Write"
        let typeIndicator = self.type == OptionType.call ? "Call" : "Put"
        let strikePrice = "$\(self.strikePrice.getString()) \(typeIndicator)"
        let price = "$\(self.price.getString())"
        let underlying = "\(OptionChain.symbol ?? "") $\(Double(OptionChain.currentPrice ?? 0.0).getString())"
        return forButton ? "\(direction) \(price) \n \(expiration) \n \(strikePrice)" : "\(underlying)\n\(direction) \(price) - \(expiration) - \(strikePrice)"
    }
    
}

