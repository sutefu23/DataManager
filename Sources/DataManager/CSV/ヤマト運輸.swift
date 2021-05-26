//
//  ヤマト運輸.swift
//  DataManager
//
//  Created by manager on 2021/05/13.
//

import Foundation

extension 送状型 {
    public static let 運送会社名_ヤマト = "ヤマト"
    
    /// ヤマト運輸として発送可能ならtrue
    public var ヤマト発送可能: Bool {
        if let order = self.指示書 {
            if order.isActive != true { return false } // 止まっているか終わっている
        }
        if let 出荷納期 = self.出荷納期 {
            if 出荷納期 < Day() { return false } // 出荷日が過去
            if let 着指定日 = self.着指定日, 着指定日 <= 出荷納期 { return false } // 着指定日が早すぎる
        }
        if 管理番号.isEmpty { return false }
        return true
    }
    
    fileprivate var ヤマト配達時間帯: String { self.isAM ? "0812" : "" }
}
    
public extension Sequence where Element == 送状型 {
    func exportヤマト送状CSV(to url: URL) throws {
        let today = Day().yearMonthDayNumberString
        let generator = TableGenerator<送状型>()
            .string("お客様管理番号") { $0.管理番号 } // 送り状レコードのレコードID
            .fix("伝票番号") { "" } // ヤマトのソフトで送状管理
//            .string("伝票番号") { $0.送り状番号 } // YamatoCSVで割り当て
            .day("出荷予定日", .yearMonthDay) { $0.出荷納期 } // FIXME: これでは先送りできない。対応必要
            .fix("届け先JISコード") { "" }
            .fix("届け先コード") { "" }
            .string("届け先名名称漢字") { $0.届け先受取者名.newlineToSpace }
            .string("届け先電話番号") { $0.届け先電話番号.toHalfCharacters }
            .string("届け先郵便番号") { $0.届け先郵便番号.toHalfCharacters }
            .string("届け先住所１") { $0.届け先住所1.newlineToSpace }
            .string("届け先住所２") { $0.届け先住所2.newlineToSpace }
            .string("届け先アパートマンション名") { $0.届け先住所3.newlineToSpace }
            .fix("届け先会社・部門名1") { "" }
            .fix("届け先会社・部門名2") { "" }
            .fix("依頼主コード") { "" }
            .string("依頼主名称漢字") { $0.依頼主受取者名.newlineToSpace }
            .string("依頼主電話番号") { $0.依頼主電話番号.toHalfCharacters }
            .string("依頼主郵便番号") { $0.依頼主郵便番号.toHalfCharacters }
            .string("依頼主住所１") { $0.依頼主住所1.newlineToSpace }
            .string("依頼主住所２") { $0.依頼主住所2.newlineToSpace }
            .string("依頼主アパートマンション") { $0.依頼主住所3.newlineToSpace }
            .fix("YGX顧客コード（電話番号）") { "0926112768" }
            .fix("YGX顧客コード（枝番）") { "" }
            .fix("荷扱区分1") { "" }
            .fix("荷扱区分2") { "" }
            .string("配達指示・備考") { $0.記事.newlineToSpace }
            .fix("コレクト金額") { "" }
            .string("品名コード1") { $0.伝票番号?.整数文字列 } // 伝票番号または空欄
            .string("品名名称1") { $0.品名.prefix(50).newlineToSpace } // 50文字で区切る
            .fix("品名コード2") { "" }
            .string("品名名称2") { $0.品名.dropFirst(50).newlineToSpace }
            .fix("サイズ品目コード") { "1101" }
            .day("配達指定日", .yearMonthDay) { $0.着指定日 }
            .string("配達時間帯") { $0.ヤマト配達時間帯 } // 指定がある場合、ヤマト形式で出力
            .integer("発行枚数") { $0.個数 }
            .fix("OMSフラグ") { "0" }
            .fix("更新日付") { today } // 出力日を入れる
            .fix("重量") { "0" }
            .fix("届け先FAX番号") { "" }
            .fix("届け先メールアドレス") { "" }
            .string("営業所止めフラグ") { $0.届け先受取者名.contains(oneOf: "営業所止め", "センター止め") ? "1" : "" }
            .fix("営業所止め店所コード") { "" }
            .fix("営業所止め店所名") { "" }
            .fix("記事1") { "" }
            .fix("記事2") { "" }
            .fix("記事3") { "" }
            .fix("記事4") { "" }
            .fix("記事5") { "" }
            .fix("予備") { "" }
        try generator.write(self, format: .excel(header: false), to: url, concurrent: true)
    }
}

public struct ヤマト出荷実績型: Identifiable {
    public let id = serialGenerator.generateID()
    
