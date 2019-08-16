//
//  社員.swift
//  DataManager
//
//  Created by manager on 2019/03/30.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

public var 全社員一覧 = [社員型]()

public struct 社員型 {
    /// 指定された文字列が社員コードとして使用可能かチェックする。実際に登録されたコードかどうかは確認しない
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
