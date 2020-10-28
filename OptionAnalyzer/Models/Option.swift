//
//  Option.swift
//  OptionAnalyzer
//
//  Created by Brandon Baker on 1/29/20.
//  Copyright © 2020 Brandon Baker. All rights reserved.
//

import UIKit
import SwiftyJSON

class Option {

    var strikePrice : String!
    var price : String!
    var expiration : String!
    var type : OptionType!
    var greeks : Greeks
    
    init(price: String, expiration: String, type: OptionType, strikePrice: String, greeks: JSON) {
        self.price = price
        self.expiration = expiration
        self.type = type
        self.strikePrice = strikePrice
        self.greeks = Greeks(greeks)
    }
    
}
