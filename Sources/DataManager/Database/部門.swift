//
//  部門.swift
//  DataManager
//
//  Created by manager on 2020/05/19.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

public enum 部門型: Int {
    case 本社 = 1
    case 東京 = 2
    case 大阪 = 3
    
    init?<S: StringProtocol>(code: S) {
        switch code {
        case "001": self = .本社
        case "002": self = .東京
        case "003": self = .大阪
        default: return nil
        }
    }
    
    public var 部門コード: String { "00\(self.rawValue)" }
}

extension FileMakerRecord {
    func 部門(forKey key: String) -> 部門型? {
        guard let code = self.string(forKey: key) else { return nil }
        return 部門型(code: code)
    }
}