    public let お客様管理番号: String
    public let 伝票番号: String
    public let 出荷予定日: Day
    public let 届け先JISコード: String
    public let 届け先コード: String
    public let 届け先名称漢字: String
    public let 届け先電話番号: String
    public let 届け先郵便番号: String
    public let 届け先住所１: String
    public let 届け先住所２: String
    public let 届け先アパートマンション名: String
    public let 届け先会社・部門名１: String
    public let 届け先会社・部門名２: String
    public let 依頼主コード: String
    public let 依頼主名称漢字: String
    public let 依頼主電話番号: String
    public let 依頼主郵便番号: String
    public let 依頼主住所１: String
    public let 依頼主住所２: String
    public let 依頼主アパートマンション: String
    public let 依頼主会社・部門名１: String
    public let 依頼主会社・部門名２: String
    public let YGX顧客コード（電話番号）: String
    public let YGX顧客コード（枝番）: String
    public let 荷扱区分１: String
    public let 荷扱区分２: String
    public let 配達指示・備考: String
    public let コレクト金額: String
    public let クール区分: String
    public let 品名コード１: String
    public let 品名名称１: String
    public let 品名コード２: String
    public let 品名名称２: String
    public let サイズ品目コード１: String
    public let 配達指定日: Day?
    public let 配達時間帯: String
    public let 発行枚数: String
    public let OMSフラグ: String
    public let 更新日付: String
    public let 重量: String
    public let 届け先FAX番号: String
    public let 届け先メールアドレス: String
    public let 営業所止めフラグ: String
    public let 営業所止め店所コード: String
    public let 営業所止め店所名: String
    public let 記事１: String
    public let 記事２: String
    public let 記事３: String
    public let 記事４: String
    public let 記事５: String
    public let 予備: String
    
    public init?(_ line: String) {
        let cols = line.csvColumns
        guard cols.count == 51 , let day1 = Day(yyyymmdd: cols[3]) else { return nil }
        let day2 = Day(yyyymmdd: cols[35])

        self.お客様管理番号 = cols[1].dashStribbped
        self.伝票番号 = cols[2].dashStribbped
        self.出荷予定日 = day1
        self.届け先JISコード = cols[4].dashStribbped
        self.届け先コード = cols[5].dashStribbped
        self.届け先名称漢字 = cols[6].dashStribbped
        self.届け先電話番号 = cols[7].dashStribbped
        self.届け先郵便番号 = cols[8].dashStribbped
        self.届け先住所１ = cols[9].dashStribbped
        self.届け先住所２ = cols[10].dashStribbped
        self.届け先アパートマンション名 = cols[11].dashStribbped
        self.届け先会社・部門名１ = cols[12].dashStribbped
        self.届け先会社・部門名２ = cols[13].dashStribbped
        self.依頼主コード = cols[14].dashStribbped
        self.依頼主名称漢字 = cols[15].dashStribbped
        self.依頼主電話番号 = cols[16].dashStribbped
        self.依頼主郵便番号 = cols[17].dashStribbped
        self.依頼主住所１ = cols[18].dashStribbped
        self.依頼主住所２ = cols[19].dashStribbped
        self.依頼主アパートマンション = cols[20].dashStribbped
        self.依頼主会社・部門名１ = cols[21].dashStribbped
        self.依頼主会社・部門名２ = cols[22].dashStribbped
        self.YGX顧客コード（電話番号） = cols[23].dashStribbped
        self.YGX顧客コード（枝番） = cols[24].dashStribbped
        self.荷扱区分１ = cols[25].dashStribbped
        self.荷扱区分２ = cols[26].dashStribbped
        self.配達指示・備考 = cols[27].dashStribbped
        self.コレクト金額 = cols[28].dashStribbped
        self.クール区分 = cols[29].dashStribbped
        self.品名コード１ = cols[30].dashStribbped
        self.品名名称１ = cols[31].dashStribbped
        self.品名コード２ = cols[32].dashStribbped
        self.品名名称２ = cols[33].dashStribbped
        self.サイズ品目コード１ = cols[34].dashStribbped
        self.配達指定日 = day2
        self.配達時間帯 = cols[36].dashStribbped
        self.発行枚数 = cols[37].dashStribbped
        self.OMSフラグ = cols[38].dashStribbped
        self.更新日付 = cols[39].dashStribbped
        self.重量 = cols[40].dashStribbped
        self.届け先FAX番号 = cols[41].dashStribbped
        self.届け先メールアドレス = cols[42].dashStribbped
        self.営業所止めフラグ = cols[43].dashStribbped
        self.営業所止め店所コード = cols[44].dashStribbped
        self.営業所止め店所名 = cols[45].dashStribbped
        self.記事１ = cols[46].dashStribbped
        self.記事２ = cols[47].dashStribbped
        self.記事３ = cols[48].dashStribbped
        self.記事４ = cols[49].dashStribbped
        self.記事５ = cols[50].dashStribbped
        self.予備 = cols[51].dashStribbped

    }
    
