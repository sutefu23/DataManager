//
//  ヤマト運輸.swift
//  DataManager
//
//  Created by manager on 2021/05/13.
//

import Foundation

extension 送状型 {
    public static let 運送会社名_ヤマト = "ヤマト"
}

private extension 送状型 {
    var 配達時間帯: String { self.isAM ? "0812" : "" }
}
    
public extension Sequence where Element == 送状型 {
    func exportヤマト送状CSV(to url: URL) throws {
        let generator = TableGenerator<送状型>()
            .string("お客様管理番号") { $0.管理番号 }
            .fix("送状種類") { "0" } // 発払い
            .fix("クール区分") { "" } // 通常
            .fix("伝票番号") { "" } // データ入力では空白　ヤマトの送状番号に置き換えられる
            .day("出荷予定日", .yearMonthDay) { $0.出荷納期 }
            .day("お届け予定(指定)日", .yearMonthDay) { $0.着指定日 }
            .string("配達時間帯") { return $0.配達時間帯 }
            .fix("お届け先コード") { "" } // TODO: ?確認
            .string("お届け先電話番号") { $0.届け先電話番号.toHalfCharacters }
            .fix("お届け先電話番号枝番") { "" }
            .string("お届け先郵便番号") { $0.届け先郵便番号.toHalfCharacters }
            .string("お届け先住所") { $0.届け先住所1 + " " + $0.届け先住所2 }
            .string("お届け先住所(アパートマンション名)") { $0.届け先住所3 }
            .fix("お届け先会社・部門名1") { "" }
            .fix("お届け先会社・部門名2") { "" }
            .string("お届け先名") { $0.届け先受取者名 }
            .fix("お届け先名略称カナ") { "" }
            .fix("敬称") { "なし" }
            .fix("ご依頼主コード") { "" } // TODO: ?確認
            .string("ご依頼主電話番号") { $0.依頼主電話番号.toHalfCharacters }
            .fix("ご依頼主電話番号枝番") { "" }
            .string("ご依頼主郵便番号") { $0.依頼主郵便番号.toHalfCharacters }
            .string("ご依頼主住所") { $0.依頼主住所1 + " " + $0.依頼主住所2 }
            .string("ご依頼主住所(アパートマンション名)") { $0.依頼主住所3 }
            .string("ご依頼主名") { $0.依頼主受取者名 }
            .fix("ご依頼主略称カナ") { "" }
            .fix("品名コード1") { "" }
            .string("品名1") { $0.品名 }
            .fix("品名コード2") { "" }
            .fix("品名2") { "" }
            .fix("荷扱い1") { "" }
            .fix("荷扱い2") { "" }
            .string("記事") { $0.記事 }
            .fix("コレクト代金引換額（税込）") { "" }
            .fix("コレクト内消費税金額") { "" }
            .fix("営業所止置き") { "" } // 0はしない
            .fix("営業所コード") { "" }
            .fix("発行枚数") { "" }
            .fix("個数口枠の印字") { "" }
            .fix("ご請求先顧客コード") { "" } // TODO: ?確認
            .fix("ご請求先分類コード") { "" } // TODO: ?確認
            .fix("運賃管理番号") { "" } // TODO: ?確認
            .fix("注文時カード払いデータ登録") { "" }
            .fix("注文時カード払い加盟店番号") { "" }
            .fix("注文時カード払い申込受付番号1") { "" }
            .fix("注文時カード払い申込受付番号2") { "" }
            .fix("注文時カード払い申込受付番号3") { "" }
            .fix("お届け予定eメール利用区分") { "" }
            .fix("お届け予定eメールe-mailアドレス") { "" }
            .fix("入力機種") { "" }
            .fix("お届け予定eメールメッセージ") { "" }
            .fix("お届け完了eメール利用区分") { "" }
            .fix("お届け完了eメールe-mailアドレス") { "" }
            .fix("お届け完了eメールメッセージ") { "" }
            .fix("クロネコ収納代行利用区分") { "" }
            .fix("収納代行決済QRコード印刷") { "" }
            .fix("収納代行請求金額(税込)") { "" }
            .fix("収納代行内消費税金額等") { "" }
            .fix("収納代行請求先郵便番号") { "" }
            .fix("収納代行請求先住所") { "" }
            .fix("収納代行請求先住所(アパートマンション名)") { "" }
            .fix("収納代行請求先会社・部門名1") { "" }
            .fix("収納代行請求先会社・部門名2") { "" }
            .fix("収納代行請求先名(漢字)") { "" }
            .fix("収納代行請求先名(カナ)") { "" }
            .fix("収納代行問合わせ先名(漢字)") { "" }
            .fix("収納代行問合わせ先郵便番号") { "" }
            .fix("収納代行問合わせ先住所") { "" }
            .fix("収納代行問合わせ先住所(アパートマンション名)") { "" }
            .fix("収納代行問合わせ先電話番号") { "" }
            .fix("収納代行管理番号") { "" }
            .fix("収納代行品名") { "" }
            .fix("収納代行備考") { "" }
            .fix("複数口くくりキー") { "" }
            .fix("検索キータイトル1") { "" }
            .fix("検索キー1") { "" }
            .fix("検索キータイトル2") { "" }
            .fix("検索キー2") { "" }
            .fix("検索キータイトル3") { "" }
            .fix("検索キー3") { "" }
            .fix("検索キータイトル4") { "" }
            .fix("検索キー4") { "" }
            .fix("検索キータイトル5") { "" }
            .fix("検索キー5") { "" }
            .fix("発行依頼先会社コード") { "" }
            .fix("発行依頼先分類コード") { "" }
        try generator.write(self, format: .excel(header: false), to: url)
    }
}

