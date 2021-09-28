//
//  食事メニュー.swift
//  DataManager
//
//  Created by 四熊泰之 on R 2/09/25.
//

import Foundation

private let lock = NSRecursiveLock()

public enum メニュー種類型: 図番型, Comparable, CaseIterable{
    
    public typealias RawValue = String
    case 朝食
    case A定食
    case B定食
    case C定食

    public static func ==(left: メニュー種類型, right: メニュー種類型) -> Bool {
        left.rawValue == right.rawValue
    }
    
    public var code: 図番型 {
        switch self {
        case .朝食: return "10000"
        case .A定食: return "10001"
        case .B定食: return "10002"
        case .C定食: return "10003"
        }
    }
    
    public static func <(left: メニュー種類型, right: メニュー種類型) -> Bool {
        left.code < right.code
    }
}


public enum 食事種類型: String, Comparable {
    case 朝食
    case 昼食
    
    public static func ==(left: 食事種類型, right: 食事種類型) -> Bool {
        left.rawValue == right.rawValue
    }
    
    var code: Int {
        switch self {
        case .朝食: return 0
        case .昼食: return 1
        }
    }
    
    public static func <(left: 食事種類型, right: 食事種類型) -> Bool {
        left.code < right.code
    }
}

public enum 食事カテゴリー型: String, Comparable, CaseIterable{
    public static func < (lhs: 食事カテゴリー型, rhs: 食事カテゴリー型) -> Bool {
        lhs.code < rhs.code
    }
    
    case 朝食 = "朝食"
    case 一汁三菜ランチＡ = "一汁三菜ランチＡ"
    case 一汁三菜ランチＢ = "一汁三菜ランチＢ"
    case お好みランチ = "お好みランチ"
    
    public var code: 図番型 {
        switch self {
        case .朝食: return メニュー種類型.朝食.code
        case .一汁三菜ランチＡ: return メニュー種類型.A定食.code
        case .一汁三菜ランチＢ: return メニュー種類型.B定食.code
        case .お好みランチ: return メニュー種類型.C定食.code
        }
    }
}

extension FileMakerRecord {
    func 食事種類(forKey key: String) -> 食事種類型? {
        guard let name = self.string(forKey: key) else { return nil }
        return 食事種類型(rawValue: name)
    }
}
public typealias メニューID型 = String
public struct 食事メニューData型: Equatable {
    public static let layout = "DataAPI_6"
    public static var db: FileMakerDB { .system }

    public var メニューID: メニューID型
    public var 図番: 図番型
    public var 提供日: Day
    public var 発注日: Day
    public var 種類: 食事種類型
    public var 内容: String
    public var カロリー: String
    public var 食塩: String
    public var 最大提供数: Int
    public var 金額: Int
    public var 提供パターン: String
}

extension 食事メニューData型: FileMakerSyncData {
    public var memoryFootPrint: Int { 11 * 16 } // てきとう

    public init(_ record: FileMakerRecord) throws {
        func makeError(_ key: String) -> Error { record.makeInvalidRecordError(name: "食事メニュー", mes: key) }
        func getString(_ key: String) throws -> String {
            guard let str = record.string(forKey: key) else { throw makeError(key) }
            return str
        }
        func getDay(_ key: String) throws -> Day {
            guard let day = record.day(forKey: key) else { throw makeError(key) }
            return day
        }

        guard let 種類 = record.食事種類(forKey: "種類") else { throw makeError("種類") }
        self.種類 = 種類
        self.メニューID = try getString("メニューID")
        self.図番 = try getString("図番")
        self.提供日 = try getDay("提供日")
        self.発注日 = try getDay("発注日")
        self.内容 = try getString("内容")
        self.カロリー = try getString("カロリー")
        self.食塩 = try getString("食塩")
        self.提供パターン = try getString("提供パターン")
        self.最大提供数 = record.integer(forKey: "最大提供数") ?? 999
        self.金額 = record.integer(forKey: "金額") ?? 0
    }
    
    public var fieldData: FileMakerFields {
        var data = FileMakerFields()
        data["図番"] = 図番
        data["提供日"] = 提供日.fmString
        data["発注日"] = 発注日.fmString
        data["種類"] = 種類.rawValue
        data["内容"] = 内容
        data["カロリー"] = カロリー
        data["食塩"] = 食塩
        data["最大提供数"] = "\(最大提供数)"
        data["金額"] = "\(金額)"
        data["提供パターン"] = 提供パターン
        return data
    }
}

public class 食事メニュー型: FileMakerSyncObject<食事メニューData型> {
//    public var メニューID: メニューID型 {
//        get { data.メニューID }
//        set { data.メニューID = newValue }
//    }
//    public var 図番: 図番型 {
//        get { data.図番 }
//        set { data.図番 = newValue }
//    }
//    public var 提供日: Day {
//        get { data.提供日 }
//        set { data.提供日 = newValue }
//    }
//    public var 発注日: Day {
//        get { data.発注日 }
//        set { data.発注日 = newValue }
//    }
//    public var 種類: 食事種類型 {
//        get { data.種類 }
//        set { data.種類 = newValue }
//    }
//    public var 内容: String {
//        get { data.内容 }
//        set { data.内容 = newValue }
//    }
//    public var カロリー: String {
//        get { data.カロリー }
//        set { data.カロリー = newValue }
//    }
//    public var 食塩: String {
//        get { data.食塩 }
//        set { data.食塩 = newValue }
//    }
//    public var 最大提供数: Int {
//        get { data.最大提供数 }
//        set { data.最大提供数 = newValue }
//    }
//    public var 金額: Int {
//        get { data.金額 }
//        set { data.金額 = newValue }
//    }
//    public var 提供パターン: String {
//        get { data.提供パターン }
//        set { data.提供パターン = newValue }
//    }

