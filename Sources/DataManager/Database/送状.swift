//
//  送状.swift
//  DataManager
//
//  Created by manager on 2021/01/21.
//

import Foundation
//import CoreLocation

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

public struct 送り状番号型: CustomStringConvertible {
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
    
    public var isValid: Bool { return !ハイフンなし生データ.isEmpty }
    public var description: String { self.rawValue }
    
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
    
    public var ハイフンなし生データ: String { return rawValue.filter { $0 != "-" } }
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

public class 送状型: Identifiable, FileMakerSearchObject {
    public static let layout = "DataAPI_16"

    public let recordId: FileMakerRecordID?

    public var 管理番号: String
    public var 送り状番号: 送り状番号型
    public var 運送会社: 運送会社型
    public var 福山依頼主コード: String

    public let 同送情報: String
    public let 種類: String
    public let 着指定日: Day?
    public let 着指定時間: String
    public let 指示書UUID: UUID
    public let 品名: String
    public let 記事: String
    public let 運送会社備考: String
    public let 届け先郵便番号: String
    public let 届け先住所1: String
    public let 届け先住所2: String
    public let 届け先住所3: String
    public let 届け先受取者名: String
    public let 届け先電話番号: String
    public let 依頼主郵便番号: String
    public let 依頼主住所1: String
    public let 依頼主住所2: String
    public let 依頼主住所3: String
    public let 依頼主受取者名: String
    public let 依頼主電話番号: String
    public let 地域: String
    public let ヤマトお客様コード: String

    public let 伝票番号: 伝票番号型?
    public let 伝票種類: 伝票種類型?
    public let 出荷納期: Day?
    public let 発送事項: String?
    public let 伝票状態: 伝票状態型?
    
    required public init(_ record: FileMakerRecord) throws {
        func makeError(_ key: String) -> Error { record.makeInvalidRecordError(name: Self.name, mes: key) }
        func getString(_ key: String) throws -> String {
            guard let string = record.string(forKey: key) else { throw makeError(key) }
            return string
        }
        guard let 指示書UUID = record.uuid(forKey: "指示書UUID") else { throw makeError("指示書UUID") }
        self.指示書UUID = 指示書UUID
        
        self.管理番号 = try getString("管理番号")
        self.送り状番号 = try 送り状番号型(rawValue: getString("送り状番号"))
        self.福山依頼主コード = try getString("福山依頼主コード")
        self.運送会社 = try 運送会社型(name: getString("運送会社"))
        
        self.同送情報 = try getString("同送情報")
        self.種類 = try getString("種類")
        self.着指定日 = record.day(forKey: "着指定日")
        self.着指定時間 = try getString("着指定時間")
        self.品名 = try getString("品名")
        self.記事 = try getString("記事")
        self.運送会社備考 = try getString("運送会社備考")
        self.届け先郵便番号 = try getString("届け先郵便番号")
        self.届け先住所1 = try getString("届け先住所1")
        self.届け先住所2 = try getString("届け先住所2")
        self.届け先住所3 = try getString("届け先住所3")
        self.届け先受取者名 = try getString("届け先受取者名")
        self.届け先電話番号 = try getString("届け先電話番号")
        self.依頼主郵便番号 = try getString("依頼主郵便番号")
        self.依頼主住所1 = try getString("依頼主住所1")
        self.依頼主住所2 = try getString("依頼主住所2")
        self.依頼主住所3 = try getString("依頼主住所3")
        self.依頼主受取者名 = try getString("依頼主受取者名")
        self.依頼主電話番号 = try getString("依頼主電話番号")
        self.地域 = try getString("地域")
        self.ヤマトお客様コード = try getString("ヤマトお客様コード")

        self.recordId = record.recordId

        self.伝票番号 = record.伝票番号(forKey: "エッチング指示書テーブル::伝票番号")
        self.伝票種類 = record.伝票種類(forKey: "エッチング指示書テーブル::伝票種類")
        self.出荷納期 = record.day(forKey: "エッチング指示書テーブル::出荷納期")
        self.発送事項 = record.string(forKey: "エッチング指示書テーブル::発送事項")
        self.伝票状態 = record.伝票状態(forKey: "エッチング指示書テーブル::伝票状態")
    }

