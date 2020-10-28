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

public enum IDカード種類型: String, Hashable {
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

struct IDカードData型: Equatable {
    static let dbName = "DataAPI_8"
    
    var 社員番号: String
    var カードID: String
    var 種類: IDカード種類型
    var 備考: String
    var 食事グループ: String
    
    init(社員番号: String, カードID: String, 種類: IDカード種類型, 備考: String, 食事グループ: String) {
        self.社員番号 = 社員番号
        self.カードID = カードID
        self.種類 = 種類
        self.備考 = 備考
        self.食事グループ = 食事グループ
    }
    
    init?(_ record: FileMakerRecord) {
        guard let 社員番号 = record.string(forKey: "社員番号"),
              let カードID = record.string(forKey: "カードID"),
              let 食事グループ = record.string(forKey: "食事グループ"),
              let 種類 = record.IDカード種類(forKey: "種類") else { return nil }
        self.社員番号 = 社員番号
        self.カードID = カードID
        self.種類 = 種類
        self.備考 = record.string(forKey: "備考") ?? ""
        self.食事グループ = 食事グループ
    }
    
    var fieldData: FileMakerQuery {
        var data = FileMakerQuery()
        data["社員番号"] = 社員番号
        data["カードID"] = カードID
        data["種類"] = 種類.rawValue
        data["備考"] = 備考
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

    public var 種類: IDカード種類型 {
        get { data.種類 }
        set { data.種類 = newValue }
    }
    
    public var 備考: String {
        get { data.備考 }
        set { data.備考 = newValue }
    }
    
    public var 食事グループ: String {
        get { data.食事グループ }
        set { data.食事グループ = newValue }
    }
    
    init(社員番号: String, カードID: String, 種類: IDカード種類型, 備考: String, 食事グループ: String) {
        self.data = IDカードData型(社員番号: 社員番号, カードID: カードID, 種類: 種類, 備考: 備考, 食事グループ: 食事グループ)
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
