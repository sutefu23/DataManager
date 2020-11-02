//
//  食事要求型.swift
//  DataManager
//
//  Created by 四熊泰之 on R 2/09/26.
//

import Foundation

private let serialQueue: OperationQueue = {
   let queue = OperationQueue()
    queue.maxConcurrentOperationCount = 1
    queue.qualityOfService = .utility
    return queue
}()

public enum 食事要求状態型: String {
    case 未処理
    case 受取待
    case 受渡済
    case 追加発注
}

struct 食事要求Data型: Equatable {
    static let dbName = "DataAPI_7"
    
    var 社員番号: String
    var メニューID: メニューID型
    var 要求状態: 食事要求状態型
    
    var 修正情報タイムスタンプ: Date
    
    init(社員番号: String, メニューID: メニューID型, 要求状態: 食事要求状態型) {
        self.社員番号 = 社員番号
        self.メニューID = メニューID
        self.要求状態 = 要求状態
        self.修正情報タイムスタンプ = Date().rounded()
    }
    
    init?(_ record: FileMakerRecord) {
        guard let 社員番号 = record.string(forKey: "社員番号"),
              let メニューID = record.string(forKey: "メニューID"),
              let 状態str = record.string(forKey: "要求状態"),
              let 要求状態 = 食事要求状態型(rawValue: 状態str) else { return nil }
        self.社員番号 = 社員番号
        self.メニューID = メニューID
        self.要求状態 = 要求状態
        self.修正情報タイムスタンプ = record.date(forKey: "修正情報タイムスタンプ") ?? Date().rounded()
    }
    
    var fieldData: FileMakerQuery {
        var data = FileMakerQuery()
        data["社員番号"] = self.社員番号
        data["メニューID"] = self.メニューID
        data["要求状態"] = self.要求状態.rawValue
        return data
    }
}

public class 食事要求型: Identifiable {
    var original: 食事要求Data型?
    var data: 食事要求Data型
    
    public internal(set) var recordId: String?
    
    public var 社員番号: String {
        get { data.社員番号 }
        set { data.社員番号 = newValue }
    }
    public var メニューID: メニューID型 {
        get { data.メニューID }
        set { data.メニューID = newValue }
    }
    public var 要求状態: 食事要求状態型 {
        get { data.要求状態 }
        set { data.要求状態 = newValue }
    }
    
    public var 修正情報タイムスタンプ: Date { data.修正情報タイムスタンプ }
    
    init(社員番号: String, メニューID: メニューID型, 要求状態: 食事要求状態型) {
        self.data = 食事要求Data型(社員番号: 社員番号, メニューID: メニューID, 要求状態: 要求状態)
    }
    
    init?(_ record: FileMakerRecord) {
        guard let data = 食事要求Data型(record) else { return nil }
        self.data = data
        self.original = data
        self.recordId = record.recordID
    }

    public var isChanged: Bool { original != data }
    
    public lazy var メニュー: 食事メニュー型? = {
        try? 食事メニューキャッシュ型.shared.キャッシュメニュー(メニューID: self.メニューID)
    }()
    public lazy var IDカード: IDカード型? = {
        try? IDカード型.find(社員番号: self.社員番号).last
    }()
    
    public lazy var 社員: 社員型? = { 社員型(社員コード: self.社員番号) }()

    // MARK: - DB操作
    public func delete() throws {
        guard let recordID = self.recordId else { return }
        var result: Error? = nil
        let operation = BlockOperation {
            do {
                let db = FileMakerDB.system
                try db.delete(layout: 食事要求Data型.dbName, recordId: recordID)
                self.recordId = nil
                //                資材使用記録キャッシュ型.shared.flush(伝票番号: self.伝票番号)
            } catch {
                result = error
            }
        }
        serialQueue.addOperation(operation)
        operation.waitUntilFinished()
        if let error = result { throw error }
    }

    public func upload() {
        let data = self.data.fieldData
        serialQueue.addOperation {
            let db = FileMakerDB.system
            let _ = try? db.insert(layout: 食事要求Data型.dbName, fields: data)
            //                資材使用記録キャッシュ型.shared.flush(伝票番号: self.伝票番号)
        }
    }

    public func synchronize() throws {
        if !isChanged { return }
        let data = self.data.fieldData
        var result: Result<String, Error>!
        let operation = BlockOperation {
            let db = FileMakerDB.system
            do {
                if let recordID = self.recordId {
                    try db.update(layout: 食事要求Data型.dbName, recordId: recordID, fields: data)
                    result = .success(recordID)
                } else {
                    let recordID = try db.insert(layout: 食事要求Data型.dbName, fields: data)
                    result = .success(recordID)
                }
//                資材使用記録キャッシュ型.shared.flush(伝票番号: self.伝票番号)
            } catch {
                result = .failure(error)
            }
        }
        serialQueue.addOperation(operation)
        operation.waitUntilFinished()
        self.recordId = try result.get()
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
        var result: Result<[FileMakerRecord], Error>!
        let operation = BlockOperation {
            let db = FileMakerDB.system
            do {
                let list: [FileMakerRecord] = try db.find(layout: 食事要求Data型.dbName, query: [query])
                result = .success(list)
            } catch {
                result = .failure(error)
            }
        }
        serialQueue.addOperation(operation)
        operation.waitUntilFinished()
        let list = try result.get().compactMap { 食事要求型($0) }
        return list
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
        let query: FileMakerQuery = ["DataAPI_食事メニュー::発注日": 発注日.fmString]
        return try find(query: query)
    }

    public static func find追加発注(発注日: Day) throws -> [食事要求型] {
        let query: FileMakerQuery = ["DataAPI_食事メニュー::提供日": 発注日.fmString, "要求状態": "追加発注"]
        return try find(query: query)
    }

    public static func find(提供日: Day, 種類: 食事種類型? = nil) throws -> [食事要求型] {
        var query: FileMakerQuery = ["DataAPI_食事メニュー::提供日": 提供日.fmString]
        if let type = 種類 {
            query["DataAPI_食事メニュー::種類"] = "==\(type.rawValue)"
        }
        return try find(query: query)
    }

    public static func find(提供開始日: Day) throws -> [食事要求型] {
        let query: FileMakerQuery = ["DataAPI_食事メニュー::提供日": ">=\(提供開始日.fmString)"]
        return try find(query: query)
    }
    
    public static func find(提供期間: ClosedRange<Day>) throws -> [食事要求型] {
        var query = FileMakerQuery()
        query["DataAPI_食事メニュー::提供日"] = makeQueryDayString(提供期間)
        return try find(query: query)
    }
    
    public static func backup(from day: Day) throws {
        let list = try 食事要求型.find(提供開始日: day)
        let gen = TableGenerator<食事要求型>()
            .string("社員番号") { $0.社員番号 }
            .string("メニューID") { $0.メニューID }
            .string("要求状態") { $0.要求状態.rawValue }
            .date("修正情報タイムスタンプ", .yearToMinute) { $0.修正情報タイムスタンプ }
        try gen.share(list, format: .excel(header: true), title: "backup食事要求\(day.monthDayJString).csv")
    }

}

public extension Sequence where Element == 食事要求型 {
    /// 要求を時間帯ごとに分割する
    var 時間帯リスト: [(開始時間: Time, list: [食事要求型])] {
        let dic = Dictionary(grouping: self) { $0.食事時間帯?.開始時間 ?? Time(0, 0) }
        return dic.sorted { $0.key < $1.key }.map { ($0.key, $0.value) }
    }
}
