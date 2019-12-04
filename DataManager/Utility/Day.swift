//
//  Day.swift
//  DataManager
//
//  Created by manager on 2019/01/30.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

public struct Day : Hashable, Comparable {
    public let year : Int
    public let month : Int
    public let day : Int
    
    public init() {
        let date = Date()
        self.year = date.yearNumber
        self.month = date.monthNumber
        self.day = date.dayNumber
    }
    
    public init(year:Int, month:Int, day:Int) {
        self.init(year, month, day)
    }
    public init(_ year:Int, _ month:Int, _ day:Int) {
        self.year = year
        self.month = month
        self.day = day
    }
    
    init?(fmJSONDay: String) {
        let parts = fmJSONDay.split(separator: "/")
        guard parts.count == 3 else { return nil }
        guard let day0 = Int(parts[0]) else { return nil }
        guard let day1 = Int(parts[1]) else { return nil }
        guard let day2 = Int(parts[2]) else { return nil }
        
        if day0 > day2 {
            self.year = day0
            self.month = day1
            self.day = day2
        } else {
            self.year = day2
            self.month = day0
            self.day = day1
        }
        
    }
    
    // FileMakerの日付
    public init?<S : StringProtocol>(fmDate: S) {
        if fmDate.isEmpty { return nil }
        let digs = fmDate.split(separator: "/")
        if digs.count != 3 {
            let now = Date().day.year
            if let date = Day(fmDate: "\(now)/\(fmDate)") {
                self = date
                return
            } else {
                return nil
            }
        }
        guard let year = Int(digs[0]), let month = Int(digs[1]), let day = Int(digs[2]) else { return nil }
        self.year = year
        self.month = month
        self.day = day
    }


    public static func <(left:Day, right:Day) -> Bool {
        if left.year != right.year { return left.year < right.year }
        if left.month != right.month { return left.month < right.month }
        return left.day < right.day
    }
    
    public var week : 週型 {
        return weekCache[self]
    }
    
    public var fmString : String {
        return "\(make2dig(month))/\(make2dig(day))/\(make4dig(year))"
    }
    
    public var fmImportString : String {
        return "\(make4dig(year))/\(make2dig(month))/\(make2dig(day))"
    }
    
    public var yearMonthString : String {
        return "\(year)/\(make2dig(month))"
    }

    public var monthDayString : String {
        return "\(make2dig(month))/\(make2dig(day))"
    }

    public var monthDayJString : String {
        return "\(make2dig(month))月\(make2dig(day))日"
    }

    var description : String {
        return "\(make4dig(year))/\(make2dig(month))/\(make2dig(day))"
    }
    
    public var nextDay : Day {
        if self.day < 28 {
            return Day(year: self.year, month: self.month, day: self.day+1)
        }
        let date = Date(self)
        return date.nextDay.day
    }
    
    public var prevDay : Day {
        if self.day > 1 {
            return Day(year: self.year, month: self.month, day: self.day-1)
        }
        let date = Date(self)
        return date.prevDay.day
    }
    
    public var monthDayWeekString : String {
        return "\(self.month)/\(self.day)(\(self.week))"
    }
}

class WeekCache {
    subscript(day:Day) -> 週型 {
        lock.lock()
        defer { lock.unlock() }
        if let week = cache[day] {
            return week
        } else {
            let week = Date(day).week
            cache[day] = week
            return week
        }
    }
    private var cache : [Day:週型] = [:]
    private let lock = NSLock()
}
private let weekCache = WeekCache()

extension Date {
    /// 日付
    public var day : Day {
        let comp = cal.dateComponents([.year, .month, .day], from: self)
        return Day(year: comp.year!, month: comp.month!, day: comp.day!)
    }
    
    public init(_ day:Day) {
        var comp = DateComponents()
        comp.year = day.year
        comp.month = day.month
        comp.day = day.day
        let date = cal.date(from: comp)!
        self = date
    }
    
    public init(_ day:Day, _ time:Time) {
        var comp = DateComponents()
        comp.year = day.year
        comp.month = day.month
        comp.day = day.day
        comp.hour = time.hour
        comp.minute = time.minute
        comp.second = time.second
        let date = cal.date(from: comp)!
        self = date
    }
}
