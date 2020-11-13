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
public final class 発注型 {
    let record: FileMakerRecord
    public let 発注種類: 発注種類型
    public let 資材: 資材型
    public let 指定注文番号: 指定注文番号型
    
    init?(_ record: FileMakerRecord) {
        self.record = record
        guard let type = record.発注種類(forKey: "発注種類") else { return nil }
        self.発注種類 = type
        switch type {
        case .資材:
            guard let item = record.資材(forKey: "図番") else { return nil }
            self.資材 = item
            guard let number = record.指定注文番号(forKey: "指定注文番号") else { return nil }
            self.指定注文番号 = number
        case .外注:
            self.資材 = 資材型.empty
            guard let text = record.string(forKey: "指定注文番号") else { return nil }
            self.指定注文番号 = 指定注文番号型(text: text)
        }
    }
    public var 状態: 発注状態型 { return record.発注状態(forKey: "状態")! }
}

public extension 発注型 {
    var 注文番号: 注文番号型 { return record.注文番号(forKey: "注文番号")! }
    var 会社名: String { return record.string(forKey: "会社名")! }
    var 会社コード: 会社コード型 { return record.string(forKey: "会社コード")! }
    var 会社: 取引先型? { return try? 取引先キャッシュ型.shared.キャッシュ取引先(会社コード: self.会社コード) }
    var 金額: String { return record.string(forKey: "金額")! }
    var 発注日: Day { return record.day(forKey: "発注日")! }
    var 登録日: Day { return record.day(forKey: "登録日")! }
    var 図番: String { return 資材.図番 }
    var 単位: String { return 資材.単位 }
    var 版数: String { return record.string(forKey: "版数")! }
    var 製品名称: String { return record.string(forKey: "製品名称")! }
    var 規格: String { return record.string(forKey: "規格")! }
    var 規格2: String { return record.string(forKey: "規格2")! }
    var 納品日: Day? { return record.day(forKey: "納品日") }
    var 納品書処理日: Day? { return record.day(forKey: "納品書処理日") }
    var 備考: String { return record.string(forKey: "備考")! }
    var 依頼社員: 社員型? { return record.社員(forKey: "依頼社員番号") }
    var 品名1: String { return self.製品名称 }
    var 品名2: String { return self.規格 }
    var 品名3: String { return self.規格2 }
    var 発注数量: Int? { return record.integer(forKey: "発注数量") }
    var 発注数量文字列: String { return record.string(forKey: "発注数量")! }
    
    var 補正済状態: 発注状態型 {
        guard let state = (try? 資材入庫状況キャッシュ型.shared.キャッシュ資材入庫状況(指定注文番号: self.指定注文番号)) else { return self.状態 }
        switch state.資材入庫状況状態 {
        case .入庫済:
            switch self.状態 {
            case .未処理, .発注済み, .発注待ち:
                return .納品書待ち
            case .処理済み, .納品書待ち, .納品済み:
                try? state.delete()
                return self.状態
            }
        }
    }
}

public enum 発注種類型: CustomStringConvertible {
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
        let db = FileMakerDB.pm_osakaname
        let list: [FileMakerRecord] = try db.find(layout: 発注型.dbName, query: [query])
        return list.compactMap { 発注型($0) }
    }

    static func find(API識別キー: UUID, session: FileMakerSession) throws -> [発注型] {
        var query = FileMakerQuery()
        query["API識別キー"] = "==\(API識別キー.uuidString)"
        let list: [FileMakerRecord] = try session.find(layout: 発注型.dbName, query: [query])
        return list.compactMap { 発注型($0) }
    }
    
    public static func find(登録期間: ClosedRange<Day>, 発注種類: 発注種類型, 版数: String?) throws -> [発注型] {
        var query = FileMakerQuery()
        query["登録日"] = makeQueryDayString(登録期間)
        query["発注種類"] = 発注種類.description
        if let han = 版数 {
            query["版数"] = "==\(han)"
        }
        let db = FileMakerDB.pm_osakaname
        let list: [FileMakerRecord] = try db.find(layout: 発注型.dbName, query: [query])
        return list.compactMap { 発注型($0) }
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
        let db = FileMakerDB.pm_osakaname
        let list: [FileMakerRecord] = try db.find(layout: 発注型.dbName, query: [query])
        return list.compactMap { 発注型($0) }
    }
    
    public static func findDirect(送り状指定注文番号 str: String) throws -> 発注型? {
        guard let num = 指定注文番号型(str, day: Day()) else { return nil }
        var query = FileMakerQuery()
        query["指定注文番号"] = num.テキスト
        let db = FileMakerDB.pm_osakaname
        let list: [FileMakerRecord] = try db.find(layout: 発注型.dbName, query: [query])
        return list.compactMap { 発注型($0) }.last
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
