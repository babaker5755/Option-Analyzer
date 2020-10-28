//
//  GraphCell.swift
//  OptionAnalyzer
//
//  Created by Brandon Baker on 1/31/20.
//  Copyright © 2020 Brandon Baker. All rights reserved.
//

import UIKit
import Material

class GraphCell: UIView {
    
    var value : CGFloat? = nil
    
    let size : CGFloat = 35
    let padding : CGFloat = 3
    
    var displayText : String? = nil
    
    lazy var label : UILabel = {
        let frame = CGRect(origin: .zero, size: CGSize(width: size - (padding), height: size - (padding)))
        let label = UILabel(frame: frame)
        label.text = "\(value ?? 0)"
        label.textColor = .darkText
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.textColor = .white
        label.fontSize = 15
        return label
    }()
    
    init(gv: GraphValue, x: CGFloat, y: CGFloat) {
        self.value = NumberFormatter().number(from: gv.stringValue) as? CGFloat
        super.init(frame: CGRect(x: (x * size) + (size * 2), y: (y * size) + (size * 2), width: size - padding, height: size - padding))
        self.layer.cornerRadius = 2
        self.layer.masksToBounds = true
        label.frame = CGRect(x: padding, y: 0, width: size - (padding * 3), height: size - padding)
        label.textColor = .black
        self.addSubview(label)
        self.backgroundColor = gv.color
        
        self.displayText = "Cost: $\(gv.optionCost.getString())\nValue: $\(gv.value.getString())"
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.showInfoWindow))
        self.addGestureRecognizer(tap)
        
        let delay = Double(sqrt(x * y) * 0.04)
        fadeIn(delay)
    }
    
    // Strike
    init(row: Int, text: String, closestCell: Bool = false, x: CGFloat = 0) {
        let y = CGFloat(row)
        self.value = y
        
        super.init(frame: CGRect(x: (x) * size, y: (y * size) + (size * 2), width: (size * 2) - padding, height: size - padding))
        self.backgroundColor = .clear
        if closestCell {
            addBorder((y * size) + (size * 2))
        }
        label.frame = CGRect(origin: .zero, size: CGSize(width: (size * 2) - padding, height: size - padding))
        label.text = text
        self.addSubview(label)
    }
    
    init(column: Int, text: String) {
        let x = CGFloat(column)
        self.value = x
        super.init(frame: CGRect(x: (x * size) + (size * 2), y: size, width: size - padding, height: size - padding))
        self.backgroundColor = .clear
        
        label.text = text
        self.addSubview(label)
    }
    
    init(month: Month) {
        let x = CGFloat(month.startIndex)
        let width = (CGFloat(month.endIndex - month.startIndex) + 1) * size
        self.value = x
        super.init(frame: CGRect(x: (x * size) + (size * 2), y: 0, width: width - padding, height: size - padding))
        self.backgroundColor = .clear
        
        label.frame = CGRect(x: 0, y: 0, width: width - padding, height: size - padding)
        label.text = month.name
        label.fontSize = 19
        self.addSubview(label)
    }
    
    func fadeIn(_ delay : Double) {
        self.alpha = 0.0
        self.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        UIView.animate(withDuration: 0.1, animations: {
            self.transform = CGAffineTransform.identity
            self.alpha = 1.0
        })
    }
    
    func addBorder(_ y: CGFloat) {
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.borderWidth = 2
    }
    
    @objc func showInfoWindow() {
        guard let text = displayText else { return }
        guard let superview = self.superview else { return }
        let infoWindow = InfoWindow(text: text, frame: CGRect(center: self.center, size: CGSize(width: size * 3.5, height: size * 2.8)))
        infoWindow.backgroundColor = UIColor.foreground.withAlphaComponent(0.96)
        infoWindow.layer.cornerRadius = 4
        superview.addSubview(infoWindow)
        infoWindow.showInfoWindow(duration: 4)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
