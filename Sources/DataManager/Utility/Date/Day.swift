//
//  Day.swift
//  DataManager
//
//  Created by manager on 2019/01/30.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

public struct Day: Hashable, Strideable, Codable, Comparable {
    public typealias YearType = Int16
    public typealias MonthType = Int8
    public typealias DayType = Int8
    
    public var year: YearType // 西暦32767年まで対応。それ以降は考えない
    public var month: MonthType
    public var day: DayType
    
    public init() {
        let date = Date()
        self.year = YearType(date.yearNumber)
        self.month = MonthType(date.monthNumber)
        self.day = DayType(date.dayNumber)
    }

    public init(year: Int, month: Int, day: Int) {
        self.init(YearType(year), MonthType(month), DayType(day))
    }

    public init(year: YearType, month: MonthType, day: DayType) {
        self.init(year, month, day)
    }

    public init(month: Int, day: Int) {
        self.init(MonthType(month), DayType(day))
    }

    public init(month: MonthType, day: DayType) {
        self.init(month, day)
    }

    public init(_ month: MonthType, _ day: DayType) {
        let date = Date()
        let year = Int16(date.yearNumber)
        self.init(year, month, day)
    }

    public init(_ year: YearType, _ month: MonthType, _ day: DayType) {
        self.year = year
        self.month = month
        self.day = day
    }
    
    init?(fmJSONDay: String) {
        let parts = fmJSONDay.split(separator: "/")
        guard parts.count == 3 else { return nil }
        guard let day0 = YearType(parts[0]) else { return nil }
        guard let day1 = YearType(parts[1]) else { return nil }
        guard let day2 = YearType(parts[2]) else { return nil }
        
        if day0 > day2 {
            self.year = day0
            guard let month = MonthType(exactly: day1), let day = DayType(exactly: day2) else { return nil }
            self.month = month
            self.day = day
        } else {
            self.year = day2
            guard let month = MonthType(exactly: day0), let day = DayType(exactly: day1) else { return nil }
            self.month = month
            self.day = day
        }
    }
    public init?<S: StringProtocol>(yyyymmdd: S) {
        let numbers = yyyymmdd.toHalfCharacters
        guard numbers.count == 8,
              let year = YearType(numbers.prefix(4)), year > 2000,
              let month = MonthType(numbers.dropFirst(4).prefix(2)), month >= 1 && month <= 12,
              let day = DayType(numbers.dropFirst(6)), day >= 1 && day <= 31
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
        guard let numbers = numbers, let value = Int(numbers), value > 0 && value <= 10000_00_00 else { return nil }
        self.year = YearType(value <= 100_00 ? Date().yearNumber : 2000 + (value / 100_00))
        self.month = MonthType((value % 100_00) / 100)
        self.day = DayType(value % 100)
        guard year >= 2000 && year <= 2200 && month >= 1 && month <= 12 && day >= 1 && day <= 31 else { return nil }
    }

    public init?<S: StringProtocol>(fmDate: S) {
        if fmDate.isEmpty { return nil }
        let digs = fmDate.split(separator: "/")
        switch digs.count {
        case 2:
            guard let month = MonthType(digs[0]), let day = DayType(digs[1]) else { return nil }
            self.year = Day().year
            self.month = month
            self.day = day
        case 3:
            guard let year = YearType(digs[0]), let month = MonthType(digs[1]), let day = DayType(digs[2]) else { return nil }
            self.year = year
            self.month = month
            self.day = day
        default:
            return nil
        }
    }
    // MARK: - <Hashable>
    public static func ==(left: Day, right: Day) -> Bool {
        return left.day == right.day && left.month == right.month && left.year == right.year
    }
    
    // MARK: - <Codable>
    enum CodingKeys: String, CodingKey {
        case year = "Year"
        case month = "Month"
        case day = "Day"
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.year = try values.decode(YearType.self, forKey: .year)
        self.month = try values.decodeIfPresent(MonthType.self, forKey: .month) ?? 1
        self.day = try values.decodeIfPresent(DayType.self, forKey: .day) ?? 1
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
        return "\(monthString)/\(dayString)/\(yearString)"
    }
    
    public var fmImportString: String {
        return "\(yearString)/\(monthString)/\(dayString)"
    }
    
    public var yearMonthString: String {
        return "\(year)/\(monthString)"
    }

    public var monthDayString: String {
        return "\(monthString)/\(dayString)"
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
        return "\(year)/\(monthString)/\(dayString)"
    }

    public var yearMonthDayNumberString: String {
        return "\(year)\(monthString)\(dayString)"
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
        return "\(yearString)/\(monthString)/\(dayString)"
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
    
    func prev(month: Int) -> Day {
        var year = self.year
        var month = Int(self.month)-month
        if month == 0 {
            month += 12
            year -= 1
        }
        let day = min(self.day, 28)
        return Day(year, Int8(month), day)
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
        comp.year = Int(day.year)
        comp.month = Int(day.month)
        comp.day = Int(day.day)
        let date = cal.date(from: comp)!
        self = date
    }
    
    public init(_ day: Day, _ time: Time) {
        var comp = DateComponents()
        comp.year = Int(day.year)
        comp.month = Int(day.month)
        comp.day = Int(day.day)
        comp.hour = Int(time.hour)
        comp.minute = Int(time.minute)
        comp.second = Int(time.second)
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
                guard let day = Day.DayType(digs2[0]) else { return nil }
                var to = from
                if day < from.day {
                    to.month += 1
                }
                to.day = day
                to.normalize()
                self = from...to
            case 2:
                guard let month = Day.MonthType(digs2[0]), let day = Day.DayType(digs2[1]) else { return nil }
                var to = Day(from.year, month, day)
                if to < from {
                    to.year += 1
                }
                self = from...to
            case 3:
                guard let year = Day.YearType(digs2[0]), let month = Day.MonthType(digs2[1]), let day = Day.DayType(digs2[2]) else { return nil }
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
