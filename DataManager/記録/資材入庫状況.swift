//
//  資材入庫状況.swift
//  DataManager
//
//  Created by manager on 2020/03/24.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

public enum 資材入庫状況状態型 {
    case 入庫済
    
    init?(_ text: String) {
        switch text {
        case "入庫済":
            self = .入庫済
        default:
            return nil
        }
    }
    
    var text: String {
        switch self {
        case .入庫済: return "入庫済"
        }
    }
}
extension FileMakerRecord {
    func 資材入庫状況状態(forKey key: String) -> 資材入庫状況状態型? {
        guard let string = self.string(forKey: key) else { return nil }
        return 資材入庫状況状態型(string)
    }
}

struct 資材入庫状況Data型: Equatable {
    static let dbName = "DataAPI_4"
    var 指定注文番号:  指定注文番号型
    var 資材入庫状況状態: 資材入庫状況状態型

    init?(_ record: FileMakerRecord) {
        guard let 指定注文番号 = record.指定注文番号(forKey: "指定注文番号") else  { return nil }
        guard let 資材入庫状況状態 = record.資材入庫状況状態(forKey: "資材入庫状況状態") else { return nil }
        self.指定注文番号 = 指定注文番号
        self.資材入庫状況状態 = 資材入庫状況状態
    }
    
    init(指定注文番号: 指定注文番号型, 資材入庫状況状態: 資材入庫状況状態型) {
        self.指定注文番号 = 指定注文番号
        self.資材入庫状況状態 = 資材入庫状況状態
    }
    
    var fieldData: FileMakerQuery {
        var data = FileMakerQuery()
        data["指定注文番号"] = 指定注文番号.テキスト
        data["資材入庫状況状態"] = 資材入庫状況状態.text
        return data
    }

    static func find(_ 指定注文番号: 指定注文番号型) throws -> 資材入庫状況Data型? {
        let db = FileMakerDB.system
        var query = FileMakerQuery()
        query["指定注文番号"] = "==\(指定注文番号.テキスト)"
        let list: [FileMakerRecord] = try db.find(layout: dbName, query: [query])
        return list.compactMap{ 資材入庫状況Data型($0) }.first
    }
    
    static func fetchAll() throws -> [資材入庫状況Data型] {
        let db = FileMakerDB.system
        return try db.fetch(layout: dbName).compactMap { 資材入庫状況Data型($0) }
    }
}

public class 資材入庫状況型 {
    var original: 資材入庫状況Data型
    var data: 資材入庫状況Data型
    var recordID: String?

    var 指定注文番号: 指定注文番号型 {
        get { data.指定注文番号 }
        set { data.指定注文番号 = newValue }
    }
    var 資材入庫状況状態: 資材入庫状況状態型 {
        get { data.資材入庫状況状態 }
        set { data.資材入庫状況状態 = newValue }
    }
    
    init(data: 資材入庫状況Data型, recordID: String) {
        self.data = data
        self.original = data
        self.recordID = recordID
    }
    
    public init(_ 指定注文番号: 指定注文番号型, 資材入庫状況状態: 資材入庫状況状態型) {
        let data = 資材入庫状況Data型(指定注文番号: 指定注文番号, 資材入庫状況状態: 資材入庫状況状態)
        self.original = data
        self.data = data
        self.recordID = nil
    }
    
    func delete() throws {
        guard let recordId = self.recordID else { return }
        let db = FileMakerDB.system
        try db.delete(layout: 資材入庫状況Data型.dbName, recordId: recordId)
        self.recordID = nil
        資材入庫状況キャッシュ型.shared.flushCache(指定注文番号: self.指定注文番号)
    }
    
    public func synchronize() {
        if self.recordID != nil && self.data == self.original { return }
        let data = self.data.fieldData
        let db = FileMakerDB.system
        do {
            if let recordID = self.recordID {
                try db.update(layout: 資材入庫状況Data型.dbName, recordId: recordID, fields: data)
            } else {
                let db = FileMakerDB.system
                let recordID = try db.insert(layout: 資材入庫状況Data型.dbName, fields: data)
                self.recordID = recordID
            }
            self.original = self.data
            資材入庫状況キャッシュ型.shared.flushCache(指定注文番号: self.指定注文番号)
        } catch {
            NSLog(error.localizedDescription)
        }
    }
    
    static func findDirect(指定注文番号: 指定注文番号型) throws -> 資材入庫状況型? {
        let db = FileMakerDB.system
        var query = FileMakerQuery()
        query["指定注文番号"] = "==\(指定注文番号.テキスト)"
        let list: [FileMakerRecord] = try db.find(layout: 資材入庫状況Data型.dbName, query: [query])
        if let record = list.first, let recordId = record.recordId {
            if let data = 資材入庫状況Data型(record) {
                return 資材入庫状況型(data: data, recordID: recordId)
            }
        }
        return nil
    }
    
    // 不要になったレコードの消去
    static func removeOld() throws {
        let db = FileMakerDB.system
        let list: [資材入庫状況型] = try db.fetch(layout: 資材入庫状況Data型.dbName).compactMap {
            guard let recordId = $0.recordId, let data = 資材入庫状況Data型($0) else { return nil }
            return 資材入庫状況型(data: data, recordID: recordId)
        }
        for data in list {
            guard let order = try 発注型.find(指定注文番号: data.指定注文番号).first else { continue }
            switch order.状態 {
            case .未処理, .発注待ち, .発注済み:
                break
            case .処理済み, .納品書待ち, .納品済み:
                try data.delete()
            }
        }
    }
}

// MARK: -

public class 資材入庫状況キャッシュ型 {
    let expireTime: TimeInterval = 10*60*60
    public static let shared = 資材入庫状況キャッシュ型()
    private let lock = NSLock()
    var map = [指定注文番号型: (expire: Date, data:資材入庫状況型?)]()

    func 現在資材入庫状況(指定注文番号: 指定注文番号型) throws -> 資材入庫状況型? {
        guard let result = try 資材入庫状況型.findDirect(指定注文番号: 指定注文番号) else {
            let date = Date(timeIntervalSinceNow: self.expireTime)
            lock.lock()
            map[指定注文番号] = (date, nil)
            lock.unlock()
            return nil
        }
        let date = Date(timeIntervalSinceNow: self.expireTime)
        lock.lock()
        map[指定注文番号] = (date, result)
        lock.unlock()
        return result
    }
    
    func キャッシュ資材入庫状況(指定注文番号: 指定注文番号型) throws -> 資材入庫状況型? {
        lock.lock()
        let cache = map[指定注文番号]
        lock.unlock()
        if let cache = cache, Date() < cache.expire { return cache.data }
        return try self.現在資材入庫状況(指定注文番号: 指定注文番号)
    }
    
    public func removeOldData() {
        try? 資材入庫状況型.removeOld()
    }
    
    func flushCache(指定注文番号: 指定注文番号型) {
        lock.lock()
        self.map[指定注文番号] = nil
        lock.unlock()
    }
    
    func flushAllCache() {
        lock.lock()
        map.removeAll()
        lock.unlock()
        try? 資材入庫状況型.removeOld()
    }
}
