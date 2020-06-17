//
//  資材使用記録.swift
//  DataManager
//
//  Created by manager on 2020/04/16.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

private let serialQueue: OperationQueue = {
   let queue = OperationQueue()
    queue.maxConcurrentOperationCount = 1
    queue.qualityOfService = .utility
    return queue
}()

struct 資材使用記録Data型: Equatable {
    static let dbName = "DataAPI_5"
    var 登録日時: Date
    
    var 伝票番号: 伝票番号型
    var 工程: 工程型
    var 作業者: 社員型
    var 図番: 図番型
    var 表示名: String
    var 単価: Double?
    var 用途: String?
    var 使用量: String?
    var 使用面積: Double?
    var 分量: Double?
    var 金額: Double?
    
    init(登録日時: Date, 伝票番号: 伝票番号型, 工程: 工程型, 作業者: 社員型, 図番: 図番型, 表示名: String, 単価: Double?, 用途: String?, 使用量: String?, 使用面積: Double?, 分量: Double?, 金額: Double?) {
        self.登録日時 = 登録日時
        self.伝票番号 = 伝票番号
        self.工程 = 工程
        self.作業者 = 作業者
        self.図番 = 図番
        self.表示名 = 表示名
        self.単価 = 単価
        self.用途 = 用途
        self.使用量 = 使用量
        self.使用面積 = 使用面積
        self.金額 = 金額
        self.分量 = 分量
    }
    
    init?(_ record: FileMakerRecord) {
        guard let date = record.date(dayKey: "登録日", timeKey: "登録時間") else { return nil }
        guard let number = record.伝票番号(forKey: "伝票番号") else { return nil }
        guard let process = record.工程(forKey: "工程コード") else { return nil }
        guard let worker = record.社員(forKey: "作業者コード") else { return nil }
        guard let item = record.資材(forKey: "図番") else { return nil }
        
        self.登録日時 = date
        self.伝票番号 = number
        self.工程 = process
        self.作業者 = worker
        self.図番 = item.図番
        self.単価 = record.double(forKey: "単価") ?? item.単価
        self.使用量 = record.string(forKey: "使用量")
        self.用途 = record.string(forKey: "用途")
        self.使用面積 = record.double(forKey: "使用面積")
        self.金額 = record.double(forKey: "金額")
        if let title = record.string(forKey: "表示名"), !title.isEmpty {
            self.表示名 = title.全角半角日本語規格化()
        } else {
            self.表示名 = item.標準表示名
        }
        self.分量 = record.double(forKey: "分量")
    }
    
    var fieldData: FileMakerQuery {
        var data = FileMakerQuery()
        data["登録日"] = 登録日時.day.fmString
        data["登録時間"] = 登録日時.time.fmImportString
        data["伝票番号"] = "\(伝票番号.整数値)"
        data["工程コード"] = 工程.code
        data["作業者コード"] = 作業者.Hなし社員コード
        data["図番"] = 図番
        data["表示名"] = 表示名
        if let price = 単価 { data["単価"] = "\(price)" }
        data["使用量"] = 使用量
        data["用途"] = 用途
        if let value = self.分量 { data["分量"] = "\(value)" }
        if let area = 使用面積 { data["使用面積"] = "\(area)" }
        if let charge = self.金額 { data["金額"] = "\(charge)" }
        return data
    }
}

public class 資材使用記録型 {
    var original: 資材使用記録Data型?
    var data: 資材使用記録Data型
    public internal(set) var recordID: String?

    public var 登録日時: Date {
        get { data.登録日時 }
        set { data.登録日時 = newValue }
    }
    public var 伝票番号: 伝票番号型 {
        get { data.伝票番号 }
        set { data.伝票番号 = newValue }
    }
    public var 工程: 工程型 {
        get { data.工程 }
        set { data.工程 = newValue }
    }
    public var 作業者: 社員型 {
        get { data.作業者 }
        set { data.作業者 = newValue }
    }
    
    public var 表示名: String {
        get { data.表示名 }
        set { data.表示名 = newValue }
    }
    public var 図番: 図番型 {
        get { data.図番 }
        set { data.図番 = newValue }
    }
    public var 単価: Double? {
        get { data.単価 }
        set { data.単価 = newValue }
    }
    public var 用途: String? {
        get { data.用途 }
        set { data.用途 = newValue }
    }
    public var 使用量: String? {
        get { data.使用量 }
        set { data.使用量 = newValue }
    }
    public var 使用面積: Double? {
        get { data.使用面積 }
        set { data.使用面積 = newValue }
    }
    public var 金額: Double? {
        get { data.金額 }
        set { data.金額 = newValue }
    }
    public var 分量: Double? {
        get { data.分量 }
        set { data.分量 = newValue }
    }
    
    public init(登録日時: Date, 伝票番号: 伝票番号型, 工程: 工程型, 作業者: 社員型, 図番: 図番型, 表示名: String, 単価: Double?, 用途: String?, 使用量: String?, 使用面積: Double?, 分量: Double?, 金額: Double?) {
        self.data = 資材使用記録Data型(登録日時: 登録日時, 伝票番号: 伝票番号, 工程: 工程, 作業者: 作業者, 図番: 図番, 表示名: 表示名, 単価: 単価, 用途: 用途, 使用量: 使用量, 使用面積: 使用面積, 分量: 分量, 金額: 金額)
    }

