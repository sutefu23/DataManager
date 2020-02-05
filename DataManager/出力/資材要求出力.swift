//
//  資材要求出力.swift
//  DataManager
//
//  Created by manager on 2020/02/04.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

public struct 資材要求出力型 {
    public let 登録日: Day
    public let 登録時間: Time
    public let 注文番号: String
    public let 社員: 社員型
    public let 資材番号: String
    public let 数量: Int
    public let 希望納期: Day?
    public let 備考: String
    
    public init(登録日: Day = Day(), 登録時間: Time = Time(), 注文番号: String, 社員: 社員型, 資材番号: String, 数量: Int, 希望納期: Day?, 備考: String) {
        self.登録日 = 登録日
        self.登録時間 = 登録時間
        self.注文番号 = 注文番号
        self.社員 = 社員
        self.資材番号 = 資材番号
        self.数量 = 数量
        self.希望納期 = 希望納期
        self.備考 = 備考
    }    

    func makeRecord(識別キー key: UUID) -> [String: String] {
        var record: [String: String] = [
            "識別キー": key.uuidString,
            "登録日": self.登録日.fmString,
            "登録時間": self.登録時間.fmImportString,
            "注文番号": self.注文番号,
            "社員番号": self.社員.Hなし社員コード,
            "資材番号": self.資材番号,
            "数量": "\(self.数量)",
            "備考": self.備考
        ]
        if let day = self.希望納期 {
            record["希望納期"] = day.fmString
        }
        return record
    }
}

extension Sequence where Element == 資材要求出力型 {
    public func exportToDB() throws {
        let db = FileMakerDB.pm_osakaname
        let uuid = UUID()
        var count = 0
        do {
            for progress in self {
                try db.insert(layout: "DataAPI_MaterialRequirementsInput", fields: progress.makeRecord(識別キー: uuid))
                count += 1
            }
            if count > 0 {
                try db.executeScript(layout: "DataAPI_MaterialRequirementsInput", script: "DataAPI_MaterialRequestments_RecordSet", param: uuid.uuidString)
            }
        } catch {
            NSLog("\(error)")
            throw error
        }
    }
}
