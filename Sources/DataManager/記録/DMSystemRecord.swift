//
//  DMSystemRecord.swift
//  DataManager
//
//  Created by manager on 2020/03/25.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

/// systemデータベースファイル上のテーブルのレコードのデータとその状態
@dynamicMemberLookup
public class DMSystemRecord<R: DMSystemRecordData>: DMSystemRecordManager {
    public typealias RecordData = R
    var original: RecordData?
    var data: RecordData
    public internal(set) var recordId: String?
    
    public var memoryFootPrint: Int {
        var result = data.memoryFootPrint * 2 + 16
        if let size = original?.memoryFootPrint {
            result += size
        }
        if let size = recordId?.memoryFootPrint {
            result += size
        }
        return result
    }
    
    init(_ data: RecordData, recordId: String? = nil) {
        if let recordId = recordId {
            self.data = data
            self.original = data
            self.recordId = recordId
        } else {
            self.data = data
            self.original = nil
            self.recordId = nil
        }
    }
    
    required public init(_ record: FileMakerRecord) throws {
        guard let recordId = record.recordId else { throw FileMakerError.invalidData(message: "レコードIDがnil") }
        self.recordId = recordId
        let data = try RecordData(record)
        self.data = data
        self.original = data
    }

    public subscript<T>(dynamicMember keyPath: ReferenceWritableKeyPath<RecordData, T>) -> T {
        get { self.data[keyPath: keyPath] }
        set { self.data[keyPath: keyPath] = newValue }
    }

    public subscript<T>(dynamicMember keyPath: WritableKeyPath<RecordData, T>) -> T {
        get { self.data[keyPath: keyPath] }
        set { self.data[keyPath: keyPath] = newValue }
    }

    public var isChanged: Bool { original != data }
    
    @discardableResult
    func generic_delete() throws -> Bool {
        guard let recordId = self.recordId else { return false }
        let db = RecordData.db
        try db.delete(layout: RecordData.layout, recordId: recordId)
        self.recordId = nil
        self.original = nil
        return true
    }

    @discardableResult
    func generic_insert() throws -> Bool {
        guard self.recordId == nil else { return false }
        let db = RecordData.db
        let data = self.data.fieldData
        self.recordId = try db.insert(layout: RecordData.layout, fields: data)
        self.original = self.data
        return true
    }

    @discardableResult
    func generic_update() throws -> Bool {
        guard let recordId = self.recordId else { return false }
        let db = RecordData.db
        let data = self.data.fieldData
        try db.update(layout: RecordData.layout, recordId: recordId, fields: data)
        self.original = self.data
        return true
    }
    
    @discardableResult
    func generic_synchronize() throws -> Bool {
        if self.recordId == nil {
            return try generic_insert()
        } else {
            return try generic_update()
        }
    }
}

/// systemデータベースファイル上のテーブルのレコードのデータ
public protocol DMSystemRecordData: DMCacheElement, Equatable {
    static var db: FileMakerDB { get }
    static var layout: String { get }
    init(_ record: FileMakerRecord) throws
    var fieldData: FileMakerQuery { get }
}
extension DMSystemRecordData {
    public static var db: FileMakerDB { .system }
}

/// systemデータベースファイル上のテーブルのレコードの管理メカニズム
public protocol DMSystemRecordManager: DMCacheElement {
    associatedtype RecordData: DMSystemRecordData
    init(_ record: FileMakerRecord) throws
    static var queue: OperationQueue { get }
    
    static func fetchAll() throws -> [Self]
    static func find(query: FileMakerQuery) throws -> [Self]
    static func find(querys: [FileMakerQuery]) throws -> [Self]
    
    var recordId: String? { get }
}

extension DMSystemRecordManager {
    public static var queue: OperationQueue { DataManagerController.shared.serialQueue }

    public static func fetchAll() throws -> [Self] {
        return try find(querys: [])
    }

    public static func find(query: FileMakerQuery) throws -> [Self] {
        return try find(querys: [query])
    }

    public static func find(querys: [FileMakerQuery]) throws -> [Self] {
        let records: [FileMakerRecord]
        if querys.isEmpty || querys.allSatisfy({ $0.isEmpty} ) {
            records = try RecordData.db.fetch(layout: RecordData.layout)
        } else {
            records = try RecordData.db.find(layout: RecordData.layout, query: querys)
        }
        return try records.compactMap { try Self($0) }
    }
}
