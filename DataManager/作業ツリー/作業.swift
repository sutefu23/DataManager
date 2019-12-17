//
//  作業.swift
//  DataManager
//
//  Created by manager on 2019/09/03.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

public enum 作業種類型 {
    case 通常
    case 保留
    case 校正
    case 営業戻し
    
    var string : String {
        switch self {
        case .通常: return "通常"
        case .保留: return "保留"
        case .校正: return "校正"
        case .営業戻し: return "営業戻し"
        }
    }
}

public class 作業型 {
    public var 作業種類 : 作業種類型
    public var 工程 : 工程型
    public var 開始日時 : Date
    public var 完了日時 : Date
    public var 作業者 : 社員型
    public var 伝票番号 : 伝票番号型
    
    public var 進捗度 : Int?
    public var 関連保留校正 : [作業型] = []

    init?(_ progress:進捗型? = nil, type:作業種類型 = .通常, state:工程型? = nil, from:Date? = nil, to:Date? = nil, worker: 社員型? = nil, 伝票番号 number:伝票番号型? = nil) {
        self.作業種類 = type
        guard let worker = worker ?? progress?.作業者 else { return nil }
        guard let state = state ?? progress?.工程 else { return nil }
        guard let st = from ?? progress?.登録日時 else { return nil }
        guard let ed = to ?? progress?.登録日時 else { return nil }
        guard let number = number ?? progress?.伝票番号 else { return nil }

        self.作業者 = worker
        self.工程 = state
        if st > ed { return nil }
        self.開始日時 = st
        self.完了日時 = ed
        self.伝票番号 = number
    }
    
    init?(_ work:作業記録型) {
        guard let from = work.開始日時, let to = work.完了日時 else { return nil }
        self.作業種類 = work.作業種類
        self.工程 = work.工程
        self.開始日時 = from
        self.完了日時 = to
        self.作業者 = work.作業者
        self.伝票番号 = work.伝票番号
        self.進捗度 = work.進捗度
        self.関連保留校正 = work.関連保留校正
    }
    
    var 工程社員 : 工程社員型 {
        return 工程社員型(工程: self.工程, 社員: self.作業者)
    }
    
    func isCross(to work:作業型) -> Bool {
        if work.完了日時 < self.開始日時 || self.完了日時 < work.開始日時 { return false }
        return true
    }
    
    func contains(_ work:作業型) -> Bool {
        return self.開始日時 <= work.開始日時 && work.完了日時 <= self.完了日時
    }
    
    public lazy var 作業時間 : TimeInterval = self.calcWorkTime()
    func calcWorkTime() -> TimeInterval {
        var result : TimeInterval = 0
        var current = self.開始日時
        let orderedStops = self.関連保留校正.sorted { $0.開始日時 < $1.開始日時 }
        for stop in orderedStops {
            if (stop.開始日時...stop.完了日時).contains(current) {
                current = stop.完了日時
            } else if (current...self.完了日時).contains(stop.開始日時) {
                result += self.工程.作業時間(from: current, to: stop.開始日時)
                current = stop.完了日時
            }
        }
        return self.工程.作業時間(from: current, to: self.完了日時)
    }
}

public class 作業記録型 {
    public var 作業種類 : 作業種類型
    public var 工程 : 工程型
    public var 開始日時 : Date?
    public var 完了日時 : Date?
    public var 作業者 : 社員型
    public var 伝票番号 : 伝票番号型
    
    public var 進捗度 : Int?
    public var 関連保留校正 : [作業型] = []
    public var 管理戻し : [作業型] = []
    public lazy var 作業期間 : ClosedRange<Date>? = {
        guard let from = self.開始日時, let to = self.完了日時 else { return nil }
        return from...to
    }()

    /// rangeに含まれる時間を含む
    public func isOverlap(range: ClosedRange<Day>) -> Bool {
        if let from = self.開始日時?.day {
            if range.contains(from) { return true }
        }
        if let to = self.完了日時?.day {
            if range.contains(to) { return true }
        }
        guard let from = self.開始日時?.day, let to = self.完了日時?.day else { return false }
        return (from...to).contains(range.lowerBound)
    }
    
    init?(_ progress:進捗型? = nil, type:作業種類型 = .通常, state:工程型? = nil, from:Date?, to:Date?, worker: 社員型? = nil, 伝票番号 number:伝票番号型? = nil) {
        self.作業種類 = type
        guard let worker = worker ?? progress?.作業者 else { return nil }
        guard let state = state ?? progress?.工程 else { return nil }
        guard let number = number ?? progress?.伝票番号 else { return nil }
        if let from = from, let to = to {
            if from > to { return nil }
        }

        self.作業者 = worker
        self.工程 = state
        self.開始日時 = from
        self.完了日時 = to
        self.伝票番号 = number
    }
    
