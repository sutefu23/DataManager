//
//  Month.swift
//  DataManager
//
//  Created by manager on 8/17/1 R.
//  Copyright © 1 Reiwa 四熊泰之. All rights reserved.
//

import Foundation

public struct Month: Hashable, Strideable, Codable {
    public var year: Int
    public var month: Int
    public var shortYear: Int {
        return year % 100
    }
    
    public init() {
        let date = Date()
        self.year = date.yearNumber
        self.month = date.monthNumber
    }

    public init(year: Int, month: Int) {
        self.init(year, month)
    }
    
    public init?<S: StringProtocol>(fmDate: S) {
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
    
    init(_ year: Int, _ month: Int) {
        self.year = year
        self.month = month
    }
    // MARK: - <Codable>
    enum CodingKeys: String, CodingKey {
        case year = "Year"
        case month = "Month"
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.year = try values.decode(Int.self, forKey: .year)
        self.month = try values.decodeIfPresent(Int.self, forKey: .month) ?? 1
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.year, forKey: .year)
        if self.month != 1 { try container.encode(self.month, forKey: .month) }
    }

    // MARK: -
    public var prevMonth: Month {
        var year = self.year
        var month = self.month-1
        if month < 1 {
            month = 12
            year -= 1
        }
        return Month(year: year, month: month)
    }
    
    public var nextMonth: Month {
        var year = self.year
        var month = self.month+1
        if month > 12 {
            month = 1
            year += 1
        }
        return Month(year, month)
    }
    
    public var shortYearMonthString: String {
        var yearString = "\(shortYear)"
        var monthString = "\(month)"
        if yearString.count == 1 { yearString = "0" + yearString }
        if monthString.count == 1 { monthString = "0" + monthString }
        return yearString + monthString
    }

    public var monthOrYearMonthString: String {
        var monthString = "\(month)"
        if Date().yearNumber == self.year {
            return monthString
        } else {
            if monthString.count == 1 { monthString = "0" + monthString }
            return "\(year)/\(monthString)"
        }
    }

    public var yearMonthJString: String {
        return "\(year)年\(month)月"
    }
    
    public var firstDay: Day {
        return Day(self.year, self.month, 1)
    }
    
    public var lastDay: Day {
        return self.nextMonth.firstDay.prevDay
    }
    public var days: ClosedRange<Day> {
        firstDay...lastDay
    }
    
    public var weeks: [ClosedRange<Day>] {
        var weeks: [ClosedRange<Day>] = []
        var current = Day(year: self.year, month: self.month, day: 1)
        while current.week != .日 { current = current.prevDay }
        repeat {
            let lastDay = current.nextDay.nextDay.nextDay.nextDay.nextDay.nextDay
            weeks.append(current...lastDay)
            current = lastDay.nextDay            
        } while current.month == self.month
        return weeks
    }
    
    public var workWeeks: [ClosedRange<Day>] {
        return self.weeks.compactMap {
            var firstDay: Day?
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
    
    public static func <(left: Month, right: Month) -> Bool {
        if left.year != right.year { return left.year < right.year }
        return left.month < right.month
    }
    
    // MARK: - <Strideable>
    public func distance(to other: Month) -> Int {
        if self > other { return -other.distance(to: self) }
        var count = 0
        var month = self
        while month < other {
            count += 1
            month = month.nextMonth
        }
        return count
    }
    
    public func advanced(by n: Int) -> Month {
        if n == 1 { return self.nextMonth }
        if n == -1 { return self.prevMonth }
        let cal = Calendar(identifier: .gregorian)
        let date = cal.date(byAdding: .month, value: n, to: Date(self))
        return date!.month
    }

}

// MARK: -
/// 特定月範囲の週を取り出す
public extension ClosedRange where Bound == Month {
    var workWeeks: [ClosedRange<Day>] {
        var set = Set<ClosedRange<Day>>()
        var month = self.lowerBound
        let to = self.upperBound
        while month <= to {
            for week in month.workWeeks { set.insert(week) }
            month = month.nextMonth
        }
        return set.sorted { $0.lowerBound < $1.lowerBound }
    }
}

extension Date {
    public var month: Month {
        let comp = cal.dateComponents([.year, .month], from: self)
        return Month(year: comp.year!, month: comp.month!)
    }

    public init(_ month: Month) {
        var comp = DateComponents()
        comp.year = month.year
        comp.month = month.month
        comp.day = 1
        let date = cal.date(from: comp)!
        self = date
    }

}
