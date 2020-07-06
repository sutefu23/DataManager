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

public class 社員型: Hashable, Codable {
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
    public lazy var 社員姓: String = {
        var name = ""
        for ch in self.社員名称 {
            if ch.isWhitespace || ch == "　" { break }
            name.append(ch)
        }
        return name
    }()
    private var 部署Data: 部署型?
    public var 部署: 部署型? {
        if let data = self.部署Data { return data }
        let mem = try? 社員型.findDirect(self.社員番号)
        self.部署Data = mem?.部署Data
        return mem?.部署Data
    }

    public init?(社員番号: Int?) {
        guard let 社員番号 = 社員番号, let member = 社員型.社員番号マップ[社員番号] else { return nil }
        self.社員番号 = member.社員番号
        self.社員名称 = member.社員名称
    }

    init(社員番号: Int, 社員名称: String) {
        self.社員番号 = 社員番号
        self.社員名称 = 社員名称
    }
    
    convenience init?(社員名称: String) {
        for member in 社員型.全社員一覧 {
            if member.社員名称 == 社員名称 {
                self.init(社員番号: member.社員番号, 社員名称: 社員名称)
                return
            }
        }
        return nil
    }
    
    init?(_ record: FileMakerRecord) {
        guard let 社員番号 = record.integer(forKey: "社員番号") else { return nil }
        guard let 社員名称 = record.string(forKey: "社員名称") else { return nil }
        self.社員番号 = 社員番号
        self.社員名称 = 社員名称
        self.部署Data = record.キャッシュ部署(forKey: "部署記号") 
    }
    
    public convenience init?<S: StringProtocol>(社員コード: S) {
        guard let num = calc社員番号(社員コード) else { return nil }
        self.init(社員番号: num)
    }
    
    // MARK: - Coable
    enum CodingKeys: String, CodingKey {
        case 社員番号, 社員名称
    }
    
    public required convenience init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let num = try values.decode(Int.self, forKey: .社員番号)
        let name: String
        if let object = 社員型.社員番号マップ[num] {
            name = object.社員名称
        } else {
            name = try values.decode(String.self, forKey: .社員名称)
        }
        self.init(社員番号: num, 社員名称: name)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.社員番号, forKey: .社員番号)
        try container.encode(self.社員名称, forKey: .社員名称)
    }
    
    // MARK: - Equatable
    public static func ==(left: 社員型, right: 社員型) -> Bool {
        return left.社員番号 == right.社員番号
    }
    
    // MARK: - Hashable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.社員番号)
    }
}

public extension 社員型 {
    static let 室中哲郎: 社員型 = 社員番号マップ[019]!
    static let 関雄也: 社員型 = 社員番号マップ[034]!
    static let 森藤年栄: 社員型 = 社員番号マップ[717]!
}

// MARK: - 保存
public extension UserDefaults {
    func 社員一覧(forKey key: String) -> [社員型]? {
        return self.json(forKey: key)
    }
    
    func setOptional(_ members: [社員型]?, forKey key: String) {
        self.setJson(object: members, forKey: key)
    }
    
    func 社員(forKey key: String) -> 社員型? {
        return self.json(forKey: key)
    }
    
    func setOptional(_ member: 社員型?, forKey key: String) {
        self.setJson(object: member, forKey: key)
    }
}

extension FileMakerRecord {
    func 社員(forKey key: String) -> 社員型? {
        guard let number = self.integer(forKey: key) else { return nil }
        return 社員型(社員番号: number)
    }
    func 社員名称(forKey key: String) -> 社員型? {
        guard let name = self.string(forKey: key) else { return nil }
        return 社員型(社員名称: name)
    }
}

// MARK: -
extension 社員型 {
    static let dbName = "DataAPI_8"
    
    static func fetchAll() throws -> [社員型] {
        let db = FileMakerDB.pm_osakaname
        let list: [FileMakerRecord] = try db.fetch(layout: 社員型.dbName)
        return list.compactMap { 社員型($0) }
    }
    
    static func findDirect(_ 社員番号: Int) throws -> 社員型? {
        let db = FileMakerDB.pm_osakaname
        var query = FileMakerQuery()
        query["社員番号"] = "==\(String(format: "%03d",社員番号))"
        let list = try db.find(layout: 社員型.dbName, query: [query])
        return list.compactMap { 社員型($0) }.first
    }
}
