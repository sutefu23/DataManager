//
//  作業区間.swift
//  DataManager
//
//  Created by manager on 2021/07/13.
//

import Foundation

class 作業区間型 {
    var 開始: 進捗型
    var 完了: 進捗型
    var 作業外時間: TimeInterval = 0
    
    init(開始: 進捗型, 完了: 進捗型) {
        self.開始 = 開始
        self.完了 = 完了
    }
    
    func apply保留校正(_ range: 作業型) {
        if range.開始日時 >= 開始.登録日時 && range.完了日時 <= 完了.登録日時 {
            作業外時間 += range.作業時間
        }
    }
}

func make作業区間(_ source: [進捗型]) -> (list: [作業区間型], recordIDMap: [String: 作業区間型]) {
    struct MapKey: Hashable {
        var 伝票番号: 伝票番号型
        var 工程: 工程型
        var 作業内容: 作業内容型
        var 作業者: 社員型
        
        init(_ progress: 進捗型) {
            self.伝票番号 = progress.伝票番号
            self.工程 = progress.工程
            self.作業内容 = progress.作業内容
            self.作業者 = progress.作業者
        }
    }
    let group = DispatchGroup()
    let lock = NSLock()
    let lock2 = NSLock()
    var recordIDMap: [String: 作業区間型] = [:]
    var result: [作業区間型] = []
    let map = Dictionary(grouping: source) { MapKey($0) }
    for (key, list) in map {
        DispatchQueue.global().async(group: group) {
            var calc: ProgressCalculator = InitialCalculator()
            let list = list.sorted { $0.登録日時 < $1.登録日時 }
            for progress in list {
                calc = calc.process(progress)
            }
            if let order = key.伝票番号.キャッシュ指示書 {
                calc.apply保留校正(order)
            }
            lock.lock()
            result.append(contentsOf: calc.result)
            lock.unlock()
            lock2.lock()
            calc.result.forEach {
                recordIDMap[$0.開始.recordID] = $0
                recordIDMap[$0.完了.recordID] = $0
            }
            lock2.unlock()
        }
    }
    return (result, recordIDMap)
}

class ProcessMap2 {
    struct MapKey: Hashable {
        var 工程: 工程型
        var 作業内容: 作業内容型
        var 作業者: 社員型
    }
    
    init(_ source: [進捗型]) {
        
    }
    
    func buddy(of procgress: 進捗型) -> [進捗型] {
        return [procgress]
    }
}

// MARK: - 作業区間作成
protocol ProgressCalculator {
    var result: [作業区間型] { get set }
    var errors: [String] { get }
    
    func process(_ next: 進捗型) -> ProgressCalculator
}

extension ProgressCalculator {
    /// 保留・校正処理
    func apply保留校正(_ order: 指示書型) {
        let list = order.保留校正一覧
        for range in list {
            result.forEach { $0.apply保留校正(range) }
        }
    }
}

class InitialCalculator: ProgressCalculator {
    var result: [作業区間型] = []
    var errors: [String] = []
    
    func process(_ next: 進捗型) -> ProgressCalculator {
        switch next.作業内容 {
        case .受取:
            return self
        case .開始:
            return StaringCalcurator(result: result, errors: errors, from: next)
        case .仕掛:
            errors.append("開始の前に仕掛かりがある")
            return self // 開始がないので何もできない
        case .完了:
            errors.append("開始の前に完了がある")
            return self // 開始がないので何もできない
        }
    }
}

class StaringCalcurator: ProgressCalculator {
    var result: [作業区間型]
    var errors: [String]
    var from: 進捗型
    
    init(result: [作業区間型], errors: [String], from: 進捗型) {
        self.result = result
        self.errors = errors
        self.from = from
    }
    
    func process(_ next: 進捗型) -> ProgressCalculator {
        switch next.作業内容 {
        case .受取:
            return self
        case .開始:
            self.from = next
            return self
        case .仕掛:
            return WorkingCalculator(result: result, errors: errors, from: from, working: next)
        case .完了:
            return CompletingCalculator(result: result, errors: errors, from: from, complete: next)
        }
    }
}

class WorkingCalculator: ProgressCalculator {
    var result: [作業区間型]
    var errors: [String]
    var from: 進捗型
    var working: 進捗型
    
    init(result: [作業区間型], errors: [String], from: 進捗型, working: 進捗型) {
        self.result = result
        self.errors = errors
        self.from = from
        self.working = working
    }

    func process(_ next: 進捗型) -> ProgressCalculator {
        switch next.作業内容 {
        case .受取:
            return self
        case .開始:
            let work = 作業区間型(開始: from, 完了: working)
            return StaringCalcurator(result: result + [work], errors: errors, from: next)
        case .仕掛:
            self.working = next
            return self // 開始がないので何もできない
        case .完了:
            return CompletingCalculator(result: result, errors: errors, from: from, complete: next)
        }
    }
}

class CompletingCalculator: ProgressCalculator {
    var result: [作業区間型]
    var errors: [String]
    var from: 進捗型
    
    init(result: [作業区間型], errors: [String], from: 進捗型, complete: 進捗型) {
        self.result = result + [作業区間型(開始: from, 完了: complete)]
        self.errors = errors
        self.from = from
    }

    func process(_ next: 進捗型) -> ProgressCalculator {
        switch next.作業内容 {
        case .受取:
            return self
        case .開始:
            return StaringCalcurator(result: result, errors: errors, from: next)
        case .仕掛:
            errors.append("開始の前に仕掛かりがある")
            return self // 開始がないので何もできない
        case .完了:
            result.last!.完了 = next
            return self
        }
    }
}