    init(_ original: 送状型) {
        self.recordId = original.recordId
        self.管理番号 = original.管理番号
        self.送り状番号 = original.送り状番号
        self.福山依頼主コード = original.福山依頼主コード
        self.運送会社 = original.運送会社
        self.同送情報 = original.同送情報
        self.種類 = original.種類
        self.着指定日 = original.着指定日
        self.着指定時間 = original.着指定時間
        self.指示書UUID = original.指示書UUID
        self.品名 = original.品名
        self.記事 = original.記事
        self.運送会社備考 = original.運送会社備考
        self.届け先郵便番号 = original.届け先郵便番号
        self.届け先住所1 = original.届け先住所1
        self.届け先住所2 = original.届け先住所2
        self.届け先住所3 = original.届け先住所3
        self.届け先受取者名 = original.届け先受取者名
        self.届け先電話番号 = original.届け先電話番号
        self.依頼主郵便番号 = original.依頼主郵便番号
        self.依頼主住所1 = original.依頼主住所1
        self.依頼主住所2 = original.依頼主住所2
        self.依頼主住所3 = original.依頼主住所3
        self.依頼主受取者名 = original.依頼主受取者名
        self.依頼主電話番号 = original.依頼主電話番号
        self.地域 = original.地域
        self.ヤマトお客様コード = original.ヤマトお客様コード
        
        self.伝票番号 = original.伝票番号
        self.伝票種類 = original.伝票種類
        self.出荷納期 = original.出荷納期
        self.発送事項 = original.発送事項
        self.伝票状態 = original.伝票状態
    }
    
    public var memoryFootPrint: Int { return 50 * 8} // 仮設定のため適当

    public func clone() -> 送状型 { return 送状型(self) }
    
    public lazy var 指示書: 指示書型? = {
        try? 指示書型.findDirect(uuid: self.指示書UUID)
    }()
    
    public lazy var 依頼主住所: 住所型 = {
        return 住所型(郵便番号: self.依頼主郵便番号 , 住所1: self.依頼主住所1, 住所2: self.依頼主住所2, 住所3: self.依頼主住所3, 名前: self.依頼主受取者名 , 電話番号: self.依頼主電話番号)
    }()
    
    public lazy var isAM: Bool = {
        let str = self.着指定時間.toHalfCharacters.uppercased()
        return str.hasPrefix("AM")
    }()
    public var 個数: Int = 1
}

extension 送状型 {
    public static func find(伝票番号: String? = nil, 送状番号: String? = nil, 運送会社名: String = "") throws -> [送状型] {
        var query = FileMakerQuery()
        if let number = 伝票番号型(invalidNumber: 伝票番号), let order = try 指示書伝票番号キャッシュ型.shared.find(number) {
            query["指示書UUID"] = order.uuid.uuidString
        }
        query["送り状番号"] = 送状番号
        if !運送会社名.isEmpty {
            query["運送会社"] = 運送会社名
        }
        return try find(query: query)
    }

    public static func find最近登録(基準登録日: Day, 運送会社: 運送会社型) throws -> [送状型] {
        var query = FileMakerQuery()
        query["登録日"] = ">\(基準登録日.fmString)"
        query["運送会社"] = 運送会社.社名
        return try find(query: query)
    }

    public static func find採番待ち(運送会社: 運送会社型) throws -> [送状型] {
        let today = Day()
        var query = FileMakerQuery()
        query["送り状番号"] = "=0"
        query["運送会社"] = 運送会社.社名
        return try find(query: query).filter {
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
        return try find(query: query)
    }
    
    public static func findDirect(送状管理番号: String) throws -> 送状型? {
        var query = FileMakerQuery()
        query["管理番号"] = 送状管理番号
        return try find(query: query).first
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
        return 郵便番号 == to.郵便番号 && 住所1.hasPrefix(to.住所1) && 住所2.hasPrefix(to.住所2) && 名前.contains(to.名前) && 電話番号 == 電話番号
    }

//    public static func 郵便番号存在チェック(_ zip: String) -> ([CLPlacemark]?, error: Error?){
//        let sem = DispatchSemaphore(value: 0)
//        let geocoder = CLGeocoder()
//        var result: (place: [CLPlacemark]?, error: Error?) = (nil, nil)
//        DispatchQueue.global().async {
//            geocoder.geocodeAddressString(zip, completionHandler: {(placemarks, error) -> Void in
//                result = (placemarks, error)
//                sem.signal()
//            })
//        }
//        return result
//    }
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
