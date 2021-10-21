//
//  Month.swift
//  DataManager
//
//  Created by manager on 8/17/1 R.
//  Copyright © 1 Reiwa 四熊泰之. All rights reserved.
//

import Foundation

public struct Month: DMCacheElement, Hashable, Strideable, Codable, Comparable {
    public typealias YearType = Day.YearType
    public typealias MonthType = Day.MonthType

    public var longYear: YearType
    public var month: MonthType
    public var shortYear: YearType { longYear % 100 }
    
    public init() {
        let date = Date()
        self.longYear = YearType(date.yearNumber)
        self.month = MonthType(date.monthNumber)
    }

    public init(year: Int, month: Int) {
        var year = year < 1000 ? year + 2000 : year
        var month = month
        if month < 1 {
            let d = month / 12
            year = year + (d - 1)
            month = month - (d-1)*12
        } else if month > 12 {
            let d = month / 12
            year = year + d
            month = month - d*12
        }
        self.init(YearType(year), MonthType(month))
    }

    public init(_ day: Day) {
        self.init(day.year, day.month)
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
        guard let year = YearType(digs[0]), let month = MonthType(digs[1]) else { return nil }
        self.longYear = year
        self.month = month
    }
    
    public init(_ year: YearType, _ month: Month.MonthType) {
        self.longYear = year
        self.month = month
    }
    // MARK: - <Codable>
    enum CodingKeys: String, CodingKey {
        case year = "Year"
        case month = "Month"
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.longYear = try values.decode(YearType.self, forKey: .year)
        self.month = try values.decodeIfPresent(MonthType.self, forKey: .month) ?? 1
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.longYear, forKey: .year)
        if self.month != 1 { try container.encode(self.month, forKey: .month) }
    }

    // MARK: -
    public var prevMonth: Month {
        if self.month > 1 {
            return Month(self.longYear, self.month-1)
        } else {
            return Month(self.longYear-1, 12)
        }
    }
    
    public var nextMonth: Month {
        if self.month < 12 {
            return Month(self.longYear, self.month+1)
        } else {
            return Month(self.longYear+1, 1)
        }
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
        if Date().yearNumber == self.longYear {
            return monthString
        } else {
            if monthString.count == 1 { monthString = "0" + monthString }
            return "\(longYear)/\(monthString)"
        }
    }

    public var yearMonthJString: String { "\(longYear)年\(month)月" }
    /// ４桁年文字列
    public var longYearString: String { String(longYear) }
    /// 2桁固定の年文字列
    public var shortYear2String: String {
        shortYear < 10 ? "0\(shortYear)" : String(shortYear)
    }

    /// 2桁固定の月番号文字列
    public var month2String: String {
        month < 10 ? "0\(month)" : String(month)
    }
    
    public var firstDay: Day {
        return Day(self.longYear, self.month, 1)
    }
    
    public var lastDay: Day {
        return self.nextMonth.firstDay.prevDay
    }
    public var days: ClosedRange<Day> {
        firstDay...lastDay
    }
    
    public var weeks: [ClosedRange<Day>] {
        var weeks: [ClosedRange<Day>] = []
        var current = Day(year: self.longYear, month: self.month, day: 1)
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
    
    public var workDays: [Day] {
        self.days.filter { $0.isWorkday }
    }

    public static func <(left: Month, right: Month) -> Bool {
        if left.longYear != right.longYear { return left.longYear < right.longYear }
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
        return Month(Month.YearType(comp.year!), Month.MonthType(comp.month!))
    }

    public init(_ month: Month) {
        var comp = DateComponents()
        comp.year = Int(month.longYear)
        comp.month = Int(month.month)
        comp.day = 1
        let date = cal.date(from: comp)!
        self = date
    }
}
