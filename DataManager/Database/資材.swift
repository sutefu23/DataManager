//
//  資材.swift
//  DataManager
//
//  Created by manager on 2019/03/19.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

public typealias 図番型 = String

public class 資材型: Codable, Comparable, Hashable {
    static let empty = 資材型()
    
    let record: FileMakerRecord
    public let 図番: 図番型
    public let 製品名称: String
    public let 規格: String
    public let 単価: Double?

    init(図番: 図番型 = "", 製品名称: String = "") {
        self.record = FileMakerRecord()
        self.図番 = 図番
        self.製品名称 = 製品名称
        self.規格 = ""
        self.単価 = nil
    }
    
    init(_ record: FileMakerRecord) throws {
        self.record = record
        guard let 図番 = record.string(forKey: "f13") else { throw FileMakerError.invalidData(message: "図番:f13 of レコードID \(record.recordID ?? "")") }
        guard let 製品名称 = record.string(forKey: "f3") else { throw FileMakerError.invalidData(message: "製品名称:f3 of 図番 \(図番)") }
        guard let 規格 = record.string(forKey: "f15") else { throw FileMakerError.invalidData(message: "規格:f15 of 図番 \(図番)") }
        self.図番 = 図番
        self.製品名称 = 製品名称
        self.規格 = 規格
        self.単価 = record.double(forKey: "f88")
    }
    public convenience init?(図番: 図番型) {
        guard let record = (try? 資材キャッシュ型.shared.キャッシュ資材(図番: 図番))?.record else { return nil }
        try? self.init(record)
    }
    
    // MARK: - Coable
    enum CodingKeys: String, CodingKey {
        case 図番
    }
    
    public required convenience init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let num = try values.decode(String.self, forKey: .図番)
        if let record = try 資材キャッシュ型.shared.キャッシュ資材(図番: num)?.record {
            try self.init(record)
        } else {
            self.init(図番: num, 製品名称: "\(num)?")
        }
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
        var scanner = DMScanner(self.図番, normalizedFullHalf: true)
        self.図番_数 = scanner.scanInteger() ?? Int.max
        self.図番_文字 = scanner.string
    }
    
    /// 図番が生産管理に存在する場合true
    public var isValid: Bool {
        (try? 資材キャッシュ型.shared.キャッシュ資材(図番: self.図番)) != nil
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

    public lazy var 表示用単価: String = {
        guard let num = self.単価 else { return "" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: NSNumber(value: num)) ?? ""
    }()

    // MARK: 在庫処理
    var レコード在庫数: Int { // 在庫キャッシュ経由でアクセスするとキャッシュされる
        return record.integer(forKey: "f32") ?? 0
    }
    public func 現在在庫数() throws -> Int {
        return  try 在庫数キャッシュ型.shared.現在在庫(of: self)
    }
    public func キャッシュ在庫() throws -> Int {
        return  try 在庫数キャッシュ型.shared.キャッシュ在庫数(of: self)
    }
    
    public func 現在入出庫() throws -> [資材入出庫型] {
        return try 入出庫キャッシュ型.shared.現在入出庫(of: self)
    }
    
    public func キャッシュ入出庫() throws -> [資材入出庫型] {
        return try 入出庫キャッシュ型.shared.キャッシュ入出庫(of: self)
    }
    
    // MARK: - 発注キャッシュ
    public func 現在発注一覧()throws -> [発注型] {
        return try 資材発注キャッシュ型.shared.現在発注一覧(図番: self.図番)
    }
    
    public func キャッシュ発注一覧()throws -> [発注型] {
        return try 資材発注キャッシュ型.shared.キャッシュ発注一覧(図番: self.図番)
    }
    
    public func prepareキャッシュ() throws {
        let _ = try self.キャッシュ入出庫()
        let _ = try self.キャッシュ在庫()
        let _ = try self.キャッシュ発注一覧()
    }
}

extension StringProtocol {
    var 図番バーコード: String? {
        if self.contains("-") { return nil }
        let count = self.count
        if (count == 8 || count == 9) && Int(self) != nil {
            return "I\(self)"
        }
        return String(self)
    }
}

public extension 資材型 {
    var 図番バーコード: String? { self.図番.図番バーコード }

    var 版数: String {
        return record.string(forKey: "f14") ?? ""
    }
    
    var 備考: String {
        return record.string(forKey: "備考") ?? ""
    }
    
    var 発注先名称: String {
        return record.string(forKey: "dbo.ZB_T1:f6") ?? ""
    }
    
    var 会社コード: 会社コード型 {
        return record.string(forKey: "会社コード") ?? ""
    }
    
