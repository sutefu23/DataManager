//
//  伝票種類.swift
//  DataManager
//
//  Created by manager on 2019/02/04.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

public enum 伝票種類型 {
    case 箱文字
    case 切文字
    case エッチング
    case 加工
    case 外注
    case 校正
    
    init?<T>(_ name:T) where T : StringProtocol {
        switch name {
        case "箱文字": self = .箱文字
        case "切文字": self = .切文字
        case "エッチング": self = .エッチング
        case "加工": self = .加工
        case "外注": self = .外注
        case "校正": self = .校正
        default:
            return nil
        }
    }
    
    var fmString : String {
        switch self {
        case .箱文字 : return "箱文字"
        case .切文字 : return "切文字"
        case .エッチング : return "エッチング"
        case .加工 : return "加工"
        case .外注 : return "外注"
        case .校正 : return "校正"
        }
    }
}

extension FileMakerRecord {
    func 伝票種類(forKey key:String) -> 伝票種類型? {
        guard let name = string(forKey: key) else { return nil }
        return 伝票種類型(name)
    }
}
