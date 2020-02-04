//
//  資材要求出力.swift
//  DataManager
//
//  Created by manager on 2020/02/04.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

public struct 資材要求出力型 {
    let 登録日: Day
    let 登録時間: Time
    let 注文番号: String
    let 社員: 社員型
    let 資材番号: String
    let 数量: Int
    let 希望納期: Date
    let 備考: String
    
    func makeRecord(識別キー key: UUID) -> [String: String] {
        let record: [String: String] = [
            "識別キー": key.uuidString,
            "登録日": self.登録日.fmString,
            "登録時間": self.登録時間.fmImportString,
            "注文番号": self.注文番号,
            "社員番号": self.社員.Hなし社員コード,
            "資材番号": self.資材番号,
            "数量": "\(self.数量)",
            "備考": self.備考
        ]
        return record
    }

}

extension Sequence where Element == 資材要求出力型 {
    func exportToDB() throws {
        let db = FileMakerDB.pm_osakaname2
        let uuid = UUID()
        var count = 0
        for progress in self {
            try db.insert(layout: "DataAPI_ProcessInput", fields: progress.makeRecord(識別キー: uuid))
            count += 1
        }
        if count > 0 {
            try db.executeScript(layout: "DataAPI_ProcessInput", script: "DataAPI_ProcessInput_RecordSet", param: uuid.uuidString)
        }
    }
}
