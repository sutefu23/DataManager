//
//  工程.swift
//  DataManager
//
//  Created by manager on 2019/02/05.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

extension FileMakerRecord {
    func 工程(forKey key: String) -> 工程型? {
        guard let code = string(forKey: key) else { return nil }
        return 工程型(code)
    }
}

public struct 工程型: Hashable, Comparable, Codable {
    public static let dbName = "DataAPI_7"
    let number: Int

    public init?<S: StringProtocol>(_ name: S) {
        let name = String(name)
        if let state = 名称工程DB[name] {
            self.init(state.number)
        } else {
            self.init(code: name)
        }
    }

    init(_ number: Int) { self.number = number }
    
    init(name: String, code: String) {
        assert(!name.isEmpty)
        self.init(code: code)!
        nameMap2[self] = name
        codeMap2[self] = code
    }
    
    public init?(code: String?) {
        guard let code = code else { return nil }
        var main: Int = 0
        var sub: Int = 0
        for (index, ch) in code.uppercased().enumerated() {
            if ch.isASCIINumber {
                guard let ascii = ch.asciiValue else { return nil }
                main = main*10 + Int(ascii) - 48
            } else {
                if index == 0 {
                    if ch != "P" { return nil }
                } else {
                    guard let ascii = ch.asciiValue else { return nil }
                    if ascii < 65 || ascii >= 65 + 26 { return nil }
                    sub = Int(ascii) - 64
                }
            }
        }
        self.number = main * 100 + sub
        if number <= 0 { return nil }
    }
    
    public var description: String {
        return 工程名称DB[self] ?? nameMap2[self] ?? ""
    }
    public var is製作工程: Bool { is製作工程Set.contains(self) }

    public func 作業時間(from: Date?, to: Date?) -> TimeInterval? {
        guard let from = from, let to = to else { return nil }
        return TimeInterval(工程: self, 作業開始: from, 作業完了: to)
    }
    public func 作業時間(from: Date, to: Date) -> TimeInterval {
        return TimeInterval(工程: self, 作業開始: from, 作業完了: to)
    }
    /// fromとtoの間の経過時間を算出。fromとtoが前後してるものはマイナスで返す
    public func 経過時間(from: Date, to: Date) -> TimeInterval {
        if from <= to {
            return 作業時間(from: from, to: to)
        }else{
            return 作業時間(from: to, to: from) * -1
        }
    }
    
    public func 推定始業時間(of day: Day) -> Time {
        return 標準カレンダー.勤務時間(工程: self, 日付: day).始業
    }
    public func 推定終業時間(of day: Day) -> Time {
        return 標準カレンダー.勤務時間(工程: self, 日付: day).終業
    }
    public var isValid: Bool { 工程名称DB.codeMap[self] != nil }
    public var code: String { return 工程名称DB.codeMap[self] ?? codeMap2[self]! }
    
    public static func < (left: 工程型, right: 工程型) -> Bool { return left.number < right.number  }
    public static func == (left: 工程型, right: 工程型) -> Bool { return left.number == right.number  }
    
    // MARK: - Codable
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
//        var dv = try container.decode(Double.self)
        var number = try container.decode(Int.self)
        if number < 100 || (number % 100) > 25 {
            number = (number / 10)*100 + number % 100
        }
        self.init(number)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.number)
    }
    
    /// fromからtoに対して基準時間(始業と終業の間)を境に0.5刻みでどれだけ進んだかを返す
    public func calc作業日(from : Date, to : Date) -> Double{
        let isSameDay = from.dayNumber == to.dayNumber //fromとtoが同じ日かどうか
        let workdays = from.day.workDays(to: to.day) - (isSameDay ? 1 : 2) // fromとtoの間に何日営業日があるか
        let from基準時間 = from.day.基準時間(for: self)
        let to基準時間 = to.day.基準時間(for: self)
        
        let start = self.推定始業時間(of: from.day) < from基準時間 ? 1.0 : 0.5
        let end = self.推定終業時間(of: to.day) < to基準時間 ? 0 : 0.5
        let offset = isSameDay ? -1 : 0 //同日だったら１ひく
        return start + end + Double(workdays) + Double(offset)
    }
}

extension Day {
    /// 工程の始業と終業の中間の時間を返す
    public func 基準時間(for 工程 :工程型) -> Time {
        let 始業時間 = 工程.推定始業時間(of: self)
        let 終業時間 = 工程.推定終業時間(of: self)
        return middleTime(from: 始業時間, to: 終業時間)
    }
    /// 時間と時間の間の時間を返す(テストのために切り出しました)
    internal func middleTime(from: Time, to: Time ) -> Time {
        let minute = Int((( to - from) / 2 ) / 60)
        return from.appendMinutes(minute)
    }
    
}

