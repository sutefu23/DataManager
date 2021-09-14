//
//  用途.swift
//  DataManager
//
//  Created by manager on 2021/07/01.
//

import Foundation

public struct 用途型: Equatable {
    public static let 天板 = 用途型(用途コード: "Y001", 用途名: "天板")
    public static let 底板 = 用途型(用途コード: "Y002", 用途名: "底板")
    public static let 中板 = 用途型(用途コード: "Y003", 用途名: "中板")
    public static let 作直 = 用途型(用途コード: "Y100", 用途名: "作直")
    public static let 部署内やり直し = 用途型(用途コード: "Y101", 用途名: "部署内やり直し")

    public var 用途コード: String
    public var 用途名: String
    
    init(用途コード: String, 用途名: String) {
        self.用途コード = 用途コード
        self.用途名 = 用途名
    }

    public init?(用途名: String?) {
        guard let name = 用途名, let yoto = map2[name] else { return nil }
        self = yoto
    }
}

private let list: [用途型] = [.天板, .中板, .底板]

private let map: [String: 用途型] = {
    var map: [String: 用途型] = [:]
    for yoto in list {
        map[yoto.用途コード] = yoto
    }
    return map
}()

private let map2: [String: 用途型] = {
    var map: [String: 用途型] = [:]
    for yoto in list {
        map[yoto.用途名] = yoto
    }
    return map
}()

extension FileMakerRecord {
    func 用途(forKey key: String) -> 用途型? {
        guard let code = self.string(forKey: key) else { return nil }
        return map[code]
    }
}
