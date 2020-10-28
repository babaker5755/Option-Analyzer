//
//  OptionSpread.swift
//  OptionAnalyzer
//
//  Created by Brandon Baker on 1/24/20.
//  Copyright © 2020 Brandon Baker. All rights reserved.
//

import UIKit
import SigmaSwiftStatistics
import Darwin

let expirationLimit : Int = 30
let strikeLimit : Int = 30

struct Expiration {
    var date: Date
    var dateString : String
    var daysTillExp : Int
}

class OptionSpread {
    
    static let instance = OptionSpread()
    var spreadData : [Double:[GraphValue]] = [:]
    var expirations : [Expiration] = []
    var optionLegs : [OptionLeg] = []
    
    var spreadInfo : String? {
        get {
            return "Graph Mode: \(Settings.graphMode.name())"
        }
    }
    
    var maxValue : Double = 0.0
    var lowestValue: Double = 0.0
    var minMax : (Double, Double)? = nil
    
    var reloadGraph : (() -> Void) = { }
    var closestStrike : Double? = nil
    
    func updateSpread(temp: OptionLeg? = nil) {
        spreadData = [:]
        expirations = []
        closestStrike = nil
        maxValue = 0.0
        lowestValue = 0.0
        
        if let temp = temp {
            optionLegs.append(temp)
        }
        
        // Get Strike Axis Points
        var strikeAxis : [Double] = Array(repeating: 0, count: strikeLimit)
        guard let currentPrice = OptionChain.currentPrice?.rounded(.toNearestOrEven) else { return }
        guard let closestExpiration = optionLegs.sorted(by: {$0.expiration < $1.expiration }).first?.expiration else {return}
        
        
        // Get Calendar Axis Points
        var expirations : [Expiration] = []
        
        var dayBefore = closestExpiration
        while dayBefore > .yesterday {
            expirations.insert(Expiration(date: dayBefore,
                                          dateString: getMMdd(from: dayBefore),
                                          daysTillExp: getDaysUntil(dayBefore)), at: 0)
            dayBefore = dayBefore.dayBefore
        }
        
        while expirations.count > expirationLimit {
            for (i, date) in expirations.enumerated() {
                if i % 2 == 0 && i != 0 {
                    expirations.removeAll(where: {$0.daysTillExp == date.daysTillExp})
                }
            }
        }

        let increment = minMax != nil ? getIncrement(minMax: minMax!) : getIncrement(currentPrice: currentPrice)
        
        var mutatedPrice = currentPrice
        mutatedPrice += Double(increment * Double(strikeLimit) / 2.0)
        
        for i in 0..<strikeAxis.count {
            let axis = mutatedPrice - (Double(i) * increment)
            if axis >= 0 {
                strikeAxis[i] = axis
            }
            if closestStrike == nil && axis <= currentPrice {
                closestStrike = axis
            }
        }
        
        self.expirations = expirations
        
        // reset max and min value
        if let leg = optionLegs.first, let underlying = strikeAxis.first, let day = expirations.first {
            let first = getValueForOption(option: leg, underlyingPrice: underlying, day: day)
            maxValue = first
            lowestValue = first
        }
        
        // Calculate Option Value at underlying x expiration
        for option in optionLegs {
            
            for underlyingStrikePrice in strikeAxis {
                
                var valuesAtUnderlyingPrice : [GraphValue] = []
                
                for day in expirations {
                    
                    var value = getValueForOption(option: option,
                                                  underlyingPrice: Double(underlyingStrikePrice),
                                                  day: day)
                    
                    compareToBoundsAndSet(value)

                    guard var optionCost = option.price else { continue }
                    optionCost = option.direction == .short ? -optionCost : optionCost
                    value = option.direction == .short ? -value : value
                    let gv = GraphValue(value: value, optionCost: optionCost)
                    valuesAtUnderlyingPrice.append(gv)
                }
                
                if let currentDataPoints : [GraphValue] = spreadData[underlyingStrikePrice] {
                    let newDataPoints : [GraphValue] = valuesAtUnderlyingPrice.reversed()
                    var newArray : [GraphValue] = []
                    maxValue = 0
                    lowestValue = 0
                    for i in 0..<currentDataPoints.count {
                        
                        if !(i < currentDataPoints.count) { continue }
                        
                        let newGv = newDataPoints[i]
                        let oldGv = currentDataPoints[i]
                        
                        let spreadValue = newGv.value + oldGv.value
                        let spreadCost = newGv.optionCost + oldGv.optionCost
                        
                        compareToBoundsAndSet(spreadValue)
                        
                        let gv = GraphValue(value: spreadValue, optionCost: spreadCost)
                        newArray.append(gv)
                    }
                    spreadData[underlyingStrikePrice] = newArray
                } else {
                    spreadData[underlyingStrikePrice] = valuesAtUnderlyingPrice.reversed()
                }
                
            }
        }
        
        reloadGraph()
        
        if let temp = temp,
            let index = optionLegs.firstIndex(where: {$0 == temp}){
            optionLegs.remove(at: index)
        }
    }
    
