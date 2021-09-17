//
//  資材要求出力.swift
//  DataManager
//
//  Created by manager on 2020/02/04.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

public struct 資材要求出力型: FileMakerExportRecord {
    public let 登録日: Day
    public let 登録時間: Time
    public let 注文番号: 注文番号型
    public let 社員: 社員型
    public let 資材: 資材型
    public let 数量: Int
    public let 希望納期: Day?
    public let 備考: String
    
    public init(登録日: Day = Day(), 登録時間: Time = Time(), 注文番号: 注文番号型, 社員: 社員型, 資材: 資材型, 数量: Int, 希望納期: Day?, 備考: String) {
        self.登録日 = 登録日
        self.登録時間 = 登録時間
        self.注文番号 = 注文番号
        self.社員 = 社員
        self.資材 = 資材
        self.数量 = 数量
        self.希望納期 = 希望納期
        self.備考 = 備考
    }    
    
    public typealias ImportBuddyType = 発注型
    public static var db: FileMakerDB { .pm_osakaname }
    public static var exportLayout: String { "DataAPI_MaterialRequirementsInput" }
    public static var exportScript: String { "DataAPI_MaterialRequestments_RecordSet" }
    
    public func makeExportRecord(exportUUID: UUID) -> FileMakerQuery {
        var record: [String: String] = [
            "識別キー": exportUUID.uuidString,
            "登録日": self.登録日.fmString,
            "登録時間": self.登録時間.fmImportString,
            "注文番号": self.注文番号.記号,
            "社員番号": self.社員.Hなし社員コード,
            "資材番号": self.資材.図番,
            "数量": "\(self.数量)",
            "備考": self.備考
        ]
        if let day = self.希望納期 {
            record["希望納期"] = day.fmString
        }
        return record
    }
    
    public func flushCache() {
        資材発注キャッシュ型.shared.flushCache(図番: self.資材.図番)
    }
    
    public static func prepareUploads(uuid: UUID, session: FileMakerSession) throws {
        var query = FileMakerQuery()
        query["API識別キー"] = "==\(uuid.uuidString)"
        _ = try session.find(layout: 発注型.dbName, query: [query])
    }
}
