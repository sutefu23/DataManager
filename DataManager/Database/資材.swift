//
//  資材.swift
//  DataManager
//
//  Created by manager on 2019/03/19.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

public class 資材型 {
    let record: FileMakerRecord
    let 図番: String
    var 製品名称: String
    var 規格: String

    init?(_ record: FileMakerRecord) {
        self.record = record
        guard let 図番 = record.string(forKey: "f13") else { return nil }
        guard let 製品名称 = record.string(forKey: "f3") else { return nil }
        guard let 規格 = record.string(forKey: "f15") else { return nil }
        self.図番 = 図番
        self.製品名称 = 製品名称
        self.規格 = 規格
    }
    public convenience init?(図番: String ) {
        guard let record = (try? 資材型.find(図番: 図番))?.record else { return nil }
        self.init(record)
    }
}

public extension 資材型 {
    var 版数: String {
        return record.string(forKey: "f14") ?? ""
    }
    
    var 備考: String {
        return record.string(forKey: "備考") ?? ""
    }
    
    var 発注先名称: String {
        return record.string(forKey: "dbo.ZB_T1:f6") ?? ""
    }
    
    var 会社コード: String {
        return record.string(forKey: "会社コード") ?? ""
    }
    
    var 規格2: String {
        return record.string(forKey: "規格2") ?? ""
    }
    
    var 種類: String {
        return record.string(forKey: "種類") ?? ""
    }
}
// MARK: - 保存


// MARK: - 検索
public extension 資材型 {
    static let dbName = "DataAPI_5"
    
    static func fetch() throws -> [資材型] {
        let db = FileMakerDB.pm_osakaname
        let list: [FileMakerRecord] = try db.fetch(layout: 資材型.dbName)
        return list.compactMap { 資材型($0) }
    }
    
    static func find(図番: String) throws -> 資材型? {
        let db = FileMakerDB.pm_osakaname
        var query = FileMakerQuery()
        query["f13"] = "==\(図番)"
        let list: [FileMakerRecord] = try db.find(layout: 資材型.dbName, query: [query])
        return list.compactMap { 資材型($0) }.first
    }
}
