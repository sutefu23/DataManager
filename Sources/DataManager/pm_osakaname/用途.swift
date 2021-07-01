//
//  用途.swift
//  DataManager
//
//  Created by manager on 2021/07/01.
//

import Foundation

public struct 用途型 {
    public var 用途コード: String
    public var 用途名: String
}

private let list: [用途型] = [
    用途型(用途コード: "Y001", 用途名: "天板"),
    用途型(用途コード: "Y002", 用途名: "底板"),
    用途型(用途コード: "Y003", 用途名: "中板"),
]

private let map: [String: 用途型] = {
    var map: [String: 用途型] = [:]
    for yoto in list {
        map[yoto.用途コード] = yoto
    }
    return map
}()

extension FileMakerRecord {
    func 用途(forKey key: String) -> 用途型? {
        guard let code = self.string(forKey: key) else { return nil }
        return map[code]
    }
}
