//
//  Graph.swift
//  OptionAnalyzer
//
//  Created by Brandon Baker on 4/4/20.
//  Copyright © 2020 Brandon Baker. All rights reserved.
//

import UIKit
import Material

struct Month {
    var name : String
    var startIndex: Int
    var endIndex: Int
}

class Graph: UIScrollView {
    
    private var size : CGFloat = 35
    let subview = UIView()
    
    static var text = "Type a symbol above and\npress + to add an option"
    
    lazy var emptyLabel : UILabel = {
        let label  = UILabel(frame: CGRect(x: 50, y: 130, width: Screen.width - 100, height: 50))
        label.font = .avinerMedium
        label.adjustsFontSizeToFitWidth = true
        label.numberOfLines = 2
        label.text = Graph.text
        label.textAlignment = .center
        label.textColor = .whiteText
        return label
    }()
    
    func reloadGraph() {
        subview.subviews.forEach {
            if !($0 is UIButton || $0 == emptyLabel) {
                $0.removeFromSuperview()
            }
        }
        let data = OptionSpread.instance.spreadData
        let expirations = OptionSpread.instance.expirations
        
        emptyLabel.text = Graph.text
        emptyLabel.isHidden = !(data.isEmpty || expirations.isEmpty)
        
        var months : [Month] = []
        let sortedData = data.sorted(by: { $0.0 > $1.0 })
        let contentHeight : CGFloat = CGFloat(strikeLimit) + 3
        let contentWidth : CGFloat = CGFloat(expirations.count)
        
        for (i, expiration) in expirations.enumerated() {
            let month = getMonthFromDate(date: expiration.date)
            let day = getDayFromDate(date: expiration.date)
            if !months.map({ $0.name }).contains(month) {
                let month = Month(name: month, startIndex: i, endIndex: i)
                months.append(month)
            } else {
                if let index = months.firstIndex(where: { $0.name == month }),
                    let month = months.first(where: { $0.name == month }){
                    months[index] = Month(name: month.name, startIndex: month.startIndex, endIndex: i)
                }
            }
            let cell = GraphCell(column: i, text: day)
            subview.addSubview(cell)
        }
        
        for month in months {
            let cell = GraphCell(month: month)
            subview.addSubview(cell)
        }
        
        // Data cells
        for (strikeIndex, column) in sortedData.enumerated() {
            for (day, gv) in column.value.enumerated() {
                // Data cell
                gv.setColor()
                let cell = GraphCell(gv: gv, x:CGFloat(day), y: CGFloat(strikeIndex))
                subview.addSubview(cell)
            }
        }
        
        // Y axis (strikePrices)
        for (y, strikePrice) in sortedData.enumerated() {
            
            let double = strikePrice.key
            let digitsAfterDecimal = double.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2
            let string = "$\(double.getString(digitsAfterDecimal))"
            let closestCell : Bool = OptionSpread.instance.closestStrike == double
            
            let cell = GraphCell(row: y, text: string, closestCell: closestCell)
            subview.addSubview(cell)
            
            let endCell = GraphCell(row: y, text: string, closestCell: closestCell, x: CGFloat(expirations.count + 2))
            subview.addSubview(endCell)
        }
        
        let contentSize = CGSize(width: (contentWidth + 4) * size, height: contentHeight * size)
        var subviewFrame = CGRect(x: 0, y: 0, width: contentSize.width, height: contentSize.height)
        if contentSize.width < Screen.width {
            if (data.isEmpty || expirations.isEmpty) {
                subviewFrame = CGRect(x: 0, y: 0, width: Screen.width, height: contentSize.height)
            } else {
                subviewFrame = CGRect(x: ((Screen.width - contentSize.width) / 2), y: 0, width: contentSize.width, height: contentSize.height)
            }
        }
        subview.frame = subviewFrame
        self.contentSize = contentSize
    }
    
    func getMonthFromDate(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "LLLL"
        let nameOfMonth = dateFormatter.string(from: date)
        return nameOfMonth
    }
    
    func getDayFromDate(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd"
        let nameOfMonth = dateFormatter.string(from: date)
        return nameOfMonth
    }
    
    init() {
        super.init(frame: .zero)
        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false
        self.minimumZoomScale = 0.3
        self.maximumZoomScale = 2.0
        subview.addSubview(emptyLabel)
        self.addSubview(subview)
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
