//
//  TableGenerator.swift
//  DataManager
//
//  Created by manager on 2020/01/07.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

public enum ExportType {
    case numbers
    case excel
    case html
    
    func header(title: String) -> String {
        switch self {
        case .numbers, .excel:
            return ""
        case .html:
            var line : String = ""
            line += "<!DOCTYPE html>"
            line += "<html>"
            line += "<head>"
            line += "<title>\(title)</title>"
            line += "</head>"
            line += "<body>"
            line += #"<p><table border="1">"#
            return line
        }
    }
    func footer() -> String {
        switch self {
        case .numbers, .excel:
            return ""
        case .html:
            var line : String = ""
            line += "</table></p>"
            line += "</body>"
            line += "</html>"
            return line
        }
    }
    
    func makeLine(_ cols:[String]) -> String {
        switch self {
        case .excel:
            return cols.map { "\"\($0)\"" }.joined(separator: ",") + "\n"
        case .numbers:
            return cols.joined(separator: "\t") + "\n"
        case .html:
            let tag = "td"
            var line = "<tr>"
            for d in cols {
                line += "<\(tag)>\(d)</\(tag)>"
            }
            line += "</tr>"
            return line
        }

    }
    
    func encode(text: String) -> Data {
        switch self {
        case .numbers, .html:
            return text.data(using: .utf8, allowLossyConversion: true) ?? Data()
        case .excel:
            return text.data(using: .shiftJIS, allowLossyConversion: true) ?? Data()
        }
    }
}

class TableColumn<S> {
    let title: String
    let getter: (S) -> String?
    
    init(title: String, getter:@escaping (S)->String?) {
        self.title = title
        self.getter = getter
    }
    
    func value(for source: S) -> String {
        return getter(source) ?? ""
    }
}

public class TableGenerator<S> {
    let columns: [TableColumn<S>]
    
    public init() {
        self.columns = []
    }
    init(_ columns:[TableColumn<S>]) {
        self.columns = columns
    }
    
    public func makeText(_ source:[S], format: ExportType, title: String) throws -> String {
        var text = format.header(title: title)
        let titles = columns.map  {$0.title }
        text += format.makeLine(titles)
        for rowSource in source {
            let cols = columns.map { $0.value(for: rowSource) }
            text += format.makeLine(cols)
        }
        text += format.footer()
        return text
    }
    
    public func makeData(_ source:[S], format: ExportType, title: String) throws -> Data {
        let text = try makeText(source, format: format, title: title)
        let data = format.encode(text: text)
        return data
    }
    
    public func write(_ source:[S], format: ExportType, to url: URL) throws {
        let title = url.deletingPathExtension().lastPathComponent
        let data = try makeData(source, format: format, title: title)
        try data.write(to: url, options: .atomicWrite)
    }
    
    func appending(_ col: TableColumn<S>) -> TableGenerator<S> {
        var columns = self.columns
        columns.append(col)
        return TableGenerator(columns)
    }
}

public extension TableGenerator {
    enum IntFormat {
        case native
    }
    
    enum DoubleFormat {
        case native
        case round0
        case round1
    }
    
    enum DateFormat {
        case monthDayHourMinute
        case dayWeekToMinute
    }
    enum DayFormat {
        case monthDay
        case monthDayWeek
        case yearMonth
        case monthDayJ
    }
    enum TimeFormat {
        case hourMinute
        case hourMinuteSecond
    }
    enum TimeIntervalFormat {
        case minute0
        case minute1
    }

    func col(_ title: String, _ getter: @escaping (S)->String?) -> TableGenerator<S> {
        let col = TableColumn(title: title, getter: getter)
        return appending(col)
    }
    
    func col(_ title: String, _ format: IntFormat = .native, _ getter: @escaping (S)->Int?) -> TableGenerator<S> {
        let col = TableColumn<S>(title: title) {
            if let value = getter($0) {
                return String(value)
            } else {
                return ""
            }
        }
        return appending(col)
    }
    
    func col(_ title: String, _ format: DoubleFormat = .native, _ getter: @escaping (S)->Double?) -> TableGenerator<S> {
        return self.col(title) {
            guard let value = getter($0) else { return nil }
            switch format {
            case .native:
                return String(value)
            case .round0:
                return String(format: "%.0f", value)
            case .round1:
                return String(format: "%.1f", value)
            }
        }
    }
    
    func col(_ title: String, _ format: DayFormat = .monthDay, _ getter: @escaping (S)->Day?) -> TableGenerator<S> {
        return self.col(title) {
            let day = getter($0)
            switch format {
            case .monthDay:
                return day?.monthDayString
            case .yearMonth:
                return day?.yearMonthString
            case .monthDayWeek:
                return day?.monthDayWeekString
            case .monthDayJ:
                return day?.monthDayJString
            }
        }
    }
    
    func col(_ title: String, _ format: TimeFormat = .hourMinute, _ getter: @escaping (S)->Time?) -> TableGenerator<S>
    {
        return self.col(title) {
            guard let time = getter($0) else { return nil }
            switch format {
            case .hourMinute:
                return time.hourMinuteString
            case .hourMinuteSecond:
                return time.hourMinuteSecondString
            }
        }
    }
    
    func col(_ title: String, _ format: TimeIntervalFormat = .minute0, _ getter: @escaping (S)->TimeInterval?) -> TableGenerator<S> {
        return self.col(title) {
            guard let value = getter($0) else { return nil }
            switch format {
            case .minute0:
                return String(format: "%.0f", value/60)
            case .minute1:
                return String(format: "%.1f", value/60)
            }
        }
    }
}
