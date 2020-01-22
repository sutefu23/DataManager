//
//  略号.swift
//  DataManager
//
//  Created by manager on 2019/02/07.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

private let codeMap: [String: 略号型] = {
    var map = [String: 略号型]()
    for item in 略号型.allCases {
        map[item.code] = item
    }
    return map
}()

func make略号(_ line: String) -> Set<略号型> {
    var set = Set<略号型>()
    for ch in line {
        if let item = 略号型(String(ch)) {
            set.insert(item)
        }
    }
    return set
}

extension Set where Element  == 略号型 {
    public var code: String {
        var code = ""
        for item in self {
            code += item.code
        }
        return code
    }
}

public enum 略号型: CaseIterable {
    case 外注
    case 腐食
    case 印刷
    case 看板
    case 組込
    case 工程写真
    case 先出し
    case 色未定
    case 送り先未定
    case その他未定
    case 溶接
    case 半田
    case レーザー
    case フォーミング
    case 研磨
    case 塗装
    case 両面テープ
    
    public init?(_ code: String) {
        guard let item = codeMap[code] else { return nil }
        self = item
    }
    
    public var code: String {
        switch self {
        case .外注: return "外"
        case .腐食: return "腐"
        case .印刷: return "印"
        case .看板: return "看"
        case .組込: return "組"
        case .工程写真: return "写"
        case .先出し: return "先"
        case .色未定: return "色"
        case .送り先未定: return "送"
        case .その他未定: return "他"
        case .溶接: return "溶"
        case .半田: return "半"
        case .レーザー: return "レ"
        case .フォーミング: return "フ"
        case .研磨: return "研"
        case .塗装: return "塗"
        case .両面テープ: return "両"
        }
    }
    
}

public extension Sequence where Element == 略号型 {
    var code: String {
        return self.reduce("") { $0 + $1.code }
    }
}
