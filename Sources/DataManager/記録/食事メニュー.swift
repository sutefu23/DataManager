//
//  食事メニュー.swift
//  DataManager
//
//  Created by 四熊泰之 on R 2/09/25.
//

import Foundation

private let serialQueue: OperationQueue = {
   let queue = OperationQueue()
    queue.maxConcurrentOperationCount = 1
    queue.qualityOfService = .utility
    return queue
}()

enum 食事種類型: String {
    case 朝食
    case 夕食
}
extension FileMakerRecord {
    func 食事種類(forKey key: String) -> 食事種類型? {
        guard let name = self.string(forKey: key) else { return nil }
        return 食事種類型(rawValue: name)
    }
}
public typealias メニューID型 = String
struct 食事メニューData型: Equatable {
    static let dbName = "DataAPI_6"
    var メニューID: メニューID型
    var 図番: 図番型
    var 提供日: Day
    var 発注日: Day
    var 種類: 食事種類型
    var 内容: String
    var カロリー: String
    var 食塩: String
    var 最大提供数: Int
    var 金額: Int
    
    init(メニューID: メニューID型, 図番: 図番型, 提供日: Day, 発注日: Day, 種類: 食事種類型, 内容: String, カロリー: String, 食塩: String, 最大提供数: Int, 金額: Int) {
        self.メニューID = メニューID
        self.図番 = 図番
        self.提供日 = 提供日
        self.発注日 = 発注日
        self.種類 = 種類
        self.内容 = 内容
        self.カロリー = カロリー
        self.食塩 = 食塩
        self.最大提供数 = 最大提供数
        self.金額 = 金額
    }
    
    init?(_ record: FileMakerRecord) {
        guard let メニューID = record.string(forKey: "メニューID"),
              let 図番 = record.string(forKey: "図番"),
              let 提供日 = record.day(forKey: "提供日"),
              let 発注日 = record.day(forKey: "発注日"),
              let 種類 = record.食事種類(forKey: "種類"),
              let 最大提供数 = record.integer(forKey: "最大提供数"),
              let 金額 = record.integer(forKey: "金額")
        else { return nil }
        self.メニューID = メニューID
        self.図番 = 図番
        self.提供日 = 提供日
        self.発注日 = 発注日
        self.種類 = 種類
        self.内容 = record.string(forKey: "内容") ?? ""
        self.カロリー = record.string(forKey: "カロリー") ?? ""
        self.食塩 = record.string(forKey: "食塩") ?? ""
        self.最大提供数 = 最大提供数
        self.金額 = 金額
    }
    
    var fieldData: FileMakerQuery {
        var data = FileMakerQuery()
        data["メニューID"] = メニューID
        data["図番"] = 図番
        data["提供日"] = 提供日.fmString
        data["発注日"] = 発注日.fmString
        data["種類"] = 種類.rawValue
        data["内容"] = 内容
        data["カロリー"] = カロリー
        data["食塩"] = 食塩
        data["最大提供数"] = "\(最大提供数)"
        data["金額"] = "\(金額)"
        return data
    }
}

public class 食事メニュー型 {
    var original: 食事メニューData型?
    var data: 食事メニューData型
    
    public internal(set) var recordID: String?
    var メニューID: メニューID型 {
        get { data.メニューID }
        set { data.メニューID = newValue }
    }
    var 図番: 図番型 {
        get { data.図番 }
        set { data.図番 = newValue }
    }
    var 提供日: Day {
        get { data.提供日 }
        set { data.提供日 = newValue }
    }
    var 発注日: Day {
        get { data.発注日 }
        set { data.発注日 = newValue }
    }
    var 種類: 食事種類型 {
        get { data.種類 }
        set { data.種類 = newValue }
    }
    var 内容: String {
        get { data.内容 }
        set { data.内容 = newValue }
    }
    var カロリー: String {
        get { data.カロリー }
        set { data.カロリー = newValue }
    }
    var 食塩: String {
        get { data.食塩 }
        set { data.食塩 = newValue }
    }
    var 最大提供数: Int {
        get { data.最大提供数 }
        set { data.最大提供数 = newValue }
    }
    var 金額: Int {
        get { data.金額 }
        set { data.金額 = newValue }
    }

