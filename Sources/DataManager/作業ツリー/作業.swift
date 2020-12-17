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
    
    var string: String {
        switch self {
        case .通常: return "通常"
        case .保留: return "保留"
        case .校正: return "校正"
        case .営業戻し: return "営業戻し"
        }
    }
}

public class 作業型 {
    public var 作業種類: 作業種類型
    public var 工程: 工程型
    public var 開始日時: Date
    public var 完了日時: Date
    public var 作業者: 社員型
    public var 伝票番号: 伝票番号型
    
    public var 進捗度: Int?
    public var 関連保留校正: [作業型] = []

    init?(_ progress: 進捗型? = nil, type: 作業種類型 = .通常, state: 工程型? = nil, from: Date? = nil, to: Date? = nil, worker: 社員型? = nil, 伝票番号 number: 伝票番号型? = nil) {
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
    
    init?(_ work: 作業記録型) {
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
    
    var 工程社員: 工程社員型 {
        return 工程社員型(工程: self.工程, 社員: self.作業者)
    }
    
    func isCross(to work: 作業型) -> Bool {
        if work.完了日時 < self.開始日時 || self.完了日時 < work.開始日時 { return false }
        return true
    }
    
    func contains(_ work: 作業型) -> Bool {
        return self.開始日時 <= work.開始日時 && work.完了日時 <= self.完了日時
    }
    
    public lazy var 作業時間: TimeInterval = self.calcWorkTime()
    func calcWorkTime() -> TimeInterval {
        var result: TimeInterval = 0
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
    public var 作業種類: 作業種類型
    public var 工程: 工程型
    public var 開始日時: Date?
    public var 完了日時: Date?
    public var 作業者: 社員型
    public var 伝票番号: 伝票番号型
    
    public var 進捗度: Int?
    public var 関連保留校正: [作業型] = []
    public var 管理戻し: [作業型] = []
    public lazy var 作業期間: ClosedRange<Date>? = {
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
    
    init?(_ progress: 進捗型? = nil, type: 作業種類型 = .通常, state: 工程型? = nil, from: Date?, to: Date?, worker: 社員型? = nil, 伝票番号 number: 伝票番号型? = nil) {
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
    
    var 工程社員: 工程社員型 {
        return 工程社員型(工程: self.工程, 社員: self.作業者)
    }
    
    public lazy var 作業時間: TimeInterval? = self.calc作業時間()

    public func calc作業時間(from: Date? = nil, to: Date? = nil) -> TimeInterval? {
        guard let from = maxDate(from, self.開始日時), let to = minDate(to, self.完了日時) else { return nil }
        if from > to  { return nil }
        var result: TimeInterval = 0
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
    
    public lazy var 原稿校正時間: TimeInterval = {
        if self.工程 != .原稿 { return 0 }
        return self.関連保留校正.filter { $0.作業種類 == .校正 }.reduce(0) { $0 + $1.作業時間 }
    }()
    
    public lazy var 営業戻し時間: TimeInterval = {
        if self.工程 != .管理 { return 0 }
        return self.関連保留校正.filter { $0.作業種類 == .営業戻し }.reduce(0) { $0 + $1.作業時間 }
    }()
}

extension Array where Element == 作業記録型 {
    public func calc累積作業時間(from: Date? = nil, to: Date? = nil) -> TimeInterval? {
        var result: TimeInterval? = nil
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
        func maskRange(from: Date?, to: Date?, mask: ClosedRange<Date>) -> ClosedRange<Date>? {
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
    
    public func maskedFrom(_ date: Date, fill: Bool) -> Date? {
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
    
    public func maskedEnd(_ date: Date, fill: Bool) -> Date? {
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
    public static var 作業記録補完: Bool = true
    
    func setup関連保留校正処理<S: Sequence>(_ works: S) where S.Element == 作業記録型 {
        let stops = self.保留校正一覧 + make管理戻し()
        for work in works {
            guard let range = work.作業期間 else { continue }
            for stop in stops {
                if range.overlaps(stop.開始日時...stop.完了日時) {
                    work.関連保留校正.append(stop)
                }
            }
        }
    }
    
    func make進捗入力記録一覧() -> [作業記録型] {
        var registMap = Set<工程型>()
        var works = [作業記録型]()
        var firstAccepts: [工程型: 進捗型] = [:]
        var accepts: [工程型: 進捗型] = [:]
        var froms: [工程型: 進捗型] = [:]
        var pending: [工程型: 進捗型] = [:]
        var sharedFroms: [工程型: 進捗型] = [:]
        var completed: [工程型: 進捗型] = [:]
        var lastMarked: [工程型: 進捗型] = [:]
        func regist(work: 作業記録型, state: 工程型) {
            works.append(work)
            registMap.insert(state)
            accepts[state] = nil
            froms[state] = nil
        }
        let list = self.進捗一覧.filter { $0.作業種別 == .通常 }
        var countMap: [工程型: ProgressCounter] = [:]
        for progress in list {
            let process = progress.工程
            if let counter = countMap[process] {
                counter.append(progress.作業内容)
            } else {
                let counter = ProgressCounter(progress.作業内容)
                countMap[process] = counter
            }
        }
        var フォーミングfrom: 進捗型? = nil
        var フォーミングto: 進捗型? = nil
        for progress  in list {
            let state = progress.工程
            if state == .フォーミング {
                switch progress.作業内容 {
                case .受取:
                    if let to = フォーミングto {
                        if let work = 作業記録型(progress, from: フォーミングfrom?.登録日時, to: to.登録日時) { works.append(work) }
                        フォーミングto = nil
                    }
                    フォーミングfrom = progress
                case .開始, .仕掛:
                    break
                case .完了:
                    if let work = 作業記録型(progress, from: フォーミングfrom?.登録日時, to: progress.登録日時) { works.append(work) }
                    フォーミングfrom = nil
                    フォーミングto = nil
                }
                continue
            } else if state == .タレパン || state == .シャーリング || state == .プレーナー {
                switch progress.作業内容 {
                case .受取, .開始, .仕掛:
                    break
                case .完了:
                    フォーミングto = progress
                }
                continue
            }
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
            if 指示書型.作業記録補完 {
                完了補完(前工程: .立ち上がり, 後工程: .半田)
                完了補完(前工程: .半田, 後工程: .裏加工)
                完了補完(前工程: .立ち上がり_溶接, 後工程: .溶接)
                完了補完(前工程: .溶接, 後工程: .裏加工_溶接)
            }
            
            switch progress.作業内容 {
            case .受取:
                accepts[state] = progress
                if firstAccepts[state] == nil { firstAccepts[state] = progress }
            case .開始:
                if let mid = pending[state], let from = froms[state] {
                    pending[state] = nil
                    if let work = 作業記録型(progress, from: from.登録日時, to: mid.登録日時) {
                        regist(work: work, state: state)
                    }
                }
                froms[state] = progress
            case .仕掛:
                if froms[state] != nil {
                    pending[state] = progress
                }
            case .完了:
                pending[state] = nil
                if let from = froms[state] {
                    if let work = 作業記録型(progress, from: from.登録日時, to: progress.登録日時) {
                        regist(work: work, state: state)
                    }
                } else {
                    if progress.作業種別 == .在庫 {
                        break
                    }
                    func 開始補完(前工程: 工程型, 後工程: 工程型) -> Bool {
                        if state != 後工程 || countMap[前工程]?.lessStart != true { return false }
                        if let coms = lastMarked[前工程], coms.作業内容 == .完了, let work = 作業記録型(progress, from: coms.登録日時, to: progress.登録日時) {
                            regist(work: work, state: state)
                            return true
                        }
                        return false
                    }
                    if 指示書型.作業記録補完 {
                        if 開始補完(前工程: .照合検査, 後工程: .立ち上がり) { break }
                        if 開始補完(前工程: .立ち上がり, 後工程: .半田) { break }
                        if 開始補完(前工程: .半田, 後工程: .裏加工) { break }
                        if 開始補完(前工程: .照合検査, 後工程: .立ち上がり_溶接) { break }
                        if 開始補完(前工程: .立ち上がり_溶接, 後工程: .溶接) { break }
                        if 開始補完(前工程: .溶接, 後工程: .裏加工_溶接) { break }
                    }
                    switch state {
                    case .営業:
                        if let work = 作業記録型(progress, from: self.登録日時, to: progress.登録日時) {
                            regist(work: work, state: state)
                        }
                    case .管理:
                        if let accept = firstAccepts[state], let work = 作業記録型(progress, from: accept.登録日時, to: progress.登録日時)  {
                            regist(work: work, state: state)
                        } else {
                            completed[state] = progress
                        }
                    case .レーザー（アクリル）:
                        if let from = froms[.レーザー] {
                            if let work = 作業記録型(progress, from: from.登録日時, to: progress.登録日時) {
                                regist(work: work, state: state)
                                sharedFroms[.レーザー] = from
                                froms[.レーザー] = nil
                            }
                        } else {
                            completed[state] = progress
                        }
                        if let work = 作業記録型(progress, from: nil, to: progress.登録日時) {
                            regist(work: work, state: state)
                        }
                    case .レーザー:
                        if let from = froms[.レーザー（アクリル）] ?? sharedFroms[.レーザー] {
                            if let work = 作業記録型(progress, from: from.登録日時, to: progress.登録日時) {
                                regist(work: work, state: state)
                                froms[.レーザー（アクリル）] = nil
                                sharedFroms[.レーザー] = nil
                            }
                        } else {
                            completed[state] = progress
                        }
                    default:
                        completed[state] = progress
                    }
                }
            }
            lastMarked[state] = progress
        }
        if フォーミングfrom != nil || フォーミングto != nil, let work = 作業記録型(フォーミングto ?? フォーミングfrom, state: .フォーミング, from: フォーミングfrom?.登録日時, to: フォーミングto?.登録日時) { works.append(work) }
        self.setup関連保留校正処理(works)
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
    
    public func make作業区間(state: 工程型, from: (process: 工程型, state: 作業内容型), to: (process: 工程型, state: 作業内容型)) -> [作業記録型] {
        var head: 進捗型? = nil
        var works: [作業記録型] = []
        for progress in self.進捗一覧 {
            if progress.工程 == from.process && progress.作業内容 == from.state {
                head = progress
            } else if progress.工程 == to.process && progress.作業内容 == to.state {
                if let work = 作業記録型(head, type: .通常, state: state, from: head?.登録日時, to: progress.登録日時) {
                    works.append(work)
                }
            }
        }
        self.setup関連保留校正処理(works)
        return works
    }

    public func calc作業時間(state: 工程型, from: (process: 工程型, state: 作業内容型), to: (process: 工程型, state: 作業内容型)) -> TimeInterval? {
        let works = self.make作業区間(state: state, from: from, to: to)
        return works.calc累積作業時間()
    }

    public func make箱文字滞留期間() -> [箱文字期間型: 作業記録型]? {
        let worker = self.担当者1 ?? self.担当者2 ?? self.担当者3
        let list = self.進捗一覧
        guard let kend = list.findFirst(工程: .管理, 作業内容: .完了)?.登録日時
            ,let nend = list.findFirst(工程: .入力, 作業内容: .完了)?.登録日時
            ,let send = list.findFirst(工程: .照合検査, 作業内容: .完了)?.登録日時 else { return nil }
        let yend = (list.findFirst(工程: .裏加工_溶接, 作業内容: .完了) ?? list.findFirst(工程: .溶接, 作業内容: .完了))?.登録日時
        let hend = (list.findFirst(工程: .裏加工, 作業内容: .完了) ?? list.findFirst(工程: .裏加工, 作業内容: .仕掛) ?? list.findFirst(工程: .半田, 作業内容: .完了))?.登録日時
        let hakoend: Date
        let hakostate: 工程型
        if let yend = yend {
            if let hend = hend {
                if hend > yend {
                    hakoend = hend
                    hakostate = .半田
                } else {
                    hakoend = yend
                    hakostate = .溶接
                }
            } else {
                hakoend = yend
                hakostate = .溶接
            }
        } else if let hend = hend {
            hakoend = hend
            hakostate = .半田
        } else { return nil }
        guard let htime = list.findLast(工程: .発送, 作業内容: .完了)?.登録日時 else { return nil }
        
        guard let ekwork = 作業記録型(nil, type: .通常, state: .管理, from: self.登録日時, to: kend, worker: worker, 伝票番号: self.伝票番号)
        ,let gnwork = 作業記録型(nil, type: .通常, state: .原稿, from: kend, to: nend, worker: worker, 伝票番号: self.伝票番号)
        ,let lswork = 作業記録型(nil, type: .通常, state: .レーザー, from: nend, to: send, worker: worker, 伝票番号: self.伝票番号)
        ,let hywork = 作業記録型(nil, type: .通常, state: hakostate, from: send, to: hakoend, worker: worker, 伝票番号: self.伝票番号)
            ,let akwork = 作業記録型(nil, type: .通常, state: .発送, from: hakoend, to: htime, worker: worker, 伝票番号: self.伝票番号) else { return nil }
        let result: [箱文字期間型: 作業記録型] = [
            .営業管理: ekwork,
            .原稿入力: gnwork,
            .レーザー照合: lswork,
            .溶接半田: hywork,
            .後工程: akwork]
        self.setup関連保留校正処理(result.values)
        return result
    }
}

public enum 箱文字期間型: Hashable, CaseIterable {
    case 営業管理
    case 原稿入力
    case レーザー照合
    case 溶接半田
    case 後工程
    
    public var 関連工程: [工程型] {
        switch self {
        case .営業管理:
            return [.営業, .管理]
        case .原稿入力:
            return [.原稿, .入力, .出力]
        case .レーザー照合:
            return [.レーザー, .レーザー（アクリル）, .照合検査]
        case .溶接半田:
            return [.立ち上がり, .立ち上がり_溶接, .半田, .溶接, .裏加工, .裏加工_溶接]
        case .後工程:
            return [.研磨, .表面仕上, .塗装, .乾燥炉, .品質管理, .組立, .発送, .拭き取り]
        }
    }
}

public extension Day {
    func makeTimeMap(is四熊: Bool = false) throws -> [箱文字期間型: Time] {
        var result: [箱文字期間型: Time] = [:]
        
        let list = try 進捗型.find(工程: nil, 伝票種類: .箱文字, 登録日: self).filter {
            if is四熊 == false && $0.社員番号 == 23 { return false }
            return $0.登録時間 > 標準終業時間
        }
        let group = Dictionary(grouping: list) { $0.工程 }
        for range in 箱文字期間型.allCases {
            for process in range.関連工程 {
                guard let progressList = group[process] else { continue }
                guard let time = progressList.map({ $0.登録時間 }).max() else { continue }
                if let current = result[range] {
                    if current < time {
                        result[range] = time
                    }
                } else {
                    result[range] = time
                }
            }
        }
        
        let list2 = try 指示書変更内容履歴型.find(日付: self,伝票種類: .箱文字).filter { $0.種類 == .指示書承認 && $0.日時.time > 標準終業時間 }
        for change in list2 {
            let time = change.日時.time
            if let current = result[.営業管理] {
                if current < time {
                    result[.営業管理] = time
                }
            } else {
                result[.営業管理] = time
            }
        }
        return result
    }
}

public extension ClosedRange where Bound == Day {
    func make平均残業時間Map(is四熊: Bool = false) throws -> [箱文字期間型: TimeInterval] {
        var work: [箱文字期間型: (sum: TimeInterval, count: TimeInterval)] = [:]
        var day = self.lowerBound
        while self.contains(day) {
            if day.isWorkday {
                let map = try day.makeTimeMap(is四熊: is四熊)
                for (key, value) in map {
                    let zanSeconds = value - 標準終業時間
                    if zanSeconds <= 0 { continue }
                    if let current = work[key] {
                        work[key] = (current.sum + zanSeconds, current.count + 1)
                    } else {
                        work[key] = (zanSeconds, 1)
                    }
                }
            }
            day = day.nextDay
        }
        var result: [箱文字期間型: TimeInterval] = [:]
        for (key, value) in work {
            result[key] = value.sum / value.count
        }
        return result
    }
}
