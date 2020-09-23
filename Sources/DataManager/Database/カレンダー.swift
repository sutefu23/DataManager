//
//  カレンダー.swift
//  DataManager
//
//  Created by manager on 2019/03/04.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

public let 標準始業時間 = Time(8, 40)
public let 標準終業時間 = Time(17, 30)

public enum 日付タイプ型 {
    case 出勤日
    case 休日
    
    var description: String {
        switch self {
        case .出勤日: return "出勤日"
        case .休日: return "休日"
        }
    }
}

public extension TimeInterval {
    init(工程: 工程型?, 作業開始 from: Date, 作業完了 to: Date, by cal: カレンダー型 = 標準カレンダー) {
        self = cal.calcWorkTime(state: 工程, from: from, to: to)
    }
}

public extension Day {
    func 日付タイプ(_ cal: カレンダー型 = 標準カレンダー) -> 日付タイプ型 {
        return cal.isHoliday(of: self) ? .休日: . 出勤日
    }
}

public extension Date {
    func 日付タイプ(_ cal: カレンダー型 = 標準カレンダー) -> 日付タイプ型 {
        return self.day.日付タイプ(cal)
    }
    
    func 作業時間(from: Date, by cal: カレンダー型 = 標準カレンダー) -> TimeInterval {
        return cal.calcWorkTime(state: nil, from: from, to: self)
    }
    
    func 作業時間(to: Date, by cal: カレンダー型 = 標準カレンダー) -> TimeInterval {
        return cal.calcWorkTime(state: nil, from: self, to: to)
    }
    
    func 翌出勤日(by cal: カレンダー型 = 標準カレンダー, count: Int = 1) -> Date {
        return Date(self.day.翌出勤日(by: cal, count: count))
    }
    
    func 前出勤日(by cal: カレンダー型 = 標準カレンダー, count: Int = 1) -> Date {
        return Date(self.day.前出勤日(by: cal, count: count))
    }
}

public extension Day {
    func 翌出勤日(by cal: カレンダー型 = 標準カレンダー, count: Int = 1) -> Day {
        let count = (count > 0) ? count : 1
        var day = self.nextDay
        for _ in 1...count {
            while cal.isHoliday(of: day) {
                day = day.nextDay
            }
        }
        return day
    }
    
