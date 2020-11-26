//
//  箱文字日報.swift
//  DataManager
//
//  Created by 四熊泰之 on R 1/12/05.
//  Copyright © Reiwa 1 四熊泰之. All rights reserved.
//

import Foundation

private let serialQueue: OperationQueue = {
   let queue = OperationQueue()
    queue.maxConcurrentOperationCount = 1
    queue.qualityOfService = .utility
    return queue
}()

struct 箱文字日報Data型 {
    static let dbName = "DataAPI_2"
    var 工程: 工程型
    var 作業日: Day
    var 件数: Int?
    var 分: Int?
    var 備考: String
    
    init?(_ record: FileMakerRecord) {
        guard let state = record.工程(forKey: "工程コード") else { return nil }
        self.工程 = state
        guard let day = record.day(forKey: "作業日") else { return nil }
        self.作業日 = day
        self.件数 = record.integer(forKey: "件数")
        self.分 = record.integer(forKey: "分")
        self.備考 = record.string(forKey: "備考") ?? ""
    }
    
    init(工程: 工程型, 作業日: Day, 件数: Int?, 分: Int?, 備考: String) {
        self.工程 = 工程
        self.作業日 = 作業日
        self.件数 = 件数
        self.分 = 分
        self.備考 = 備考
    }
    
    var fieldData: [String: String] {
        var data = [String: String]()
        data["作業日"] = 作業日.fmString
        data["工程コード"] = 工程.code
        if let number = self.件数 { data["件数"] = "\(number)" } else { data["件数"] = "" }
        if let number = self.分 { data["分"] = "\(number)" } else { data["分"] = "" }
        data["備考"] = 備考
        return data
    }
}

public final class 箱文字日報型 {
    var data: 箱文字日報Data型
    var recordId: String?
    
    public var 工程: 工程型 {
        get { data.工程 }
        set { data.工程 = newValue }
    }
    public var 作業日: Day {
        get { data.作業日 }
        set { data.作業日 = newValue }
    }
    public var 件数: Int? {
        get { data.件数 }
        set { data.件数 = newValue }
    }
    public var 分: Int? {
        get { data.分 }
        set { data.分 = newValue }
    }
    public var 備考: String {
        get { data.備考 }
        set { data.備考 = newValue }
    }

    public init(工程: 工程型, 作業日: Day, 件数: Int?, 分: Int?, 備考: String) {
        self.data = 箱文字日報Data型(工程: 工程, 作業日: 作業日, 件数: 件数, 分: 分, 備考: 備考)
        self.recordId = nil
    }
    
    init(data: 箱文字日報Data型, recordId: String) {
        self.data = data
        self.recordId = recordId
    }

    public func delete() {
        guard let recordId = self.recordId else { return }
        serialQueue.addOperation {
            let db = FileMakerDB.system
            try? db.delete(layout: 箱文字日報Data型.dbName, recordId: recordId)
            self.recordId = nil
        }
    }
    
    public func synchronize() {
        let data = self.data.fieldData
        serialQueue.addOperation {
            let db = FileMakerDB.system
            if let recordId = self.recordId {
                try? db.update(layout: 箱文字日報Data型.dbName, recordId: recordId, fields: data)
            } else {
                if let recordId = try? db.insert(layout: 箱文字日報Data型.dbName, fields: data) {
                    self.recordId = recordId
                }
            }
        }
    }

    public static func findDirect(作業日: Day, 工程: 工程型) throws -> 箱文字日報型? {
        var result: Result<箱文字日報型?, Error> = .success(nil)
        let operation = BlockOperation {
            let db = FileMakerDB.system
            var query = [String: String]()
            query["工程コード"] = "==\(工程.code)"
            query["作業日"] = "\(作業日.fmString)"
            do {
                let list: [FileMakerRecord] = try db.find(layout: 箱文字日報Data型.dbName, query: [query])
                if let record = list.first, let recordId = record.recordID {
                    if let data = 箱文字日報Data型(record) {
                        result = .success(箱文字日報型(data: data, recordId: recordId))
                    } else {
                        result = .success(nil)
                    }
                }
            } catch {
                result = .failure(error)
            }
        }
        serialQueue.addOperation(operation)
        operation.waitUntilFinished()
        return try result.get()
    }
}
