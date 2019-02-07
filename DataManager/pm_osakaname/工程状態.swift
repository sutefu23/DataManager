//
//  工程状態.swift
//  DataManager
//
//  Created by manager on 2019/02/04.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

public enum 工程状態型 {
    case 通常
    case 保留
    case 校正中
    
    init?<T>(_ code: T) where T : StringProtocol {
        switch code {
        case "通常": self = .通常
        case "保留": self = .保留
        case "校正中": self = .校正中
        default: return nil
        }
    }

    public var descripton : String {
        switch self {
        case .通常 : return "通常"
        case .保留 : return "保留"
        case .校正中 : return "校正中"
        }
    }
}

extension FileMakerRecord {
    func 工程状態(forKey key:String) -> 工程状態型? {
        guard let name = string(forKey: key) else { return nil }
        return 工程状態型(name)
    }
}
