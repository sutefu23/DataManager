//
//  資材使用記録.swift
//  DataManager
//
//  Created by manager on 2020/04/16.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

private let lock = NSRecursiveLock()

public enum 印刷対象型: RawRepresentable, Hashable {
    public static let 仮印刷対象工程: Set<工程型> = [.裏加工, .裏加工_溶接]
    case 全て
    case なし
    
    public init?(rawValue: String) {
        switch rawValue {
        case "なし": self = .なし
        case "全て": self = .全て
        default:
            return nil
        }
    }
    
    public var rawValue: String {
        switch self {
        case .なし: return "なし"
        case .全て: return "全て"
        }
    }
    
    public var is封筒印刷あり: Bool {
        switch self {
        case .全て:
            return true
        case .なし:
            return false
        }
    }
}

extension FileMakerRecord {
    func 印刷対象(forKey key: String) -> 印刷対象型? {
        guard let str = self.string(forKey: key) else { return nil }
        return 印刷対象型(rawValue: str)
    }
}

public struct 資材使用記録Data型: FileMakerSyncData, Equatable, DMCacheElement {
    public static let layout = "DataAPI_5"
    public static var db: FileMakerDB { .system }
    public var 登録日時: Date
    
    public var 伝票番号: 伝票番号型
    public var 工程: 工程型
    public var 作業者: 社員型
    public var 図番: 図番型
    public var 表示名: String
    public var 単価: Double?
    public var 用途: String?
    public var 使用量: String?
    public var 使用面積: Double?
    public var 単位量: Double?
    public var 単位数: Double?
    public var 金額: Double?
    public var 印刷対象: 印刷対象型?
    public var 原因工程: 工程型?

    public var memoryFootPrint: Int { return 15 * 16 }
    
    init(登録日時: Date, 伝票番号: 伝票番号型, 工程: 工程型, 作業者: 社員型, 図番: 図番型, 表示名: String, 単価: Double?, 用途: String?, 使用量: String?, 使用面積: Double?, 単位量: Double?, 単位数: Double?, 金額: Double?, 印刷対象: 印刷対象型?, 原因工程: 工程型?) {
        self.登録日時 = 登録日時
        self.伝票番号 = 伝票番号
        self.工程 = 工程
        self.作業者 = 作業者
        self.図番 = 図番
        self.表示名 = 表示名
        self.単価 = 単価
        self.用途 = 用途
        self.使用量 = 使用量
        self.使用面積 = 使用面積
        self.金額 = 金額
        self.単位量 = 単位量
        self.単位数 = 単位数
        self.印刷対象 = 印刷対象
        self.原因工程 = 原因工程
    }
    
    public init(_ record: FileMakerRecord) throws {
        func makeError0(_ key: String) -> Error { record.makeInvalidRecordError(name: "資材使用記録", mes: key) }
        guard let 伝票番号 = record.伝票番号(forKey: "伝票番号") else { throw makeError0("伝票番号") }
        func makeError(_ key: String) -> Error { record.makeInvalidRecordError(name: "資材使用記録: \(伝票番号.整数文字列)", mes: key) }
        guard let 登録日 = record.date(dayKey: "登録日", timeKey: "登録時間") else { throw makeError("登録日") }
        guard let 工程 = record.工程(forKey: "工程コード") else { throw makeError("工程") }
        guard let 作業者 = record.社員(forKey: "作業者コード") else { throw makeError("作業者") }
        guard let 資材 = record.資材(forKey: "図番") else {
            throw makeError("図番[\(record.string(forKey: "図番") ?? "nil")]")
        }
        
        self.登録日時 = 登録日
        self.伝票番号 = 伝票番号
        self.工程 = 工程
        self.作業者 = 作業者
        self.図番 = 資材.図番
        self.単価 = record.double(forKey: "単価") ?? 資材.単価
        self.使用量 = record.string(forKey: "使用量")
        self.使用面積 = record.double(forKey: "使用面積")
        self.用途 = record.string(forKey: "用途")
        self.金額 = record.double(forKey: "金額")
        if let title = record.string(forKey: "表示名"), !title.isEmpty {
            self.表示名 = title.全角半角日本語規格化()
        } else {
            self.表示名 = 資材.標準表示名
        }
        self.単位量 = record.double(forKey: "単位量")
        self.単位数 = record.double(forKey: "単位数")
        self.印刷対象 = record.印刷対象(forKey: "印刷対象")
        self.原因工程 = record.工程(forKey: "原因工程コード")
    }
    
