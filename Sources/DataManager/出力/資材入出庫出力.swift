//
//  資材入出庫出力.swift
//  DataManager
//
//  Created by manager on 2020/02/05.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

public struct 資材入出庫出力型: FileMakerExportRecord {
    public typealias ImportBuddyType = 資材入出庫型
    public static let layout: String = "DataAPI_MaterialEntry"
    public static let exportScript: String = "DataAPI_MaterialEntry_RecordSet"

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
        guard let item = try? 資材キャッシュ型.shared.キャッシュ資材(図番: 図番型(digs[2]))
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
        
    public func makeExportRecord(exportUUID: UUID) -> FileMakerQuery {
        var record: FileMakerQuery = [
            "識別キー": exportUUID.uuidString,
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
    
    public static func prepareUploads(uuid: UUID, session: FileMakerSession) throws {
        let _  = try session.find(layout: 資材入出庫型.dbName, query: [["UUID": "==\(uuid.uuidString)"]])
    }
}
