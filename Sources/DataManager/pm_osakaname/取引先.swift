//
//  取引先.swift
//  DataManager
//
//  Created by manager on 2020/03/24.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation
public typealias 会社コード型 = String

public enum 分類型 : String{
    case 見込み = "見込み"
    case 顧客 = "顧客"
    case 発注先 = "発注先"
}

public final class 取引先型: Identifiable {
    let record: FileMakerRecord

    init?(_ record: FileMakerRecord) {
        self.record = record
        guard let 会社コード = record.string(forKey: "会社コード") else { return nil }
        self.会社コード = 会社コード
    }
    public init?(会社コード code: String) throws {
        guard let record = try 取引先型.find(会社コード: code)?.record else { return nil }
        self.会社コード = code
        self.record = record
    }
    
    public var 会社コード: 会社コード型
    public var 会社名: String { return record.string(forKey: "会社名")! }
    public var 印字会社名: String { return record.string(forKey: "印字会社名")! }
    public var 分類: 分類型 { return 分類型(rawValue: record.string(forKey: "分類")!)! }
    public var 郵便番号: String { return record.string(forKey: "郵便番号")! }
    public var 住所1: String { return record.string(forKey: "住所1")! }
    public var 住所2: String { return record.string(forKey: "住所2")! }
    public var 住所3: String { return record.string(forKey: "住所3")! }
    public var 代表者名称: String { return record.string(forKey: "代表者名称")! }
    public var 代表TEL: String { return record.string(forKey: "代表TEL")! }
    public var 直通TEL: String { return record.string(forKey: "直通TEL")! }

    public var 電話番号: String { return 代表TEL.isEmpty ? 直通TEL : 代表TEL }
    
    public var is原稿社名不要: Bool { self.会社コード.is原稿社名不要会社コード }
    public var is管理用: Bool { self.会社コード.is管理用会社コード }
    
    public func is社名マッチ(to name: String) -> Bool {
        let name = name.比較用文字列
        if name.contains("(仮)") { return true }
        let name1 = 会社名.比較用文字列
        let name2 = 印字会社名.比較用文字列
        if name == name1 || name == name2 { return true }
        if name.count <= 1 { return false }
        if name1.count > 1 && (name1.hasPrefix(name) || name.hasPrefix(name1)) { return true }
        if name2.count > 1 && (name2.hasPrefix(name) || name.hasPrefix(name2)) { return true }
        // 特殊ケース
        if self.会社コード == "4836" && name1 == "VOICEDESIGN" && name == "ボイスデザイン" { return true }
        if self.会社コード == "4934" && name1 == "My工房" && name == "mykoubou" { return true }
        return false
    }
}

extension 取引先型 {
    static let dbName = "DataAPI_14"

    public static func find(会社コード: 会社コード型) throws -> 取引先型? {
        let db = FileMakerDB.pm_osakaname
        var query = FileMakerQuery()
        query["会社コード"] = "==\(会社コード)"
        let list: [FileMakerRecord] = try db.find(layout: 取引先型.dbName, query: [query])
        return list.compactMap { 取引先型($0) }.first
    }

    public static func find(分類: 分類型) throws -> [取引先型]? {
        let db = FileMakerDB.pm_osakaname
        var query = FileMakerQuery()
        query["分類"] = "\(分類)"
        
        let list: [FileMakerRecord] = try db.find(layout: 取引先型.dbName, query: [query])
        return list.compactMap { 取引先型($0) }
    }
}

// MARK: - 管理用
extension 会社コード型 {
    public var is管理用会社コード: Bool {
        管理用会社コードSet.contains(self)
    }
    
    public var is原稿社名不要会社コード: Bool {
        原稿社名不要会社コード一覧.contains(self)
    }
}

var 管理用会社コードSet: Set<会社コード型> = {
    Set<会社コード型>(管理用会社コード一覧)
}()

var 管理用会社コード一覧: [会社コード型] = [
    "3105", // 自社分
    "3205", // 個人
    "0333", // 宮下部長
    "0334", // 山本副部長
    "0337", // 業務
    "0338", // 棚木
    "0339", // 東京
    "0340", // 大阪
    "0342", // 末松
    "0344", // 古賀
    "0345", // 佐々木
    "0346", // 平野
    "0347", // 大里
    "0348", // 山内
    "4896", // 下拂
]
// MARK: - 原稿名不要
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
    "1882", // トレード
    "2052", // 東洋銘板
    "3073", // 東洋銘板
    "0695", // 大山板金
    "0456", // 梅電社
    "2214", // 広島ネームプレート
    "2579", // 美濃クラフト
    "1681", // タカショーデジテック
    "2286", // 福彫
]
