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
    public var 伝票番号 : Int
    
    public var 進捗度 : Int?
    public var 関連保留校正 : [作業型] = []

    init?(_ progress:進捗型? = nil, type:作業種類型 = .通常, state:工程型? = nil, from:Date? = nil, to:Date? = nil, worker: 社員型? = nil, 伝票番号 number:Int? = nil) {
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
    public var 伝票番号 : Int
    
    public var 進捗度 : Int?
    public var 関連保留校正 : [作業型] = []
    public var 管理戻し : [作業型] = []
    public lazy var 作業期間 : ClosedRange<Date>? = {
        guard let from = self.開始日時, let to = self.完了日時 else { return nil }
        return from...to
    }()

    init?(_ progress:進捗型? = nil, type:作業種類型 = .通常, state:工程型? = nil, from:Date?, to:Date?, worker: 社員型? = nil, 伝票番号 number:Int? = nil) {
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
    
    public lazy var 作業時間 : TimeInterval? = {
        guard let from = self.開始日時, var to = self.完了日時 else { return nil }
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
    }()
    
    public lazy var 原稿校正時間 : TimeInterval = {
        if self.工程 != .原稿 { return 0 }
        return self.関連保留校正.filter { $0.作業種類 == .校正 }.reduce(0) { $0 + $1.作業時間 }
    }()
    
    public lazy var 営業戻し時間 : TimeInterval = {
        if self.工程 != .管理 { return 0 }
        return self.関連保留校正.filter { $0.作業種類 == .営業戻し }.reduce(0) { $0 + $1.作業時間 }
    }()
}

extension 指示書型 {
    func make進捗入力記録一覧() -> [作業記録型] {
        var registMap = Set<工程型>()
        var works = [作業記録型]()
        var firstAccepts : [工程型 : 進捗型] = [:]
        var accepts : [工程型 : 進捗型] = [:]
        var froms : [工程型 : 進捗型] = [:]
        var completed : [工程型 : 進捗型] = [:]
        for progress  in self.進捗一覧 {
            let state = progress.工程
            switch progress.作業内容 {
            case .受取:
                accepts[state] = progress
                if firstAccepts[state] == nil { firstAccepts[state] = progress }
            case .開始:
                froms[state] = progress
            case .完了:
                if let from = froms[state] {
                    if let work = 作業記録型(progress, from: from.登録日時, to: progress.登録日時) {
                        works.append(work)
                        registMap.insert(state)
                        accepts[state] = nil
                        froms[state] = nil
                    }
                } else {
                    switch state {
                    case .営業:
                        if let work = 作業記録型(progress, from: self.登録日時, to: progress.登録日時) {
                            works.append(work)
                            registMap.insert(state)
                        }
                    case .管理:
                        if let accept = firstAccepts[state], let work = 作業記録型(progress, from: accept.登録日時, to: progress.登録日時)  {
                            works.append(work)
                            accepts[state] = nil
                            registMap.insert(state)
                        }
                    default:
                        completed[state] = progress
                    }
                }
            case .仕掛:
                break
            }
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
