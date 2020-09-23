//
//  経理状態.swift
//  DataManager
//
//  Created by manager on 8/17/1 R.
//  Copyright © 1 Reiwa 四熊泰之. All rights reserved.
//

import Foundation

public enum 経理状態型 {
    case 未登録
    case 受注処理済
    case 売上処理済
    
    init?(_ text: String) {
        switch text {
        case "未登録":
            self = .未登録
        case "受注処理済":
            self = .受注処理済
        case "売上処理済":
            self = .売上処理済
        default:
            return nil
        }
    }
    
    public var text: String {
        switch self {
        case .未登録: return "未登録"
        case .受注処理済: return "受注処理済"
        case .売上処理済: return "売上処理済"
        }
    }
}

extension FileMakerRecord {
    func 経理状態(forKey key: String) -> 経理状態型? {
        guard let name = string(forKey: key) else { return nil }
        return 経理状態型(name)
    }
}