public struct ヤマト出荷実績型: Identifiable {
    public let id = serialGenerator.generateID()
    
    public let お客様管理番号 : String
    public let 送り状種別 : String
    public let クール区分 : String
    public let 伝票番号 : String
    public let 出荷予定日 : Day
    public let お届け予定（指定）日 : String
    public let 配達時間帯 : String
    public let お届け先コード : String
    public let お届け先電話番号 : String
    public let お届け先電話番号枝番 : String
    public let お届け先郵便番号 : String
    public let お届け先住所 : String
    public let お届け先住所（アパートマンション名） : String
    public let お届け先会社・部門名１ : String
    public let お届け先会社・部門名２ : String
    public let お届け先名 : String
    public let お届け先名略称カナ : String
    public let 敬称 : String
    public let ご依頼主コード : String
    public let ご依頼主電話番号 : String
    public let ご依頼主電話番号枝番 : String
    public let ご依頼主郵便番号 : String
    public let ご依頼主住所 : String
    public let ご依頼主住所（アパートマンション名） : String
    public let ご依頼主名 : String
    public let ご依頼主略称カナ : String
    public let 品名コード１ : String
    public let 品名１ : String
    public let 品名コード２ : String
    public let 品名２ : String
    public let 荷扱い１ : String
    public let 荷扱い２ : String
    public let 記事 : String
    public let コレクト代金引換額（税込） : String
    public let コレクト内消費税額等 : String
    public let 営業所止置き : String
    public let 営業所コード : String
    public let 発行枚数 : String
    public let 個数口枠の印字 : String
    public let ご請求先顧客コード : String
    public let ご請求先分類コード : String
    public let 運賃管理番号 : String
    public let 注文時カード払いデータ登録 : String
    public let 注文時カード払い加盟店番号 : String
    public let 注文時カード払い申込受付番号１ : String
    public let 注文時カード払い申込受付番号２ : String
    public let 注文時カード払い申込受付番号３ : String
    public let お届け予定ｅメール利用区分 : String
    public let お届け予定ｅメールemailアドレス : String
    public let 入力機種 : String
    public let お届け予定eメールメッセージ : String
    public let お届け完了ｅメール利用区分 : String
    public let お届け完了ｅメールemailアドレス : String
    public let お届け完了eメールメッセージ : String
    public let クロネコ収納代行利用区分 : String
    public let 収納代行決済ＱＲコード印刷 : String
    public let 収納代行請求金額（税込） : String
    public let 収納代行内消費税額等 : String
    public let 収納代行請求先郵便番号 : String
    public let 収納代行請求先住所 : String
    public let 収納代行請求先住所（アパートマンション名） : String
    public let 収納代行請求先会社・部門名１ : String
    public let 収納代行請求先会社・部門名２ : String
    public let 収納代行請求先名（漢字） : String
    public let 収納代行請求先名（カナ） : String
    public let 収納代行問合せ先名（漢字）: String
    public let 収納代行問合せ先郵便番号 : String
    public let 収納代行問合せ先住所 : String
    public let 収納代行問合せ先住所（アパートマンション名） : String
    public let 収納代行問合せ先電話番号 : String
    public let 収納代行管理番号 : String
    public let 収納代行品名 : String
    public let 収納代行備考 : String
    
