//
//  作業時間分析.swift
//  DataManager
//
//  Created by manager on 2021/03/30.
//

import Foundation

#if os(iOS)
#elseif os(macOS)
import CreateML

@available(OSX 11.0, *)
public struct OrderTimeInfo {
    public let order: 指示書型
    public let model: TimeModel
    
    public init(order: 指示書型, model: TimeModel) {
        self.order = order
        self.model = model
    }

    // 名目
    public func calc名目(process: 工程型) -> TimeInterval? {
        return order.make集計(工程: process)?.名目
    }

    public func calc名目(set: Set<工程型>) -> TimeInterval? {
        return order.make集計(関連工程: set)?.名目
    }

    public func calc名目(group: 作業グループ型) -> TimeInterval? {
        return order.make集計(作業グループ: group)?.名目
    }

    public func calc名目推計(group: 作業グループ型) -> TimeInterval? {
        return try? model.predict名目作業時間(order, 作業グループ: group)
    }
    
    public func calc名目推計(process: 工程型) -> TimeInterval? {
        return try? model.predict名目作業時間(order, 工程: process)
    }
    
    public func calc名目推計(set: Set<工程型>) -> TimeInterval? {
        return try? model.predict作業時間(order, 関連工程: set, 集計タイプ: .名目)
    }

    // 実質
    public func calc実働(process: 工程型) -> TimeInterval? {
        return order.make集計(工程: process)?.実質
    }

    public func calc実働(set: Set<工程型>) -> TimeInterval? {
        return order.make集計(関連工程: set)?.実質
    }

    public func calc実働(group: 作業グループ型) -> TimeInterval? {
        return order.make集計(作業グループ: group)?.実質
    }

    public func calc実働推計(group: 作業グループ型) -> TimeInterval? {
        return try? model.predict実働作業時間(order, 作業グループ: group)
    }
    
    public func calc実働推計(process: 工程型) -> TimeInterval? {
        return try? model.predict実働作業時間(order, 工程: process)
    }
    
    public func calc実働推計(set: Set<工程型>) -> TimeInterval? {
        return try? model.predict実働作業時間(order, 関連工程: set)
    }

}

public enum 指示書分類型: Hashable {
    case 切文字
    case 箱文字_その他
    case 箱文字_大
    case 箱文字_W
    case 加工
    case エッチング
    
    public init?(_ order: 指示書型) {
        switch order.伝票種類 {
        case .切文字:
            self = .切文字
        case .箱文字:
            if order.箱文字側面高さ.contains(where: { $0 > 1500 }) {
                self = .箱文字_大
            } else if order.仕様.toJapaneseNormal.contains("W") {
                self = .箱文字_W
            } else {
                self = .箱文字_その他
            }
        case .エッチング:
            self = .エッチング
        case .加工:
            self = .加工
        case .外注, .校正:
            return nil
        }
    }
}

public enum 作業グループ型: Hashable {
    case データ
    case 準備
    case 製造
    case 仕上
    case 発送
    
    public var 関連工程: Set<工程型> {
        switch self {
        case .データ:
            return [.原稿, .入力, .出力]
        case .準備:
            return [.レーザー, .フォーミング, .腐蝕, .版焼き, .腐蝕印刷, .エッチング, .印刷, .シート貼り]
        case .製造:
            return [.オブジェ, .加工, .切文字, .溶接, .裏加工_溶接, .半田, .レーザー溶接, .ボンド, .裏加工]
        case .仕上:
            return [.研磨, .表面仕上, .マスキング, .中塗り, .塗装, .下処理, .乾燥炉, .プライマー, .外注, .拭き取り]
        case .発送:
            return [.品質管理, .発送]
        }
    }
}
// 作業集計
extension 指示書型 {
//    /// タイムテーブルの集計
//    public func makeTimeTable() -> TimeTable {
//        return TimeTable(データ集計: make集計(作業グループ: .データ), 準備集計: make集計(作業グループ: .準備), 製造集計: make集計(作業グループ: .製造), 仕上集計: make集計(作業グループ: .仕上), 発送集計: make集計(作業グループ: .発送))
//    }

    func make集計(作業グループ: 作業グループ型) -> (開始: Date, 名目: TimeInterval, 実質: TimeInterval, 完了: Date)? {
        return make集計(関連工程: 作業グループ.関連工程)
    }
    
