//
//  OptionSelectionView.swift
//  OptionAnalyzer
//
//  Created by Brandon Baker on 1/24/20.
//  Copyright © 2020 Brandon Baker. All rights reserved.
//

import UIKit
import Material
import UPCarouselFlowLayout
import MMMaterialDesignSpinner
import AwesomeEnum

class OptionSelectionView: UIView, UIPickerViewDelegate, UIPickerViewDataSource {

    var optionLeg : OptionLeg!
    var close : (() -> Void)!
    let picker = UIPickerView()
    
    let descriptionLabel = UILabel()
    let spinner = MMMaterialDesignSpinner()
    
    let typeSelector : UISegmentedControl = UISegmentedControl(items: [OptionType.call.rawValue, OptionType.put.rawValue])
    let directionSelector : UISegmentedControl = UISegmentedControl(items: [OptionDirection.long.rawValue, OptionDirection.short.rawValue])
    var selectedOption : Option? = nil
    
    var isLoading : Bool = false {
        didSet {
            if isLoading {
                picker.isHidden = true
                spinner.startAnimating()
            } else {
                picker.isHidden = false
                spinner.stopAnimating()
            }
        }
    }
    
    var selectedExpiration : String? = nil {
        didSet {
            guard let selectedExpiration = selectedExpiration else { return }
            isLoading = true
            OptionChain.getOptionChain(expiration: selectedExpiration) { success in
                self.isLoading = false
                guard success else { return }
                self.loadOptionLegInfo()
                OptionSpread.instance.updateSpread()
                self.picker.reloadComponent(1)
                guard let index = self.options.firstIndex(where: { Double($0.strikePrice) ?? 0.0 < OptionChain.currentPrice ?? 0.0 }) else { return }
                self.picker.selectRow(index, inComponent: 1, animated: false)
                self.pickerView(self.picker, didSelectRow: index, inComponent: 1)
            }
            self.optionLeg.setExpiration(expiration: selectedExpiration)
        }
    }
    
    var selectedStrikePrice : String? = nil {
        didSet {
            guard var strikePrice = selectedStrikePrice else { return }
            strikePrice.removeAll(where: {$0 == "$"})
            let splitString = strikePrice.components(separatedBy: " - ")
            if splitString.count > 1 {
                self.optionLeg.setPrice(price: splitString[1])
            }
            guard let option = selectedOption else { return }
            self.optionLeg.greeks = option.greeks
            self.optionLeg.setStrikePrice(strikePrice: splitString[0])
            loadOptionLegInfo()
            OptionSpread.instance.updateSpread(temp: self.optionLeg)
        }
    }
    
    init() {
        optionLeg = OptionLeg(strikePrice : 0.00, price: 0.00, expiration: Date(), type: .call, direction: .long, greeks: nil)
        super.init(frame: CGRect.zero)
        self.backgroundColor = .primaryForeground
        
        loadOptionLegInfo()
        setupViews()
        
    }
    
    func scrollToOptionLeg(_ optionLeg: OptionLeg) {
        // TODO
    }
    
    @objc func directionSelected(_ sender: Any) {
        guard let selector = sender as? UISegmentedControl else { return }
        let direction : OptionDirection = selector.selectedSegmentIndex == 0 ? .long : .short
        self.optionLeg.direction = direction
        let currentExpiration = selectedExpiration
        self.selectedExpiration = currentExpiration
        loadOptionLegInfo()
    }
    
    @objc func typeSelected(_ sender: Any) {
        guard let selector = sender as? UISegmentedControl else { return }
        let type : OptionType = selector.selectedSegmentIndex == 0 ? .call : .put
        self.optionLeg.type = type
        loadOptionLegInfo()
        self.picker.reloadComponent(1)
        pickerView(picker, didSelectRow: self.picker.selectedRow(inComponent: 1), inComponent: 1)
    }
    
    var options : [Option] {
        return OptionChain.options.filter { $0.type == optionLeg.type }.reversed()
    }
    
    func getOptionPrice(_ option: Option) -> String {
        return "$\(option.strikePrice ?? "") - $\(option.price ?? "")"
    }
    
    func loadOptionLegInfo() {
        descriptionLabel.text = optionLeg.getOptionInfo()
        typeSelector.selectedSegmentIndex = (optionLeg.type == .put) ? 1 : 0
        directionSelector.selectedSegmentIndex = (optionLeg.direction == .short) ? 1 : 0
    }
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        switch (component){
        case 0:
            return Screen.width * 0.4
        case 1:
            return Screen.width * 0.6
        default: return 0
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 0 {
            return OptionChain.dates.count
        }
        return options.count
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        if component == 0 {
            return NSAttributedString(string: OptionChain.dates[row], attributes: [NSAttributedString.Key.foregroundColor : UIColor.whiteText])
        }
        return NSAttributedString(string: getOptionPrice(options[row]), attributes: [NSAttributedString.Key.foregroundColor : UIColor.whiteText])
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if component == 0 {
            self.selectedExpiration = OptionChain.dates[row]
            return
        }
        let prices = options.map { getOptionPrice($0) }
        guard row < prices.count else { return }
        self.selectedOption = OptionChain.options[row]
        self.selectedStrikePrice = prices[row]
    }
    
