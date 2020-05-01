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
//        if 入庫数 == 0 && 出庫数 == 0 { return nil }
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
        forEach {
            在庫数キャッシュ型.shared.flushCache($0.資材.図番)
            入出庫キャッシュ型.shared.flushCache($0.資材.図番)
        }
        let db = FileMakerDB.pm_osakaname
        let session = db.retainSession()
        defer { db.releaseSession(session) }
        return try self.exportToDB(loopCount: 0, session: session)
    }
    
    func exportToDB(loopCount: Int, session: FileMakerSession) throws {
        if loopCount >= 10 {
            let targets = Array(self)
            NSLog("retry count:\(loopCount) orders:\(targets.count)")
            return
        }
        
        let uuid = UUID()
        var count = 0
        do {
            for progress in self {
                try session.insert(layout: "DataAPI_MaterialEntry", fields: progress.makeRecord(識別キー: uuid))
                count += 1
            }
            if count > 0 {
                try session.executeScript(layout: "DataAPI_MaterialEntry", script: "DataAPI_MaterialEntry_RecordSet", param: uuid.uuidString)
            }
            var errorResult: [資材入出庫出力型] = []
            for progress in self {
                let result = try 資材入出庫型.find(登録日: progress.登録日, 登録時間: progress.登録時間, 社員: progress.社員, 入力区分: progress.入力区分, 資材: progress.資材, 入庫数: progress.入庫数, 出庫数: progress.出庫数)
                if result.isEmpty { errorResult.append(progress) }
            }
            if !errorResult.isEmpty {
                try errorResult.exportToDB(loopCount: loopCount + 1, session: session)
            }
        } catch {
            NSLog(error.localizedDescription)
            throw error
        }
    }
}
