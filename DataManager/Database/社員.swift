//
//  社員.swift
//  DataManager
//
//  Created by manager on 2019/03/30.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

public var 全社員一覧 = [社員型]()

private func calc社員番号(_ code:String) -> Int? {
    var code = code.uppercased()
    guard let firstCode = code.first else { return nil }
    if firstCode.isNumber == false {
        guard firstCode == "H" else { return nil }
        code.remove(at: code.startIndex)
    }
    guard let num = Int(code), num >= 0 && num < 1000 else { return nil }
    return num
}

public struct 社員型 {
    /// 指定された文字列が社員コードとして使用可能かチェックする。実際に登録されたコードかどうかは確認しない
//    public static func isValid社員コード(_ code:String) -> Bool {
//        guard let num = calc社員番号(code) else { return false }
//        return num > 0 && num < 1000
//    }
    
    public let 社員番号 : Int
    public var 社員コード : String {
        if 社員番号 < 10 { return "H00\(社員番号)" }
        if 社員番号 < 100 { return "H0\(社員番号)" }
        return "H\(社員番号)"
    }
    
    public init?(社員コード:String) {
        guard let num = calc社員番号(社員コード) else { return nil }
        self.社員番号 = num
    }
}
