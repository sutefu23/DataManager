//
//  作業系列.swift
//  DataManager
//
//  Created by manager on 2019/12/03.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

public struct 作業系列型: Hashable {
    public static var 全作業系列: [作業系列型] {
        lock.lock(); defer { lock.unlock() }
        if let cache = 全作業系列Cache { return cache }
        guard let list = try? 作業系列Data型.fetchAll() else { return [] }
        list.forEach { 作業系列キャッシュ.regist($0, forKey: $0.系列コード) }
        let result = list.map { 作業系列型($0) }
        全作業系列Cache = result
        return result
    }
    
    public static var 外注系列一覧: [会社コード型 : [作業系列型]] {
        lock.lock(); defer { lock.unlock() }
        if let cache = 外注系列一覧Cache { return cache }
        let list = 全作業系列
        if 全作業系列Cache == nil { return [:] } // DBアクセス失敗
        var map: [会社コード型 : [作業系列型]] = [:]
        for series in list {
            guard let info = series.外注情報 else { continue }
            if var list = map[info.会社コード] {
                list.append(series)
                map[info.会社コード] = list
            } else {
                map[info.会社コード] = [series]
            }
        }
        外注系列一覧Cache = map
        return map
    }
    
    public static func 登録チェック() {
        let _ = 作業系列型.null
        let _ = 作業系列型.gx
        let _ = 作業系列型.ex
        let _ = 作業系列型.hp
        let _ = 作業系列型.water
        let _ = 作業系列型.ボルト1
        let _ = 作業系列型.ボルト2
        let _ = 作業系列型.塗装外注
        let _ = 作業系列型.メッキ外注
        let _ = 作業系列型.その他外注
    }
    // レーザー
    public static let null = 作業系列型(系列コード: "S000")!
    public static let gx = 作業系列型(系列コード: "S001")!
    public static let ex = 作業系列型(系列コード: "S002")!
    public static let hp = 作業系列型(系列コード: "S003")!
    public static let water = 作業系列型(系列コード: "S004")!
    // 付属品準備
    public static let ボルト1 = 作業系列型(系列コード: "S011")!
    public static let ボルト2 = 作業系列型(系列コード: "S012")!
    // 外注
    public static let 塗装外注 = 作業系列型(系列コード: "S021")!
    public static let メッキ外注 = 作業系列型(系列コード: "S022")!
    public static let その他外注 = 作業系列型(系列コード: "S023")!

    private let data: 作業系列Data型
    public var 系列コード: String { data.系列コード }
    public var 名称: String { data.名称 }
    public var 備考: String { data.備考 }
    public var 外注情報: (社名: String, 会社コード: String, 作業内容: String)? { data.外注情報 }

    public var recordId: FileMakerRecordID? { data.recordId }

    public init?(系列コード: String) {
        if 系列コード.isEmpty { return nil }
        let code = 系列コード.uppercased()
        guard let data = try? 作業系列キャッシュ.find(code) else { return nil }
        self.data = data
    }
    
    init(_ data: 作業系列Data型) {
        self.data = data
    }
    
    public static func == (left: 作業系列型, right: 作業系列型) -> Bool {
        return left.data == right.data
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(data)
    }
}
private let lock = NSRecursiveLock()
private var 全作業系列Cache: [作業系列型]? = nil
private var 外注系列一覧Cache: [会社コード型 : [作業系列型]]? = nil

// MARK: -
let 作業系列キャッシュ = DMDBCache<String, 作業系列Data型>(lifeSpan: 4*60*60, nilCache: true) {
    return try 作業系列Data型.find(系列コード: $0)
}

class 作業系列Data型: FileMakerSearchObject, DMCacheElement, Hashable {
    static let db: FileMakerDB = .pm_osakaname
    static let layout: String = "DataAPI_9"

    let memoryFootPrint: Int
    let 系列コード: String
    let 名称: String
    
    // [会社コード,作業内容]
    let 備考: String

    let 外注情報: (社名: String, 会社コード: String, 作業内容: String)?

    let recordId: FileMakerRecordID?

    required init(_ record: FileMakerRecord) throws {
        func makeError(_ key: String) -> Error { record.makeInvalidRecordError(name: "作業系列", mes: key) }
        guard let 系列コード = record.string(forKey: "系列コード") else { throw makeError("系列コード") }
        guard let 名称 = record.string(forKey: "名称") else { throw makeError("名称") }
        guard let 備考 = record.string(forKey: "備考") else { throw makeError("備考") }
        self.recordId = record.recordId
        self.系列コード = 系列コード
        self.名称 = 名称
        self.memoryFootPrint = 系列コード.memoryFootPrint + 名称.memoryFootPrint + 備考.memoryFootPrint + recordId.memoryFootPrint

        var scanner = DMScanner(備考, normalizedFullHalf: true, skipSpaces: true)
        if let (カッコ前, カッコ内) = scanner.scanParen("[", "]") {
            let cols = カッコ内.csvColumns
            if cols.count >= 3 {
                let 社名 = String(cols[0])
                let 会社コード = String(cols[1])
                let 作業内容 = String(cols[2])
                self.外注情報 = (社名, 会社コード, 作業内容)
                self.備考 = カッコ前
                return
            }
        }
        self.備考 = 備考
        self.外注情報 = nil
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
    
    static func == (left: 作業系列Data型, right: 作業系列Data型) -> Bool {
        return left === right
    }
    
    static func find(系列コード: String) throws -> 作業系列Data型? {
        return try self.find(query: ["系列コード": 系列コード]).first
    }
}
