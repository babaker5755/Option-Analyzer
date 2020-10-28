//
//  HalfScreenModalViewController.swift
//  OptionAnalyzer
//
//  Created by Brandon Baker on 6/9/20.
//  Copyright © 2020 Brandon Baker. All rights reserved.
//

import UIKit
import Material

class HalfScreenModalViewController: UIViewController {
    
    let nameField = TextField()
    var height = Screen.height / 2 {
        didSet {
            mainView.snp.remakeConstraints { make in
                make.bottom.equalToSuperview()
                make.height.equalTo(height)
                make.width.centerX.equalToSuperview()
            }
        }
    }
    let mainView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .clear
        
        mainView.backgroundColor = .white
        mainView.layer.cornerRadius = 16
        mainView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        self.view.addSubview(mainView)
        mainView.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.height.equalTo(height)
            make.width.centerX.equalToSuperview()
        }
        
        self.modalPresentationStyle = .pageSheet
    }
    
}
