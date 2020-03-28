//
//  管理資材.swift
//  DataManager
//
//  Created by 四熊泰之 on R 2/03/17.
//  Copyright © Reiwa 2 四熊泰之. All rights reserved.
//

import Foundation

public typealias 管理資材一覧一覧型 = 管理対象一覧型<管理資材一覧型> // 資材一覧の一覧
public typealias 管理資材一覧型 = 管理対象一覧型<管理資材型> // 資材一覧

public typealias 管理板材一覧一覧型 = 管理対象一覧型<管理板材一覧型> // 板材一覧の一覧
public typealias 管理板材一覧型 = 管理対象一覧型<管理板材型> // 板材一覧

/// 管理対象
public protocol 管理対象型: class, Codable {
    func isIdential(to: Self) -> Bool // 対象が同じものかどうか調べる。同じ物はリストに乗れない
}

// MARK: - 一般資材
public class 管理対象一覧型<T: 管理対象型>: 管理対象型, BidirectionalCollection, ExpressibleByArrayLiteral {
    public func isIdential(to: 管理対象一覧型<T>) -> Bool { self === to }
    
    private var 一覧: [T]
    public var タイトル: String

    public init() {
        self.一覧 = []
        self.タイトル = ""
    }
    public typealias ArrayLiteralElement = T
    public required init(arrayLiteral elements: T...) {
        self.一覧 = elements
        self.タイトル = ""
    }
    
    // MARK: <Collection>
    public var isEmpty: Bool { return 一覧.isEmpty }
    public var startIndex: Int { return 一覧.startIndex }
    public var endIndex: Int { return 一覧.endIndex }
    public subscript(position: Int) -> T {
        get { return 一覧[position] }
        set { 一覧[position] = newValue }
    }
    public func index(before i: Int) -> Int { return 一覧.index(before: i) }
    public func index(after i: Int) -> Int { return 一覧.index(after: i) }
    public func makeIterator() -> IndexingIterator<[T]> { return 一覧.makeIterator() }

    // MARK: - <Codable>
    enum CodingKeys: String, CodingKey {
        case 一覧
        case タイトル
    }
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.一覧 = try values.decodeIfPresent([T].self , forKey: .一覧) ?? []
        self.タイトル = try values.decodeIfPresent(String.self, forKey: .タイトル) ?? ""
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if !self.一覧.isEmpty { try container.encode(self.一覧, forKey: .一覧) }
        if !self.タイトル.isEmpty {  try container.encode(self.タイトル, forKey: .タイトル) }
    }

    // MARK: 通常操作
    public func append(_ item: T) -> Int {
        一覧.append(item)
        return 一覧.count-1
    }
    
    public func append<S: Sequence>(contentsOf list: S) where S.Element == T {
        list.forEach { _ = self.append($0) }
    }
    public func insert<S: Sequence>(contentsOf list: S, at: Index) where S.Element == T {
        var index = at
        for item in list {
            一覧.insert(item, at: index)
            index = 一覧.index(after: index)
        }
    }
 
    public func remove(_ item: T) -> Int? {
        guard let index = 一覧.firstIndex(where: { $0.isIdential(to: item) }) else { return nil }
        return self.remove(at: index)
    }
    
    public func remove(at index: Int) -> Int? {
        if 一覧.indices.contains(index) {
            一覧.remove(at: index)
            if 一覧.indices.contains(index) {
                return index
            } else if 一覧.indices.contains(index-1) {
                return index-1
            }
        }
        return nil
    }
    
    public func moveUp(at index: Int) -> Int? {
        guard self.一覧.indices.contains(index) else { return nil }
        let prevIndex = index-1
        if 一覧.indices.contains(prevIndex) {
            一覧.swapAt(prevIndex, index)
            return prevIndex
        } else {
            return index
        }
    }
    
    public func moveUp(_ item: T) -> Int? {
        if let index = self.一覧.firstIndex(where: { $0.isIdential(to: item) }) {
            return moveUp(at: index)
        } else {
            return nil
        }
    }
    
    public func moveDown(at index: Int) -> Int? {
        guard self.一覧.indices.contains(index) else { return nil }
        let nextIndex = index+1
        if 一覧.indices.contains(nextIndex) {
            一覧.swapAt(index, nextIndex)
            return nextIndex
        } else {
            return index
        }
    }
    
    public func moveDown(_ item: T) -> Int? {
        if let index = 一覧.firstIndex(where: { $0.isIdential(to: item) }) {
            return moveDown(at: index)
        } else {
            return nil
        }
    }
    
    public func sort(_ cmp:(T, T) -> Bool) {
        self.一覧.sort(by: cmp)
    }
}

