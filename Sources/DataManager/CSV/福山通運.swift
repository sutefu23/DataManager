//
//  福山通運.swift
//  DataManager
//
//  Created by manager on 2021/01/21.
//

import Foundation

// MARK: - 生産管理 -> 福山
extension 送状型 {
    public static let 運送会社名_福山 = "福山"
}

private extension 送状型 {
    var 荷受人コード: String { "" }
    var 電話番号: String { 届け先電話番号 }
    var 住所: String { 届け先住所1 }
    var 住所2: String { 届け先住所2 }
    var 住所3: String { 届け先住所3 }
    var 名前: String { 届け先受取者名 }
    var 名前2: String { "" }
    var 郵便番号: String { 届け先郵便番号 }
    var 特殊計: String { "" }
    var 着店コード: String { "" }
    var 才数: String { "0" }
    var 重量: String { "0" }
    var 輸送商品1: String {
        if self.配達指定日 == nil { return "" }
        return 着指定時間.toHalfCharacters.contains("AM") ? "100" : "" // 時間指定
    }
    var 輸送商品2: String {
        if self.配達指定日 == nil { return "" }
        return 着指定時間.toHalfCharacters.contains("AM") ? "130" : "" // AM指定
    }
    var 品名記事1: String {
        String(self.品名.prefix(全角2文字: 30))
    }
    var 品名記事2: String { String(self.品名.dropFirst(全角2文字: 30).prefix(全角2文字: 30)) }
    var 品名記事3: String {
        if let number = self.伝票番号?.表示用文字列 {
            return number + " " + self.記事
        } else {
            return self.記事
        }
    }
    var 配達指定日: Day? { self.着指定日 }
    var 予備: String  { "" }
    var 元払区分: String { "1" }
    var 保険金額: String { "" }
    var 出荷日付: Day { 出荷納期! }
    var 登録日付: String  { "" }
}

extension Sequence where Element == 送状型 {
    public func export福山システムCSV(to url: URL) throws {
        let generator = TableGenerator<送状型>()
            .string("荷受人コード") { $0.荷受人コード }
            .string("電話番号") { $0.届け先電話番号 }
            .string("住所") { $0.届け先住所1 }
            .string("住所2") { $0.届け先住所2 }
            .string("住所3") { $0.届け先住所3 }
            .string("名前") { $0.名前 }
            .string("名前2") { $0.名前2 }
            .string("郵便番号") { $0.届け先郵便番号 }
            .string("特殊計") { $0.特殊計 }
            .string("着店コード") { $0.着店コード }
            .string("送人コード") { $0.福山依頼主コード }
            .integer("個数") { $0.個数 }
            .string("才数") { $0.才数 }
            .string("重量") { $0.重量 }
            .string("輸送商品1") { $0.輸送商品1 }
            .string("輸送商品2") { $0.輸送商品2 }
            .string("品名記事1") { $0.品名記事1 }
            .string("品名記事2") { $0.品名記事2 }
            .string("品名記事3") { $0.品名記事3 }
            .day("配達指定日", .yearMonthDayNumber) { $0.配達指定日 }
            .string("お客様管理番号") { $0.管理番号 }
            .string("予備") { $0.予備 }
            .string("元払区分") { $0.元払区分 }
            .string("保険金額") { $0.保険金額 }
            .day("出荷日付", .yearMonthDayNumber) { $0.出荷日付 }
            .string("登録日付") { $0.登録日付 }
        try generator.write(self, format: .excel(header: false), to: url)
    }
}

// MARK: -
public struct 福山ご依頼主型 {
    public var 荷受人コード: String
    public var 電話番号: String
    public var 住所1: String
    public var 住所2: String
    public var 予備1: String
    public var 名前1: String
    public var 名前2: String
    public var 予備2: String
    public var 郵便番号: String
    public var カナ略称: String
    public var 才数: String
    public var 重量: String
    public var メールアドレス: String
    public var 請求先コード : String
    public var 請求先部課コード: String

    public var 住所型: 住所型 {
        return DataManager.住所型(
            郵便番号: self.郵便番号,
            住所1: self.住所1,
            住所2: self.住所2,
            住所3: "",
            名前: self.名前1,
            電話番号:  self.電話番号
        )
    }

