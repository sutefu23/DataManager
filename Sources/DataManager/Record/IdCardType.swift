//
//  IDカード型.swift
//  DataManager
//
//  Created by manager on 2020/09/30.
//

import Foundation

private let lock = NSRecursiveLock()

public enum IDカード種類型: String, Hashable, CaseIterable {
    case マスタ
    case 予備
    case その他
}

extension FileMakerRecord {
    func IDカード種類(forKey key: String) -> IDカード種類型? {
        guard let str = self.string(forKey: key) else { return nil }
        return IDカード種類型(rawValue: str)
    }
}

public struct IDカードData型: FileMakerSyncData {
    public static let layout = "DataAPI_8"
    public static var db: FileMakerDB { .system }

    public var 社員番号: String
    public var カードID: String
    public var 種類: IDカード種類型
    public var 備考: String
    public var 食事グループ: String
    
    public var memoryFootPrint: Int { 5 * 16 } // てきとう

    init(社員番号: String, カードID: String, 種類: IDカード種類型, 備考: String, 食事グループ: String) {
        self.社員番号 = 社員番号
        self.カードID = カードID
        self.種類 = 種類
        self.備考 = 備考
        self.食事グループ = 食事グループ
    }
    
    public init(_ record: FileMakerRecord) throws {
        func makeError(_ key: String) -> Error { record.makeInvalidRecordError(name: "IDカード", mes: key) }
        guard let 社員番号 = record.string(forKey: "社員番号") else { throw makeError("社員番号") }
        guard let カードID = record.string(forKey: "カードID") else { throw makeError("カードID") }
        guard let 食事グループ = record.string(forKey: "食事グループ") else { throw makeError("食事グループ") }
        guard let 種類 = record.IDカード種類(forKey: "種類") else { throw makeError("種類") }
        self.社員番号 = 社員番号
        self.カードID = カードID
        self.種類 = 種類
        self.備考 = record.string(forKey: "備考") ?? ""
        self.食事グループ = 食事グループ
    }
    
    public var fieldData: FileMakerFields {
        var data = FileMakerFields()
        data["社員番号"] = 社員番号
        data["カードID"] = カードID
        data["種類"] = 種類.rawValue
        data["食事グループ"] = 食事グループ
        data["備考"] = 備考
        return data
    }
}

public class IDカード型: FileMakerSyncObject<IDカードData型> {
//    public var 社員番号: String {
//        get { data.社員番号 }
//        set { data.社員番号 = newValue }
//    }
//    public var カードID: String {
//        get { data.カードID }
//        set { data.カードID = newValue }
//    }
//
//    public var 種類: IDカード種類型 {
//        get { data.種類 }
//        set { data.種類 = newValue }
//    }
//    
//    public var 備考: String {
//        get { data.備考 }
//        set { data.備考 = newValue }
//    }
//    
//    public var 食事グループ: String {
//        get { data.食事グループ }
//        set { data.食事グループ = newValue }
//    }
    
    public init(社員番号: String, カードID: String, 種類: IDカード種類型, 備考: String, 食事グループ: String) {
        let data = IDカードData型(社員番号: 社員番号, カードID: カードID, 種類: 種類, 備考: 備考, 食事グループ: 食事グループ)
        super.init(data)
    }
    required init(_ record: FileMakerRecord) throws { try super.init(record) }

    // MARK: - DB操作
    public func delete() throws {
        lock.lock(); defer { lock.unlock() }
        if try generic_delete() {
            IDカードキャッシュ型.shared.flush(社員番号: self.社員番号)
        }
    }

    public func upload() throws {
        lock.lock(); defer { lock.unlock() }
        if try generic_insert() {
            IDカードキャッシュ型.shared.flush(社員番号: self.社員番号)
        }
    }
    
    public func synchronize() throws {
        lock.lock(); defer { lock.unlock() }
        if try generic_synchronize() {
            IDカードキャッシュ型.shared.flush(社員番号: self.社員番号)
        }
    }
    
    // MARK: - DB検索
    static func find(query: FileMakerQuery) throws -> [IDカード型] {
        lock.lock(); defer { lock.unlock() }
        return try find(querys: [query])
    }
    
    public static func find(社員番号: String? = nil, カードID: String? = nil) throws -> [IDカード型] {
        var query = FileMakerQuery()
        if let number = 社員番号 {
            query["社員番号"] = "==\(number)"
        }
        if let number = カードID {
            query["カードID"] = "==\(number)"
        }
        return try find(query: query)
    }
        
    #if !os(tvOS)
    public static func backup(from: Day) throws {
        let list = try IDカード型.find(query: [:])
        let gen = TableGenerator<IDカード型>()
            .string("社員番号") { $0.社員番号 }
            .string("食事グループ") { $0.食事グループ }
            .string("カードID") { $0.カードID }
            .string("種類") { $0.種類.rawValue }
            .string("備考") { $0.備考 }
        try gen.share(list, format: .excel(header: true), dir: "backup", title: "食事IDカード.csv")
    }
    #endif
}

// MARK: - キャッシュ
class IDカードキャッシュ型 {
    struct IDカードキャッシュKey: Hashable {
        let 社員番号: String
    }
    
    static let shared = IDカードキャッシュ型()
    var expireTime: TimeInterval = 1*60*60 // 1時間
    private let lock = NSLock()
    private var cache: [IDカードキャッシュKey: (有効期限: Date, IDカード: IDカード型)] = [:]

    func 現在IDカード(社員番号: String) throws -> IDカード型? {
        let key = IDカードキャッシュKey(社員番号: 社員番号)
        guard let object = try IDカード型.find(社員番号: 社員番号).first else { return nil }
        let expire = Date(timeIntervalSinceNow: self.expireTime)
        lock.lock()
        cache[key] = (expire, object)
        lock.unlock()
        return object
    }

    func キャッシュIDカード(社員番号: String) throws -> IDカード型? {
        let key = IDカードキャッシュKey(社員番号: 社員番号)
        lock.lock()
        let data = self.cache[key]
        lock.unlock()
        if let data = data, Date() <= data.有効期限 {
            return data.IDカード
        }
        return try self.現在IDカード(社員番号: 社員番号)
    }

    func flush(社員番号: String) {
        let key = IDカードキャッシュKey(社員番号: 社員番号)
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
