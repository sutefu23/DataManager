//
//  送状.swift
//  DataManager
//
//  Created by manager on 2021/01/21.
//

import Foundation

public enum 送り状番号状態型 {
    /// 送り状番号指定もれ
    case 入力なし
    /// システムによる送り状番号割り当て処理を待っている状態
    case 処理待ち
    ///　運送会社の割り当てを待っている
    case 運送会社割当待ち
    /// 仮に割り当ててあり、出荷情報による確定待ち
    case 仮設定
    /// 仮に割り当ててある送り状番号は運送会社システムに転送されている
    case 仮番号印刷済み
    /// 送り状番号確定済み
    case 確定
}

public struct 送り状番号型 {
    /// 生データ
    public let rawValue: String
    /// 送り状番号
    public let 送り状番号: String?
    /// 種類
    public let 状態: 送り状番号状態型

    init(rawValue: String) {
        self.rawValue = rawValue
        var check = rawValue.toJapaneseNormal.spaceStripped
        if check.contains("出力済") {
            self.状態 = .運送会社割当待ち
            self.送り状番号 = nil
            return
        }
        if check.hasPrefix("仮:") {
            self.状態 = .仮設定
            check.removeFirst(2)
            self.送り状番号 = check
            return
        }
        if check.hasPrefix("出力:") || check.hasPrefix("印刷:") {
            self.状態 = .仮番号印刷済み
            check.removeFirst(3)
            self.送り状番号 = check
            return
        }
        if let value = Int(self.rawValue) {
            if value > 0 {
                self.状態 = .確定
                self.送り状番号 = self.rawValue
            } else {
                self.状態 = .処理待ち
                self.送り状番号 = nil
            }
        } else {
            self.状態 = .入力なし
            self.送り状番号 = nil
        }
    }
    
    public var ヤマト送状元番号: Int? {
        guard let str = self.送り状番号 else { return nil }
        return Int(str.dropLast())
    }
    
    public init(状態: 送り状番号状態型, 送り状番号: String? = nil, 運送会社: 運送会社型? = nil) {
        switch 状態 {
        case .入力なし:
            self.状態 = .入力なし
            self.送り状番号 = nil
            self.rawValue = ""
            return
        case .処理待ち:
            break
        case .運送会社割当待ち:
            let 社名 = 運送会社?.社名 ?? ""
            self.状態 = .運送会社割当待ち
            self.送り状番号 = nil
            self.rawValue = "\(社名)出力済"
            return
        case .仮設定:
            guard let str = 送り状番号, let value = Int(str), value > 0 else { break }
            self.rawValue = "仮: \(str)"
            self.状態 = .仮設定
            self.送り状番号 = str
            return
        case .仮番号印刷済み:
            guard let str = 送り状番号, let value = Int(str), value > 0 else { break }
                self.rawValue = "出力: \(str)"
            self.状態 = .仮番号印刷済み
            self.送り状番号 = str
            return
        case .確定:
            guard let str = 送り状番号, let value = Int(str), value > 0 else { break }
            self.rawValue = str
            self.状態 = .確定
            self.送り状番号 = str
            return
        }
        self.状態 = .処理待ち
        self.rawValue = "0"
        self.送り状番号 = nil
    }
}

/// 運送会社を規定する
public enum 運送会社型: Hashable {
    case ヤマト
    case セイノー
    case 福山
    case 佐川
    case その他(String)
    
    init(name: String) {
        switch name.toJapaneseNormal {
        case "ヤマト":
            self = .ヤマト
        case "セイノー":
            self = .セイノー
        case "福山":
            self = .福山
        case "佐川":
            self = .佐川
        default:
            self = .その他(name)
        }
    }
    
    public var 社名: String {
        switch self {
        case .ヤマト:
            return "ヤマト"
        case .セイノー:
            return "セイノー"
        case .福山:
            return "福山"
        case .佐川:
            return "佐川"
        case .その他(let name):
            return name
        }
    }
}

public class 送状型: Identifiable {
    let record: FileMakerRecord

