//
//  資材入出庫出力.swift
//  DataManager
//
//  Created by manager on 2020/02/05.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

public struct 資材入出庫出力型 {
    public let 登録日: Day
    public let 登録時間: Time
    public let 資材: 資材型
    public let 部署: 部署型
    public let 入庫数: Int
    public let 出庫数: Int
    public let 社員: 社員型
    public let 入力区分: 入力区分型
    
    public init?(登録日: Day = Day(), 登録時間: Time = Time(), 資材: 資材型, 部署: 部署型, 入庫数: Int, 出庫数: Int, 社員: 社員型, 入力区分: 入力区分型) {
        if 入庫数 < 0 || 出庫数 < 0 { return nil }
        if 入庫数 == 0 && 出庫数 == 0 { return nil }
        self.登録日 = 登録日
        self.登録時間 = 登録時間
        self.資材 = 資材
        self.部署 = 部署
        self.入庫数 = 入庫数
        self.出庫数 = 出庫数
        self.社員 = 社員
        self.入力区分 = 入力区分
    }
    
    func makeRecord(識別キー key: UUID) -> [String: String] {
        var record: [String: String] = [
            "識別キー": key.uuidString,
            "登録日": self.登録日.fmString,
            "登録時間": self.登録時間.fmImportString,
            "資材番号": self.資材.図番,
            "部署記号" : self.部署.部署記号,
            "社員番号": self.社員.Hなし社員コード,
            "入力区分": self.入力区分.name
        ]
        if self.入庫数 > 0 {
            record["入庫数"] = "\(self.入庫数)"
        }
        if self.出庫数 > 0 {
            record["出庫数"] = "\(self.出庫数)"
        }
        return record
    }
}

extension Sequence where Element == 資材入出庫出力型 {
    public func exportToDB() throws {
        let db = FileMakerDB.pm_osakaname2
        let uuid = UUID()
        var count = 0
        do {
            for progress in self {
                try db.insert(layout: "DataAPI_MaterialEntry", fields: progress.makeRecord(識別キー: uuid))
                count += 1
            }
            if count > 0 {
                try db.executeScript(layout: "DataAPI_MaterialEntry", script: "DataAPI_MaterialEntry_RecordSet", param: uuid.uuidString)
            }
        } catch {
            NSLog(error.localizedDescription)
            throw error
        }
    }
}
