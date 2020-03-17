//
//  注文番号.swift
//  DataManager
//
//  Created by manager on 2020/03/17.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

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
}

public class 注文番号型: Hashable, Codable {
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

    let 記号: String
    let 名称: String
    
    init(_ record: FileMakerRecord) throws {
        guard let mark = record.string(forKey: "記号"), !mark.isEmpty else { throw FileMakerError.notFound(message: "注文番号型:記号") }
        guard let name = record.string(forKey: "名称"), !name.isEmpty else { throw FileMakerError.notFound(message: "注文番号型:名称") }
        self.記号 = mark
        self.名称 = name
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
        self.記号 = result.記号
        self.名称 = result.名称
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
    static let dbName = "DataAPI_13"

    static func 注文番号一覧読み込み() throws -> [注文番号型] {
        let db = FileMakerDB.pm_osakaname
        let list: [FileMakerRecord] = try db.fetch(layout: 注文番号型.dbName)
        return try list.compactMap { try 注文番号型($0) }.sorted { $0.記号 < $1.記号 }
    }
}
