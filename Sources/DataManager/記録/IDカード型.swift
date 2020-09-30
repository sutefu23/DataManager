//
//  IDカード型.swift
//  DataManager
//
//  Created by manager on 2020/09/30.
//

import Foundation

private let serialQueue: OperationQueue = {
   let queue = OperationQueue()
    queue.maxConcurrentOperationCount = 1
    queue.qualityOfService = .utility
    return queue
}()

struct IDカードData型: Equatable {
    static let dbName = "DataAPI_8"
    
    var 社員番号: String
    var カードID: String
    
    init(社員番号: String, カードID: String) {
        self.社員番号 = 社員番号
        self.カードID = カードID
    }
    
    init?(_ record: FileMakerRecord) {
        guard let 社員番号 = record.string(forKey: "社員番号"),
              let カードID = record.string(forKey: "カードID") else { return nil }
        self.社員番号 = 社員番号
        self.カードID = カードID
    }
    
    var fieldData: FileMakerQuery {
        var data = FileMakerQuery()
        data["社員番号"] = 社員番号
        data["カードID"] = カードID
        return data
    }
}

public class IDカード型 {
    var original: IDカードData型?
    var data: IDカードData型
    
    public internal(set) var recordId: String?
    
    public var 社員番号: String {
        get { data.社員番号 }
        set { data.社員番号 = newValue }
    }
    public var カードID: String {
        get { data.カードID }
        set { data.カードID = newValue }
    }

    init(社員番号: String, カードID: String) {
        self.data = IDカードData型(社員番号: 社員番号, カードID: カードID)
    }
    
    init?(_ record: FileMakerRecord) {
        guard let data = IDカードData型(record) else { return nil }
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
                try db.delete(layout: IDカードData型.dbName, recordId: recordID)
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
            let _ = try? db.insert(layout: IDカードData型.dbName, fields: data)
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
                    try db.update(layout: IDカードData型.dbName, recordId: recordID, fields: data)
                    result = .success(recordID)
                } else {
                    let recordID = try db.insert(layout: IDカードData型.dbName, fields: data)
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
    static func find(query: FileMakerQuery) throws -> [IDカード型] {
        if query.isEmpty { return [] }
        var result: Result<[FileMakerRecord], Error>!
        let operation = BlockOperation {
            let db = FileMakerDB.system
            do {
                let list: [FileMakerRecord] = try db.find(layout: IDカードData型.dbName, query: [query])
                result = .success(list)
            } catch {
                result = .failure(error)
            }
        }
        serialQueue.addOperation(operation)
        operation.waitUntilFinished()
        let list = try result.get().compactMap { IDカード型($0) }
        return list
    }
    
    public static func find(社員番号: String? = nil, カードID: String? = nil) throws -> [IDカード型] {
        var query = [String: String]()
        if let number = 社員番号 {
            query["社員番号"] = "==\(number)"
        }
        if let number = カードID {
            query["カードID"] = "==\(number)"
        }
        return try find(query: query)
    }

}
