//
//  Date.swift
//  DataManager
//
//  Created by manager on 2019/01/30.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

let cal = Calendar(identifier: .gregorian)
public enum 週型: Int {
    case 日 = 1
    case 月 = 2
    case 火 = 3
    case 水 = 4
    case 木 = 5
    case 金 = 6
    case 土 = 7
    
    public var description: String {
        switch self {
        case .日: return "日"
        case .月: return "月"
        case .火: return "火"
        case .水: return "水"
        case .木: return "木"
        case .金: return "金"
        case .土: return "土"
        }
    }
}

extension Date {
    // MARK: 初期化
    public init?(year: Day.YearType, month: Day.MonthType, day: Day.DayType) {
        let date = Day(year: year, month: month, day: day)
        self = Date(date)
    }
    
    public init?(year: Day.YearType, month: Day.MonthType, day: Day.DayType, hour: Time.HourType, minute: Time.MinuteType, second: Time.SecondType = 0) {
        let day = Day(year: year, month: month, day: day)
        let time = Time(hour, minute, second)
        self = Date(day, time)
    }
    /// FileMakerDataAPIの日付と時間
    init?<T>(fmJSONDay: T?, fmJSONTime: T? = nil) where T : StringProtocol{
        guard let fmJSONDay = fmJSONDay else { return nil }
        var parts = fmJSONDay.split(separator: "/")
        guard parts.count == 3 else { return nil }
        guard let day0 = Int(parts[0]) else { return nil }
        guard let day1 = Int(parts[1]) else { return nil }
        guard let day2 = Int(parts[2]) else { return nil }
        
        var comps = DateComponents()
        if day0 > day2 {
            comps.year = day0
            comps.month = day1
            comps.day = day2
        } else {
            comps.year = day2
            comps.month = day0
            comps.day = day1
        }
        
        if let fmJSONTime = fmJSONTime {
            parts = fmJSONTime.split(separator: ":")
            if parts.count == 3 {
                guard let hour = Int(parts[0]) else { return nil }
                guard let minute = Int(parts[1]) else { return nil }
                guard let second = Int(parts[2]) else { return nil }
                comps.hour = hour
                comps.minute = minute
                comps.second = second
            } else if parts.count == 2 {
                guard let hour = Int(parts[0]) else { return nil }
                guard let minute = Int(parts[1]) else { return nil }
                comps.hour = hour
                comps.minute = minute
                comps.second = 0
            } else {
                return nil
            }
        }
        guard let date = cal.date(from: comps) else { return nil }
        self = date

    }
    
    /// FileMakerDataAPIの日時
    public init?(fmJSONDayTime: String?) {
        guard let group = fmJSONDayTime?.split(separator: " ") else { return nil }
        switch group.count {
        case 1:
            self.init(fmJSONDay: group[0])
        case 2:
            self.init(fmJSONDay: group[0], fmJSONTime: group[1])
        default:
            return nil
        }
    }
    
    // FileMakerの日付
    public init?<S: StringProtocol>(fmDate: S) {
        guard let day = Day(fmDate: fmDate) else { return nil }
        self = Date(day)
    }

    /// 少数数点以下の秒を切り捨てる
    public func rounded() -> Date {
        let val = floor(self.timeIntervalSince1970)
        return Date(timeIntervalSince1970: val)
    }

    /// 装飾表示
    public var yearMonthString: String {
        return day.yearMonthString
    }
    
    // MARK: - 日付処理
    public var nextMonth: Date {
        let day = cal.date(byAdding: .month, value: 1, to: self)!.day
        return Date(day)
    }
    
    public var monthFirstDay: Date {
        let day = self.day
        let day1 = Day(year: day.year, month: day.month, day: 1)
        return Date(day1)
    }
    
    // MARK: 日付計算
    /// 曜日
    public var week: 週型 {
        return 週型(rawValue: cal.component(.weekday, from: self))!
    }
    /// 日付が同じかどうかを比べる（時間は違っていてok）
    public func isEqualDay(to: Date) -> Bool {
        return self.day == to.day
    }
    
    public var monthDayString: String {
        return self.day.monthDayString
    }
    
    public var yearMonthDayJString: String {
        return self.day.yearMonthDayJString
    }

    public var yearMonthDayString: String {
        return self.day.yearMonthDayString
    }
    
    public var monthDayJString: String {
        return self.day.monthDayJString
    }
    
    public var dataString: String {
        return "\(self.day.description) \(self.time.description)"
    }
    
    public var fmImportDay: String {
        return self.day.fmImportString
    }
    
    public var fmImportTime: String {
        return self.time.fmImportString
    }
    
    public var fmDayTime: String {
        return "\(day.fmString) \(time.fmImportString)"
    }
}

public extension TimeInterval {
    var minuteString: String {
        let min = Int(self / 60)
        return String(min)
    }
}

public func maxDate(_ date1: Date?, _ date2: Date?) -> Date? {
    guard let date1 = date1 else { return date2 }
    guard let date2 = date2 else { return date1 }
    return max(date1, date2)
}

public func minDate(_ date1: Date?, _ date2: Date?) -> Date? {
    guard let date1 = date1 else { return date2 }
    guard let date2 = date2 else { return date1 }
    return min(date1, date2)
}
