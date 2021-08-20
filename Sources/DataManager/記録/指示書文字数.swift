//
//  指示書文字数.swift
//  DataManager
//
//  Created by manager on 2019/11/26.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

private var session: FileMakerDB {
    return FileMakerDB.system
}

private let serialQueue: OperationQueue = {
   let queue = OperationQueue()
    queue.maxConcurrentOperationCount = 1
    queue.qualityOfService = .utility
    return queue
}()

struct 箱文字文字数型: Hashable {
    var 半田文字数: Int
    var 溶接文字数: Int
    var 総文字数: Int
    
    init(_ record: FileMakerRecord) {
        self.半田文字数 = record.integer(forKey: "半田文字数") ?? 0
        self.溶接文字数 = record.integer(forKey: "溶接文字数") ?? 0
        self.総文字数 = record.integer(forKey: "総文字数") ?? 0
    }

    init(指示書 order: 指示書型) {
        let 総文字数 = order.製作文字数概算
        let 半田文字数, 溶接文字数 : Int
        if order.is半田あり {
            if order.is溶接あり {
                半田文字数 = 0
                溶接文字数 = 0
            } else {
                半田文字数 = 総文字数
                溶接文字数 = 0
            }
        } else if order.is溶接あり {
            半田文字数 = 0
            溶接文字数 = 総文字数
        } else {
            半田文字数 = 0
            溶接文字数 = 0
        }
        self.init(半田文字数: 半田文字数, 溶接文字数: 溶接文字数, 総文字数: 総文字数)
    }
    
    init(半田文字数: Int, 溶接文字数: Int, 総文字数: Int) {
        self.半田文字数 = 半田文字数
        self.溶接文字数 = 溶接文字数
        self.総文字数 = 総文字数
    }
}

public final class 指示書文字数型 {
    public static func synchronizeAll() {
        serialQueue.waitUntilAllOperationsAreFinished()
    }
    static let dbName = "DataAPI_1"

    public init(指示書 order: 指示書型) {
        self.初期箱文字文字数 = 箱文字文字数型(指示書: order)

        if let data = try? 箱文字文字数型.find(指示書: order) {
            self.recordId = data.recordId
            self.伝票番号 = order.伝票番号
            self.読み込み時箱文字文字数 = data.箱文字文字数
            self.現箱文字文字数 = data.箱文字文字数
        } else {
            self.伝票番号 = order.伝票番号
            self.読み込み時箱文字文字数 = 初期箱文字文字数
            self.現箱文字文字数 = 初期箱文字文字数
        }
    }

    var recordId: String?
    public let 伝票番号: 伝票番号型

    var 初期箱文字文字数: 箱文字文字数型
    var 読み込み時箱文字文字数: 箱文字文字数型
    var 現箱文字文字数: 箱文字文字数型
     
    public var 半田文字数: Int {
        get { self.現箱文字文字数.半田文字数 }
        set {
            if newValue == self.半田文字数 { return }
            self.現箱文字文字数.半田文字数 = newValue
            self.synchronize()
        }
    }
    public var 溶接文字数: Int {
        get { self.現箱文字文字数.溶接文字数 }
        set {
            if newValue == self.溶接文字数 { return }
            self.現箱文字文字数.溶接文字数 = newValue
            self.synchronize()
        }
    }
    public var 総文字数: Int {
        get { self.現箱文字文字数.総文字数 }
        set {
            if newValue == self.総文字数 { return }
            self.現箱文字文字数.総文字数 = newValue
            self.synchronize()
        }
    }
    
    var isInitial: Bool { return 初期箱文字文字数 == 現箱文字文字数 }
    var isChanged: Bool { return 読み込み時箱文字文字数 != 現箱文字文字数 }
    
    var fieldData: [String: String] {
        var data = [String: String]()
        data["伝票番号"] = "\(伝票番号)"
        data["半田文字数"] = "\(現箱文字文字数.半田文字数)"
        data["溶接文字数"] = "\(現箱文字文字数.溶接文字数)"
        data["総文字数"] = "\(現箱文字文字数.総文字数)"
        return data
    }
    
    func insert() {
        if self.recordId != nil { return }
        let data = self.fieldData
        let operation = BlockOperation {
            if let recordId = try? session.insert(layout: 指示書文字数型.dbName, fields: data) {
                self.recordId = recordId
            }
        }
        serialQueue.addOperation( operation )
        operation.waitUntilFinished()
    }
    
    func update() {
        guard let recordId = self.recordId else { return }
        let data = self.fieldData
        serialQueue.addOperation {
            try? session.update(layout: 指示書文字数型.dbName, recordId: recordId, fields: data)
        }
    }
    
    func delete() {
        guard let recordId = self.recordId else { return }
        serialQueue.addOperation {
            try? session.delete(layout: 指示書文字数型.dbName, recordId: recordId)
        }
    }
    
     public func synchronize() {
        if self.isInitial {
            self.delete()
            return
        }
        if self.isChanged == false { return }
        if let recordId = self.recordId {
            let data = self.fieldData
            serialQueue.addOperation {
                try? session.update(layout: 指示書文字数型.dbName, recordId: recordId, fields: data)
            }
        } else {
            self.insert()
        }
        self.読み込み時箱文字文字数 = self.現箱文字文字数
    }
}

extension 箱文字文字数型 {
    static func find(指示書 order: 指示書型) throws -> (recordId: String, 箱文字文字数: 箱文字文字数型)? {
        var result: Result<(recordId: String, 箱文字文字数: 箱文字文字数型)?, Error> = .success(nil)
        let operation = BlockOperation {
            var query = [String: String]()
            query["伝票番号"] = "\(order.伝票番号)"
            do {
                let list: [FileMakerRecord] = try session.find(layout: 指示書文字数型.dbName, query: [query])
                if let record = list.first, let recordId = record.recordID {
                    let data = 箱文字文字数型(record)
                    result = .success((recordId, data))
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
