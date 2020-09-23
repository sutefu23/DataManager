//
//  入力区分.swift
//  DataManager
//
//  Created by manager on 2020/02/05.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

public enum 入力区分型 {
    case 通常入出庫
    case 棚卸
    case 数量調整
    
    public init?(_ name: String) {
        switch name {
        case "通常入出庫":
            self = .通常入出庫
        case "棚卸":
            self = .棚卸
        case "数量調整":
            self = .数量調整
        default:
            return nil
        }
    }
    
    public var name: String {
        switch self {
        case .通常入出庫: return "通常入出庫"
        case .棚卸: return "棚卸"
        case .数量調整: return "数量調整"
        }
    }
}

// MARK: - 保存
extension FileMakerRecord {
    func 入力区分(forKey key: String) -> 入力区分型? {
        guard let name = self.string(forKey: key) else { return nil }
        return 入力区分型(name)
    }
}
