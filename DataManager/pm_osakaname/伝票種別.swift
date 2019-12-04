//
//  伝票種別.swift
//  DataManager
//
//  Created by manager on 2019/11/28.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

public enum 伝票種別型 {
    case 通常
    case クレーム
    case 再製
    
    init?<T>(_ code: T) where T : StringProtocol {
        switch code {
        case "":
            self = .通常
        case "クレーム":
            self = .クレーム
        case "作直":
            self = .再製
        default:
            return nil
        }
    }
    
    public var label : String {
        switch self {
        case .通常:
            return ""
        case .クレーム:
            return "クレーム"
        case .再製:
            return "作直"
        }
    }
}

