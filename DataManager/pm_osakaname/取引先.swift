//
//  取引先.swift
//  DataManager
//
//  Created by manager on 2020/03/24.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation
public typealias 会社コード型 = String

public final class 取引先型 {
    let record: FileMakerRecord

    init?(_ record: FileMakerRecord) {
        self.record = record
    }
    public init?(会社コード code: String) throws {
        guard let record = try 取引先型.find(会社コード: code)?.record else { return nil }
        self.record = record
    }
    
    public var 会社コード: 会社コード型 { return record.string(forKey: "会社コード")! }
    public var 会社名: String { return record.string(forKey: "会社名")! }
    public var 分類: String { return record.string(forKey: "分類")! }
    
    public var is原稿社名不要: Bool { 原稿社名不要会社コードSet.contains(self.会社コード) }
}

extension 取引先型 {
    static let dbName = "DataAPI_14"

    static func find(会社コード: 会社コード型) throws -> 取引先型? {
        let db = FileMakerDB.pm_osakaname
        var query = FileMakerQuery()
        query["会社コード"] = "==\(会社コード)"
        let list: [FileMakerRecord] = try db.find(layout: 取引先型.dbName, query: [query])
        return list.compactMap { 取引先型($0) }.first
    }
}

var 原稿社名不要会社コードSet: Set<会社コード型> = {
    Set<会社コード型>(原稿社名不要会社コード一覧)
}()

var 原稿社名不要会社コード一覧: [会社コード型] = [
    "2014", // 西田塗料
    "1647", // 高松ホットスタンプ
    "2093", // ハマジ北九州
    "2152", // ハマジ熊本
    "2112", // ハマジ久留米
    "2111", // ハマジ長崎
    "2153", // ハマジ福岡ビジネスヘッド
    "2130", // ハマジ福岡東
    "3441", // ハマジ大分
    "4028", // 新星社
    "1881", // トンボ
    "2728", // ユニコン
    "2724", // ユニコン 米子
    "3156", // RGB
    "2339", // 福田商事
    "2898", // オミノ
    "4248", // オミノ大阪営業所
    "0831", // 城戸工芸
    "2620", // メイク広告
//    "2564", // ミナミ工芸㈱
    "3659", // ㈲ミナミ工芸
    "2052", // 東洋銘板
    "3073", // 東洋銘板
    "0695", // 大山板金
    "0456", // 梅電社
    "2214", // 広島ネームプレート
    "2579", // 美濃クラフト
    "1681", // タカショーデジテック
    "2286", // 福彫
]
