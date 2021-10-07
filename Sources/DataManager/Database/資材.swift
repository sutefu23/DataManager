//
//  資材.swift
//  DataManager
//
//  Created by manager on 2019/03/19.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

public typealias 図番型 = String

public final class 資材型: FileMakerSearchObject, Codable, Comparable, Hashable {
    public static var layout: String { "DataAPI_5" }
    
    public let recordId: FileMakerRecordID?
    private let data2: 発注資材情報型
    private let data: 資材種類Data型
    private let 社名コードData: 社名コードData型
    
    public let 登録日: Day
    public let 図番: 図番型
    public var 製品名称: String { data2.製品名称 }
    public var 規格: String { data2.規格 }
    public var 規格2: String { data2.規格2 }
    public let 備考: String

    public let 単価: Double?
    public let 箱入り数: Double
    public let レコード在庫数: Int
    public let is棚卸し対象: Bool
    
    public var 発注先名称: String { 社名コードData.会社名 }
    public var 会社コード: 会社コード型 { 社名コードData.会社コード }

    public var 版数: String { data2.版数 }
    public var 種類: String { data.種類 }
    public var 旧図番: Set<String>? { data.種類data.旧図番 }
    public var ボルト等種類: Set<選択ボルト等種類型>? { data.種類data.ボルト等種類 }
    public var 単位: String { data.単位 }

    public var memoryFootPrint: Int {
        return (3 * 1 + 2 * 10 + 3 + 1) * 8 + data.memoryFootPrint
    }
    
    public init(_ record: FileMakerRecord) throws {
        func makeError(_ key: String) -> Error { record.makeInvalidRecordError(name: "資材", mes: key) }
        func getString(_ key: String, _ mes: String? = nil) throws -> String {
            guard let string = record.string(forKey: key) else { throw makeError(mes ?? key) }
            return string
        }
        guard let 登録日 = record.day(forKey: "登録日") else { throw makeError("登録日") }
        self.登録日 = 登録日

        let 図番 = try getString("f13", "図番")
        self.図番 = 図番
        self.備考 = try getString("備考")

        self.単価 = record.double(forKey: "f88")
        
        self.箱入り数 = record.double(forKey: "f43") ?? 1
        self.レコード在庫数 = record.integer(forKey: "f32") ?? 0
        self.is棚卸し対象 = record.string(forKey: "棚卸し対象")?.isEmpty == false
        
        self.recordId = record.recordId
        self.data = 資材種類Data型(資材: record).regist()
        self.data2 = 発注資材情報型(資材: record).regist()
        self.社名コードData = 社名コードData型(資材: record).regist()
    }
    
    init(_ item: 資材型) {
        self.recordId = item.recordId
        self.data = item.data
        self.data2 = item.data2
        self.社名コードData = item.社名コードData

        self.図番 = item.図番
//        self.製品名称 = item.製品名称
//        self.規格 = item.規格
        self.単価 = item.単価
        
        self.箱入り数 = item.箱入り数
        self.レコード在庫数 = item.レコード在庫数
        self.is棚卸し対象 = item.is棚卸し対象
        self.備考 = item.備考
//        self.規格2 = item.規格2
        self.登録日 = item.登録日
    }
    
    // MARK: - Coable
    enum CodingKeys: String, CodingKey {
        case 図番
    }
    
    public required convenience init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let num = try values.decode(String.self, forKey: .図番)
//        if num == "996068" { num = "990120" }
        if let item = try 資材キャッシュ型.shared.キャッシュ資材(図番: num) {
            self.init(item)
        } else {
            throw FileMakerError.invalidData(message: "不明な図番がある\(num)")
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
    
    public lazy var 表示用単価: String = {
        guard let num = self.単価 else { return "" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: NSNumber(value: num)) ?? ""
    }()

    // MARK: 在庫処理
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

    var 発注先: 取引先型? {
        return try? 取引先キャッシュ型.shared.キャッシュ取引先(会社コード: self.会社コード)
    }
    
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
    
    @discardableResult
    func 数量調整(部署: 部署型? = nil, 調整者: 社員型, 現在数: Int) throws -> Bool {
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
    static func find(図番: 図番型) throws -> 資材型? {
        if 図番.isEmpty { return nil }
        var query = FileMakerQuery()
        query["f13"] = "==\(図番)"
        return try self.find(query: query).first
    }
    
    static func find新図番資材(元図番: 図番型) throws -> [資材型] {
        if 元図番.isEmpty { return [] }
        var query = FileMakerQuery()
        query["種類"] = "[\(元図番)]"
        return try self.find(query: query).filter { $0.旧図番?.contains(元図番) == true }
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

final class 資材種類Data型: DMLightWeightObject, FileMakerLightWeightData {
    static let cache = LightWeightStorage<資材種類Data型>()

    let 種類: String
    let 単位: String
    let 種類data: 資材種類内容型

    init(資材 record: FileMakerRecord) {
        self.単位 = record.string(forKey: "dbo.SYS_T2:f4") ?? ""
        self.種類 = record.string(forKey: "種類") ?? ""
        self.種類data = 資材種類内容型(種類: 種類)
    }
    deinit { self.cleanUp() }

    var cachedData: [String] { [種類, 単位] }
}

final class 社名コードData型: DMLightWeightObject, FileMakerLightWeightData {
    static let cache = LightWeightStorage<社名コードData型>()

    let 会社名: String
    let 会社コード: 会社コード型

    init(資材 record: FileMakerRecord) {
        self.会社名 = record.string(forKey: "dbo.ZB_T1:f6") ?? ""
        self.会社コード = record.string(forKey: "会社コード") ?? ""
    }

    init(発注 record: FileMakerRecord) {
        self.会社名 = record.string(forKey: "会社名") ?? ""
        self.会社コード = record.string(forKey: "会社コード") ?? ""
    }

    init(指示書 record: FileMakerRecord) {
        self.会社名 = record.string(forKey: "社名") ?? ""
        self.会社コード = record.string(forKey: "会社コード") ?? ""
    }
    deinit { self.cleanUp() }

    var cachedData: [String] { [会社名, 会社コード]}
}
