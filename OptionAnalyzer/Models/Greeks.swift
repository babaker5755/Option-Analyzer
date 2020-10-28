//
//  Greeks.swift
//  OptionAnalyzer
//
//  Created by Brandon Baker on 4/4/20.
//  Copyright © 2020 Brandon Baker. All rights reserved.
//

import UIKit
import SwiftyJSON

class Greeks: Codable {

    let phi : Double!
    let gamma : Double!
    let theta : Double!
    let delta : Double!
    let vega : Double!
    let mid_iv : Double!
    let smv_vol : Double!
    let rho : Double!
    
    init(_ greeks: JSON) {
        
        let phi = greeks["phi"].doubleValue
        let gamma = greeks["gamma"].doubleValue
        let theta = greeks["theta"].doubleValue
        let delta = greeks["delta"].doubleValue
        let vega = greeks["vega"].doubleValue
        let mid_iv = greeks["mid_iv"].doubleValue
        let rho = greeks["rho"].doubleValue
        let smv_vol = greeks["smv_vol"].doubleValue
        
        self.phi = phi
        self.gamma = gamma
        self.theta = theta
        self.delta = delta
        self.vega = vega
        self.mid_iv = mid_iv
        self.rho = rho
        self.smv_vol = smv_vol
    }
}
