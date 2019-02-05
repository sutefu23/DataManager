//
//  作業内容.swift
//  DataManager
//
//  Created by manager on 2019/02/05.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

public enum 作業内容型 {
    case 受取
    case 開始
    case 仕掛
    case 完了
    
    init?(code:String) {
        switch code.uppercased() {
        case "F500":
            self = .受取
        case "F1000":
            self = .開始
        case "F1500":
            self = .仕掛
        case "F2000":
            self = .完了
        default:
            return nil
        }
    }
    
    var code : String {
        switch self {
        case .受取: return "F500"
        case .開始: return "F1000"
        case .仕掛: return "F1500"
        case .完了: return "F2000"
        }
    }
    
    public var caption : String {
        switch self {
        case .受取: return "受取"
        case .開始: return "開始"
        case .仕掛: return "仕掛"
        case .完了: return "完了"
        }
    }
}

extension FileMakerRecord {
    func 作業内容(forKey key:String) -> 作業内容型? {
        guard let code = string(forKey: key) else { return nil }
        return 作業内容型(code:code)
    }
}
