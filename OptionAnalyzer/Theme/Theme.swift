//
//  Theme.swift
//  OptionAnalyzer
//
//  Created by Brandon Baker on 1/24/20.
//  Copyright © 2020 Brandon Baker. All rights reserved.
//

import UIKit
import MaterialComponents.MaterialDialogs
import Material
import StoreKit
import Mixpanel

extension UIColor {
    
    static let background = UIColor(red: 66/255, green: 66/255, blue: 80/255, alpha: 1)
    static let foreground = UIColor(red: 51/255, green: 51/255, blue: 60/255, alpha: 1)
    static let primaryForeground = UIColor(red:0.22, green:0.22, blue:0.25, alpha:1.00)
    static let primary = UIColor(red:1.00, green:1.00, blue:1.00, alpha:1.00)
    static let secondary = UIColor(red:0.00, green:0.36, blue:0.34, alpha:1.00)
    static let thirdly = UIColor(red:0.12, green:0.73, blue:0.50, alpha:1.00)
    static let forthly = UIColor(red:0.00, green:0.49, blue:0.32, alpha:1.00)
    static let whiteText = UIColor(red:1.00, green:1.00, blue:1.00, alpha:1.00)
    static let grayText = UIColor(red:0.37, green:0.37, blue:0.40, alpha:1.00)
}

extension UIFont {
    static let avinerMedium = UIFont(name: "Avenir-Medium", size: 22)!
}
extension Double {
    public func isBetween(lower: Double, upper: Double) -> Bool {
      return lower <= self && self <= upper
    }
    public func getString(_ decimals: Int = 2) -> String {
        return String(format: "%.\(decimals)f", self)
    }
}

extension Date {
    static var yesterday: Date { return Date().dayBefore }
    static var tomorrow:  Date { return Date().dayAfter }
    static var today : Date { return Date().noon }
    var dayBefore: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: noon)!
    }
    var dayAfter: Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: noon)!
    }
    var noon: Date {
        return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: self)!
    }
    var month: Int {
        return Calendar.current.component(.month,  from: self)
    }
    var isLastDayOfMonth: Bool {
        return dayAfter.month != month
    }
}

extension UIViewController {
    
    func showAlert(title: String, message: String, buttonTitle: String = "OK", completion: (() -> Void)?) {
        let alertController = MDCAlertController(title: title, message: message)
        let action = MDCAlertAction(title:buttonTitle) { _ in
            completion?()
        }
        alertController.addAction(action)
        self.present(alertController, animated:true, completion: nil)
    }
    
    func showStrategyCreationWindow(completion: ((String?) -> Void)?) {
        let message = "Save this strategy to review later.\n\n\n\n\n"
        let alertController = MDCAlertController(title: "Save Strategy", message: message)
        let field = TextField()
        
        let action = MDCAlertAction(title:"Save") { _ in
            completion?(field.text)
        }
        alertController.addAction(action)
        
        let cancel = MDCAlertAction(title:"Cancel")
        alertController.addAction(cancel)
        
        if let scrollView = alertController.view.subviews.first(where: { $0 is UIScrollView }), let messageLabel = scrollView.subviews.first(where: {
            if let label = $0 as? UILabel, label.text == message {
                return true
            }
            return false
        }) {
            field.tintColor = .foreground
            field.dividerActiveColor = .foreground
            field.placeholderActiveColor = .foreground
            field.placeholder = "Strategy Name"
            alertController.view.addSubview(field)
            field.snp.makeConstraints { make in
                make.top.equalTo(messageLabel.snp.top).offset(40)
                make.width.equalToSuperview().offset(-48)
                make.height.equalTo(40)
                make.centerX.equalToSuperview()
            }
        }
        
        
        
        self.present(alertController, animated:true, completion: nil)
    }
    
    func showPurchaseViewController(completion: (() -> Void)?) {
        
        Helpers.trackEvent("Purchase Alert Shown")
        
        let alertController = MDCAlertController(title: "Purchase Premium", message: "As a free user, you're limited to analyzing one option leg at a time. Please consider purchasing premium for $1.99.\n\n" +
            "- Analyze up to 10 option legs at a time\n" +
            "- Save option spread strategies\n" +
        "- Support this app's further development and ongoing data costs")
        
        let cancel = MDCAlertAction(title:"Cancel") { _ in
            // cancel
        }
        alertController.addAction(cancel)
        
        let restore = MDCAlertAction(title:"Restore") { _ in
            Products.store.restorePurchases()
        }
        alertController.addAction(restore)
        
        let purchase = MDCAlertAction(title:"Purchase ($1.99)") { _ in
            Products.store.requestProducts(completionHandler: { success,products in
                if success, let product = products?.first {
                    print(product.productIdentifier)
                    Products.store.buyProduct(product)
                }
            })
        }
        alertController.addAction(purchase)
        
        self.present(alertController, animated:true, completion: nil)
    }
}

class Helpers {
    static func addGuidelines(_ view: UIView) {
        _ = view.subviews.map {
            _ = $0.subviews.map {
                _ = $0.subviews.map {
                    _ = $0.subviews.map {
                        $0.layer.borderColor = UIColor.white.cgColor
                        $0.layer.borderWidth = 1
                    }
                    $0.layer.borderColor = UIColor.white.cgColor
                    $0.layer.borderWidth = 1
                }
                $0.layer.borderColor = UIColor.white.cgColor
                $0.layer.borderWidth = 1
            }
            $0.layer.borderColor = UIColor.white.cgColor
            $0.layer.borderWidth = 1
        }
    }
    
    static func trackEvent(_ event: String, properties: [String:String]? = nil) {
        print(event, properties ?? "")
        Mixpanel.mainInstance().track(event: event,
                                      properties: properties)
    }
}