    init?(_ record: FileMakerRecord) {
        guard let data = 資材使用記録Data型(record) else { return nil }
        self.data = data
        self.original = data
        self.recordID = record.recordID
    }
    
    public var isChanged: Bool { original != data }
    
    public func delete() throws {
        guard let recordID = self.recordID else { return }
        var result: Error? = nil
        let operation = BlockOperation {
            do {
                let db = FileMakerDB.system
                try db.delete(layout: 資材使用記録Data型.dbName, recordId: recordID)
                self.recordID = nil
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
            let _ = try? db.insert(layout: 資材使用記録Data型.dbName, fields: data)
            資材使用記録キャッシュ型.shared.flush(伝票番号: self.伝票番号)
        }
    }
    
    public func synchronize() throws {
        if !isChanged { return }
        let data = self.data.fieldData
        var result: Result<String, Error>!
        let operation = BlockOperation {
            let db = FileMakerDB.system
            do {
                if let recordID = self.recordID {
                    try db.update(layout: 資材使用記録Data型.dbName, recordId: recordID, fields: data)
                    result = .success(recordID)
                } else {
                    let recordID = try db.insert(layout: 資材使用記録Data型.dbName, fields: data)
                    result = .success(recordID)
                }
                資材使用記録キャッシュ型.shared.flush(伝票番号: self.伝票番号)
            } catch {
                result = .failure(error)
            }
        }
        serialQueue.addOperation(operation)
        operation.waitUntilFinished()
        self.recordID = try result.get()
    }

    static func find(query: FileMakerQuery) throws -> [資材使用記録型] {
        if query.isEmpty { return [] }
        var result: Result<[FileMakerRecord], Error>!
        let operation = BlockOperation {
            let db = FileMakerDB.system
            do {
                let list: [FileMakerRecord] = try db.find(layout: 資材使用記録Data型.dbName, query: [query])
                result = .success(list)
            } catch {
                result = .failure(error)
            }
        }
        serialQueue.addOperation(operation)
        operation.waitUntilFinished()
        let list = try result.get().compactMap { 資材使用記録型($0) }
        return list
    }
    public static func find(登録日:ClosedRange<Day>) throws -> [資材使用記録型] {
        var query = [String: String]()
        query["登録日"] = makeQueryDayString(登録日)
        return try find(query: query)
    }
    
    public static func find(伝票番号: 伝票番号型? = nil, 図番: 図番型? = nil) throws -> [資材使用記録型] {
        var query = [String: String]()
        if let order = 伝票番号 {
            query["伝票番号"] = "==\(order)"
        }
        if let item = 図番 {
            query["図番"] = "==\(item)"
        }
        return try find(query: query)
    }
    
    public static func find(伝票番号: 伝票番号型, 図番: 図番型, 表示名: String, 工程: 工程型? = nil) throws -> [資材使用記録型] {
        var query = FileMakerQuery()
        query["伝票番号"] = "==\(伝票番号)"
        query["図番"] = "==\(図番)"
        query["表示名"] = "==\(表示名)"
        if let 工程 = 工程 {
            query["工程コード"] = "==\(工程.code)"
        }
        return try find(query: query)
    }
    
    public static func find(伝票番号: 伝票番号型?, 工程: 工程型?, 登録期間: ClosedRange<Day>?) throws -> [資材使用記録型] {
        var query = FileMakerQuery()
        if let number = 伝票番号 {
            query["伝票番号"] = "==\(number)"
        }
        if let 工程 = 工程 {
            query["工程コード"] = "==\(工程.code)"
        }
        if let days = 登録期間 {
            query["登録日"] = makeQueryDayString(days)
        }
        if query.isEmpty { return [] }
        return try find(query: query)
    }
}

class 資材使用記録キャッシュ型 {
    static let shared = 資材使用記録キャッシュ型()
    var expireTime: TimeInterval = 1*60*60 // 1時間
    private let lock = NSLock()
    private var cache: [伝票番号型: (有効期限: Date, 資材使用記録: [資材使用記録型])] = [:]

    func 現在資材使用記録(伝票番号: 伝票番号型) throws -> [資材使用記録型]? {
        let list = try 資材使用記録型.find(伝票番号: 伝票番号)
        let expire = Date(timeIntervalSinceNow: self.expireTime)
        lock.lock()
        cache[伝票番号] = (expire, list)
        lock.unlock()
        return list
    }

    func キャッシュ資材使用記録(伝票番号: 伝票番号型) throws -> [資材使用記録型]? {
        lock.lock()
        let data = self.cache[伝票番号]
        lock.unlock()
        if let data = data, Date() <= data.有効期限 {
            return data.資材使用記録
        }
        return try self.現在資材使用記録(伝票番号: 伝票番号)
    }

    func flush(伝票番号: 伝票番号型) {
        lock.lock()
        cache[伝票番号] = nil
        lock.unlock()
    }
    
    func flushAllCache() {
        lock.lock()
        self.cache.removeAll()
        lock.unlock()
    }

}
