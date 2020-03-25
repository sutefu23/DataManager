//
//  取引先.swift
//  DataManager
//
//  Created by manager on 2020/03/24.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation
public typealias 会社コード型 = String

public class 取引先型 {
    let record: FileMakerRecord

    init?(_ record: FileMakerRecord) {
        self.record = record
    }
    
    public var 会社コード: 会社コード型 { return record.string(forKey: "会社コード")! }
    public var 会社名: String { return record.string(forKey: "会社名")! }
    public var 分類: String { return record.string(forKey: "分類")! }
}

extension 取引先型 {
    static let dbName = "DataAPI_14"

    static func find(会社コード: 会社コード型) throws -> 取引先型? {
        let db = FileMakerDB.pm_osakaname
        var query = FileMakerQuery()
        query["会社コード"] = "==\(会社コード)"
        let list: [FileMakerRecord] = try db.find(layout: 取引先型.dbName, query: [query])
        return list.compactMap { 取引先型($0) }.first
    }

}