private var nameMap2 = [工程型: String]()
private var codeMap2 = [工程型: String]()

class 工程名称DB型 {
    var map: [工程型: String]
    var reversedMap: [String: 工程型]
    var codeMap: [工程型: String]
    
    init() {
        let _ = 工程型.工場工程一覧
        var map: [工程型: String] = [:]
        var map2: [String: 工程型] = [
            "レーザー・ウォーター" : .レーザー,
            "アクリル" : .レーザー（アクリル）,
            "アクリル（レーザー）" : .レーザー（アクリル）,
            "組立・検品" : .組立,
            "組立検品" : .組立,
            "照合検査" : .照合検査,
            "照合・検査" : .照合検査,
            "ルーターカット" : .ルーター,
            "附属品準備" : .付属品準備,
            "腐食" : .腐蝕,
            "タップ" : .タップ,
            "洗い場" : .表面仕上,
            "検査" : .照合検査,
            "設計" : .商品設計,
        ]
        var map3: [工程型: String] = [:]
        for record in db_全工程 {
            guard let code = record.string(forKey: "工程コード"), let state = 工程型(code: code), let name = record.string(forKey: "工程名") else { continue }
            map[state] = name
            map2[name] = state
            map3[state] = code.uppercased()
        }
        self.map = map
        self.reversedMap = map2
        self.codeMap = map3
    }
    
    subscript(_ state: 工程型) -> String? {
        return map[state] ?? nameMap2[state]
    }
}

private let db_全工程: [FileMakerRecord] = {
    let db = FileMakerDB.pm_osakaname
    return (try? db.fetch(layout: 工程型.dbName)) ?? []
}()

var is製作工程Set: Set<工程型> = {
    var set = Set<工程型>()
    for record in db_全工程 {
        guard let code = record.string(forKey: "工程コード"),
              let process = 工程型(code: code),
              let state1 = record.string(forKey: "受取"),
              let state2 = record.string(forKey: "開始"),
              let state3 = record.string(forKey: "仕掛"),
              let state4 = record.string(forKey: "完了")
        else { continue }
        if state1 == "製作中" || state2 == "製作中" || state3 == "製作中" || state4 == "製作中" {
            set.insert(process)
        }
    }
    return set
}()

func flush工程名称DB() {
    if isInit工程名称DB {
        工程名称DB = 工程名称DB型()
    }
}

private var isInit工程名称DB = false
private(set) var 工程名称DB: 工程名称DB型 = {
    isInit工程名称DB = true
    return 工程名称DB型()
}()

var 名称工程DB: [String: 工程型] { 工程名称DB.reversedMap }

public extension 工程型 {
    static let 工場工程一覧: [工程型] = [
        .営業, .校正, .管理, .商品設計,
        .原稿, .出力, .フィルム, .入力,
        .レーザー, .レーザー（アクリル）, .照合検査,
        .腐蝕, .印刷, .版焼き, .腐蝕印刷, .腐蝕印刷,
        .フォーミング, .シャーリング, .プレーナー, .タレパン,
        .加工, .仕上, .オブジェ,
        .切文字,
        .溶接, .立ち上がり_溶接, .裏加工_溶接, .レーザー溶接,
        .立ち上がり, .半田, .裏加工, .ボンド,
        .ルーター, .タップ, .シート貼り,
        .研磨, .表面仕上, .中塗り, .マスキング, .プライマー,
        .下処理, .塗装, .乾燥炉, .拭き取り,
        .外注, .付属品準備, .組立,
        .品質管理, .発送,
    ]
    static var 有効工程一覧: [工程型] = {
        let list: [工程型] = db_全工程.compactMap {
            guard let code = $0.string(forKey: "工程コード"),
                  let process = 工程型(code: code) else { return nil }
            let name = process.description
            if name.contains("廃止") || name.contains("予備") { return nil }
            return process
        }.sorted()
        return list.isEmpty ? 工程型.工場工程一覧 : list
    }()