    public init(会社コード: String, 住所: 住所型) {
        self.荷受人コード = 会社コード
        self.電話番号 = 住所.電話番号
        self.住所1 = 住所.住所1
        self.住所2 = 住所.住所2 + 住所.住所3
        self.予備1 = ""
        self.名前1 = 住所.名前
        self.名前2 = ""
        self.予備2 = ""
        self.郵便番号 = 住所.郵便番号
        self.カナ略称 = ""
        self.才数 = "0"
        self.重量 = "0"
        self.メールアドレス = ""
        self.請求先コード = "0925181131"
        self.請求先部課コード = ""
    }
}
extension Array where Element == 福山ご依頼主型 {
    public init(url: URL) throws {
        let text = try String(contentsOf: url, encoding: .shiftJIS)
        var result: [福山ご依頼主型] = []
        text.enumerateLines {
            (line, _) in
            let fields = line.csvColumns
            if !fields.isEmpty && !fields[0].isEmpty {
                let ご依頼主 = 福山ご依頼主型(会社コード: fields[0].dashStribbped, 住所: 住所型(郵便番号: fields[8].dashStribbped, 住所1: fields[2].dashStribbped, 住所2: fields[3].dashStribbped + fields[4].dashStribbped, 住所3: "", 名前: fields[5].dashStribbped, 電話番号: fields[1].dashStribbped))
                result.append(ご依頼主)
            }

        }
        self.init(result)
    }
    
}

extension Sequence where Element == 福山ご依頼主型 {
    
    public func exportCSV(to url: URL) throws {
        let generator = TableGenerator<福山ご依頼主型>()
            .string("登録荷受人コード") { $0.荷受人コード }
            .string("電話番号") { $0.電話番号 }
            .string("住所1") { $0.住所1 }
            .string("住所2") { $0.住所2 }
            .string("予備1") { $0.予備1 }
            .string("名前1") { $0.名前1 }
            .string("名前2") { $0.名前2 }
            .string("予備2") { $0.予備2 }
            .string("郵便番号") { $0.郵便番号 }
            .string("カナ略称") { $0.カナ略称 }
            .string("才数") { $0.才数 }
            .string("重量") { $0.重量 }
            .string("メールアドレス") { $0.メールアドレス }
            .string("請求先コード") { $0.請求先コード }
            .string("請求先部課コード") { $0.請求先部課コード }
        try generator.write(self, format: .excel(header: false), to: url)
    }
}

// MARK: - 福山 -> 生産管理
public struct 福山出荷実績型: Identifiable {
    public let id = serialGenerator.generateID()
    
    public let 登録日付: Day
    public let 出荷日付: Day
    public let 送り状番号: String
    public let 荷受人コード: String
    public let 荷受人郵便番号: String
    public let 荷受人電話番号: String
    public let 荷受人住所1: String
    public let 荷受人住所2: String
    public let 荷受人住所3: String
    public let 荷受人名前1: String
    public let 荷受人名前2: String
    public let 特殊計: String
    public let 着店コード: String
    public let 着店名: String
    public let 荷送人コード: String
    public let 荷送人郵便番号: String
    public let 荷送人電話番号: String
    public let 荷送人住所1: String
    public let 荷送人住所2: String
    public let 荷送人名前1: String
    public let 荷送人名前2: String
    public let 個数: String
    public let 重量: String
    public let 指定日: Day?
    public let 輸送商品1: String
    public let 輸送商品2: String
    public let 品名記事1: String
    public let 品名記事2: String
    public let 品名記事3: String
    public let 元着区分: String
    public let 保険金額: String
    public let お客様管理番号: String
    public let 請求先コード: String
    public let 請求先部課所コード: String
    