public class 管理資材型: 管理対象型 {
    public var 資材: 資材型
    public var 基本発注数: Int?
    public var 安全在庫数: Int?
    public var 発注備考: String
    public var 管理者メモ: String
    public var 在庫管理あり: Bool
    /// 発注状態が発注済で入庫したものの一覧
    public var 入庫済発注: Set<指定注文番号型> = []

    // MARK: <Codable>
    enum CodingKeys: String, CodingKey {
        case 資材
        case 基本発注数
        case 安全在庫数
        case 発注備考
        case 管理者メモ
        case 在庫管理あり
    }
    
    public required init(資材: 資材型, 基本発注数: Int? = nil, 安全在庫数: Int? = nil, 発注備考: String = "", 管理者メモ: String = "", 在庫管理あり: Bool = false) {
        self.資材 = 資材
        self.基本発注数 = 基本発注数
        self.安全在庫数 = 安全在庫数
        self.発注備考 = 発注備考
        self.管理者メモ = 管理者メモ
        self.在庫管理あり = 在庫管理あり
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.資材 = try values.decode(資材型.self, forKey: .資材)
        self.基本発注数 = try values.decodeIfPresent(Int.self, forKey: .基本発注数)
        self.安全在庫数 = try values.decodeIfPresent(Int.self, forKey: .安全在庫数)
        self.発注備考 = try values.decodeIfPresent(String.self, forKey: .発注備考) ?? ""
        self.管理者メモ = try values.decodeIfPresent(String.self, forKey: .管理者メモ) ?? ""
        self.在庫管理あり = try values.decodeIfPresent(Bool.self, forKey: .在庫管理あり) ?? false
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.資材, forKey: .資材)
        if let num = self.基本発注数 { try container.encode(num, forKey: .基本発注数) }
        if let num = self.安全在庫数 { try container.encode(num, forKey: .安全在庫数) }
        if !self.発注備考.isEmpty { try container.encode(self.発注備考, forKey: .発注備考) }
        if !self.管理者メモ.isEmpty { try container.encode(self.管理者メモ, forKey: .管理者メモ) }
        try container.encode(self.在庫管理あり, forKey: .在庫管理あり)
    }
    
    // MARK: <管理対象型>
    public func isIdential(to: 管理資材型) -> Bool {
        return self.資材.図番 == to.資材.図番
    }
}

// MARK: - 板
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

    func updateSheetParameters() {
        let param = 資材板情報型(self.資材)
        self.材質 = param.材質
        self.種類 = param.種類
        self.板厚 = param.板厚
        self.サイズ = param.サイズ
        self.高さ = param.高さ
        self.横幅 = param.横幅
        self.管理者メモ = param.備考
    }
    
    public required init(資材: 資材型, 基本発注数: Int? = nil, 安全在庫数: Int? = nil, 発注備考: String = "", 管理者メモ: String = "", 在庫管理あり: Bool = true) {
        super.init(資材: 資材, 基本発注数: 基本発注数, 安全在庫数: 安全在庫数, 発注備考: 発注備考, 管理者メモ: 管理者メモ)
        updateSheetParameters()
    }
    
    public init(材質: String, 種類: String, 板厚: String, サイズ: String, 資材: 資材型, 基本発注数: Int? = nil, 安全在庫数: Int? = nil, 発注備考: String = "", 管理者メモ: String = "", 在庫管理あり: Bool = true) {
        self.材質 = 材質
        self.種類 = 種類
        self.板厚 = 板厚
        self.板厚数値 = Double(板厚)
        self.サイズ = サイズ
        super.init(資材: 資材, 基本発注数: 基本発注数, 安全在庫数: 安全在庫数, 発注備考: 発注備考, 管理者メモ: 管理者メモ)
    }
    
    // MARK: <Codable>
    enum SheetCodingKeys: String, CodingKey {
        case 材質
        case 種類
        case 板厚
        case サイズ
        case 在庫管理あり
        case 高さ
        case 横幅
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: SheetCodingKeys.self)
        try super.init(from: decoder)
        let param = 資材板情報型(self.資材)
        self.材質 = try values.decodeIfPresent(String.self, forKey: .材質) ?? param.材質
        self.種類 = try values.decodeIfPresent(String.self, forKey: .種類) ?? param.種類
        self.板厚 = try values.decodeIfPresent(String.self, forKey: .板厚) ?? param.板厚
        self.板厚数値 = Double(self.板厚)
        self.サイズ = try values.decodeIfPresent(String.self, forKey: .サイズ) ?? param.サイズ
        self.高さ = try values.decodeIfPresent(Double.self, forKey: .高さ) ?? param.高さ
        self.横幅 = try values.decodeIfPresent(Double.self, forKey: .横幅) ?? param.横幅
        self.在庫管理あり = try values.decodeIfPresent(Bool.self, forKey: .在庫管理あり) ?? true
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
            return "\(self.板厚)tX\(self.サイズ)"
        }
    }
}

