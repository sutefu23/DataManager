//
//  使用資材.swift
//  DataManager
//
//  Created by manager on 2021/07/01.
//

import Foundation

public class 使用資材型: FileMakerImportRecord {
    public static var name: String { "使用資材" }
    public static var db: FileMakerDB { FileMakerDB.pm_osakaname }
    public static var layout: String { "DataAPI_17" }
    
    static let dbName = "DataAPI_17"
    public let recordId: String?
    
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
    
    public var memoryFootPrint: Int { return 30 * 8 } // 仮設定のため適当

    public required init(_ record: FileMakerRecord) throws {
        guard let day = record.day(forKey: "登録日"),
              let time = record.time(forKey: "登録時間"),
              let order = record.伝票番号(forKey: "伝票番号"),
              let item = record.string(forKey: "図番"),
              let title = record.string(forKey: "表示名"),
              let use = record.string(forKey: "使用量") else { throw FileMakerError.invalidData(message: "不正な使用資材データ: レコードID\(record.recordId ?? "")") }
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
        self.recordId = record.recordId
    }

//    public static func makeExportCheckQuery(exportUUID: UUID) -> FileMakerQuery {
//        return ["登録セッションUUID": "==\(exportUUID.uuidString)"]
//    }

    static func find(query: FileMakerQuery, session: FileMakerSession? = nil) throws -> [使用資材型] {
        if query.isEmpty { return [] }

        let list: [FileMakerRecord]
        if let session = session {
            list = try session.find(layout: 使用資材型.dbName, query: [query])
        } else {
            list = try FileMakerDB.pm_osakaname.find(layout: 使用資材型.dbName, query: [query])
        }
        return try list.map { try 使用資材型($0) }
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
        return try find(query: query)
    }
    
    static func find(登録日時: Date, 伝票番号: 伝票番号型, 作業者: 社員型?, 工程: 工程型?, 用途: 用途型?, 図番: 図番型, 表示名: String, 使用量: String, 面積: String?,印刷対象: 印刷対象型?, 単位量: Double?, 単位数: Double?, 金額: Double?, 原因工程: 工程型?) throws -> [使用資材型] {
        var query = FileMakerQuery()
        query["登録日"] = 登録日時.day.fmString
        query["登録日時"] = 登録日時.time.fmImportString
        query["伝票番号"] = 伝票番号.整数文字列
        query["社員コード"] = 作業者?.Hなし社員コード
        query["工程コード"] = 工程?.code
        query["用途コード"] = 用途?.用途コード
        query["資材番号"] = 図番
        query["表示名"] = 表示名
        query["使用量"] = 使用量
        if let area = 面積 {
            query["面積"] = area
        }
        query["印刷対象"] = 印刷対象?.rawValue
        if let value = 単位量 {
            query["単位量"] = "\(value)"
        }
        if let value = 単位数 {
            query["単位数"] = "\(value)"
        }
        if let charge = 金額 {
            query["金額"] = "\(charge)"
        }
        query["原因部署"] = 原因工程?.code
        return try find(query: query)
    }
}
