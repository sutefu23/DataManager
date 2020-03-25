//
//  資材入庫状況.swift
//  DataManager
//
//  Created by manager on 2020/03/24.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

struct 資材入庫状況Data型: Equatable {
    static let dbName = "DataAPI_4"
    
    var 指定注文番号:  指定注文番号型
    var 発注状態: 発注状態型

    init?(_ record: FileMakerRecord) {
        guard let 指定注文番号 = record.指定注文番号(forKey: "注文") else  { return nil }
        guard let 発注状態 = record.発注状態(forKey: "発注状態") else { return nil }
        self.指定注文番号 = 指定注文番号
        self.発注状態 = 発注状態
    }
    
    init(指定注文番号: 指定注文番号型, 発注状態: 発注状態型) {
        self.指定注文番号 = 指定注文番号
        self.発注状態 = 発注状態
    }
    
    var fieldData: FileMakerQuery {
        var data = FileMakerQuery()
        data["指定注文番号"] = 指定注文番号.テキスト
        data["発注状態"] = 発注状態.data
        return data
    }

    static func find(_ 指定注文番号: 指定注文番号型) throws -> 資材入庫状況Data型? {
        let db = FileMakerDB.system
        var query = FileMakerQuery()
        query["指定注文番号"] = "==\(指定注文番号.テキスト)"
        let list: [FileMakerRecord] = try db.find(layout: dbName, query: [query])
        return list.compactMap{ 資材入庫状況Data型($0) }.first
    }
}

public class 資材入庫状況型 {
    var original: 資材入庫状況Data型
    var data: 資材入庫状況Data型
    var recordID: String?

    public var 指定注文番号: 指定注文番号型 {
        get { data.指定注文番号 }
        set { data.指定注文番号 = newValue }
    }
    public var 発注状態: 発注状態型 {
        get { data.発注状態 }
        set { data.発注状態 = newValue }
    }
    
    init(data: 資材入庫状況Data型, recordID: String) {
        self.data = data
        self.original = data
        self.recordID = recordID
    }
    
    init(_ 指定注文番号: 指定注文番号型, 発注状態: 発注状態型) {
        let data = 資材入庫状況Data型(指定注文番号: 指定注文番号, 発注状態: 発注状態)
        self.original = data
        self.data = data
        self.recordID = nil
    }
    
    public func delete() {
        guard let recordId = self.recordID else { return }
        let db = FileMakerDB.system
        try? db.delete(layout: 資材入庫状況Data型.dbName, recordId: recordId)
        self.recordID = nil
    }
    
    public func synchronize() {
        if self.data == self.original { return }
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
        } catch {
            NSLog(error.localizedDescription)
        }
    }
    
    public static func allRegistered(for 伝票番号: 伝票番号型) throws -> [資材入庫状況型] {
        let db = FileMakerDB.system
        var query = [String: String]()
        query["伝票番号"] = "==\(伝票番号.整数値)"
        let list: [FileMakerRecord] = try db.find(layout: 資材入庫状況Data型.dbName, query: [query])
        let orders: [資材入庫状況型] = list.compactMap {
            guard let recordID = $0.recordId, let data = 資材入庫状況Data型($0) else { return nil }
            return 資材入庫状況型(data: data, recordID: recordID)
        }
        return orders
    }
    
    public static func findDirect(伝票番号: 伝票番号型, 工程: 工程型?) throws -> 資材入庫状況型? {
        let db = FileMakerDB.system
        var query = FileMakerQuery()
        query["伝票番号"] = "==\(伝票番号.整数値)"
        if let process = 工程 {
            query["工程コード"] = process.code
        } else {
            query["工程コード"] = "="
        }
        let list: [FileMakerRecord] = try db.find(layout: 資材入庫状況Data型.dbName, query: [query])
        if let record = list.first, let recordId = record.recordId {
            if let data = 資材入庫状況Data型(record) {
                return 資材入庫状況型(data: data, recordID: recordId)
            }
        }
        return nil
    }
}

