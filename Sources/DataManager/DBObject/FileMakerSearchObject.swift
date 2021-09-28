//
//  FileMakerSearchRecord.swift
//  DataManager
//
//  Created by 四熊泰之 on R 3/09/24.
//

import Foundation

/// 検索レコード
public protocol FileMakerSearchObject: FileMakerObject {
/// レコードId
    var recordId: FileMakerRecordID? { get }
    
    /// 指定されたレコードデータで初期化する
    init(_ record: FileMakerRecord) throws

    
    /// 全レコード読み出し
    static func fetchAll() throws -> [Self]
    /// 指定された検索条件で検索する
    static func find(query: FileMakerQuery) throws -> [Self]
    /// 指定された検索OR条件で検索する
    static func find(querys: [FileMakerQuery]) throws -> [Self]

    /// レコードを削除する
    func delete() throws -> FileMakerRecordID?
    /// レコードを更新する
    func update(_ data: FileMakerFields) throws
}

extension FileMakerSearchObject {
    public static var db: FileMakerDB { .pm_osakaname }

    public static func find(recordId: String) throws -> Self? {
        guard let record = try Self.db.find(layout: Self.layout, recordId: recordId) else { return nil }
        return try Self(record)
    }

    public static func fetchAll() throws -> [Self] {
        let list = try db.fetch(layout: layout)
        return list.compactMap { try? Self($0) }
    }

    public static func find(query: FileMakerQuery) throws -> [Self] {
        return try self.find(querys: [query])
    }

    public static func find(querys: [FileMakerQuery]) throws -> [Self] {
        let records: [FileMakerRecord] = try Self.db.execute { try basic_find(querys: querys, session: $0) }
        return try records.map { try Self($0) }
    }

    /// レコードを削除する
    public func delete() throws -> FileMakerRecordID? {
        guard let recordId = self.recordId else { return nil }
        try Self.db.delete(layout: Self.layout, recordId: recordId)
        return recordId
    }
    
    /// レコードを更新する
    public func update(_ data: FileMakerFields) throws {
        guard let recordId = self.recordId else { throw FileMakerError.update(message: "\(Self.name): レコードIDがnil") }
        try Self.db.update(layout: Self.layout, recordId: recordId, fields: data)
    }
}

public typealias FileMakerFields = FileMakerQuery
