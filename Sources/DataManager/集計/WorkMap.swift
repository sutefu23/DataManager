//
//  WorkMap.swift
//  DataManager
//
//  Created by manager on 2021/04/13.
//

import Foundation

// ある期間の作業時間の集計
class WorkMap {
    /// 集計期間
    let range: ClosedRange<Day>
    
    private let lock = NSLock()
    private var map: [Day: TimeMap]
    let orders: [指示書型]
    
    init(range: ClosedRange<Day>, orders: [指示書型]? = nil) throws {
        self.range = range
        self.map = [:]
        self.orders = try orders ?? 指示書型.find(作業範囲: range, 伝票種類: .箱文字)
//        self.orders = try orders ?? 指示書型.normalFind(作業範囲: range)

        DispatchQueue.concurrentPerform(iterations: self.orders.count) {
            let order = self.orders[$0]
            let list = order.進捗入力記録一覧
            list.forEach { self.registRecord($0) }
        }
    }
    
    subscript(_ day: Day) -> TimeMap {
        lock.lock()
        defer { lock.unlock() }
        if let timeMap = map[day] {
            return timeMap
        } else {
            let timeMap = TimeMap(day)
            map[day] = timeMap
            return timeMap
        }
    }
    
    func orders(day: Day) -> [指示書型] {
        return self.orders.filter {
            if $0.受注日 > day { return false }
            if $0.出荷納期 < day { return false }
            return true            
        }
    }
    
    func registRecord(_ record: 作業記録型) {
        guard let from = record.開始日時?.day, let to = record.完了日時?.day else { return }
        let process = record.工程
        for day in from...to {
            guard let seconds = record.作業時間(of: day) else { continue }
            self[day].append(seconds, for: process)
        }
    }
}

/// ある一日の作業時間の集計
class TimeMap {
    let day: Day
    private var map: [工程型: TimeInterval]
    private let lock = NSLock()
    
    init(_ day: Day) {
        self.day = day
        self.map = [:]
    }
    
    func append(_ seconds: TimeInterval, for process: 工程型) {
        lock.lock()
        defer { lock.unlock() }
        if let current = map[process] {
            map[process] = current + seconds
        } else {
            map[process] = seconds
        }
    }
    
    /// 工程に対応する作業時間を返す
    subscript(_ process: 工程型) -> TimeInterval? {
        lock.lock()
        defer { lock.unlock() }
        return map[process]
    }
    
//    subscript(_ group: 作業グループ型) -> TimeInterval? {
//        return group.関連工程.reduce(nil) {
//            guard let seconds = self[$1] else { return $0 }
//            guard let current = $0 else { return seconds }
//            return current + seconds
//        }
//    }
    
    func calc作業時間(関連工程 set: Set<工程型>) -> TimeInterval? {
        return set.reduce(nil) {
            guard let time = self[$1] else { return $0 }
            guard let current = $0 else { return time }
            return current + time
        }
    }
}
