//
//  食事要求型.swift
//  DataManager
//
//  Created by 四熊泰之 on R 2/09/26.
//

import Foundation

private let serialQueue: OperationQueue = {
   let queue = OperationQueue()
    queue.maxConcurrentOperationCount = 1
    queue.qualityOfService = .utility
    return queue
}()

public enum 食事要求状態型: String {
    case 未処理
    case 受取待ち
    case 受渡済み
}

struct 食事要求Data型: Equatable {
    static let dbName = "DataAPI_7"
    
    var 社員番号: String
    var メニューID: メニューID型
    var 要求状態: 食事要求状態型
    
    var 修正情報タイムスタンプ: Date
    
    init(社員番号: String, メニューID: メニューID型, 要求状態: 食事要求状態型) {
        self.社員番号 = 社員番号
        self.メニューID = メニューID
        self.要求状態 = 要求状態
        self.修正情報タイムスタンプ = Date().rounded()
    }
    
    init?(_ record: FileMakerRecord) {
        guard let 社員番号 = record.string(forKey: "社員番号"),
              let メニューID = record.string(forKey: "メニューID"),
              let 状態str = record.string(forKey: "要求状態"),
              let 要求状態 = 食事要求状態型(rawValue: 状態str) else { return nil }
        self.社員番号 = 社員番号
        self.メニューID = メニューID
        self.要求状態 = 要求状態
        self.修正情報タイムスタンプ = record.date(forKey: "修正情報タイムスタンプ") ?? Date().rounded()
    }
    
    var fieldData: FileMakerQuery {
        var data = FileMakerQuery()
        data["社員番号"] = self.社員番号
        data["メニューID"] = self.メニューID
        data["要求状態"] = self.要求状態.rawValue
        return data
    }
}

public class 食事要求型 {
    var original: 食事要求Data型?
    var data: 食事要求Data型
    
    public internal(set) var recordId: String?
    
    public var 社員番号: String {
        get { data.社員番号 }
        set { data.社員番号 = newValue }
    }
    public var メニューID: メニューID型 {
        get { data.メニューID }
        set { data.メニューID = newValue }
    }
    public var 要求状態: 食事要求状態型 {
        get { data.要求状態 }
        set { data.要求状態 = newValue }
    }
    
    public var 修正情報タイムスタンプ: Date { data.修正情報タイムスタンプ }
    
    init(社員番号: String, メニューID: メニューID型, 要求状態: 食事要求状態型) {
        self.data = 食事要求Data型(社員番号: 社員番号, メニューID: メニューID, 要求状態: 要求状態)
    }
    
    init?(_ record: FileMakerRecord) {
        guard let data = 食事要求Data型(record) else { return nil }
        self.data = data
        self.original = data
        self.recordId = record.recordID
    }

    public var isChanged: Bool { original != data }

    // MARK: - DB操作
    public func delete() throws {
        guard let recordID = self.recordId else { return }
        var result: Error? = nil
        let operation = BlockOperation {
            do {
                let db = FileMakerDB.system
                try db.delete(layout: 食事要求Data型.dbName, recordId: recordID)
                self.recordId = nil
                //                資材使用記録キャッシュ型.shared.flush(伝票番号: self.伝票番号)
            } catch {
                result = error
            }
        }
        serialQueue.addOperation(operation)
        operation.waitUntilFinished()
        if let error = result { throw error }
    }

    public func upload() {
        let data = self.data.fieldData
        serialQueue.addOperation {
            let db = FileMakerDB.system
            let _ = try? db.insert(layout: 食事要求Data型.dbName, fields: data)
            //                資材使用記録キャッシュ型.shared.flush(伝票番号: self.伝票番号)
        }
    }

    public func synchronize() throws {
        if !isChanged { return }
        let data = self.data.fieldData
        var result: Result<String, Error>!
        let operation = BlockOperation {
            let db = FileMakerDB.system
            do {
                if let recordID = self.recordId {
                    try db.update(layout: 食事要求Data型.dbName, recordId: recordID, fields: data)
                    result = .success(recordID)
                } else {
                    let recordID = try db.insert(layout: 食事要求Data型.dbName, fields: data)
                    result = .success(recordID)
                }
//                資材使用記録キャッシュ型.shared.flush(伝票番号: self.伝票番号)
            } catch {
                result = .failure(error)
            }
        }
        serialQueue.addOperation(operation)
        operation.waitUntilFinished()
        self.recordId = try result.get()
    }

    // MARK: - DB検索
    static func find(query: FileMakerQuery) throws -> [食事要求型] {
        if query.isEmpty { return [] }
        var result: Result<[FileMakerRecord], Error>!
        let operation = BlockOperation {
            let db = FileMakerDB.system
            do {
                let list: [FileMakerRecord] = try db.find(layout: 食事要求Data型.dbName, query: [query])
                result = .success(list)
            } catch {
                result = .failure(error)
            }
        }
        serialQueue.addOperation(operation)
        operation.waitUntilFinished()
        let list = try result.get().compactMap { 食事要求型($0) }
        return list
    }

    public static func find(社員ID: String? = nil, メニューID: String? = nil) throws -> [食事要求型] {
        var query = FileMakerQuery()
        if let menuID = メニューID {
            query["メニューID"] = "==\(menuID)"
        }
        if let staffID = 社員ID {
            query["社員番号"] = "==\(staffID)"
        }
        assert(!query.isEmpty)
        return try find(query: query)
    }
    
    public static func find(提供日: Day, 種類: 食事種類型) throws -> [食事要求型] {
        let query: FileMakerQuery = ["提供日": 提供日.fmString, "種類": 種類.rawValue]
        return try find(query: query)
    }

    public static func find(提供開始日: Day) throws -> [食事要求型] {
        let query: FileMakerQuery = ["提供日": ">=\(提供開始日.fmString)"]
        return try find(query: query)
    }
}
