//
//  発注.swift
//  DataManager
//
//  Created by manager on 8/9/1 R.
//  Copyright © 1 Reiwa 四熊泰之. All rights reserved.
//

import Foundation

public class 外注型 {
}
public final class 発注型: FileMakerSearchObject {
    public static let layout = "DataAPI_4"

    public let recordId: FileMakerRecordID?

    public let 資材: 資材型?
    public let 指定注文番号: 指定注文番号型
    
    public let 注文番号: 注文番号型
    public let 会社名: String
    public let 会社コード: 会社コード型
    public let 金額: String
    public let 発注日: Day
    public let 登録日: Day
    public let 版数: String
    public let 製品名称: String
    public let 規格: String
    public let 規格2: String
    public let 発注数量文字列: String
    public let 備考: String
    public let 納品日: Day?
    public let 納品書処理日: Day?
    public let 依頼社員: 社員型?
    public let 発注数量: Int?
    public let 状態: 発注状態型
    public let 発注種類: 発注種類型

    public var memoryFootPrint: Int { return 22 * 8} // 仮設定のため適当

    public required init(_ record: FileMakerRecord) throws {
        func makeError(_ key: String) -> Error { record.makeInvalidRecordError(name: Self.name, mes: key) }
        func getString(_ key: String) throws -> String {
            guard let string = record.string(forKey: key) else { throw makeError(key) }
            return string
        }
        func getDay(_ key: String) throws -> Day {
            guard let day = record.day(forKey: key) else { throw makeError(key) }
            return day
        }
        guard let 注文番号 = record.注文番号(forKey: "注文番号") else { throw makeError("注文番号") }
        guard let 発注種類 = record.発注種類(forKey: "発注種類") else { throw makeError("発注種類") }
        
        switch 発注種類 {
        case .資材:
            guard let 資材 = record.資材(forKey: "図番") else { throw makeError("図番") }
            self.資材 = 資材
            guard let 指定注文番号 = record.指定注文番号(forKey: "指定注文番号") else { throw makeError("指定注文番号") }
            self.指定注文番号 = 指定注文番号
        case .外注:
            self.資材 = nil
            self.指定注文番号 = try 指定注文番号型(text: getString("指定注文番号"))
        }
        self.注文番号 = 注文番号
        self.発注種類 = 発注種類

        self.会社名 = try getString("会社名")
        self.会社コード = try getString("会社コード")
        self.金額 = try getString("金額")
        self.発注日 = try getDay("発注日")
        self.登録日 = try getDay("登録日")
        self.版数 = try getString("版数")
        self.製品名称 = try getString("製品名称")
        self.規格 = try getString("規格")
        self.規格2 = try getString("規格2")
        self.備考 = try getString("備考")
        self.発注数量文字列 = try getString("発注数量")
        
        self.recordId = record.recordId

        self.状態 = record.発注状態(forKey: "状態") ?? .処理済み
        self.納品日 = record.day(forKey: "納品日")
        self.納品書処理日 = record.day(forKey: "納品書処理日")
        self.依頼社員 = record.社員(forKey: "依頼社員番号")
        self.発注数量 = Int(self.発注数量文字列)
    }
}

public extension 発注型 {
    var 会社: 取引先型? { return try? 取引先キャッシュ型.shared.キャッシュ取引先(会社コード: self.会社コード) }
    var 図番: String { return 資材?.図番 ?? "" }
    var 単位: String { return 資材?.単位 ?? "" }
    var 品名1: String { return self.製品名称 }
    var 品名2: String { return self.規格 }
    var 品名3: String { return self.規格2 }
    
    var 補正済状態: 発注状態型 {
        guard let state = try? 資材入庫状況キャッシュ型.shared.キャッシュ資材入庫状況(指定注文番号: self.指定注文番号) else { return self.状態 }
        switch state.資材入庫状況状態 {
        case .入庫済:
            switch self.状態 {
            case .未処理, .発注済み, .発注待ち:
                return .納品書待ち
            case .処理済み, .納品書待ち, .納品済み:
                let _ = try? state.delete()
                return self.状態
            }
        }
    }
}

