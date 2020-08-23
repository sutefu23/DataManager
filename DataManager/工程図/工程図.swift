//
//  工程図.swift
//  DataManager
//
//  Created by manager on 2019/02/12.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

public final class 工程図型 {
    public static var empty: 工程図型 {
        let zu = 工程図型()
        zu.カレンダ情報 = [カレンダ情報型(カレンダID: 0, カレンダ名称: "デフォルト")]
        zu.作業別工程情報 = [作業別工程情報型(第1階層グループ名称: "新しいグループ")]
        zu.区分情報1 = [区分情報型(第1階層グループ名称: "新しいグループ")]
        zu.区分情報2 = [区分情報型(第1階層グループ名称: "新しいグループ")]
        zu.区分情報3 = [区分情報型(第1階層グループ名称: "新しいグループ")]
        zu.区分情報4 = [区分情報型(第1階層グループ名称: "新しいグループ")]
        return zu
    }
    
    public var 資源マスタ情報: [資源マスタ情報型]
    public var 供給資源情報: [供給資源情報型]
    public var カレンダ情報: [カレンダ情報型]
    public var 作業別工程情報: [作業別工程情報型]
    public var 必要資源情報: [必要資源情報型]
    public var コンストレイン情報: [コンストレイン情報型]
    public var 区分情報1: [区分情報型]
    public var 区分情報2: [区分情報型]
    public var 区分情報3: [区分情報型]
    public var 区分情報4: [区分情報型]
    public var マイルストーン情報 : [マイルストーン情報型]
    
    public init() {
        self.資源マスタ情報 = []
        self.供給資源情報 = []
        self.カレンダ情報 = []
        self.作業別工程情報 = []
        self.必要資源情報 = []
        self.コンストレイン情報 = []
        self.区分情報1 = []
        self.区分情報2 = []
        self.区分情報3 = []
        self.区分情報4 = []
        self.マイルストーン情報 = []
    }
    
    public func makeFile() -> FileWrapper {
        let file = FileWrapper(directoryWithFileWrappers: [
            資源マスタ情報型.filename: 資源マスタ情報.makeFile(),
            供給資源情報型.filename: 供給資源情報.makeFile(),
            カレンダ情報型.filename: カレンダ情報.makeFile(),
            作業別工程情報型.filename: 作業別工程情報.makeFile(),
            必要資源情報型.filename: 必要資源情報.makeFile(),
            コンストレイン情報型.filename: コンストレイン情報.makeFile(),
            区分情報型.filename1: 区分情報1.makeFile(),
            区分情報型.filename2: 区分情報2.makeFile(),
            区分情報型.filename3: 区分情報3.makeFile(),
            区分情報型.filename4: 区分情報4.makeFile(),
            マイルストーン情報型.filename: マイルストーン情報.makeFile()
            ]
        )
        return file
    }
    
    public func export(to url: URL) throws {
        let file = makeFile()
        try file.write(to: url, options: .atomic, originalContentsURL: nil)
    }
}

public extension 工程図型 {
    enum 山積みグラフ表示型: Int, RawRepresentable {
        case 表示なし = 0
        case 表示あり = 1
        case 使用時のみ = 2
        
        var code: String { return self.rawValue.description }
    }
    
    enum 曜日型: String, RawRepresentable {
        case 日曜日 = "SUN"
        case 月曜日 = "MON"
        case 火曜日 = "TUE"
        case 水用日 = "WED"
        case 木曜日 = "THU"
        case 金曜日 = "FRI"
        case 土曜日 = "SAT"
        
        var code: String { return self.rawValue }
    }
    
    enum 編集不可型: Int, RawRepresentable {
        case 編集可 = 0
        case 編集不可 = 1

        var code: String { return self.rawValue.description }
    }
    enum テキストの表示位置型: Int, RawRepresentable {
        case 左 = 0
        case 中央 = 1

        var code: String { return self.rawValue.description }
    }

    enum オンオフ型: Int, RawRepresentable {
        case オフ = 0
        case オン = 1

        var code: String { return self.rawValue.description }
    }
    
    enum 必要資源情報タイプ型: Int, RawRepresentable {
        case レベル = 0
        case トータル = 1

        var code: String { return self.rawValue.description }
    }
    
    enum コンストレインタイプ型: Int, RawRepresentable {
        case ＦＳ = 0
        case ＦＦ = 1
        case ＳＳ = 2
        case ＳＦ = 3

        var code: String { return self.rawValue.description }
    }
    
    enum 描画順序型: Int, RawRepresentable {
        case 縦から = 0
        case 横から = 1
        case 直線で結ぶ = 2
        case 直線で結ぶ（矢印無し） = 3
        case 縦から太線 = 8
        case 横から太線 = 9
        case 直線太線 = 10
        case 直線太線（矢印無し） = 11

        var code: String { return self.rawValue.description }
    }

}

// MARK: -
public protocol 工程図データ型 {
    func makeColumns() -> [String?]
    static var header : String { get }
    static var filename : String { get }
}

public extension Sequence where Element : 工程図データ型 {
    func makeFile() -> FileWrapper {
        let columnsCount = Element.header.split(separator: "\t").count
        var text = "\(Element.header)\n"
        for object in self {
            let columns : [String] = object.makeColumns().map { $0 ?? "" }
            assert((columns.count+1) == columnsCount)
            let line = columns.joined(separator: "\t") + "\tEOR\n"
            text.append(line)
        }
        let data = text.data(using: .shiftJIS, allowLossyConversion: true) ?? Data()
        let file = FileWrapper(regularFileWithContents: data)
        return file
    }
}

public extension Day {
    var 工程図年月日 : String {
        var result = "\(year)/"
        result += (month < 10) ? "0\(month)/" : "\(month)/"
        result += (day < 10) ? "0\(day)" : "\(day)"
        return result
    }

}

public extension Time {
    var 工程図時分 : String {
        var result = hour < 10 ? "0\(hour):" : "\(hour):"
        result += (minute < 10) ? "0\(minute)" : "\(minute)"
        return result
    }
}

public extension Date {
    var 工程図日時 : String {
        return day.工程図年月日 + " " + time.工程図時分
    }
}

extension Int {
    var 工程図番号 : String { return "\(self)" }
}