    var 発注先: 取引先型? {
        return try? 取引先キャッシュ型.shared.キャッシュ取引先(会社コード: self.会社コード)
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

    var 登録日: Day { record.day(forKey: "登録日")! }
    
    // MARK: - 入出庫処理
    func 入庫(日時: Date? = nil, 部署: 部署型? = nil, 入庫者: 社員型, 入庫数: Int, 入力区分: 入力区分型 = .通常入出庫) throws {
        if 入庫数 == 0 { return }
        guard 入庫数 > 0 else {
            try self.出庫(日時: 日時, 部署: 部署, 出庫者: 入庫者, 出庫数: -入庫数, 入力区分: 入力区分)
            return
        }
        guard let action = 資材入出庫出力型(登録日: 日時?.day, 登録時間: 日時?.time, 資材: self, 部署: 部署, 入庫数: 入庫数, 出庫数: 0, 社員: 入庫者, 入力区分: 入力区分) else { throw FileMakerError.invalidData(message: "資材入庫: 図番:\(self.図番) 入庫者:\(入庫者.社員名称) 入庫数:\(入庫数)") }
        try [action].exportToDB()
    }
    
    func 出庫(日時: Date? = nil, 部署: 部署型? = nil, 出庫者: 社員型, 出庫数: Int, 入力区分: 入力区分型 = .通常入出庫) throws {
        if 出庫数 == 0 { return }
        guard 出庫数 > 0 else {
            try self.入庫(部署: 部署, 入庫者: 出庫者, 入庫数: -出庫数, 入力区分: 入力区分)
            return
        }
        guard let action = 資材入出庫出力型(登録日: 日時?.day, 登録時間: 日時?.time, 資材: self, 部署: 部署, 入庫数: 0, 出庫数: 出庫数, 社員: 出庫者, 入力区分: 入力区分) else { throw FileMakerError.invalidData(message: "資材出庫: 図番:\(self.図番) 出庫者:\(出庫者.社員名称) 出庫数:\(出庫数)") }
        try [action].exportToDB()
    }

    func 数量確認(日時: Date? = nil, 部署: 部署型? = nil, 確認者: 社員型, 入力区分: 入力区分型 = .数量調整) throws {
        guard let action = 資材入出庫出力型(登録日: 日時?.day, 登録時間: 日時?.time, 資材: self, 部署: 部署, 入庫数: 0, 出庫数: 0, 社員: 確認者, 入力区分: 入力区分) else { throw FileMakerError.invalidData(message: "資材確認: 図番:\(self.図番) 確認者:\(確認者.社員名称))") }
        try [action].exportToDB()
    }
    
    @discardableResult func 数量調整(部署: 部署型? = nil, 調整者: 社員型, 現在数: Int) throws -> Bool {
        let data = try self.現在在庫数()
        let diff = 現在数 - data
        if diff == 0 { return false }
        if diff > 0 { // 現在数がデータより多い==追加の入庫が必要
            try self.入庫(部署: 部署, 入庫者: 調整者, 入庫数: diff, 入力区分: .数量調整)
        } else { // 現在数がデータより少ない==追加の出庫が必要
            assert(diff < 0)
            try self.出庫(部署: 部署, 出庫者: 調整者, 出庫数: -diff, 入力区分: .数量調整)
        }
        return true
    }
}
    
// MARK: - 保存
extension FileMakerRecord {
    func 資材(forKey key: String) -> 資材型? {
        guard let number = self.string(forKey: key) else { return nil }
        return try? 資材キャッシュ型.shared.キャッシュ資材(図番: number)
    }
}

// MARK: - 検索
public extension 資材型 {
    static let dbName = "DataAPI_5"
    
    /// 全資材の読み込み
    static func fetchAll() throws -> [資材型] {
        let db = FileMakerDB.pm_osakaname
        let list: [FileMakerRecord] = try db.fetch(layout: 資材型.dbName)
        return try list.compactMap { try 資材型($0) }.sorted()
    }
    
    static func find(図番: 図番型) throws -> 資材型? {
        if 図番.isEmpty { return nil }
        let db = FileMakerDB.pm_osakaname
        var query = FileMakerQuery()
        query["f13"] = "==\(図番)"
        let list: [FileMakerRecord] = try db.find(layout: 資材型.dbName, query: [query])
        return try list.compactMap { try 資材型($0) }.first
    }
}

extension 資材型 {
    public var 面積単価: Double? {
        let sheet = 管理板材型(資材: self)
        guard let width = sheet.横幅, let height = sheet.高さ, let price = self.単価 else { return nil }
        return price / (width * height)
    }

    public var 面積: Double? {
        let sheet = 管理板材型(資材: self)
        guard let width = sheet.横幅, let height = sheet.高さ else { return nil }
        return width * height
    }

    public var 標準表示名: String {
        (self.規格.isEmpty ? self.製品名称 : "\(self.製品名称) \(self.規格)").全角半角日本語規格化()
    }
}
