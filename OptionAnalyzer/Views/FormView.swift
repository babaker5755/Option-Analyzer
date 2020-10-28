//
//  FormView.swift
//  OptionAnalyzer
//
//  Created by Brandon Baker on 1/24/20.
//  Copyright © 2020 Brandon Baker. All rights reserved.
//

import UIKit
import Material
import SnapKit
import Alamofire
import SwiftyJSON
import MMMaterialDesignSpinner

class FormView: UIView, TextFieldDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    
    let symbolField = TextField()
    let currentPriceLabel = UILabel()
    var collectionView : UICollectionView!
    
    let spinner = MMMaterialDesignSpinner()
    
    init() {
        super.init(frame: CGRect.zero)
        
        setupViews()
        
    }
    
    private func setupViews() {
        
        let halfWidth = (Screen.width - 48) / 2
        
        symbolField.placeholder = "Stock symbol"
        symbolField.font = .avinerMedium
        symbolField.placeholderActiveColor = .primary
        symbolField.placeholderNormalColor = .primary
        symbolField.dividerActiveColor = .primary
        symbolField.dividerNormalColor = .primary
        symbolField.returnKeyType = .done
        symbolField.autocorrectionType = .no
        symbolField.delegate = self
        symbolField.textColor = .whiteText
        symbolField.contentVerticalAlignment = .center
        self.addSubview(symbolField)
        symbolField.snp.makeConstraints { make in
            make.width.equalTo(halfWidth)
            make.height.equalTo(40)
            make.top.equalToSuperview().offset(70)
            make.left.equalToSuperview().offset(16)
        }
        
        currentPriceLabel.text = "--"
        currentPriceLabel.font = .avinerMedium
        currentPriceLabel.textAlignment = .center
        currentPriceLabel.textColor = .whiteText
        currentPriceLabel.contentMode = .center
        self.addSubview(currentPriceLabel)
        currentPriceLabel.snp.makeConstraints { make in
            make.width.equalTo(halfWidth)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(40)
            make.top.equalToSuperview().offset(70)
        }
        
        spinner.tintColor = .primary
        self.addSubview(spinner)
        spinner.snp.makeConstraints { make in
            make.width.height.equalTo(25)
            make.center.equalTo(currentPriceLabel.snp.center)
        }
        
        let maxSize = (UIScreen.main.bounds.width / 2) - 32
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: maxSize, height: maxSize * 0.5)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 10
        layout.scrollDirection = UICollectionView.ScrollDirection.vertical
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.setCollectionViewLayout(layout, animated: true)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(OptionLegCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        self.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(symbolField.snp.bottom).offset(24)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return OptionSpread.instance.optionLegs.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! OptionLegCollectionViewCell
        if indexPath.row == OptionSpread.instance.optionLegs.count {
            cell.plusButton.isEnabled = true
            cell.optionLeg = nil
            return cell
        }
        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(gesture:)))
        cell.addGestureRecognizer(lpgr)
        cell.optionLeg = OptionSpread.instance.optionLegs[indexPath.row]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == OptionSpread.instance.optionLegs.count { return }
        guard OptionSpread.instance.optionLegs.count > indexPath.row else { return }
        let optionLeg = OptionSpread.instance.optionLegs[indexPath.row]
        editOptionLeg(optionLeg)
    }
    
    @objc func handleLongPress(gesture : UILongPressGestureRecognizer!) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        let p = gesture.location(in: self.collectionView)
        if let indexPath = self.collectionView.indexPathForItem(at: p) {
            guard let vc = self.next?.next as? ViewController else { return }
            vc.showAlert(title: "Deleting Option Leg", message: "Tap the button below to delete", buttonTitle: "DELETE", completion: {
                guard let cell = self.collectionView.cellForItem(at: indexPath) as? OptionLegCollectionViewCell else { return }
                guard let index = OptionSpread.instance.optionLegs.firstIndex(where: { cell.optionLeg == $0 }) else { return }
                OptionSpread.instance.optionLegs.remove(at: index)
                self.collectionView.reloadData()
                OptionSpread.instance.updateSpread()
                OptionSpread.instance.reloadGraph()
            })
        } else {
            print("couldn't find index path")
        }
    }
    
    func editOptionLeg(_ optionLeg: OptionLeg) {
        guard let vc = self.next?.next as? ViewController,
            let index = OptionSpread.instance.optionLegs.firstIndex(where: { optionLeg == $0 })else { return }
        OptionSpread.instance.optionLegs.remove(at: index)
        vc.showOptionSelectionView(optionLeg)
    }
    
    func addOptionLeg() {
        guard let vc = self.next?.next as? ViewController else { return }
        guard OptionSpread.instance.optionLegs.count < 10 else {
            self.collectionView.reloadData()
            vc.showAlert(title: "Too many option legs", message: "At this time, the maximum number of option legs is limited to 10.",completion: { })
            return
        }
        if OptionSpread.instance.optionLegs.count > 0  && !Products.store.isPurchased("1") {
            self.collectionView.reloadData()
            vc.showPurchaseViewController(completion: {})
            return
        }
        vc.showOptionSelectionView()
    }
    
    func clearOptionInfo() {
        self.currentPriceLabel.text = "--"
        OptionChain.symbol = nil
        OptionSpread.instance.optionLegs = []
        collectionView.reloadData()
        OptionSpread.instance.updateSpread()
        OptionSpread.instance.reloadGraph()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        clearOptionInfo()
        guard let symbol = textField.text?.trimmed, symbol != ""  else { return }
        loadOptionSymbol(symbol)
    }
    
    func loadOptionSymbol(_ symbol: String, completion: (() -> Void)? = nil) {
        currentPriceLabel.text = ""
        spinner.startAnimating()
        OptionChain.getUnderlyingPrice(symbol: symbol, completion: { success in
            self.spinner.stopAnimating()
            if success {
                if let price = OptionChain.currentPrice {
                    self.currentPriceLabel.text = "$\(price.getString())"
                }
                completion?()
            } else {
                guard let vc = self.next?.next as? ViewController else { return }
                vc.showAlert(title: "Error", message: "There was an error getting the price for that symbol, please check that you are entering a valid symbol.", completion: {
                    self.clearOptionInfo()
                    self.symbolField.text = ""
                })
            }
        })
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        _ = textField.resignFirstResponder()
        return true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
