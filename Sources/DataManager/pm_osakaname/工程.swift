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
        return 工程名称DB[self] ?? ""
    }
    public var is製作工程: Bool { is製作工程Set.contains(self) } 

    public func 作業時間(from: Date?, to: Date?) -> TimeInterval? {
        guard let from = from, let to = to else { return nil }
        return TimeInterval(工程: self, 作業開始: from, 作業完了: to)
    }
    public func 作業時間(from: Date, to: Date) -> TimeInterval {
        return TimeInterval(工程: self, 作業開始: from, 作業完了: to)
    }
    public func 推定始業時間(of day: Day) -> Time {
        return 標準カレンダー.勤務時間(工程: self, 日付: day).始業
    }
    public func 推定終業時間(of day: Day) -> Time {
        return 標準カレンダー.勤務時間(工程: self, 日付: day).終業
    }
    public var isValid: Bool { 工程名称DB.codeMap[self] != nil }
    public var code: String { return 工程名称DB.codeMap[self]! }
    
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
}

class 工程名称DB型 {
    var map: [工程型: String]
    var reversedMap: [String: 工程型]
    var codeMap: [工程型: String]
    
    init() {
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
            "検査" : .照合検査
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
    
    subscript(_ state: 工程型) -> String? { return map[state] }
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
    工程名称DB = 工程名称DB型()
}

private(set) var 工程名称DB: 工程名称DB型 = 工程名称DB型()
var 名称工程DB: [String: 工程型] { 工程名称DB.reversedMap }

public extension 工程型 {
    static let 工場工程一覧: [工程型] = [
        .営業, .校正, .管理,
        .原稿, .出力, .フィルム, .入力,
        .レーザー, .レーザー（アクリル）, .照合検査,
        .腐蝕, .印刷,
        .フォーミング, .シャーリング, .プレーナー, .タレパン,
        .加工, .仕上, .オブジェ,
        .切文字,
        .溶接, .立ち上がり_溶接, .裏加工_溶接, .レーザー溶接,
        .立ち上がり, .半田, .裏加工,
        .ルーター, .タップ,
        .研磨, .表面仕上,
        .塗装, .乾燥炉, .拭き取り,
        .外注, .付属品準備, .組立,
        .品質管理, .発送,
    ]
    
    static let 営業 = 工程型(code: "P001")!
    static let 校正 = 工程型(code: "P002")!
    static let 管理 = 工程型(code: "P003")!
    static let 設計 = 工程型(code: "P003B")!
    static let 原稿 = 工程型(code: "P004")!
    static let 出力 = 工程型(code: "P004B")!
    static let フィルム = 工程型(code: "P004C")!
    static let 入力 = 工程型(code: "P005")!
    static let レーザー = 工程型(code: "P006")!
    static let レーザー（アクリル） = 工程型(code: "P006A")!
    static let 照合検査 = 工程型(code: "P006B")!
    static let 腐蝕 = 工程型(code: "P007")!
    static let オブジェ = 工程型(code: "P008")!
    static let フォーミング = 工程型(code: "P009")!
    static let シャーリング = 工程型(code: "P009A")!
    static let プレーナー = 工程型(code: "P009B")!
    static let タレパン = 工程型(code: "P009C")!
    static let 加工 = 工程型(code: "P010")!
    static let 仕上 = 工程型(code: "P011")!
    static let 切文字 = 工程型(code: "P012")!
    static let 溶接 = 工程型(code: "P013")!
    static let 立ち上がり_溶接 = 工程型(code: "P013A")!
    static let 裏加工_溶接 = 工程型(code: "P013C")!
    static let 立ち上がり = 工程型(code: "P014")!
    static let 半田 = 工程型(code: "P015")!
    static let レーザー溶接 = 工程型(code: "P015A")!
    static let ボンド = 工程型(code: "P015B")!
    static let 裏加工 = 工程型(code: "P015C")!
    static let 研磨 = 工程型(code: "P016")!
    static let ルーター = 工程型(code: "P017")!
    static let タップ = 工程型(code: "P017B")!
    static let 印刷 = 工程型(code: "P018")!
    static let 表面仕上 = 工程型(code: "P019")!
    static let 塗装 = 工程型(code: "P020")!
    static let 乾燥炉 = 工程型(code: "P020B")!
    static let 外注 = 工程型(code: "P021")!
    static let 拭き取り = 工程型(code: "P022")!
    static let 付属品準備 = 工程型(code: "P024")!
    static let 組立 = 工程型(code: "P026")!
    static let 品質管理 = 工程型(code: "P026B")!
    static let 発送 = 工程型(code: "P027")!
    static let 経理 = 工程型(code: "P028")!
}

// MARK: - 管理グループ
public let 管理グループ: [工程型] = 管理グループ1 + 管理グループ2
public let 管理グループ1: [工程型] = [
    .営業, .管理
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
    .腐蝕, .印刷
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
