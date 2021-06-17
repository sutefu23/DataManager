//
//  資材使用記録.swift
//  DataManager
//
//  Created by manager on 2020/04/16.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

private let lock = NSRecursiveLock()

public enum 印刷対象型: String {
    public static let 仮印刷対象工程: Set<工程型> = [.裏加工, .裏加工_溶接]
    
    case 全て
    case なし
    
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

struct 資材使用記録Data型: Equatable {
    static let dbName = "DataAPI_5"
    var 登録日時: Date
    
    var 伝票番号: 伝票番号型
    var 工程: 工程型
    var 作業者: 社員型
    var 図番: 図番型
    var 表示名: String
    var 単価: Double?
    var 用途: String?
    var 使用量: String?
    var 使用面積: Double?
    var 単位量: Double?
    var 単位数: Double?
    var 金額: Double?
    var 印刷対象: 印刷対象型?
    var 原因工程: 工程型?

    init(登録日時: Date, 伝票番号: 伝票番号型, 工程: 工程型, 作業者: 社員型, 図番: 図番型, 表示名: String, 単価: Double?, 用途: String?, 使用量: String?, 単位量: Double?, 単位数: Double?, 金額: Double?, 印刷対象: 印刷対象型?, 原因工程: 工程型?) {
        self.登録日時 = 登録日時
        self.伝票番号 = 伝票番号
        self.工程 = 工程
        self.作業者 = 作業者
        self.図番 = 図番
        self.表示名 = 表示名
        self.単価 = 単価
        self.用途 = 用途
        self.使用量 = 使用量
        self.金額 = 金額
        self.単位量 = 単位量
        self.単位数 = 単位数
        self.印刷対象 = 印刷対象
        self.原因工程 = 原因工程
    }
    
    init?(_ record: FileMakerRecord) {
        guard let date = record.date(dayKey: "登録日", timeKey: "登録時間") else { return nil }
        guard let number = record.伝票番号(forKey: "伝票番号") else { return nil }
        guard let process = record.工程(forKey: "工程コード") else { return nil }
        guard let worker = record.社員(forKey: "作業者コード") else { return nil }
        guard let item = record.資材(forKey: "図番") else { return nil }
        
        self.登録日時 = date
        self.伝票番号 = number
        self.工程 = process
        self.作業者 = worker
        self.図番 = item.図番
        self.単価 = record.double(forKey: "単価") ?? item.単価
        self.使用量 = record.string(forKey: "使用量")
        self.用途 = record.string(forKey: "用途")
        self.金額 = record.double(forKey: "金額")
        if let title = record.string(forKey: "表示名"), !title.isEmpty {
            self.表示名 = title.全角半角日本語規格化()
        } else {
            self.表示名 = item.標準表示名
        }
        self.単位量 = record.double(forKey: "単位量")
        self.単位数 = record.double(forKey: "単位数")
        self.印刷対象 = record.印刷対象(forKey: "印刷対象")
        self.原因工程 = record.工程(forKey: "原因工程コード")
    }
    
    var fieldData: FileMakerQuery {
        var data = FileMakerQuery()
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
        } else {
            data["単位量"] = ""
        }
        if let value = self.単位数 {
            data["単位数"] = "\(value)"
        } else {
            data["単位数"] = ""
        }
        if let charge = self.金額 {
            data["金額"] = "\(charge)"
        } else {
            data["金額"] = ""
        }
        if let target = self.印刷対象 {
            data["印刷対象"] = target.rawValue
        } else {
            data["印刷対象"] = ""
        }
        return data
    }
}

public final class 資材使用記録型 {
    var original: 資材使用記録Data型?
    var data: 資材使用記録Data型
    public internal(set) var recordID: String?

    public var 登録日時: Date {
        get { data.登録日時 }
        set { data.登録日時 = newValue }
    }
    public var 伝票番号: 伝票番号型 {
        get { data.伝票番号 }
        set { data.伝票番号 = newValue }
    }
    public var 工程: 工程型 {
        get { data.工程 }
        set { data.工程 = newValue }
    }
    public var 原因工程: 工程型? {
        get { data.原因工程 }
        set { data.原因工程 = newValue }
    }
    public var 作業者: 社員型 {
        get { data.作業者 }
        set { data.作業者 = newValue }
    }
    
    public var 表示名: String {
        get { data.表示名 }
        set { data.表示名 = newValue }
    }
    public var 図番: 図番型 {
        get { data.図番 }
        set { data.図番 = newValue }
    }
    public var 単価: Double? {
        get { data.単価 }
        set { data.単価 = newValue }
    }
    public var 用途: String? {
        get { data.用途 }
        set { data.用途 = newValue }
    }
    public var 使用量: String? {
        get { data.使用量 }
        set { data.使用量 = newValue }
    }
    public var 金額: Double? {
        get { data.金額 }
        set { data.金額 = newValue }
    }
    public var 単位量: Double? {
        get { data.単位量 }
        set { data.単位量 = newValue }
    }