    var 工程社員 : 工程社員型 {
        return 工程社員型(工程: self.工程, 社員: self.作業者)
    }
    
    public lazy var 作業時間 : TimeInterval? = self.calc作業時間()

    public func calc作業時間(from: Date? = nil, to: Date? = nil) -> TimeInterval? {
        guard let from = maxDate(from, self.開始日時), let to = minDate(to, self.完了日時) else { return nil }
        if from > to  { return nil }
        var result : TimeInterval = 0
        var current = from

        // 保留処理
        let orderedStops = self.関連保留校正.filter { $0.作業種類 == .保留}.sorted { $0.開始日時 < $1.開始日時 }.filter { $0.作業種類 != .営業戻し }
        for stop in orderedStops {
            if (stop.開始日時...stop.完了日時).contains(current) {
                current = stop.完了日時
            } else if (current...to).contains(stop.開始日時) {
                result += self.工程.作業時間(from: current, to: stop.開始日時)
                current = stop.完了日時
            }
        }
        return result + self.工程.作業時間(from: current, to: to) - self.営業戻し時間 - self.原稿校正時間
    }
    
    public lazy var 原稿校正時間 : TimeInterval = {
        if self.工程 != .原稿 { return 0 }
        return self.関連保留校正.filter { $0.作業種類 == .校正 }.reduce(0) { $0 + $1.作業時間 }
    }()
    
    public lazy var 営業戻し時間 : TimeInterval = {
        if self.工程 != .管理 { return 0 }
        return self.関連保留校正.filter { $0.作業種類 == .営業戻し }.reduce(0) { $0 + $1.作業時間 }
    }()
}

extension Array where Element == 作業記録型 {
    public func 累積作業時間(from: Date? = nil, to: Date? = nil) -> TimeInterval? {
        var result : TimeInterval? = nil
        for work in self {
            if let time = work.calc作業時間(to: to) {
                if let current = result {
                    result = current + time
                } else {
                    result = time
                }
            }
        }
        return result
    }
    
    public func workTime(mask: ClosedRange<Date>) -> TimeInterval {
        func maskRange(from:Date?, to: Date?, mask: ClosedRange<Date>) -> ClosedRange<Date>? {
            let resultFrom: Date = maxDate(from, mask.lowerBound)!
            let resultTo: Date = minDate(to, mask.upperBound)!
            return resultFrom <= resultTo ? resultFrom...resultTo : nil
        }
        var time: TimeInterval = 0
        for record in self {
            if let range = maskRange(from: record.開始日時, to: record.完了日時, mask: mask) {
                time += record.工程.作業時間(from: range.lowerBound, to: range.upperBound)
            }
        }
        return time
    }
    
    public func maskedFrom(_ date:Date, fill:Bool) -> Date? {
        let records: [Date] = self.compactMap {
            if let end = $0.完了日時 {
                if end < date { return nil }
            }
            if fill {
                return maxDate($0.開始日時, date)
            } else {
                if let start = $0.開始日時, start >= date {
                    return start
                }
                return nil
            }
        }
        return records.min()
    }
    
    public func maskedEnd(_ date:Date, fill:Bool) -> Date? {
        let records: [Date] = self.compactMap {
            if let start = $0.開始日時 {
                if date < start { return nil }
            }
            if fill {
                return minDate($0.完了日時, date)
            } else {
                if let end = $0.完了日時, end <= date {
                    return end
                }
                return nil
            }
        }
        return records.max()
    }

}

class ProgressCounter {
    var acc: Int = 0
    var start: Int = 0
    var work: Int = 0
    var comp: Int = 0
    
    init(_ work: 作業内容型) {
        self.append(work)
    }
    
    func append(_ work: 作業内容型) {
        switch work {
        case .受取: self.acc += 1
        case .開始: self.start += 1
        case .仕掛: self.work += 1
        case .完了: self.comp += 1
        }
    }
    
    var lessComp: Bool { return comp < start }
    var lessStart: Bool { return start < comp }
}

