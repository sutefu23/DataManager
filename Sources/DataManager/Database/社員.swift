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
    if firstCode.isASCIINumber == false {
        guard firstCode == "H" else { return nil }
        code.remove(at: code.startIndex)
    }
    guard let num = Int(code), num >= 0 && num < 1000 else { return nil }
    return num
}

private var 全社員一覧cache: [社員型]? = nil

public final class 社員型: Hashable, Codable {
    static let 社員番号マップ: [Int: 社員型] = {
        var map = [Int: 社員型]()
        for member in 社員型.全社員一覧 {
            map[member.社員番号] = member
        }
        return map
    }()
    
    public static let 全社員一覧: [社員型] = {
        if FileMakerDB.isEnabled == false { return [] }
        do {
            if let cache = 全社員一覧cache { return cache }
            let cache = try 社員型.fetchAll()
            全社員一覧cache = cache
            return cache
        } catch {
            NSLog(error.localizedDescription)
            return 仮社員一覧
        }
    }()

    public let 社員番号: Int
    public let 社員名称: String
    public var 社員_姓ふりがな: String = ""
    public var 社員_名ふりがな: String = ""
    public var ふりがな: String {
        if 社員_姓ふりがな.isEmpty { return 社員_名ふりがな }
        if 社員_名ふりがな.isEmpty { return 社員_姓ふりがな }
        return "\(社員_姓ふりがな)　\(社員_名ふりがな)"
    }
    
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
    public let 補足情報: String

    init(_ source: 社員型) {
        self.社員番号 = source.社員番号
        self.社員名称 = source.社員名称
        self.部署Data = source.部署Data
        self.補足情報 = source.補足情報
        self.社員_姓ふりがな = source.社員_姓ふりがな
        self.社員_名ふりがな = source.社員_名ふりがな
    }
    
    public init?(社員番号: Int?) {
        guard let 社員番号 = 社員番号, let member = 社員型.社員番号マップ[社員番号] else { return nil }
        self.社員番号 = member.社員番号
        self.社員名称 = member.社員名称
        self.部署Data = member.部署Data
        self.補足情報 = member.補足情報
        self.社員_姓ふりがな = member.社員_姓ふりがな
        self.社員_名ふりがな = member.社員_名ふりがな
    }
    
    public init(社員番号: Int, 社員名称: String) {
        if let member = 社員型.社員番号マップ[社員番号] {
            self.社員番号 = member.社員番号
            self.社員名称 = member.社員名称
            self.部署Data = member.部署Data
            self.補足情報 = member.補足情報
            self.社員_姓ふりがな = member.社員_姓ふりがな
            self.社員_名ふりがな = member.社員_名ふりがな
        } else {
            self.社員番号 = 社員番号
            self.社員名称 = 社員名称
            self.部署Data = nil
            self.補足情報 = ""
            self.社員_姓ふりがな = ""
            self.社員_名ふりがな = ""
        }
    }
    
    convenience init?(社員名称: String) {
        for member in 社員型.全社員一覧 {
            if member.社員名称 == 社員名称 {
                self.init(member)
                return
            }
        }
        return nil
    }
    
    init(_ record: FileMakerRecord) throws {
        func makeError(_ key: String) -> Error { record.makeInvalidRecordError(name: "社員", mes: key) }
        guard let 社員番号 = record.integer(forKey: "社員番号") else { throw makeError("社員番号") }
        guard let 社員名称 = record.string(forKey: "社員名称") else { throw makeError("社員名称") }
        self.社員番号 = 社員番号
        self.社員名称 = 社員名称
        self.部署Data = record.キャッシュ部署(forKey: "部署記号")
        self.補足情報 = record.string(forKey: "アマダ社員番号") ?? ""
        self.社員_姓ふりがな = record.string(forKey: "社員_姓ふりがな") ?? ""
        self.社員_名ふりがな = record.string(forKey: "社員_名ふりがな") ?? ""
    }
    
    public convenience init?<S: StringProtocol>(社員コード: S) {
        guard let num = calc社員番号(社員コード) else { return nil }
        self.init(社員番号: num)
    }
    
    // MARK: - Coable
    enum CodingKeys: String, CodingKey {
        case 社員番号, 社員名称, 社員_姓ふりがな, 社員_名ふりがな, 補足情報, 部署
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let num = try values.decode(Int.self, forKey: .社員番号)
        if let member = 社員型.社員番号マップ[num] {
            self.社員番号 = member.社員番号
            self.社員名称 = member.社員名称
            self.部署Data = member.部署Data
            self.補足情報 = member.補足情報
            self.社員_姓ふりがな = member.社員_姓ふりがな
            self.社員_名ふりがな = member.社員_名ふりがな
        } else {
            self.社員番号 = num
            self.社員名称 = try values.decode(String.self, forKey: .社員名称)
            self.部署Data = try values.decodeIfPresent(部署型.self, forKey: .部署)
            self.補足情報 = try values.decodeIfPresent(String.self, forKey: .補足情報) ?? ""
            self.社員_姓ふりがな = try values.decodeIfPresent(String.self, forKey: .社員_姓ふりがな) ?? ""
            self.社員_名ふりがな = try values.decodeIfPresent(String.self, forKey: .社員_名ふりがな) ?? ""
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.社員番号, forKey: .社員番号)
        try container.encode(self.社員名称, forKey: .社員名称)
        try container.encode(self.部署, forKey: .部署)
        try container.encode(self.補足情報, forKey: .補足情報)
        try container.encode(self.社員_姓ふりがな, forKey: .社員_姓ふりがな)
        try container.encode(self.社員_名ふりがな, forKey: .社員_名ふりがな)
    }
    