    init(メニューID: メニューID型, 図番: 図番型, 提供日: Day, 発注日: Day, 種類: 食事種類型, 内容: String, カロリー: String, 食塩: String, 最大提供数: Int, 金額: Int) {
        self.data = 食事メニューData型(メニューID: メニューID, 図番: 図番, 提供日: 提供日, 発注日: 発注日, 種類: 種類, 内容: 内容, カロリー: カロリー, 食塩: 食塩, 最大提供数: 最大提供数, 金額: 金額)
    }
    
    init?(_ record: FileMakerRecord) {
        guard let data = 食事メニューData型(record) else { return nil }
        self.data = data
        self.original = data
        self.recordID = record.recordID
    }

    public var isChanged: Bool { original != data }

    // MARK: - DB操作
    public func delete() throws {
        guard let recordID = self.recordID else { return }
        var result: Error? = nil
        let operation = BlockOperation {
            do {
                let db = FileMakerDB.system
                try db.delete(layout: 食事メニューData型.dbName, recordId: recordID)
                self.recordID = nil
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
            let _ = try? db.insert(layout: 食事メニューData型.dbName, fields: data)
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
                if let recordID = self.recordID {
                    try db.update(layout: 食事メニューData型.dbName, recordId: recordID, fields: data)
                    result = .success(recordID)
                } else {
                    let recordID = try db.insert(layout: 食事メニューData型.dbName, fields: data)
                    result = .success(recordID)
                }
//                資材使用記録キャッシュ型.shared.flush(伝票番号: self.伝票番号)
            } catch {
                result = .failure(error)
            }
        }
        serialQueue.addOperation(operation)
        operation.waitUntilFinished()
        self.recordID = try result.get()
    }

    // MARK: - DB検索
    static func find(query: FileMakerQuery) throws -> [食事メニュー型] {
        if query.isEmpty { return [] }
        var result: Result<[FileMakerRecord], Error>!
        let operation = BlockOperation {
            let db = FileMakerDB.system
            do {
                let list: [FileMakerRecord] = try db.find(layout: 食事メニューData型.dbName, query: [query])
                result = .success(list)
            } catch {
                result = .failure(error)
            }
        }
        serialQueue.addOperation(operation)
        operation.waitUntilFinished()
        let list = try result.get().compactMap { 食事メニュー型($0) }
        return list
    }

    public static func find(メニューID: String? = nil, 図番: 図番型? = nil) throws -> [食事メニュー型] {
        var query = [String: String]()
        if let order = メニューID {
            query["メニューID"] = "==\(order)"
        }
        if let item = 図番 {
            query["図番"] = "==\(item)"
        }
        return try find(query: query)
    }

}

// MARK: - キャッシュ
class 食事メニューキャッシュ型 {
    static let shared = 食事メニューキャッシュ型()
    var expireTime: TimeInterval = 1*60*60 // 1時間
    private let lock = NSLock()
    private var cache: [メニューID型: (有効期限: Date, 食事メニュー: [食事メニュー型])] = [:]

    func 現在メニュー(メニューID: メニューID型) throws -> [食事メニュー型]? {
        let list = try 食事メニュー型.find(メニューID: メニューID)
        let expire = Date(timeIntervalSinceNow: self.expireTime)
        lock.lock()
        cache[メニューID] = (expire, list)
        lock.unlock()
        return list
    }

    func キャッシュメニュー(メニューID: メニューID型) throws -> [食事メニュー型]? {
        lock.lock()
        let data = self.cache[メニューID]
        lock.unlock()
        if let data = data, Date() <= data.有効期限 {
            return data.食事メニュー
        }
        return try self.現在メニュー(メニューID: メニューID)
    }

    func flush(メニューID: メニューID型) {
        lock.lock()
        cache[メニューID] = nil
        lock.unlock()
    }
    
    func flushAllCache() {
        lock.lock()
        self.cache.removeAll()
        lock.unlock()
    }
}
