//
//  取引先.swift
//  DataManager
//
//  Created by manager on 2020/03/24.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation
public typealias 会社コード型 = String

public enum 分類型: String{
    case 見込み = "見込み"
    case 顧客 = "顧客"
    case 発注先 = "発注先"
}

public final class 取引先型: FileMakerSearchObject, Identifiable {
    public static var layout: String { "DataAPI_14" }

    static let 外注先会社コード: Set<String> = ["2971", "2993", "4442",  "3049", "3750"]

    public let recordId: FileMakerRecordID?
    public let 会社コード: 会社コード型
    public let 会社名: String
    public let 印字会社名: String
    public let 分類: 分類型?
    public let 郵便番号: String
    public let 住所1: String
    public let 住所2: String
    public let 住所3: String
    public let 代表者名称: String
    public let 代表TEL: String
    public let 直通TEL: String
    public let 社員名称: String

    public var memoryFootPrint: Int {
        return 12*16
    }
    
    public init(_ record: FileMakerRecord) throws {
        func makeError(_ key: String) -> Error { record.makeInvalidRecordError(name: "取引先", mes: key) }
        func getString(_ key: String) throws -> String {
            guard let string = record.string(forKey: key) else { throw makeError(key) }
            return string
        }
        self.会社コード = try getString("会社コード")
        self.会社名 = try getString("会社名")
        self.印字会社名 = try getString("印字会社名")
        self.分類 = 分類型(rawValue: try getString("分類"))
        self.郵便番号 = try getString("郵便番号")
        self.住所1 = try getString("住所1")
        self.住所2 = try getString("住所2")
        self.住所3 = try getString("住所3")
        self.代表者名称 = try getString("代表者名称")
        self.代表TEL = try getString("代表TEL")
        self.直通TEL = try getString("直通TEL")
        self.社員名称 = try getString("社員名称")
        self.recordId = record.recordId
    }
    public convenience init?(会社コード: String) throws {
        guard let record = try Self.findRecords(query: ["会社コード" : "==\(会社コード)"]).first else { return nil }
        try self.init(record)
    }

    public var 電話番号: String { return 代表TEL.isEmpty ? 直通TEL : 代表TEL }
    public var is原稿社名不要: Bool { self.会社コード.is原稿社名不要会社コード }
    public var is管理用: Bool { self.会社コード.is管理用会社コード }
    
    public lazy var 株有なし社名 = self.calc株有なし社名()
    private func calc株有なし社名() -> String {
        var name = self.会社名.toJapaneseNormal
        if name.hasPrefix("㈱") || name.hasPrefix("㈲") { name.removeFirst() }
        if name.hasPrefix("(株)") || name.hasPrefix("(有)") { name.removeFirst(3) }
        if name.hasSuffix("㈱") || name.hasSuffix("㈲") { name.removeLast() }
        if name.hasSuffix("(株)") || name.hasSuffix("(有)") { name.removeLast(3) }
        while name.hasPrefix(" ") { name.removeFirst() }
        while name.hasSuffix(" ") { name.removeLast() }
        return name
    }
    
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
        switch self.会社コード {
        case "1842": return name1.contains("テクノサイン") && name.contains("テクノサイン")
        case "4836": return name1 == "VOICEDESIGN" && name == "ボイスデザイン"
        case "4934": return name1 == "My工房" && name == "mykoubou"
        default:
            return false
        }
    }
}

extension 取引先型 {
//    static let dbName = "DataAPI_14"
//
    public static func find(会社コード: 会社コード型) throws -> 取引先型? {
        return try find(query: ["会社コード" : "==\(会社コード)"]).first
    }

    public static func find(分類: 分類型) throws -> [取引先型] {
        return try find(query: ["分類" : "\(分類)"])
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

let 管理用会社コードSet: Set<会社コード型> = Set<会社コード型>(管理用会社コード一覧)

let 管理用会社コード一覧: [会社コード型] = [
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
let 原稿社名不要会社コードSet: Set<会社コード型> = Set<会社コード型>(原稿社名不要会社コード一覧)

let 原稿社名不要会社コード一覧: [会社コード型] = [
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
    //    "2564", // ミナミ工芸㈱
]
