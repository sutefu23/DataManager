//
//  月間目標型.swift
//  DataManager
//
//  Created by manager on 2020/11/25.
//

import Foundation

private let lock = NSRecursiveLock()

struct 月間目標Data型: Equatable {
    static let dbName = "DataAPI_10"

    var 対象月: Month
    
    var 箱文字件数: Int
    var 溶接件数: Int
    var 半田件数: Int
    var 切文字件数: Int
    var 加工件数: Int
    var エッチング件数: Int
    
    var 売上金額: Double
    
    var 箱文字比率: Double
    var 切文字比率: Double
    var 加工比率: Double
    var エッチング比率: Double
    var 外注比率: Double
}

extension 月間目標Data型 {
    init?(_ record: FileMakerRecord) {
        guard
            let 対象月 = record.day(forKey: "対象月"),
            let 箱文字件数 = record.integer(forKey: "箱文字件数"),
            let 溶接件数 = record.integer(forKey: "溶接件数"),
            let 半田件数 = record.integer(forKey: "半田件数"),
            let 切文字件数 = record.integer(forKey: "切文字件数"),
            let 加工件数 = record.integer(forKey: "加工件数"),
            let エッチング件数 = record.integer(forKey: "エッチング件数"),
            let 売上金額 = record.double(forKey: "売上金額"),
            let 箱文字比率 = record.double(forKey: "箱文字比率"),
            let 切文字比率 = record.double(forKey: "切文字比率"),
            let 加工比率 = record.double(forKey: "加工比率"),
            let エッチング比率 = record.double(forKey: "エッチング比率"),
            let 外注比率 = record.double(forKey: "外注比率")
        else { return nil }
        self.init(対象月: Month(対象月),
                  箱文字件数: 箱文字件数,
                  溶接件数: 溶接件数,
                  半田件数: 半田件数,
                  切文字件数: 切文字件数,
                  加工件数: 加工件数,
                  エッチング件数: エッチング件数,
                  売上金額: 売上金額,
                  箱文字比率: 箱文字比率,
                  切文字比率: 切文字比率,
                  加工比率: 加工比率,
                  エッチング比率: エッチング比率,
                  外注比率: 外注比率)
    }
    
    var fieldData: FileMakerQuery {
        var data = FileMakerQuery()
        data["対象月"] = self.対象月.firstDay.fmString
        data["箱文字件数"] = String(箱文字件数)
        data["溶接件数"] = String(溶接件数)
        data["半田件数"] = String(半田件数)
        data["切文字件数"] = String(切文字件数)
        data["加工件数"] = String(加工件数)
        data["エッチング件数"] = String(エッチング件数)
        data["売上金額"] = String(売上金額)
        data["箱文字比率"] = String(箱文字比率)
        data["切文字比率"] = String(切文字比率)
        data["加工比率"] = String(加工比率)
        data["エッチング比率"] = String(エッチング比率)
        data["外注比率"] = String(外注比率)
        return data
    }
}

public final class 月間目標型 {
    var original: 月間目標Data型?
    var data: 月間目標Data型
    
    public internal(set) var recordId: String?
    
    public var 対象月: Month {
        get { data.対象月 }
        set { data.対象月 = newValue }
    }

    public var 箱文字件数: Int {
        get { data.箱文字件数 }
        set { data.箱文字件数 = newValue }
    }
    public var 溶接件数: Int {
        get { data.溶接件数 }
        set { data.溶接件数 = newValue }
    }
    public var 半田件数: Int {
        get { data.半田件数 }
        set { data.半田件数 = newValue }
    }
    public var 切文字件数: Int {
        get { data.切文字件数 }
        set { data.切文字件数 = newValue }
    }
    public var 加工件数: Int {
        get { data.加工件数 }
        set { data.加工件数 = newValue }
    }
    public var エッチング件数: Int {
        get { data.エッチング件数 }
        set { data.エッチング件数 = newValue }
    }
    
    public var 売上金額: Double {
        get { data.売上金額 }
        set { data.売上金額 = newValue }
    }
    