    // MARK: - Equatable
    public static func ==(left: 社員型, right: 社員型) -> Bool {
        return left.社員番号 == right.社員番号
    }
    
    // MARK: - Hashable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.社員番号)
    }
    
    // MARK: -
    public var 給与計算社員番号: Int? {
        let number = self.補足情報
        guard let value = Int(number) else { return nil }
        return value
    }
    
    public var is食堂現金払い: Bool {
        self.給与計算社員番号 == nil
    }
}

func prepare社員(社員番号: Int, 社員名称: String) -> 社員型 {
    if let member = 社員型.社員番号マップ[社員番号] {
        return member
    } else {
        return 社員型(社員番号: 社員番号, 社員名称: 社員名称)
    }
}

// 社員リスト（一部抜粋）
public extension 社員型 {
    static let 稗田_司 = prepare社員(社員番号: 012, 社員名称: "稗田 司")
    static let 伊川_浩 = prepare社員(社員番号: 016, 社員名称: "伊川 浩")
    static let 川原_夏彦 = prepare社員(社員番号: 017, 社員名称: "川原 夏彦")
    static let 室中_哲郎 = prepare社員(社員番号: 019, 社員名称: "室中 哲郎")
    static let 関_雄也 = prepare社員(社員番号: 034, 社員名称: "関 雄也")
    static let 佐伯_潤一 = prepare社員(社員番号: 038, 社員名称: "佐伯　潤一")
    static let 田中_希望 = prepare社員(社員番号: 059, 社員名称: "田中　希望")
    static let 山本_沢 = prepare社員(社員番号: 061, 社員名称: "山本　沢")
    static let 平山_裕二 = prepare社員(社員番号: 084, 社員名称: "平山　裕二")
    static let 荒川_謙二 = prepare社員(社員番号: 095, 社員名称: "荒川　謙二")
    static let 井手_法昭 = prepare社員(社員番号: 102, 社員名称: "井手 法昭")
    static let 岸原_秀昌 = prepare社員(社員番号: 112, 社員名称: "岸原 秀昌")
    static let 川﨑_誠 = prepare社員(社員番号: 120, 社員名称: "川﨑　誠")
    static let 葏口_徹 = prepare社員(社員番号: 125, 社員名称: "葏口 徹")
    static let 森藤_年栄 = prepare社員(社員番号: 717, 社員名称: "森藤 年栄")
    static let 森_未来 = prepare社員(社員番号: 734, 社員名称: "森　未来")
    static let 平上_未奈 = prepare社員(社員番号: 748, 社員名称: "平上　未奈")
    static let 坂本_祐樹 = prepare社員(社員番号: 920, 社員名称: "坂本　祐樹")
    static let 和田_千秋 = prepare社員(社員番号: 955, 社員名称: "和田 千秋")
}
private var 仮社員一覧: [社員型] {
    return [
        .稗田_司,
        .伊川_浩,
        .川原_夏彦,
        .室中_哲郎,
        .関_雄也,
        .佐伯_潤一,
        .田中_希望,
        .荒川_謙二,
        .井手_法昭,
        .岸原_秀昌,
        .川﨑_誠,
        .葏口_徹,
        .森藤_年栄,
        .森_未来,
        .平上_未奈,
        .坂本_祐樹,
        .和田_千秋,
    ]
}


// MARK: - 保存
public extension UserDefaults {
    func 社員一覧(forKey key: String) -> [社員型]? { self.json(forKey: key) }
    
    func setOptional(_ members: [社員型]?, forKey key: String) { self.setJson(object: members, forKey: key) }
    
    func 社員(forKey key: String) -> 社員型? { self.json(forKey: key) }
    
    func setOptional(_ member: 社員型?, forKey key: String) { self.setJson(object: member, forKey: key) }
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
        return list.compactMap { try? 社員型($0) }
    }
    
    static func findDirect(_ 社員番号: Int) throws -> 社員型? {
        let db = FileMakerDB.pm_osakaname
        var query = FileMakerQuery()
        query["社員番号"] = "==\(String(format: "%03d",社員番号))"
        let list = try db.find(layout: 社員型.dbName, query: [query])
        return try list.map { try 社員型($0) }.first
    }
}
