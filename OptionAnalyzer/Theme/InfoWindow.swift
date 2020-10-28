//
//  InfoWindow.swift
//  OptionAnalyzer
//
//  Created by Brandon Baker on 4/15/20.
//  Copyright © 2020 Brandon Baker. All rights reserved.
//

import UIKit

class InfoWindow: UIView {

    init(text: String, frame: CGRect) {
        super.init(frame: frame)
        self.alpha = 0.0
        self.backgroundColor = UIColor.primaryForeground.withAlphaComponent(0.7)
        let label = UILabel()
        label.textColor = .whiteText
        label.adjustsFontSizeToFitWidth = true
        label.baselineAdjustment = .alignCenters
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = text
        label.font = .avinerMedium
        label.fontSize = 17
        self.addSubview(label)
        label.snp.makeConstraints { make in
            make.top.left.equalToSuperview().offset(8)
            make.right.bottom.equalToSuperview().offset(-8)
        }
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func showInfoWindow(duration : Double = 4) {
        UIView.animate(withDuration: 0.5, animations: {
            self.alpha = 1.0
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: {
            UIView.animate(withDuration: 0.5, animations: {
                self.alpha = 0.0
            },completion: {_ in
                self.removeFromSuperview()
            })
        })
    }

}
