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
    /// 管理するデータ型
    public typealias RecordData = R
    /// サーバー上のデータ
    var original: RecordData?
    /// 現在のデータ
    var data: RecordData
    /// レコードID
    public internal(set) var recordId: FileMakerRecordID?

    /// メモリの使用量の概算を返す
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
    
    /// 指定されたデータで初期化する
    init(_ data: RecordData, recordId: FileMakerRecordID? = nil) {
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
    
    /// 指定されたレコードで初期化する
    required public init(_ record: FileMakerRecord) throws {
        guard let recordId = record.recordId else { throw FileMakerError.invalidData(message: "レコードIDがnil") }
        self.recordId = recordId
        let data = try RecordData(record)
        self.data = data
        self.original = data
    }

    /// dataに対するインターフェースを動的に生成する（dataがclassの場合に有効化される）
    public subscript<T>(dynamicMember keyPath: ReferenceWritableKeyPath<RecordData, T>) -> T {
        get { self.data[keyPath: keyPath] }
        set { self.data[keyPath: keyPath] = newValue }
    }

    /// dataに対するインターフェースを動的に生成する（dataがstructの場合に有効化される）
    public subscript<T>(dynamicMember keyPath: WritableKeyPath<RecordData, T>) -> T {
        get { self.data[keyPath: keyPath] }
        set { self.data[keyPath: keyPath] = newValue }
    }

    /// サーバーにアップロードすべきものがある場合trueを返す
    public var isChanged: Bool { original != data }
    
    /// レコードを削除する
    @discardableResult
    func generic_delete() throws -> Bool {
        guard let recordId = self.recordId else { return false }
        let db = RecordData.db
        try db.delete(layout: RecordData.layout, recordId: recordId)
        self.recordId = nil
        self.original = nil
        return true
    }

    /// レコードを新規登録し、登録に成功するとtrueを返す
    @discardableResult
    func generic_insert() throws -> Bool {
        guard self.recordId == nil else { return false }
        let db = RecordData.db
        let data = self.data.fieldData
        self.recordId = try db.insert(layout: RecordData.layout, fields: data)
        self.original = self.data
        return true
    }

    /// レコードの内容を更新し、。更新に成功するとtrueを返す。
    @discardableResult
    func generic_update() throws -> Bool {
        guard let recordId = self.recordId else { return false }
        let db = RecordData.db
        let data = self.data.fieldData
        try db.update(layout: RecordData.layout, recordId: recordId, fields: data)
        self.original = self.data
        return true
    }
    
    /// レコードが未踏胃録なら登録し、登録済みなら更新する。成功するとtrueを返す
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
    /// テーブルのあるDBファイル
    static var db: FileMakerDB { get }
    /// テーブル操作用のレイアウト名
    static var layout: String { get }
    
    /// 指定レコードで初期化する
    init(_ record: FileMakerRecord) throws
    /// 出力用のデータ
    var fieldData: FileMakerFields { get }
}

/// systemデータベースファイル上のテーブルのレコードの管理メカニズム
public protocol DMSystemRecordManager: FileMakerImportRecord {
    associatedtype RecordData: DMSystemRecordData
    init(_ record: FileMakerRecord) throws
    static var queue: OperationQueue { get }
}

extension DMSystemRecordManager {
    /// テーブルのあるDBファイル
    public static var db: FileMakerDB { RecordData.db }
    /// テーブル操作用のレイアウト名
    public static var layout: String { RecordData.layout }

    public static var queue: OperationQueue { DataManagerController.shared.serialQueue }
}
