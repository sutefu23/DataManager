//
//  伝票状態.swift
//  DataManager
//
//  Created by manager on 2019/02/04.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

public enum 伝票状態型 {
    case 未製作
    case 製作中
    case 発送済
    case キャンセル
    
    init?<T>(_ code: T) where T : StringProtocol {
        switch code {
        case "未製作": self = .未製作
        case "製作中": self = .製作中
        case "発送済": self = .発送済
        case "キャンセル": self = .キャンセル
        default: return nil
        }
    }

}

extension FileMakerRecord {
    func 伝票状態(forKey key:String) -> 伝票状態型? {
        guard let name = string(forKey: key) else { return nil }
        return 伝票状態型(name)
    }
}
