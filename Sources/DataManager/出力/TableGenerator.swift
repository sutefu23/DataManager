//
//  TableGenerator.swift
//  DataManager
//
//  Created by manager on 2020/01/07.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

public enum ExportType {
    case numbers(header: Bool = true)
    case excel(header: Bool = true)
    case excel_utf8(header: Bool = true)
    case html(header: Bool = true)
    case filemaker
    case utf8
    case libreoffice(header: Bool = true)
    
    func header(title: String) -> String {
        switch self {
        case .numbers, .excel, .filemaker, .libreoffice, .utf8, .excel_utf8:
            return ""
        case .html:
            var line: String = ""
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
        case .numbers, .excel, .filemaker, .libreoffice, .utf8, .excel_utf8:
            return ""
        case .html:
            var line : String = ""
            line += "</table></p>"
            line += "</body>"
            line += "</html>"
            return line
        }
    }
    
    private static let ngCharacters: CharacterSet = {
        var set = CharacterSet()
        set.insert(charactersIn: ",\"\r\n\t\\")
        return set
    }()

    private func clamp(_ string: String) -> String {
        let ng = ExportType.ngCharacters
        return string.filter {
            for sc in $0.unicodeScalars {
                if ng.contains(sc) { return false}
            }
            return true
        }
    }

    func makeLine(_ cols: [String]) -> String {
        switch self {
        case .utf8:
            return cols.joined() + "\n"
        case .filemaker:
            return cols.map { clamp($0) }.joined(separator: ",") + "\n"
        case .excel, .libreoffice, .excel_utf8:
            return cols.map { "\"\(clamp($0))\"" }.joined(separator: ",") + "\n"
        case .numbers:
            return cols.map { clamp($0) }.joined(separator: "\t") + "\n"
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
        case .numbers, .html, .libreoffice, .utf8, .excel_utf8:
            return text.data(using: .utf8, allowLossyConversion: true) ?? Data()
        case .excel, .filemaker:
            return text.data(using: .shiftJIS, allowLossyConversion: true) ?? Data()
        }
    }
}

final class TableColumn<S> {
    let title: String
    let getter: (S) -> String?
    
    init(title: String, getter: @escaping (S) -> String?) {
        self.title = title
        self.getter = getter
    }

    func value(for source: S) -> String {
        return getter(source) ?? ""
    }
}

public final class TableGenerator<S> {
    let columns: [TableColumn<S>]
    
    public init() {
        self.columns = []
    }
    init(_ columns: [TableColumn<S>]) {
        self.columns = columns
    }
    
    public func makeText<C: Sequence>(_ source: C, format: ExportType, title: String) throws -> String where C.Element == S {
        var text = format.header(title: title)
        switch format {
        case .excel(header: let header), .excel_utf8(header: let header), .html(header: let header), .libreoffice(header: let header), .numbers(header: let header):
            if header {
                let titles = columns.map  { $0.title }
                text += format.makeLine(titles)
            }
        case .filemaker, .utf8:
            text = ""
        }
        for rowSource in source {
            let cols = columns.map { $0.value(for: rowSource) }
            text += format.makeLine(cols)
        }
        text += format.footer()
        return text
            
    }
    
    public func makeData<C: Sequence>(_ source: C, format: ExportType, title: String) throws -> Data where C.Element == S {
        let text = try makeText(source, format: format, title: title)
        let data = format.encode(text: text)
        return data
    }
    
    public func write<C: Sequence>(_ source: C, format: ExportType, to url: URL) throws where C.Element == S {
        let title = url.deletingPathExtension().lastPathComponent
        let data = try makeData(source, format: format, title: title)
        try data.write(to: url, options: .atomic)
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
        case currency
    }
    enum DoubleFormat {
        case native
        case round0
        case round1
        case currency
    }
    enum DateFormat {
        case monthDayHourMinute
        case dayWeekToMinute
        case yearToMinute
    }
    enum MonthFormat {
        case shortYearMonth
        case monthOrYearMonth
        case yearMonthJ
    }
    enum DayFormat {
        case yearMonthDay
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
        /// 小数点以下は切り捨て
        case minute0
        /// 小数点以下１桁まで
        case minute1
    }

    func string(_ title: String, _ getter: @escaping (S) -> String?) -> TableGenerator<S> {
        let col = TableColumn(title: title, getter: getter)
        return appending(col)
    }

