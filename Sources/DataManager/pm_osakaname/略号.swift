//
//  略号.swift
//  DataManager
//
//  Created by manager on 2019/02/07.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

public enum 略号型: UInt8, DMStringEnum, Comparable {
    public static let stringMap: [String : 略号型] = makeStringMap()
    
    case 外注 = 0
    case 腐食
    case 印刷
    case 看板
    case 組込
    case 工程写真
    case 先出し
    case 溶接
    case 半田
    case レーザー
    case フォーミング
    case 研磨
    case 塗装
    case 両面テープ
    case 色未定
    case 送り先未定
    case その他未定

    public static func < (lhs: 略号型, rhs: 略号型) -> Bool { lhs.rawValue < rhs.rawValue }
    
    public var description: String { code }
    
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
 
    #if os(Linux) || os(Windows)
    #else
    public var 表示色: DMColor {
        switch self {
        case .外注,. 腐食, .印刷, .看板, .組込, .工程写真, .先出し: return .black
        case .色未定, .送り先未定, .その他未定: return .red
        case .溶接, .半田, .レーザー, .フォーミング, .研磨, .塗装, .両面テープ: return .blue
        }
    }
    #endif
}

public struct 略号情報型: OptionSet {
    public typealias Element = 略号情報型
    
    public let rawValue: UInt32
    
    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }
    
    public init(_ line: String) {
        self.rawValue = 0
        for ch in line {
            if let item = 略号型(String(ch)) {
                self.insert(item)
            }
        }
    }
    
    public mutating func insert(_ option: 略号型) {
        self.insert(略号情報型(rawValue: 1 << option.rawValue))
    }
    
    public func contains(_ option: 略号型) -> Bool {
        return self.contains(略号情報型(rawValue: 1 << option.rawValue))
    }
    
    public var 略号一覧: [略号型] {
        return 略号型.allCases.filter { self.contains($0) }
    }
    
    public var code: String {
        var code = ""
        for item in 略号型.allCases {
            if self.contains(item) {
                code += item.code
            }
        }
        return code
    }
}

//public extension Sequence where Element == 略号型 {
//    var code: String {
//        return self.reduce("") { $0 + $1.code }
//    }
//}
