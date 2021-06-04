//
//  Day.swift
//  DataManager
//
//  Created by manager on 2019/01/30.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

public struct Day: Hashable, Strideable, Codable {
    public var year: Int
    public var month: Int
    public var day: Int
    
    public init() {
        let date = Date()
        self.year = date.yearNumber
        self.month = date.monthNumber
        self.day = date.dayNumber
    }
    
    public init(year: Int, month: Int, day: Int) {
        self.init(year, month, day)
    }

    public init(month: Int, day: Int) {
        self.init(month, day)
    }

    public init(_ month: Int, _ day: Int) {
        let date = Date()
        let year = date.yearNumber
        self.init(year, month, day)
    }

    public init(_ year: Int, _ month: Int, _ day: Int) {
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
    public init?<S: StringProtocol>(yyyymmdd: S) {
        let numbers = yyyymmdd.toHalfCharacters
        guard numbers.count == 8,
              let year = Int(numbers.prefix(4)), year > 2000,
              let month = Int(numbers.dropFirst(4).prefix(2)), month >= 1 && month <= 12,
              let day = Int(numbers.dropFirst(6)), day >= 1 && day <= 31
        else { return nil }
        self.init(year, month, day)
    }
    
    // FileMakerの日付
    public init?<S: StringProtocol>(fmDate2: S?) {
        guard let fmDate = fmDate2 else { return nil }
        self.init(fmDate: fmDate)
    }

    /// 4桁の数字mmddまたは6桁の数字yymmddから初期化
    public init?<S: StringProtocol>(numbers: S?) {
        guard let numbers = numbers, let value = Int(numbers), value > 0 else { return nil }
        self.year = value <= 100_00 ? Day().year : 2000 + (value / 100_00)
        self.month = (value % 100_00) / 100
        self.day = value % 100
        guard year >= 2000 && year <= 2200 && month >= 1 && month <= 12 && day >= 1 && day <= 31 else { return nil }
    }

    public init?<S: StringProtocol>(fmDate: S) {
        if fmDate.isEmpty { return nil }
        let digs = fmDate.split(separator: "/")
        switch digs.count {
        case 2:
            guard let month = Int(digs[0]), let day = Int(digs[1]) else { return nil }
            self.year = Day().year
            self.month = month
            self.day = day
        case 3:
            guard let year = Int(digs[0]), let month = Int(digs[1]), let day = Int(digs[2]) else { return nil }
            self.year = year
            self.month = month
            self.day = day
        default:
            return nil
        }
    }
    // MARK: - <Codable>
    enum CodingKeys: String, CodingKey {
        case year = "Year"
        case month = "Month"
        case day = "Day"
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.year = try values.decode(Int.self, forKey: .year)
        self.month = try values.decodeIfPresent(Int.self, forKey: .month) ?? 1
        self.day = try values.decodeIfPresent(Int.self, forKey: .day) ?? 1
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.year, forKey: .year)
        if self.month != 1 { try container.encode(self.month, forKey: .month) }
        if self.day != 1 { try container.encode(self.day, forKey: .day) }
    }

    // MARK: -
    public var isToday: Bool {
        return Day() == self
    }

    public static func <(left: Day, right: Day) -> Bool {
        if left.year != right.year { return left.year < right.year }
        if left.month != right.month { return left.month < right.month }
        return left.day < right.day
    }
    
    public var week: 週型 {
        return weekCache[self]
    }
    
    public var weekDays: ClosedRange<Day> {
        var from = self
        while from.week != .日 { from = from.prevDay }
        let to = from.nextDay.nextDay.nextDay.nextDay.nextDay.nextDay
        return from...to
    }
    
    // MARK: - 文字列表現
    public var fmString: String {
        return "\(make2dig(month))/\(make2dig(day))/\(make4dig(year))"
    }
    
    public var fmImportString: String {
        return "\(make4dig(year))/\(make2dig(month))/\(make2dig(day))"
    }
    
    public var yearMonthString: String {
        return "\(year)/\(make2dig(month))"
    }

    public var monthDayString: String {
        return "\(make2dig(month))/\(make2dig(day))"
    }

    public var monthDayJString: String {
        return "\(make2digS(month))月\(make2digS(day))日"
    }

    public var monthDayWeekJString: String {
        return "\(make2digS(month))月\(make2digS(day))日(\(self.week))"
    }

    public var yearMonthDayJString: String {
        return "\(year)年\(make2digS(month))月\(make2digS(day))日"
    }

    public var yearMonthDayString: String {
        return "\(year)/\(make2dig(month))/\(make2dig(day))"
    }

    public var yearMonthDayNumberString: String {
        return "\(year)\(make2dig(month))\(make2dig(day))"
    }

