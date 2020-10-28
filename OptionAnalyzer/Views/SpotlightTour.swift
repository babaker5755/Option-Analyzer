//
//  SpotlightTour.swift
//  OptionAnalyzer
//
//  Created by Brandon Baker on 5/1/20.
//  Copyright © 2020 Brandon Baker. All rights reserved.
//

import UIKit
import AwesomeSpotlightView
import Material

extension ViewController : AwesomeSpotlightViewDelegate {
    
    func startSpotlightTour() {
        let halfWidth = (Screen.width) / 2
        let spotlight0 = AwesomeSpotlight(withRect: CGRect(x: 0, y: Screen.height / 2 - 150, width: 0, height: 0), shape: .roundRectangle, text: "Welcome to OptionAnalyzer!\nPlease take this quick tour to get started!\n\n Tap anywhere to continue.")
        let spotlight1 = AwesomeSpotlight(withRect: CGRect(x: 8, y: 135, width: halfWidth, height: 70), shape: .roundRectangle, text: "Type a symbol to get option chain data.")
        let spotlight2 = AwesomeSpotlight(withRect: CGRect(x: 8, y: 195, width: halfWidth, height: (halfWidth / 2) + 30), shape: .roundRectangle, text: "Add an option leg to the graph by pressing the + button.")
        let spotlight3 = AwesomeSpotlight(withRect: CGRect(x: 0, y: 250, width: Screen.width, height: Screen.height - 250), shape: .roundRectangle, text: "You can view the graph update in real time as you select the expiration and strike price of your option leg.")
        let spotlight4 = AwesomeSpotlight(withRect: CGRect(x: Screen.width - 68, y: 32, width: 60, height: 60), shape: .roundRectangle, text: "Configure settings, enter full screen mode, and set the graph mode to view different statistics on your graphed data.")
        
        spotlightView = AwesomeSpotlightView(frame: view.frame, spotlight: [spotlight0, spotlight1, spotlight2, spotlight3, spotlight4])
        spotlightView.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        spotlightView.cutoutRadius = 8
        spotlightView.delegate = self
        view.addSubview(spotlightView)
        spotlightView.start()
    }
    
    func performOnTimer(_ action: @escaping (() -> Void)) {
        action()
    }
    
    func spotlightView(_ spotlightView: AwesomeSpotlightView, didNavigateToIndex index: Int) {
        switch index {
        case 1:
            performOnTimer {
                self.formView.symbolField.text = "aapl"
            }
        case 2:
            performOnTimer {
                self.formView.textFieldDidEndEditing(self.formView.symbolField)
            }
        case 3:
            performOnTimer {
                self.formView.addOptionLeg()
            }
        case 4:
            performOnTimer {
                if let selectionView = self.optionSelectionViewController.view as? OptionSelectionView {
                    selectionView.pressedSave()
                }
                Helpers.trackEvent(LocalStorage.finishedTour ? "Completed Tour" : "Completed First Tour")
                LocalStorage.finishedTour = true
            }
        default:
            break
        }
    }
}