    public var fieldData: FileMakerFields {
        var data = FileMakerFields()
        data["登録日"] = 登録日時.day.fmString
        data["登録時間"] = 登録日時.time.fmImportString
        data["伝票番号"] = "\(伝票番号.整数値)"
        data["工程コード"] = 工程.code
        data["原因工程コード"] = 原因工程?.code
        data["作業者コード"] = 作業者.Hなし社員コード
        data["図番"] = 図番
        data["表示名"] = 表示名
        if let price = 単価 { data["単価"] = "\(price)" }
        data["使用量"] = 使用量
        data["用途"] = 用途
        if let value = self.単位量 {
            data["単位量"] = "\(value)"
        }
        if let value = self.単位数 {
            data["単位数"] = "\(value)"
        }
        if let charge = self.金額 {
            data["金額"] = "\(charge)"
        }
        if let target = self.印刷対象 {
            data["印刷対象"] = target.rawValue
        }
        if let value = self.使用面積 {
            data["使用面積"] = "\(value)"
        }
        return data
    }
}

public final class 資材使用記録型: FileMakerSyncObject<資材使用記録Data型>,登録日時比較可能型 {
    public var 登録日時: Date {
        get { data.登録日時 }
    }
    
    typealias RecordData = 資材使用記録Data型

    public var 登録日: Day { return data.登録日時.day }
    public var 登録時間: Time { return data.登録日時.time }

//    public var 登録日時: Date {
//        get { data.登録日時 }
//        set { data.登録日時 = newValue }
//    }
//    public var 伝票番号: 伝票番号型 {
//        get { data.伝票番号 }
//        set { data.伝票番号 = newValue }
//    }
//    public var 工程: 工程型 {
//        get { data.工程 }
//        set { data.工程 = newValue }
//    }
//    public var 原因工程: 工程型? {
//        get { data.原因工程 }
//        set { data.原因工程 = newValue }
//    }
//    public var 作業者: 社員型 {
//        get { data.作業者 }
//        set { data.作業者 = newValue }
//    }
//    
//    public var 表示名: String {
//        get { data.表示名 }
//        set { data.表示名 = newValue }
//    }
//    public var 図番: 図番型 {
//        get { data.図番 }
//        set { data.図番 = newValue }
//    }
//    public var 単価: Double? {
//        get { data.単価 }
//        set { data.単価 = newValue }
//    }
//    public var 用途: String? {
//        get { data.用途 }
//        set { data.用途 = newValue }
//    }
//    public var 使用量: String? {
//        get { data.使用量 }
//        set { data.使用量 = newValue }
//    }
//    public var 使用面積: Double? {
//        get { data.使用面積 }
//        set { data.使用面積 = newValue }
//    }
//    public var 金額: Double? {
//        get { data.金額 }
//        set { data.金額 = newValue }
//    }
//    public var 単位量: Double? {
//        get { data.単位量 }
//        set { data.単位量 = newValue }
//    }
//
//    public var 単位数: Double? {
//        get { data.単位数 }
//        set { data.単位数 = newValue }
//    }
//    
//    public var 印刷対象: 印刷対象型? {
//        get { data.印刷対象 }
//        set { data.印刷対象 = newValue }
//    }
    
    public var 仮印刷対象: 印刷対象型 {
        if let target = data.印刷対象 { return target }
        return 印刷対象型.仮印刷対象工程.contains(data.工程) ? .全て : .なし
    }

    public init(登録日時: Date, 伝票番号: 伝票番号型, 工程: 工程型, 作業者: 社員型, 図番: 図番型, 表示名: String, 単価: Double?, 用途: String?, 使用量: String?, 使用面積: Double?, 単位量: Double?, 単位数: Double?, 金額: Double?, 印刷対象: 印刷対象型?, 原因工程: 工程型?) {
        let data = 資材使用記録Data型(登録日時: 登録日時, 伝票番号: 伝票番号, 工程: 工程, 作業者: 作業者, 図番: 図番, 表示名: 表示名, 単価: 単価, 用途: 用途, 使用量: 使用量, 使用面積: 使用面積, 単位量: 単位量, 単位数: 単位数, 金額: 金額, 印刷対象: 印刷対象, 原因工程: 原因工程)
        super.init(data)
    }
    required init(_ record: FileMakerRecord) throws { try super.init(record) }

    /// 必要に応じて用途「作直」を「部署内やり直し」に置き換える
    public func 部署内やり直しチェック() throws {
        guard let errorProcess = self.原因工程?.チェック工程 else { return }
        switch self.用途 {
        case "作直":
            break
        case "":
            self.用途 = "作直"
        case "部署内やり直し":
            return
        default:
            return
        }
        let execProcess = self.工程.チェック工程
        guard execProcess == errorProcess else { return }
        if let last = try 指示書進捗キャッシュ型.shared.キャッシュ一覧(self.伝票番号)?.工程別進捗一覧[execProcess]?.last(where: { $0.登録日時 < self.登録日時 && $0.作業種別 != .作直 }) {
            if last.作業内容 == .完了 { return }
        }
        self.用途 = "部署内やり直し"
    }
}

extension 工程型 {
    var チェック工程: 工程型 {
        let map: [工程型: 工程型] = [
            .レーザー: .照合検査,
            .腐蝕: .エッチング,
            .版焼き: .エッチング,
            .腐蝕印刷: .エッチング,
            .タレパン: .フォーミング,
            .プレーナー: .フォーミング,
            .シャーリング: .フォーミング,
            .マスキング: .中塗り,
            .プライマー: .塗装,
        ]
        return map[self] ?? self
    }
}