    func 前出勤日(by cal: カレンダー型 = 標準カレンダー, count: Int = 1) -> Day {
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
public struct 勤務時間型 {
    static let standard: 勤務時間型 = 勤務時間型(始業: 標準始業時間, 終業: 標準終業時間, 休憩時間: [
        (from: Time(10,00), to: Time(10,10)),
        (from: Time(12,00), to: Time(13,00)),
        (from: Time(15,00), to: Time(15,10)),
        (from: Time(17,30), to: Time(17,40)),
        ])

    static let handa: 勤務時間型 = 勤務時間型(始業: 標準始業時間, 終業: Time(20, 00), 休憩時間: [
        (from: Time(10,00), to: Time(10,10)),
        (from: Time(12,00), to: Time(13,00)),
        (from: Time(15,00), to: Time(15,10)),
        (from: Time(17,30), to: Time(17,40)),
        ])

    public var 始業: Time
    public var 終業: Time
    public var 休憩時間: [(from: Time, to: Time)]

    init(始業 from: Time = Time(8, 40), 終業 to: Time) {
        self.始業 = from
        self.終業 = to
        self.休憩時間 = [
            (from: Time(10,00), to: Time(10,10)),
            (from: Time(12,00), to: Time(13,00)),
            (from: Time(15,00), to: Time(15,10)),
            (from: Time(17,30), to: Time(17,40)),
        ]
    }

    init(始業 from: Time, 終業 to: Time, 休憩時間 rests: [(from: Time, to: Time)]) {
        self.始業 = from
        self.終業 = to
        self.休憩時間 = rests.sorted { $0.from < $1.from }
    }

    private func round(_ time: Time) -> Time {
        if time <= self.始業 { return self.始業 }
        if self.終業 <= time { return self.終業 }
        for rest in self.休憩時間 {
            if rest.from <= time && time <= rest.to { return rest.to }
        }
        return time
    }
    
    func calcWorkTime(from: Time, to: Time) -> TimeInterval {
        var offset : TimeInterval = 0
        for rest in self.休憩時間 {
            if from <= rest.from && rest.to <= to {
                offset += (rest.to - rest.from)
            }
        }
        let result = (to - from) - offset
        return result >= 0 ? result : 0
    }
    
    var fullTime: TimeInterval { return calcWorkTime(from: self.始業, to: self.終業) }
}

public let 標準カレンダー: カレンダー型 = 自動カレンダー型()
public let 半田カレンダー: カレンダー型 = 固定カレンダー型(day: 出勤日DB型.shared, time: 勤務時間型.handa)

public protocol カレンダー型 {
    func isHoliday(of day: Day) -> Bool
    func calcWorkTime(state: 工程型?, from: Date, to: Date) -> TimeInterval
    func 勤務時間(工程: 工程型, 日付: Day) -> 勤務時間型
}
 
public extension カレンダー型 {
    func 勤務日数(from: Day, to: Day) -> Int {
        var day = from
        var count = 0
        while day < to {
            count += 1
            repeat {
                day = day.nextDay
            } while day.isHoliday
        }
        return count
    }
}

final class 固定カレンダー型: カレンダー型 {
    private let dayDB: 出勤日DB型
    private let timeDB: 勤務時間型
    
    init(day: 出勤日DB型, time: 勤務時間型) {
        self.dayDB = day
        self.timeDB = time
    }
// MARK: 日付
    func isHoliday(of day: Day) -> Bool {
        return dayDB.isHoliday(of: day)
    }

    
// MARK: 時間
    func 勤務時間(工程: 工程型, 日付: Day) -> 勤務時間型 {
        return timeDB
    }
    func calcWorkTime(state: 工程型?, from: Date, to: Date) -> TimeInterval {
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

final class 自動カレンダー型: カレンダー型 {
   
    final class DayDB {
        let day: Day
        private let lock = NSLock()
        private var map: [工程型: 勤務時間型] = [:]
        private var all : 勤務時間型?
        private var allProgress: [進捗型]?
        private var progressMap: [工程型: [進捗型]]?
        
        init(_ day: Day) {
            self.day = day
        }
        
        private func fetchAllProgress() -> [進捗型] {
            if let list = self.allProgress { return list }
            let list = (try? 進捗型.find(工程: nil, 登録日: day)) ?? []
            self.allProgress = list
            return list
        }
        
        private func fetchProgress(for state: 工程型) -> [進捗型] {
            if let map = progressMap { return map[state] ?? [] }
            let map = Dictionary(grouping: fetchAllProgress()) { $0.工程 }
            self.progressMap = map
            return map[state] ?? []
        }
        
        func timeDB(of state: 工程型?) -> 勤務時間型 {
            lock.lock(); defer { lock.unlock() }
            let result: 勤務時間型
            if let state = state {
                if let cache = map[state] { return cache }
                if let time = fetchProgress(for: state).map({ $0.登録時間 }).max() {
                    result = 勤務時間型(終業: max(time, 標準終業時間))
                } else {
                    result = 勤務時間型.standard
                }
                map[state] = result
            } else {
                if let cache = self.all { return cache }
                if let time = fetchAllProgress().map({ $0.登録時間 }).max() {
                    result = 勤務時間型(終業: max(time, 標準終業時間))
                } else {
                    result = 勤務時間型.standard
                }
                self.all = result
            }
            return result
        }
    }
    private let lock = NSLock()
    private let dayDB: 出勤日DB型
    
    var db: [Day: DayDB]
    
    init() {
        self.db = [:]
        self.dayDB = 出勤日DB型.shared
    }

    func isHoliday(of day: Day) -> Bool {
        return dayDB.isHoliday(of:day)
    }
    
    func 勤務時間(工程: 工程型, 日付: Day) -> 勤務時間型 {
        return timeDB(of: 日付, state: 工程)
    }

    func timeDB(of day: Day, state: 工程型?) -> 勤務時間型 {
        lock.lock(); defer { lock.unlock() }
        if let db = self.db[day] {
            return db.timeDB(of: state)
        }
        let db = DayDB(day)
        self.db[day] = db
        return db.timeDB(of: state)
    }
    
    func calcWorkTime(state: 工程型?, from: Date, to: Date) -> TimeInterval {
        if to < from  { return 0 }
        var day = from.day
        let toDay = to.day
        var timeDB = self.timeDB(of: day, state: state)
        if day == toDay {
            return timeDB.calcWorkTime(from: from.time, to: to.time)
        }
        var workTime = timeDB.calcWorkTime(from: from.time, to: timeDB.終業)
        day = day.nextDay
        while day != toDay {
            if day.isHoliday == false {
                timeDB = self.timeDB(of: day, state: state)
                workTime += timeDB.fullTime
            }
            day = day.nextDay
        }
        timeDB = self.timeDB(of: day, state: state)
        workTime += timeDB.calcWorkTime(from: timeDB.始業, to: to.time)
        return workTime
    }
}
