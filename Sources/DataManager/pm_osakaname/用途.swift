//
//  用途.swift
//  DataManager
//
//  Created by manager on 2021/07/01.
//

import Foundation

public struct 用途型: Hashable {
    public static let 天板 = 用途型(用途コード: "Y001", 用途名: "天板")
    public static let 底板 = 用途型(用途コード: "Y002", 用途名: "底板")
    public static let 中板 = 用途型(用途コード: "Y003", 用途名: "中板")
    public static let 作直 = 用途型(用途コード: "Y100", 用途名: "作直")
    public static let 部署内やり直し = 用途型(用途コード: "Y101", 用途名: "部署内やり直し")

    public var 用途コード: String { data.用途コード }
    public var 用途名: String { data.用途名 }
    private let data: 用途Data型
    
    init(用途コード: String, 用途名: String) {
        self.data = 用途Data型(用途コード: 用途コード, 用途名: 用途名).regist()
    }

    public init?(用途名: String?) {
        guard let name = 用途名, let yoto = map2[name] else { return nil }
        self.data = yoto.data
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

private final class 用途Data型: DMLightWeightObject, DMLightWeightObjectProtocol {
    static let cache = LightWeightStorage<用途Data型>()

    let 用途コード: String
    let 用途名: String
    
    init(用途コード: String, 用途名: String) {
        self.用途コード = 用途コード
        self.用途名 = 用途名
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(用途コード)
        hasher.combine(用途名)
    }
    
    static func == (left: 用途Data型, right: 用途Data型) -> Bool {
        if left === right { return true }
        return left.用途コード == right.用途コード && left.用途名 == right.用途名
    }
}

extension FileMakerRecord {
    func 用途(forKey key: String) -> 用途型? {
        guard let code = self.string(forKey: key) else { return nil }
        return map[code]
    }
}
