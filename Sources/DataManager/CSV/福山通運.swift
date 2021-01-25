//
//  福山通運.swift
//  DataManager
//
//  Created by manager on 2021/01/21.
//

import Foundation

extension 送状型 {
    public static let 運送会社名_福山 = "福山"
}

// MARK: - 生産管理 -> 福山
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
            .string("送人コード") { $0.送人コード }
            .string("個数") { $0.個数 }
            .string("才数") { $0.才数 }
            .string("重量") { $0.重量 }
            .string("輸送商品1") { $0.輸送商品1 }
            .string("輸送商品2") { $0.輸送商品2 }
            .string("品名記事1") { $0.品名記事1 }
            .string("品名記事2") { $0.品名記事2 }
            .string("品名記事3") { $0.品名記事3 }
            .day("配達指定日", .yearMonthDayNumber) { $0.配達指定日 }
            .string("予備") { $0.予備 }
            .string("元払区分") { $0.元払区分 }
            .string("保険金額") { $0.保険金額 }
            .day("出荷日付", .yearMonthDayNumber) { $0.出荷日付 }
            .string("登録日付") { $0.登録日付 }
        try generator.write(self, format: .filemaker, to: url)
    }
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
    var 送人コード: String { "??????" }
    var 個数: String { "1" }
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
    var 品名記事1: String { String(self.品名.prefix(15)) }
    var 品名記事2: String { String(self.品名.dropFirst(15).prefix(15)) }
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

public struct 福山ご依頼主型 {
    public let 荷受人コード: String
    public let 電話番号: String
    public let 住所1: String
    public let 住所2: String
    public let 予備1: String
    public let 名前1: String
    public let 名前2: String
    public let 予備2: String
    public let 郵便番号: String
    public let カナ略称: String
    public let 才数: String
    public let 重量: String
    public let メールアドレス: String
    public let 請求先コード : String
    public let 請求先部課コード: String
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
        self.送り状番号 = String(cols[2])
        self.荷受人コード = String(cols[3])
        self.荷受人郵便番号 = String(cols[4])
        self.荷受人電話番号 = String(cols[5])
        self.荷受人住所1 = String(cols[6])
        self.荷受人住所2 = String(cols[7])
        self.荷受人住所3 = String(cols[8])
        self.荷受人名前1 = String(cols[9])
        self.荷受人名前2 = String(cols[10])
        self.特殊計 = String(cols[11])
        self.着店コード = String(cols[12])
        self.着店名 = String(cols[13])
        self.荷送人コード = String(cols[14])
        self.荷送人郵便番号 = String(cols[15])
        self.荷送人電話番号 = String(cols[16])
        self.荷送人住所1 = String(cols[17])
        self.荷送人住所2 = String(cols[18])
        self.荷送人名前1 = String(cols[19])
        self.荷送人名前2 = String(cols[20])
        self.個数 = String(cols[21])
        self.重量 = String(cols[22])
        self.指定日 = Day(yyyymmdd: cols[23])
        self.輸送商品1 = String(cols[24])
        self.輸送商品2 = String(cols[25])
        self.品名記事1 = String(cols[26])
        self.品名記事2 = String(cols[27])
        self.品名記事3 = String(cols[28])
        self.元着区分 = String(cols[29])
        self.保険金額 = String(cols[30])
        self.お客様管理番号 = String(cols[31])
        self.請求先コード = String(cols[32])
        self.請求先部課所コード = String(cols[33])
    }
    
    public var 対応送状: 送状型? {
        return try? 送状型.findDirect(送状管理番号: お客様管理番号)
    }
}

extension Array where Element == 福山出荷実績型 {
    public init(url: URL) throws {
        let text = try String(contentsOf: url, encoding: .shiftJIS)
        var result: [福山出荷実績型] = []
        text.enumerateLines {
            (line, _) in
            if let csv = 福山出荷実績型(line) {
                result.append(csv)
            }
        }
        self.init(result)
    }
    
    public func checkAll(day: Day?) throws -> (result: [福山出荷実績検証結果型], nodata: [送状型]) {
        var result: [福山出荷実績検証結果型] = []
        var orderMap: [String: 送状型] = [:]
        if let day = day {
            for order in try 送状型.find(出荷納期: day, 運送会社名: 送状型.運送会社名_福山) {
                orderMap[order.管理番号] = order
            }
        }
        var nodataMap = orderMap
        let map = Dictionary(grouping: self) { $0.お客様管理番号 }
        for orders in map.values {
            if orders.count >= 2 {
                result.append(contentsOf: orders.map { 福山出荷実績検証結果型(福山出荷実績: $0, 検証結果: .送状管理番号がかぶっている) } )
            } else {
                for order in orders {
                    let check: 福山出荷実績検証結果型.検証結果型
                    let key = order.お客様管理番号
                    if let send = orderMap[key] ?? order.対応送状 {
                        nodataMap[key] = nil
                        let number = send.送り状番号
                        if number.isEmpty {
                            check = .問題なし（送状番号未登録）
                        } else {
                            if number == order.送り状番号 {
                                check = .問題なし（送状番号登録済み）
                            } else {
                                check = .異なる送状番号が登録されている
                            }
                        }
                    } else {
                        check = .対応する送状が存在しない
                    }
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

public class 福山出荷実績検証結果型 {
    public enum 検証結果型: String {
        case 問題なし（送状番号未登録）
        case 問題なし（送状番号登録済み）
        case 対応する送状が存在しない
        case 異なる送状番号が登録されている
        case 送状管理番号がかぶっている
        
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
        case .対応する送状が存在しない, .異なる送状番号が登録されている, .送状管理番号がかぶっている:
            return false
        }
    }
    
    public var is登録対象: Bool {
        switch self.検証結果 {
        case .問題なし（送状番号未登録）:
            return true
        case .問題なし（送状番号登録済み）, .対応する送状が存在しない, .異なる送状番号が登録されている, .送状管理番号がかぶっている:
            return false
        }
    }
}
