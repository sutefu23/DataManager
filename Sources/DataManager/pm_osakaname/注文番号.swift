//
//  注文番号.swift
//  DataManager
//
//  Created by manager on 2020/03/17.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

private let 注文番号部署記号対応表: [String: 部署型] = [
    "A": 部署型.営業,
    "B": 部署型.経理,
    "C": 部署型.管理,
    "D": 部署型.外注,
    "E": 部署型.原稿・入力,
    "F": 部署型.腐蝕・印刷・水処理,
    "G": 部署型.付属品準備,
    "H": 部署型.フォーミング,
    "I": 部署型.ルーター,
    "J": 部署型.加工,
    "K": 部署型.研磨,
    "L": 部署型.オブジェ,
    "M": 部署型.腐蝕・印刷・水処理,
    "N": 部署型.レーザー・ウォーター・照合・検査,
    "O": 部署型.組立・検品,
    "P": 部署型.箱文字溶接,
    "Q": 部署型.箱文字半田,
    "R": 部署型.レーザー・ウォーター・照合・検査,
    "S": 部署型.切文字,
    "T": 部署型.腐蝕・印刷・水処理,
    "U": 部署型.表面仕上,
    "V": 部署型.塗装,
    "W": 部署型.発送,
    "X": 部署型.資材,
    "Y": 部署型.品質管理,
]
private let 部署注文番号対応map: [部署型: 注文番号型] = {
    var map: [部署型: 注文番号型] = [:]
    for (number, section) in 注文番号部署記号対応表 {
        map[section] = 注文番号キャッシュ型.shared[number]!
    }
    return map
}()
extension 部署型 {
    var 注文番号: 注文番号型? {
        部署注文番号対応map[self]
    }
}

public class 注文番号キャッシュ型 {
    public static let shared = 注文番号キャッシュ型()
    
    private var map: [String: 注文番号型] = [:]

    private init() {
        do {
            let list = try 注文番号型.注文番号一覧読み込み()
            list.forEach { map[$0.記号] = $0 }
        } catch {
            NSLog(error.localizedDescription)
        }
    }
    
    public subscript(記号: String) -> 注文番号型? { map[記号] }
    public var 全注文番号: [注文番号型] {
        return self.map.values.sorted { $0.記号 < $1.記号 }
    }
    public var 営業以外全注文番号: [注文番号型] {
        return self.map.values.filter { !$0.記号.hasPrefix("A") }.sorted { $0.記号 < $1.記号 }
    }
}

public class 注文番号型: FileMakerObject, Hashable, Codable {
    public static var db: FileMakerDB { .pm_osakaname }
    public static let layout = "DataAPI_13"

    public static let 経理 = 注文番号キャッシュ型.shared["B"]!
    public static let 管理・資材 = 注文番号キャッシュ型.shared["C"]!
    public static let 外注 = 注文番号キャッシュ型.shared["D"]!
    public static let 原稿・入力 = 注文番号キャッシュ型.shared["E"]!
    public static let 印刷 = 注文番号キャッシュ型.shared["F"]!
    public static let 付属品準備 = 注文番号キャッシュ型.shared["G"]!
    public static let フォーミング = 注文番号キャッシュ型.shared["H"]!
    public static let ルーター = 注文番号キャッシュ型.shared["I"]!
    public static let 加工 = 注文番号キャッシュ型.shared["J"]!
    public static let 研磨 = 注文番号キャッシュ型.shared["K"]!
    public static let オブジェ = 注文番号キャッシュ型.shared["L"]!
    public static let 腐蝕 = 注文番号キャッシュ型.shared["M"]!
    public static let レーザ･ウォーター = 注文番号キャッシュ型.shared["N"]!
    public static let 組立 = 注文番号キャッシュ型.shared["O"]!
    public static let 箱文字_溶接 = 注文番号キャッシュ型.shared["P"]!
    public static let 箱文字_半田 = 注文番号キャッシュ型.shared["Q"]!
    public static let 照合･検査 = 注文番号キャッシュ型.shared["R"]!
    public static let 切文字 = 注文番号キャッシュ型.shared["S"]!
    public static let 水処理 = 注文番号キャッシュ型.shared["T"]!
    public static let 表面仕上 = 注文番号キャッシュ型.shared["U"]!
    public static let 塗装 = 注文番号キャッシュ型.shared["V"]!
    public static let 発送 = 注文番号キャッシュ型.shared["W"]!
    public static let 社内一般品 = 注文番号キャッシュ型.shared["X"]!
    public static let 品質管理 = 注文番号キャッシュ型.shared["Y"]!
    public static let 予備 = 注文番号キャッシュ型.shared["Z"]!

    public var 記号: String { data.記号 }
    public var 名称: String { data.名称 }
    private let data: 注文番号Data型
    
    public var memoryFootPrint: Int { 記号.memoryFootPrint + 名称.memoryFootPrint }
    
    public init(_ record: FileMakerRecord) throws {
        self.data = try 注文番号Data型(record).regist()
    }
    
    public var 対応部署: 部署型? {
        if let sec = 注文番号部署記号対応表[self.記号] { return sec }
        if self.記号.hasPrefix("A") { return .営業 }
        return nil
    }
    
    // MARK: - <Hashable>
    public static func == (left: 注文番号型, right: 注文番号型) -> Bool {
        return left.記号 == right.記号
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.記号)
    }
    
    // MARK: - <Codable>
    enum CodingKeys: String, CodingKey {
        case 記号
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let mark = try values.decode(String.self, forKey: .記号)
        guard let result = 注文番号キャッシュ型.shared[mark] else { throw FileMakerError.notFound(message: "不明な注文番号（\(mark)）")}
        self.data = result.data
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.記号, forKey: .記号)
    }
}

extension FileMakerRecord {
    func 注文番号(forKey key: String) -> 注文番号型? {
        guard let mark = self.string(forKey: key) else { return nil }
        return 注文番号キャッシュ型.shared[mark]
    }
}
extension 注文番号型 {
    static func 注文番号一覧読み込み() throws -> [注文番号型] {
        let list: [FileMakerRecord] = try fetchAllRecords()
        return list.compactMap { try? 注文番号型($0) }.sorted { $0.記号 < $1.記号 }
    }
}

// MARK: -
private final class 注文番号Data型: DMLightWeightObject, FileMakerLightWeightData {
    static let cache = LightWeightStorage<注文番号Data型>()
    
    let 記号: String
    let 名称: String

    init(_ record: FileMakerRecord) throws {
        guard let mark = record.string(forKey: "記号"), !mark.isEmpty else { throw FileMakerError.notFound(message: "注文番号型:記号") }
        guard let name = record.string(forKey: "名称") else { throw FileMakerError.notFound(message: "注文番号型:名称") }
        self.記号 = mark
        self.名称 = name
    }

    var cachedData: [String] { [記号, 名称] }
}
