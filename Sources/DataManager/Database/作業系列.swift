//
//  作業系列.swift
//  DataManager
//
//  Created by manager on 2019/12/03.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

private var seriesCache: [String: 作業系列型] = [:]
private let lock = NSLock()

func flush作業系列Cache() {
    lock.lock()
    seriesCache.removeAll()
    lock.unlock()
}

public struct 作業系列型: Hashable {
    public static func 登録チェック() {
        let _ = 作業系列型.null
        let _ = 作業系列型.gx
        let _ = 作業系列型.ex
        let _ = 作業系列型.hp
        let _ = 作業系列型.water
        let _ = 作業系列型.ボルト1
        let _ = 作業系列型.ボルト2
    }

    public static let null = 作業系列型(系列コード: "S000")!
    public static let gx = 作業系列型(系列コード: "S001")!
    public static let ex = 作業系列型(系列コード: "S002")!
    public static let hp = 作業系列型(系列コード: "S003")!
    public static let water = 作業系列型(系列コード: "S004")!
    public static let ボルト1 = 作業系列型(系列コード: "S011")!
    public static let ボルト2 = 作業系列型(系列コード: "S012")!
    
    public let 系列コード: String
    public let 名称: String
    public let 備考: String
    
    init(_ record: FileMakerRecord) throws {
        func makeError(_ key: String) -> Error { record.makeInvalidRecordError(name: "作業系列", mes: key) }
        guard let 系列コード = record.string(forKey: "系列コード") else { throw makeError("系列コード") }
        guard let 名称 = record.string(forKey: "名称") else { throw makeError("名称") }
        guard let 備考 = record.string(forKey: "備考") else { throw makeError("備考") }
        self.系列コード = 系列コード
        self.名称 = 名称
        self.備考 = 備考
    }
    public init?(系列コード: String) {
        if 系列コード.isEmpty { return nil }
        let code = 系列コード.uppercased()
        lock.lock()
        defer { lock.unlock() }
        if let cache = seriesCache[code] {
            self = cache
            return
        }
        guard let series = try? 作業系列型.find(系列コード: code) else { return nil }
        seriesCache[code] = series
        self = series
    }
    
    public static func == (left: 作業系列型, right: 作業系列型) -> Bool {
        return left.系列コード == right.系列コード
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(系列コード)
    }
}

extension 作業系列型 {
    static let dbName = "DataAPI_9"
    
    public static func find(系列コード: String) throws -> 作業系列型? {
        let db = FileMakerDB.pm_osakaname
        let list: [FileMakerRecord] = try db.find(layout: 作業系列型.dbName, query: [["系列コード": 系列コード]])
        return try list.map { try 作業系列型($0) }.first
    }
}
