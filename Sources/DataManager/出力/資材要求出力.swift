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

    func makeRecord(識別キー key: UUID) -> [String: String] {
        var record: [String: String] = [
            "識別キー": key.uuidString,
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
    
    func isEqual(to order: 発注型) -> Bool {
        return self.登録日 == order.登録日 && self.注文番号 == order.注文番号 && self.社員 == order.依頼社員 && self.資材 == order.資材 && self.数量 == order.発注数量 && self.備考 == order.備考
    }
}

extension Sequence where Element == 資材要求出力型 {
    public func exportToDB() throws {
        let db = FileMakerDB.pm_osakaname
        let session = db.retainSession()
        defer { db.releaseSession(session) }
        try self.exportToDB(loopCount: 0, session: session)
        /// 発注キャッシュをクリアしないと表示がおかしくなる
        let set = Set<図番型>(self.map { $0.資材.図番 })
        let cache = 資材発注キャッシュ型.shared
        set.forEach { cache.flushCache(図番: $0) }
    }
    
    private func exportToDB(loopCount: Int, session: FileMakerSession) throws {
        let targets = Array(self)
        if targets.isEmpty { return }
        let layout = "DataAPI_MaterialRequirementsInput"
        if loopCount >= 5 { throw FileMakerError.upload発注(message: "\(targets.first!.資材.図番)など\(targets.count)件") }
        let uuid = UUID()
        do {
            // 発注処理
            for progress in targets {
                try session.insert(layout: layout, fields: progress.makeRecord(識別キー: uuid))
            }
            Thread.sleep(forTimeInterval: TimeInterval(loopCount)+0.1)
            try session.executeScript(layout: layout, script: "DataAPI_MaterialRequestments_RecordSet", param: uuid.uuidString)
            Thread.sleep(forTimeInterval: TimeInterval(loopCount)+0.1)
            let result = try 発注型.find(API識別キー: uuid, session: session) // 結果読み込み
            if result.count == targets.count { // 登録成功
                return
            }
            if result.count > 0 { // 部分的に登録成功
                let rest = targets.filter { target in return !result.contains(where: { target.isEqual(to: $0) }) }
                try rest.exportToDB(loopCount: loopCount+1, session: session)
                return
            } else { // 完全に登録失敗
                try targets.exportToDB(loopCount: loopCount+1, session: session)
            }
        } catch {
            throw error
        }
    }
}
