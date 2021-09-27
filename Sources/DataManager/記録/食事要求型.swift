//
//  食事要求型.swift
//  DataManager
//
//  Created by 四熊泰之 on R 2/09/26.
//

import Foundation

private let lock = NSRecursiveLock()

public enum 食事要求状態型: Int, Comparable, Hashable {
    case 未処理 = 0
    case 受取待 = 1
    case 受渡済 = 2
    case 追加発注 = 3
    
    public init?(text: String) {
        switch text {
        case "未処理":
            self = .未処理
        case "受取待":
            self = .受取待
        case "受渡済":
            self = .受渡済
        case "追加発注":
            self = .追加発注
        default:
            return nil
        }
    }
    
    public var text: String {
        switch self {
        case .未処理:
            return "未処理"
        case .受取待:
            return "受取待"
        case .受渡済:
            return "受渡済"
        case .追加発注:
            return "追加発注"
        }
    }
    
    public static func <(left: 食事要求状態型, right: 食事要求状態型) -> Bool {
        return left.rawValue < right.rawValue
    }
}

public struct 食事要求Data型: DMSystemRecordData {
    public static let layout = "DataAPI_7"
    public static var db: FileMakerDB { .system }

    public var 社員番号: String
    public var メニューID: メニューID型
    public var 要求状態: 食事要求状態型
    
    var 修正情報タイムスタンプ: Date
    
    public var memoryFootPrint: Int { 4 * 16 } // てきとう

    init(社員番号: String, メニューID: メニューID型, 要求状態: 食事要求状態型) {
        self.社員番号 = 社員番号
        self.メニューID = メニューID
        self.要求状態 = 要求状態
        self.修正情報タイムスタンプ = Date().rounded()
    }
    
    public init(_ record: FileMakerRecord) throws {
        func makeError(_ key: String) -> Error { record.makeInvalidRecordError(name: "食事要求", mes: key) }
        guard let 状態str = record.string(forKey: "要求状態"),
              let 要求状態 = 食事要求状態型(text: 状態str) else { throw makeError("要求状態") }
        guard let 修正情報タイムスタンプ = record.date(forKey: "修正情報タイムスタンプ") else { throw makeError("修正情報タイムスタンプ") }
        guard let 社員番号 = record.string(forKey: "社員番号") else { throw makeError("社員番号") }
        guard let メニューID = record.string(forKey: "メニューID") else { throw makeError("メニューID") }
        self.要求状態 = 要求状態
        self.修正情報タイムスタンプ = 修正情報タイムスタンプ
        self.社員番号 = 社員番号
        self.メニューID = メニューID
    }
    
    public var fieldData: FileMakerFields {
        var data = FileMakerFields()
        data["社員番号"] = self.社員番号
        data["メニューID"] = self.メニューID
        data["要求状態"] = self.要求状態.text
        return data
    }
}

public class 食事要求型: DMSystemRecord<食事要求Data型>, Identifiable {    
//    public var 社員番号: String {
//        get { data.社員番号 }
//        set { data.社員番号 = newValue }
//    }
//    public var メニューID: メニューID型 {
//        get { data.メニューID }
//        set { data.メニューID = newValue }
//    }
//    public var 要求状態: 食事要求状態型 {
//        get { data.要求状態 }
//        set { data.要求状態 = newValue }
//    }
//    
    public var 修正情報タイムスタンプ: Date { data.修正情報タイムスタンプ }
    
    public init(社員番号: String, メニューID: メニューID型, 要求状態: 食事要求状態型) {
        let data = 食事要求Data型(社員番号: 社員番号, メニューID: メニューID, 要求状態: 要求状態)
        super.init(data)
    }
    required init(_ record: FileMakerRecord) throws { try super.init(record) }

    
    public lazy var メニュー: 食事メニュー型? = {
        try? 食事メニューキャッシュ型.shared.キャッシュメニュー(メニューID: self.メニューID)
    }()
    public lazy var IDカード: IDカード型? = {
        try? IDカードキャッシュ型.shared.キャッシュIDカード(社員番号: self.社員番号) ?? IDカードキャッシュ型.shared.現在IDカード(社員番号: self.社員番号)
    }()
    
