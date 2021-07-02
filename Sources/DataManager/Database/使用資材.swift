//
//  使用資材.swift
//  DataManager
//
//  Created by manager on 2021/07/01.
//

import Foundation

class 使用資材型 {
    static let dbName = "DataAPI_17"

    public var 登録日: Day
    public var 登録時間: Time
    public var 伝票番号: 伝票番号型
    public var 作業者: 社員型?
    public var 工程: 工程型?
    public var 用途: 用途型?
    public var 図番: 図番型
    public var 表示名: String
    public var 使用量: String
    public var 面積: String?
    public var 印刷対象: 印刷対象型?
    public var 単位量: Double?
    public var 単位数: Double?
    public var 金額: Double?
    public var 原因工程: 工程型?
    public var 登録セッションUUID: String?

    public var 登録日時: Date { Date(self.登録日, self.登録時間) }
    
    init?(_ record: FileMakerRecord) {
        guard let day = record.day(forKey: "登録日"),
              let time = record.time(forKey: "登録時間"),
              let order = record.伝票番号(forKey: "伝票番号"),
              let item = record.string(forKey: "図番"),
              let title = record.string(forKey: "表示名"),
              let use = record.string(forKey: "使用量") else { return nil }
        self.登録日 = day
        self.登録時間 = time
        self.伝票番号 = order
        self.図番 = item
        self.表示名 = title
        self.使用量 = use
        self.作業者 = record.社員(forKey: "作業者コード")
        self.工程 = record.工程(forKey: "工程コード")
        self.用途 = record.用途(forKey: "用途コード")
        self.印刷対象 = record.印刷対象(forKey: "印刷対象")
        self.単位量 = record.double(forKey: "単位量")
        self.単位数 = record.double(forKey: "単位数")
        self.金額 = record.double(forKey: "金額")
        self.原因工程 = record.工程(forKey: "原因工程")
        self.面積 = record.string(forKey: "面積")
        self.登録セッションUUID = record.string(forKey: "登録セッションUUID") ?? ""
    }
}

extension 使用資材型 {
    static func find(query: FileMakerQuery, session: FileMakerSession? = nil) throws -> [使用資材型] {
        let list: [FileMakerRecord]
        if let session = session {
            list = try session.find(layout: 使用資材型.dbName, query: [query])
        } else {
            list = try FileMakerDB.pm_osakaname.find(layout: 使用資材型.dbName, query: [query])
        }
        return list.compactMap { 使用資材型($0) }
    }
    
    static func find(API識別キー: UUID, session: FileMakerSession) throws -> [使用資材型] {
        var query = FileMakerQuery()
        query["登録セッションUUID"] = "==\(API識別キー.uuidString)"
        return try find(query: query, session: session)
    }
    
    static func find(登録日: Day? = nil, 伝票番号: 伝票番号型? = nil) throws -> [使用資材型] {
        var query = FileMakerQuery()
        if let day = 登録日 {
            query["登録日"] = day.fmString
        }
        if let number = 伝票番号 {
            query["伝票番号"] = number.整数文字列
        }
        if query.isEmpty { return [] }
        return try find(query: query)
    }
}