    static let 営業 = 工程型(name: "営業", code: "P001")
    static let 校正 = 工程型(name: "校正", code: "P002")
    static let 管理 = 工程型(name: "管理", code: "P003")
    static let 商品設計 = 工程型(name: "商品設計", code: "P003B")
    static let 原稿 = 工程型(name: "原稿", code: "P004")
    static let 出力 = 工程型(name: "出力", code: "P004B")
    static let フィルム = 工程型(name: "フィルム", code: "P004C")
    static let 入力 = 工程型(name: "入力", code: "P005")
    static let レーザー = 工程型(name: "レーザー", code: "P006")
    static let レーザー（アクリル） = 工程型(name: "レーザー（アクリル）", code: "P006A")
    static let 照合検査 = 工程型(name: "照合検査", code: "P006B")
    static let 腐蝕 = 工程型(name: "腐蝕", code: "P007")
    static let 版焼き = 工程型(name: "版焼き", code: "P007A")
    static let 腐蝕印刷 = 工程型(name: "腐蝕印刷", code: "P007B")
    static let エッチング = 工程型(name: "エッチング", code: "P007C")
    static let オブジェ = 工程型(name: "オブジェ", code: "P008")
    static let フォーミング = 工程型(name: "フォーミング", code: "P009")
    static let シャーリング = 工程型(name: "シャーリング", code: "P009A")
    static let プレーナー = 工程型(name: "プレーナー", code: "P009B")
    static let タレパン = 工程型(name: "タレパン", code: "P009C")
    static let 加工 = 工程型(name: "加工", code: "P010")
    static let 仕上 = 工程型(name: "仕上", code: "P011")
    static let 切文字 = 工程型(name: "切文字", code: "P012")
    static let 溶接 = 工程型(name: "溶接", code: "P013")
    static let 立ち上がり_溶接 = 工程型(name: "立ち上がり（溶接）", code: "P013A")
    static let 裏加工_溶接 = 工程型(name: "裏加工（溶接）", code: "P013C")
    static let 立ち上がり = 工程型(name: "立ち上がり", code: "P014")
    static let 半田 = 工程型(name: "半田", code: "P015")
    static let レーザー溶接 = 工程型(name: "レーザー溶接", code: "P015A")
    static let ボンド = 工程型(name: "ボンド", code: "P015B")
    static let 裏加工 = 工程型(name: "裏加工", code: "P015C")
    static let 研磨 = 工程型(name: "研磨", code: "P016")
    static let ルーター = 工程型(name: "ルーター", code: "P017")
    static let タップ = 工程型(name: "タップ", code: "P017B")
    static let シート貼り = 工程型(name: "シート貼り", code: "P017C")
    static let 印刷 = 工程型(name: "印刷", code: "P018")
    static let 表面仕上 = 工程型(name: "表面仕上", code: "P019")
    static let マスキング = 工程型(name: "マスキング", code: "P019A")
    static let 中塗り = 工程型(name: "中塗り", code: "P019B")
    static let 塗装 = 工程型(name: "塗装", code: "P020")
    static let 下処理 = 工程型(name: "下処理", code: "P020A")
    static let 乾燥炉 = 工程型(name: "乾燥炉", code: "P020B")
    static let プライマー = 工程型(name: "プライマー", code: "P020C")
    static let 外注 = 工程型(name: "外注", code: "P021")
    static let 拭き取り = 工程型(name: "拭き取り", code: "P022")
    static let 付属品準備 = 工程型(name: "付属品準備", code: "P024")
    static let 組立 = 工程型(name: "組立", code: "P026")
    static let 品質管理 = 工程型(name: "品質管理", code: "P026B")
    static let 発送 = 工程型(name: "発送", code: "P027")
    static let 経理 = 工程型(name: "経理", code: "P028")
}

// MARK: - 管理グループ
public let 管理グループ: [工程型] = 管理グループ1 + 管理グループ2
public let 管理グループ1: [工程型] = [
    .営業, .管理, .商品設計
]
public let 管理グループ2: [工程型] = [
    .原稿, .入力, .出力
]

public let 第1製造グループ: [工程型] = 第1製造グループ1 + 第1製造グループ2 + 第1製造グループ3
public let 第1製造グループ1: [工程型] = [
    .レーザー, .照合検査
]
public let 第1製造グループ2: [工程型] = [
    .フォーミング, .シャーリング, .プレーナー, .タレパン
]
public let 第1製造グループ3: [工程型] = [
    .腐蝕, .印刷, .版焼き, .腐蝕印刷, .エッチング
]

public let 第3製造グループ: [工程型] = 第3製造グループ1 + 第3製造グループ2 + 第3製造グループ3
public let 第3製造グループ1: [工程型] = [
    .立ち上がり, .立ち上がり_溶接
]
public let 第3製造グループ2: [工程型] = [
    .半田, .溶接
]
public let 第3製造グループ3: [工程型] = [
    .ボンド, .裏加工, .裏加工_溶接
]


