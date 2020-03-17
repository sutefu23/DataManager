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
    public let 登録日: Day
    public let 登録時間: Time
    public let 社員: 社員型
    public let 入力区分: 入力区分型
    public let 資材: 資材型
    public let 入庫数: Int
    public let 出庫数: Int
    public let 部署: 部署型

    init?(_ record: FileMakerRecord) {
        self.record = record
        guard let day = record.day(forKey: "登録日") else { return nil }
        guard let time = record.time(forKey: "登録時間") else { return nil }
        guard let worker = record.社員(forKey: "社員番号") else { return nil }
        guard let type = record.入力区分(forKey: "入力区分") else { return nil }
        guard let item = record.資材(forKey: "資材番号") else { return nil }
        guard let sec = record.部署(forKey: "部署記号") else { return nil }
        let input = record.integer(forKey: "入庫数") ?? 0
        let output = record.integer(forKey: "出庫数") ?? 0
        self.登録日 = day
        self.登録時間 = time
        self.社員 = worker
        self.入力区分 = type
        self.資材 = item
        self.入庫数 = input
        self.出庫数 = output
        self.部署 = sec
    }
    
    public var 出庫金額: Double{
        return 資材.単価 * Double(出庫数)
    }
}

extension 資材入出庫型 {
    public static let dbName = "DataAPI_12"
    
    public static func find(登録日: Day? = nil, 登録時間: Time? = nil, 社員: 社員型? = nil, 入力区分: 入力区分型? = nil, 資材: 資材型? = nil, 入庫数: Int? = nil, 出庫数: Int? = nil) throws -> [資材入出庫型] {
        var query = FileMakerQuery()
        query["登録日"] = 登録日?.fmString
        query["登録時間"] = 登録時間?.fmImportString
        query["社員番号"] = 社員?.Hなし社員コード
        query["入力区分"] = 入力区分?.name
        query["資材番号"] = 資材?.図番
        if let num = 入庫数, num > 0 {
            query["入庫数"] = String(num)
        }
        if let num = 出庫数, num > 0 {
            query["出庫数"] = String(num)
        }
        if query.isEmpty {
            return []
        }
        let db = FileMakerDB.pm_osakaname
        let list: [FileMakerRecord] = try db.find(layout: 資材入出庫型.dbName, query: [query])
        return list.compactMap { 資材入出庫型($0) }
    }

    static func find(登録日: Day? = nil, 登録時間: Time? = nil, 社員: 社員型? = nil, 入力区分: 入力区分型? = nil, 資材: 資材型? = nil, 入庫数: Int? = nil, 出庫数: Int? = nil, session: FileMakerSession) throws -> [資材入出庫型] {
        var query = FileMakerQuery()
        query["登録日"] = 登録日?.fmString
        query["登録時間"] = 登録時間?.fmImportString
        query["社員番号"] = 社員?.Hなし社員コード
        query["入力区分"] = 入力区分?.name
        query["資材番号"] = 資材?.図番
        if let num = 入庫数, num > 0 {
            query["入庫数"] = String(num)
        }
        if let num = 出庫数, num > 0 {
            query["出庫数"] = String(num)
        }
        if query.isEmpty {
            return []
        }
        let list: [FileMakerRecord] = try session.find(layout: 資材入出庫型.dbName, query: [query])
        return list.compactMap { 資材入出庫型($0) }
    }

    public static func find(期間: ClosedRange<Day>, 入力区分: 入力区分型? = nil) throws -> [資材入出庫型] {
        var query = FileMakerQuery()
        query["登録日"] = makeQueryDayString(期間)
        query["入力区分"] = 入力区分?.name
        if query.isEmpty {
            return []
        }
        let db = FileMakerDB.pm_osakaname
        let list: [FileMakerRecord] = try db.find(layout: 資材入出庫型.dbName, query: [query])
        return list.compactMap { 資材入出庫型($0) }
    }
}
