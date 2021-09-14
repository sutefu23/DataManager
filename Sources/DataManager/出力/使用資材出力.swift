//
//  使用資材出力.swift
//  DataManager
//
//  Created by manager on 2021/07/01.
//

import Foundation

public struct 使用資材出力型: FileMakerExportRecord {
    public var 登録日時: Date
    
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

    public init(登録日時: Date,
                伝票番号: 伝票番号型,
                作業者: 社員型?,
                工程: 工程型?,
                用途: 用途型?,
                図番: 図番型,
                表示名: String,
                使用量: String,
                面積: String?,
                印刷対象: 印刷対象型? = nil,
                単位量: Double? = nil,
                単位数: Double? = nil,
                金額: Double? = nil,
                原因工程: 工程型? = nil
    ) {
        self.登録日時 = 登録日時
        self.伝票番号 = 伝票番号
        self.作業者 = 作業者
        self.工程 = 工程
        self.用途 = 用途
        self.図番 = 図番
        self.表示名 = 表示名
        self.使用量 = 使用量
        self.面積 = 面積
        self.印刷対象 = 印刷対象
        self.単位量 = 単位量
        self.単位数 = 単位数
        self.金額 = 金額
        self.原因工程 = 原因工程
    }
    
    init?(_ record: FileMakerRecord) {
        guard let date = record.date(dayKey: "登録日", timeKey: "登録時間") else { return nil }
        guard let number = record.伝票番号(forKey: "伝票番号") else { return nil }
        guard let item = record.資材(forKey: "図番") else { return nil }
        
        self.登録日時 = date
        self.伝票番号 = number
        self.工程 = record.工程(forKey: "工程コード")
        self.作業者 = record.社員(forKey: "作業者コード")
        self.図番 = item.図番
        self.使用量 = record.string(forKey: "使用量") ?? ""
        self.用途 = record.用途(forKey: "用途")
        self.金額 = record.double(forKey: "金額")
        if let title = record.string(forKey: "表示名"), !title.isEmpty {
            self.表示名 = title.全角半角日本語規格化()
        } else {
            self.表示名 = item.標準表示名
        }
        self.面積 = record.string(forKey: "面積")
        self.単位量 = record.double(forKey: "単位量")
        self.単位数 = record.double(forKey: "単位数")
        self.印刷対象 = record.印刷対象(forKey: "印刷対象")
        self.原因工程 = record.工程(forKey: "原因工程コード")
    }
    
    public init(_ record: 資材使用記録型) {
        self.登録日時 = record.登録日時
        self.伝票番号 = record.伝票番号
        self.工程 = record.工程
        self.作業者 = record.作業者
        self.図番 = record.図番
        self.使用量 = record.使用量 ?? ""
        self.用途 = 用途型(用途名: record.用途)
        self.金額 = record.金額
        self.表示名 = record.表示名
        if let val = record.使用面積 {
            self.面積 = "\(val)"
        } else {
            self.面積 = nil
        }
        self.単位量 = record.単位量
        self.単位数 = record.単位数
        self.印刷対象 = record.印刷対象
        self.原因工程 = record.原因工程
    }
    
//    func makeRecord(識別キー key: UUID) -> [String: String] {
//        var record: [String: String] = [
//            "登録セッションUUID": key.uuidString,
//            "登録日": 登録日時.day.fmString,
//            "登録時間": 登録日時.time.fmImportString,
//            "伝票番号": "\(伝票番号.整数値)",
//            "資材番号": 図番,
//            "表示名": 表示名,
//            "使用量": 使用量,
//        ]
//        record["工程コード"] = 工程?.code
//        record["社員コード"] = 作業者?.Hなし社員コード
//        record["原因部署"] = 原因工程?.code
//        record["用途コード"] = 用途?.用途コード
//        record["印刷対象"] = 印刷対象?.rawValue
//        if let area = self.面積 {
//            record["面積"] = area
//        }
//        if let value = self.単位量 {
//            record["単位量"] = "\(value)"
//        }
//        if let value = self.単位数 {
//            record["単位数"] = "\(value)"
//        }
//        if let charge = self.金額 {
//            record["金額"] = "\(charge)"
//        }
//        return record
//    }
//
    func isEqual(to order: 使用資材型) -> Bool {
        return
            self.伝票番号 == order.伝票番号 &&
            self.作業者 == order.作業者 &&
            self.使用量 == order.使用量 &&
            (self.単位数 ?? 1.0) == (order.単位数 ?? 1.0) &&
            self.単位量 == order.単位量 &&
            (self.印刷対象 ?? .なし) == (order.印刷対象 ?? .なし) &&
            self.原因工程 == order.原因工程 &&
            self.図番 == order.図番 &&
            self.工程 == order.工程 &&
            self.用途 == order.用途 &&
            self.登録日時 == order.登録日時 &&
            self.表示名 == order.表示名 &&
            self.金額 == order.金額 &&
            self.面積 == order.面積
    }
    
