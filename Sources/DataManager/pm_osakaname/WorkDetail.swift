//
//  作業内容.swift
//  DataManager
//
//  Created by manager on 2019/02/05.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

let statemap: [String: 作業内容型] = {
    var map = [String: 作業内容型]()
    for state in 作業内容型.allCases {
        map[state.code] = state
        map[state.description] = state
    }
    return map
}()

public enum 作業内容型: Int, CaseIterable, CustomStringConvertible, Comparable, Codable {
    case 受取 = 0
    case 開始 = 1
    case 仕掛 = 2
    case 完了 = 3
    
    public init?<S : StringProtocol>(_ code: S) {
        guard let state = statemap[code.uppercased()] else { return nil }
        self = state
    }
    
    public var code: String {
        switch self {
        case .受取: return "F500"
        case .開始: return "F1000"
        case .仕掛: return "F1500"
        case .完了: return "F2000"
        }
    }
    
    public var description: String {
        switch self {
        case .受取: return "受取"
        case .開始: return "開始"
        case .仕掛: return "仕掛"
        case .完了: return "完了"
        }
    }
    
    public static func < (left: 作業内容型, right: 作業内容型) -> Bool {
        return left.rawValue < right.rawValue
    }
}

extension FileMakerRecord {
    func 作業内容(forKey key: String) -> 作業内容型? {
        guard let code = string(forKey: key)?.toJapaneseNormal else { return nil }
        return 作業内容型(code)
    }
}
