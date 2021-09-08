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
    
    public init?(登録日: Day? = nil, 登録時間: Time? = nil, 資材: 資材型, 部署: 部署型?, 入庫数: Int, 出庫数: Int, 社員: 社員型, 入力区分: 入力区分型) {
        guard let sec = 部署 ?? 社員.部署 else { return nil }
        let day = 登録日 ?? Day()
        let time = 登録時間 ?? Time()
        if 入庫数 < 0 || 出庫数 < 0 { return nil }
        self.登録日 = day
        self.登録時間 = time
        self.資材 = 資材
        self.部署 = sec
        self.入庫数 = 入庫数
        self.出庫数 = 出庫数
        self.社員 = 社員
        self.入力区分 = 入力区分
    }
    
    public init?(出庫CSV line: String) {
        let digs = line.split(separator: ",")
        if digs.count < 5 { return nil }
        guard let day = Day(fmDate: digs[0])
            else { return nil }
        guard let time = Time(fmTime: digs[1])
            else { return nil }
        guard let item = 資材型(図番: 図番型(digs[2]))
            else { return nil }
        guard let count = Int(digs[3])
            else { return nil }
        guard let member = 社員型(社員コード: digs[4])
            else { return nil }
        guard let sec = member.部署
            else { return nil }
        self.登録日 = day
        self.登録時間 = time
        self.資材 = item
        self.部署 = sec
        self.入庫数 = 0
        self.出庫数 = count
        self.社員 = member
        self.入力区分 = .通常入出庫
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
        let isZero = self.入庫数 == 0 && self.出庫数 == 0
        if self.入庫数 > 0 || isZero {
            record["入庫数"] = "\(self.入庫数)"
        }
        if self.出庫数 > 0 || isZero {
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
        let targets = Array(self)
        if targets.isEmpty { return }
        if loopCount >= 3 {
            throw FileMakerError.insert(message: "資材入出庫出力失敗(回数オーバー)", code: nil)
        }
        
        let uuid = UUID()
        do {
            session.log("入出庫\(targets.count)件出力開始[\(loopCount)]", detail: "uuid: \(uuid.uuidString)", level: .information)
            for progress in targets {
                try session.insert(layout: "DataAPI_MaterialEntry", fields: progress.makeRecord(識別キー: uuid))
            }
            let waitTime = TimeInterval(targets.count)+0.5
            Thread.sleep(forTimeInterval: waitTime)
            try session.executeScript(layout: "DataAPI_MaterialEntry", script: "DataAPI_MaterialEntry_RecordSet", param: uuid.uuidString, waitTime: (waitTime, TimeInterval(loopCount)))
            var errorResult: [資材入出庫出力型] = []
            for progress in self {
                let result = try 資材入出庫型.find(登録日: progress.登録日, 登録時間: progress.登録時間, 社員: progress.社員, 入力区分: progress.入力区分, 資材: progress.資材, 入庫数: progress.入庫数, 出庫数: progress.出庫数)
                if result.isEmpty { errorResult.append(progress) }
            }
            if !errorResult.isEmpty {
                try errorResult.exportToDB(loopCount: loopCount + 1, session: session)
            }
            session.log("入出庫出力完了[\(loopCount)]", detail: "uuid: \(uuid.uuidString)", level: .information)
        } catch {
            throw error.log(.critical)
        }
    }
}