public enum 発注種類型: CustomStringConvertible, CaseIterable {
    case 資材
    case 外注
    
    init?(data: String) {
        switch data {
        case "資材": self = .資材
        case "外注": self = .外注
        default:
            return nil
        }
    }
    
    public var description: String {
        switch self {
        case .資材: return "資材"
        case .外注: return "外注"
        }
    }
}

extension FileMakerRecord {
    func 発注種類(forKey key: String) -> 発注種類型? {
        guard let data = self.string(forKey: key) else { return nil }
        return 発注種類型(data: data)
    }
}

extension 発注型 {
    public static let dbName = "DataAPI_4"
    
    public static func find(伝票番号: 伝票番号型, 発注種類: 発注種類型?) throws -> [発注型] {
        var query = FileMakerQuery()
        query["伝票番号"] = "==\(伝票番号.整数値)"
        query["発注種類"] = 発注種類?.description
        return try find(query: query)
    }

    static func find(API識別キー: UUID, session: FileMakerSession) throws -> [発注型] {
        var query = FileMakerQuery()
        query["API識別キー"] = "==\(API識別キー.uuidString)"
        let list: [FileMakerRecord] = try session.find(layout: 発注型.dbName, query: [query])
        return try list.map { try 発注型($0) }
    }
    
    public static func find(登録期間: ClosedRange<Day>, 発注種類: 発注種類型, 版数: String?) throws -> [発注型] {
        var query = FileMakerQuery()
        query["登録日"] = makeQueryDayString(登録期間)
        query["発注種類"] = 発注種類.description
        if let han = 版数 {
            query["版数"] = "==\(han)"
        }
        return try find(query: query)
    }
    
    public static func check指定注文番号(登録期間: ClosedRange<Day>) throws -> [(登録日: Day, 注文番号: String)] {
        var result = [(登録日: Day, 注文番号: String)]()
        var query = FileMakerQuery()
        query["登録日"] = makeQueryDayString(登録期間)
        query["発注種類"] = 発注種類型.資材.description
        let db = FileMakerDB.pm_osakaname
        let list: [FileMakerRecord] = try db.find(layout: 発注型.dbName, query: [query])
        for record in list {
            guard let day = record.day(forKey: "登録日") else { continue }
            guard let string = record.string(forKey: "指定注文番号") else { continue }
            if 指定注文番号型(string) == nil {
                result.append((day, string))
            }
        }
        return result
    }
    
    public static func find(指定注文番号: 指定注文番号型? = nil, 登録日: Day? = nil, 発注種類: 発注種類型? = nil, 注文番号: 注文番号型? = nil, 社員: 社員型? = nil, 資材番号: 図番型? = nil, 数量: Int? = nil) throws -> [発注型]{
        var query = FileMakerQuery()
        query["指定注文番号"] = 指定注文番号?.テキスト
        query["登録日"] = 登録日?.fmString
        query["注文番号"] = 注文番号?.記号
        query["発注種類"] = 発注種類?.description
        query["依頼社員番号"] = 社員?.Hなし社員コード
        query["資材番号"] = 資材番号
        if let num = 数量 {
            query["発注数量"] = "\(num)"
        }
        return try find(query: query)
    }
    
    public static func findDirect(送り状指定注文番号 str: String) throws -> 発注型? {
        guard let num = 指定注文番号型(str, day: Day()) else { return nil }
        var query = FileMakerQuery()
        query["指定注文番号"] = num.テキスト
        return try find(query: query).last
    }
}

// MARK:
extension Sequence where Element == 発注型 {
    public var 未納発注個数: Int {
        let limit = Day(2019, 12, 31)
        return self.reduce(0) {
            switch $1.補正済状態 {
            case .未処理, .発注待ち, .発注済み:
                if $1.登録日 < limit { return $0 }
                return $0 + ($1.発注数量 ?? 0)
            case .納品書待ち, .納品済み, .処理済み:
                return $0
            }
        }
    }
}
