//
//  TableGenerator.swift
//  DataManager
//
//  Created by 四熊泰之 on R 1/11/24.
//  Copyright © Reiwa 1 四熊泰之. All rights reserved.
//

import Foundation

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

public class TableGenerator<S> {
    let columns: [TableColumn<S>]
    
    public convenience init() {
        self.init([])
    }
    
    init(_ columns: [TableColumn<S>]) {
        self.columns = columns
    }
    
    public func write(_ source: [S], of format: CSVTarget, to url: URL) throws {
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
        let footer = join(rows: columns.map { $0.makeFooter() })
        lines.append(footer)
        let data = lines.joined().data(using: format.encoding, allowLossyConversion: true)
        try data?.write(to: url, options: [.atomicWrite])
    }
    
    private func nextTable(_ col: TableColumn<S>) -> TableGenerator<S> {
        var columns = self.columns
        columns.append(col)
        return TableGenerator<S>(columns)
    }
    
    public func col(_ name: String, _ getter: @escaping (S)->String?) -> TableGenerator<S> {
        let col = StringColumn<S>(name: name, getter: getter)
        return nextTable(col)
    }
}

// MAK: -
class TableColumn<S> {
    let name: String
    
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