    /// 指定された作業グループの作業集計
    func make集計(関連工程 set: Set<工程型>) -> (開始: Date, 名目: TimeInterval, 実質: TimeInterval, 完了: Date)? {
        let progress = self.進捗一覧.filter { set.contains($0.工程) }
        guard let from = progress.first?.登録日時, let to = progress.last?.登録日時 else { return nil }
        // 名目時間
        var time1 = from.作業時間(to: to)
        if time1 < 0 { time1 = 0 }
        // 実質時間
        var time2: TimeInterval = 0
        for process in set {
            guard let workList = self.工程別作業記録[process], workList.isEmpty == false else { continue }
            for work in workList {
                guard let time = work.作業時間 else { continue }
                time2 += time
            }
        }
        return (from, time1, time2, to)
    }
    
    /// 指定された工程の作業集計
    func make集計(工程 process: 工程型) -> (開始: Date, 名目: TimeInterval, 実質: TimeInterval, 完了: Date)? {
        let progress = self.進捗一覧.filter { $0.工程 == process }
        guard let from = progress.first?.登録日時, let to = progress.last?.登録日時 else { return nil }
        // 名目時間
        var time1 = from.作業時間(to: to)
        if time1 < 0 { time1 = 0 }
        // 実質時間
        var time2: TimeInterval = 0
        if let workList = self.工程別作業記録[process], workList.isEmpty == false {
            if let time = workList.calc累積作業時間() {
                time2 += time
            }
        }
        return (from, time1, time2, to)
    }
}

// 時間集計
public enum 時間集計型: Hashable {
    case 名目
    case 実質
}

@available(OSX 11.0, *)
public class TimeModel {
    private let lock = NSLock()
    private let orders: [指示書型]
    private let orderMap: [指示書分類型: [指示書型]]
    private var modelCache: [ModelKey: 作業時間推計モデル型] = [:]
    private var modelCache2: [ModelKey: 作業時間推計モデル型] = [:]
    private struct ModelKey: Hashable {
        let 関連工程: Set<工程型>
        let 指示書分類: 指示書分類型
        let 集計タイプ: 時間集計型
    }
    public init(orders: [指示書型]) {
        self.orders = orders
        var map = [指示書分類型: [指示書型]]()
        for order in orders {
            guard let type = 指示書分類型(order) else { continue }
            if var list = map[type] {
                list.append(order)
                map[type] = list
            } else {
                map[type] = [order]
            }
        }
        self.orderMap = map
    }
    
    private func prepareModel(forKey key: ModelKey) throws -> 作業時間推計モデル型 {
        lock.lock()
        defer { lock.unlock() }
        if let cache = modelCache[key] { return cache }
        let orders = self.orderMap[key.指示書分類] ?? self.orders
        let model = try 作業時間推計モデル型(orders, 関連工程: key.関連工程, 集計タイプ: key.集計タイプ)
        modelCache[key] = model
        return model
    }

    public func predict名目作業時間(_ order: 指示書型, 作業グループ: 作業グループ型) throws -> TimeInterval {
        return try self.predict作業時間(order, 関連工程: 作業グループ.関連工程, 集計タイプ: .名目)
    }

    public func predict名目作業時間(_ order: 指示書型, 工程: 工程型) throws -> TimeInterval {
        return try self.predict作業時間(order, 関連工程: [工程], 集計タイプ: .名目)
    }

    public func predict名目作業時間(_ order: 指示書型, 関連工程: Set<工程型>) throws -> TimeInterval {
        return try self.predict作業時間(order, 関連工程: 関連工程, 集計タイプ: .名目)
    }

    public func predict実働作業時間(_ order: 指示書型, 作業グループ: 作業グループ型) throws -> TimeInterval {
        return try self.predict作業時間(order, 関連工程: 作業グループ.関連工程, 集計タイプ: .実質)
    }

    public func predict実働作業時間(_ order: 指示書型, 工程: 工程型) throws -> TimeInterval {
        return try self.predict作業時間(order, 関連工程: [工程], 集計タイプ: .実質)
    }

    public func predict実働作業時間(_ order: 指示書型, 関連工程: Set<工程型>) throws -> TimeInterval {
        return try self.predict作業時間(order, 関連工程: 関連工程, 集計タイプ: .実質)
    }

    public func predict作業時間(_ order: 指示書型, 関連工程: Set<工程型>, 集計タイプ: 時間集計型) throws -> TimeInterval {
        guard let type = 指示書分類型(order) else { return 0 }
        let key = ModelKey(関連工程: 関連工程, 指示書分類: type, 集計タイプ: 集計タイプ)
        let model = try self.prepareModel(forKey: key)
        return try model.predict作業時間(order)
    }

}