    func getIncrement(currentPrice: Double) -> Double {
        var increment : Double = 1.0
        //        let daysTillExpiration = getDaysUntil(closestExpiration)
        if currentPrice.isBetween(lower: 0, upper: 10)  {//|| daysTillExpiration < 10
            increment = 0.25
        } else if currentPrice.isBetween(lower: 10, upper: 20)  {//|| daysTillExpiration < 10
            increment = 0.5
        } else if currentPrice.isBetween(lower: 20, upper: 150) { //|| daysTillExpiration < 30
            increment = 1.0
        } else if currentPrice.isBetween(lower: 150, upper: 450) { //|| daysTillExpiration < 60
            increment = 2.0
        } else if currentPrice.isBetween(lower: 450, upper: 800) { //|| daysTillExpiration < 200
            increment = 3.0
        } else if currentPrice.isBetween(lower: 800, upper: 3000)  { //|| daysTillExpiration > 365
            increment = 5.0
        } else if currentPrice.isBetween(lower: 3000, upper: 10000)  { //|| daysTillExpiration > 365
            increment = 7.0
        }
        return increment
    }
    
    func getIncrement(minMax: (Double, Double)) -> Double {
        var increment : Double = 1.0
        let min = minMax.0
        let max = minMax.1
        increment = (max - min) / Double(strikeLimit)
        
        print(min, max, increment, strikeLimit)
        
        return increment
    }
    
    // Black Scholes Model
    func getValueForOption(option: OptionLeg, underlyingPrice: Double, day: Expiration) -> Double {

        guard let strikePrice = option.strikePrice else { return 0.0 }
        let t = Double(day.daysTillExp) / 365.0
        let d = OptionChain.currentDiv
        let r : Double = option.greeks?.rho ?? 0.5
        guard let iv : Double = option.greeks?.smv_vol else { return 0.0 }
        let e = Darwin.M_E

        let d1p1 = log(underlyingPrice / strikePrice)
        let d1p2 = t * (r - d + (pow(iv,2)/2) )
        let d1p3 = (iv * sqrt(t))
        let d1 = (d1p1 + d1p2) / d1p3
        let d2 = d1 - d1p3

        var value : Double = 0.0
        let qtPow = -(d*t)
        let rtPow = -(r*t)
        if option.type == .call {
            guard let ndd1 = Sigma.normalDistribution(x: d1) else { return 0.0 }
            guard let ndd2 = Sigma.normalDistribution(x: d2) else { return 0.0 }
            let call1 = underlyingPrice * (pow(e, qtPow)) * ndd1
            let call2 = strikePrice * (pow(e, rtPow)) * ndd2
            value = call1 - call2
        } else if option.type == .put {
            guard let ndd1 = Sigma.normalDistribution(x: -d1) else { return 0.0 }
            guard let ndd2 = Sigma.normalDistribution(x: -d2) else { return 0.0 }
            let put1 = strikePrice * (pow(e, rtPow)) * ndd2
            let put2 = underlyingPrice * (pow(e, qtPow)) * ndd1
            value = put1 - put2
        }
        
        if value < 0 || value == .nan || value == .signalingNaN || value.isNaN {
            value = 0
        }

        return value
    }
    
    func getDaysUntil(_ date: Date) -> Int {
        
        guard let diffInDays = Calendar.current.dateComponents([.day], from: Date().noon, to: date.noon).day else { return 0 }
        
        return diffInDays
    }
    
    func compareToBoundsAndSet(_ value: Double) {
        if value > maxValue {
            maxValue = value
        }
        if value < lowestValue {
            lowestValue = value
        }
    }
    
    func getMMdd(from date: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .day], from: date)
        guard let date = calendar.date(from:components) else { return ""}
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM'/'dd"
        return dateFormatter.string(from: date)
    }
    
}
