//
//  工程.swift
//  DataManager
//
//  Created by manager on 2019/02/05.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

/*
let stateMap : [String : 工程型] = {
    var map = [String : 工程型]()
    for state in 工程型.allCases {
        map[state.code] = state
        map[state.description] = state
    }
    map["レーザー・ウォーター"] = .レーザー
    map["アクリル"] = .レーザー（アクリル）
    map["アクリル（レーザー）"] = .レーザー（アクリル）
    map["組立・検品"] = .組立検品
    map["照合・検査"] = .照合検査
    map["ルーターカット"] = .ルーター
    map["附属品準備"] = .付属品準備
    map["腐食"] = .腐蝕
    map["タップ"] = .タップ
    map["洗い場"] = .表面仕上
    map["検査"] = .照合検査
    return map
}()

public enum 工程型 : Int, Comparable, CaseIterable, CustomStringConvertible, Hashable, Codable {
    case 営業 = 10
    case 校正 = 20
    case 管理 = 30
    case 設計 = 32
    case 原稿 = 40
    case 出力 = 42
    case 入力 = 50
    case レーザー = 60
    case レーザー（アクリル） = 61
    case 照合検査 = 62
    case 腐蝕 = 70
    case オブジェ = 80
    case フォーミング = 90
    case シャーリング = 91
    case プレーナー = 92
    case タレパン = 93
    case 加工 = 100
    case 仕上 = 110
    case 切文字 = 120
    case 溶接 = 130
    case 立ち上がり_溶接 = 131
    case 裏加工_溶接 = 133
    case 立ち上がり = 140
    case 半田 = 150
    case レーザー溶接 = 152
    case 裏加工 = 153
    case 研磨 = 160
    case ルーター = 170
    case タップ = 172
    case 印刷 = 180
    case 表面仕上 = 190
    case 塗装 = 200
    case 乾燥炉 = 202
    case 外注 = 210
    case 拭き取り = 220
    case 付属品準備 = 240
    case 組立検品 = 260
    case 品質管理 = 261
    case 発送 = 270
    case 経理 = 280
    
    init?(_ number:Int) {
        self.init(rawValue: number)
    }
    
    var number : Int { return self.rawValue }
    
    public init?<S : StringProtocol>(_ code:S) {
        guard let state = stateMap[code.uppercased()] else {
            return nil
        }
        self = state
    }
    
    public var code : String {
        switch self {
        case .営業 : return "P001"
        case .校正 : return "P002"
        case .管理 : return "P003"
        case .設計 : return "P003B"
        case .原稿 : return "P004"
        case .出力 : return "P004B"
        case .入力 : return "P005"
        case .レーザー: return "P006"
        case .レーザー（アクリル）: return "P006A"
        case .照合検査 : return "P006B"
        case .腐蝕 : return "P007"
        case .オブジェ : return "P008"
        case .フォーミング: return "P009"
        case .シャーリング : return "P009A"
        case .プレーナー : return "P009B"
        case .タレパン : return "P009C"
        case .加工 : return "P010"
        case .仕上 : return "P011"
        case .切文字 : return "P012"
        case .溶接 : return "P013"
        case .立ち上がり_溶接: return "P013A"
        case .裏加工_溶接: return "P013C"
        case .立ち上がり : return "P014"
        case .半田 : return "P015"
        case .レーザー溶接 : return "P015B"
        case .裏加工: return "P015C"
        case .研磨 : return "P016"
        case .ルーター : return "P017"
        case .タップ : return "P017B"
        case .印刷 : return "P018"
        case .表面仕上 : return "P019"
        case .塗装 : return "P020"
        case .乾燥炉: return "P020B"
        case .外注 : return "P021"
        case .拭き取り : return "P022"
        case .付属品準備 : return "P024"
        case .組立検品 : return "P026"
        case .品質管理 : return "P026B"
        case .発送 : return "P027"
        case .経理 : return "P028"
        }
    }
    
    public var description : String {
        switch self {
        case .シャーリング: return "シャーリング"
        case .プレーナー: return "プレーナー"
        case .営業: return "営業"
        case .校正: return "校正"
        case .管理: return "管理"
        case .設計: return "設計"
        case .原稿: return "原稿"
        case .出力: return "出力"
        case .入力: return "入力"
        case .レーザー: return "レーザー"
        case .レーザー（アクリル） : return "レーザー（アクリル）"
        case .照合検査: return "照合検査"
        case .切文字: return "切文字"
        case .立ち上がり: return "立ち上がり"
        case .半田: return "半田"
        case .溶接: return "溶接"
        case .立ち上がり_溶接: return "立ち上がり（溶接)"
        case .裏加工_溶接: return "裏加工(溶接)"
        case .加工: return "加工"
        case .フォーミング: return "フォーミング"
        case .タレパン: return "タレパン"
        case .表面仕上: return "表面仕上"
        case .仕上: return "仕上"
        case .印刷: return "印刷"
        case .腐蝕: return "腐蝕"
        case .外注: return "外注"
        case .塗装: return "塗装"
        case .乾燥炉: return "乾燥炉"
        case .発送: return "発送"
        case .経理: return "経理"
        case .オブジェ: return "オブジェ"
        case .研磨: return "研磨"
        case .ルーター: return "ルーター"
        case .拭き取り: return "拭き取り"
        case .付属品準備: return "付属品準備"
        case .組立検品: return "組立"
        case .品質管理: return "品質管理"
        case .レーザー溶接: return "レーザー溶接"
        case .タップ: return "タップ(ルーター)"
        case .裏加工: return "裏加工"
        }
    }
        
    public static func <(left:工程型, right:工程型) -> Bool {
        return left.rawValue < right.rawValue
    }
    
}

 */
