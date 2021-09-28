//
//  資材入出庫.swift
//  DataManager
//
//  Created by manager on 2020/03/03.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

public final class 資材入出庫型: FileMakerSearchObject {
    public static var db: FileMakerDB { .pm_osakaname }
    public static var layout: String { "DataAPI_12" }

    public let recordId: FileMakerRecordID?

    public let 登録日: Day
    public let 登録時間: Time
    public lazy var 登録日時: Date = Date(self.登録日, self.登録時間)
    public let 社員: 社員型
    public let 入力区分: 入力区分型
    public let 資材: 資材型
    public let 入庫数: Int
    public let 出庫数: Int
    public let 部署: 部署型
    public let 修正社員名: String
    
    public var memoryFootPrint: Int { return 10 * 8} // 仮設定のため適当
    
    public required init(_ record: FileMakerRecord) throws {
//        self.record = record
        guard let day = record.day(forKey: "登録日"),
              let time = record.time(forKey: "登録時間"),
              let worker = record.社員(forKey: "社員番号") ?? record.社員名称(forKey: "社員名称"),
              let type = record.入力区分(forKey: "入力区分"),
              let item = record.資材(forKey: "資材番号"),
              let name = record.string(forKey: "修正社員名"),
              let sec = record.キャッシュ部署(forKey: "部署記号") else { throw FileMakerError.invalidData(message: "recordId:[\(record.recordId?.description ?? "")]不正な内容") }
        self.recordId = record.recordId
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
        self.修正社員名 = name
    }
    
    public var 出庫金額: Double? {
        guard let num = 資材.単価 else { return nil }
        return num * Double(出庫数)
    }
}

extension 資材入出庫型 {
    public static let dbName = "DataAPI_12"
    
    public static func fetchAll() throws -> [資材入出庫型] {
        let db = FileMakerDB.pm_osakaname
        let list = try db.fetch(layout: 資材入出庫型.dbName)
        return try list.map { try 資材入出庫型($0) }
    }
    
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
        return try self.find(query: query)
    }

    public static func find(図番: 図番型) throws -> [資材入出庫型] {
        return try self.find(query: ["資材番号" : 図番])
    }

//    static func find(登録日: Day? = nil, 登録時間: Time? = nil, 社員: 社員型? = nil, 入力区分: 入力区分型? = nil, 資材: 資材型? = nil, 入庫数: Int? = nil, 出庫数: Int? = nil, session: FileMakerSession?) throws -> [資材入出庫型] {
//        var query = FileMakerQuery()
//        query["登録日"] = 登録日?.fmString
//        query["登録時間"] = 登録時間?.fmImportString
//        query["社員番号"] = 社員?.Hなし社員コード
//        query["入力区分"] = 入力区分?.name
//        query["資材番号"] = 資材?.図番
//        if let num = 入庫数, num > 0 {
//            query["入庫数"] = String(num)
//        }
//        if let num = 出庫数, num > 0 {
//            query["出庫数"] = String(num)
//        }
//        if query.isEmpty {
//            return []
//        }
//        let list: [FileMakerRecord]
//        if let session = session {
//            list = try session.find(layout: 資材入出庫型.dbName, query: [query])
//        } else {
//            list = try FileMakerDB.pm_osakaname.find(layout: 資材入出庫型.dbName, query: [query])
//        }
//        return try list.map { try 資材入出庫型($0) }
//    }
//
    public static func find(期間: ClosedRange<Day>, 入力区分: 入力区分型? = nil, 部署: 部署型? = nil, 図番: String? = nil) throws -> [資材入出庫型] {
        var query = FileMakerQuery()
        query["登録日"] = makeQueryDayString(期間)
        if let num = 部署?.部署番号 {
            query["部署記号"] = "==\(num)"
        }
        query["資材番号"] = 図番
        query["入力区分"] = 入力区分?.name
        if query.isEmpty {
            return []
        }
        return try self.find(query: query)
    }
}
