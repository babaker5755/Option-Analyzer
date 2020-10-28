//
//  ViewController.swift
//  OptionAnalyzer
//
//  Created by Brandon Baker on 1/24/20.
//  Copyright © 2020 Brandon Baker. All rights reserved.
//

import UIKit
import Material
import AwesomeEnum
import DropDown
import AwesomeSpotlightView

class ViewController: UIViewController, UIScrollViewDelegate, SettingModalDelegate {
    
    let titleLabel = UILabel()
    let formView = FormView()
    let graphViewController = UIViewController()
    let optionSelectionViewController = UIViewController()
    let dropdown = DropDown()
    
    var spotlightView = AwesomeSpotlightView()
    var tourTimer = Timer()
    var seconds = 5
    
    var settings : [SettingOption] = SettingOption.allCases
    
    var graphModes : [GraphMode] = [.percentOfCost, .value, .profit, .percentProfit] 
    
    var graph = Graph()
    var infoButton = FlatButton()
    var settingsButton = FlatButton()
    
    let optionSelectionViewHeight : CGFloat = (Screen.height / 2) - 100
    let graphViewHeight : CGFloat = (Screen.height / 2) + 20
    
    var selectionViewIsOpened : Bool = false {
        didSet {
            Graph.text = selectionViewIsOpened ? "Select an expiration and strike to view the graph" : "Type a symbol above and\npress + to add an option"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .background
        
        setupViews()
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(touchedView))
        gestureRecognizer.cancelsTouchesInView = false
        self.view.addGestureRecognizer(gestureRecognizer)
        
        if !LocalStorage.finishedTour {
            startSpotlightTour()
        }
        
    }
    
    func showOptionSelectionView(_ optionLeg : OptionLeg? = nil) {
        guard OptionChain.symbol != nil, OptionChain.currentPrice != nil else { return }
        let optionSelectionView = OptionSelectionView()
        optionSelectionView.close = {
            self.animateVcs() {
                optionSelectionView.removeFromSuperview()
                self.formView.collectionView.reloadData()
            }
        }
        optionSelectionViewController.view = optionSelectionView
        optionSelectionViewController.view.frame = CGRect(x: 0, y: Screen.height, width: Screen.width, height: optionSelectionViewHeight)
        addChild(optionSelectionViewController)
        self.view.addSubview(optionSelectionView)
        optionSelectionViewController.didMove(toParent: self)
        animateVcs() {
            guard let optionLeg = optionLeg else { return }
            optionSelectionView.scrollToOptionLeg(optionLeg)
        }
    }
    
    func animateVcs(completion: (() -> Void)? = nil) {
        self.formView.collectionView.isUserInteractionEnabled = self.selectionViewIsOpened
        UIView.animate(withDuration: 0.5, animations: {
            if !self.selectionViewIsOpened {
                self.titleLabel.frame.origin.y -= 35
                self.optionSelectionViewController.view.frame.origin.y -= self.optionSelectionViewHeight
                self.graphViewController.view.frame.origin.y -= self.optionSelectionViewHeight
            } else {
                self.titleLabel.frame.origin.y += 35
                self.optionSelectionViewController.view.frame.origin.y += self.optionSelectionViewHeight
                self.graphViewController.view.frame.origin.y += self.optionSelectionViewHeight
            }
            self.selectionViewIsOpened = !self.selectionViewIsOpened
        }, completion: { _ in
                completion?()
        })
    }
    
    func moveTitleLabel(up: Bool) {
        self.titleLabel.frame.origin.y += up ? -35 : 35
    }
    