    func integer(_ title: String, _ format: IntFormat = .native, _ getter: @escaping (S) -> Int?) -> TableGenerator<S> {
        let col = TableColumn<S>(title: title) {
            if let value = getter($0) {
                switch format {
                case .native:
                    return String(value)
                case .currency:
                    let formatter = NumberFormatter()
                    formatter.numberStyle = .currency
                    return formatter.string(from: NSNumber(value: value)) ?? ""
                }
            } else {
                return ""
            }
        }
        return appending(col)
    }
    
    func double(_ title: String, _ format: DoubleFormat = .native, _ getter: @escaping (S) -> Double?) -> TableGenerator<S> {
        let col = TableColumn<S>(title: title) {
            guard let value = getter($0) else { return nil }
            switch format {
            case .native:
                return String(value)
            case .round0:
                return String(format: "%.0f", value)
            case .round1:
                return String(format: "%.1f", value)
            case .currency:
                let formatter = NumberFormatter()
                formatter.numberStyle = .currency
                return formatter.string(from: NSNumber(value: value)) ?? ""
            }
        }
        return appending(col)
    }
    
    func month(_ title: String, _ format: MonthFormat = .shortYearMonth, _ getter: @escaping (S) -> Month?) -> TableGenerator<S> {
        let col = TableColumn<S>(title: title) {
            let month = getter($0)
            switch format {
            case .shortYearMonth:
                return month?.shortYearMonthString
            case .yearMonthJ:
                return month?.yearMonthJString
            case .monthOrYearMonth:
                return month?.monthOrYearMonthString
            }
        }
        return appending(col)
    }
    func date(_ title: String, _ format: DateFormat = .monthDayHourMinute, _ getter: @escaping (S) -> Date?) -> TableGenerator<S>{
        let col = TableColumn<S>(title: title){
            let date = getter($0)
            switch format {
            case .monthDayHourMinute:
                return date?.monthDayHourMinuteString
            case .dayWeekToMinute:
                return date?.dayWeekToMinuteString
            case .yearToMinute:
                return date?.yearToMinuteString
            }
        }
        return appending(col)
    }
    func day(_ title: String, _ format: DayFormat = .monthDay, _ getter: @escaping (S) -> Day?) -> TableGenerator<S> {
        let col = TableColumn<S>(title: title) {
            let day = getter($0)
            switch format {
            case .yearMonthDay:
                return day?.yearMonthDayString
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
        return appending(col)
    }
    
    func time(_ title: String, _ format: TimeFormat = .hourMinute, _ getter: @escaping (S) -> Time?) -> TableGenerator<S>
    {
        let col = TableColumn<S>(title: title) {
            guard let time = getter($0) else { return nil }
            switch format {
            case .hourMinute:
                return time.hourMinuteString
            case .hourMinuteSecond:
                return time.hourMinuteSecondString
            }
        }
        return appending(col)
    }
    
    func timeInterval(_ title: String, _ format: TimeIntervalFormat = .minute0, _ getter: @escaping (S) -> TimeInterval?) -> TableGenerator<S> {
        let col = TableColumn<S>(title: title) {
            guard let value = getter($0) else { return nil }
            switch format {
            case .minute0:
                //小数点第一位以下は切り捨て（旧CSVエクスポーターにデータを合わせるため
                let value = Int(value/60)
                //結果が０以下の時はnilを返す
                if value <= 0 { return nil }
                return String(value)
            case .minute1:
                return String(format: "%.1f", value/60)
            }
        }
        return appending(col)
    }
}

#if targetEnvironment(macCatalyst)
import UIKit

public extension TableGenerator {
    func share(_ source: [S], format: ExportType, title: String, shareButton: UIButton? = nil) throws {
        let url = 生産管理集計URL.appendingPathComponent(title)
        try self.write(source, format: format, to: url)
    }
}

#elseif os(iOS)
import UIKit

public extension TableGenerator {
    func share(_ source: [S], format: ExportType, title: String, shareButton: UIButton? = nil) throws {
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(title)
        try self.write(source, format: format, to: url)

        guard let source = UIApplication.shared.windows.last?.rootViewController else { return }
        let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
//        controller.excludedActivityTypes = [.airDrop, .mail]
        controller.popoverPresentationController?.sourceView = source.view
        if let button = shareButton {
                controller.popoverPresentationController?.sourceRect = button.frame
        }
        source.present(controller, animated: true, completion: nil)
    }
}
#elseif os(macOS)
import AppKit

public extension TableGenerator {
    func share(_ source: [S], format: ExportType, title: String) throws {
        let url = 生産管理集計URL.appendingPathComponent(title)
        try self.write(source, format: format, to: url)
    }
}

#endif

