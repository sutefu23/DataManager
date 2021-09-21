//
//  カレンダー.swift
//  DataManager
//
//  Created by manager on 2019/03/04.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

/// 始業時間(朝礼を考慮して40分からとしている)
public let 標準始業時間 = Time(8, 40)
/// 終業時間
public let 標準終業時間 = Time(17, 30)

public extension TimeInterval {
    /// 指定された工程について作業時間を計算する
    init(工程: 工程型?, 作業開始 from: Date, 作業完了 to: Date, by cal: カレンダー型 = 標準カレンダー) {
        self = cal.calcWorkTime(state: 工程, from: from, to: to)
    }
}

public extension Date {
    /// fromからthisまでの作業時間を計算する
    func 作業時間(工程: 工程型? = nil, from: Date, by cal: カレンダー型 = 標準カレンダー) -> TimeInterval {
        return cal.calcWorkTime(state: 工程, from: from, to: self)
    }
    
    /// thisからtoまでの作業時間を計算する
    func 作業時間(工程: 工程型? = nil, to: Date, by cal: カレンダー型 = 標準カレンダー) -> TimeInterval {
        return cal.calcWorkTime(state: 工程, from: self, to: to)
    }
    
    /// thisからcount営業日後の日を計算する
    func 翌出勤日(by cal: カレンダー型 = 標準カレンダー, count: Int = 1) -> Date {
        return Date(self.day.翌出勤日(by: cal, count: count))
    }
    
    /// thisからcount営業日前の日を計算する
    func 前出勤日(by cal: カレンダー型 = 標準カレンダー, count: Int = 1) -> Date {
        return Date(self.day.前出勤日(by: cal, count: count))
    }
}

public extension Day {
    /// thisからcount営業日後の日を計算する
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
    
    /// thisからcount営業日前の日を計算する
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

/// １日の勤務時間情報を保持する。0:00から0:00までの１日と考え、0:00を跨ぐことは想定しない
public struct 勤務時間型 {
    /// 一般的な勤務時間モデル
    static let standard: 勤務時間型 = 勤務時間型(始業: 標準始業時間, 終業: 標準終業時間, 休憩時間: [
        (from: Time(10,00), to: Time(10,10)),
        (from: Time(12,00), to: Time(13,00)),
        (from: Time(15,00), to: Time(15,10)),
        (from: Time(17,30), to: Time(17,40)),
        ])

    /// 半田部の勤務時間モデル
    static let handa: 勤務時間型 = 勤務時間型(始業: 標準始業時間, 終業: Time(20, 00), 休憩時間: [
        (from: Time(10,00), to: Time(10,10)),
        (from: Time(12,00), to: Time(13,00)),
        (from: Time(15,00), to: Time(15,10)),
        (from: Time(17,30), to: Time(17,40)),
        ])

    /// 始業時間
    public var 始業: Time
    /// 通常の就業時間
    public var 終業: Time
    /// 休憩時間のリスト。残業時間時の休憩時間も含む
    public var 休憩時間: [(from: Time, to: Time)]

    init(始業 from: Time = 標準始業時間, 終業 to: Time) {
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

    /// 指定された時間を勤務時間に丸める。休憩時間の時は休憩後の時間にする
    private func round(_ time: Time) -> Time {
        if time <= self.始業 { return self.始業 }
        if self.終業 <= time { return self.終業 }
        for rest in self.休憩時間 {
            if rest.from <= time && time <= rest.to { return rest.to }
        }
        return time
    }

    /// 指定された領域のから休憩時間を引いて作業時間を計算する
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
    
    /// １日のフルタイムの作業時間を返す
    var fullTime: TimeInterval { return calcWorkTime(from: self.始業, to: self.終業) }
}

/// 工程毎に１日の進捗入力から計算された残業時間を算出した残業カレンダー
public let 標準カレンダー: カレンダー型 = 自動カレンダー型()
/// 半田舞踊の専用カレンダ。就業時間は固定で20:00
public let 半田カレンダー: カレンダー型 = 固定カレンダー型(day: 出勤日DB型.shared, time: 勤務時間型.handa)

/// 標準的なカレンダーのインターフェース
public protocol カレンダー型 {
    func isHoliday(of day: Day) -> Bool
    func calcWorkTime(state: 工程型?, from: Date, to: Date, 終業カット: Bool) -> TimeInterval
    func 勤務時間(工程: 工程型?, 日付: Day) -> 勤務時間型
}

public extension カレンダー型 {
    // 2つの日にち間の勤務日数を数える。from==toで0日と数える
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

    /// 全工程で最大の勤務時間
    func 勤務時間(日付: Day) -> 勤務時間型 { self.勤務時間(工程: nil, 日付: 日付) }
    /// 勤務時間を計算する
    func calcWorkTime(state: 工程型?, from: Date, to: Date) -> TimeInterval {
        calcWorkTime(state: state, from: from, to: to, 終業カット: false)
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
    func 勤務時間(工程: 工程型?, 日付: Day) -> 勤務時間型 {
        return timeDB
    }
    func calcWorkTime(state: 工程型?, from: Date, to: Date, 終業カット: Bool) -> TimeInterval {
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
        var toTime = to.time
        if 終業カット && timeDB.終業 < toTime {
            toTime = timeDB.終業
        }
        workTime += timeDB.calcWorkTime(from: timeDB.始業, to: toTime)
        return workTime
    }
}

final class 自動カレンダー型: カレンダー型 {
   
    struct ProgressListCache {
        var list: [進捗型]?
        
        init(list: [進捗型]?) { self.list = list }
    }
    
    final class DayDB {
        let day: Day
        private let lock = NSRecursiveLock()
        private var map: [工程型: 勤務時間型] = [:]
        private var all : 勤務時間型?
        private var allProgress: [進捗型]?
        private var progressMap: [工程型: [進捗型]] = [:]
        
        init(_ day: Day) {
            self.day = day
        }
        
        private func fetchAllProgress() -> [進捗型] {
            lock.lock()
            defer { lock.unlock() }
            if let list = self.allProgress { return list }
            let list = (try? 進捗型.find(工程: nil, 登録日: day)) ?? []
            self.allProgress = list
            return list
        }
        
        private func fetchProgress(for state: 工程型) -> [進捗型] {
            lock.lock()
            defer { lock.unlock() }
            if let cache = progressMap[state] { return cache }
            if let allProgress = allProgress {
                let list = allProgress.filter { $0.工程 == state }
                progressMap[state] = list
                return list
            } else {
                if let list = try? 進捗型.find(工程: state, 登録日: day) {
                    progressMap[state] = list
                    return list
                } else {
                    return []
                }
            }
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
    
    func 勤務時間(工程: 工程型?, 日付: Day) -> 勤務時間型 {
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
    
    func calcWorkTime(state: 工程型?, from: Date, to: Date, 終業カット: Bool) -> TimeInterval {
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
        var toTime = to.time
        if 終業カット && timeDB.終業 < toTime {
            toTime = timeDB.終業
        }
        workTime += timeDB.calcWorkTime(from: timeDB.始業, to: toTime)
        return workTime
    }
}
