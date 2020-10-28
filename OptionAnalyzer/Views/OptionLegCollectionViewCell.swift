//
//  OptionLegCollectionViewCell.swift
//  OptionAnalyzer
//
//  Created by Brandon Baker on 1/25/20.
//  Copyright © 2020 Brandon Baker. All rights reserved.
//

import UIKit
import Material
import MaterialComponents.MaterialDialogs

class OptionLegCollectionViewCell: UICollectionViewCell {
    
    let plusButton = FlatButton()
    let descriptionLabel = UILabel()
    
    var optionLeg : OptionLeg? {
        didSet {
            if let optionLeg = self.optionLeg {
                plusButton.isHidden = true
                descriptionLabel.isHidden = false
                descriptionLabel.text = optionLeg.getOptionInfo(forButton: true)
            } else {
                descriptionLabel.isHidden = true
                plusButton.isHidden = false
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = .foreground
        self.layer.cornerRadius = 4
        
        self.contentView.layer.cornerRadius = 2.0
        self.contentView.layer.borderWidth = 1.0
        self.contentView.layer.borderColor = UIColor.clear.cgColor
        self.contentView.layer.masksToBounds = true

        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        self.layer.shadowRadius = 2.0
        self.layer.shadowOpacity = 0.5
        self.layer.masksToBounds = false
        self.layer.shadowPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: self.contentView.layer.cornerRadius).cgPath
        
        plusButton.title = "+"
        plusButton.addTarget(self, action: #selector(addOptionLegView), for: .touchUpInside)
        plusButton.titleColor = .whiteText
        plusButton.titleLabel?.font = .avinerMedium
        plusButton.titleLabel?.fontSize = 32
        plusButton.titleLabel?.textAlignment = .center
        self.addSubview(plusButton)
        plusButton.snp.makeConstraints{ make in
            make.top.left.right.bottom.equalToSuperview()
        }
        
        descriptionLabel.textColor = .whiteText
        descriptionLabel.font = .avinerMedium
        descriptionLabel.numberOfLines = 3
        descriptionLabel.fontSize = 15
        descriptionLabel.textAlignment = .center
        self.addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalToSuperview()
        }
    
    }
    
    @objc func addOptionLegView() {
        if let parentFormView = self.superview?.superview as? FormView {
            if OptionChain.symbol == nil {
                return
            }
            plusButton.isEnabled = false
            parentFormView.addOptionLeg()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
