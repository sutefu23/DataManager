//
//  社員.swift
//  DataManager
//
//  Created by manager on 2019/03/30.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

private func calc社員番号<S: StringProtocol>(_ code: S) -> Int? {
    var code = code.uppercased()
    guard let firstCode = code.first else { return nil }
    if firstCode.isNumber == false {
        guard firstCode == "H" else { return nil }
        code.remove(at: code.startIndex)
    }
    guard let num = Int(code), num >= 0 && num < 1000 else { return nil }
    return num
}

public struct 社員型: Hashable, Codable {
    static let 社員番号マップ: [Int: 社員型] = {
        var map = [Int: 社員型]()
        for member in 社員型.全社員一覧 {
            map[member.社員番号] = member
        }
        return map
    }()
    
    public static let 全社員一覧: [社員型] = {
        do {
            return try 社員型.fetchAll()
        } catch {
            NSLog(error.localizedDescription)
            return []
        }
    }()

    public let 社員番号: Int
    public let 社員名称: String
    public var 社員コード: String {
        if 社員番号 < 10 { return "H00\(社員番号)" }
        if 社員番号 < 100 { return "H0\(社員番号)" }
        return "H\(社員番号)"
    }
    public var Hなし社員コード: String {
        if 社員番号 < 10 { return "00\(社員番号)" }
        if 社員番号 < 100 { return "0\(社員番号)" }
        return "\(社員番号)"
    }

    public init?(社員番号: Int) {
        guard let member = 社員型.社員番号マップ[社員番号] else { return nil }
        self.社員番号 = member.社員番号
        self.社員名称 = member.社員名称
    }

    init(社員番号: Int, 社員名称: String) {
        self.社員番号 = 社員番号
        self.社員名称 = 社員名称
    }
    
    init?(_ record: FileMakerRecord) {
        guard let 社員番号 = record.integer(forKey: "社員番号") else { return nil }
        guard let 社員名称 = record.string(forKey: "社員名称") else { return nil }
        self.社員番号 = 社員番号
        self.社員名称 = 社員名称
    }
    
    public init?<S: StringProtocol>(社員コード: S) {
        guard let num = calc社員番号(社員コード) else { return nil }
        self.init(社員番号: num)
    }
    
    public static func ==(left: 社員型, right: 社員型) -> Bool {
        return left.社員番号 == right.社員番号
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.社員番号)
    }
}

public extension 社員型 {
    static let 室中哲郎: 社員型 = 社員番号マップ[019]!
    static let 森藤年栄: 社員型 = 社員番号マップ[717]!
}

extension 社員型 {
    static let dbName = "DataAPI_8"
    
    static func fetchAll() throws -> [社員型] {
        let db = FileMakerDB.pm_osakaname
        let list: [FileMakerRecord] = try db.fetch(layout: 社員型.dbName)
        return list.compactMap { 社員型($0) }
    }
}

