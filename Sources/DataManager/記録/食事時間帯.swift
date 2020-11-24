//
//  食事時間帯.swift
//  DataManager
//
//  Created by manager on 2020/10/27.
//

import Foundation

private let lock = NSRecursiveLock()

struct 食事時間帯Data型: Equatable {
    static let dbName = "DataAPI_9"
    var 提供パターン: String
    var 食事グループ: String
    var 開始時間: Time
    var 終了時間: Time
    
    init(提供パターン: String, 食事グループ: String, 開始時間: Time, 終了時間: Time) {
        self.提供パターン = 提供パターン
        self.食事グループ = 食事グループ
        self.開始時間 = 開始時間
        self.終了時間 = 終了時間
    }
    
    init?(_ record: FileMakerRecord) {
        guard let 提供パターン = record.string(forKey: "提供パターン"),
              let 食事グループ = record.string(forKey: "食事グループ"),
              let 開始時間 = record.time(forKey: "開始時間"),
              let 終了時間 = record.time(forKey: "終了時間") else { return nil }
        self.init(提供パターン: 提供パターン, 食事グループ: 食事グループ, 開始時間: 開始時間, 終了時間: 終了時間)
    }
    
    var fieldData: FileMakerQuery {
        var data = FileMakerQuery()
        data["提供パターン"] = 提供パターン
        data["食事グループ"] = 食事グループ
        data["開始時間"] = 開始時間.fmImportString
        data["終了時間"] = 終了時間.fmImportString
        return data
    }
}

public class 食事時間帯型 {
    var original: 食事時間帯Data型?
    var data: 食事時間帯Data型
    
    public internal(set) var recordId: String?

    public var 提供パターン: String {
        get { data.提供パターン }
        set { data.提供パターン = newValue }
    }
    
    public var 食事グループ: String {
        get { data.食事グループ }
        set { data.食事グループ = newValue }
    }
    
    public var 開始時間: Time {
        get { data.開始時間 }
        set { data.開始時間 = newValue }
    }
    
    public var 終了時間: Time {
        get { data.終了時間 }
        set { data.終了時間 = newValue }
    }
    
    init(提供パターン: String, 食事グループ: String, 開始時間: Time, 終了時間: Time) {
        self.data = 食事時間帯Data型(提供パターン: 提供パターン, 食事グループ: 食事グループ, 開始時間: 開始時間, 終了時間: 終了時間)
    }
    
    init?(_ record: FileMakerRecord) {
        guard let data = 食事時間帯Data型(record) else { return nil }
        self.data = data
        self.original = data
        self.recordId = record.recordID
    }

    public var isChanged: Bool { original != data }

    // MARK: - DB操作
    public func delete() throws {
        guard let recordID = self.recordId else { return }
        lock.lock(); defer { lock.unlock() }
        let db = FileMakerDB.system
        try db.delete(layout: 食事時間帯Data型.dbName, recordId: recordID)
        self.recordId = nil
        食事時間帯キャッシュ型.shared.flush(提供パターン: self.提供パターン, 食事グループ: self.食事グループ)
    }
    
    public func upload() {
        let data = self.data.fieldData
        lock.lock(); defer { lock.unlock() }
        let db = FileMakerDB.system
        let _ = try? db.insert(layout: 食事時間帯Data型.dbName, fields: data)
        食事時間帯キャッシュ型.shared.flush(提供パターン: self.提供パターン, 食事グループ: self.食事グループ)
    }
    
    public func synchronize() throws {
        if !isChanged { return }
        let data = self.data.fieldData
        lock.lock(); defer { lock.unlock() }
        
        let db = FileMakerDB.system
        if let recordId = self.recordId {
            try db.update(layout: 食事時間帯Data型.dbName, recordId: recordId, fields: data)
        } else {
            self.recordId = try db.insert(layout: 食事時間帯Data型.dbName, fields: data)
        }
        食事時間帯キャッシュ型.shared.flush(提供パターン: self.提供パターン, 食事グループ: self.食事グループ)
    }

    // MARK: - DB検索
    
    static func find(query: FileMakerQuery) throws -> [食事時間帯型] {
        lock.lock(); defer { lock.unlock() }
        let db = FileMakerDB.system
        let list: [FileMakerRecord]
        if query.isEmpty {
            list = try db.fetch(layout: 食事時間帯Data型.dbName)
        } else {
            list = try db.find(layout: 食事時間帯Data型.dbName, query: [query])
        }
        return list.compactMap { 食事時間帯型($0) }
    }
    
    public static func find(提供パターン: String? = nil, 食事グループ: String? = nil) throws -> [食事時間帯型] {
        var query = [String: String]()
        if let number = 提供パターン {
            query["提供パターン"] = "==\(number)"
        }
        if let number = 食事グループ {
            query["食事グループ"] = "==\(number)"
        }
        return try find(query: query)
    }

    #if !os(tvOS)
    public static func backup(from: Day) throws {
        let list = try 食事時間帯型.find(query: [:])
        let gen = TableGenerator<食事時間帯型>()
            .string("提供パターン") { $0.提供パターン }
            .string("食事グループ") { $0.食事グループ }
            .time("開始時間") { $0.開始時間 }
            .time("終了時間") { $0.終了時間 }
        try gen.share(list, format: .excel(header: true), dir: "backup", title: "食事時間帯.csv")
    }
    #endif
}

// MARK: - キャッシュ
class 食事時間帯キャッシュ型 {
    struct 食事時間帯キャッシュKey: Hashable {
        let 提供パターン: String
        let 食事グループ: String
    }
    
    static let shared = 食事時間帯キャッシュ型()
    var expireTime: TimeInterval = 1*60*60 // 1時間
    private let lock = NSLock()
    private var cache: [食事時間帯キャッシュKey: (有効期限: Date, 食事時間帯: 食事時間帯型)] = [:]

    func 現在食事時間帯(提供パターン: String, 食事グループ: String) throws -> 食事時間帯型? {
        let key = 食事時間帯キャッシュKey(提供パターン: 提供パターン, 食事グループ: 食事グループ)
        guard let object = try 食事時間帯型.find(提供パターン: 提供パターン, 食事グループ: 食事グループ).first else { return nil }
        let expire = Date(timeIntervalSinceNow: self.expireTime)
        lock.lock()
        cache[key] = (expire, object)
        lock.unlock()
        return object
    }

    func キャッシュ食事時間帯(提供パターン: String, 食事グループ: String) throws -> 食事時間帯型? {
        let key = 食事時間帯キャッシュKey(提供パターン: 提供パターン, 食事グループ: 食事グループ)
        lock.lock()
        let data = self.cache[key]
        lock.unlock()
        if let data = data, Date() <= data.有効期限 {
            return data.食事時間帯
        }
        return try self.現在食事時間帯(提供パターン: 提供パターン, 食事グループ: 食事グループ)
    }

    func flush(提供パターン: String, 食事グループ: String) {
        let key = 食事時間帯キャッシュKey(提供パターン: 提供パターン, 食事グループ: 食事グループ)
        lock.lock()
        cache[key] = nil
        lock.unlock()
    }
    
    func flushAllCache() {
        lock.lock()
        self.cache.removeAll()
        lock.unlock()
    }
}
