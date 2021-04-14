//
//  資源量分析.swift
//  DataManager
//
//  Created by manager on 2021/04/13.
//

import Foundation

#if os(iOS)
#elseif os(macOS)
import CreateML

@available(OSX 11.0, *)
public struct OrderResourceInfo {
    public let day: Day
    let model: ProcessModel
    
    public init(day: Day, model: ProcessModel) {
        self.day = day
        self.model = model
    }

    public func predict資源量(作業グループ group: 作業グループ型) -> TimeInterval? {
        return self.predict資源量(関連工程: group.関連工程)
    }

    public func real資源量(作業グループ group: 作業グループ型) -> TimeInterval? {
        return self.real資源量(関連工程: group.関連工程)
    }
    
    public func predict資源量(関連工程 set: Set<工程型>) -> TimeInterval? {
        do {
            return try model.predict資源量(day: day, 関連工程: set)
        } catch {
            return nil
        }
    }

    public func real資源量(関連工程 set: Set<工程型>) -> TimeInterval? {
        do {
            return try model.real資源量(day: day, 関連工程: set)
        } catch {
            return nil
        }
    }
}

@available(OSX 11.0, *)
public class ProcessModel {
    private let lock = NSLock()
    
    private var map: [Set<工程型>: 資源量推計モデル型] = [:]
    private let workMap: WorkMap
    
    public init(range: ClosedRange<Day>, orders: [指示書型]? = nil) throws {
        self.workMap = try WorkMap(range: range, orders: orders)
    }
    
    private func prepareModel(for set: Set<工程型>) throws -> 資源量推計モデル型 {
        lock.lock()
        defer { lock.unlock() }
        if let cache = map[set] { return cache }
        let model = try 資源量推計モデル型(map: self.workMap, 関連工程: set)
        map[set] = model
        return model
    }
    
    public func predict資源量(day: Day, 関連工程 set: Set<工程型>) throws -> TimeInterval? {
        return try self.prepareModel(for: set).predict資源量(day: day)
    }

    public func real資源量(day: Day, 関連工程 set: Set<工程型>) throws -> TimeInterval? {
        return try self.prepareModel(for: set).real資源量(day: day)
    }

}

private struct ModelKey: Hashable {
    var range: ClosedRange<Day>
    var set: Set<工程型>
}


@available(OSX 11.0, *)
public struct 資源量推計モデル型 {
    private static var modelCache: [ModelKey: (model: MLDataTable, realMap: [Day: TimeInterval])] = [:]
    private static let modelLock = NSLock()
    static func makeTable(days: ClosedRange<Day>, map: WorkMap, 関連工程 set: Set<工程型>, predict: Bool) throws -> (model: MLDataTable, realMap: [Day: TimeInterval]) {
        let modelLock = 資源量推計モデル型.modelLock
        let key = ModelKey(range: days, set: set)
        modelLock.lock()
        if let cache = 資源量推計モデル型.modelCache[key] {
            資源量推計モデル型.modelLock.unlock()
            return cache
        }
        modelLock.unlock()
        
        let lock = NSLock()
        var 作業時間: [TimeInterval] = []
        var 年: [Int] = []
        var 月: [Int] = []
        var 日: [Int] = []
        var 前日休日: [Bool] = []
        var 翌日休日: [Bool] = []
        var 曜日: [Int] = []
        var 伝票数: [Int] = []
        
        var realMap: [Day: TimeInterval] = [:]

        let days = [Day](days)
        DispatchQueue.concurrentPerform(iterations: days.count) {
            let day = days[$0]
            if day.isHoliday { return }
            let _作業時間: TimeInterval = map[day].calc作業時間(関連工程: set) ?? 0
            let _年 = day.year
            let _月 = day.month
            let _日 = day.day
            let _前日休日 = day.prevDay.isHoliday
            let _翌日休日 = day.nextDay.isHoliday
            let _曜日 = day.week.rawValue - 1 // 日曜を0にする
            let _伝票数 = map.orders(day: day.prevWorkDay).count
            
            lock.lock()
            作業時間.append(_作業時間)
            年.append(_年)
            月.append(_月)
            日.append(_日)
            前日休日.append(_前日休日)
            翌日休日.append(_翌日休日)
            曜日.append(_曜日)
            伝票数.append(_伝票数)
            realMap[day] = _作業時間
            lock.unlock()
        }
        // モデルの作成
        var dic: [String: MLDataValueConvertible]  = [
            "作業時間": 作業時間,
            "年": 年,
            "月": 月,
            "日": 日,
            "前日休日": 前日休日,
            "翌日休日": 翌日休日,
            "曜日": 曜日,
            "伝票数": 伝票数,
        ]
        if !predict {
            dic["作業時間"] = 作業時間
        }
        let table = try MLDataTable(dictionary: dic)
        let result = (table, realMap)
        modelLock.lock()
        資源量推計モデル型.modelCache[key] = result
        modelLock.unlock()
        return result
    }
    
    let map: WorkMap
    let realMap: [Day: TimeInterval]
    let regressor: MLLinearRegressor
    let set: Set<工程型>

    init(map: WorkMap, 関連工程 set: Set<工程型>) throws {
        self.map = map
        self.set = set
        let (table, realMap) = try 資源量推計モデル型.makeTable(days: map.range, map: map, 関連工程: set, predict: false)
        self.realMap = realMap
        self.regressor = try MLLinearRegressor(trainingData: table, targetColumn: "作業時間")
    }
    
    func predict資源量(day: Day) throws -> TimeInterval? {
        let (table, _) = try 資源量推計モデル型.makeTable(days: day...day, map: map, 関連工程: set, predict: true)
        let col = try self.regressor.predictions(from: table)
        guard let values = col.doubles, !values.isEmpty else { return nil }
        return values.element(at: 0)
    }

    func real資源量(day: Day) throws -> TimeInterval? {
        if let real = self.realMap[day] { return real }
        let (_, realMap2) = try 資源量推計モデル型.makeTable(days: day...day, map: map, 関連工程: set, predict: true)
        return realMap2[day]
    }
}

#endif
