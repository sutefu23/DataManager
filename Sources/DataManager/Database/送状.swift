//
//  送状.swift
//  DataManager
//
//  Created by manager on 2021/01/21.
//

import Foundation

public final class 送状型: Identifiable {
    let record: FileMakerRecord

    init?(_ record: FileMakerRecord) {
        self.record = record
    }
    
    public var 管理番号: String { record.string(forKey: "管理番号")! }
    public var 同送情報: String { record.string(forKey: "同送情報")! }
    public var 種類: String { record.string(forKey: "種類")! }
    public var 送り状番号: String { record.string(forKey: "送り状番号")! }
    public var 運送会社: String { record.string(forKey: "運送会社")! }
    public var 着指定日: Day? { record.day(forKey: "着指定日") }
    public var 着指定時間: String { record.string(forKey: "着指定時間")! }
    public var 指示書UUID: String { record.string(forKey: "指示書UUID")! }
    public var 品名: String { record.string(forKey: "品名")! }
    public var 記事: String { record.string(forKey: "記事")! }
    public var 運送会社備考: String { record.string(forKey: "運送会社備考")! }
    public var 届け先郵便番号: String { record.string(forKey: "届け先郵便番号")! }
    public var 届け先住所1: String { record.string(forKey: "届け先住所1")! }
    public var 届け先住所2: String { record.string(forKey: "届け先住所2")! }
    public var 届け先住所3: String { record.string(forKey: "届け先住所3")! }
    public var 届け先受取者名: String { record.string(forKey: "届け先受取者名")! }
    public var 届け先電話番号: String { record.string(forKey: "届け先電話番号")! }
    public var 依頼主郵便番号: String { record.string(forKey: "依頼主郵便番号")! }
    public var 依頼主住所1: String { record.string(forKey: "依頼主住所1")! }
    public var 依頼主住所2: String { record.string(forKey: "依頼主住所2")! }
    public var 依頼主住所3: String { record.string(forKey: "依頼主住所3")! }
    public var 依頼主受取者名: String { record.string(forKey: "依頼主受取者名")! }
    public var 依頼主電話番号: String { record.string(forKey: "依頼主電話番号")! }
    public var 地域: String { record.string(forKey: "地域")! }
    
    public lazy var 指示書: 指示書型? = {
        try? 指示書型.findDirect(uuid: self.指示書UUID)
    }()
    
    public var 伝票番号: 伝票番号型? { record.伝票番号(forKey: "エッチング指示書テーブル::伝票番号") }
    public var 伝票種類: 伝票種類型? { record.伝票種類(forKey: "エッチング指示書テーブル::伝票種類") }
    public var 出荷納期: Day? { record.day(forKey: "エッチング指示書テーブル::出荷納期") }
    public var 発送事項: String? { record.string(forKey: "エッチング指示書テーブル::発送事項") }
}

extension 送状型 {
    static let dbName = "DataAPI_16"
    
    static func find(_ query: FileMakerQuery) throws -> [送状型] {
        if query.isEmpty { return [] }
        let db = FileMakerDB.pm_osakaname
        let list: [FileMakerRecord] = try db.find(layout: 送状型.dbName, query: [query])
        let result = list.compactMap { 送状型($0) }
        return result
    }
    
    public static func find(伝票番号: String, 運送会社名: String = "") throws -> [送状型] {
        var query = FileMakerQuery()
        if let order = try 指示書型.findDirect(伝票番号文字列: 伝票番号) {
            query["指示書UUID"] = order.uuid
        }
        if !運送会社名.isEmpty {
            query["運送会社"] = 運送会社名
        }
        return try find(query)
    }
    
    public static func find(出荷納期: Day, 運送会社名: String = "") throws -> [送状型] {
        var query = FileMakerQuery()
        query["エッチング指示書テーブル::出荷納期"] = 出荷納期.fmString
        if !運送会社名.isEmpty {
            query["運送会社"] = 運送会社名
        }
        return try find(query)
    }
    
    public static func findDirect(送状管理番号: String) throws -> 送状型? {
        var query = FileMakerQuery()
        query["管理番号"] = 送状管理番号
        return try find(query).first
    }
}
