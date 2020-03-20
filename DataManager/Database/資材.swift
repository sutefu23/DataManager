//
//  資材.swift
//  DataManager
//
//  Created by manager on 2019/03/19.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

public class 資材型: Codable, Comparable, Hashable {
    let record: FileMakerRecord
    public let 図番: String
    public let 製品名称: String
    public let 規格: String
    public let 単価: Double?

    init(_ record: FileMakerRecord) throws {
        self.record = record
        guard let 図番 = record.string(forKey: "f13") else { throw FileMakerError.invalidData(message: "図番:f13 of レコードID \(record.recordId ?? "")") }
        guard let 製品名称 = record.string(forKey: "f3") else { throw FileMakerError.invalidData(message: "製品名称:f3 of 図番 \(図番)") }
        guard let 規格 = record.string(forKey: "f15") else { throw FileMakerError.invalidData(message: "規格:f13 of 図番 \(図番)") }
        self.図番 = 図番
        self.製品名称 = 製品名称
        self.規格 = 規格
        self.単価 = record.double(forKey: "f88")
    }
    public convenience init?(図番: String ) {
        guard let record = (try? 資材型.find(図番: 図番))?.record else { return nil }
        try? self.init(record)
    }
    
    // MARK: - Coable
    enum CodingKeys: String, CodingKey {
        case 図番
    }
    
    public required convenience init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let num = try values.decode(String.self, forKey: .図番)
        guard let record = try 資材型.find(図番: num)?.record else {
            throw FileMakerError.notFound(message: "図番:\(num)")
        }
        try self.init(record)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.図番, forKey: .図番)
    }
    
    public var 図番数: Int {
        if let num = 図番_数 { return num }
        self.analyze図番()
        return 図番_数!
    }

    public var 図番追記文字: String {
        if let str = 図番_文字 { return str }
        self.analyze図番()
        return 図番_文字!
    }

    private var 図番_数: Int? = nil
    private var 図番_文字: String? = nil
    
    func analyze図番() {
        var scanner = DMScanner(self.図番)
        self.図番_数 = scanner.scanInteger() ?? Int.max
        self.図番_文字 = scanner.string
    }
    
    // MARK: - <Comparable>
    public static func == (left: 資材型, right: 資材型) -> Bool {
        return left.図番 == right.図番
    }
    public static func < (left: 資材型, right: 資材型) -> Bool {
        if left.図番数 != right.図番数 {
            return left.図番数 < right.図番数
        } else {
            return left.図番追記文字 < right.図番追記文字
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.図番)
    }
    
    public lazy var 箱入り数: Double = {
        guard let num = self.record.double(forKey: "f43") else { return 1 }
        return num > 0 ? num : 1
    }()
    
    var レコード在庫数: Int {
        return record.integer(forKey: "f32") ?? 0
    }
    
    public var 表示用単価: String {
        guard let num = self.単価 else { return "" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: NSNumber(value: num)) ?? ""
    }
}

public extension 資材型 {
    var 版数: String {
        return record.string(forKey: "f14") ?? ""
    }
    
    var 備考: String {
        return record.string(forKey: "備考") ?? ""
    }
    
    var 発注先名称: String {
        return record.string(forKey: "dbo.ZB_T1:f6") ?? ""
    }
    
    var 会社コード: String {
        return record.string(forKey: "会社コード") ?? ""
    }
    
    var 規格2: String {
        return record.string(forKey: "規格2") ?? ""
    }
    
    var 種類: String {
        return record.string(forKey: "種類") ?? ""
    }
    
    var 単位: String {
        return record.string(forKey: "dbo.SYS_T2:f4") ?? ""
    }
}

// MARK: - 保存
extension FileMakerRecord {
    func 資材(forKey key: String) -> 資材型? {
        guard let number = self.string(forKey: key) else { return nil }
        return 資材キャッシュ型.shared[number]
    }
}

// MARK: - 検索
public extension 資材型 {
    static let dbName = "DataAPI_5"
    
    /// 全資材の読み込み
    static func fetch() throws -> [資材型] {
        let db = FileMakerDB.pm_osakaname
        let list: [FileMakerRecord] = try db.fetch(layout: 資材型.dbName)
        return try list.compactMap { try 資材型($0) }.sorted()
    }
    
    static func find(図番: String) throws -> 資材型? {
        let db = FileMakerDB.pm_osakaname
        var query = FileMakerQuery()
        query["f13"] = "==\(図番)"
        let list: [FileMakerRecord] = try db.find(layout: 資材型.dbName, query: [query])
        return try list.compactMap { try 資材型($0) }.first
    }
}
