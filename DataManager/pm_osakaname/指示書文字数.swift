//
//  指示書文字数.swift
//  DataManager
//
//  Created by manager on 2019/11/26.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

struct 指示書文字数型 {
    static let dbName = "DataAPI_指示書文字数"
    
    init?(_ record:FileMakerRecord) {
        guard let number = record.integer(forKey: "伝票番号"), 伝票番号型.isValidNumber(number) else { return nil }
        self.伝票番号 = number
        self.recordId = record.recordId
        self.original半田文字数 = record.integer(forKey: "半田文字数")
        self.original溶接文字数 = record.integer(forKey: "溶接文字数")
        self.original総文字数 = record.integer(forKey: "総文字数")
        self.半田文字数 = original半田文字数
        self.溶接文字数 = original溶接文字数
        self.総文字数 = original総文字数
    }
    init?(伝票番号: Int?, 半田文字数: Int?, 溶接文字数:Int?, 総文字数:Int?) {
        guard let number = 伝票番号, 伝票番号型.isValidNumber(number) else { return nil }
        self.伝票番号 = number
        self.original半田文字数 = nil
        self.original溶接文字数 = nil
        self.original総文字数 = nil
        self.半田文字数 = 半田文字数
        self.溶接文字数 = 溶接文字数
        self.総文字数 = 総文字数
    }
    var recordId: String?
    let 伝票番号: Int
    let original半田文字数: Int?
    let original溶接文字数: Int?
    let original総文字数: Int?
    
    var 半田文字数: Int?
    var 溶接文字数: Int?
    var 総文字数: Int?
    
    var isChanged: Bool {
        return original半田文字数 != 半田文字数 || original溶接文字数 != 溶接文字数 || original総文字数 != 総文字数
    }
    
    var fieldData : [String : String] {
        var data = [String : String]()
        data["伝票番号"] = "\(伝票番号)"
        if let num = 半田文字数 { data["半田文字数"] = "\(num)" } else { data["半田文字数"] = "" }
        if let num = 溶接文字数 { data["溶接文字数"] = "\(num)" } else { data["溶接文字数"] = "" }
        if let num = 総文字数 { data["総文字数"] = "\(num)" } else { data["総文字数"] = "" }
        return data
    }

    mutating func insert() -> Bool {
        if self.recordId != nil { return false }
        let db = FileMakerDB.system
        if let recordId = db.insert(layout: 指示書文字数型.dbName, fields: fieldData) {
            self.recordId = recordId
            return true
        } else {
            return false
        }
    }
    
    func update() -> Bool {
        guard let recordId = self.recordId else { return false }
        let db = FileMakerDB.system
        return db.update(layout: 指示書文字数型.dbName, recordId: recordId, fields: fieldData)
    }
    
    func delete() -> Bool {
        guard let recordId = self.recordId else { return false }
        let db = FileMakerDB.system
        return db.delete(layout: 指示書文字数型.dbName, recordId: recordId)
    }
}

extension 指示書文字数型 {
    static func find(伝票番号: Int) -> 指示書文字数型? {
        let db = FileMakerDB.system
        var query = [String:String]()
        query["伝票番号"] = "\(伝票番号)"
        let list : [FileMakerRecord]? = db.find(layout: 指示書文字数型.dbName, query: [query])
        return list?.compactMap { 指示書文字数型($0) }.first
    }
}
