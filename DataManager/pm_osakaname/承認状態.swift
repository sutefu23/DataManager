//
//  承認状態.swift
//  DataManager
//
//  Created by 四熊泰之 on R 1/10/20.
//  Copyright © Reiwa 1 四熊泰之. All rights reserved.
//

import Foundation

public enum 承認状態型 {
    case 未承認
    case 承認済
    
    init?(_ text:String) {
        switch text {
        case "承認済":
            self = .承認済
        case "未承認":
            self = .未承認
        default:
            return nil
        }
    }
    
    public var text : String {
        switch self {
        case .承認済: return "承認済"
        case .未承認: return "未承認"
        }
    }
}

extension FileMakerRecord {
    func 承認状態(forKey key:String) -> 承認状態型? {
        guard let name = string(forKey: key) else { return nil }
        return 承認状態型(name)
    }
}