// MARK: - 工程分析
extension 指示書型 {
    func make進捗入力記録一覧() -> [作業記録型] {
        var registMap = Set<工程型>()
        var works = [作業記録型]()
        var firstAccepts : [工程型 : 進捗型] = [:]
        var accepts : [工程型 : 進捗型] = [:]
        var froms : [工程型 : 進捗型] = [:]
        var completed : [工程型 : 進捗型] = [:]
        var lastMarked : [工程型 : 進捗型] = [:]
        func regist(work: 作業記録型, state: 工程型) {
            works.append(work)
            registMap.insert(state)
            accepts[state] = nil
            froms[state] = nil
        }
        let list = self.進捗一覧.filter { $0.作業種別 == .通常 }
        var countMap : [工程型 : ProgressCounter] = [:]
        for progress in list {
            let process = progress.工程
            if let counter = countMap[process] {
                counter.append(progress.作業内容)
            } else {
                let counter = ProgressCounter(progress.作業内容)
                countMap[process] = counter
            }
        }
        for progress  in list {
            let state = progress.工程
            func 完了補完(前工程: 工程型, 後工程: 工程型) {
                if state != 後工程 || countMap[前工程]?.lessComp != true { return }
                switch progress.作業内容 {
                case .受取:
                    if let from = froms[前工程], let work = 作業記録型(from, from: from.登録日時, to: progress.登録日時) {
                        regist(work: work, state: 前工程)
                    }
                case .開始:
                    if let from = froms[前工程], let work = 作業記録型(from, from: from.登録日時, to: progress.登録日時) {
                        regist(work: work, state: 前工程)
                    }
                case .仕掛, .完了:
                    return
                }
            }
            完了補完(前工程: .立ち上がり, 後工程: .半田)
            完了補完(前工程: .半田, 後工程: .裏加工)
            完了補完(前工程: .立ち上がり_溶接, 後工程: .溶接)
            完了補完(前工程: .溶接, 後工程: .裏加工_溶接)
            
            switch progress.作業内容 {
            case .受取:
                accepts[state] = progress
                if firstAccepts[state] == nil { firstAccepts[state] = progress }
            case .開始:
                froms[state] = progress
            case .完了:
                if let from = froms[state] {
                    if let work = 作業記録型(progress, from: from.登録日時, to: progress.登録日時) {
                        regist(work: work, state: state)
                    }
                } else {
                    func 開始補完(前工程: 工程型, 後工程: 工程型) -> Bool {
                        if state != 後工程 || countMap[前工程]?.lessStart != true { return false }
                        if let coms = lastMarked[前工程], coms.作業内容 == .完了, let work = 作業記録型(progress, from: coms.登録日時, to: progress.登録日時) {
                            regist(work: work, state: state)
                            return true
                        }
                        return false
                    }
                    if 開始補完(前工程: .照合検査, 後工程: .立ち上がり) { break }
                    if 開始補完(前工程: .立ち上がり, 後工程: .半田) { break }
                    if 開始補完(前工程: .半田, 後工程: .裏加工) { break }
                    if 開始補完(前工程: .照合検査, 後工程: .立ち上がり_溶接) { break }
                    if 開始補完(前工程: .立ち上がり_溶接, 後工程: .溶接) { break }
                    if 開始補完(前工程: .溶接, 後工程: .裏加工_溶接) { break }
                    switch state {
                    case .営業:
                        if let work = 作業記録型(progress, from: self.登録日時, to: progress.登録日時) {
                            regist(work: work, state: state)
                        }
                    case .管理:
                        if let accept = firstAccepts[state], let work = 作業記録型(progress, from: accept.登録日時, to: progress.登録日時)  {
                            regist(work: work, state: state)
                        }
                    default:
                        completed[state] = progress
                    }
                }
            case .仕掛:
                break
            }
            lastMarked[state] = progress
        }
        let stops = self.保留校正一覧 + make管理戻し()
        for work in works {
            guard let range = work.作業期間 else { continue }
            for stop in stops {
                if range.overlaps(stop.開始日時...stop.完了日時) {
                    work.関連保留校正.append(stop)
                }
            }
        }
        for (state, progress) in froms {
            guard !registMap.contains(state) else { continue }
            if let work = 作業記録型(progress, from: progress.登録日時, to: nil) {
                works.append(work)
                registMap.insert(state)
            }
        }
        for (state, progress) in completed {
            guard !registMap.contains(state) else { continue }
            if let work = 作業記録型(progress, from: nil, to: progress.登録日時) {
                works.append(work)
                registMap.insert(state)
            }
        }
        if !registMap.contains(.営業) {
            if let work = 作業記録型(type: .通常, state: .営業, from: self.登録日時, to: nil, worker: self.担当者1, 伝票番号: self.伝票番号) {
                works.append(work)
            }
        }
        return works
    }
    
    func make管理戻し() -> [作業型] {
        var list: [作業型] = []
        var stop: Date? = nil
        loop:for progress in self.進捗一覧 where progress.工程 == .管理 {
            switch progress.作業内容 {
            case .仕掛:
                if stop == nil { stop = progress.登録日時 }
            case .受取:
                if let stop = stop {
                    if let work = 作業型(progress, type: .営業戻し, from: stop, to: progress.登録日時) {
                        list.append(work)
                    }
                }
            case .完了:
                break loop
            case .開始:
                break
            }
        }
        return list
    }
}
