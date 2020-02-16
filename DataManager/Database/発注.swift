//
//  発注.swift
//  DataManager
//
//  Created by manager on 8/9/1 R.
//  Copyright © 1 Reiwa 四熊泰之. All rights reserved.
//

import Foundation

public class 発注型 {
    let record: FileMakerRecord
    
    init?(_ record: FileMakerRecord) {
        self.record = record
    }
    
    var 状態: String { return record.string(forKey: "状態")! }
    var 種類: String { return record.string(forKey: "種類")! }
}

public extension 発注型 {
    var 注文番号: String { return record.string(forKey: "注文番号")! }
    var 会社名: String { return record.string(forKey: "会社名")! }
    var 会社コード: String { return record.string(forKey: "会社コード")! }
    var 金額: String { return record.string(forKey: "金額")! }
    var 発注日: Day { return record.day(forKey: "発注日")! }
    var 登録日: Day { return record.day(forKey: "登録日")! }
    var 図番: String { return record.string(forKey: "図番")! }
    var 版数: String { return record.string(forKey: "版数")! }
    var 製品名称: String { return record.string(forKey: "製品名称")! }
    var 規格: String { return record.string(forKey: "規格")! }
    var 規格2: String { return record.string(forKey: "規格2")! }
    var 納品日: Day { return record.day(forKey: "納品日")! }
    var 備考: String { return record.string(forKey: "備考")! }
    var 依頼社員: 社員型 { return record.社員(forKey: "依頼社員番号")! }
    var 品名1: String { return self.製品名称 }
    var 品名2: String { return self.規格 }
    var 品名3: String { return self.規格2 }
    var 発注数量: Int? { return record.integer(forKey: "発注数量") }
    var 発注数量文字列: String { return record.string(forKey: "発注数量")! }
}

extension 発注型 {
    public static let dbName = "DataAPI_4"
    
    public static func find(伝票番号: 伝票番号型) throws -> [発注型] {
        var query = FileMakerQuery()
        query["伝票番号"] = "==\(伝票番号.整数値)"
        let db = FileMakerDB.pm_osakaname
        let list: [FileMakerRecord] = try db.find(layout: 発注型.dbName, query: [query])
        return list.compactMap { 発注型($0) }
    }
    public static func find(API識別キー: UUID) throws -> [発注型] {
        var query = FileMakerQuery()
        query["API識別キー"] = "==\(API識別キー.uuidString)"
        let db = FileMakerDB.pm_osakaname
        let list: [FileMakerRecord] = try db.find(layout: 発注型.dbName, query: [query])
        return list.compactMap { 発注型($0) }
    }
    
    public static func find(登録日: Day? = nil, 注文番号: String? = nil, 社員: 社員型? = nil, 資材番号: String? = nil, 数量: Int? = nil) throws -> [発注型]{
        var query = FileMakerQuery()
        query["登録日"] = 登録日?.fmString
        query["注文番号"] = 注文番号
        query["依頼社員番号"] = 社員?.Hなし社員コード
        query["資材番号"] = 資材番号
        if let num = 数量 {
            query["発注数量"] = "\(num)"
        }
        let db = FileMakerDB.pm_osakaname
        let list: [FileMakerRecord] = try db.find(layout: 発注型.dbName, query: [query])
        return list.compactMap { 発注型($0) }
    }
}
