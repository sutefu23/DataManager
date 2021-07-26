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
    
    fileprivate var ヤマト配達時間帯: String { self.isAM ? "1200" : "" }
    
    public func makeヤマト子伝票() -> [送状型] {
        var count = self.個数
        var result: [送状型] = []
        while count > 1 {
            guard let number = ヤマト送状管理システム型.shared.子伝票番号割り当て() else { return [] }
            let child = self.clone()
            child.送り状番号 = 送り状番号型(状態: .仮設定, 送り状番号: number)
            result.append(child)
            count -= 1
        }
        return result
    }
}

public extension Sequence where Element == 送状型 {
    func exportヤマト送状CSV(to url: URL) throws {
        try url.prepareDirectory()

        let today = Day().yearMonthDayNumberString
        let children = self.reduce([]) { $0 + $1.makeヤマト子伝票() } // 複数小口に関しては子伝票が必要
        let generator = TableGenerator<送状型>()
            .string("お客様管理番号") { $0.管理番号 } // 送り状レコードのレコードID
            .string("送状番号") { $0.送り状番号.送り状番号 } // ヤマトのソフトで送状管理
            .day("出荷予定日", .yearMonthDay) { $0.出荷納期 } // 先送りは想定していない
            .fix("届け先JISコード") { "" }
            .fix("届け先コード") { "" }
            .string("届け先名名称漢字") { $0.届け先受取者名.newlineToSpace.dropHeadSpaces }
            .string("届け先電話番号") { $0.届け先電話番号.toHalfCharacters }
            .string("届け先郵便番号") { $0.届け先郵便番号.toHalfCharacters }
            .string("届け先住所１") { $0.届け先住所1.修正済み住所1.newlineToSpace }
            .string("届け先住所２") { $0.届け先住所2.newlineToSpace }
            .string("届け先アパートマンション名") { $0.依頼主受取者名.isEmpty ? "" : $0.届け先住所3.newlineToSpace }
            .fix("届け先会社・部門名1") { "" }
            .fix("届け先会社・部門名2") { "" }
            .fix("依頼主コード") { "" }
            .string("依頼主名称漢字") { ($0.依頼主受取者名.isEmpty ? $0.届け先住所3 : $0.依頼主受取者名).newlineToSpace }
            .string("依頼主電話番号") { $0.依頼主電話番号.toHalfCharacters }
            .string("依頼主郵便番号") { $0.依頼主郵便番号.toHalfCharacters }
            .string("依頼主住所１") { $0.依頼主住所1.修正済み住所1.newlineToSpace }
            .string("依頼主住所２") { $0.依頼主住所2.newlineToSpace }
            .string("依頼主アパートマンション") { $0.依頼主住所3.newlineToSpace }
            .fix("依頼主会社・部門名1") { "" }
            .fix("依頼主会社・部門名2") { "" }
            .string("YGX顧客コード（電話番号）") { $0.ヤマトお客様コード }
            .fix("YGX顧客コード（枝番）") { "" }
            .fix("荷扱区分1") { "" }
            .fix("荷扱区分2") { "" }
            .string("配達指示・備考") { $0.記事.newlineToSpace + " " + ($0.伝票番号?.整数文字列 ?? "") }
            .fix("コレクト金額") { "" }
            .fix("クール区分") { "0" } // 0:通常
            .string("品名コード1") { $0.伝票番号?.整数文字列 } // 伝票番号または空欄
            .string("品名名称1") { $0.品名.newlineToSpace.prefix(全角2文字: 50) } // 50文字で区切る
            .fix("品名コード2") { "" }
            .string("品名名称2") { $0.品名.newlineToSpace.dropFirst(全角2文字: 50).prefix(全角2文字: 50) }
            .fix("サイズ品目コード") { "1101" }
            .day("配達指定日", .yearMonthDay) { $0.着指定日 }
            .string("配達時間帯") { $0.ヤマト配達時間帯 } // 指定がある場合、ヤマト形式で出力
            .fix("発行枚数") { "1" }
            .fix("OMSフラグ") { "0" }
            .fix("更新日付") { today } // 出力日を入れる
            .fix("重量") { "1000" }
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
        try generator.write(self + children, format: .excel(header: false), to: url, concurrent: true)
    }
}

public struct ヤマト出荷実績型 {
    public var お客様管理番号: String // cols[0]
    public var 宅急便伝票番号: String // cols[1]
    public var 個口数: Int // cols[2]
    public var 荷札発行年月日: Day // cols[3]
    public var 親伝票番号: String // cols[4]
    
    init?(_ line: String) {
        let cols = line.csvColumns
        guard cols.count == 5 && Int(cols[0]) != nil && Int(cols[1]) != nil,
              let count = Int(cols[2]),
              let day = Day(yyyymmdd: cols[3]) else { return nil }
        self.お客様管理番号 = String(cols[0])
        self.宅急便伝票番号 = String(cols[1])
        self.個口数 = count
        self.荷札発行年月日 = day
        self.親伝票番号 = String(cols[4])
    }
    
    public func update生産管理送状番号() throws {
        guard 宅急便伝票番号 == 親伝票番号, // 親伝票のみ出力する
              let order = try 送状型.findDirect(送状管理番号: self.お客様管理番号),
              order.ヤマト出荷実績戻し待ち else { return }
        order.送り状番号 = 送り状番号型(状態: .確定, 送り状番号: self.親伝票番号)
        try order.upload送状番号()
    }
}

extension Array where Element == ヤマト出荷実績型 {
    public init(url: URL) throws {
        let text = try String(contentsOf: url, encoding: .shiftJIS)
        var result: [ヤマト出荷実績型] = []
        var isFirst = true
        text.enumerateLines {
            (line, _) in
            if isFirst { // 先頭行はヘッダなのでスキップする
                isFirst = false
                return
            }
            if let csv = ヤマト出荷実績型(line) {
                result.append(csv)
            }
        }
        self.init(result)
    }

    public func append送り状記録(at url: URL) throws {
        let records = self.compactMap { 送状出荷実績型($0) }
        try records.export受け渡し送状(at: url)
    }
}