    public init?(_ line: String) {
        let cols = line.csvColumns
        guard cols.count == 34,
              let day1 = Day(yyyymmdd: cols[0]),
              let day2 = Day(yyyymmdd: cols[1]) else { return nil }
        
        self.登録日付 = day1
        self.出荷日付 = day2
        self.送り状番号 = cols[2].dashStribbped
        self.荷受人コード = cols[3].dashStribbped
        self.荷受人郵便番号 = cols[4].dashStribbped
        self.荷受人電話番号 = cols[5].dashStribbped
        self.荷受人住所1 = cols[6].dashStribbped
        self.荷受人住所2 = cols[7].dashStribbped
        self.荷受人住所3 = cols[8].dashStribbped
        self.荷受人名前1 = cols[9].dashStribbped
        self.荷受人名前2 = cols[10].dashStribbped
        self.特殊計 = cols[11].dashStribbped
        self.着店コード = cols[12].dashStribbped
        self.着店名 = cols[13].dashStribbped
        self.荷送人コード = cols[14].dashStribbped
        self.荷送人郵便番号 = cols[15].dashStribbped
        self.荷送人電話番号 = cols[16].dashStribbped
        self.荷送人住所1 = cols[17].dashStribbped
        self.荷送人住所2 = cols[18].dashStribbped
        self.荷送人名前1 = cols[19].dashStribbped
        self.荷送人名前2 = cols[20].dashStribbped
        self.個数 = cols[21].dashStribbped
        self.重量 = cols[22].dashStribbped
        self.指定日 = Day(yyyymmdd: cols[23])
        self.輸送商品1 = cols[24].dashStribbped
        self.輸送商品2 = cols[25].dashStribbped
        self.品名記事1 = cols[26].dashStribbped
        self.品名記事2 = cols[27].dashStribbped
        self.品名記事3 = cols[28].dashStribbped
        self.元着区分 = cols[29].dashStribbped
        self.保険金額 = cols[30].dashStribbped
        self.お客様管理番号 = cols[31].dashStribbped
        self.請求先コード = cols[32].dashStribbped
        self.請求先部課所コード = cols[33].dashStribbped
    }
    
    public var 対応送状: 送状型? {
        return try? 送状型.findDirect(送状管理番号: お客様管理番号)
    }
    
    public func update生産管理送状番号() throws {
        guard let order = try 送状型.findDirect(送状管理番号: self.お客様管理番号), !order.is送り状番号設定済 && order.運送会社 == .福山 else { return }
        order.送り状番号 = self.送り状番号
        try order.upload送状番号()
    }
}

extension Array where Element == 福山出荷実績型 {
    public init(url: URL) throws {
        let text = try String(contentsOf: url, encoding: .shiftJIS)
        var result: [福山出荷実績型] = []
        var isFirst = true
        text.enumerateLines {
            (line, _) in
            if isFirst { // 先頭行はスキップする
                isFirst = false
                return
            }
            if let csv = 福山出荷実績型(line) {
                result.append(csv)
            }
        }
        self.init(result)
    }
    
    public func append送り状記録(at url: URL) throws {
        let records = self.compactMap { 送状出荷実績型($0) }
        try records.export受け渡し送状(at: url)
    }

    public func checkAll(day: Day?, isDebugMode: Bool = false) throws -> (result: [福山出荷実績検証結果型], nodata: [送状型]) {
        var result: [福山出荷実績検証結果型] = []
        var orderMap: [String: 送状型] = [:]
        if let day = day {
            for order in try 送状型.find(出荷納期: day, 運送会社名: 送状型.運送会社名_福山) {
                orderMap[order.管理番号] = order
            }
        }
        var nodataMap = orderMap
        
        func validate(order: 福山出荷実績型) -> 福山出荷実績検証結果型.検証結果型 {
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
                if number == order.送り状番号 {
                    return .問題なし（送状番号登録済み）
                } else {
                    return .異なる送状番号が登録されている
                }
            }
        }
        
        let map = Dictionary(grouping: self) { $0.お客様管理番号 }
        for orders in map.values {
            if orders.count >= 2 {
                result.append(contentsOf: orders.map { 福山出荷実績検証結果型(福山出荷実績: $0, 検証結果: .送状管理番号がかぶっている) } )
            } else {
                for order in orders {
                    let check = validate(order: order)
                    result.append(福山出荷実績検証結果型(福山出荷実績: order, 検証結果: check))
                }
            }
        }
        result.sort { $0.福山出荷実績.送り状番号 < $1.福山出荷実績.送り状番号 }
        let nodata = nodataMap.values.sorted {
            if let num0 = $0.伝票番号, let num1 = $1.伝票番号, num0 != num1 {
                return num0 < num1
            }
            return $0.管理番号 < $1.管理番号
        }
        return (result, nodata)
    }
}

public class 福山出荷実績検証結果型: Identifiable{
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
    
    public let 福山出荷実績: 福山出荷実績型
    public let 検証結果: 検証結果型
    public lazy var 対応送状: 送状型? = self.福山出荷実績.対応送状
    
    public init(福山出荷実績: 福山出荷実績型, 検証結果: 検証結果型) {
        self.福山出荷実績 = 福山出荷実績
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
