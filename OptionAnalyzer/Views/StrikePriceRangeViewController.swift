//
//  SettingsTableViewController.swift
//  OptionAnalyzer
//
//  Created by Brandon Baker on 6/9/20.
//  Copyright © 2020 Brandon Baker. All rights reserved.
//

import UIKit
import Material

protocol SettingModalDelegate {
    func didChangeSetting()
}

class StrikePriceRangeViewController: HalfScreenModalViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    let titleLabel = UILabel()
    var dataSource : [Double] = []
    var delegate : SettingModalDelegate?
    let picker = UIPickerView()
    
    var maxValue : Double = 0.0
    var minValue: Double = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.mainView.backgroundColor = .primaryForeground
        
        titleLabel.text = "Custom Strike Price Range"
        titleLabel.font = .boldSystemFont(ofSize: 21)
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.textColor = .whiteText
        titleLabel.textAlignment = .center
        self.mainView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.width.equalToSuperview().offset(-32)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(16)
        }
        
        
        guard var currentPrice = OptionChain.currentPrice?.rounded(.toNearestOrEven) else {
            let label  = UILabel()
            label.font = .avinerMedium
            label.adjustsFontSizeToFitWidth = true
            label.numberOfLines = 2
            label.text = "Type a symbol above and press + to add an option before selecting a custom strike range"
            label.textAlignment = .center
            label.textColor = .whiteText
            self.mainView.addSubview(label)
            label.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.centerX.equalToSuperview()
                make.width.equalToSuperview().offset(-64)
            }
            return
        }
        
        let lowLabel = UILabel()
        lowLabel.text = "Lowest Strike"
        lowLabel.textColor = .whiteText
        lowLabel.isUserInteractionEnabled = false
        lowLabel.textAlignment = .center
        self.mainView.addSubview(lowLabel)
        lowLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.width.equalToSuperview().multipliedBy(0.5)
            make.left.equalToSuperview().offset(24)
        }
        
        let highLabel = UILabel()
        highLabel.text = "Highest Strike"
        highLabel.textColor = .whiteText
        highLabel.isUserInteractionEnabled = false
        highLabel.textAlignment = .center
        self.mainView.addSubview(highLabel)
        highLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.width.equalToSuperview().multipliedBy(0.5)
            make.right.equalToSuperview().offset(-24)
        }
        
        
        let numberOfStrikes = 100
        let increment = OptionSpread.instance.getIncrement(currentPrice: currentPrice) * 2.5
        var strikeAxis : [Double] = Array(repeating: 0, count: numberOfStrikes)
        
        currentPrice += Double(increment * Double(numberOfStrikes) / 2.0)
        for i in 0..<strikeAxis.count {
            let axis = currentPrice - (Double(i) * increment)
            if axis >= 0 {
                strikeAxis[i] = axis
            }
        }
        dataSource = strikeAxis
        
        picker.layer.zPosition = 5
        picker.delegate = self
        picker.dataSource = self
        self.mainView.addSubview(picker)
        picker.snp.makeConstraints { make in
            make.top.equalTo(highLabel.snp.bottom).offset(8)
            make.width.equalToSuperview().offset(-32)
            make.centerX.equalToSuperview()
            make.height.greaterThanOrEqualTo(150)
        }
        
        if let minMax = OptionSpread.instance.minMax {
            self.picker.selectRow(dataSource.firstIndex(of: minMax.0) ?? dataSource.count - 1, inComponent: 0, animated: false)
            self.picker.selectRow(dataSource.firstIndex(of: minMax.1) ?? 0, inComponent: 1, animated: false)
        } else {
            self.picker.selectRow(dataSource.count - 1, inComponent: 0, animated: false)
            self.picker.selectRow(0, inComponent: 1, animated: false)
        }
        
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        print(dataSource[row])
        var minMax : (Double, Double) = OptionSpread.instance.minMax ?? (dataSource.last ?? 0.0,dataSource.first ?? 0.0)
        
        if component == 0 {
            if dataSource[row] > minMax.1 {
                minValue = minMax.1
                minMax.0 = minMax.1
                self.picker.selectRow(dataSource.firstIndex(of: minMax.1) ?? dataSource.count - 1,
                                      inComponent: 0,
                                      animated: true)
            } else {
                minValue = dataSource[row]
                minMax.0 = dataSource[row]
            }
        } else if component == 1 {
            if dataSource[row] < minMax.0 {
                maxValue = minMax.0
                maxValue = minMax.0
                self.picker.selectRow(dataSource.firstIndex(of: minMax.0) ?? 0,
                                      inComponent: 1,
                                      animated: true)
            } else {
                maxValue = dataSource[row]
                minMax.1 = dataSource[row]
            }
        }
        OptionSpread.instance.minMax = minMax
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return dataSource.count
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        return NSAttributedString(string: dataSource[row].getString(2),
                                  attributes: [NSAttributedString.Key.foregroundColor : UIColor.whiteText])
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        dismissAndRefresh()
    }
    
    func dismissAndRefresh() {
        delegate?.didChangeSetting()
        self.dismiss(animated: true, completion: nil)
    }
    
}

