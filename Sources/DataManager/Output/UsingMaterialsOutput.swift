//
//  使用資材出力.swift
//  DataManager
//
//  Created by manager on 2021/07/01.
//

import Foundation

public struct 使用資材出力型: FileMakerExportObject {
    public static var layout: String { "DataAPI_UseMaterialInput" }

    public var 登録日時: Date
    
    public let 用途: 用途型?
    public let 伝票番号: 伝票番号型
    public let 使用量: String
    public let 単位量: Double?
    public let 単位数: Double?
    public let 金額: Double?
    public let 面積: Double?

    public var 図番: 図番型 { data.図番! }
    public var 表示名: String { data.表示名 }
    public var 印刷対象: 印刷対象型? { data.印刷対象 }
    public var 原因工程: 工程型? { data.原因工程 }
    public var 作業者: 社員型? { data.作業者 }
    public var 工程: 工程型? { data.工程 }
    private let data: 使用資材Data型

    public var memoryFootPrint: Int { 14 * 16 }

    public init(登録日時: Date,
                伝票番号: 伝票番号型,
                作業者: 社員型?,
                工程: 工程型?,
                用途: 用途型?,
                図番: 図番型,
                表示名: String,
                使用量: String,
                面積: Double?,
                印刷対象: 印刷対象型? = nil,
                単位量: Double? = nil,
                単位数: Double? = nil,
                金額: Double? = nil,
                原因工程: 工程型? = nil
    ) {
        self.登録日時 = 登録日時
        self.伝票番号 = 伝票番号
        self.用途 = 用途
        self.使用量 = 使用量
        self.面積 = 面積
        self.単位量 = 単位量
        self.単位数 = 単位数
        self.金額 = 金額
        self.data = 使用資材Data型(図番: 図番, 表示名: 表示名, 印刷対象: 印刷対象, 原因工程: 原因工程, 工程: 工程, 作業者: 作業者)
    }
    
    init?(_ record: FileMakerRecord) {
        guard let date = record.date(dayKey: "登録日", timeKey: "登録時間") else { return nil }
        guard let number = record.伝票番号(forKey: "伝票番号") else { return nil }
        guard let item = record.資材(forKey: "図番") else { return nil }
        self.登録日時 = date
        self.伝票番号 = number
        self.使用量 = record.string(forKey: "使用量") ?? ""
        self.用途 = record.用途(forKey: "用途")
        self.金額 = record.double(forKey: "金額")
        self.面積 = record.double(forKey: "面積")
        self.単位量 = record.double(forKey: "単位量")
        self.単位数 = record.double(forKey: "単位数")

        let 表示名: String
        if let title = record.string(forKey: "表示名"), !title.isEmpty {
            表示名 = title.全角半角日本語規格化()
        } else {
            表示名 = item.標準表示名
        }
        let 工程 = record.工程(forKey: "工程コード")
        let 作業者 = record.社員(forKey: "作業者コード")
        let 図番 = item.図番
        let 印刷対象 = record.印刷対象(forKey: "印刷対象")
        let 原因工程 = record.工程(forKey: "原因工程コード")
        self.data = 使用資材Data型(図番: 図番, 表示名: 表示名, 印刷対象: 印刷対象, 原因工程: 原因工程, 工程: 工程, 作業者: 作業者)
    }
    
    public init(_ record: 資材使用記録型) {
        self.登録日時 = record.登録日時
        self.伝票番号 = record.伝票番号
        self.使用量 = record.使用量 ?? ""
        self.用途 = 用途型(用途名: record.用途)
        self.金額 = record.金額
        self.面積 = record.使用面積
        self.単位量 = record.単位量
        self.単位数 = record.単位数

        let 表示名 = record.表示名
        let 工程 = record.工程
        let 作業者 = record.作業者
        let 図番 = record.図番
        let 印刷対象 = record.印刷対象
        let 原因工程 = record.原因工程
        self.data = 使用資材Data型(図番: 図番, 表示名: 表示名, 印刷対象: 印刷対象, 原因工程: 原因工程, 工程: 工程, 作業者: 作業者)
    }
    
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
    
    public func makeExportRecord() -> FileMakerFields {
        var record: FileMakerQuery = [
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

        record.insertFlatMap(self.面積, forKey: "面積") { "\($0)" }
        record.insertFlatMap(self.単位量, forKey: "単位量") { "\($0)" }
        record.insertFlatMap(self.単位数, forKey: "単位数") { "\($0)" }
        record.insertFlatMap(self.金額, forKey: "金額") { "\($0)" }
        return record
    }
    
    public static func makeExportCommand(fields: [FileMakerFields]) -> FileMakerCommand {
        return .export(db: db, layout: layout,
                       prepare: (layout: 使用資材型.layout, field: "登録セッションUUID"),
                       fields: fields,
                       uuidField: "登録セッションUUID",
                       script: "DataAPI_UseMaterialInput_RecordSet",
                       checkField: "エラー")
    }
}
