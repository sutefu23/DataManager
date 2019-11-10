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
    
    public init?<S : StringProtocol>(fmDate: S) {
        if fmDate.isEmpty { return nil }
        let digs = fmDate.split(separator: "/")
        if digs.count != 2 {
            let now = Date().day.year
            if let month = Month(fmDate: "\(now)/\(fmDate)") {
                self = month
                return
            } else {
                return nil
            }
        }
        guard let year = Int(digs[0]), let month = Int(digs[1]) else { return nil }
        self.year = year
        self.month = month
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
    
    public var nextMonth : Month {
        var year = self.year
        var month = self.month+1
        if month > 12 {
            month = 1
            year += 1
        }
        return Month(year, month)
    }
    
    public var shortYearMonthString : String {
        var yearString = "\(shortYear)"
        var monthString = "\(month)"
        if yearString.count == 1 { yearString = "0" + yearString }
        if monthString.count == 1 { monthString = "0" + monthString }
        return yearString + monthString
    }
    
    public var yearMonthJString : String {
        return "\(year)年\(month)月"
    }
    
    public var firstDay : Day {
        return Day(self.year, self.month, 1)
    }
    
    public var lastDay : Day {
        return self.nextMonth.firstDay.prevDay
    }
    
    public var weeks : [ClosedRange<Day>] {
        var weeks : [ClosedRange<Day>] = []
        var current = Day(year: self.year, month: self.month, day: 1)
        while current.week != .日 { current = current.prevDay }
        repeat {
            let lastDay = current.nextDay.nextDay.nextDay.nextDay.nextDay.nextDay
            weeks.append(current...lastDay)
            current = lastDay.nextDay            
        } while current.month == self.month
        return weeks
    }
    
    public var workWeeks : [ClosedRange<Day>] {
        return self.weeks.compactMap {
            var firstDay : Day?
            var lastDay: Day?
            var day = $0.lowerBound
            while $0.contains(day) {
                if day.isWorkday {
                    if firstDay == nil { firstDay = day }
                    lastDay = day
                }
                day = day.nextDay
            }
            if let firstDay = firstDay, let lastDay = lastDay {
                return firstDay...lastDay
            } else {
                return nil
            }
        }
    }
}
