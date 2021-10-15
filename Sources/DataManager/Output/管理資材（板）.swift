//
//  管理資材（板）.swift
//  DataManager
//
//  Created by manager on 2020/05/13.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

public class 管理板材型: 管理資材型 {
    public var 材質: String = "" // SUS304 BSP SUS316 SUS430 AL52S AL1100 STEEL
    public var 種類: String = "" // HL DS 白 黒マット ボンデ
    public var 板厚: String = "" { // 5.0 13
        didSet { self.板厚数値 = Double(self.板厚) }
    }
    public var サイズ: String = ""
    public private(set) var 板厚数値: Double? = nil
    
    public var 横幅: Double?
    public var 高さ: Double?

    public var is分割材: Bool { return 個別在庫 != nil }

    public var 表示名: String {
        "\(材質) \(板厚)t \(サイズ)"
    }
    
    func updateSheetParameters() {
        let param = 資材板情報型.find(self.資材)
        self.材質 = param.材質
        self.種類 = param.種類
        self.板厚 = param.板厚
        self.サイズ = param.サイズ
        self.高さ = param.高さ
        self.横幅 = param.横幅
        self.管理者メモ = param.備考
    }
    
    public required init(資材: 資材型, 基本発注数: Int? = nil, 安全在庫数: Int? = nil, 発注備考: String = "", 管理者メモ: String = "", 在庫管理あり: Bool = true, 個別在庫: Int? = nil) {
        super.init(資材: 資材, 基本発注数: 基本発注数, 安全在庫数: 安全在庫数, 発注備考: 発注備考, 管理者メモ: 管理者メモ, 在庫管理あり: 在庫管理あり, 個別在庫: 個別在庫)
        updateSheetParameters()
    }
    
    public init(材質: String, 種類: String, 板厚: String, サイズ: String, 資材: 資材型, 基本発注数: Int? = nil, 安全在庫数: Int? = nil, 発注備考: String = "", 管理者メモ: String = "", 在庫管理あり: Bool = true, 個別在庫: Int? = nil) {
        self.材質 = 材質
        self.種類 = 種類
        self.板厚 = 板厚
        self.板厚数値 = Double(板厚)
        self.サイズ = サイズ
        
        super.init(資材: 資材, 基本発注数: 基本発注数, 安全在庫数: 安全在庫数, 発注備考: 発注備考, 管理者メモ: 管理者メモ, 在庫管理あり: 在庫管理あり, 個別在庫: 個別在庫)
    }
    
    // MARK: <Codable>
    enum SheetCodingKeys: String, CodingKey {
        case 材質
        case 種類
        case 板厚
        case サイズ
        case 高さ
        case 横幅
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: SheetCodingKeys.self)
        self.板厚数値 = Double(self.板厚)
        try super.init(from: decoder)
        let param = 資材板情報型.find(self.資材)
        self.材質 = try values.decodeIfPresent(String.self, forKey: .材質) ?? param.材質
        self.種類 = try values.decodeIfPresent(String.self, forKey: .種類) ?? param.種類
        self.板厚 = try values.decodeIfPresent(String.self, forKey: .板厚) ?? param.板厚
        self.サイズ = try values.decodeIfPresent(String.self, forKey: .サイズ) ?? param.サイズ
        self.高さ = try values.decodeIfPresent(Double.self, forKey: .高さ) ?? param.高さ
        self.横幅 = try values.decodeIfPresent(Double.self, forKey: .横幅) ?? param.横幅
    }
    
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: SheetCodingKeys.self)
        try container.encode(self.材質, forKey: .材質)
        try container.encode(self.種類, forKey: .種類)
        try container.encode(self.板厚, forKey: .板厚)
        try container.encode(self.サイズ, forKey: .サイズ)
        try container.encode(self.高さ, forKey: .高さ)
        try container.encode(self.横幅, forKey: .横幅)
        try super.encode(to: encoder)
    }
    // MARK: -
    public var サイズ表示: String {
        if 板厚.isEmpty {
            return self.サイズ
        } else if self.サイズ.isEmpty {
            return "\(self.板厚)t"
        } else {
            return "\(self.板厚)tx\(self.サイズ)"
        }
    }
    
    public func make分割板(height: Double, width: Double) -> 管理板材型? {
        if self.高さ == height && self.横幅 == width { return nil }
        let buddy = 管理板材型(材質: self.材質, 種類: self.種類, 板厚: self.板厚, サイズ: self.サイズ, 資材: self.資材, 基本発注数: self.基本発注数, 安全在庫数: self.安全在庫数, 発注備考: self.発注備考, 管理者メモ: self.管理者メモ, 在庫管理あり: self.在庫管理あり, 個別在庫: 0)
        buddy.高さ = height
        buddy.横幅 = width
        buddy.サイズ = "\(String(format: "%.0f", height))x\(String(format: "%.0f", width))"
        return buddy
    }
    
    public func is同分割板(to item: 管理板材型) -> Bool {
        if self.個別在庫 == nil { return false }
        return self.高さ == item.高さ && self.横幅 == item.横幅 && self.資材 == item.資材
    }
}

public extension 管理板材一覧一覧型 {
    func find(図番: 図番型, 個別在庫あり: Bool) -> 管理板材型? {
        for list in self {
            if let item = list.find(図番: 図番, 個別在庫あり: 個別在庫あり) { return item }
        }
        return nil
    }
}

public extension 管理板材一覧型 {
    func find(図番: 図番型, 個別在庫あり: Bool) -> 管理板材型? {
        for item in self {
            if item.資材.図番 == 図番 && item.個別在庫あり == 個別在庫あり  {
                return item
            }
        }
        return nil
    }
}
