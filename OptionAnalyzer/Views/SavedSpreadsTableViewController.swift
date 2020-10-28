//
//  SavedSpreadsTableViewController.swift
//  OptionAnalyzer
//
//  Created by Brandon Baker on 4/18/20.
//  Copyright © 2020 Brandon Baker. All rights reserved.
//

import UIKit

class SavedSpreadsTableViewController: UITableViewController {
    
    var savedStrategies : [OptionStrategy] = []
    
    var completion : ((String) -> Void) = { _ in }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        savedStrategies = Settings.savedStrategies
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.dismiss(animated: true, completion: {
            let strategy = self.savedStrategies[indexPath.row]
            OptionSpread.instance.optionLegs = strategy.legs
            OptionSpread.instance.minMax = nil
            if let min = strategy.min, let max = strategy.max {
                OptionSpread.instance.minMax = (min, max)
            }
            self.completion(strategy.symbol)
        })
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return savedStrategies.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = savedStrategies[indexPath.row].strategyName ?? "Saved Spread"
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            Settings.savedStrategies.remove(at: indexPath.row)
            savedStrategies = Settings.savedStrategies
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
}
