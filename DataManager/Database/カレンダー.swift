//
//  カレンダー.swift
//  DataManager
//
//  Created by manager on 2019/03/04.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

public enum 日付タイプ型 {
    case 出勤日
    case 休日
    
    var description : String {
        switch self {
        case .出勤日: return "出勤日"
        case .休日: return "休日"
        }
    }
}

public extension TimeInterval {
    init(作業開始 from:Date, 作業完了 to:Date, by cal:カレンダー型 = カレンダー型.standard) {
        self = cal.calcWorkTime(from: from, to: to)
    }
}

public extension Day {
    func 日付タイプ(_ cal:カレンダー型 = カレンダー型.standard) -> 日付タイプ型 {
        return cal.isHoliday(of: self) ? .休日: . 出勤日
    }

}

public extension Date {
    func 日付タイプ(_ cal:カレンダー型 = カレンダー型.standard) -> 日付タイプ型 {
        return self.day.日付タイプ(cal)
    }
    
    func 作業時間(from:Date, by cal:カレンダー型 = カレンダー型.standard) -> TimeInterval {
        return cal.calcWorkTime(from: from, to: self)
    }
    
    func 作業時間(to:Date, by cal:カレンダー型 = カレンダー型.standard) -> TimeInterval {
        return cal.calcWorkTime(from: self, to: to)
    }
    
    func 翌出勤日(by cal:カレンダー型 = カレンダー型.standard, count:Int = 1) -> Date {
        return Date(self.day.翌出勤日(by: cal, count: count))
    }
    
    func 前出勤日(by cal:カレンダー型 = カレンダー型.standard, count:Int = 1) -> Date {
        return Date(self.day.前出勤日(by: cal, count: count))
    }
}

public extension Day {
    func 翌出勤日(by cal:カレンダー型 = カレンダー型.standard, count:Int = 1) -> Day {
        let count = (count > 0) ? count : 1
        var day = self.nextDay
        for _ in 1...count {
            while cal.isHoliday(of: day) {
                day = day.nextDay
            }
        }
        return day
    }
    
    func 前出勤日(by cal:カレンダー型 = カレンダー型.standard, count:Int = 1) -> Day {
        let count = (count > 0) ? count : 1
        var day = self.prevDay
        for _ in 1...count {
            while cal.isHoliday(of: day) {
                day = day.prevDay
            }
        }
        return day
    }
}
struct 勤務時間型 {
    static let standard : 勤務時間型 = 勤務時間型(始業: Time(8, 30), 終業: Time(19, 00), 休憩時間: [
        (from:Time(10,00), to:Time(10,10)),
        (from:Time(12,00), to:Time(13,00)),
        (from:Time(15,00), to:Time(15,10)),
        (from:Time(17,30), to:Time(17,40)),
        ])

    static let handa : 勤務時間型 = 勤務時間型(始業: Time(8, 30), 終業: Time(20, 00), 休憩時間: [
        (from:Time(10,00), to:Time(10,10)),
        (from:Time(12,00), to:Time(13,00)),
        (from:Time(15,00), to:Time(15,10)),
        (from:Time(17,30), to:Time(17,40)),
        ])

    var 始業 : Time
    var 終業 : Time
    var 休憩時間 : [(from:Time, to:Time)]
    
    init(始業 from:Time, 終業 to:Time, 休憩時間 rests:[(from:Time, to:Time)]) {
        self.始業 = from
        self.終業 = to
        self.休憩時間 = rests.sorted { $0.from < $1.from }
    }

    private func round(_ time:Time) -> Time {
        if time <= self.始業 { return self.始業 }
        if self.終業 <= time { return self.終業 }
        for rest in self.休憩時間 {
            if rest.from <= time && time <= rest.to { return rest.to }
        }
        return time
    }
    
    func calcWorkTime(from:Time, to:Time) -> TimeInterval {
        var offset : TimeInterval = 0
        for rest in self.休憩時間 {
            if from <= rest.from && rest.to <= to {
                offset += (rest.to - rest.from)
            }
        }
        let result = (to - from) - offset
        return result >= 0 ? result : 0
    }
    
    var fullTime : TimeInterval { return calcWorkTime(from: self.始業, to: self.終業) }
}

public class カレンダー型 {
    static var 工程別カレンダー : [工程型 : カレンダー型] = [:]

    public static subscript(_ state:工程型) -> カレンダー型 {
        get { 工程別カレンダー[state] ?? カレンダー型.standard }
        set { 工程別カレンダー[state] = newValue }
    }
    
    public static let standard : カレンダー型 = カレンダー型(day: 出勤日DB型(), time: 勤務時間型.standard)
    public static let handa : カレンダー型 = カレンダー型(day: 出勤日DB型(), time: 勤務時間型.handa)
    private let dayDB : 出勤日DB型
    private let timeDB : 勤務時間型
    
    init(day:出勤日DB型, time:勤務時間型) {
        self.dayDB = day
        self.timeDB = time
    }
}

// MARK: 日付
extension カレンダー型 {
    func isHoliday(of day:Day) -> Bool {
        return dayDB.isHoliday(of:day)
    }
}

// MARK: 時間
extension カレンダー型 {
    func calcWorkTime(from:Date, to:Date) -> TimeInterval {
        if to < from  { return 0 }
        var day = from.day
        let toDay = to.day
        if day == toDay {
            return timeDB.calcWorkTime(from: from.time, to: to.time)
        }
        var workTime = timeDB.calcWorkTime(from: from.time, to: timeDB.終業)
        day = day.nextDay
        while day != toDay {
            if day.isHoliday == false {
                workTime += timeDB.fullTime
            }
            day = day.nextDay
        }
        workTime += timeDB.calcWorkTime(from: timeDB.始業, to: to.time)
        return workTime
    }
}
