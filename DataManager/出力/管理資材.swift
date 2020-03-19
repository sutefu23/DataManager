//
//  管理資材.swift
//  DataManager
//
//  Created by 四熊泰之 on R 2/03/17.
//  Copyright © Reiwa 2 四熊泰之. All rights reserved.
//

import Foundation

public struct 管理資材一覧型: Codable {
    public var 一覧: [管理資材型]

    public init() {
        self.一覧 = []
    }
    // MARK: - <Codable>
    enum CodingKeys: String, CodingKey {
        case 一覧
    }
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.一覧 = try values.decode([管理資材型].self , forKey: .一覧)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.一覧, forKey: .一覧)
    }
}

public struct 管理資材型: Codable {
    public var 資材: 資材型
    public var 基本発注数: Int?
    public var 安全在庫数: Int?
    public var 発注備考: String
    public var 管理者メモ: String

    // MARK: - <Codable>
    enum CodingKeys: String, CodingKey {
        case 資材
        case 基本発注数
        case 安全在庫数
        case 発注備考
        case 管理者メモ
    }
    
    public init(資材: 資材型, 基本発注数: Int? = nil, 安全在庫数: Int? = nil, 発注備考: String = "", 管理者メモ: String = "") {
        self.資材 = 資材
        self.基本発注数 = 基本発注数
        self.安全在庫数 = 安全在庫数
        self.発注備考 = 発注備考
        self.管理者メモ = 管理者メモ
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.資材 = try values.decode(資材型.self, forKey: .資材)
        self.基本発注数 = try values.decodeIfPresent(Int.self, forKey: .基本発注数)
        self.安全在庫数 = try values.decodeIfPresent(Int.self, forKey: .安全在庫数)
        self.発注備考 = try values.decodeIfPresent(String.self, forKey: .発注備考) ?? ""
        self.管理者メモ = try values.decodeIfPresent(String.self, forKey: .管理者メモ) ?? ""
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.資材, forKey: .資材)
        if let num = self.基本発注数 { try container.encode(num, forKey: .基本発注数) }
        if let num = self.安全在庫数 { try container.encode(num, forKey: .安全在庫数) }
        if !self.発注備考.isEmpty { try container.encode(self.発注備考, forKey: .発注備考) }
        if !self.管理者メモ.isEmpty { try container.encode(self.管理者メモ, forKey: .管理者メモ) }
    }
    
}