extension FileMakerRecord {
    func 工程(forKey key:String) -> 工程型? {
        guard let code = string(forKey: key) else { return nil }
        return 工程型(code)
    }
}

public struct 工程型 : Hashable, Comparable {
    let number : Int

    public init?(_ name: String) {
        if let state = 名称工程DB[name] {
            self.init(state.number)
        } else {
            self.init(code: name)
        }
    }

    init(_ number:Int) { self.number = number }
    
    init?(code: String) {
        var main : Int = 0
        var sub : Int = 0
        for (index, ch) in code.uppercased().enumerated() {
            if ch.isNumber {
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
    }
    
    public var description : String {
        return 工程名称DB[self] ?? ""
    }

    public func 作業時間(from:Date, to:Date) -> TimeInterval {
        let cal = カレンダー型[self]
        return cal.calcWorkTime(from: from, to: to)
    }

    public var code : String {
        let main = number / 100
        let sub = number % 100
        var str = "P"
        if main < 100 { str += "0" }
        if main < 10 { str += "0" }
        str += "\(main)"
        if sub > 0 {
            str += String(Character(UnicodeScalar(UInt8(sub+64))))
        }
        return str
    }
    
    public static func < (left:工程型, right:工程型) -> Bool { return left.number < right.number  }
}

class 工程名称DB型 {
    var map : [工程型 : String]
    var reversedMap : [String : 工程型]
    
    init() {
        var map : [工程型 : String] = [:]
        var map2 : [String : 工程型] = [
            "レーザー・ウォーター" : .レーザー,
            "アクリル" : .レーザー（アクリル）,
            "アクリル（レーザー）" : .レーザー（アクリル）,
            "組立・検品" : .組立,
            "照合・検査" : .照合検査,
            "ルーターカット" : .ルーター,
            "附属品準備" : .付属品準備,
            "腐食" : .腐蝕,
            "タップ" : .タップ,
            "洗い場" : .表面仕上,
            "検査" : .照合検査
        ]
        let db = FileMakerDB.pm_osakaname
        let list : [FileMakerRecord] = db.fetch(layout: "DataAPI_工程") ?? []
        for record in list {
            guard let code = record.string(forKey: "工程コード"), let state = 工程型(code: code), let name = record.string(forKey: "工程名") else { continue }
            map[state] = name
            map2[name] = state
        }
        self.map = map
        self.reversedMap = map2
    }
    
    subscript(_ state: 工程型) -> String? { return map[state] }
}

let 工程名称DB : 工程名称DB型 = 工程名称DB型()
var 名称工程DB : [String : 工程型] { 工程名称DB.reversedMap }

public extension 工程型 {
    static let 営業 = 工程型(code:"P001")!
    static let 校正 = 工程型(code:"P002")!
    static let 管理 = 工程型(code:"P003")!
    static let 設計 = 工程型(code:"P003B")!
    static let 原稿 = 工程型(code:"P004")!
    static let 出力 = 工程型(code:"P004B")!
    static let 入力 = 工程型(code:"P005")!
    static let レーザー = 工程型(code:"P006")!
    static let レーザー（アクリル） = 工程型(code:"P006A")!
    static let 照合検査 = 工程型(code:"P006B")!
    static let 腐蝕 = 工程型(code:"P007")!
    static let オブジェ = 工程型(code:"P008")!
    static let フォーミング = 工程型(code:"P009")!
    static let シャーリング = 工程型(code:"P009A")!
    static let プレーナー = 工程型(code:"P009B")!
    static let タレパン = 工程型(code:"P009C")!
    static let 加工 = 工程型(code:"P010")!
    static let 仕上 = 工程型(code:"P011")!
    static let 切文字 = 工程型(code:"P012")!
    static let 溶接 = 工程型(code:"P013")!
    static let 立ち上がり_溶接 = 工程型(code:"P013A")!
    static let 裏加工_溶接 = 工程型(code:"P013C")!
    static let 立ち上がり = 工程型(code:"P014")!
    static let 半田 = 工程型(code:"P015")!
    static let レーザー溶接 = 工程型(code:"P015B")!
    static let 裏加工 = 工程型(code:"P015C")!
    static let 研磨 = 工程型(code:"P016")!
    static let ルーター = 工程型(code:"P017")!
    static let タップ = 工程型(code:"P017B")!
    static let 印刷 = 工程型(code:"P018")!
    static let 表面仕上 = 工程型(code:"P019")!
    static let 塗装 = 工程型(code:"P020")!
    static let 乾燥炉 = 工程型(code:"P020B")!
    static let 外注 = 工程型(code:"P021")!
    static let 拭き取り = 工程型(code:"P022")!
    static let 付属品準備 = 工程型(code:"P024")!
    static let 組立 = 工程型(code:"P026")!
    static let 品質管理 = 工程型(code:"P026B")!
    static let 発送 = 工程型(code:"P027")!
    static let 経理 = 工程型(code:"P028")!
}