extension 資材使用記録型 {
    // MARK: - DB操作
    public func delete() throws {
        lock.lock(); defer { lock.unlock() }
        if try generic_delete() {
            資材使用記録キャッシュ型.shared.flush(伝票番号: self.伝票番号)
        }
    }

    public func upload() throws {
        lock.lock(); defer { lock.unlock() }
        if try generic_insert() {
            資材使用記録キャッシュ型.shared.flush(伝票番号: self.伝票番号)
            let output = 使用資材出力型(self)
            try [output].exportToDB()
        }
    }
    
    public func synchronize() throws {
        lock.lock(); defer { lock.unlock() }
        if self.recordId == nil {
            try self.upload()
        } else if try generic_synchronize() {
            資材使用記録キャッシュ型.shared.flush(伝票番号: self.伝票番号)
        }
    }
    
    // MARK: - DB検索
    public static func find(登録日: ClosedRange<Day>) throws -> [資材使用記録型] {
        return try find(query: ["登録日": makeQueryDayString(登録日)])
    }
    
    public static func find(伝票番号: 伝票番号型? = nil, 図番: 図番型? = nil) throws -> [資材使用記録型] {
        var query = FileMakerQuery()
        if let order = 伝票番号 {
            query["伝票番号"] = "==\(order)"
        }
        if let item = 図番 {
            query["図番"] = "==\(item)"
        }
        return try find(query: query)
    }
    
    public static func find(伝票番号: 伝票番号型, 図番: 図番型, 表示名: String? = nil, 工程: 工程型? = nil) throws -> [資材使用記録型] {
        var query = FileMakerQuery()
        query["伝票番号"] = "==\(伝票番号)"
        query["図番"] = "==\(図番)"
        if let 表示名 = 表示名 { query["表示名"] = "==\(表示名)" }
        if let 工程 = 工程 { query["工程コード"] = "==\(工程.code)" }
        return try find(query: query)
    }
    
    public static func find(伝票番号: 伝票番号型? = nil, 工程: 工程型?, 登録期間: ClosedRange<Day>?) throws -> [資材使用記録型] {
        var query = FileMakerQuery()
        if let number = 伝票番号 {
            query["伝票番号"] = "==\(number)"
        }
        if let 工程 = 工程 {
            query["工程コード"] = "==\(工程.code)"
        }
        if let days = 登録期間 {
            query["登録日"] = makeQueryDayString(days)
        }
        if query.isEmpty { return [] }
        return try find(query: query)
    }
}

public struct 資材使用記録キャッシュData型: DMCacheElement {
    let list: [資材使用記録型]
    
    public var memoryFootPrint: Int { return list.reduce(16) { $0 + $1.memoryFootPrint } }
}

public class 資材使用記録キャッシュ型: DMDBCache<伝票番号型, 資材使用記録キャッシュData型> {
    public static let shared: 資材使用記録キャッシュ型 = 資材使用記録キャッシュ型(lifeSpan: 1*60*60, nilCache: false) {
        let list = try 資材使用記録型.find(伝票番号: $0)
        if list.isEmpty { return nil }
        return 資材使用記録キャッシュData型(list: list)
    }
    
    public func 現在資材使用記録(伝票番号: 伝票番号型) throws -> [資材使用記録型]? {
        return try find(伝票番号, noCache: true)?.list
    }

    public func キャッシュ資材使用記録(伝票番号: 伝票番号型) throws -> [資材使用記録型]? {
        return try find(伝票番号, noCache: false)?.list
    }

    public func flush(伝票番号: 伝票番号型) {
        removeCache(forKey: 伝票番号)
    }
}

/*
class 資材使用記録キャッシュ型 {
    static let shared = 資材使用記録キャッシュ型()
    var expireTime: TimeInterval = 1*60*60 // 1時間
    private let lock = NSLock()
    private var cache: [伝票番号型: (有効期限: Date, 資材使用記録: [資材使用記録型])] = [:]

    func 現在資材使用記録(伝票番号: 伝票番号型) throws -> [資材使用記録型]? {
        let list = try 資材使用記録型.find(伝票番号: 伝票番号)
        let expire = Date(timeIntervalSinceNow: self.expireTime)
        lock.lock()
        cache[伝票番号] = (expire, list)
        lock.unlock()
        return list
    }

    func キャッシュ資材使用記録(伝票番号: 伝票番号型) throws -> [資材使用記録型]? {
        lock.lock()
        let data = self.cache[伝票番号]
        lock.unlock()
        if let data = data, Date() <= data.有効期限 {
            return data.資材使用記録
        }
        return try self.現在資材使用記録(伝票番号: 伝票番号)
    }

    func flush(伝票番号: 伝票番号型) {
        lock.lock()
        cache[伝票番号] = nil
        lock.unlock()
    }
    
    func flushAllCache() {
        lock.lock()
        self.cache.removeAll()
        lock.unlock()
    }
}
*/
