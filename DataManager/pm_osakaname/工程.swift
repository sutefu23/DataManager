//
//  工程.swift
//  DataManager
//
//  Created by manager on 2019/02/05.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

let processmap : [String : 工程型] = {
    var map = [String : 工程型]()
    for process in 工程型.allCases {
        map[process.code] = process
        map[process.caption] = process
    }
    map["レーザー・ウォーター"] = .レーザー
    return map
}()

public enum 工程型 : Int, Comparable, CaseIterable {
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
    case 腐食 = 70
    case オブジェ = 80
    case フォーミング = 90
    case シャーリング = 91
    case プレーナー = 92
    case タレパン = 93
    case 加工 = 100
    case 仕上 = 110
    case 切文字 = 120
    case 溶接 = 130
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
    case 外注 = 210
    case 拭き取り = 220
    case 附属品準備 = 240
    case 組立検品 = 260
    case 発送 = 270
    case 経理 = 280
    
    init?(_ number:Int) {
        self.init(rawValue: number)
    }
    
    var number : Int { return self.rawValue }
    
    public init?(_ code:String) {
        guard let process = processmap[code.uppercased()] else { return nil }
        self = process
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
        case .腐食 : return "P007"
        case .オブジェ : return "P008"
        case .フォーミング: return "P009"
        case .シャーリング : return "P009A"
        case .プレーナー : return "P009B"
        case .タレパン : return "P009C"
        case .加工 : return "P010"
        case .仕上 : return "P011"
        case .切文字 : return "P012"
        case .溶接 : return "P013"
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
        case .外注 : return "P021"
        case .拭き取り : return "P022"
        case .附属品準備 : return "P024"
        case .組立検品 : return "P026"
        case .発送 : return "P027"
        case .経理 : return "P028"
        }
        
    }
    
    public var caption : String {
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
        case .加工: return "加工"
        case .フォーミング: return "フォーミング"
        case .タレパン: return "タレパン"
        case .表面仕上: return "表面仕上"
        case .仕上: return "表面仕上"
        case .印刷: return "印刷"
        case .腐食: return "腐食"
        case .外注: return "外注"
        case .塗装: return "塗装"
        case .発送: return "発送"
        case .経理: return "経理"
        case .オブジェ: return "オブジェ"
        case .研磨: return "研磨"
        case .ルーター: return "ルーター"
        case .拭き取り: return "拭き取り"
        case .附属品準備: return "附属品準備"
        case .組立検品: return "組立検品"
        case .レーザー溶接: return "レーザー溶接"
        case .タップ: return "タップ"
        case .裏加工: return "裏加工"
        }
    }
        
    public static func <(left:工程型, right:工程型) -> Bool {
        return left.rawValue < right.rawValue
    }
}

extension FileMakerRecord {
    func 工程(forKey key:String) -> 工程型? {
        guard let code = string(forKey: key) else { return nil }
        return 工程型(code)
    }
}