    func setupViews() {
        
        titleLabel.frame = CGRect(x: 0, y: 80, width: Screen.width, height: 30)
        titleLabel.text = "OptionAnalyzer"
        titleLabel.textColor = .whiteText
        titleLabel.font = .avinerMedium
        titleLabel.fontSize = 25
        titleLabel.textAlignment = .center
        self.view.addSubview(titleLabel)
        
        
        self.view.addSubview(formView)
        formView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(80)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-graphViewHeight)
        }
        
        graph.layer.shadowColor = UIColor.black.cgColor
        graph.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        graph.layer.shadowRadius = 2
        graph.layer.shadowOpacity = 0.5
        graph.layer.cornerRadius = 4
        graph.layer.masksToBounds = true
        graph.backgroundColor = UIColor.foreground
        graph.delegate = self
        
        let frame = CGRect(x: 0, y: Screen.height - graphViewHeight, width: Screen.width, height: graphViewHeight)
        graphViewController.view = graph
        graphViewController.view.frame = frame
        addChild(graphViewController)
        self.view.addSubview(graph)
        graphViewController.didMove(toParent: self)
        
        OptionSpread.instance.reloadGraph = reloadGraph
        
        let size : CGFloat = 24
        let infoImage = Awesome.Solid.infoCircle.asImage(size: size, color: .background, backgroundColor: .clear)
        infoButton = FlatButton(image: infoImage)
        infoButton.addTarget(self, action: #selector(showInfoWindow), for: .touchUpInside)
        infoButton.layer.cornerRadius = size / 2
        graph.subview.addSubview(infoButton)
        infoButton.snp.makeConstraints { make in
            make.top.left.equalToSuperview().offset(16)
            make.width.height.equalTo(size)
        }
        
        let cogImage = Awesome.Solid.cog.asImage(size: size, color: .foreground, backgroundColor: .clear)
        settingsButton = FlatButton(image: cogImage)
        settingsButton.frame = CGRect(x: Screen.width - 48, y: 40, width: 32, height: 32)
        settingsButton.addTarget(self, action: #selector(showDropDown), for: .touchUpInside)
        settingsButton.layer.cornerRadius = size / 2
        self.view.addSubview(settingsButton)
        dropdown.anchorView = settingsButton
        dropdown.dataSource = self.settings.map { $0.rawValue }
        dropdown.selectionAction = { (index, item) in
            guard let settingOption : SettingOption = SettingOption(rawValue: item) else {
                switch item {
                case "Save Strategy":
                    self.saveStrategy()
                case "View Strategies":
                    let vc = SavedSpreadsTableViewController()
                    vc.completion = { symbol in
                        self.formView.loadOptionSymbol(symbol) {
                            self.formView.symbolField.text = symbol
                            self.formView.collectionView.reloadData()
                            OptionSpread.instance.updateSpread()
                            OptionSpread.instance.reloadGraph()
                        }
                    }
                    self.present(vc, animated: true, completion: nil)
                    self.dropdown.dataSource = self.settings.map { $0.rawValue }
                default:
                    Settings.graphMode = self.graphModes.first(where: { $0.name() == item }) ?? .percentOfCost
                    self.dropdown.hide()
                    self.dropdown.dataSource = self.settings.map { $0.rawValue }
                    OptionSpread.instance.updateSpread()
                    self.reloadGraph()
                }
                return
            }
            
            switch settingOption {
            case .fullScreen:
                self.toggleFullScreen()
                self.dropdown.hide()
            case .graphMode:
                self.dropdown.dataSource = self.graphModes.map { $0.name() }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.dropdown.show()
                }
            case .strikeRange:
                let modal = StrikePriceRangeViewController()
                modal.delegate = self
                self.present(modal, animated: true, completion: nil)
            case .clear:
                self.dropdown.hide()
                OptionSpread.instance.optionLegs = []
                OptionSpread.instance.minMax = nil
                self.formView.collectionView.reloadData()
                OptionSpread.instance.updateSpread()
                self.reloadGraph()
            case .tour:
                self.startSpotlightTour()
            case .strategies:
                guard Products.store.isPurchased("1") else {
                    self.showPurchaseViewController(completion: {})
                    return
                }
                self.dropdown.dataSource = ["Save Strategy", "View Strategies"]
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.dropdown.show()
                }
            }
        }
    }
    
    func didChangeSetting() {
        OptionSpread.instance.updateSpread()
        self.reloadGraph()
    }
    
    func saveStrategy() {
        self.dropdown.dataSource = self.settings.map { $0.rawValue }
        guard let symbol = OptionChain.symbol, OptionSpread.instance.optionLegs.count > 0 else { return }
        self.showStrategyCreationWindow { name in
            Settings.savedStrategies.append(OptionStrategy(strategyName: name,
                                                           symbol: symbol,
                                                           legs: OptionSpread.instance.optionLegs,
                                                           min: OptionSpread.instance.minMax?.0,
                                                           max:OptionSpread.instance.minMax?.1))
        }
    }
    
    @objc func showDropDown() {
        if selectionViewIsOpened {
            if let optionSelectionView = self.optionSelectionViewController.view as? OptionSelectionView {
                optionSelectionView.pressedClose()
            }
        } else {
            self.dropdown.show()
        }
    }
    
    @objc func showInfoWindow() {
        guard let info =  OptionSpread.instance.spreadInfo else { return }
        let infoWindow = InfoWindow(text: info, frame: CGRect(x: 0, y: Screen.height - graphViewHeight - 50, width: Screen.width, height: 50))
        self.view.addSubview(infoWindow)
        infoWindow.showInfoWindow()
    }
    
    func toggleFullScreen() {
        let defaultFrame = CGRect(x: 0, y: Screen.height - graphViewHeight, width: Screen.width, height: graphViewHeight)
        let fullScreenFrame = CGRect(x: 0, y: 80, width: Screen.width, height: Screen.height - 80)
        let isInDefaultLocation = self.graphViewController.view.frame == defaultFrame
        UIView.animate(withDuration: 0.5, animations: {
            self.graphViewController.view.frame = isInDefaultLocation ? fullScreenFrame : defaultFrame
            self.moveTitleLabel(up: isInDefaultLocation)
        })
    }
    
    func reloadGraph() {
        graph.reloadGraph()
    }
    
    @objc private func touchedView() {
        self.formView.endEditing(true)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return graph.subview
    }
}