    public var 単位数: Double? {
        get { data.単位数 }
        set { data.単位数 = newValue }
    }
    
    public var 印刷対象: 印刷対象型? {
        get { data.印刷対象 }
        set { data.印刷対象 = newValue }
    }
    
    public var 仮印刷対象: 印刷対象型 {
        if let target = data.印刷対象 { return target }
        return 印刷対象型.仮印刷対象工程.contains(data.工程) ? .全て : .なし
    }

    public init(登録日時: Date, 伝票番号: 伝票番号型, 工程: 工程型, 作業者: 社員型, 図番: 図番型, 表示名: String, 単価: Double?, 用途: String?, 使用量: String?, 単位量: Double?, 単位数: Double?, 金額: Double?, 印刷対象: 印刷対象型?, 原因工程: 工程型?) {
        self.data = 資材使用記録Data型(登録日時: 登録日時, 伝票番号: 伝票番号, 工程: 工程, 作業者: 作業者, 図番: 図番, 表示名: 表示名, 単価: 単価, 用途: 用途, 使用量: 使用量, 単位量: 単位量, 単位数: 単位数, 金額: 金額, 印刷対象: 印刷対象, 原因工程: 原因工程)
    }

    init?(_ record: FileMakerRecord) {
        guard let data = 資材使用記録Data型(record) else { return nil }
        self.data = data
        self.original = data
        self.recordID = record.recordID
    }
    
    public var isChanged: Bool { original != data }
    
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
        if let last = try 指示書進捗キャッシュ型.shared.キャッシュ一覧(self.伝票番号).工程別進捗一覧[execProcess]?.last(where: { $0.登録日時 < self.登録日時 && $0.作業種別 != .作直 }) {
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
        guard let recordID = self.recordID else { return }
        lock.lock(); defer { lock.unlock() }
        let db = FileMakerDB.system
        try db.delete(layout: 資材使用記録Data型.dbName, recordId: recordID)
        self.recordID = nil
        資材使用記録キャッシュ型.shared.flush(伝票番号: self.伝票番号)
    }

    public func upload() throws {
        let data = self.data.fieldData
        lock.lock(); defer { lock.unlock() }
        let db = FileMakerDB.system
        let _ = try db.insert(layout: 資材使用記録Data型.dbName, fields: data)
        資材使用記録キャッシュ型.shared.flush(伝票番号: self.伝票番号)
    }
    
    public func synchronize() throws {
        if !isChanged { return }
        let data = self.data.fieldData
        lock.lock(); defer { lock.unlock() }
            let db = FileMakerDB.system
        if let recordID = self.recordID {
            try db.update(layout: 資材使用記録Data型.dbName, recordId: recordID, fields: data)
        } else {
            self.recordID = try db.insert(layout: 資材使用記録Data型.dbName, fields: data)
        }
        self.original = self.data
        資材使用記録キャッシュ型.shared.flush(伝票番号: self.伝票番号)
    }
    
    // MARK: - DB検索
    static func find(query: FileMakerQuery) throws -> [資材使用記録型] {
        if query.isEmpty { return [] }
        lock.lock(); defer { lock.unlock() }
        let db = FileMakerDB.system
        let list: [FileMakerRecord] = try db.find(layout: 資材使用記録Data型.dbName, query: [query])
        return list.compactMap { 資材使用記録型($0) }
    }
    public static func find(登録日:ClosedRange<Day>) throws -> [資材使用記録型] {
        var query = [String: String]()
        query["登録日"] = makeQueryDayString(登録日)
        return try find(query: query)
    }
    
    public static func find(伝票番号: 伝票番号型? = nil, 図番: 図番型? = nil) throws -> [資材使用記録型] {
        var query = [String: String]()
        if let order = 伝票番号 {
            query["伝票番号"] = "==\(order)"
        }
        if let item = 図番 {
            query["図番"] = "==\(item)"
        }
        return try find(query: query)
    }
    
    public static func find(伝票番号: 伝票番号型, 図番: 図番型, 表示名: String, 工程: 工程型? = nil) throws -> [資材使用記録型] {
        var query = FileMakerQuery()
        query["伝票番号"] = "==\(伝票番号)"
        query["図番"] = "==\(図番)"
        query["表示名"] = "==\(表示名)"
        if let 工程 = 工程 {
            query["工程コード"] = "==\(工程.code)"
        }
        return try find(query: query)
    }
    
    public static func find(伝票番号: 伝票番号型?, 工程: 工程型?, 登録期間: ClosedRange<Day>?) throws -> [資材使用記録型] {
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