    public init(メニューID: メニューID型, 図番: 図番型, 提供日: Day, 発注日: Day, 種類: 食事種類型, 内容: String, カロリー: String, 食塩: String, 最大提供数: Int, 金額: Int, 提供パターン: String) {
        let data = 食事メニューData型(メニューID: メニューID, 図番: 図番, 提供日: 提供日, 発注日: 発注日, 種類: 種類, 内容: 内容, カロリー: カロリー, 食塩: 食塩, 最大提供数: 最大提供数, 金額: 金額, 提供パターン: 提供パターン)
        super.init(data)
    }
    required init(_ record: FileMakerRecord) throws { try super.init(record) }

    public var 略称: String {
        switch self.図番 {
        case "10000": return "朝"
        case "10001": return "A"
        case "10002": return "B"
        case "10003": return "C"
        default: 
            if let item = try? 資材キャッシュ型.shared.キャッシュ資材(図番: self.図番), let 略号 = item.規格.first {
                return String(略号)
            } else {
                return "?"
            }
        }
    }
    
    // MARK: - DB操作
    public func delete() throws {
        lock.lock(); defer { lock.unlock() }
        if try generic_delete() {
            食事メニューキャッシュ型.shared.flush(メニューID: self.メニューID)
        }
    }

    public func upload() throws {
        lock.lock(); defer { lock.unlock() }
        if try generic_insert() {
            食事メニューキャッシュ型.shared.flush(メニューID: self.メニューID)
        }
    }
    
    public func synchronize() throws {
        lock.lock(); defer { lock.unlock() }
        if try generic_synchronize() {
            食事メニューキャッシュ型.shared.flush(メニューID: self.メニューID)
        }
    }
    
    // MARK: - DB検索
    static func find(query: FileMakerQuery) throws -> [食事メニュー型] {
        lock.lock(); defer { lock.unlock() }
        let result = try find(querys: [query])
        let cache = 食事メニューキャッシュ型.shared
        result.forEach { cache.regist($0) }
        return result
    }

    public static func find(メニューID: String? = nil, 図番: 図番型? = nil) throws -> [食事メニュー型] {
        var query = FileMakerQuery()
        if let order = メニューID {
            query["メニューID"] = "==\(order)"
        }
        if let item = 図番 {
            query["図番"] = "==\(item)"
        }
        return try find(query: query)
    }

    public static func find(from day: Day) throws -> [食事メニュー型] {
        return try find(query: ["提供日": ">=\(day.fmString)"])
    }

    public static func find(提供日: Day) throws -> [食事メニュー型] {
        return try find(query: ["提供日": "==\(提供日.fmString)"])
    }
    
    #if !os(tvOS)
    public static func backup(from day: Day) throws {
        let list = try 食事メニュー型.find(from: day)
        let gen = TableGenerator<食事メニュー型>()
            .string("メニューID") { $0.メニューID }
            .string("図番") { $0.図番 }
            .day("提供日") { $0.提供日 }
            .day("発注日") { $0.発注日 }
            .string("種類") { $0.種類.rawValue }
            .string("内容") { $0.内容 }
            .string("食塩") { $0.食塩 }
            .string("カロリー") { $0.カロリー }
            .integer("最大提供数") { $0.最大提供数 }
            .integer("金額") { $0.金額 }
            .string("提供パターン") { $0.提供パターン }
        try gen.share(list, format: .excel(header: true), dir: "backup", title: "食事メニュー\(day.monthDayJString).csv")
    }
    #endif
}

// MARK: - キャッシュ
public class 食事メニューキャッシュ型 {
    public static let shared = 食事メニューキャッシュ型()
    var expireTime: TimeInterval = 1*60*60 // 1時間
    private let lock = NSLock()
    private var cache: [メニューID型: (有効期限: Date, 食事メニュー: 食事メニュー型)] = [:]

    func 現在メニュー(メニューID: メニューID型) throws -> 食事メニュー型? {
        guard let menu = try 食事メニュー型.find(メニューID: メニューID).first else { return nil }
        return menu
    }

    func regist(_ menu: 食事メニュー型) {
        let expire = Date(timeIntervalSinceNow: self.expireTime)
        lock.lock()
        cache[menu.メニューID] = (expire, menu)
        lock.unlock()
    }
    
    public func キャッシュメニュー(メニューID: メニューID型) throws -> 食事メニュー型? {
        lock.lock()
        let data = self.cache[メニューID]
        lock.unlock()
        if let data = data, Date() <= data.有効期限 {
            return data.食事メニュー
        }
        return try self.現在メニュー(メニューID: メニューID)
    }

    func flush(メニューID: メニューID型) {
        lock.lock()
        cache[メニューID] = nil
        lock.unlock()
    }
    
    func flushAllCache() {
        lock.lock()
        self.cache.removeAll()
        lock.unlock()
    }
}
