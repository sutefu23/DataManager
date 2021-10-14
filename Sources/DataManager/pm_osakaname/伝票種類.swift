//
//  伝票種類.swift
//  DataManager
//
//  Created by manager on 2019/02/04.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

public enum 伝票種類型: Int, DMStringEnum, Comparable {
    public static let stringMap: [String : 伝票種類型] = makeStringMap()
    
    case 箱文字 = 1
    case 切文字 = 2
    case 加工 = 3
    case エッチング = 4
    case 外注 = 5
    case 校正 = 6
    case 赤伝 = 7
    
    public var description: String { return fmString }

    var fmString: String {
        switch self {
        case .箱文字: return "箱文字"
        case .切文字: return "切文字"
        case .エッチング: return "エッチング"
        case .加工: return "加工"
        case .外注: return "外注"
        case .校正: return "校正"
        case .赤伝: return "赤伝"
        }
    }
    
    #if os(Linux) || os(Windows)
    #else
    public var color: DMColor {
        switch self{
        case .箱文字:
            return DMColor.green.dark(brightnessRatio: 0.5)
        case .切文字:
            return .blue
        case .加工:
            return DMColor.orange.dark(brightnessRatio: 0.5)
        case .エッチング:
            return DMColor.magenta.dark(brightnessRatio: 0.75)
        case .外注, .校正, .赤伝:
            return DMColor.black
        }
    }
    #endif
    
    public static func <(left: 伝票種類型, right: 伝票種類型) -> Bool { left.rawValue < right.rawValue }
}

extension FileMakerRecord {
    func 伝票種類(forKey key: String) -> 伝票種類型? {
        guard let name = string(forKey: key) else { return nil }
        return 伝票種類型(name)
    }
}