@available(OSX 11.0, *)
struct 作業時間推計モデル型 {
    static func makeTable(orders: [指示書型], 関連工程 set: Set<工程型>, 集計タイプ: 時間集計型) throws -> MLDataTable {
        let lock = NSLock()
        // 集計
        var 作業時間: [TimeInterval] = []
        var 年: [Int] = []
        var 月: [Int] = []
        var 日: [Int] = []
        var 伝票種類: [Int] = []
        var 仕様: [String] = []
        var 文字数: [Int] = []
        var サイズ: [Double] = []
        var 裏仕様: [String] = []
        
        var 社内塗装あり: [Bool] = []
        var 外注あり: [Bool] = []
        var レーザーあり: [Bool] = []
        var エッチングあり: [Bool] = []
        var 印刷あり: [Bool] = []
        var 台板あり: [Bool] = []

        DispatchQueue.concurrentPerform(iterations: orders.count) {
            let order = orders[$0]
            let timeTable = order.make集計(関連工程: set)
            let _作業時間: TimeInterval
            switch 集計タイプ {
            case .名目:
                _作業時間 = timeTable?.名目 ?? 0
            case .実質:
                _作業時間 = timeTable?.実質 ?? 0
            }
            let day = order.出荷納期
            let _年 = day.year
            let _月 = day.month
            let _日 = day.day
            let _伝票種類 = order.伝票種類.rawValue
            let _仕様 = order.仕様
            let _裏仕様 = order.裏仕様
            let _文字数 = order.指示書文字数.総文字数
            let _サイズ = order.寸法サイズ.max() ?? order.仮サイズ
            let _社内塗装あり = order.社内塗装あり || order.is内作塗装あり
            let _外注あり = order.外注塗装あり || order.外注メッキあり || order.is外注塗装あり
            let _レーザーあり = order.レーザーアクリルあり || !order.レーザー加工機.isEmpty
            let _エッチングあり = order.略号.contains(.腐食)
            let _印刷あり = order.略号.contains(.印刷)
            let _台板あり = order.略号.contains(.看板) || order.略号.contains(.組込)

            lock.lock()
            作業時間.append(_作業時間)
            年.append(_年)
            月.append(_月)
            日.append(_日)
            伝票種類.append(_伝票種類)
            仕様.append(_仕様)
            裏仕様.append(_裏仕様)
            文字数.append(_文字数)
            サイズ.append(_サイズ)
            社内塗装あり.append(_社内塗装あり)
            外注あり.append(_外注あり)
            レーザーあり.append(_レーザーあり)
            エッチングあり.append(_エッチングあり)
            印刷あり.append(_印刷あり)
            台板あり.append(_台板あり)
            lock.unlock()
        }
        // モデルの作成
        let dic: [String: MLDataValueConvertible]  = [
            "作業時間": 作業時間,
            "年": 年,
            "月": 月,
            "日": 日,
            "伝票種類": 伝票種類,
            "仕様": 仕様,
            "裏仕様": 裏仕様,
            "文字数": 文字数,
            "サイズ": サイズ,
            "社内塗装あり": 社内塗装あり.map{ $0 ? 1 : 0 },
            "外注あり": 外注あり.map{ $0 ? 1 : 0 },
            "レーザーあり": レーザーあり.map{ $0 ? 1 : 0 },
            "エッチングあり": エッチングあり.map{ $0 ? 1 : 0 },
            "印刷あり": 印刷あり.map{ $0 ? 1 : 0 },
            "台板あり": 台板あり.map{ $0 ? 1 : 0 },
        ]
        let table = try MLDataTable(dictionary: dic)
        return table
    }

    let regressor: MLLinearRegressor
    let set: Set<工程型>
    let 集計タイプ: 時間集計型

    init(_ orders: [指示書型], 関連工程 set: Set<工程型>, 集計タイプ: 時間集計型) throws {
        self.集計タイプ = 集計タイプ
        self.set = set
        let table = try 作業時間推計モデル型.makeTable(orders: orders, 関連工程: set, 集計タイプ: 集計タイプ)
        self.regressor = try MLLinearRegressor(trainingData: table, targetColumn: "作業時間")
    }
    
    func predict作業時間(_ order: 指示書型) throws -> TimeInterval {
        let table = try 作業時間推計モデル型.makeTable(orders: [order], 関連工程: self.set, 集計タイプ: 集計タイプ)
        let col = try self.regressor.predictions(from: table)
        guard let values = col.doubles, !values.isEmpty else { return 0 }
        return values.element(at: 0) ?? 0
    }
}

private extension 指示書型 {
    /// サイズ欄が空の時に仮に入れるサイズ
    var 仮サイズ: Double {
        switch self.伝票種類 {
        case .箱文字:
            return 500
        case .切文字:
            return 150
        case .加工, .エッチング:
            return 600
        case .校正, .外注:
            return 0
        }
    }
}

#endif
