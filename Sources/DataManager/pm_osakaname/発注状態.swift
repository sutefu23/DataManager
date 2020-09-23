//
//  発注状態.swift
//  DataManager
//
//  Created by manager on 2020/03/19.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

public enum 発注状態型: CustomStringConvertible {
    case 未処理
    case 発注待ち
    case 発注済み
    case 納品書待ち
    case 納品済み
    case 処理済み
    
    init?(data: String) {
        switch data {
        case "未処理":
            self = .未処理
        case "発注待ち":
            self = .発注待ち
        case "発注済み":
            self = .発注済み
        case "納品書待ち":
            self = .納品書待ち
        case "納品済み":
            self = .納品済み
        case "処理済み":
            self = .処理済み
        default:
            return nil
        }
    }
    
    public var description: String { return data }
    
    public var data: String {
        switch self {
        case .未処理: return "未処理"
        case .発注待ち: return "発注待ち"
        case .発注済み: return "発注済み"
        case .納品書待ち: return "納品書待ち"
        case .納品済み: return "納品済み"
        case .処理済み: return "処理済み"
        }
    }
}

extension FileMakerRecord {
    func 発注状態(forKey key: String) -> 発注状態型? {
        guard let data = self.string(forKey: key) else { return nil }
        return 発注状態型(data: data)
    }
}
