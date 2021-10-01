//
//  部署.swift
//  DataManager
//
//  Created by manager on 2020/02/05.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

public final class 部署型: FileMakerSearchObject, Comparable, Hashable, Codable {
    public static var layout: String { "DataAPI_11" }
    
    public var 部署記号: String { return "\(self.部署番号)" }
    public var 部署名: String
    public let 部署番号: Int
    public let recordId: FileMakerRecordID?
    
    public init(_ 部署番号: Int, _ 部署名: String) {
        if let sec = 部署型.部署番号マップ[部署番号] {
            self.部署名 = sec.部署名
            self.部署番号 = sec.部署番号
            self.recordId = sec.recordId
        } else {
            self.部署名 = 部署名
            self.部署番号 = 部署番号
            self.recordId = nil
        }
    }
    
    public init(_ record: FileMakerRecord) throws {
        func makeError(_ key: String) -> Error { record.makeInvalidRecordError(name: "部署", mes: key) }
        guard let code = record.string(forKey: "部署記号"),
              let number = Int(code) else {
                  throw makeError("部署記号")
              }
        guard let name = record.string(forKey: "部署名") else { throw makeError("部署名") }
        self.recordId = record.recordId
        self.部署番号 = number
        self.部署名 = name
    }
    
    public var memoryFootPrint: Int { return 部署名.memoryFootPrint + 部署番号.memoryFootPrint + recordId.memoryFootPrint }

    // MARK: - Coable
    enum CodingKeys: String, CodingKey {
        case 部署名, 部署番号
    }
    
    public required convenience init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let 部署番号 = try values.decode(Int.self, forKey: .部署番号)
        let 部署名 = try values.decode(String.self, forKey: .部署名)
        self.init(部署番号, 部署名)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.部署番号, forKey: .部署番号)
        try container.encode(self.部署名, forKey: .部署名)
    }

    // MARK: - <Hahable>
    public static func ==(left: 部署型, right: 部署型) -> Bool {
        return left.部署番号 == right.部署番号
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.部署記号)
    }
    
    // MARK: - <Comparable>
    public static func <(left: 部署型, right: 部署型) -> Bool {
        return left.部署番号 < right.部署番号
    }
}

// MARK: - DB
extension 部署型 {
    public static let 経理 = 部署型(1, "経理")
    public static let 営業 = 部署型(2, "営業")
    public static let 管理 = 部署型(3, "管理")
    public static let 原稿・入力 = 部署型(4, "原稿・入力")
    public static let レーザー・ウォーター・照合・検査 = 部署型(5, "レーザー・ウォーター・照合・検査")
    public static let フォーミング = 部署型(6, "フォーミング")
    public static let 予備 = 部署型(7, "予備")
    public static let ルーター = 部署型(8, "ルーター")
    public static let 腐蝕・印刷・水処理 = 部署型(9, "腐蝕・印刷・水処理")
    public static let 箱文字半田 = 部署型(10, "箱文字半田")
    public static let 箱文字溶接 = 部署型(11, "箱文字溶接")
    public static let 切文字 = 部署型(12, "切文字")
    public static let 加工 = 部署型(13, "加工")
    public static let オブジェ = 部署型(14, "オブジェ")
    public static let 付属品準備 = 部署型(15, "付属品準備")
    public static let 研磨 = 部署型(16, "研磨")
    public static let 表面仕上 = 部署型(17, "表面仕上")
    public static let 塗装 = 部署型(18, "塗装")
    public static let 組立・検品 = 部署型(19, "組立・検品")
    public static let 発送 = 部署型(20, "発送")
    public static let ハイエスト = 部署型(21, "ハイエスト")
    public static let 食堂 = 部署型(22, "食堂")
    public static let 退職者 = 部署型(23, "退職者")
    public static let 幹部 = 部署型(24, "幹部")
    public static let 資材 = 部署型(25, "資材")
    public static let 情報システム = 部署型(26, "情報システム")
    public static let 品質管理 = 部署型(27, "品質管理")
    public static let 外注 = 部署型(28, "外注")

    static let 部署番号マップ: [Int: 部署型] = {
        var map: [Int: 部署型] = [:]
        for sec in 部署一覧 {
            map[sec.部署番号] = sec
        }
        return map
    }()

    public static let 部署一覧: [部署型] = {
        do {
            let list = try 部署型.fetchAll()
            return list
        } catch {
            NSLog(error.localizedDescription)
            return []
        }
    }()
    
    public static let 有効部署一覧: [部署型] = {
        return 部署一覧.filter {
            if $0.部署名 == "(予備)" || $0.部署名 == "退職者" { return false }
            return true
        }
    }()
}

// MARK: - 保存
extension FileMakerRecord {
    func キャッシュ部署(forKey key: String) -> 部署型? {
        guard let number = self.integer(forKey: key) else { return nil }
        if let member = 部署型.部署番号マップ[number] { return member }
        return 現在部署(forKey: key)
    }

    
    func 現在部署(forKey key: String) -> 部署型? {
        guard let number = self.integer(forKey: key) else { return nil }
        let sec = 部署型(number, "")
        return sec.部署名.isEmpty ? nil : sec
    }
}

// MARK: - 検索
extension 部署型 {
        public static func find(部署記号: String? = nil, 部署名: String? = nil) throws -> [部署型] {
        var query = FileMakerQuery()
        query["部署記号"] = 部署記号
        query["部署名"] = 部署名
        return try find(query: query)
    }
}