    public var shortYearMonthDayString: String {
        if Day().year == self.year {
            return monthDayString
        } else {
            return fmImportString
        }
    }

    public var yearString: String { make4dig(year) }
    public var monthString: String { make2dig(month) }
    public var dayString: String { make2dig(day) }

    public var monthDayWeekString: String {
        return "\(self.month)/\(self.day)(\(self.week))"
    }
    
    public var description: String {
        return "\(make4dig(year))/\(make2dig(month))/\(make2dig(day))"
    }
    
    // MARK: - 変更
    public var nextDay: Day {
        if self.day < 28 {
            return Day(year: self.year, month: self.month, day: self.day+1)
        }
        let date = Date(self)
        return date.nextDay.day
    }
    
    public var prevDay: Day {
        if self.day > 1 {
            return Day(year: self.year, month: self.month, day: self.day-1)
        }
        let date = Date(self)
        return date.prevDay.day
    }

    public var prevWorkDay: Day {
        var day = self.prevDay
        while day.isHoliday { day = day.prevDay }
        return day
    }

    public var nextWorkDay: Day {
        var day = self.nextDay
        while day.isHoliday { day = day.nextDay }
        return day
    }
    
    public func appendWorkDays(_ days: Int) -> Day {
        if days == 0 { return self }
        var day: Day = self
        if days < 0 {
            for _ in 1...(-days) {
                day = day.prevWorkDay
            }
        } else {
            for _ in 1...days {
                day = day.nextWorkDay
            }
        }
        return day
    }
    
    public mutating func normalize() {
        self = Date(self).day
    }
    
    // MARK: - <Strideable>
    public func distance(to other: Day) -> Int {
        if self > other { return -other.distance(to: self) }
        var count = 0
        var day = self
        while day < other {
            count += 1
            day = day.nextDay
        }
        return count
    }

    // MARK: - <Strideable>
    public func workDays(to other: Day) -> Int {
        if self > other { return -other.workDays(to: self) }
        var count = self.isWorkday ? 1 : 0
        var day = self
        while day < other {
            day = day.nextDay
            if day.isWorkday { count += 1 }
        }
        return count
    }

    public func advanced(by n: Int) -> Day {
        if n == 1 { return self.nextDay }
        if n == -1 { return self.prevDay }
        let cal = Calendar(identifier: .gregorian)
        let date = cal.date(byAdding: .day, value: n, to: Date(self))
        return date!.day
    }
}

// MARK: -
class WeekCache {
    subscript(day: Day) -> 週型 {
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
    private var cache: [Day:週型] = [:]
    private let lock = NSLock()
}
private let weekCache = WeekCache()

extension Date {
    /// 日付
    public var day: Day {
        let comp = cal.dateComponents([.year, .month, .day], from: self)
        return Day(year: comp.year!, month: comp.month!, day: comp.day!)
    }
    
    public init(_ day: Day) {
        var comp = DateComponents()
        comp.year = day.year
        comp.month = day.month
        comp.day = day.day
        let date = cal.date(from: comp)!
        self = date
    }
    
    public init(_ day: Day, _ time: Time) {
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

public extension ClosedRange where Bound == Day {
    init?<S: StringProtocol>(_ string: S) {
        let string = string.toJapaneseNormal
        let digs = string.split(separator: "-")
        switch digs.count {
        case 1: // day...day
            guard let day = Day(fmDate: digs[0]) else { return nil }
            self = day...day
        case 2: // from-to
            guard let from = Day(fmDate: digs[0]) else { return nil }
            let digs2 = digs[1].split(separator: "/")
            switch digs2.count {
            case 1:
                guard let day = Int(digs2[0]) else { return nil }
                var to = from
                if day < from.day {
                    to.month += 1
                }
                to.day = day
                to.normalize()
                self = from...to
            case 2:
                guard let month = Int(digs2[0]), let day = Int(digs2[1]) else { return nil }
                var to = Day(from.year, month, day)
                if to < from {
                    to.year += 1
                }
                self = from...to
            case 3:
                guard let year = Int(digs2[0]), let month = Int(digs2[1]), let day = Int(digs2[2]) else { return nil }
                let to = Day(year, month, day)
                if from > to { return nil }
                self = from...to
            default:
                return nil
            }
        default:
            return nil
        }
    }
    
    var prevWeekDays: ClosedRange<Day> {
        let week = self.lowerBound.weekDays
        let to = week.lowerBound.prevDay
        let from = to.prevDay.prevDay.prevDay.prevDay.prevDay.prevDay
        return from...to
    }
    
    var nextWeekDays: ClosedRange<Day> {
        let week = self.lowerBound.weekDays
        let from = week.upperBound.nextDay
        let to = from.nextDay.nextDay.nextDay.nextDay.nextDay.nextDay
        return from...to
    }
}
