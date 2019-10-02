//
//  Month.swift
//  DataManager
//
//  Created by manager on 8/17/1 R.
//  Copyright © 1 Reiwa 四熊泰之. All rights reserved.
//

import Foundation

public struct Month {
    public let year : Int
    public let month : Int
    public var shortYear : Int {
        return year % 100
    }
    
    public init() {
        let date = Date()
        self.year = date.yearNumber
        self.month = date.monthNumber
    }

    public init(year:Int, month:Int) {
        self.init(year, month)
    }
    init(_ year:Int, _ month:Int) {
        self.year = year
        self.month = month
    }

    public var prevMonth : Month {
        var year = self.year
        var month = self.month-1
        if month < 1 {
            month = 12
            year -= 1
        }
        return Month(year: year, month: month)
    }
    
    public var shortYearMonthString : String {
        var yearString = "\(shortYear)"
        var monthString = "\(month)"
        if yearString.count == 1 { yearString = "0" + yearString }
        if monthString.count == 1 { monthString = "0" + monthString }
        return yearString + monthString
    }
}