    @objc func pressedSave() {
        if let optionLeg = self.optionLeg {
            OptionSpread.instance.optionLegs.append(optionLeg)
        }
        OptionSpread.instance.updateSpread()
        close()
    }
    
    @objc func pressedClose() {
        close()
        OptionSpread.instance.updateSpread()
        OptionSpread.instance.reloadGraph()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}


extension OptionSelectionView {
    
    func setupViews() {
        
        let labelView = UIView()
        labelView.backgroundColor = .background
        labelView.layer.zPosition = 10
        labelView.layer.shadowColor = Color.black.cgColor
        labelView.layer.shadowOffset = CGSize(width: 0, height: 4)
        labelView.layer.shadowRadius = 4
        labelView.layer.shadowOpacity = 0.5
        
        let closeButton = FlatButton(image: Awesome.Regular.windowClose.asImage(size: 28, color: Color.red.withAlphaComponent(0.7), backgroundColor: .clear))
        closeButton.addTarget(self, action: #selector(pressedClose), for: .touchUpInside)
        labelView.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.height.width.equalTo(40)
        }
        
        let saveCheck = FlatButton(image: Awesome.Solid.check.asImage(size: 28, color: Color.green.withAlphaComponent(0.7), backgroundColor: .clear))
        saveCheck.addTarget(self, action: #selector(pressedSave), for: .touchUpInside)
        labelView.addSubview(saveCheck)
        saveCheck.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.height.width.equalTo(40)
        }
        
        for (i, text) in ["Expiration", "Strike - Price"].enumerated() {
            let label = UILabel()
            label.text = text
            label.textColor = .whiteText
            label.isUserInteractionEnabled = false
            label.textAlignment = .center
            labelView.addSubview(label)
            label.snp.makeConstraints { make in
                make.height.equalToSuperview()
                make.centerY.equalToSuperview()
                make.width.equalToSuperview().multipliedBy(0.5)
                _ = i == 0 ? make.left.equalToSuperview().offset(24) : make.right.equalToSuperview().offset(-24)
            }
        }
        self.addSubview(labelView)
        labelView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.height.equalTo(40)
            make.width.centerX.equalToSuperview()
        }
        
        
        descriptionLabel.font = .avinerMedium
        descriptionLabel.fontSize = 17
        descriptionLabel.textColor = .whiteText
        descriptionLabel.numberOfLines = 2
        descriptionLabel.textAlignment = .center
        descriptionLabel.adjustsFontSizeToFitWidth = true
        self.addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(40)
            make.height.equalTo(70)
            make.width.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        
        
        let halfWidth = (Screen.width - 48) / 2
        directionSelector.setTitleTextAttributes([
            NSAttributedString.Key.foregroundColor: UIColor.whiteText,
        ], for: .normal)
        directionSelector.selectedSegmentTintColor = .foreground
        directionSelector.backgroundColor = .background
        directionSelector.addTarget(self, action: #selector(directionSelected(_:)), for: .valueChanged)
        self.addSubview(directionSelector)
        directionSelector.snp.makeConstraints{ make in
            make.top.equalTo(descriptionLabel.snp.bottom)
            make.left.equalToSuperview().offset(16)
            make.width.equalTo(halfWidth)
            make.height.equalTo(35)
        }
        
        typeSelector.setTitleTextAttributes([
            NSAttributedString.Key.foregroundColor: UIColor.whiteText,
        ], for: .normal)
        typeSelector.selectedSegmentTintColor = .foreground
        typeSelector.backgroundColor = .background
        typeSelector.addTarget(self, action: #selector(typeSelected(_:)), for: .valueChanged)
        self.addSubview(typeSelector)
        typeSelector.snp.makeConstraints{ make in
            make.top.equalTo(directionSelector.snp.top)
            make.right.equalToSuperview().offset(-16)
            make.width.equalTo(halfWidth)
            make.height.equalTo(directionSelector.snp.height)
        }
        
        picker.layer.zPosition = 5
        picker.delegate = self
        picker.dataSource = self
        self.addSubview(picker)
        picker.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-8)
            make.top.equalTo(typeSelector.snp.bottom).offset(8)
            make.width.equalToSuperview().offset(-32)
            make.centerX.equalToSuperview()
        }
        
        spinner.isHidden = true
        spinner.tintColor = .primary
        spinner.hidesWhenStopped = true
        self.addSubview(spinner)
        spinner.snp.makeConstraints { make in
            make.centerX.equalTo(picker.snp.centerX)
            make.centerY.equalTo(picker.snp.centerY).offset(20)
            make.width.height.equalTo(40)
        }
        
        if OptionChain.dates.count > 0 {
            pickerView(picker, didSelectRow: 0, inComponent: 0)
        }
    }
}