    /// サーバーに登録済みならtrue。サーバーに繋がらないなど判定不能時はnilを返す
    public func registered() -> Bool? {
        do {
            let list = try 使用資材キャッシュ型.shared.キャッシュ使用資材一覧(伝票番号: self.伝票番号)
            return list.contains { self.isEqual(to: $0) }
        } catch {
            return nil
        }
    }
    
    public typealias ImportBuddyType = 使用資材型
    public static var db: FileMakerDB { FileMakerDB.pm_osakaname }
    public static var exportLayout: String { "DataAPI_UseMaterialInput" }
    public static var exportScript: String { "DataAPI_UseMaterialInput_RecordSet" }
    public static var uuidField: String { "登録セッションUUID" }

    public func makeExportRecord(exportUUID: UUID) -> FileMakerQuery {
        var record: [String: String] = [
            "登録セッションUUID": exportUUID.uuidString,
            "登録日": 登録日時.day.fmString,
            "登録時間": 登録日時.time.fmImportString,
            "伝票番号": "\(伝票番号.整数値)",
            "資材番号": 図番,
            "表示名": 表示名,
            "使用量": 使用量,
        ]
        record["工程コード"] = 工程?.code
        record["社員コード"] = 作業者?.Hなし社員コード
        record["原因部署"] = 原因工程?.code
        record["用途コード"] = 用途?.用途コード
        record["印刷対象"] = 印刷対象?.rawValue
        if let area = self.面積 {
            record["面積"] = area
        }
        if let value = self.単位量 {
            record["単位量"] = "\(value)"
        }
        if let value = self.単位数 {
            record["単位数"] = "\(value)"
        }
        if let charge = self.金額 {
            record["金額"] = "\(charge)"
        }
        return record
    }
    
//    public func isUploaded(data: 使用資材型) -> Bool {
//        return self.isEqual(to: data)
//    }    
}

/*
extension Collection where Element == 使用資材出力型 {
    public func exportToDB_old() throws {
//        if self.count >= 4 {
//            let array = Array(self)
//            try array[..<2].exportToDB()
//            try array[2...].exportToDB()
//        } else {
            let db = FileMakerDB.pm_osakaname
            let session = db.retainExportSession()
            defer { db.releaseExportSession(session) }
            try self.exportToDB(loopCount: 0, session: session)
//        }
    }
    
    private func exportToDB(loopCount: Int, session: FileMakerSession, uuid: UUID? = nil) throws {
        let targets = Array(self)
        if targets.isEmpty { return }
        let layout = "DataAPI_UseMaterialInput"
        if loopCount > 2 { throw FileMakerError.upload使用資材(message: "\(targets.first!.図番)など\(targets.count)件,sid:\(session.id)").log(.critical) }
        let uuid = UUID()
        do {
            session.log("使用資材\(targets.count)件出力開始[\(loopCount)]", detail: "uuid: \(uuid.uuidString)", level: .information)
            // 発注処理
            for progress in targets {
                try session.insert(layout: layout, fields: progress.makeRecord(識別キー: uuid))
            }
            let waitTime = TimeInterval(loopCount)+1.0
            Thread.sleep(forTimeInterval: waitTime)
            try session.executeScript(layout: layout, script: "DataAPI_UseMaterialInput_RecordSet", param: uuid.uuidString, waitTime: (waitTime, TimeInterval(targets.count)))
            let result = try 使用資材型.find(API識別キー: uuid, session: session) // 結果読み込み
            if result.count == targets.count { // 登録成功
                session.log("使用資材出力完了[\(loopCount)]", detail: "uuid: \(uuid.uuidString)", level: .information)
                return
            }
            if result.count > 0 { // 部分的に登録成功
                session.log("部分的に登録成功[\(loopCount)]", detail: "uuid: \(uuid.uuidString)", level: .information)
                let rest = targets.filter { target in return !result.contains(where: { target.isEqual(to: $0) }) }
                try rest.exportToDB(loopCount: loopCount+1, session: session, uuid: uuid)
            } else { // 完全に登録失敗
                session.log("完全に登録失敗[\(loopCount)]", detail: "uuid: \(uuid.uuidString)", level: .information)
                try targets.exportToDB(loopCount: loopCount+1, session: session, uuid: uuid)
            }
        } catch {
            session.log("登録失敗[\(loopCount)]", detail: "uuid: \(uuid)", level: .information)
            throw error.log(.critical)
        }
    }
}
*/
