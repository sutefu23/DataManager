//
//  資材入出庫.swift
//  DataManager
//
//  Created by manager on 2020/03/03.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

public class 資材入出庫型 {
    let record: FileMakerRecord
    var 登録日: Day
    var 登録時間: Time
    var 社員: 社員型
    var 入力区分: 入力区分型
    var 資材: 資材型
    var 入庫数: Int
    var 出庫数: Int

    init?(_ record: FileMakerRecord) {
        self.record = record
        guard let day = record.day(forKey: "登録日") else { return nil }
        guard let time = record.time(forKey: "登録時間") else { return nil }
        guard let worker = record.社員(forKey: "社員番号") else { return nil }
        guard let type = record.入力区分(forKey: "入力区分") else { return nil }
        guard let item = record.資材(forKey: "資材番号") else { return nil }
        guard let input = record.integer(forKey: "入庫数") else { return nil }
        guard let output = record.integer(forKey: "出庫数") else { return nil }
        self.登録日 = day
        self.登録時間 = time
        self.社員 = worker
        self.入力区分 = type
        self.資材 = item
        self.入庫数 = input
        self.出庫数 = output
    }

}

extension 資材入出庫型 {
    public static let dbName = "DataAPI_12"
    
    static func find(登録日: Day? = nil, 登録時間: Time? = nil, 社員: 社員型? = nil, 入力区分: 入力区分型? = nil, 資材: 資材型? = nil, 入庫数: Int? = nil, 出庫数: Int? = nil) throws -> [資材入出庫型] {
        var query = FileMakerQuery()
        query["登録日"] = 登録日?.fmString
        query["登録時間"] = 登録時間?.fmImportString
        query["社員番号"] = 社員?.Hなし社員コード
        query["入力区分"] = 入力区分?.name
        query["資材番号"] = 資材?.図番
        if let num = 入庫数 {
            query["入庫数"] = String(num)
        }
        if let num = 出庫数 {
            query["出庫数"] = String(num)
        }
        if query.isEmpty {
            return []
        }
        let db = FileMakerDB.pm_osakaname
        let list: [FileMakerRecord] = try db.find(layout: 資材入出庫型.dbName, query: [query])
        return list.compactMap { 資材入出庫型($0) }
    }
}
