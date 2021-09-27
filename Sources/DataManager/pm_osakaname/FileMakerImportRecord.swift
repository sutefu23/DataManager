//
//  FileMakerImportRecord.swift
//  DataManager
//
//  Created by 四熊泰之 on R 3/09/24.
//

import Foundation

/// 入力レコード
public protocol FileMakerImportRecord: FileMakerObject {
/// レコードId
    var recordId: FileMakerRecordID? { get }

    /// レコードを削除する
    func delete() throws -> FileMakerRecordID?
    /// レコードを更新する
    func update(_ data: FileMakerFields) throws
}

extension FileMakerImportRecord {
    public static var db: FileMakerDB { .pm_osakaname }

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
