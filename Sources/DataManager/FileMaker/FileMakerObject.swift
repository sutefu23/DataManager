//
//  FileMakerObject.swift
//  DataManager
//
//  Created by 四熊泰之 on R 3/09/25.
//

import Foundation

/// レコードの内容をオブジェクトしたものの共通インターフェース
/// recordIdは内容ではなく管理タグのため、共通インターフェースとしては含めない
public protocol FileMakerObject: DMCacheElement, DMLogger {
    static var db: FileMakerDB { get }
    static var layout: String { get }
    static var name: String { get }

    /// 全レコード読み出し
    static func fetchAll() throws -> [Self]
    /// 指定された検索条件で検索する
    static func find(query: FileMakerQuery) throws -> [Self]
    /// 指定された検索OR条件で検索する
    static func find(querys: [FileMakerQuery]) throws -> [Self]

    /// 指定された検索条件で検索する
    static func find(query: FileMakerQuery, session: FileMakerSession) throws -> [Self]
    /// 指定された検索OR条件で検索する
    static func find(querys: [FileMakerQuery], session: FileMakerSession) throws -> [Self]

    /// 指定されたレコードデータで初期化する
    init(_ record: FileMakerRecord) throws
}

extension FileMakerObject {
    public static var name: String { className(of: self) }
    
    /// ログシステムにレコードを記録する
    public func registLogData<T: DMRecordData>(_ data: T, _ level: DMLogLevel) {
        let data = DMFileMakerObjectRecord(db: Self.db, layout: Self.layout, data: data)
        DMLogSystem.shared.registLogData(data, level)
    }

    public static func fetchAll() throws -> [Self] {
        let list = try db.fetch(layout: layout)
        return list.compactMap { try? Self($0) }
    }

    public static func find(query: FileMakerQuery) throws -> [Self] {
        return try self.find(querys: [query])
    }

    public static func find(querys: [FileMakerQuery]) throws -> [Self] {
        let db = Self.db
        return try db.execute { try self.find(querys: querys, session: $0) }
    }

    public static func find(query: FileMakerQuery, session: FileMakerSession) throws -> [Self] {
        return try self.find(querys: [query], session: session)
    }

    public static func find(querys: [FileMakerQuery], session: FileMakerSession) throws -> [Self] {
        let records: [FileMakerRecord]
        if querys.isEmpty || querys.allSatisfy({ $0.isEmpty }) { // 条件指定が全くない
            records = try session.fetch(layout: Self.layout) // 全データ読み込み
        } else {
            records = try session.find(layout: Self.layout, query: querys) // 指定条件で検索
        }
        return try records.compactMap { try Self($0) }
    }
    
    public static func find(recordId: String) throws -> Self? {
        guard let record = try Self.db.find(layout: Self.layout, recordId: recordId) else { return nil }
        return try Self(record)
    }
}
