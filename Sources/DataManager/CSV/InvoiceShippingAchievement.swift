//
//  送状出荷実績.swift
//  DataManager
//
//  Created by manager on 2021/07/12.
//

import Foundation

public struct 送状出荷実績型 {
    // 運送会社システムより
    public var 出荷日: Day
    public var 送状番号: String
    public var 管理番号: String
    public var 個数: Int
    
    // 送り状からの引き写し
    public var 着指定日: Day?
    public var 着指定時間: String
    public var 種類: String
    public var 品名: String
    public var 記事: String
    public var 同送情報: String
    public var 運送会社備考: String
    public var 届け先郵便番号: String
    public var 届け先住所1: String
    public var 届け先住所2: String
    public var 届け先住所3: String
    public var 届け先受取者名: String
    public var 届け先電話番号: String
    public var 依頼主郵便番号: String
    public var 依頼主住所1: String
    public var 依頼主住所2: String
    public var 依頼主住所3: String
    public var 依頼主受取者名: String
    public var 依頼主電話番号: String

    public init?(_ source: ヤマト出荷実績型) {
        guard source.宅急便伝票番号 == source.親伝票番号 else { return nil } // 子伝票は扱わない
        self.init(管理番号: source.お客様管理番号, 送状番号: source.宅急便伝票番号, 出荷日: source.荷札発行年月日, 個数: source.個口数)
    }
    
    public init?(_ source: 福山出荷実績型) {
        self.init(管理番号: source.お客様管理番号, 送状番号: source.送り状番号, 出荷日: source.出荷日付, 個数: Int(source.個数))
    }
    
    init?(管理番号: String, 送状番号: String, 出荷日: Day, 個数: Int?) {
        guard let order = try? 送状型.findDirect(送状管理番号: 管理番号) else { return nil }
        self.管理番号 = 管理番号
        self.送状番号 = 送状番号
        self.出荷日 = 出荷日
        self.個数 = 個数 ?? 1
        
        self.着指定日 = order.着指定日
        self.着指定時間 = order.着指定時間
        self.種類 = order.種類
        self.品名 = order.品名
        self.記事 = order.記事
        self.同送情報 = order.同送情報
        self.運送会社備考 = order.運送会社備考
        self.届け先郵便番号 = order.届け先郵便番号
        self.届け先住所1 = order.届け先住所1
        self.届け先住所2 = order.届け先住所2
        self.届け先住所3 = order.届け先住所3
        self.届け先受取者名 = order.届け先受取者名
        self.届け先電話番号 = order.届け先電話番号
        self.依頼主郵便番号 = order.依頼主郵便番号
        self.依頼主住所1 = order.依頼主住所1
        self.依頼主住所2 = order.依頼主住所2
        self.依頼主住所3 = order.依頼主住所3
        self.依頼主受取者名 = order.依頼主受取者名
        self.依頼主電話番号 = order.依頼主電話番号
    }
    
    var 送状: 送状型? {
        try? 送状型.findDirect(送状管理番号: self.管理番号)
    }
    
    var 伝票番号: 伝票番号型? {
        return 送状?.伝票番号
    }
    
    var 会社コード: String? {
        return 送状?.指示書?.会社コード
    }
}

extension 送状出荷実績型 {
    init?(_ line: String) {
        let cols = line.csvColumns
        guard cols.count == 23,
              let day0 = Day(fmDate: cols[0]),
              let int2 = Int(cols[2])
              else { return nil }
        self.出荷日 = day0
        self.送状番号 = String(cols[1])
        self.個数 = int2
        self.着指定日 = Day(fmDate: cols[3])
        self.着指定時間 = String(cols[4])
        self.種類 = String(cols[5])
        self.品名 = String(cols[6])
        self.記事 = String(cols[7])
        self.運送会社備考 = String(cols[8])
        self.同送情報 = String(cols[9])
        self.届け先郵便番号 = String(cols[10])
        self.届け先住所1 = String(cols[11])
        self.届け先住所2 = String(cols[12])
        self.届け先住所3 = String(cols[13])
        self.届け先受取者名 = String(cols[14])
        self.届け先電話番号 = String(cols[15])
        self.依頼主郵便番号 = String(cols[16])
        self.依頼主住所1 = String(cols[17])
        self.依頼主住所2 = String(cols[18])
        self.依頼主住所3 = String(cols[19])
        self.依頼主受取者名 = String(cols[20])
        self.依頼主電話番号 = String(cols[21])
        self.管理番号 = String(cols[22])
    }
    
