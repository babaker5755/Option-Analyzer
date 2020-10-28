//
//  Settings.swift
//  OptionAnalyzer
//
//  Created by Brandon Baker on 4/11/20.
//  Copyright © 2020 Brandon Baker. All rights reserved.
//

import UIKit

enum GraphMode : String, CaseIterable {
    
    case percentOfCost = "percentOfCost"
    case value = "value"
    case profit = "profit"
    case percentProfit = "percentProfit"
    
    func name() -> String {
        switch self {
        case .percentProfit : return "Percent Gain"
        case .percentOfCost : return "Percent of Cost"
        case .value : return "Option/Spread Value"
        case .profit : return "Option/Spread Profit"
        }
    }
    
    static func withLabel(_ label: String) -> GraphMode? {
        return self.allCases.first{ "\($0)" == label }
    }
    
}

class LocalStorage {
    
    public static var finishedTour : Bool {
        get {
            return UserDefaults().bool(forKey: "finishedTour")
        }
        set {
            UserDefaults().set(newValue, forKey: "finishedTour")
        }
    }
    
    public static var key : String? = nil {
        didSet {
            if key == nil {
                AppDelegate.fetchKeyFromDatabase()
            }
        }
    }
    
    public static var userId : String {
        get {
            return UserDefaults().string(forKey: "userId") ?? UUID().uuidString
        }
        set {
            UserDefaults().set(newValue, forKey: "userId")
        }
    }
    
}

class Settings {

    public static var graphMode: GraphMode {
        get {
            let string = UserDefaults().string(forKey: "graphMode")
            return GraphMode.withLabel(string ?? "percentOfRisk") ?? .percentOfCost
        }
        set {
            UserDefaults().set(newValue.rawValue, forKey: "graphMode")
        }
    }
    
    public static var savedStrategies : [OptionStrategy] {
        get {
            if let data = UserDefaults.standard.data(forKey: "savedStrategies") {
                do {
                    // Create JSON Decoder
                    let decoder = JSONDecoder()

                    // Decode Note
                    let strategies = try decoder.decode([OptionStrategy].self, from: data)

                    return strategies
                } catch {
                    print("Unable to Decode Notes (\(error))")
                }
            }
            return []
        }
        set {

            do {
                // Create JSON Encoder
                let encoder = JSONEncoder()

                // Encode Note
                let data = try encoder.encode(newValue)

                // Write/Set Data
                UserDefaults.standard.set(data, forKey: "savedStrategies")

            } catch {
                print("Unable to Encode Note (\(error))")
            }
        }
    }
    
    
    
}