    public init?(_ line: String) {
        let cols = line.csvColumns
        guard cols.count == 73 , let day1 = Day(yyyymmdd: cols[5]) else { return nil }
          
        self.お客様管理番号 = cols[1].dashStribbped
        self.送り状種別 = cols[2].dashStribbped
        self.クール区分 = cols[3].dashStribbped
        self.伝票番号 = cols[4].dashStribbped
        self.出荷予定日 = day1
        self.お届け予定（指定）日 = cols[6].dashStribbped
        self.配達時間帯 = cols[7].dashStribbped
        self.お届け先コード = cols[8].dashStribbped
        self.お届け先電話番号 = cols[9].dashStribbped
        self.お届け先電話番号枝番 = cols[10].dashStribbped
        self.お届け先郵便番号 = cols[11].dashStribbped
        self.お届け先住所 = cols[12].dashStribbped
        self.お届け先住所（アパートマンション名） = cols[13].dashStribbped
        self.お届け先会社・部門名１ = cols[14].dashStribbped
        self.お届け先会社・部門名２ = cols[15].dashStribbped
        self.お届け先名 = cols[16].dashStribbped
        self.お届け先名略称カナ = cols[17].dashStribbped
        self.敬称 = cols[18].dashStribbped
        self.ご依頼主コード = cols[19].dashStribbped
        self.ご依頼主電話番号 = cols[20].dashStribbped
        self.ご依頼主電話番号枝番 = cols[21].dashStribbped
        self.ご依頼主郵便番号 = cols[22].dashStribbped
        self.ご依頼主住所 = cols[23].dashStribbped
        self.ご依頼主住所（アパートマンション名） = cols[24].dashStribbped
        self.ご依頼主名 = cols[25].dashStribbped
        self.ご依頼主略称カナ = cols[26].dashStribbped
        self.品名コード１ = cols[27].dashStribbped
        self.品名１ = cols[28].dashStribbped
        self.品名コード２ = cols[29].dashStribbped
        self.品名２ = cols[30].dashStribbped
        self.荷扱い１ = cols[31].dashStribbped
        self.荷扱い２ = cols[32].dashStribbped
        self.記事 = cols[33].dashStribbped
        self.コレクト代金引換額（税込） = cols[34].dashStribbped
        self.コレクト内消費税額等 = cols[35].dashStribbped
        self.営業所止置き = cols[36].dashStribbped
        self.営業所コード = cols[37].dashStribbped
        self.発行枚数 = cols[38].dashStribbped
        self.個数口枠の印字 = cols[39].dashStribbped
        self.ご請求先顧客コード = cols[40].dashStribbped
        self.ご請求先分類コード = cols[41].dashStribbped
        self.運賃管理番号 = cols[42].dashStribbped
        self.注文時カード払いデータ登録 = cols[43].dashStribbped
        self.注文時カード払い加盟店番号 = cols[44].dashStribbped
        self.注文時カード払い申込受付番号１ = cols[45].dashStribbped
        self.注文時カード払い申込受付番号２ = cols[46].dashStribbped
        self.注文時カード払い申込受付番号３ = cols[47].dashStribbped
        self.お届け予定ｅメール利用区分 = cols[48].dashStribbped
        self.お届け予定ｅメールemailアドレス = cols[49].dashStribbped
        self.入力機種 = cols[50].dashStribbped
        self.お届け予定eメールメッセージ = cols[51].dashStribbped
        self.お届け完了ｅメール利用区分 = cols[52].dashStribbped
        self.お届け完了ｅメールemailアドレス = cols[53].dashStribbped
        self.お届け完了eメールメッセージ = cols[54].dashStribbped
        self.クロネコ収納代行利用区分 = cols[55].dashStribbped
        self.収納代行決済ＱＲコード印刷 = cols[56].dashStribbped
        self.収納代行請求金額（税込） = cols[57].dashStribbped
        self.収納代行内消費税額等 = cols[58].dashStribbped
        self.収納代行請求先郵便番号 = cols[59].dashStribbped
        self.収納代行請求先住所 = cols[60].dashStribbped
        self.収納代行請求先住所（アパートマンション名） = cols[61].dashStribbped
        self.収納代行請求先会社・部門名１ = cols[62].dashStribbped
        self.収納代行請求先会社・部門名２ = cols[63].dashStribbped
        self.収納代行請求先名（漢字） = cols[64].dashStribbped
        self.収納代行請求先名（カナ） = cols[65].dashStribbped
        self.収納代行問合せ先名（漢字） = cols[66].dashStribbped
        self.収納代行問合せ先郵便番号 = cols[67].dashStribbped
        self.収納代行問合せ先住所 = cols[68].dashStribbped
        self.収納代行問合せ先住所（アパートマンション名） = cols[69].dashStribbped
        self.収納代行問合せ先電話番号 = cols[70].dashStribbped
        self.収納代行管理番号 = cols[71].dashStribbped
        self.収納代行品名 = cols[72].dashStribbped
        self.収納代行備考 = cols[73].dashStribbped

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