    init?(_ record: FileMakerRecord) {
        guard let 管理番号 = record.string(forKey: "管理番号"),
            let 送り状番号 = record.string(forKey: "送り状番号"),
              let 運送会社 = record.string(forKey: "運送会社") else { return nil }
        self.管理番号 = 管理番号
        self.送り状番号 = 送り状番号型(rawValue: 送り状番号)
        self.運送会社 = 運送会社型(name: 運送会社)
        self.record = record
    }

    public func clone() -> 送状型 {
        let clone = 送状型(record)!
        clone.管理番号 = 管理番号
        clone.送り状番号 = 送り状番号
        clone.運送会社 = 運送会社
        return clone
    }
    
    public var 管理番号: String
    public var 送り状番号: 送り状番号型
    public var 運送会社: 運送会社型

    public var 同送情報: String { record.string(forKey: "同送情報")! }
    public var 種類: String { record.string(forKey: "種類")! }
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
    public var ヤマトお客様コード: String { record.string(forKey: "ヤマトお客様コード")! }
    public var 福山依頼主コード: String { record.string(forKey: "福山依頼主コード")! }
    
    public lazy var 指示書: 指示書型? = {
        try? 指示書型.findDirect(uuid: self.指示書UUID)
    }()
    
    public var 伝票番号: 伝票番号型? { record.伝票番号(forKey: "エッチング指示書テーブル::伝票番号") }
    public var 伝票種類: 伝票種類型? { record.伝票種類(forKey: "エッチング指示書テーブル::伝票種類") }
    public var 出荷納期: Day? { record.day(forKey: "エッチング指示書テーブル::出荷納期") }
    public var 発送事項: String? { record.string(forKey: "エッチング指示書テーブル::発送事項") }
    public var 伝票状態: 伝票状態型? { record.伝票状態(forKey: "エッチング指示書テーブル::伝票状態") }
    
    public lazy var isAM: Bool = {
        let str = self.着指定時間.toHalfCharacters.uppercased()
        return str.hasPrefix("AM")
    }()
    public var 個数: Int = 1
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
    
    public static func find(伝票番号: String? = nil, 送状番号: String? = nil, 運送会社名: String = "") throws -> [送状型] {
        var query = FileMakerQuery()
        if let number = 伝票番号, let order = try 指示書型.findDirect(伝票番号文字列: number) {
            query["指示書UUID"] = order.uuid
        }
        query["送り状番号"] = 送状番号
        if !運送会社名.isEmpty {
            query["運送会社"] = 運送会社名
        }
        return try find(query)
    }

    public static func find最近登録(基準登録日: Day, 運送会社: 運送会社型) throws -> [送状型] {
        var query = FileMakerQuery()
        query["登録日"] = ">\(基準登録日.fmString)"
        query["運送会社"] = 運送会社.社名
        return try find(query)
    }

    public static func find採番待ち(運送会社: 運送会社型) throws -> [送状型] {
        let today = Day()
        var query = FileMakerQuery()
        query["送り状番号"] = "=0"
        query["運送会社"] = 運送会社.社名
        return try find(query).filter {
            guard let order = $0.指示書 else { return false }
            if order.承認状態 == .未承認 { return false }
            switch order.伝票状態 {
            case .未製作, .製作中:
                return order.出荷納期 >= today
            case .キャンセル, .発送済:
                return false
            }
        }
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
    
    public init(
                郵便番号: String,
                住所1: String,
                住所2: String,
                住所3: String,
                名前: String,
                電話番号: String){
        self.郵便番号 = 郵便番号
        self.住所1 = 住所1
        self.住所2 = 住所2
        self.住所3 = 住所3
        self.名前 = 名前
        self.電話番号 = 電話番号        
    }
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

extension 住所型 {
    public func contains(to: 住所型) -> Bool {
//        if self.電話番号.contains("63360823") {
//            print("")
//        }
        return 郵便番号 == to.郵便番号 && 住所1.hasPrefix(to.住所1) && 住所2.hasPrefix(to.住所2) && 名前.contains(to.名前) && 電話番号 == 電話番号
    }
}

extension String {
    public var 修正済み住所1: String {
        var str = self.replacingOccurrences(of: "福岡県粕屋郡", with: "福岡県糟屋郡")
        if str.contains("糟屋郡") {
            str = str.replacingOccurrences(of: "須恵", with: "須惠")
        }
        return str
    }
}
