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

public struct 社員型 : Hashable {
    
    public let 社員番号 : Int
    public let 社員名称 : String
    public var 社員コード : String {
        if 社員番号 < 10 { return "H00\(社員番号)" }
        if 社員番号 < 100 { return "H0\(社員番号)" }
        return "H\(社員番号)"
    }
    
    public init(社員番号:Int, 社員名称:String) {
        self.社員番号 = 社員番号
        self.社員名称 = 社員名称
    }
    
    public init?(社員コード:String) {
        guard let num = calc社員番号(社員コード) else { return nil }
        self.社員番号 = num
        self.社員名称 = 社員コード
    }
    
    public static func ==(left:社員型, right:社員型) -> Bool {
        return left.社員番号 == right.社員番号
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.社員番号)
    }

}