    static func makeGenerator() -> TableGenerator<送状出荷実績型> {
        let gen = TableGenerator<送状出荷実績型>()
            .day("出荷日", .yearMonthDay) { $0.出荷日 } // cols[0]
            .string("送状番号番号") { $0.送状番号 } // cols[1]
            .integer("個数") { $0.個数 } // cols[2]
            .day("着指定日", .yearMonthDay) { $0.着指定日 } // cols[3]
            .string("着指定時間") { $0.着指定時間 } // cols[4]
            .string("種類") { $0.種類 } // cols[5]
            .string("品名") { $0.品名 } // cols[6]
            .string("記事") { $0.記事 } // cols[7]
            .string("運送会社備考") { $0.運送会社備考 } // cols[8]
            .string("同送情報") { $0.同送情報 } // cols[9]
            .string("届け先郵便番号") { $0.届け先郵便番号 } // cols[10]
            .string("届け先住所1") { $0.届け先住所1 } // cols[11]
            .string("届け先住所2") { $0.届け先住所2 } // cols[12]
            .string("届け先住所3") { $0.届け先住所3 } // cols[13]
            .string("届け先受取者名") { $0.届け先受取者名 } // cols[14]
            .string("届け先電話番号") { $0.届け先電話番号 } // cols[15]
            .string("依頼主郵便番号") { $0.依頼主郵便番号 } // cols[16]
            .string("依頼主住所1") { $0.依頼主住所1 } // cols[17]
            .string("依頼主住所2") { $0.依頼主住所2 } // cols[18]
            .string("依頼主住所3") { $0.依頼主住所3 } // cols[19]
            .string("依頼主受取者名") { $0.依頼主受取者名 } // cols[20]
            .string("依頼主電話番号") { $0.依頼主電話番号 } // cols[21]
            .string("管理番号") { $0.管理番号 } // cols[22]
        return gen
    }
}

extension Array where Element == 送状出荷実績型 {
    init(url: URL) throws {
        let text = try String(contentsOf: url, encoding: .shiftJIS)
        var result: [送状出荷実績型] = []
        var isFirst = true
        text.enumerateLines {
            (line, _) in
            if isFirst { // 先頭行はヘッダなのでスキップする
                isFirst = false
                return
            }
            if let csv = 送状出荷実績型(line) {
                result.append(csv)
            }
        }
        self.init(result)
    }
}

extension Sequence where Element == 送状出荷実績型 {
    /// 指定されたdirに出荷日の年月日フォルダを作成し、そこに伝票番号別、会社コード別にcsvを作成する
    public func export受け渡し送状(at dir: URL) throws {
        let map = Dictionary(grouping: self) { $0.出荷日 }
        
        for (day, list) in map {
            let base = dir
                .appendingPathComponent(day.yearString)
                .appendingPathComponent(day.monthString)
                .appendingPathComponent(day.dayString)
            try list.export受け渡し送状(at: base.appendingPathComponent("会社コード別")) { $0.会社コード }
            try list.export受け渡し送状(at: base.appendingPathComponent("伝票番号別")) { $0.伝票番号?.整数文字列 }
        }
    }

    /// 指定されたdirに、groupingで分類されたcsvを作成または追記する
    func export受け渡し送状(at dir: URL, grouping: (送状出荷実績型) -> String?) throws {
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let map: [(key: String, list: [送状出荷実績型])] = Dictionary(grouping: self) { grouping($0) ?? "指定なし" }.map { (key: $0.key, list: $0.value) }
        try map.concurrentForEach {
            let url = dir.appendingPathComponent("\($0.key).csv")
            try $0.list.append受け渡し送状(to: url)
        }
    }
    
    /// 最初に読み込み、重複を排除して、追記する。同じ管理番号の場合、追記が優先される
    func append受け渡し送状(to url: URL) throws {
        var map: [String: 送状出荷実績型] = [:]
        if let original = try? [送状出荷実績型](url: url) {
            original.forEach { map[$0.管理番号] = $0 }
        }
        self.forEach { map[$0.管理番号] = $0 }
        let list = map.values.sorted { $0.管理番号 < $1.管理番号 }
        let gen = 送状出荷実績型.makeGenerator()
        try gen.write(list, format: .excel(header: true), to: url)
    }
}
