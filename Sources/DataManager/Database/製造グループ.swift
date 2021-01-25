//
//  製造グループ.swift
//  DataManager
//
//  Created by manager on 2020/01/09.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

public enum 製造グループ型: CaseIterable {
    case 管理グループ
    case 第1製造グループ
    case 第2製造グループ
    case 第3製造グループ
    case 第4製造グループ
    case 第5製造グループ
    
    public var name: String {
        switch self {
        case .管理グループ:
            return "管理グループ"
        case .第1製造グループ:
            return "第１製造グループ"
        case .第2製造グループ:
            return "第２製造グループ"
        case .第3製造グループ:
            return "第３製造グループ"
        case .第4製造グループ:
            return "第４製造グループ"
        case .第5製造グループ:
            return "第５製造グループ"
        }
    }
    
    var members: [工程型] {
        switch self {
            case .管理グループ:
                return [.営業, .管理, .原稿, .入力, .出力, .フィルム, .設計]
            case .第1製造グループ:
                return [.レーザー, .照合検査, .フォーミング, .タレパン, .プレーナー, .レーザー（アクリル）, .印刷, .腐蝕, .版焼き, .腐蝕印刷, .エッチング, .付属品準備, .ルーター, .タップ, .シート貼り]
            case .第2製造グループ:
                return [.加工, .仕上, .切文字, .オブジェ]
            case .第3製造グループ:
                return [.立ち上がり, .立ち上がり_溶接, .裏加工, .裏加工_溶接, .半田, .溶接, .レーザー溶接, .ボンド]
            case .第4製造グループ:
                return [.研磨, .表面仕上, .中塗り, .塗装, .下処理, .乾燥炉, .拭き取り, .組立]
            case .第5製造グループ:
                return [.外注, .発送, .品質管理]
        }
    }
}

private let map: [工程型: 製造グループ型] = {
   var map = [工程型: 製造グループ型]()
    for group in 製造グループ型.allCases {
        for process in group.members {
            map[process] = group
        }
    }
    return map
}()

public extension 工程型 {
    var 製造グループ: 製造グループ型? { return map[self] }
}