    public var 対応送状: 送状型? {
        return try? 送状型.findDirect(送状管理番号: お客様管理番号)
    }
}

extension Array where Element == ヤマト出荷実績型 {
    public init(url: URL) throws {
        let text = try String(contentsOf: url, encoding: .shiftJIS)
        var result: [ヤマト出荷実績型] = []
        var isFirst = true
        text.enumerateLines {
            (line, _) in
            if isFirst { // 先頭行はスキップする
                isFirst = false
                return
            }
            if let csv = ヤマト出荷実績型(line) {
                result.append(csv)
            }
        }
        self.init(result)
    }
    
    public func checkAll(day: Day?, isDebugMode: Bool = false) throws -> (result: [ヤマト出荷実績検証結果型], nodata: [送状型]) {
        var result: [ヤマト出荷実績検証結果型] = []
        var orderMap: [String: 送状型] = [:]
        if let day = day {
            for order in try 送状型.find(出荷納期: day, 運送会社名: 送状型.運送会社名_ヤマト) {
                orderMap[order.管理番号] = order
            }
        }
        var nodataMap = orderMap
        
        func validate(order: ヤマト出荷実績型) -> ヤマト出荷実績検証結果型.検証結果型 {
            if isDebugMode { return .問題なし（送状番号未登録）}
            let key = order.お客様管理番号
            guard let send = order.対応送状  else { return .対応する送状が存在しない }
            nodataMap[key] = nil
            guard let data = send.指示書 else { return .対応する指示書が存在しない }
            guard data.伝票状態 != .キャンセル else { return .キャンセルされた伝票の送状 }
            let number = send.送り状番号
            if number.isEmpty || Int(number) == 0 {
                return .問題なし（送状番号未登録）
            } else {
                if number == order.伝票番号 {
                    return .問題なし（送状番号登録済み）
                } else {
                    return .異なる送状番号が登録されている
                }
            }
        }
        
        let map = Dictionary(grouping: self) { $0.お客様管理番号 }
        for orders in map.values {
            if orders.count >= 2 {
                result.append(contentsOf: orders.map { ヤマト出荷実績検証結果型(ヤマト出荷実績: $0, 検証結果: .送状管理番号がかぶっている) } )
            } else {
                for order in orders {
                    let check = validate(order: order)
                    result.append(ヤマト出荷実績検証結果型(ヤマト出荷実績: order, 検証結果: check))
                }
            }
        }
        result.sort { $0.ヤマト出荷実績.伝票番号 < $1.ヤマト出荷実績.伝票番号 }
        let nodata = nodataMap.values.sorted {
            if let num0 = $0.伝票番号, let num1 = $1.伝票番号, num0 != num1 {
                return num0 < num1
            }
            return $0.管理番号 < $1.管理番号
        }
        return (result, nodata)
    }
}

public class ヤマト出荷実績検証結果型: Identifiable{
    public enum 検証結果型: String {
        case 問題なし（送状番号未登録）
        case 問題なし（送状番号登録済み）
        case 対応する送状が存在しない
        case 対応する指示書が存在しない
        case 異なる送状番号が登録されている
        case 送状管理番号がかぶっている
        case キャンセルされた伝票の送状
        
        public var text: String { self.rawValue }
    }
    
    public let ヤマト出荷実績: ヤマト出荷実績型
    public let 検証結果: 検証結果型
    public lazy var 対応送状: 送状型? = self.ヤマト出荷実績.対応送状
    
    public init(ヤマト出荷実績: ヤマト出荷実績型, 検証結果: 検証結果型) {
        self.ヤマト出荷実績 = ヤマト出荷実績
        self.検証結果 = 検証結果
    }
    
    public var is問題なし: Bool {
        switch self.検証結果 {
        case .問題なし（送状番号未登録）, .問題なし（送状番号登録済み）:
            return true
        case .対応する送状が存在しない, .対応する指示書が存在しない, .異なる送状番号が登録されている, .送状管理番号がかぶっている, .キャンセルされた伝票の送状:
            return false
        }
    }
    
    public var is登録対象: Bool {
        switch self.検証結果 {
        case .問題なし（送状番号未登録）:
            return true
        case .問題なし（送状番号登録済み）, .対応する送状が存在しない, .対応する指示書が存在しない, .異なる送状番号が登録されている, .送状管理番号がかぶっている, .キャンセルされた伝票の送状:
            return false
        }
    }
}
