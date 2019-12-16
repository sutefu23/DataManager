//
//  TableGenerator.swift
//  DataManager
//
//  Created by 四熊泰之 on R 1/11/24.
//  Copyright © Reiwa 1 四熊泰之. All rights reserved.
//

import Foundation

/// 出力するファイル形式
public enum CSVTarget {
    case excel
    case numbers
    
    var encoding: String.Encoding {
        switch self {
        case .excel:
            return .shiftJIS
        case .numbers:
            return .utf8
        }
    }
}

/// テーブルの形式を指定する
public class TableGenerator<S, A> where A: Aggregator, A.Element == S {
    let columns: [TableColumn<S>]
    let aggregator: A

    /// 空のジェネレーター
    public convenience init() {
        let a = NullAggregator<S>() as! A
        self.init([], aggregator: a)
    }
    
    public convenience init(aggregator: A) {
        self.init([], aggregator: aggregator)
    }

    init(_ columns: [TableColumn<S>], aggregator:A) {
        self.columns = columns
        self.aggregator = aggregator
    }

    /// 与えられたデータを元にテーブルを作成する
    public func makeData(_ source: [S], of format: CSVTarget, to url: URL) -> Data {
        func join(rows: [String]) -> String {
            switch format {
            case .excel:
                return rows.map { "\"\($0)\"" }.joined(separator: ",") + "\n"
            case .numbers:
                return rows.joined(separator: "\t") + "\n"
            }
        }
        let header = join(rows: columns.map { $0.name })
        var lines: [String] = [header]
        for data in source {
            let rows = columns.map { $0.cell(of: data, for: format) }
            let line = join(rows: rows)
            lines.append(line)
        }
        for lineResult in self.aggregator.makeResult(columns: columns) {
            let footer = join(rows: lineResult)
            lines.append(footer)
        }
        let data = lines.joined().data(using: format.encoding, allowLossyConversion: true)
        return data ?? Data()
    }

    /// 与えられたデータをurlに出力する
    public func write(_ source: [S], of format: CSVTarget, to url: URL) throws {
        let data = makeData(source, of: format, to: url)
        try data.write(to: url, options: .atomicWrite)
    }

    /// 与えられたデータをもとにHTMLを作成する
    public func makeHtml(_ source: [S], title: String = "") -> String {
        func makeRow(_ data:[String], tag:String = "td") -> String {
            var line = "<tr>"
            for d in data {
                line += "<\(tag)>\(d)</\(tag)>"
            }
            line += "</tr>"
            return line
        }
        var line : String = ""
        line += "<!DOCTYPE html>"
        line += "<html>"
        line += "<head>"
        line += "<title>\(title)</title>"
        line += "</head>"
        line += "<body>"
        line += #"<p><table border="1">"#
        let header = self.columns.map { $0.name }
        line += makeRow(header)
        for data in source {
            let body = self.columns.map { $0.cell(of: data, for: .numbers)}
            line += makeRow(body)
        }
        for lineResult in self.aggregator.makeResult(columns: columns) {
            line += makeRow(lineResult)
        }
        line += "</table></p>"
        line += "</body>"
        line += "</html>"
        return line
    }

    // MARK: -
    private func nextTable(_ col: TableColumn<S>) -> TableGenerator<S, A> {
        var columns = self.columns
        columns.append(col)
        return TableGenerator<S, A>(columns, aggregator: self.aggregator)
    }
    /// カラムを一つ追加したGeneratorを作成する
    public func col(_ name: String, _ getter: @escaping (S)->String?) -> TableGenerator<S, A> {
        let col = StringColumn<S>(name: name, getter: getter)
        return nextTable(col)
    }
}

/// 集計
public protocol Aggregator: class {
    associatedtype Element

    /// 結果を出力する
    func makeResult(column:TableColumn<Element>) -> [String]
    func makeResult(columns:[TableColumn<Element>]) -> [[String]]
}

extension Aggregator {
    public func makeResult(column:TableColumn<Element>) -> [String] { return [] }

    public func makeResult(columns:[TableColumn<Element>]) -> [[String]] {
        var results : [[String]] = []
        var rows = 0
        for col in columns {
            let tmp = self.makeResult(column: col)
            results.append(tmp)
            rows = max(rows, tmp.count)
        }
        return results.map {
            if $0.count == rows { return $0 }
            var tmp = $0
            for _ in 1...rows-$0.count {
                tmp.append("")
            }
            return tmp
        }
    }
}

public class NullAggregator<S>: Aggregator {
    public typealias Element = S
}

public class FooterAggregator<S>: Aggregator {
    public typealias Element = S
    /// 結果を出力する
    public func makeResult(column:TableColumn<Element>) -> [String] { return [column.makeFooter()] }
}

