//
//  GraphValue.swift
//  OptionAnalyzer
//
//  Created by Brandon Baker on 4/9/20.
//  Copyright © 2020 Brandon Baker. All rights reserved.
//

import UIKit

class GraphValue {
    
    var color : UIColor
    var optionCost : Double
    var value : Double
    var netLong : Bool
    
    var stringValue : String
    var displayedValue : Double
    var profitValue : Double
    
    var shouldBeRed : Bool = false
    var greenPercent : Double = 0.0
    var redPercent : Double = 0.0
    var maxValue: Double = 0.0
    var lowestValue : Double = 0.0 {
        didSet {
            if lowestValue == 0 {
                lowestValue = .leastNonzeroMagnitude
            }
        }
    }
    
    init(value: Double, optionCost: Double) {
        self.color = .white
        self.optionCost = optionCost
        self.value = value
        self.netLong = optionCost >= 0
        self.profitValue = value - optionCost
        
        switch Settings.graphMode {
        case .value:
            self.displayedValue = value
            self.stringValue = displayedValue.getString()
        case .profit:
            self.displayedValue = value - optionCost//netLong ? value - optionCost : optionCost + value
            self.stringValue = displayedValue.getString()
        case .percentOfCost:
            self.displayedValue = value/optionCost * 100
            self.stringValue = displayedValue.getString(1)
        case .percentProfit:
            self.displayedValue = netLong ? ((value - optionCost)/optionCost * 100) : ((optionCost + value)/optionCost * 100)
            self.stringValue = displayedValue.getString(1)
        }
    }
    
    //DONT TOUCH THIS
    func setColor() {
        var red : CGFloat! = 1
        var green : CGFloat! = 1
        var blue : CGFloat! = 1
        var alpha  : CGFloat! = 1
        
        let maxValue = OptionSpread.instance.maxValue
        let lowestValue = OptionSpread.instance.lowestValue
        
            self.maxValue = maxValue - optionCost
            self.lowestValue = lowestValue - optionCost
            self.shouldBeRed = profitValue <= 0
        
        redPercent = netLong ? abs(profitValue) / abs(self.lowestValue) : abs(profitValue) / abs(self.maxValue)
        greenPercent = netLong ? abs(profitValue) / abs(self.maxValue) :  abs(profitValue) / abs(self.lowestValue)

        alpha = shouldBeRed ? CGFloat(redPercent) : CGFloat(greenPercent)
        
        if shouldBeRed {
            red = 1
            green = 0.3
            blue = 0.18
        } else {
            red = 0.3
            green = 1.0
            blue = 0.18
        }
        
        self.color = UIColor(red: red, green: green, blue: blue, alpha: abs(alpha))
    }
}