    public var 箱文字比率: Double {
        get { data.箱文字比率 }
        set { data.箱文字比率 = newValue }
    }
    public var 切文字比率: Double {
        get { data.切文字比率 }
        set { data.切文字比率 = newValue }
    }
    public var 加工比率: Double {
        get { data.加工比率 }
        set { data.加工比率 = newValue }
    }
    public var エッチング比率: Double {
        get { data.エッチング比率 }
        set { data.エッチング比率 = newValue }
    }
    public var 外注比率: Double {
        get { data.外注比率 }
        set { data.外注比率 = newValue }
    }
    
    public init(対象月: Month, 箱文字件数: Int, 溶接件数: Int, 半田件数: Int, 切文字件数: Int, 加工件数: Int, エッチング件数: Int, 売上金額: Double, 箱文字比率: Double, 切文字比率: Double, 加工比率: Double, エッチング比率: Double, 外注比率: Double) {
        self.data = 月間目標Data型(対象月: 対象月, 箱文字件数: 箱文字件数, 溶接件数: 溶接件数, 半田件数: 半田件数, 切文字件数: 切文字件数, 加工件数: 加工件数, エッチング件数: エッチング件数, 売上金額: 売上金額, 箱文字比率: 箱文字比率, 切文字比率: 切文字比率, 加工比率: 加工比率, エッチング比率: エッチング比率, 外注比率: 外注比率)
    }
    init?(_ record: FileMakerRecord) {
        guard let data = 月間目標Data型(record) else { return nil }
        self.data = data
        self.original = data
        self.recordId = record.recordID
    }
    
    public var isChanged: Bool { original != data }

    public func loadData(of source: 月間目標型) {
        self.data = source.data
    }
    
    public func isEqualData(to data: 月間目標型) -> Bool {
        return self.data == data.data
    }
    
    // MARK: - DB操作
    public func delete() throws {
        guard let recordID = self.recordId else { return }
        lock.lock(); defer { lock.unlock() }
        let db = FileMakerDB.system
        try db.delete(layout: 月間目標Data型.dbName, recordId: recordID)
        self.recordId = nil
//        食事時間帯キャッシュ型.shared.flush(提供パターン: self.提供パターン, 食事グループ: self.食事グループ)
    }
    
    public func upload() {
        let data = self.data.fieldData
        lock.lock(); defer { lock.unlock() }
        let db = FileMakerDB.system
        let _ = try? db.insert(layout: 月間目標Data型.dbName, fields: data)
//        食事時間帯キャッシュ型.shared.flush(提供パターン: self.提供パターン, 食事グループ: self.食事グループ)
    }
    
    public func synchronize() throws {
        if !isChanged { return }
        let data = self.data.fieldData
        lock.lock(); defer { lock.unlock() }
        
        let db = FileMakerDB.system
        if let recordId = self.recordId {
            try db.update(layout: 月間目標Data型.dbName, recordId: recordId, fields: data)
        } else {
            self.recordId = try db.insert(layout: 月間目標Data型.dbName, fields: data)
        }
//        食事時間帯キャッシュ型.shared.flush(提供パターン: self.提供パターン, 食事グループ: self.食事グループ)
    }
    
    /// 既に登録済みなら差し替える、そうでなければ普通にアップロードする
    public func replace() throws {
        if self.recordId == nil {
            if let target = try 月間目標型.find(対象月: self.対象月) {
                self.recordId = target.recordId
                if self.isEqualData(to: target) { return } // アップロード不要
            }
        }
        try self.synchronize()
    }
    
    public func load(from: 月間目標型) {
        self.original = from.original
        self.data = from.data
        self.recordId = from.recordId
    }
    
    // MARK: - DB検索
    static func find(query: FileMakerQuery) throws -> [月間目標型] {
        lock.lock(); defer { lock.unlock() }
        let db = FileMakerDB.system
        let list: [FileMakerRecord]
        if query.isEmpty {
            list = try db.fetch(layout: 月間目標Data型.dbName)
        } else {
            list = try db.find(layout: 月間目標Data型.dbName, query: [query])
        }
        return list.compactMap { 月間目標型($0) }
    }
    
    public static func find(対象月: Month) throws -> 月間目標型? {
        var query = FileMakerQuery()
        query["対象月"] = 対象月.firstDay.fmString
        return try find(query: query).first
    }
}
