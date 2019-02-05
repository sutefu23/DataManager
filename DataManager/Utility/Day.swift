//
//  Day.swift
//  DataManager
//
//  Created by manager on 2019/01/30.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

struct Day : Hashable, Comparable {
    let year : Int
    let month : Int
    let day : Int
    
    init(year:Int, month:Int, day:Int) {
        self.init(year, month, day)
    }
    init(_ year:Int, _ month:Int, _ day:Int) {
        self.year = year
        self.month = month
        self.day = day
    }
    
    init?(fmJSONDay: String) {
        var parts = fmJSONDay.split(separator: "/")
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

    static func <(left:Day, right:Day) -> Bool {
        if left.year != right.year { return left.year < right.year }
        if left.month != right.month { return left.month < right.month }
        return left.day < right.day
    }
    
    public var week : 週型 {
        return weekCache[self]
    }
    
    var fmString : String {
        return "\(make2dig(month))/\(make2dig(day))/\(make4dig(year))"
    }
}

class WeekCache {
    subscript(day:Day) -> 週型 {
        sem.wait()
        defer { sem.signal() }
        if let week = cache[day] {
            return week
        } else {
            sem.signal()
            let week = Date(day).week
            sem.wait()
            cache[day] = week
            sem.signal()
            return week
        }
    }
    private var cache : [Day:週型] = [:]
    private let sem : DispatchSemaphore = DispatchSemaphore(value: 1)
}
private let weekCache = WeekCache()

extension Date {
    /// 日付
    var day : Day {
        let comp = cal.dateComponents([.year, .month, .day], from: self)
        return Day(year: comp.year!, month: comp.month!, day: comp.day!)
    }
    
    init(_ day:Day) {
        var comp = DateComponents()
        comp.year = day.year
        comp.month = day.month
        comp.day = day.day
        let date = cal.date(from: comp)!
        self = date
    }
    
    init(_ day:Day, _ time:Time) {
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