// MAK: - 各種カラム
public class TableColumn<S> {
    public let name: String
    
    init(name: String) {
        self.name = name
    }
    func cell(of row: S, for target: CSVTarget) -> String {
        return ""
    }
    func makeFooter() -> String { return "" }
}

class GetterColumn<S, T> : TableColumn<S> {
    let getter: (S)->T?
    
    init(name: String, getter: @escaping (S)->T?) {
        self.getter = getter
        super.init(name: name)
    }
    func convert(data: T, for target: CSVTarget) -> String? {
        return nil
    }
    
    override func cell(of row: S, for target: CSVTarget) -> String {
        guard let value = getter(row) else { return "" }
        guard let result = convert(data: value, for: target) else { return "" }
        return result
    }
}
/// 文字列
class StringColumn<S> : GetterColumn<S, String> {
    override func convert(data: String, for target: CSVTarget) -> String? { return data }
}

/// 整数
class IntegerColumn<S> : GetterColumn<S, Int> {
    enum Footer {
        case no
        case avg0
        case avg1
    }
    var values : [Int] = []
    let footer: Footer
    
    init(name: String, footer: Footer, getter: @escaping (S) -> Int?) {
        self.footer = footer
        super.init(name: name, getter: getter)
    }
    
    override func convert(data: Int, for target: CSVTarget) -> String? {
        values.append(data)
        return "\(data)"
    }
    
    override func makeFooter() -> String {
        if values.isEmpty { return "" }
        let total = values.reduce(0) { $0 + $1 }
        let avg = Double(total) / Double(values.count)
        switch footer {
        case .no:
            return ""
        case .avg0:
            return String(format: "%.0f", avg)
        case .avg1:
            return String(format: "%.1f", avg)
        }
    }
}

/// 日時
class DateColumn<S> : GetterColumn<S, Date> {
    enum Format {
        case monthDayHourMinute
        case dayWeekToMinute
    }
    let format: Format
    init(name: String, format: Format, getter: @escaping (S) -> Date?) {
        self.format = format
        super.init(name: name, getter: getter)
    }
    override func convert(data: Date, for target: CSVTarget) -> String? {
        switch format {
        case .monthDayHourMinute:
            return data.monthDayHourMinuteString
        case .dayWeekToMinute:
            return data.dayWeekToMinuteString
        }
    }
}

/// 日付
class DayColumn<S>: GetterColumn<S, Day> {
    enum Format {
        case monthDay
        case monthDayWeek
        case yearMonth
        case monthDayJ
    }
    let format: Format
    init(name: String, format: Format, getter: @escaping (S) -> Day?) {
        self.format = format
        super.init(name: name, getter: getter)
    }
    override func convert(data: Day, for target: CSVTarget) -> String? {
        switch format {
        case .monthDay:
            return data.monthDayString
        case .yearMonth:
            return data.yearMonthString
        case .monthDayWeek:
            return data.monthDayWeekString
        case .monthDayJ:
            return data.monthDayJString
        }
    }
}

///　時間
class TimeColumn<S>: GetterColumn<S, Time> {
    enum Format {
        case hourMinute
        case hourMinuteSecond
    }
    let format: Format
    init(name: String, format: Format, getter: @escaping (S) -> Time?) {
        self.format = format
        super.init(name: name, getter: getter)
    }
    override func convert(data: Time, for target: CSVTarget) -> String? {
        switch format {
        case .hourMinute:
            return data.hourMinuteString
        case .hourMinuteSecond:
            return data.hourMinuteSecondString
        }
    }
}

/// 分
class TimeIntervalColumn<S>: GetterColumn<S, TimeInterval> {
    enum Footer {
        case no
        case avg0
        case avg1
    }
    enum Format {
        case minute
    }
    var values: [TimeInterval] = []
    let format: Format
    let footer: Footer
    init(name: String, format: Format, footer: Footer, getter: @escaping (S) -> TimeInterval?) {
        self.format = format
        self.footer = footer
        super.init(name: name, getter: getter)
    }
    override func convert(data: TimeInterval, for target: CSVTarget) -> String? {
        values.append(data)
        switch format {
        case .minute:
            let minute = Int(data/60)
            return "\(minute)"
        }
    }

    override func makeFooter() -> String {
        if values.isEmpty { return "" }
        let total = values.reduce(0) { $0 + $1 }
        let avg = total / Double(values.count)
        switch footer {
        case .no:
            return ""
        case .avg0:
            return String(format: "%.0f", avg)
        case .avg1:
            return String(format: "%.1f", avg)
        }
    }

}

