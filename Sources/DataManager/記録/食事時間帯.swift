//
//  食事時間帯.swift
//  DataManager
//
//  Created by manager on 2020/10/27.
//

import Foundation

private let lock = NSRecursiveLock()

public struct 食事時間帯Data型: FileMakerSyncData {
    public static let layout = "DataAPI_9"
    public static var db: FileMakerDB { .system }

    public var 提供パターン: String
    public var 食事グループ: String
    public var 開始時間: Time
    public var 終了時間: Time
    
    public var memoryFootPrint: Int { 4 * 16 } // てきとう

    init(提供パターン: String, 食事グループ: String, 開始時間: Time, 終了時間: Time) {
        self.提供パターン = 提供パターン
        self.食事グループ = 食事グループ
        self.開始時間 = 開始時間
        self.終了時間 = 終了時間
    }
    
    public init(_ record: FileMakerRecord) throws {
        func makeError(_ key: String) -> Error { record.makeInvalidRecordError(name: "食事時間帯", mes: key) }
        guard let 提供パターン = record.string(forKey: "提供パターン") else { throw makeError("提供パターン") }
        guard let 食事グループ = record.string(forKey: "食事グループ") else { throw makeError("食事グループ") }
        guard let 開始時間 = record.time(forKey: "開始時間") else { throw makeError("開始時間") }
        guard let 終了時間 = record.time(forKey: "終了時間") else { throw makeError("終了時間") }
        self.init(提供パターン: 提供パターン, 食事グループ: 食事グループ, 開始時間: 開始時間, 終了時間: 終了時間)
    }
    
    public var fieldData: FileMakerFields {
        var data = FileMakerFields()
        data["提供パターン"] = 提供パターン
        data["食事グループ"] = 食事グループ
        data["開始時間"] = 開始時間.fmImportString
        data["終了時間"] = 終了時間.fmImportString
        return data
    }
}

public class 食事時間帯型: FileMakerSyncObject<食事時間帯Data型> {
//    public var 提供パターン: String {
//        get { data.提供パターン }
//        set { data.提供パターン = newValue }
//    }
//    
//    public var 食事グループ: String {
//        get { data.食事グループ }
//        set { data.食事グループ = newValue }
//    }
//    
//    public var 開始時間: Time {
//        get { data.開始時間 }
//        set { data.開始時間 = newValue }
//    }
//    
//    public var 終了時間: Time {
//        get { data.終了時間 }
//        set { data.終了時間 = newValue }
//    }
    
    init(提供パターン: String, 食事グループ: String, 開始時間: Time, 終了時間: Time) {
        super.init(食事時間帯Data型(提供パターン: 提供パターン, 食事グループ: 食事グループ, 開始時間: 開始時間, 終了時間: 終了時間))
    }
    required init(_ record: FileMakerRecord) throws { try super.init(record) }

    // MARK: - DB操作
    public func delete() throws {
        lock.lock(); defer { lock.unlock() }
        if try generic_delete() {
            食事時間帯キャッシュ型.shared.flush(提供パターン: self.提供パターン, 食事グループ: self.食事グループ)
        }
    }
    
    public func upload() throws {
        lock.lock(); defer { lock.unlock() }
        if try generic_insert() {
            食事時間帯キャッシュ型.shared.flush(提供パターン: self.提供パターン, 食事グループ: self.食事グループ)
        }
    }
    
    public func synchronize() throws {
        lock.lock(); defer { lock.unlock() }
        if try generic_synchronize() {
            食事時間帯キャッシュ型.shared.flush(提供パターン: self.提供パターン, 食事グループ: self.食事グループ)
        }
    }

    // MARK: - DB検索
    static func find(query: FileMakerQuery) throws -> [食事時間帯型] {
        lock.lock(); defer { lock.unlock() }
        return try find(querys: [query])
    }
    
    public static func find(提供パターン: String? = nil, 食事グループ: String? = nil) throws -> [食事時間帯型] {
        var query = FileMakerQuery()
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
