//
//  送状.swift
//  DataManager
//
//  Created by manager on 2021/01/21.
//

import Foundation

public class 送状型: Identifiable {
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
    public var 伝票状態: 伝票状態型? { record.伝票状態(forKey: "エッチング指示書テーブル::伝票状態") }
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
    
    public var 送り主住所: 住所型 {
        return 住所型(郵便番号: self.依頼主郵便番号, 住所1: self.依頼主住所1, 住所2: self.依頼主住所2, 住所3: self.依頼主住所3, 名前: self.依頼主受取者名, 電話番号: self.依頼主電話番号)
    }
    public var 送り先住所: 住所型 {
        return 住所型(郵便番号: self.届け先郵便番号, 住所1: self.届け先住所1, 住所2: self.届け先住所2, 住所3: self.届け先住所3, 名前: self.届け先受取者名, 電話番号: self.届け先電話番号)
    }
}

public struct 住所型: Hashable {
    public var 郵便番号: String
    public var 住所1: String
    public var 住所2: String
    public var 住所3: String
    public var 名前: String
    public var 電話番号: String
    
    public var 比較用データ: 住所型 {
        return 住所型(
            郵便番号: self.郵便番号.toHalfCharacters.spaceStripped.filter { $0 != "-" },
            住所1: self.住所1.比較用文字列,
            住所2: self.住所2.比較用文字列,
            住所3: self.住所3.比較用文字列,
            名前: self.名前.比較用文字列,
            電話番号: self.電話番号.toHalfCharacters.spaceStripped.filter { $0 != "-" }
        )
    }
}

extension 住所型 {
    init?(会社コード: 会社コード型) throws {
        guard let company = try 取引先型.find(会社コード: 会社コード) else { return nil }
        self.郵便番号 = company.郵便番号
        self.住所1 = company.住所1
        self.住所2 = company.住所2
        self.住所3 = company.住所3
        if company.印字会社名.count <= 20 {
            self.名前 = company.印字会社名
        } else {
            self.名前 = String(company.会社名.prefix(20))
        }
        self.電話番号 = company.代表TEL
    }
}

extension 送状型 {
    public var is福山発送ok: Bool {
        let test = self.送り主住所.比較用データ
        for addr in 住所型.福山送り主一覧比較用.map ({ $0.住所 }) {
            if addr.contains(to: test) {
                return true
            }
        }
        return false
    }
}

extension 住所型 {
    public func contains(to: 住所型) -> Bool {
        return 郵便番号 == to.郵便番号 && 住所1.hasPrefix(to.住所1) && 住所2.hasPrefix(to.住所2) && 住所3.hasPrefix(to.住所3) && 名前.contains(to.名前) && 電話番号 == 電話番号
    }
    
    static let 福山送り主一覧Set: Set<住所型> = {
        Set<住所型>(福山送り主一覧.map { $0.住所.比較用データ })
    }()
    
    public static let 福山送り主一覧: [(会社コード: String, 住所: 住所型)] = {
        var list: [(会社コード: String, 住所: 住所型)] = [
            ("3105", 住所型(郵便番号: "811-2232", 住所1: "福岡県糟屋郡志免町", 住所2: "別府西1-1-8", 住所3: "", 名前: "株式会社オオサカネーム", 電話番号: "092-518-1131")),
            ("2579", 住所型(郵便番号: "501-6002", 住所1: "岐阜県羽島郡岐南町", 住所2: "三宅3-228", 住所3: "", 名前: "㈱ 美濃クラフト", 電話番号: "058-248-3000")),
            ("3659", 住所型(郵便番号: "535-0022", 住所1: "大阪市旭区", 住所2: "新森3-5-1", 住所3: "", 名前: "㈲　ミナミ工芸", 電話番号: "06-6955-6363")),
            ]
        for code in [
            "2579", "3659",
            "0297", "3160", "3161", "3163", // アボック社
            "2365", "2370", "2371", // 富士プラスチック
            "2543", // 宮崎硝子
            "1616", // タナチョー
            "0566", // エムズ
            "4444", // ㈱　リーズ
            "0866", "3395", "0828", // ㈱北浦製作所
            "1082", // ㈲コスモ創制社
            "1246", // サインプロダクト スミヨシ
            "3269", // ㈲サンキュー
            "1507", "1494", "3990", "4101", "4326", "3949", "1484", "3231", "1495", "1513", "1505", "3882", "1485", "3692", "1493", "4866", "1491", "1482", "1483", "4831", "1481", "3259", // 杉田エース
            "1490", "1497", "4196", "1509", "1488", "1498", "1502", "1510", "1492", "1496", "3826", "1486", "1515", "1487", "1489", "4796", "4789", "4715", "4682", "1480", "4764", "4718", // 杉田エース
            "3153", // ㈲　たくみ
            "3325", // 辻マーク㈱
            "3227", // 東信工業㈱
            "2624", // ㈱　ハートビル東海
            "3532", // ㈲ヒダカアート工房
            "4044", // ㈱文宣
            "2532", // ㈱ミネルヴァ・コーポレーション
            "3723", // ㈲明光房
            "2661", // 山本機工　㈱
            "2341", // ㈱　エース
            "0587", // ㈲エースサイン
            "1564", // ㈱セイユウ工芸
            "1177", // ㈲サイン開発
            "2450", // ㈲鳳文堂
            "1094", // コンダ工芸
            "1085", // ㈲幸宣社
            "2214", // 広島ネームプレート
        ] {
            guard let addr = try? 住所型(会社コード: code) else { continue }
            list.append((code, addr))
        }
        return list
    }()

    public static let 福山送り主一覧比較用: [(会社コード: String, 住所: 住所型)] = 住所型.福山送り主一覧.map { ($0.会社コード, $0.住所.比較用データ) }
}