    public lazy var 社員: 社員型? = { 社員型(社員コード: self.社員番号) }()
    
    // MARK: - DB操作
    public func delete() throws {
        lock.lock(); defer { lock.unlock() }
        try generic_delete()
    }
    
    public func upload() throws {
        lock.lock(); defer { lock.unlock() }
        try generic_insert()
    }
    
    public func synchronize() throws {
        lock.lock(); defer { lock.unlock() }
        try generic_synchronize()
    }
    
    public var 食事時間帯: 食事時間帯型? {
        guard let menu = self.メニュー, menu.種類 == .昼食,
              let group = self.IDカード?.食事グループ else { return nil }
        let pattern = menu.提供パターン
        return try? 食事時間帯キャッシュ型.shared.キャッシュ食事時間帯(提供パターン: pattern, 食事グループ: group)
    }
    
    // MARK: - DB検索
    static func find(query: FileMakerQuery) throws -> [食事要求型] {
        if query.isEmpty { return [] }
        lock.lock(); defer { lock.unlock() }
        return try find(querys: [query])
    }

    public static func find(社員ID: String? = nil, メニューID: String? = nil) throws -> [食事要求型] {
        var query = FileMakerQuery()
        if let menuID = メニューID {
            query["メニューID"] = "==\(menuID)"
        }
        if let staffID = 社員ID {
            query["社員番号"] = "==\(staffID)"
        }
        assert(!query.isEmpty)
        return try find(query: query)
    }

    public static func find(発注日: Day) throws -> [食事要求型] {
        return try find(query: ["DataAPI_食事メニュー::発注日": 発注日.fmString])
    }

    public static func find追加発注(提供日: Day) throws -> [食事要求型] {
        return try find(query: [
            "DataAPI_食事メニュー::提供日" : 提供日.fmString,
                                "要求状態" : "==追加発注"
        ])
    }

    public static func find(提供日: Day, 種類: 食事種類型? = nil) throws -> [食事要求型] {
        var query: FileMakerQuery = ["DataAPI_食事メニュー::提供日" : 提供日.fmString]
        if let type = 種類 {
            query["DataAPI_食事メニュー::種類"] = "==\(type.rawValue)"
        }
        return try find(query: query)
    }

    public static func find(提供開始日: Day) throws -> [食事要求型] {
        return try find(query: ["DataAPI_食事メニュー::提供日" : ">=\(提供開始日.fmString)"])
    }
    
    public static func find(提供期間: ClosedRange<Day>) throws -> [食事要求型] {
        return try find(query: ["DataAPI_食事メニュー::提供日" : makeQueryDayString(提供期間)])
    }
    
    #if !os(tvOS)
    public static func backup(from day: Day) throws {
        let list = try 食事要求型.find(提供開始日: day)
        let gen = TableGenerator<食事要求型>()
            .string("社員番号") { $0.社員番号 }
            .string("メニューID") { $0.メニューID }
            .string("要求状態") { $0.要求状態.text }
            .date("修正情報タイムスタンプ", .yearToMinute) { $0.修正情報タイムスタンプ }
        try gen.share(list, format: .excel(header: true), dir: "backup", title: "食事要求\(day.monthDayJString).csv")
    }
    #endif
}

public extension Sequence where Element == 食事要求型 {
    /// 要求を時間帯ごとに分割する
    var 時間帯リスト: [(開始時間: Time, list: [食事要求型])] {
        let dic = Dictionary(grouping: self) { $0.食事時間帯?.開始時間 ?? Time(0, 0) }
        return dic.sorted { $0.key < $1.key }.map { ($0.key, $0.value) }
    }
}
