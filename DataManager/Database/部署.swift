//
//  部署.swift
//  DataManager
//
//  Created by manager on 2020/02/05.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

public class 部署型: Comparable, Hashable {
    let record: FileMakerRecord

    public var 部署記号: String { return "\(self.部署番号)" }
    public var 部署名: String
    let 部署番号: Int
    
    public convenience init?(_ 部署番号: Int) {
        guard let sec = 部署型.部署番号マップ[部署番号] else { return nil }
        self.init(sec.record)
    }
    
    init?(_ record: FileMakerRecord) {
        self.record = record
        guard let code = record.string(forKey: "部署記号") else { return nil }
        guard let name = record.string(forKey: "部署名") else { return nil }
        guard let number = Int(code) else { return nil }
        self.部署番号 = number
        self.部署名 = name
    }
    
    public static func ==(left: 部署型, right: 部署型) -> Bool {
        return left.部署番号 == right.部署番号
    }
    public static func <(left: 部署型, right: 部署型) -> Bool {
        return left.部署番号 < right.部署番号
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.部署記号)
    }
}

// MARK: - DB
extension 部署型 {
    public static let 経理 = 部署型(1)!
    public static let 営業 = 部署型(2)!
    public static let 管理 = 部署型(3)!
    public static let 原稿・入力 = 部署型(4)!
    public static let レーザー・ウォーター・照合・検査 = 部署型(5)!
    public static let フォーミング = 部署型(6)!
    public static let 予備 = 部署型(7)!
    public static let ルーター = 部署型(8)!
    public static let 腐蝕・印刷・水処理 = 部署型(9)!
    public static let 箱文字半田 = 部署型(10)!
    public static let 箱文字溶接 = 部署型(11)!
    public static let 切文字 = 部署型(12)!
    public static let 加工 = 部署型(13)!
    public static let オブジェ = 部署型(14)!
    public static let 付属品準備 = 部署型(15)!
    public static let 研磨 = 部署型(16)!
    public static let 表面仕上 = 部署型(17)!
    public static let 塗装 = 部署型(18)!
    public static let 組立・検品 = 部署型(19)!
    public static let 発送 = 部署型(20)!
    public static let ハイエスト = 部署型(21)!
    public static let 食堂 = 部署型(22)!
    public static let 退職者 = 部署型(23)!
    public static let 幹部 = 部署型(24)!
    public static let 資材 = 部署型(25)!
    public static let 情報システム = 部署型(26)!
    public static let 品質管理 = 部署型(27)!
    public static let 外注 = 部署型(28)!

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
    func 部署(forKey key: String) -> 部署型? {
        guard let number = self.integer(forKey: key) else { return nil }
        return 部署型(number)
    }
}

// MARK: - 検索
extension 部署型 {
    static let dbName = "DataAPI_11"
    
    static func fetchAll() throws -> [部署型] {
        let db = FileMakerDB.pm_osakaname
        let list: [FileMakerRecord] = try db.fetch(layout: 部署型.dbName)
        return list.compactMap { 部署型($0) }

    }
    
    public static func find(部署記号: String? = nil, 部署名: String? = nil) throws -> [部署型] {
        var query = FileMakerQuery()
        query["部署記号"] = 部署記号
        query["部署名"] = 部署名
        let db = FileMakerDB.pm_osakaname
        let list: [FileMakerRecord] = try db.find(layout: 部署型.dbName, query: [query])
        return list.compactMap { 部署型($0) }
    }
}
