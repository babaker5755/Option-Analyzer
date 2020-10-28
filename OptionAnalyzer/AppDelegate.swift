//
//  AppDelegate.swift
//  OptionAnalyzer
//
//  Created by Brandon Baker on 1/24/20.
//  Copyright © 2020 Brandon Baker. All rights reserved.
//

import UIKit
import StoreKit
import SwiftKeychainWrapper
import Mixpanel
import Firebase
import FirebaseFirestore

let db = Firestore.firestore()

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        SKPaymentQueue.default().add(self)
        
        Mixpanel.initialize(token: "47f8f0775baa71ea31e7a545354b2667")
        
        Mixpanel.mainInstance().identify(distinctId: LocalStorage.userId)
        
        FirebaseApp.configure()
        
        AppDelegate.fetchKeyFromDatabase()
        
        return true
    }
    
    static func fetchKeyFromDatabase() {
        
        db.collection("keys").document("api1").getDocument { (document, error) in
            if let document = document, document.exists {
                if let apiKey = document.data()?["key"] as? String {
                    LocalStorage.key = apiKey
                }
            } else {
                Helpers.trackEvent("Unable to get api key")
            }
        }
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

extension AppDelegate : SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased, .restored:
                completeTransaction(transaction)
            case .failed:
                failedTransaction(transaction)
            default:
                print("unhandled transaction")
            }
        }
    }
    
    func completeTransaction(_ transaction: SKPaymentTransaction) {
        KeychainWrapper.standard.set(true, forKey: transaction.payment.productIdentifier)
        deliverPurchaseNotification(for: transaction.payment.productIdentifier)
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    func failedTransaction(_ transaction: SKPaymentTransaction) {
        if let transactionError = transaction.error as NSError?,
            let desc = transaction.error?.localizedDescription,
            transactionError.code != SKError.paymentCancelled.rawValue {
            print("transactionError: \(desc)")
        }
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    func deliverPurchaseNotification(for identifier: String?) {
        guard let identifier = identifier else { return }
        NotificationCenter.default.post(name: .purchaseNotification, object: identifier)
        Products.handlePurchase(purchaseIdentifier: identifier)
    }
}

extension Notification.Name {
    static let purchaseNotification = Notification.Name("PurchaseNotification")
}
