//
//  社員.swift
//  DataManager
//
//  Created by manager on 2019/03/30.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

public struct 社員型 {
    public static func isValid社員コード(_ code:String) -> Bool {
        var code = code.uppercased()
        guard let firstCode = code.first else { return false }
        if firstCode.isNumber == false {
            guard firstCode == "H" else { return false }
            code.remove(at: code.startIndex)
        }
        guard let num = Int(code) else { return false }
        return num > 0 && num < 1000
    }
}
